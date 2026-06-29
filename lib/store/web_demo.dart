part of 'p.dart';

const int _webDemoCloudTimeoutSeconds = 120;
const String _webDemoProtocolRwkvLightningV1 = "rwkv_lightning_v1";
const String _webDemoProtocolOpenAi = "openai";
const String _webDemoDefault7BBaseUrl = "http://47.115.88.183:1801/v1/chat/completions";
const String _webDemoDefault13BBaseUrl = "http://47.115.88.183:1800/v1/chat/completions";
const int _webDemoLightningMaxTokensCap = 4096;
const int _webDemoDefaultBatchSize = 30;
const int _webDemoMaxBatchSize = 30;
const double _webDemoDefaultPreviewScalePercent = 35;
const double _webDemoDefaultPreviewAutoScrollSeconds = 5;
const double _webDemoDefaultTemperature = 1;
const double _webDemoDefaultTopP = .5;
const double _webDemoDefaultPresencePenalty = 1;
const double _webDemoDefaultFrequencyPenalty = .1;
const double _webDemoDefaultPenaltyDecay = .99;
const Duration _webDemoStreamingResultsSyncInterval = Duration(milliseconds: 120);
const List<String> _webDemoLightningStopTokens = <String>["\nUser:"];

double _webDemoDefaultArgument(Argument argument) {
  return switch (argument) {
    Argument.temperature => _webDemoDefaultTemperature,
    Argument.topP => _webDemoDefaultTopP,
    Argument.presencePenalty => _webDemoDefaultPresencePenalty,
    Argument.frequencyPenalty => _webDemoDefaultFrequencyPenalty,
    Argument.penaltyDecay => _webDemoDefaultPenaltyDecay,
    Argument.maxLength => Argument.maxLength.defaults,
    Argument.topK => Argument.topK.defaults,
    Argument.batchCount => Argument.batchCount.defaults,
  };
}

enum WebDemoBackendMode {
  cloud7b,
  cloud13b,
  local,
}

@immutable
class WebDemoRun {
  final String prompt;
  final DateTime createdAt;
  final WebDemoBackendMode backendMode;
  final int batchSize;
  final String rawDecodeParams;

  const WebDemoRun({
    required this.prompt,
    required this.createdAt,
    required this.backendMode,
    required this.batchSize,
    required this.rawDecodeParams,
  });
}

@immutable
class WebDemoResult {
  final int index;
  final String raw;
  final bool streaming;
  final String? error;
  final int? messageId;

  const WebDemoResult({
    required this.index,
    required this.raw,
    required this.streaming,
    this.error,
    this.messageId,
  });

  WebDemoHtmlDocument? get document => extractFirstWebDemoHtml(raw);

  String? get html => document?.html;

  int get bytes => utf8.encode(raw).length;

  int get tokens => _estimateWebDemoTokens(raw);

  WebDemoResult copyWith({
    String? raw,
    bool? streaming,
    String? error,
    bool clearError = false,
    int? messageId,
  }) {
    return WebDemoResult(
      index: index,
      raw: raw ?? this.raw,
      streaming: streaming ?? this.streaming,
      error: clearError ? null : (error ?? this.error),
      messageId: messageId ?? this.messageId,
    );
  }
}

class _WebDemo {
  StreamSubscription<from_rwkv.ResponseBatchBufferContent>? _localSubscription;
  StreamSubscription<IsGenerating>? _localGeneratingSubscription;
  http.Client? _cloudClient;
  String _activeContent = "";
  List<String> _activeOutputs = const <String>[];
  int? _activeReceiveId;
  String? _hydratedSignature;
  Timer? _streamingResultsSyncTimer;
  bool _streamingResultsSyncPending = false;
  bool _localSamplerParamsApplied = false;

  late final promptController = TextEditingController(text: "");
  late final promptFocusNode = FocusNode();

  late final promptInput = qs("");
  late final backendMode = qs(
    Config.webDemoOfficialApiKey.trim().isNotEmpty ? WebDemoBackendMode.cloud7b : WebDemoBackendMode.local,
  );
  late final useOfficialCloud = qs(Config.webDemoOfficialApiKey.trim().isNotEmpty);
  late final promptTemplate = qs(webDemoDefaultPromptTemplate);
  late final pendingHtmlContext = qs<String?>(null);
  late final lastSavedHtmlPath = qs<String?>(null);
  late final lastError = qs<String?>(null);
  late final active = qs(false);
  late final batchSize = qs<int>(_webDemoDefaultBatchSize);
  late final previewScalePercent = qs(_webDemoDefaultPreviewScalePercent);
  late final previewAutoScrollSeconds = qs(_webDemoDefaultPreviewAutoScrollSeconds);
  late final arguments = qsff<Argument, double>((ref, argument) => _webDemoDefaultArgument(argument));
  late final currentRun = qs<WebDemoRun?>(null);
  late final results = qs<List<WebDemoResult>>(const <WebDemoResult>[]);
  late final resultByIndex = Provider.family<WebDemoResult?, int>((ref, index) {
    final results = ref.watch(this.results);
    if (index < 0 || index >= results.length) return null;
    return results[index];
  });
}

extension $WebDemo on _WebDemo {
  Future<void> _init() async {}

  bool get officialCloudConfigured => Config.webDemoOfficialApiKey.trim().isNotEmpty;

  bool get officialCloudActive => P.app.pageKey.q == .webDemo && _isCloudBackend(backendMode.q) && officialCloudConfigured;

  void setBackendMode(WebDemoBackendMode value) {
    if (active.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    backendMode.q = value;
    useOfficialCloud.q = _isCloudBackend(value);
  }

  void setUseOfficialCloud(bool value) {
    setBackendMode(value ? WebDemoBackendMode.cloud7b : WebDemoBackendMode.local);
  }

  void setPromptInput(String value) {
    promptInput.q = value;
  }

  void setBatchSize(num value) {
    final next = value.round().clamp(1, _webDemoMaxBatchSize).toInt();
    if (batchSize.q == next) return;
    batchSize.q = next;
  }

  void setPreviewScalePercent(num value) {
    final next = value.toDouble().clamp(20, 100).toDouble();
    if (previewScalePercent.q == next) return;
    previewScalePercent.q = next;
  }

  void setPreviewAutoScrollSeconds(num value) {
    final next = value.toDouble().clamp(0, 10).toDouble();
    if (previewAutoScrollSeconds.q == next) return;
    previewAutoScrollSeconds.q = next;
  }

  void setPromptTemplate(String value) {
    promptTemplate.q = value;
  }

  void resetPromptTemplate() {
    promptTemplate.q = webDemoDefaultPromptTemplate;
  }

  void syncArgument(Argument argument, double value) {
    switch (argument) {
      case Argument.maxLength:
      case Argument.temperature:
      case Argument.topP:
      case Argument.presencePenalty:
      case Argument.frequencyPenalty:
      case Argument.penaltyDecay:
        arguments(argument).q = value;
      case Argument.topK:
      case Argument.batchCount:
        break;
    }
  }

  SamplerAndPenaltyParam currentSamplerAndPenaltyParam() {
    return SamplerAndPenaltyParam(
      temperature: arguments(Argument.temperature).q,
      topP: arguments(Argument.topP).q,
      presencePenalty: arguments(Argument.presencePenalty).q,
      frequencyPenalty: arguments(Argument.frequencyPenalty).q,
      penaltyDecay: arguments(Argument.penaltyDecay).q,
    );
  }

  String resolveDecodeParamsSnapshotRaw() {
    return <SamplerAndPenaltyParam>[currentSamplerAndPenaltyParam()].rawDecodeParams;
  }

  Future<void> sendPresetPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;
    promptInput.q = trimmed;
    promptController.text = trimmed;
    promptController.selection = TextSelection.collapsed(offset: trimmed.length);
    await sendFromCurrentInput();
  }

  Future<void> sendFromCurrentInput() async {
    final raw = promptInput.q.trim();
    if (raw.isEmpty) {
      Alert.info(S.current.chat_empty_message);
      return;
    }

    promptFocusNode.unfocus();
    promptInput.q = "";
    promptController.text = "";
    final sourceHtml = pendingHtmlContext.q;
    pendingHtmlContext.q = null;
    await sendPrompt(raw, sourceHtml: sourceHtml);
  }

  Future<void> sendPrompt(String raw, {String? sourceHtml}) async {
    if (active.q || P.rwkvGeneration.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final backend = backendMode.q;
    final usingCloud = _isCloudBackend(backend);
    if (usingCloud && !officialCloudConfigured) {
      Alert.warning("Official Web Demo endpoint key is not configured");
      return;
    }
    if (!usingCloud && !checkModelSelection(preferredDemoType: .chat)) return;

    final requestedBatchSize = batchSize.q.clamp(1, _webDemoMaxBatchSize);
    if (!usingCloud && requestedBatchSize > 1 && !P.chat.batchInferenceAvailable.q) {
      Alert.info(S.current.this_model_does_not_support_batch_inference);
      return;
    }

    _cancelLocalSubscriptions();
    _cloudClient?.close();
    _cloudClient = null;
    _cancelStreamingResultsSync();
    lastError.q = null;

    final prompt = sourceHtml == null || sourceHtml.trim().isEmpty
        ? buildWebDemoPrompt(template: promptTemplate.q, request: raw)
        : buildWebDemoEditPrompt(html: sourceHtml, instruction: raw);
    final receiveId = await _createWebDemoMessagePair(
      userContent: raw,
      batchSize: requestedBatchSize,
      usingCloud: usingCloud,
    );
    if (receiveId == null) return;

    final run = WebDemoRun(
      prompt: raw,
      createdAt: DateTime.now(),
      backendMode: backend,
      batchSize: requestedBatchSize,
      rawDecodeParams: resolveDecodeParamsSnapshotRaw(),
    );
    currentRun.q = run;
    _activeReceiveId = receiveId;
    _activeOutputs = List<String>.filled(requestedBatchSize, "");
    _activeContent = "";
    results.q = List<WebDemoResult>.generate(
      requestedBatchSize,
      (int index) => WebDemoResult(index: index, raw: "", streaming: true, messageId: receiveId),
    );

    if (usingCloud) {
      unawaited(_runCloud(prompt: prompt, batchSize: requestedBatchSize, receiveId: receiveId));
      return;
    }

    _runLocal(prompt: prompt, batchSize: requestedBatchSize, receiveId: receiveId);
  }

  Future<void> prepareContinuation({
    required String html,
  }) async {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      Alert.warning("No HTML found");
      return;
    }
    pendingHtmlContext.q = trimmed;
    const nextPrompt = "Modify this page: ";
    promptInput.q = nextPrompt;
    promptController.text = nextPrompt;
    promptController.selection = TextSelection.collapsed(offset: promptController.text.length);
    if (P.app.pageKey.q != .webDemo) {
      push(.webDemo);
    }
    await 100.msLater;
    promptFocusNode.requestFocus();
    Alert.info("HTML context ready");
  }

  Future<void> prepareContinuationFromResult(WebDemoResult result) async {
    final html = result.html;
    if (html == null || html.trim().isEmpty) {
      Alert.warning("No HTML found");
      return;
    }
    await prepareContinuation(html: html);
  }

  Future<void> openResultInSystemBrowser(WebDemoResult result) async {
    final html = result.html;
    if (html == null || html.trim().isEmpty) {
      Alert.warning("No HTML found");
      return;
    }
    await openHtmlInSystemBrowser(html: html, label: "web-${result.index + 1}");
  }

  Future<void> saveResultHtml(WebDemoResult result) async {
    final html = result.html;
    if (html == null || html.trim().isEmpty) {
      Alert.warning("No HTML found");
      return;
    }
    await saveHtml(html: html, label: "web-${result.index + 1}");
    Alert.success("HTML saved");
  }

  Future<void> copyResultSource(WebDemoResult result) async {
    final content = result.html ?? result.raw;
    if (content.trim().isEmpty) {
      Alert.warning("No source to copy");
      return;
    }
    await Clipboard.setData(ClipboardData(text: content));
    Alert.success("Result copied");
  }

  Future<void> openHtmlInSystemBrowser({
    required String html,
    required String label,
  }) async {
    final file = await saveHtml(html: html, label: label);
    final launched = await launchUrl(Uri.file(file.path), mode: LaunchMode.externalApplication);
    if (!launched) {
      Alert.error("Failed to open HTML");
    }
  }

  Future<File> saveHtml({
    required String html,
    required String label,
  }) async {
    Directory? root = P.app.effectiveDocumentsDir.q;
    root ??= await getApplicationDocumentsDirectory();
    final file = await writeWebDemoHtmlFile(root: root, html: html, label: label);
    lastSavedHtmlPath.q = file.path;
    return file;
  }

  Future<void> stopActive() async {
    final receiveId = _activeReceiveId;
    _cloudClient?.close();
    _cloudClient = null;
    _cancelLocalSubscriptions();
    await P.rwkvGeneration.stop();
    if (receiveId != null) {
      _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoStopped");
      return;
    }
    _restoreLocalSamplerParamsIfNeeded();
    P.rwkvGeneration.generating.q = false;
    active.q = false;
    _markResultsStreaming(false);
  }

  void hydrateFromCurrentConversation({bool force = false}) {
    if (active.q) return;

    final orderedIds = P.msg.msgNode.q.allMsgIdsFromRoot.where((int id) => id != 0).toList();
    final signature = _buildHydrationSignature(orderedIds);
    if (!force && signature == _hydratedSignature) return;
    _hydratedSignature = signature;

    final hydratedResults = <WebDemoResult>[];
    WebDemoRun? lastRun;
    for (int i = 0; i < orderedIds.length; i++) {
      final msg = P.msg.pool.q[orderedIds[i]];
      if (msg == null) continue;
      if (msg.isMine) continue;
      if (msg.runningMode != "web_demo") continue;

      final parts = splitWebDemoBatchContent(msg.content);
      final prompt = _promptForWebDemoMessage(botMessage: msg, orderedIds: orderedIds, botIndex: i);
      lastRun = WebDemoRun(
        prompt: prompt,
        createdAt: DateTime.fromMillisecondsSinceEpoch(msg.id),
        backendMode: _backendModeForMessage(msg),
        batchSize: parts.length,
        rawDecodeParams: msg.rawDecodeParams ?? "",
      );
      for (int slot = 0; slot < parts.length; slot++) {
        hydratedResults.add(
          WebDemoResult(
            index: hydratedResults.length,
            raw: parts[slot],
            streaming: msg.changing,
            messageId: msg.id,
          ),
        );
      }
    }

    currentRun.q = lastRun;
    results.q = hydratedResults;
  }

  Future<int?> _createWebDemoMessagePair({
    required String userContent,
    required int batchSize,
    required bool usingCloud,
  }) async {
    final userId = DateTime.now().millisecondsSinceEpoch;
    final userMsg = Message(
      id: userId,
      content: userContent,
      isMine: true,
      paused: false,
    );
    await P.msg._syncMsg(userId, userMsg);
    final parentNode = P.msg.msgNode.q.rootAdd(MsgNode(userId));

    final receiveId = userId + 1;
    final currentModel = P.rwkvModel.latest.q;
    final modelName = usingCloud
        ? "Official RWKV Web Demo ${_cloudModelLabel(backendMode.q)}"
        : P.albatrossRuntime.enabled.q
        ? "Albatross"
        : currentModel?.name;
    final receiveMsg = Message(
      id: receiveId,
      content: "",
      isMine: false,
      changing: true,
      paused: false,
      modelName: modelName,
      runningMode: "web_demo",
      rawDecodeParams: resolveDecodeParamsSnapshotRaw(),
      batchSlotLabels: batchSize > 1 ? List<String>.generate(batchSize, (int index) => "Web ${index + 1}") : null,
    );
    P.msg.pool.q[receiveId] = receiveMsg;
    parentNode.add(MsgNode(receiveId));
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
    P.chat.receiveId.q = receiveId;
    P.rwkvGeneration.generating.q = true;
    active.q = true;
    P.chat._scheduleRefreshLiveTokenCounts(messageId: receiveId, liveBotContent: "");
    return receiveId;
  }

  void _runLocal({
    required String prompt,
    required int batchSize,
    required int receiveId,
  }) {
    _applyLocalSamplerParamsIfNeeded();
    final outputs = List<String>.filled(batchSize, "");
    _localSubscription = P.rwkvGeneration
        .completion(
          prompt,
          batchSize: batchSize,
          maxLength: _maxTokensForLocal,
          overrideDecodeParams: _decodeParamsForAlbatross(),
        )
        .listen(
          (response) {
            for (int i = 0; i < response.responseBufferContent.length && i < outputs.length; i++) {
              outputs[i] = stripWebDemoPromptPrefix(content: response.responseBufferContent[i], prompt: prompt);
            }
            _setActiveOutputs(outputs: outputs, receiveId: receiveId);
            final complete = response.eosFound.length >= batchSize && response.eosFound.take(batchSize).every((item) => item);
            if (!complete) return;
            _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoLocalComplete");
          },
          onError: (Object error, StackTrace stackTrace) {
            _finishCurrentMessage(
              receiveId: receiveId,
              content: _activeContent,
              callingFunction: "webDemoLocalError",
              error: error.toString(),
            );
          },
        );
    _localGeneratingSubscription = P.rwkvBridge.broadcastStream
        .whereType<IsGenerating>()
        .where((event) => !event.isGenerating)
        .take(1)
        .listen((_) {
          _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoLocalStopped");
        });
  }

  Future<void> _runCloud({
    required String prompt,
    required int batchSize,
    required int receiveId,
  }) async {
    if (_officialCloudProtocol == _webDemoProtocolRwkvLightningV1) {
      await _runRwkvLightningCloud(prompt: prompt, batchSize: batchSize, receiveId: receiveId);
      return;
    }
    await _runOpenAiCloud(prompt: prompt, batchSize: batchSize, receiveId: receiveId);
  }

  Future<void> _runRwkvLightningCloud({
    required String prompt,
    required int batchSize,
    required int receiveId,
  }) async {
    final client = _createDirectCloudClient();
    _cloudClient = client;
    final outputs = List<String>.filled(batchSize, "");

    try {
      final request = http.Request("POST", _officialChatCompletionsUri());
      request.headers["Accept"] = "*/*";
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode({
        "contents": List<String>.filled(batchSize, prompt),
        "max_tokens": _maxTokensForCloud,
        "stop_tokens": _webDemoLightningStopTokens,
        "temperature": arguments(Argument.temperature).q,
        "top_k": arguments(Argument.topK).q.round(),
        "top_p": arguments(Argument.topP).q,
        "pad_zero": true,
        "alpha_presence": arguments(Argument.presencePenalty).q,
        "alpha_frequency": arguments(Argument.frequencyPenalty).q,
        "alpha_decay": arguments(Argument.penaltyDecay).q,
        "chunk_size": 8,
        "stream": true,
        "password": Config.webDemoOfficialApiKey,
      });

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: _webDemoCloudTimeoutSeconds));
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        final responseBody = await streamedResponse.stream.bytesToString();
        throw "${streamedResponse.statusCode}: $responseBody";
      }

      final parser = AlbatrossSseParser();
      final doneSlots = List<bool>.filled(batchSize, false);
      await for (final rawChunk in streamedResponse.stream.transform(utf8.decoder)) {
        final events = parser.add(rawChunk);
        for (final event in events) {
          if (event.done) {
            _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoLightningDone");
            return;
          }
          bool changed = false;
          for (final choice in event.choices) {
            if (choice.index < 0 || choice.index >= outputs.length) continue;
            if (choice.content.isNotEmpty) {
              outputs[choice.index] = outputs[choice.index] + choice.content;
              changed = true;
            }
            if (choice.finishReason != null) doneSlots[choice.index] = true;
          }
          if (changed) {
            _setActiveOutputs(outputs: outputs, receiveId: receiveId);
          }
          if (doneSlots.every((done) => done)) {
            _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoLightningFinished");
            return;
          }
        }
      }
      if (_activeContent.trim().isEmpty) {
        throw "RWKV Lightning response did not include content";
      }
      _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoLightningStreamEnd");
    } catch (e) {
      _finishCurrentMessage(
        receiveId: receiveId,
        content: _activeContent,
        callingFunction: "webDemoLightningError",
        error: e.toString(),
      );
    } finally {
      client.close();
      if (_cloudClient == client) {
        _cloudClient = null;
      }
    }
  }

  Future<void> _runOpenAiCloud({
    required String prompt,
    required int batchSize,
    required int receiveId,
  }) async {
    final client = http.Client();
    _cloudClient = client;
    final outputs = List<String>.filled(batchSize, "");

    try {
      final request = http.Request("POST", _officialChatCompletionsUri());
      request.headers["Accept"] = "*/*";
      request.headers["Content-Type"] = "application/json";
      request.headers["Authorization"] = "Bearer ${Config.webDemoOfficialApiKey}";
      request.body = jsonEncode({
        "model": _cloudModelName,
        "messages": [
          {"role": "user", "content": prompt},
        ],
        "stream": true,
        "n": batchSize,
        ..._decodeParamsForCloud(),
      });

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: _webDemoCloudTimeoutSeconds));
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        final body = await streamedResponse.stream.bytesToString();
        throw "${streamedResponse.statusCode}: $body";
      }

      final parser = AlbatrossSseParser();
      await for (final rawChunk in streamedResponse.stream.transform(utf8.decoder)) {
        final events = parser.add(rawChunk);
        for (final event in events) {
          if (event.done) {
            _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoCloudDone");
            return;
          }
          bool changed = false;
          for (final choice in event.choices) {
            if (choice.index < 0 || choice.index >= outputs.length) continue;
            if (choice.content.isEmpty) continue;
            outputs[choice.index] = outputs[choice.index] + choice.content;
            changed = true;
          }
          if (changed) {
            _setActiveOutputs(outputs: outputs, receiveId: receiveId);
          }
        }
      }
      _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoCloudStreamEnd");
    } catch (e) {
      _finishCurrentMessage(
        receiveId: receiveId,
        content: _activeContent,
        callingFunction: "webDemoCloudError",
        error: e.toString(),
      );
    } finally {
      client.close();
      if (_cloudClient == client) {
        _cloudClient = null;
      }
    }
  }

  void _setActiveOutputs({
    required List<String> outputs,
    required int receiveId,
  }) {
    _activeOutputs = List<String>.from(outputs);
    _activeContent = _joinOutputs(_activeOutputs);
    _syncActiveMessageContent(receiveId: receiveId);
    _scheduleStreamingResultsSync();
  }

  void _syncActiveMessageContent({
    required int receiveId,
  }) {
    final current = P.msg.pool.q[receiveId];
    if (current == null || !current.changing) return;
    P.msg.pool.q = {...P.msg.pool.q, receiveId: current.copyWith(content: _activeContent)};
  }

  void _syncResultsFromOutputs({
    required bool streaming,
  }) {
    final current = results.q;
    final next = <WebDemoResult>[];
    for (int i = 0; i < _activeOutputs.length; i++) {
      final existing = i < current.length
          ? current[i]
          : WebDemoResult(index: i, raw: "", streaming: streaming, messageId: _activeReceiveId);
      final raw = _activeOutputs[i];
      if (existing.raw == raw && existing.streaming == streaming && existing.error == null) {
        next.add(existing);
        continue;
      }
      next.add(existing.copyWith(raw: raw, streaming: streaming, clearError: true));
    }
    results.q = next;
  }

  void _scheduleStreamingResultsSync() {
    _streamingResultsSyncPending = true;
    if (_streamingResultsSyncTimer != null) return;
    _streamingResultsSyncTimer = Timer(_webDemoStreamingResultsSyncInterval, () {
      _streamingResultsSyncTimer = null;
      if (!_streamingResultsSyncPending) return;
      _streamingResultsSyncPending = false;
      _syncResultsFromOutputs(streaming: true);
    });
  }

  void _flushStreamingResultsSync({
    required bool streaming,
  }) {
    _cancelStreamingResultsSync();
    _syncResultsFromOutputs(streaming: streaming);
  }

  void _cancelStreamingResultsSync() {
    _streamingResultsSyncTimer?.cancel();
    _streamingResultsSyncTimer = null;
    _streamingResultsSyncPending = false;
  }

  void _markResultsStreaming(bool streaming, {String? error}) {
    results.q = [
      for (final result in results.q) result.copyWith(streaming: streaming, error: error),
    ];
  }

  http.Client _createDirectCloudClient() {
    final ioClient = HttpClient();
    ioClient.findProxy = (uri) => "DIRECT";
    return http_io.IOClient(ioClient);
  }

  Uri _officialChatCompletionsUri() {
    final base = _effectiveOfficialBaseUrl.endsWith("/")
        ? _effectiveOfficialBaseUrl.substring(0, _effectiveOfficialBaseUrl.length - 1)
        : _effectiveOfficialBaseUrl;
    if (base.endsWith("/chat/completions")) return Uri.parse(base);
    if (_officialCloudProtocol == _webDemoProtocolRwkvLightningV1 && !base.endsWith("/v1")) {
      return Uri.parse("$base/v1/chat/completions");
    }
    if (base.endsWith("/v1")) return Uri.parse("$base/chat/completions");
    return Uri.parse("$base/chat/completions");
  }

  String get _officialCloudProtocol {
    final protocol = Config.webDemoOfficialProtocol.trim().toLowerCase();
    if (protocol == _webDemoProtocolOpenAi) return protocol;
    return _webDemoProtocolRwkvLightningV1;
  }

  String get _effectiveOfficialBaseUrl {
    final configured = Config.webDemoOfficialBaseUrl.trim();
    if (_officialCloudProtocol == _webDemoProtocolRwkvLightningV1 && backendMode.q == WebDemoBackendMode.cloud13b) {
      return _webDemoDefault13BBaseUrl;
    }
    if (_officialCloudProtocol == _webDemoProtocolRwkvLightningV1 && backendMode.q == WebDemoBackendMode.cloud7b) {
      return _webDemoDefault7BBaseUrl;
    }
    final model = Config.webDemoOfficialModel.trim().toLowerCase();
    if (configured == _webDemoDefault7BBaseUrl && (model == "13b" || model == "13.3b")) {
      return _webDemoDefault13BBaseUrl;
    }
    return configured;
  }

  Map<String, Object?> _decodeParamsForCloud() {
    final param = currentSamplerAndPenaltyParam();
    return {
      "temperature": param.temperature,
      "top_p": param.topP,
      "max_tokens": _maxTokensForCloud,
      "presence_penalty": param.presencePenalty,
      "frequency_penalty": param.frequencyPenalty,
    };
  }

  Map<String, Object?> _decodeParamsForAlbatross() {
    final param = currentSamplerAndPenaltyParam();
    return {
      "temperature": param.temperature,
      "top_k": arguments(Argument.topK).q,
      "top_p": param.topP,
      "alpha_presence": param.presencePenalty,
      "alpha_frequency": param.frequencyPenalty,
      "alpha_decay": param.penaltyDecay,
      "max_tokens": arguments(Argument.maxLength).q,
    };
  }

  int get _maxTokensForCloud {
    final maxTokens = arguments(Argument.maxLength).q.round();
    final resolved = maxTokens <= 0 ? Argument.maxLength.defaults.round() : maxTokens;
    if (_officialCloudProtocol != _webDemoProtocolRwkvLightningV1) return resolved;
    if (resolved <= _webDemoLightningMaxTokensCap) return resolved;
    return _webDemoLightningMaxTokensCap;
  }

  int get _maxTokensForLocal {
    final maxTokens = arguments(Argument.maxLength).q.round();
    if (maxTokens > 0) return maxTokens;
    return Argument.maxLength.defaults.round();
  }

  void _applyLocalSamplerParamsIfNeeded() {
    if (P.albatrossRuntime.enabled.q) return;
    _syncSamplerParamsToLoadedModels(
      currentSamplerAndPenaltyParam(),
      topK: arguments(Argument.topK).q,
    );
    _localSamplerParamsApplied = true;
  }

  void _restoreLocalSamplerParamsIfNeeded() {
    if (!_localSamplerParamsApplied) return;
    _localSamplerParamsApplied = false;
    _syncSamplerParamsToLoadedModels(
      P.rwkvParams.currentSamplerAndPenaltyParam(),
      topK: P.rwkvParams.arguments(Argument.topK).q,
    );
  }

  void _syncSamplerParamsToLoadedModels(SamplerAndPenaltyParam param, {required double topK}) {
    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      P.rwkvBridge.send(
        to_rwkv.SetSamplerParams(
          temperature: param.temperature,
          topK: topK.round(),
          topP: param.topP,
          presencePenalty: param.presencePenalty,
          frequencyPenalty: param.frequencyPenalty,
          penaltyDecay: param.penaltyDecay,
          modelID: modelID,
        ),
      );
    }
  }

  String _joinOutputs(List<String> outputs) {
    if (outputs.length <= 1) return outputs.firstOrNull ?? "";
    return buildBatchContent(outputs);
  }

  void _finishCurrentMessage({
    required int receiveId,
    required String content,
    required String callingFunction,
    String? error,
  }) {
    _restoreLocalSamplerParamsIfNeeded();
    final current = P.msg.pool.q[receiveId];
    if (current == null || !current.changing) return;
    _cancelLocalSubscriptions();
    if (error != null && error.isNotEmpty) {
      lastError.q = error;
      Alert.error(error);
    }
    final finalContent = content.trim().isEmpty && error != null ? "Web Demo failed: $error" : content;
    final (double? snapshotPrefillSpeed, double? snapshotDecodeSpeed) = P.chat._currentSpeedSnapshotForStore();
    P.chat._updateMessageById(
      id: receiveId,
      content: finalContent,
      changing: false,
      prefillSpeed: snapshotPrefillSpeed ?? current.prefillSpeed,
      decodeSpeed: snapshotDecodeSpeed ?? current.decodeSpeed,
      callingFunction: callingFunction,
    );
    P.rwkvGeneration.generating.q = false;
    active.q = false;
    _activeReceiveId = null;
    _activeContent = finalContent;
    if (_activeOutputs.isEmpty && finalContent.isNotEmpty) {
      _activeOutputs = splitWebDemoBatchContent(finalContent);
    }
    _flushStreamingResultsSync(streaming: false);
    if (error != null && error.isNotEmpty) {
      _markResultsStreaming(false, error: error);
    }
    P.chat._scheduleRefreshLiveTokenCounts(messageId: receiveId, liveBotContent: finalContent);
    unawaited(
      P.chat._refreshTokenCountsForMessage(
        messageId: receiveId,
        overrideBotContent: finalContent,
        persistToMessage: true,
      ),
    );
    unawaited(P.conversation.updateCurrentConvSubtitleFromResponseContent(finalContent, force: true));
  }

  void _cancelLocalSubscriptions() {
    _localSubscription?.cancel();
    _localSubscription = null;
    _localGeneratingSubscription?.cancel();
    _localGeneratingSubscription = null;
  }

  String _buildHydrationSignature(List<int> orderedIds) {
    final buffer = StringBuffer();
    for (final id in orderedIds) {
      final msg = P.msg.pool.q[id];
      if (msg == null) continue;
      if (msg.runningMode != "web_demo") continue;
      buffer.write(id);
      buffer.write(":");
      buffer.write(msg.content.hashCode);
      buffer.write(":");
      buffer.write(msg.changing);
      buffer.write("|");
    }
    return buffer.toString();
  }

  String _promptForWebDemoMessage({
    required Message botMessage,
    required List<int> orderedIds,
    required int botIndex,
  }) {
    final parent = P.msg.msgNode.q.findParentByMsgId(botMessage.id);
    if (parent != null) {
      final parentMsg = P.msg.pool.q[parent.id];
      if (parentMsg != null && parentMsg.isMine) return parentMsg.content;
    }

    for (int i = botIndex - 1; i >= 0; i--) {
      final candidate = P.msg.pool.q[orderedIds[i]];
      if (candidate == null) continue;
      if (candidate.isMine) return candidate.content;
    }
    return "";
  }

  WebDemoBackendMode _backendModeForMessage(Message message) {
    final modelName = message.modelName?.toLowerCase() ?? "";
    if (modelName.contains("13.3") || modelName.contains("13b")) {
      return WebDemoBackendMode.cloud13b;
    }
    if (modelName.contains("official") || modelName.contains("cloud")) {
      return WebDemoBackendMode.cloud7b;
    }
    return WebDemoBackendMode.local;
  }

  bool _isCloudBackend(WebDemoBackendMode mode) {
    return mode == WebDemoBackendMode.cloud7b || mode == WebDemoBackendMode.cloud13b;
  }

  String _cloudModelLabel(WebDemoBackendMode mode) {
    return switch (mode) {
      WebDemoBackendMode.cloud13b => "13.3B",
      WebDemoBackendMode.cloud7b => "7.2B",
      WebDemoBackendMode.local => "local",
    };
  }

  String get _cloudModelName {
    if (backendMode.q == WebDemoBackendMode.cloud13b) return "13.3b";
    return Config.webDemoOfficialModel;
  }
}

int _estimateWebDemoTokens(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  final bytes = utf8.encode(trimmed).length;
  final estimated = (bytes / 4).round();
  if (estimated < 1) return 1;
  return estimated;
}
