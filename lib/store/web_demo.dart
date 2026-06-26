part of 'p.dart';

const int _webDemoCloudTimeoutSeconds = 120;
const String _webDemoProtocolRwkvLightningV1 = "rwkv_lightning_v1";
const String _webDemoProtocolOpenAi = "openai";
const String _webDemoDefault7BBaseUrl = "http://47.115.88.183:1801/v1/chat/completions";
const String _webDemoDefault13BBaseUrl = "http://47.115.88.183:1800/v1/chat/completions";
const List<String> _webDemoLightningStopTokens = <String>["\nUser:"];

class _WebDemo {
  StreamSubscription<from_rwkv.ResponseBatchBufferContent>? _localSubscription;
  StreamSubscription<IsGenerating>? _localGeneratingSubscription;
  http.Client? _cloudClient;
  String _activeContent = "";

  late final useOfficialCloud = qs(false);
  late final promptTemplate = qs(webDemoDefaultPromptTemplate);
  late final pendingHtmlContext = qs<String?>(null);
  late final lastSavedHtmlPath = qs<String?>(null);
  late final lastError = qs<String?>(null);
  late final active = qs(false);
}

extension $WebDemo on _WebDemo {
  Future<void> _init() async {}

  bool get officialCloudConfigured => Config.webDemoOfficialApiKey.trim().isNotEmpty;

  void setUseOfficialCloud(bool value) {
    useOfficialCloud.q = value;
  }

  void setPromptTemplate(String value) {
    promptTemplate.q = value;
  }

  void resetPromptTemplate() {
    promptTemplate.q = webDemoDefaultPromptTemplate;
  }

  Future<void> sendFromCurrentInput() async {
    final raw = P.chat.textInInput.q.trim();
    if (raw.isEmpty) {
      Alert.info(S.current.chat_empty_message);
      return;
    }

    P.chat.focusNode.unfocus();
    P.chat.textInInput.q = "";
    final sourceHtml = pendingHtmlContext.q;
    pendingHtmlContext.q = null;
    await sendPrompt(raw, sourceHtml: sourceHtml);
  }

  Future<void> sendPrompt(String raw, {String? sourceHtml}) async {
    if (P.chat._showGeneratingSendBlockedAlert()) return;

    final usingCloud = useOfficialCloud.q;
    if (!usingCloud && !checkModelSelection(preferredDemoType: .chat)) return;
    if (usingCloud && !officialCloudConfigured) {
      Alert.warning("Official Web Demo endpoint key is not configured");
      return;
    }

    _cancelLocalSubscriptions();
    _cloudClient?.close();
    _cloudClient = null;
    lastError.q = null;

    final prompt = sourceHtml == null || sourceHtml.trim().isEmpty
        ? buildWebDemoPrompt(template: promptTemplate.q, request: raw)
        : buildWebDemoEditPrompt(html: sourceHtml, instruction: raw);
    final batchSize = P.chat.effectiveBatchEnabled.q ? P.chat.effectiveBatchCount.q : 1;
    final receiveId = await _createWebDemoMessagePair(
      userContent: raw,
      batchSize: batchSize,
      usingCloud: usingCloud,
    );
    if (receiveId == null) return;

    if (usingCloud) {
      unawaited(_runCloud(prompt: prompt, batchSize: batchSize, receiveId: receiveId));
      return;
    }

    _runLocal(prompt: prompt, batchSize: batchSize, receiveId: receiveId);
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
    P.chat.textInInput.q = "Modify this page: ";
    if (P.app.pageKey.q != .chat) {
      push(.chat);
    }
    await 100.msLater;
    P.chat.focusNode.requestFocus();
    P.chat.textEditingController.selection = TextSelection.collapsed(offset: P.chat.textEditingController.text.length);
    Alert.info("HTML context ready");
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
    _cloudClient?.close();
    _cloudClient = null;
    _cancelLocalSubscriptions();
    await P.rwkvGeneration.stop();
    P.rwkvGeneration.generating.q = false;
    active.q = false;
  }

  Future<int?> _createWebDemoMessagePair({
    required String userContent,
    required int batchSize,
    required bool usingCloud,
  }) async {
    MsgNode? parentNode = P.msg.msgNode.q.wholeLatestNode;
    final parentMsg = P.msg.pool.q[parentNode.id];
    if (parentMsg != null && parentMsg.type == MessageType.text && !parentMsg.isMine && getIsBatch(parentMsg.content)) {
      final selection = P.msg.batchSelection(parentMsg).q;
      if (selection == null) {
        Alert.info(S.current.please_select_a_branch_to_continue_the_conversation, position: AlertPosition.top);
        return null;
      }
      final finalizedContent = parentMsg.content.split(Config.batchMarker)[selection];
      P.msg._syncMsg(parentMsg.id, parentMsg.copyWith(content: finalizedContent, clearBatchSlotLabels: true));
      unawaited(
        P.chat._refreshTokenCountsForMessage(
          messageId: parentMsg.id,
          overrideBotContent: finalizedContent,
          persistToMessage: true,
        ),
      );
    }

    final userId = DateTime.now().millisecondsSinceEpoch;
    final userMsg = Message(
      id: userId,
      content: userContent,
      isMine: true,
      paused: false,
    );
    await P.msg._syncMsg(userId, userMsg);
    parentNode = parentNode.add(MsgNode(userId));

    final receiveId = userId + 1;
    final currentModel = P.rwkvModel.latest.q;
    final modelName = usingCloud
        ? "Official RWKV Web Demo ${Config.webDemoOfficialModel}"
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
      rawDecodeParams: P.chat._resolveDecodeParamsSnapshotRaw(),
      batchSlotLabels: batchSize > 1 ? List<String>.generate(batchSize, (int index) => "Web ${index + 1}") : null,
    );
    P.msg.pool.q[receiveId] = receiveMsg;
    parentNode.add(MsgNode(receiveId));
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
    P.chat.receiveId.q = receiveId;
    P.chat._setReceivedTokens("", immediateUi: true);
    P.rwkvGeneration.generating.q = true;
    active.q = true;
    P.chat._scheduleScrollToBottom();
    P.chat._scheduleRefreshLiveTokenCounts(messageId: receiveId, liveBotContent: "");
    return receiveId;
  }

  void _runLocal({
    required String prompt,
    required int batchSize,
    required int receiveId,
  }) {
    final outputs = List<String>.filled(batchSize, "");
    _activeContent = "";
    _localSubscription = P.rwkvGeneration
        .completion(prompt, batchSize: batchSize)
        .listen(
          (response) {
            for (int i = 0; i < response.responseBufferContent.length && i < outputs.length; i++) {
              outputs[i] = stripWebDemoPromptPrefix(content: response.responseBufferContent[i], prompt: prompt);
            }
            _activeContent = _joinOutputs(outputs);
            P.chat._setReceivedTokens(_activeContent);
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
    _activeContent = "";

    try {
      final request = http.Request("POST", _officialChatCompletionsUri());
      request.headers["Accept"] = "*/*";
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode({
        "contents": List<String>.filled(batchSize, prompt),
        "max_tokens": _maxTokensForCloud,
        "stop_tokens": _webDemoLightningStopTokens,
        "temperature": P.rwkvParams.arguments(Argument.temperature).q,
        "top_k": P.rwkvParams.arguments(Argument.topK).q.round(),
        "top_p": P.rwkvParams.arguments(Argument.topP).q,
        "pad_zero": true,
        "alpha_presence": P.rwkvParams.arguments(Argument.presencePenalty).q,
        "alpha_frequency": P.rwkvParams.arguments(Argument.frequencyPenalty).q,
        "alpha_decay": P.rwkvParams.arguments(Argument.penaltyDecay).q,
        "chunk_size": 8,
        "stream": false,
        "password": Config.webDemoOfficialApiKey,
      });

      final streamedResponse = await client.send(request).timeout(const Duration(seconds: _webDemoCloudTimeoutSeconds));
      final responseBody = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        throw "${streamedResponse.statusCode}: $responseBody";
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map) {
        throw "Unexpected RWKV Lightning response";
      }
      final choices = extractWebDemoCloudChoiceContents(Map<String, Object?>.from(decoded));
      if (choices.isEmpty) {
        throw "RWKV Lightning response did not include choices";
      }
      final outputs = buildWebDemoCloudChoiceOutputs(choices: choices, batchSize: batchSize, prompt: prompt);
      _activeContent = _joinOutputs(outputs);
      P.chat._setReceivedTokens(_activeContent);
      _finishCurrentMessage(receiveId: receiveId, content: _activeContent, callingFunction: "webDemoLightningComplete");
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
    _activeContent = "";

    try {
      final request = http.Request("POST", _officialChatCompletionsUri());
      request.headers["Accept"] = "*/*";
      request.headers["Content-Type"] = "application/json";
      request.headers["Authorization"] = "Bearer ${Config.webDemoOfficialApiKey}";
      request.body = jsonEncode({
        "model": Config.webDemoOfficialModel,
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
          for (final choice in event.choices) {
            if (choice.index < 0 || choice.index >= outputs.length) continue;
            outputs[choice.index] = outputs[choice.index] + choice.content;
          }
          _activeContent = _joinOutputs(outputs);
          P.chat._setReceivedTokens(_activeContent);
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
    final model = Config.webDemoOfficialModel.trim().toLowerCase();
    if (configured == _webDemoDefault7BBaseUrl && (model == "13b" || model == "13.3b")) {
      return _webDemoDefault13BBaseUrl;
    }
    return configured;
  }

  Map<String, Object?> _decodeParamsForCloud() {
    return {
      "temperature": P.rwkvParams.arguments(Argument.temperature).q,
      "top_p": P.rwkvParams.arguments(Argument.topP).q,
      "max_tokens": _maxTokensForCloud,
      "presence_penalty": P.rwkvParams.arguments(Argument.presencePenalty).q,
      "frequency_penalty": P.rwkvParams.arguments(Argument.frequencyPenalty).q,
    };
  }

  int get _maxTokensForCloud {
    final maxTokens = P.rwkvParams.arguments(Argument.maxLength).q.round();
    if (maxTokens <= 0) return Argument.maxLength.defaults.round();
    return maxTokens;
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
    P.chat._setReceivedTokens("", immediateUi: true);
    P.rwkvGeneration.generating.q = false;
    active.q = false;
    P.chat._scheduleRefreshLiveTokenCounts(messageId: receiveId, liveBotContent: finalContent);
    unawaited(
      P.chat._refreshTokenCountsForMessage(
        messageId: receiveId,
        overrideBotContent: finalContent,
        persistToMessage: true,
      ),
    );
  }

  void _cancelLocalSubscriptions() {
    _localSubscription?.cancel();
    _localSubscription = null;
    _localGeneratingSubscription?.cancel();
    _localGeneratingSubscription = null;
  }
}
