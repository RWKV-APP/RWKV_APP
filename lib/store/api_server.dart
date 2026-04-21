part of 'p.dart';

const _apiServerDefaultPort = 52345;
const _apiServerStreamingFirstChunkDelay = Duration(milliseconds: 220);
const _apiServerFinalBufferTimeout = Duration(milliseconds: 500);

const _apiServerHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'X-Requested-With,content-type,Authorization',
};

class _ApiServerStoppingException implements Exception {}

class _ApiServerResponseBufferGate {
  _ApiServerResponseBufferGate({
    required String staleContent,
    String replacementPrefix = '',
  }) : _staleContent = staleContent,
       _replacementPrefix = replacementPrefix,
       _staleBufferReset = staleContent.isEmpty;

  final String _staleContent;
  final String _replacementPrefix;
  bool _staleBufferReset;
  bool stalePrefixSkipped = false;

  String freshContent(String full) {
    if (_staleBufferReset) return full;
    if (full.isEmpty) {
      _staleBufferReset = true;
      return '';
    }
    if (full == _staleContent) {
      stalePrefixSkipped = true;
      return '';
    }
    if (full.startsWith(_staleContent)) {
      stalePrefixSkipped = true;
      final fresh = full.substring(_staleContent.length);
      if (_replacementPrefix.isEmpty || fresh.startsWith(_replacementPrefix)) return fresh;
      return '$_replacementPrefix$fresh';
    }
    _staleBufferReset = true;
    return full;
  }
}

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
  late final accessibleUrls = qs<List<String>>([]);
}

extension _$ApiServer on _ApiServer {
  Future<void> _init() async {
    if (!P.app.isDesktop.q && !Platform.isAndroid) return;
    qq;
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _threeDigits(int value) {
    return value.toString().padLeft(3, '0');
  }

  String _formatLogTime(DateTime time) {
    final hour = _twoDigits(time.hour);
    final minute = _twoDigits(time.minute);
    final second = _twoDigits(time.second);
    final millisecond = _threeDigits(time.millisecond);
    return '$hour:$minute:$second.$millisecond';
  }

  void _addLog(String message) {
    final time = _formatLogTime(DateTime.now());
    final entry = '[$time] $message';
    final current = logs.q;
    logs.q = [...current.length > 200 ? current.sublist(current.length - 200) : current, entry];
  }

  String _modelId(FileInfo info) => info.fileName.replaceAll('.gguf', '');

  bool _isPreferredLanIpv4(String host) {
    if (host.startsWith('10.')) return true;
    if (host.startsWith('192.168.')) return true;
    if (!host.startsWith('172.')) return false;
    final parts = host.split('.');
    if (parts.length < 2) return false;
    final second = int.tryParse(parts[1]);
    if (second == null) return false;
    return second >= 16 && second <= 31;
  }

  bool _isApiServerSupportedPlatform() {
    if (Platform.isAndroid) return true;
    return P.app.isDesktop.q;
  }

  int _lanIpv4Score(String interfaceName, String host) {
    final name = interfaceName.toLowerCase();
    int virtualPenalty = 0;
    if (name.contains('docker') ||
        name.contains('vbox') ||
        name.contains('vmware') ||
        name.contains('bridge') ||
        name.contains('utun') ||
        name.contains('tun') ||
        name.contains('tap') ||
        name.contains('vethernet')) {
      virtualPenalty = 100;
    }

    if (host.startsWith('192.168.')) return virtualPenalty;
    if (host.startsWith('10.')) return virtualPenalty + 10;
    if (!host.startsWith('172.')) return virtualPenalty + 30;
    final parts = host.split('.');
    if (parts.length < 2) return virtualPenalty + 30;
    final second = int.tryParse(parts[1]);
    if (second == null) return virtualPenalty + 30;
    if (second >= 16 && second <= 31) return virtualPenalty + 20;
    return virtualPenalty + 30;
  }

  int _longestSuffixPrefixOverlap(String previous, String current) {
    if (previous.isEmpty || current.isEmpty) return 0;
    final maxOverlap = min(previous.length, current.length);
    for (final overlap in List<int>.generate(maxOverlap, (index) => maxOverlap - index)) {
      final suffix = previous.substring(previous.length - overlap);
      if (current.startsWith(suffix)) {
        return overlap;
      }
    }
    return 0;
  }

  Future<String?> _readLatestResponseBuffer({
    required int modelID,
    required List<String> messages,
  }) async {
    final request = to_rwkv.GetResponseBufferContent(messages: messages, modelID: modelID);
    P.rwkv.send(request);

    try {
      final response = await P.rwkv.broadcastStream
          .whereType<from_rwkv.ResponseBufferContent>()
          .firstWhere((event) => event.req == request)
          .timeout(_apiServerFinalBufferTimeout);
      return response.responseBufferContent;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshAccessibleUrls({int? portOverride}) async {
    if (!_isApiServerSupportedPlatform()) {
      accessibleUrls.q = [];
      return;
    }

    final portValue = portOverride ?? port.q;
    final urlScores = <String, int>{};

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final host = address.address;
          if (host.isEmpty) continue;
          final url = 'http://$host:$portValue';
          final score = _isPreferredLanIpv4(host) ? _lanIpv4Score(interface.name, host) : _lanIpv4Score(interface.name, host) + 50;
          final previousScore = urlScores[url];
          if (previousScore != null && previousScore <= score) continue;
          urlScores[url] = score;
        }
      }
    } catch (e) {
      qqe('Failed to refresh API server URLs: $e');
    }

    final entries = urlScores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = a.value.compareTo(b.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.compareTo(b.key);
      });
    final urls = entries.map((e) => e.key).toList();
    accessibleUrls.q = urls;
  }

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
      'urls': accessibleUrls.q,
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

    void sendDelta(String delta) {
      if (delta.isEmpty) return;
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

          final staleContent =
              await _readLatestResponseBuffer(
                modelID: modelID,
                messages: messages,
              ) ??
              '';
          final bufferGate = _ApiServerResponseBufferGate(staleContent: staleContent);
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

            String rawFull = '';
            bool eosFound = false;
            if (event is from_rwkv.ResponseBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetResponseBufferContent || req.modelID != modelID) return;
              rawFull = event.responseBufferContent;
              eosFound = event.eosFound;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              rawFull = event.responseBufferContent.isNotEmpty ? event.responseBufferContent[0] : '';
              eosFound = event.eosFound.isNotEmpty ? event.eosFound[0] : false;
            } else {
              return;
            }

            final hadStalePrefixSkipped = bufferGate.stalePrefixSkipped;
            final full = bufferGate.freshContent(rawFull);
            if (!hadStalePrefixSkipped && bufferGate.stalePrefixSkipped) {
              _addLog('chat stream ignored stale response buffer');
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
              sendDelta(full);
              return;
            }
            if (!full.startsWith(previousContent)) {
              final overlap = _longestSuffixPrefixOverlap(previousContent, full);
              previousContent = full;
              if (overlap > 0) {
                final delta = full.substring(overlap);
                sendDelta(delta);
                _addLog('chat stream prefix mismatch, overlap resynced');
                return;
              }
              sendDelta(full);
              _addLog('chat stream prefix mismatch, hard resynced');
              return;
            }
            if (full.length > previousContent.length) {
              final delta = full.substring(previousContent.length);
              previousContent = full;
              sendDelta(delta);
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
          final finalContent = await _readLatestResponseBuffer(
            modelID: modelID,
            messages: messages,
          );
          final freshFinalContent = finalContent == null ? null : bufferGate.freshContent(finalContent);
          if (freshFinalContent != null && freshFinalContent.isNotEmpty) {
            if (!firstChunkSent) {
              previousContent = freshFinalContent;
              firstChunkSent = true;
              sendDelta(freshFinalContent);
              _addLog('chat stream recovered final buffer');
            } else if (freshFinalContent.startsWith(previousContent) && freshFinalContent.length > previousContent.length) {
              final delta = freshFinalContent.substring(previousContent.length);
              previousContent = freshFinalContent;
              sendDelta(delta);
              _addLog('chat stream appended final buffer delta');
            } else if (freshFinalContent != previousContent) {
              final overlap = _longestSuffixPrefixOverlap(previousContent, freshFinalContent);
              previousContent = freshFinalContent;
              if (overlap > 0) {
                sendDelta(freshFinalContent.substring(overlap));
                _addLog('chat stream recovered final buffer with overlap');
              } else {
                sendDelta(freshFinalContent);
                _addLog('chat stream recovered final buffer with hard resync');
              }
            }
          }
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

          final staleContent =
              await _readLatestResponseBuffer(
                modelID: modelID,
                messages: messages,
              ) ??
              '';
          final bufferGate = _ApiServerResponseBufferGate(staleContent: staleContent);
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
              final full = bufferGate.freshContent(event.responseBufferContent);
              if (full.isEmpty) return;
              markGenerationStarted();
              lastContent = full;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              if (event.responseBufferContent.isEmpty) return;
              final full = bufferGate.freshContent(event.responseBufferContent[0]);
              if (full.isEmpty) return;
              markGenerationStarted();
              lastContent = full;
            }
          });
          P.rwkv.send(request);
          requestLatestBuffer();
          _pollingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
            requestLatestBuffer();
          });

          await completer.future.timeout(const Duration(minutes: 10), onTimeout: () {});

          final finalContent = await _readLatestResponseBuffer(
            modelID: modelID,
            messages: messages,
          );
          final freshFinalContent = finalContent == null ? null : bufferGate.freshContent(finalContent);
          if (freshFinalContent != null && freshFinalContent.isNotEmpty) {
            lastContent = freshFinalContent;
          }

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

    void sendDelta(String delta) {
      if (delta.isEmpty) return;
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

          final staleContent =
              await _readLatestResponseBuffer(
                modelID: modelID,
                messages: const <String>[],
              ) ??
              '';
          final bufferGate = _ApiServerResponseBufferGate(
            staleContent: staleContent,
            replacementPrefix: prompt,
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

            String rawFull = '';
            bool eosFound = false;
            if (event is from_rwkv.ResponseBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetResponseBufferContent || req.modelID != modelID) return;
              rawFull = event.responseBufferContent;
              eosFound = event.eosFound;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              rawFull = event.responseBufferContent.isNotEmpty ? event.responseBufferContent[0] : '';
              eosFound = event.eosFound.isNotEmpty ? event.eosFound[0] : false;
            } else {
              return;
            }

            final hadStalePrefixSkipped = bufferGate.stalePrefixSkipped;
            final full = bufferGate.freshContent(rawFull);
            if (!hadStalePrefixSkipped && bufferGate.stalePrefixSkipped) {
              _addLog('completion stream ignored stale response buffer');
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
              sendDelta(firstDelta);
              return;
            }
            if (!full.startsWith(previousContent)) {
              final overlap = _longestSuffixPrefixOverlap(previousContent, full);
              previousContent = full;
              if (overlap > 0) {
                final delta = full.substring(overlap);
                sendDelta(delta);
                _addLog('completion stream prefix mismatch, overlap resynced');
                return;
              }
              sendDelta(full);
              _addLog('completion stream prefix mismatch, hard resynced');
              return;
            }
            if (full.length > previousContent.length) {
              final delta = full.substring(previousContent.length);
              previousContent = full;
              sendDelta(delta);
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
          final finalContent = await _readLatestResponseBuffer(
            modelID: modelID,
            messages: const <String>[],
          );
          final freshFinalContent = finalContent == null ? null : bufferGate.freshContent(finalContent);
          if (freshFinalContent != null && freshFinalContent.isNotEmpty) {
            if (!firstChunkSent) {
              previousContent = freshFinalContent;
              firstChunkSent = true;
              final delta = freshFinalContent.startsWith(prompt) ? freshFinalContent.substring(prompt.length) : freshFinalContent;
              sendDelta(delta);
              _addLog('completion stream recovered final buffer');
            } else if (freshFinalContent.startsWith(previousContent) && freshFinalContent.length > previousContent.length) {
              final delta = freshFinalContent.substring(previousContent.length);
              previousContent = freshFinalContent;
              sendDelta(delta);
              _addLog('completion stream appended final buffer delta');
            } else if (freshFinalContent != previousContent) {
              final overlap = _longestSuffixPrefixOverlap(previousContent, freshFinalContent);
              previousContent = freshFinalContent;
              if (overlap > 0) {
                sendDelta(freshFinalContent.substring(overlap));
                _addLog('completion stream recovered final buffer with overlap');
              } else {
                final delta = freshFinalContent.startsWith(prompt) ? freshFinalContent.substring(prompt.length) : freshFinalContent;
                sendDelta(delta);
                _addLog('completion stream recovered final buffer with hard resync');
              }
            }
          }
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

          final staleContent =
              await _readLatestResponseBuffer(
                modelID: modelID,
                messages: const <String>[],
              ) ??
              '';
          final bufferGate = _ApiServerResponseBufferGate(
            staleContent: staleContent,
            replacementPrefix: prompt,
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
              final full = bufferGate.freshContent(event.responseBufferContent);
              if (full.isEmpty) return;
              markGenerationStarted();
              lastContent = full;
            } else if (event is from_rwkv.ResponseBatchBufferContent) {
              final req = event.req;
              if (req is! to_rwkv.GetBatchResponseBufferContent || req.modelID != modelID) return;
              if (event.responseBufferContent.isEmpty) return;
              final full = bufferGate.freshContent(event.responseBufferContent[0]);
              if (full.isEmpty) return;
              markGenerationStarted();
              lastContent = full;
            }
          });
          P.rwkv.send(request);
          requestLatestBuffer();
          _pollingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
            requestLatestBuffer();
          });

          await completer.future.timeout(const Duration(minutes: 10), onTimeout: () {});

          final finalContent = await _readLatestResponseBuffer(
            modelID: modelID,
            messages: const <String>[],
          );
          final freshFinalContent = finalContent == null ? null : bufferGate.freshContent(finalContent);
          if (freshFinalContent != null && freshFinalContent.isNotEmpty) {
            lastContent = freshFinalContent;
          }

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
    if (!_isApiServerSupportedPlatform()) return;

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
      final httpServer = await HttpServer.bind(InternetAddress.anyIPv4, p);
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
      await _refreshAccessibleUrls(portOverride: p);
      _addLog('Server started on port $p');
      final urls = accessibleUrls.q;
      final lanText = urls.isEmpty ? 'no LAN URL detected' : urls.join(', ');
      _addLog('LAN URLs: $lanText');
      if (Platform.isAndroid) {
        qqr('API Server started on Android: $lanText');
        await WakelockPlus.enable();
      } else {
        qqr('API Server started on LAN: $lanText');
      }
      Alert.success(S.current.api_server_started_on_port(p));
    } catch (e) {
      qqe(e);
      state.q = BackendState.stopped;
      accessibleUrls.q = [];
      Alert.error(S.current.api_server_failed_to_start(e));
    }
  }

  Future<void> stop() async {
    if (!_isApiServerSupportedPlatform()) return;
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
    accessibleUrls.q = [];
    if (Platform.isAndroid) {
      await WakelockPlus.disable();
    }
    _addLog('Server stopped');
    qqr('API Server stopped');
    Alert.success(S.current.api_server_stopped);
  }

  Future<void> stopActiveRequest({bool showAlert = true}) async {
    final stopped = await _stopCurrentRequestInternal();
    if (!showAlert) return;
    if (stopped) {
      Alert.success(S.current.api_server_active_request_stopped);
      return;
    }
    Alert.warning(S.current.api_server_no_active_request);
  }

  void clearLogs() {
    logs.q = [];
  }
}
