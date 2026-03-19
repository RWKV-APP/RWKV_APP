part of 'p.dart';

const _apiServerDefaultPort = 8080;
const _apiServerStreamingFirstChunkDelay = Duration(milliseconds: 220);

const _apiServerHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'X-Requested-With,content-type,Authorization',
};

class _ApiServerStoppingException implements Exception {}

class _ApiServer {
  // ===========================================================================
  // Instance
  // ===========================================================================

  final _requestQueue = <Completer<void>>[];
  bool _processing = false;
  Timer? _pollingTimer;
  DateTime? _startTime;
  StreamSubscription<from_rwkv.FromRWKV>? _broadcastSub;
  String? _dashboardHtmlCache;
  Completer<void>? _activeInferenceCompleter;
  int? _activeModelID;
  String? _activeInferenceId;

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final port = qs(_apiServerDefaultPort);
  late final server = qs<HttpServer?>(null);
  late final state = qs(BackendState.stopped);
  late final requestCount = qs(0);
  late final activeRequest = qs(false);
  late final logs = qs<List<String>>([]);
}

extension _$ApiServer on _ApiServer {
  Future<void> _init() async {
    if (!P.app.isDesktop.q) return;
    qq;
  }

  void _addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final entry = '[$time] $message';
    final current = logs.q;
    logs.q = [...current.length > 200 ? current.sublist(current.length - 200) : current, entry];
  }

  String _modelId(FileInfo info) => info.fileName.replaceAll('.gguf', '');

  Map<String, dynamic> _errorJson(String message, {String type = 'invalid_request_error'}) {
    return {
      'error': {
        'message': message,
        'type': type,
        'param': null,
        'code': null,
      },
    };
  }

  shelf.Response _jsonResponse(Object body, {int status = 200}) {
    return shelf.Response(
      status,
      body: jsonEncode(body),
      headers: {..._apiServerHeaders, 'Content-Type': 'application/json'},
      encoding: utf8,
    );
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    if (request.method == 'OPTIONS') {
      return shelf.Response.ok(null, headers: _apiServerHeaders);
    }

    final path = request.url.path;

    if (path == '' || path == 'dashboard' || path == 'docs') {
      return _serveDashboard(request);
    }

    if (path == 'v1/models' && request.method == 'GET') {
      return _handleModels(request);
    }

    if (path == 'v1/server/status' && request.method == 'GET') {
      return _handleStatus(request);
    }

    if (path == 'v1/server/stop' && request.method == 'POST') {
      return _handleStopActiveRequest(request);
    }

    if (path == 'v1/chat/completions' && request.method == 'POST') {
      return _handleChatCompletions(request);
    }

    if (path == 'v1/completions' && request.method == 'POST') {
      return _handleCompletions(request);
    }

    return _jsonResponse(_errorJson('Not found: /$path'), status: 404);
  }

  shelf.Response _handleModels(shelf.Request request) {
    final loaded = P.rwkv.loadedModels.q;
    final models = loaded.keys.where((e) => e.weightType == .chat).map((info) {
      return {
        'id': _modelId(info),
        'object': 'model',
        'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'owned_by': 'rwkv',
      };
    }).toList();

    return _jsonResponse({'object': 'list', 'data': models});
  }

  shelf.Response _handleStatus(shelf.Request request) {
    final loaded = P.rwkv.loadedModels.q;
    final modelNames = loaded.keys.where((e) => e.weightType == .chat).map((e) => _modelId(e)).toList();
    final uptime = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;

    return _jsonResponse({
      'status': state.q == BackendState.running ? 'running' : 'stopped',
      'port': port.q,
      'models': modelNames,
      'request_count': requestCount.q,
      'active': activeRequest.q,
      'uptime_seconds': uptime,
    });
  }

  Future<shelf.Response> _handleStopActiveRequest(shelf.Request request) async {
    final stopped = await _stopCurrentRequestInternal();
    return _jsonResponse({
      'ok': true,
      'stopped': stopped,
      'active': activeRequest.q,
    });
  }

  Future<shelf.Response> _handleChatCompletions(shelf.Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      return _jsonResponse(_errorJson('Invalid JSON'), status: 400);
    }

    final messagesValue = json['messages'];
    if (messagesValue is! List) {
      return _jsonResponse(_errorJson('messages must be a list'), status: 400);
    }

    final messagesRaw = messagesValue;
    if (messagesRaw.isEmpty) {
      return _jsonResponse(_errorJson('messages is required'), status: 400);
    }

    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return _jsonResponse(_errorJson('No chat model loaded', type: 'model_not_found'), status: 503);
    }

    final stream = json['stream'] == true;
    final maxTokens = json['max_tokens'] as int?;

    final messages = <String>[];
    for (final m in messagesRaw) {
      if (m is! Map) {
        return _jsonResponse(_errorJson('each message must be an object'), status: 400);
      }
      final role = m['role'] as String? ?? '';
      final content = m['content'] as String? ?? '';
      if (role == 'system') {
        if (messages.isEmpty) {
          messages.add(content);
          messages.add('OK.');
        }
      } else if (role == 'user') {
        messages.add(content);
      } else if (role == 'assistant') {
        messages.add(content);
      }
    }

    if (messages.length.isEven) {
      messages.add('');
    }

    final reqId = 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}';
    final modelName = P.rwkv.latestModel.q != null ? _modelId(P.rwkv.latestModel.q!) : 'rwkv';

    _addLog('POST /v1/chat/completions (stream=$stream, messages=${messagesRaw.length})');
    requestCount.q++;

    if (stream) {
      return _streamingChatCompletion(messages, reqId, modelName, modelID, maxTokens);
    } else {
      return _blockingChatCompletion(messages, reqId, modelName, modelID, maxTokens);
    }
  }

  Future<shelf.Response> _streamingChatCompletion(
    List<String> messages,
    String reqId,
    String modelName,
    int modelID,
    int? maxTokens,
  ) async {
    final controller = StreamController<List<int>>();

    void sendSSE(Map<String, dynamic> data) {
      controller.add(utf8.encode('data: ${jsonEncode(data)}\n\n'));
    }

    unawaited(
      _enqueueInference(
        modelID: modelID,
        reqId: reqId,
        work: () async {
          final request = to_rwkv.ChatAsync(
            messages,
            enableReasoning: false,
            forceReasoning: false,
            addGenerationPrompt: messages.length.isOdd,
            modelID: modelID,
            maxLength: maxTokens,
          );

          String previousContent = '';
          String pendingContent = '';
          DateTime? pendingSince;
          bool generationStarted = false;
          bool firstChunkSent = false;
          final completer = Completer<void>();
          _activeInferenceCompleter = completer;

          void markGenerationStarted() {
            if (generationStarted) return;
            generationStarted = true;
            previousContent = '';
            pendingContent = '';
            pendingSince = null;
            firstChunkSent = false;
          }

          void requestLatestBuffer() {
            P.rwkv.send(to_rwkv.GetIsGenerating(modelID: modelID));
            P.rwkv.send(to_rwkv.GetResponseBufferContent(messages: messages, modelID: modelID));
          }

          _pollingTimer?.cancel();
          _broadcastSub?.cancel();
          _broadcastSub = P.rwkv.broadcastStream.listen((event) {
            if (event is from_rwkv.GenerateStart) {
              if (event.req?.requestId != request.requestId) return;
              markGenerationStarted();
              return;
            }
            if (event is from_rwkv.IsGenerating) {
              if (event.modelID != modelID) return;
              if (event.isGenerating) {
                markGenerationStarted();
              } else if (generationStarted) {
                if (!completer.isCompleted) completer.complete();
              }
              return;
            }
            if (event is from_rwkv.GenerateStop) {
              if (event.req?.requestId != request.requestId) return;
              if (!completer.isCompleted) completer.complete();
              return;
            }

            String full = '';
            bool eosFound = false;
            if (event is from_rwkv.ResponseBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetResponseBufferContent || req.modelID != modelID) return;
              full = event.responseBufferContent;
              eosFound = event.eosFound;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              full = event.responseBufferContent.isNotEmpty ? event.responseBufferContent[0] : '';
              eosFound = event.eosFound.isNotEmpty ? event.eosFound[0] : false;
            } else {
              return;
            }

            if (!generationStarted) {
              if (full.isEmpty) return;
              markGenerationStarted();
            }
            if (!firstChunkSent) {
              if (full.isEmpty) return;
              final now = DateTime.now();
              if (pendingContent.isEmpty) {
                pendingContent = full;
                pendingSince = now;
                if (!eosFound) return;
              } else if (!full.startsWith(pendingContent)) {
                pendingContent = full;
                pendingSince = now;
                if (!eosFound) return;
              } else {
                pendingContent = full;
              }

              final readyByTime = pendingSince != null && now.difference(pendingSince!) >= _apiServerStreamingFirstChunkDelay;
              if (!readyByTime && !eosFound) return;

              previousContent = full;
              firstChunkSent = true;
              sendSSE({
                'id': reqId,
                'object': 'chat.completion.chunk',
                'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'model': modelName,
                'choices': [
                  {
                    'index': 0,
                    'delta': {'content': full},
                    'finish_reason': null,
                  },
                ],
              });
              return;
            }
            if (!full.startsWith(previousContent)) {
              _addLog('chat stream prefix mismatch, ignored snapshot');
              return;
            }
            if (full.length > previousContent.length) {
              final delta = full.substring(previousContent.length);
              previousContent = full;
              sendSSE({
                'id': reqId,
                'object': 'chat.completion.chunk',
                'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'model': modelName,
                'choices': [
                  {
                    'index': 0,
                    'delta': {'content': delta},
                    'finish_reason': null,
                  },
                ],
              });
            }
          });
          P.rwkv.send(request);
          requestLatestBuffer();
          _pollingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
            requestLatestBuffer();
          });

          await completer.future.timeout(const Duration(minutes: 10), onTimeout: () {});

          _pollingTimer?.cancel();
          _pollingTimer = null;
          _broadcastSub?.cancel();
          _broadcastSub = null;

          sendSSE({
            'id': reqId,
            'object': 'chat.completion.chunk',
            'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'model': modelName,
            'choices': [
              {
                'index': 0,
                'delta': {},
                'finish_reason': 'stop',
              },
            ],
          });
          controller.add(utf8.encode('data: [DONE]\n\n'));
          await controller.close();
        },
      ).catchError((error, stackTrace) async {
        if (controller.isClosed) return;
        if (error is! _ApiServerStoppingException) {
          qqe(error);
        }
        sendSSE({
          'id': reqId,
          'object': 'chat.completion.chunk',
          'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'model': modelName,
          'choices': [
            {
              'index': 0,
              'delta': {},
              'finish_reason': 'stop',
            },
          ],
        });
        controller.add(utf8.encode('data: [DONE]\n\n'));
        await controller.close();
      }),
    );

    return shelf.Response.ok(
      controller.stream,
      headers: {
        ..._apiServerHeaders,
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-transform',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
    );
  }

  Future<shelf.Response> _blockingChatCompletion(
    List<String> messages,
    String reqId,
    String modelName,
    int modelID,
    int? maxTokens,
  ) async {
    final resultCompleter = Completer<String>();

    try {
      await _enqueueInference(
        modelID: modelID,
        reqId: reqId,
        work: () async {
          final request = to_rwkv.ChatAsync(
            messages,
            enableReasoning: false,
            forceReasoning: false,
            addGenerationPrompt: messages.length.isOdd,
            modelID: modelID,
            maxLength: maxTokens,
          );

          String lastContent = '';
          bool generationStarted = false;
          final completer = Completer<void>();
          _activeInferenceCompleter = completer;

          void markGenerationStarted() {
            if (generationStarted) return;
            generationStarted = true;
          }

          void requestLatestBuffer() {
            P.rwkv.send(to_rwkv.GetIsGenerating(modelID: modelID));
            P.rwkv.send(to_rwkv.GetResponseBufferContent(messages: messages, modelID: modelID));
          }

          _pollingTimer?.cancel();
          _broadcastSub?.cancel();
          _broadcastSub = P.rwkv.broadcastStream.listen((event) {
            if (event is from_rwkv.GenerateStart) {
              if (event.req?.requestId != request.requestId) return;
              markGenerationStarted();
              return;
            }
            if (event is from_rwkv.IsGenerating) {
              if (event.modelID != modelID) return;
              if (event.isGenerating) {
                markGenerationStarted();
              } else if (!event.isGenerating && generationStarted) {
                if (!completer.isCompleted) completer.complete();
              }
              return;
            }
            if (event is from_rwkv.GenerateStop) {
              if (event.req?.requestId != request.requestId) return;
              if (!completer.isCompleted) completer.complete();
              return;
            }

            if (event is from_rwkv.ResponseBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetResponseBufferContent || req.modelID != modelID) return;
              if (!generationStarted && event.responseBufferContent.isEmpty) return;
              markGenerationStarted();
              lastContent = event.responseBufferContent;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              if (event.responseBufferContent.isEmpty) return;
              if (!generationStarted && event.responseBufferContent[0].isEmpty) return;
              markGenerationStarted();
              lastContent = event.responseBufferContent[0];
            }
          });
          P.rwkv.send(request);
          requestLatestBuffer();
          _pollingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
            requestLatestBuffer();
          });

          await completer.future.timeout(const Duration(minutes: 10), onTimeout: () {});

          _pollingTimer?.cancel();
          _pollingTimer = null;
          _broadcastSub?.cancel();
          _broadcastSub = null;

          resultCompleter.complete(lastContent);
        },
      );
    } on _ApiServerStoppingException {
      return _jsonResponse(_errorJson('API Server is stopping', type: 'server_unavailable'), status: 503);
    }

    final content = await resultCompleter.future;

    return _jsonResponse({
      'id': reqId,
      'object': 'chat.completion',
      'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'model': modelName,
      'choices': [
        {
          'index': 0,
          'message': {'role': 'assistant', 'content': content},
          'finish_reason': 'stop',
        },
      ],
      'usage': {
        'prompt_tokens': 0,
        'completion_tokens': 0,
        'total_tokens': 0,
      },
    });
  }

  Future<shelf.Response> _handleCompletions(shelf.Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      return _jsonResponse(_errorJson('Invalid JSON'), status: 400);
    }

    final prompt = json['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return _jsonResponse(_errorJson('prompt is required'), status: 400);
    }

    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return _jsonResponse(_errorJson('No chat model loaded', type: 'model_not_found'), status: 503);
    }

    final stream = json['stream'] == true;
    final maxTokens = json['max_tokens'] as int?;
    final reqId = 'cmpl-${DateTime.now().millisecondsSinceEpoch}';
    final modelName = P.rwkv.latestModel.q != null ? _modelId(P.rwkv.latestModel.q!) : 'rwkv';

    _addLog('POST /v1/completions (stream=$stream)');
    requestCount.q++;

    if (stream) {
      return _streamingCompletion(prompt, reqId, modelName, modelID, maxTokens);
    } else {
      return _blockingCompletion(prompt, reqId, modelName, modelID, maxTokens);
    }
  }

  Future<shelf.Response> _streamingCompletion(
    String prompt,
    String reqId,
    String modelName,
    int modelID,
    int? maxTokens,
  ) async {
    final controller = StreamController<List<int>>();

    void sendSSE(Map<String, dynamic> data) {
      controller.add(utf8.encode('data: ${jsonEncode(data)}\n\n'));
    }

    unawaited(
      _enqueueInference(
        modelID: modelID,
        reqId: reqId,
        work: () async {
          final request = to_rwkv.GenerateAsync(
            prompt,
            batch: 1,
            modelID: modelID,
            maxLength: maxTokens,
          );

          String previousContent = prompt;
          String pendingContent = '';
          DateTime? pendingSince;
          bool generationStarted = false;
          bool firstChunkSent = false;
          final completer = Completer<void>();
          _activeInferenceCompleter = completer;

          void markGenerationStarted() {
            if (generationStarted) return;
            generationStarted = true;
            previousContent = prompt;
            pendingContent = '';
            pendingSince = null;
            firstChunkSent = false;
          }

          void requestLatestBuffer() {
            P.rwkv.send(to_rwkv.GetIsGenerating(modelID: modelID));
            P.rwkv.send(to_rwkv.GetResponseBufferContent(messages: [], modelID: modelID));
          }

          _pollingTimer?.cancel();
          _broadcastSub?.cancel();
          _broadcastSub = P.rwkv.broadcastStream.listen((event) {
            if (event is from_rwkv.GenerateStart) {
              if (event.req?.requestId != request.requestId) return;
              markGenerationStarted();
              return;
            }
            if (event is from_rwkv.IsGenerating) {
              if (event.modelID != modelID) return;
              if (event.isGenerating) {
                markGenerationStarted();
              } else if (generationStarted) {
                if (!completer.isCompleted) completer.complete();
              }
              return;
            }
            if (event is from_rwkv.GenerateStop) {
              if (event.req?.requestId != request.requestId) return;
              if (!completer.isCompleted) completer.complete();
              return;
            }

            String full = '';
            bool eosFound = false;
            if (event is from_rwkv.ResponseBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetResponseBufferContent || req.modelID != modelID) return;
              full = event.responseBufferContent;
              eosFound = event.eosFound;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              full = event.responseBufferContent.isNotEmpty ? event.responseBufferContent[0] : '';
              eosFound = event.eosFound.isNotEmpty ? event.eosFound[0] : false;
            } else {
              return;
            }

            if (!generationStarted) {
              if (full.isEmpty) return;
              markGenerationStarted();
            }
            if (!firstChunkSent) {
              if (full.length < prompt.length) return;
              final now = DateTime.now();
              if (pendingContent.isEmpty) {
                pendingContent = full;
                pendingSince = now;
                if (!eosFound) return;
              } else if (!full.startsWith(pendingContent)) {
                pendingContent = full;
                pendingSince = now;
                if (!eosFound) return;
              } else {
                pendingContent = full;
              }

              final readyByTime = pendingSince != null && now.difference(pendingSince!) >= _apiServerStreamingFirstChunkDelay;
              if (!readyByTime && !eosFound) return;

              final firstDelta = full.startsWith(prompt) ? full.substring(prompt.length) : full;
              previousContent = full;
              firstChunkSent = true;
              if (firstDelta.isEmpty) return;
              sendSSE({
                'id': reqId,
                'object': 'text_completion',
                'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'model': modelName,
                'choices': [
                  {'index': 0, 'text': firstDelta, 'finish_reason': null},
                ],
              });
              return;
            }
            if (!full.startsWith(previousContent)) {
              _addLog('completion stream prefix mismatch, ignored snapshot');
              return;
            }
            if (full.length > previousContent.length) {
              final delta = full.substring(previousContent.length);
              previousContent = full;
              sendSSE({
                'id': reqId,
                'object': 'text_completion',
                'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'model': modelName,
                'choices': [
                  {'index': 0, 'text': delta, 'finish_reason': null},
                ],
              });
            }
          });
          P.rwkv.send(request);
          requestLatestBuffer();
          _pollingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
            requestLatestBuffer();
          });

          await completer.future.timeout(const Duration(minutes: 10), onTimeout: () {});

          _pollingTimer?.cancel();
          _pollingTimer = null;
          _broadcastSub?.cancel();
          _broadcastSub = null;

          sendSSE({
            'id': reqId,
            'object': 'text_completion',
            'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'model': modelName,
            'choices': [
              {'index': 0, 'text': '', 'finish_reason': 'stop'},
            ],
          });
          controller.add(utf8.encode('data: [DONE]\n\n'));
          await controller.close();
        },
      ).catchError((error, stackTrace) async {
        if (controller.isClosed) return;
        if (error is! _ApiServerStoppingException) {
          qqe(error);
        }
        sendSSE({
          'id': reqId,
          'object': 'text_completion',
          'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'model': modelName,
          'choices': [
            {'index': 0, 'text': '', 'finish_reason': 'stop'},
          ],
        });
        controller.add(utf8.encode('data: [DONE]\n\n'));
        await controller.close();
      }),
    );

    return shelf.Response.ok(
      controller.stream,
      headers: {
        ..._apiServerHeaders,
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-transform',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
    );
  }

  Future<shelf.Response> _blockingCompletion(
    String prompt,
    String reqId,
    String modelName,
    int modelID,
    int? maxTokens,
  ) async {
    final resultCompleter = Completer<String>();

    try {
      await _enqueueInference(
        modelID: modelID,
        reqId: reqId,
        work: () async {
          final request = to_rwkv.GenerateAsync(
            prompt,
            batch: 1,
            modelID: modelID,
            maxLength: maxTokens,
          );

          String lastContent = '';
          bool generationStarted = false;
          final completer = Completer<void>();
          _activeInferenceCompleter = completer;

          void markGenerationStarted() {
            if (generationStarted) return;
            generationStarted = true;
          }

          void requestLatestBuffer() {
            P.rwkv.send(to_rwkv.GetIsGenerating(modelID: modelID));
            P.rwkv.send(to_rwkv.GetResponseBufferContent(messages: [], modelID: modelID));
          }

          _pollingTimer?.cancel();
          _broadcastSub?.cancel();
          _broadcastSub = P.rwkv.broadcastStream.listen((event) {
            if (event is from_rwkv.GenerateStart) {
              if (event.req?.requestId != request.requestId) return;
              markGenerationStarted();
              return;
            }
            if (event is from_rwkv.IsGenerating) {
              if (event.modelID != modelID) return;
              if (event.isGenerating) {
                markGenerationStarted();
              } else if (!event.isGenerating && generationStarted) {
                if (!completer.isCompleted) completer.complete();
              }
              return;
            }
            if (event is from_rwkv.GenerateStop) {
              if (event.req?.requestId != request.requestId) return;
              if (!completer.isCompleted) completer.complete();
              return;
            }

            if (event is from_rwkv.ResponseBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetResponseBufferContent || req.modelID != modelID) return;
              if (!generationStarted && event.responseBufferContent.isEmpty) return;
              markGenerationStarted();
              lastContent = event.responseBufferContent;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              if (event.responseBufferContent.isEmpty) return;
              if (!generationStarted && event.responseBufferContent[0].isEmpty) return;
              markGenerationStarted();
              lastContent = event.responseBufferContent[0];
            }
          });
          P.rwkv.send(request);
          requestLatestBuffer();
          _pollingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
            requestLatestBuffer();
          });

          await completer.future.timeout(const Duration(minutes: 10), onTimeout: () {});

          _pollingTimer?.cancel();
          _pollingTimer = null;
          _broadcastSub?.cancel();
          _broadcastSub = null;

          resultCompleter.complete(lastContent);
        },
      );
    } on _ApiServerStoppingException {
      return _jsonResponse(_errorJson('API Server is stopping', type: 'server_unavailable'), status: 503);
    }

    final content = await resultCompleter.future;
    final completionText = content.startsWith(prompt) ? content.substring(prompt.length) : content;

    return _jsonResponse({
      'id': reqId,
      'object': 'text_completion',
      'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'model': modelName,
      'choices': [
        {'index': 0, 'text': completionText, 'finish_reason': 'stop'},
      ],
      'usage': {
        'prompt_tokens': 0,
        'completion_tokens': 0,
        'total_tokens': 0,
      },
    });
  }

  Future<void> _enqueueInference({
    required int modelID,
    required String reqId,
    required Future<void> Function() work,
  }) async {
    if (state.q == BackendState.stopping) {
      throw _ApiServerStoppingException();
    }

    final waiter = Completer<void>();
    _requestQueue.add(waiter);
    if (!_processing) {
      _processQueue();
    }
    await waiter.future;
    if (state.q == BackendState.stopping) {
      throw _ApiServerStoppingException();
    }
    activeRequest.q = true;
    _activeModelID = modelID;
    _activeInferenceId = reqId;
    try {
      await work();
    } finally {
      if (_activeInferenceId == reqId) {
        _activeInferenceCompleter = null;
        _activeModelID = null;
        _activeInferenceId = null;
      }
      activeRequest.q = false;
    }
  }

  Future<bool> _stopCurrentRequestInternal() async {
    if (!activeRequest.q) return false;
    final modelID = _activeModelID;
    _addLog('Stop requested for active API request');
    if (P.rwkv.isAlbatrossLoaded.q || modelID == null) {
      await P.rwkv.stop();
      return true;
    }
    P.rwkv.send(to_rwkv.Stop(modelID: modelID));
    return true;
  }

  void _completeActiveInferenceIfNeeded() {
    final completer = _activeInferenceCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }

  void _abortQueuedInferences() {
    final queued = List<Completer<void>>.from(_requestQueue);
    _requestQueue.clear();
    for (final waiter in queued) {
      if (waiter.isCompleted) continue;
      waiter.completeError(_ApiServerStoppingException());
    }
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    while (_requestQueue.isNotEmpty) {
      final next = _requestQueue.removeAt(0);
      next.complete();
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return activeRequest.q;
      });
    }
    _processing = false;
  }

  Future<shelf.Response> _serveDashboard(shelf.Request request) async {
    if (_dashboardHtmlCache == null) {
      try {
        _dashboardHtmlCache = await rootBundle.loadString('assets/api_server/dashboard.html');
      } catch (e) {
        qqe('Failed to load dashboard: $e');
        return shelf.Response.internalServerError(
          body: 'Dashboard not available',
          headers: _apiServerHeaders,
        );
      }
    }
    return shelf.Response.ok(
      _dashboardHtmlCache,
      headers: {..._apiServerHeaders, 'Content-Type': 'text/html; charset=utf-8'},
    );
  }
}

extension $ApiServer on _ApiServer {
  Future<void> start() async {
    if (!P.app.isDesktop.q) return;

    if (state.q == BackendState.running) {
      Alert.warning(S.current.api_server_running);
      return;
    }

    if (state.q != BackendState.stopped) return;

    final loaded = P.rwkv.loadedModels.q;
    if (loaded.isEmpty || !loaded.keys.any((e) => e.weightType == .chat)) {
      Alert.warning(S.current.api_server_select_model_first);
      return;
    }

    state.q = BackendState.starting;
    final p = port.q;

    try {
      final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, p);
      httpServer.autoCompress = false;
      httpServer.listen((HttpRequest request) {
        final isSSE = request.method == 'POST' && (request.uri.path.contains('completions'));
        if (isSSE) {
          request.response.bufferOutput = false;
        }
        shelf_io.handleRequest(request, _handleRequest);
      });
      server.q = httpServer;
      state.q = BackendState.running;
      _startTime = DateTime.now();
      requestCount.q = 0;
      logs.q = [];
      _addLog('Server started on port $p');
      qqr('API Server started at http://127.0.0.1:$p');
      Alert.success('API Server started on port $p');
    } catch (e) {
      qqe(e);
      state.q = BackendState.stopped;
      Alert.error('Failed to start API Server: $e');
    }
  }

  Future<void> stop() async {
    if (!P.app.isDesktop.q) return;
    final httpServer = server.q;
    if (httpServer == null) return;

    state.q = BackendState.stopping;
    _abortQueuedInferences();
    final hasActiveRequest = activeRequest.q;
    if (hasActiveRequest) {
      await _stopCurrentRequestInternal();
      _completeActiveInferenceIfNeeded();
    }
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _broadcastSub?.cancel();
    _broadcastSub = null;
    await httpServer.close();
    _activeInferenceCompleter = null;
    _activeModelID = null;
    _activeInferenceId = null;
    activeRequest.q = false;
    server.q = null;
    state.q = BackendState.stopped;
    _startTime = null;
    _addLog('Server stopped');
    qqr('API Server stopped');
    Alert.success('API Server stopped');
  }

  Future<void> stopActiveRequest({bool showAlert = true}) async {
    final stopped = await _stopCurrentRequestInternal();
    if (!showAlert) return;
    if (stopped) {
      Alert.success('Stopped active request');
      return;
    }
    Alert.warning('No active request');
  }
}
