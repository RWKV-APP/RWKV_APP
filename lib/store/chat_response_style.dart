part of 'p.dart';

extension $ChatResponseStyle on _Chat {
  Future<void> onResponseStyleTapped() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final model = P.rwkvModel.latest.q;
    if (model == null && !P.albatrossRuntime.enabled.q) {
      ModelSelector.show();
      return;
    }

    final context = getContext();
    if (context == null) return;

    P.app.hapticLight();
    await ResponseStylePanel.show();
  }

  Future<void> onResponseStyleRouteChanged({
    required ResponseStyleRoute route,
    required bool enabled,
  }) async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final ResponseStyleState currentState = responseStyle.q;
    if (currentState.enabledFor(route) == enabled) {
      return;
    }
    if (!currentState.canToggle(route, enabled)) {
      resetResponseStyle();
      Alert.info(S.current.response_style_auto_switched_to_jin);
      return;
    }

    final ResponseStyleState nextState = currentState.copyWithRoute(route, enabled);
    if (!_canUseResponseStyleRouteCount(nextState.activeCount)) {
      final bool wantsToReplaceSingleRoute = enabled && currentState.activeCount == 1 && !currentState.enabledFor(route);
      if (wantsToReplaceSingleRoute) {
        final ResponseStyleState replacementState = ResponseStyleState.only(route);
        await _applyResponseStyleState(replacementState);
        return;
      }
      Alert.warning(S.current.response_style_batch_not_supported(nextState.activeCount));
      return;
    }

    await _applyResponseStyleState(nextState);
  }

  Future<void> onAllResponseStyleRoutesSelected() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final ResponseStyleState currentState = responseStyle.q;
    if (currentState.hasAllRoutes) {
      return;
    }

    final ResponseStyleState nextState = ResponseStyleState.all();
    if (!_canUseResponseStyleRouteCount(nextState.activeCount)) {
      Alert.warning(S.current.response_style_batch_not_supported(nextState.activeCount));
      return;
    }

    await _applyResponseStyleState(nextState);
  }

  Future<void> onResponseStyleRandomQuestionsTapped() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    if (P.albatrossRuntime.enabled.q) {
      Alert.info(S.current.albatross_backend_unsupported);
      return;
    }

    final model = P.rwkvModel.latest.q;
    if (model == null) {
      ModelSelector.show();
      return;
    }

    final routes = responseStyle.q.enabledRoutesInOrder;
    final routeCount = routes.length;
    if (!_canUseResponseStyleRouteCount(routeCount)) {
      Alert.warning(S.current.response_style_batch_not_supported(routeCount));
      return;
    }

    final questions = P.suggestion.pickRandomChatPrompts(routeCount);
    if (questions.length < routeCount) {
      Alert.warning(S.current.response_style_random_questions_not_enough(routeCount), position: AlertPosition.bottom);
      return;
    }

    _clearResponseStyleSequentialState();
    final sent = await _sendResponseStyleRandomQuestions(
      routes: routes,
      questions: questions,
    );
    if (!sent) return;
    pop();
  }

  void resetResponseStyle() {
    responseStyle.q = const ResponseStyleState();
    batchEnabled.q = false;
    batchCount.q = Argument.batchCount.defaults.toInt();
  }

  Future<void> _applyResponseStyleState(
    ResponseStyleState state,
  ) async {
    responseStyle.q = state;
    if (state.activeCount > 1) {
      await _setFastThinkingModeForResponseStyleBatch();
    }
    await _syncBatchStateForResponseStyle(activeCount: state.activeCount);
  }

  Future<void> _syncBatchStateForResponseStyle({
    required int activeCount,
  }) async {
    if (activeCount <= 1) {
      batchEnabled.q = false;
      batchCount.q = Argument.batchCount.defaults.toInt();
      return;
    }
    if (!batchEnabled.q) {
      await onBatchInferenceSwitchChanged(true, triggeredByResponseStyle: true);
    }
    if (batchCount.q == activeCount) {
      return;
    }
    batchCount.q = activeCount;
  }

  bool _canUseResponseStyleRouteCount(int activeCount) {
    if (activeCount <= 0) {
      return false;
    }
    if (activeCount <= 1) {
      return _hasChatGenerationTarget();
    }
    return _supportsResponseStyleBatchExecution(activeCount);
  }

  bool _supportsResponseStyleBatchExecution(int activeCount) {
    if (activeCount <= 1) {
      return false;
    }
    if (!_canUseBatchInferenceNow()) return false;

    final supportedBatchSizes = P.rwkvParams.supportedBatchSizes.q;
    if (supportedBatchSizes.isEmpty) {
      return true;
    }

    return supportedBatchSizes.max >= activeCount;
  }

  bool _shouldUseResponseStyleBatchExecution(int activeCount) {
    return _supportsResponseStyleBatchExecution(activeCount);
  }

  bool _hasChatGenerationTarget() {
    if (P.albatrossRuntime.canUse.q) return true;
    return P.rwkvModel.latest.q != null;
  }

  bool _canUseBatchInferenceNow() {
    if (P.albatrossRuntime.canUse.q) return true;
    return P.rwkvModel.latest.q?.supportsBatchInference ?? false;
  }

  MsgNode? _prepareParentNodeForNewChatMessage() {
    final parentNode = P.msg.msgNode.q.wholeLatestNode;
    final parentMsg = P.msg.pool.q[parentNode.id];
    if (parentMsg == null) return parentNode;
    if (parentMsg.type != MessageType.text) return parentNode;
    if (parentMsg.isMine) return parentNode;
    if (!getIsBatch(parentMsg.content)) return parentNode;

    final selection = P.msg.batchSelection(parentMsg).q;
    if (selection == null) {
      Alert.info(S.current.please_select_a_branch_to_continue_the_conversation, position: AlertPosition.bottom);
      return null;
    }

    final batch = parentMsg.content.split(Config.batchMarker);
    if (selection < 0 || selection >= batch.length) {
      Alert.info(S.current.please_select_a_branch_to_continue_the_conversation, position: AlertPosition.bottom);
      return null;
    }

    final finalizedContent = batch[selection];
    P.msg._syncMsg(
      parentMsg.id,
      parentMsg.copyWith(
        content: finalizedContent,
        clearBatchSlotLabels: true,
      ),
    );
    unawaited(
      _refreshTokenCountsForMessage(
        messageId: parentMsg.id,
        overrideBotContent: finalizedContent,
        persistToMessage: true,
      ),
    );

    final userParentNode = P.msg.msgNode.q.findParentByMsgId(parentMsg.id);
    if (userParentNode == null) return parentNode;
    final userParentMsg = P.msg.pool.q[userParentNode.id];
    if (userParentMsg == null) return parentNode;
    if (!userParentMsg.isMine) return parentNode;

    final userParts = userParentMsg.content.split(Config.userMsgModifierSep);
    final userRawContent = userParts[0];
    final userTail = userParts.length > 1 ? userParts.sublist(1).join(Config.userMsgModifierSep) : "";
    if (!getIsBatch(userRawContent)) return parentNode;

    final userBatch = userRawContent.split(Config.batchMarker);
    if (selection >= userBatch.length) return parentNode;

    final selectedQuestion = userBatch[selection];
    final finalizedUserContent = userTail.isNotEmpty ? selectedQuestion + Config.userMsgModifierSep + userTail : selectedQuestion;
    P.msg._syncMsg(
      userParentMsg.id,
      userParentMsg.copyWith(content: finalizedUserContent),
    );

    return parentNode;
  }

  List<ResponseStyleRoute> _resolveResponseStyleRoutesForMessage(Message message) {
    final List<String>? labels = message.batchSlotLabels;
    if (labels == null || labels.isEmpty) {
      return responseStyle.q.enabledRoutesInOrder;
    }
    final List<ResponseStyleRoute> routes = <ResponseStyleRoute>[];
    for (final String label in labels) {
      final ResponseStyleRoute? route = responseStyleRouteFromLabel(label);
      if (route == null) {
        continue;
      }
      routes.add(route);
    }
    if (routes.isEmpty) {
      return responseStyle.q.enabledRoutesInOrder;
    }
    return routes;
  }

  List<String> _buildSingleRouteHistory({
    required List<String> history,
    required ResponseStyleRoute route,
    String? assistantMessage,
  }) {
    return route.buildHistory(
      history: history,
      assistantMessage: assistantMessage,
    );
  }

  List<String> _replaceLatestHistoryMessage({
    required List<String> history,
    required String message,
  }) {
    final next = <String>[...history];
    if (next.isEmpty) {
      return <String>[message];
    }
    next[next.length - 1] = message;
    return next;
  }

  List<String>? _resolveResponseStylePerSlotUserMessages({
    required int messageId,
    required int routeCount,
  }) {
    return _resolvePerSlotUserMessagesForBatch(
      messageId: messageId,
      batchCount: routeCount,
    );
  }

  List<String>? _resolvePerSlotUserMessagesForBatch({
    required int messageId,
    required int batchCount,
  }) {
    final targetNode = P.msg.msgNode.q.findNodeByMsgId(messageId);
    final userNode = targetNode?.parent;
    if (userNode == null) return null;

    final userMessage = P.msg.pool.q[userNode.id];
    if (userMessage == null) return null;
    if (!userMessage.isMine) return null;

    final userParts = userMessage.content.split(Config.userMsgModifierSep);
    final userRawContent = userParts[0];
    if (!getIsBatch(userRawContent)) return null;

    final (batch, isBatch, resolvedBatchCount, _) = getBatchInfo(userRawContent);
    if (!isBatch) return null;
    if (resolvedBatchCount < batchCount) return null;

    final userTail = userParts.length > 1 ? userParts.sublist(1).join(Config.userMsgModifierSep) : "";
    return <String>[
      for (int i = 0; i < batchCount; i++) userTail.isNotEmpty ? batch[i] + userTail : batch[i],
    ];
  }

  Future<bool> _sendResponseStyleRandomQuestions({
    required List<ResponseStyleRoute> routes,
    required List<String> questions,
  }) async {
    if (routes.length != questions.length) {
      return false;
    }

    if (routes.length == 1) {
      cancelEditing(clearInput: true);
      focusNode.unfocus();
      await _applyResponseStyleState(ResponseStyleState(enabledRoutes: routes));
      await send(questions.first);
      return true;
    }

    final parentNode = _prepareParentNodeForNewChatMessage();
    if (parentNode == null) {
      return false;
    }

    final currentModel = P.rwkvModel.latest.q;
    if (currentModel == null) {
      ModelSelector.show();
      return false;
    }

    cancelEditing(clearInput: true);
    focusNode.unfocus();
    P.msg.clearBottomDetailsStateInScope(scope: "chat_bot_message_bottom");

    final historyPrefix = _history();
    await _applyResponseStyleState(ResponseStyleState(enabledRoutes: routes));
    final thinkingMode = P.rwkvParams.thinkingMode.q;
    final userBatchContent = buildBatchContent(questions);
    final storedContent = userBatchContent + Config.userMsgModifierSep + thinkingMode.userMsgFooter;
    final userMsgId = HF.milliseconds;
    final userMsg = Message(
      id: userMsgId,
      content: storedContent,
      isMine: true,
      type: MessageType.text,
      paused: false,
    );
    await P.msg._syncMsg(userMsgId, userMsg);
    final botParentNode = parentNode.add(MsgNode(userMsgId));

    final botMsgId = HF.milliseconds + 1;
    final botMsg = Message(
      id: botMsgId,
      content: "",
      isMine: false,
      changing: true,
      paused: false,
      modelName: currentModel.name,
      runningMode: thinkingMode.toString(),
      rawDecodeParams: _resolveDecodeParamsSnapshotRaw(),
      batchSlotLabels: routes.map((route) => route.label).toList(growable: false),
    );
    await P.msg._syncMsg(botMsgId, botMsg);
    botParentNode.add(MsgNode(botMsgId));

    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
    receiveId.q = botMsgId;
    _setReceivedTokens("", immediateUi: true);
    P.rwkvGeneration.generating.q = true;
    _liveTokenCountThrottler.cancel();
    _scheduleRefreshLiveTokenCounts(messageId: botMsgId, liveBotContent: "");

    final slotConfigs = <to_rwkv.ChatBatchSlotConfig>[];
    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      String userContent = questions[i];
      if (thinkingMode.userMsgFooter.isNotEmpty) {
        userContent = userContent + thinkingMode.userMsgFooter;
      }
      slotConfigs.add(
        to_rwkv.ChatBatchSlotConfig(
          messages: _buildSingleRouteHistory(
            history: <String>[...historyPrefix, userContent],
            route: route,
          ),
          enableReasoning: true,
          forceReasoning: false,
          forceLang: route.forceLang,
        ),
      );
    }

    P.rwkvGeneration.sendMessages(
      slotConfigs.first.messages,
      overrideBatchSlotConfigs: slotConfigs,
    );
    _checkSensitive(userBatchContent);

    _scheduleScrollToBottom();
    return true;
  }

  List<to_rwkv.ChatBatchSlotConfig> _buildResponseStyleSlotConfigs({
    required List<String> history,
    required List<ResponseStyleRoute> routes,
    Map<ResponseStyleRoute, String?>? assistantMessages,
    List<String>? perSlotUserMessages,
  }) {
    final slotConfigs = <to_rwkv.ChatBatchSlotConfig>[];
    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final perSlotUserMessage = perSlotUserMessages != null && i < perSlotUserMessages.length ? perSlotUserMessages[i] : null;
      final routeHistory = perSlotUserMessage == null
          ? history
          : _replaceLatestHistoryMessage(
              history: history,
              message: perSlotUserMessage,
            );
      slotConfigs.add(
        to_rwkv.ChatBatchSlotConfig(
          messages: _buildSingleRouteHistory(
            history: routeHistory,
            route: route,
            assistantMessage: assistantMessages?[route],
          ),
          enableReasoning: true,
          forceReasoning: false,
          forceLang: route.forceLang,
        ),
      );
    }
    return slotConfigs;
  }

  Future<void> _setFastThinkingModeForResponseStyleBatch() async {
    if (P.rwkvParams.thinkingMode.q == .fast) {
      return;
    }
    await P.rwkvParams.setModelConfig(thinkingMode: .fast);
  }

  List<String> _buildRequestHistoryForResponseStyleRoute({
    required List<String> history,
    required ResponseStyleRoute route,
    String? assistantMessage,
  }) {
    return route.buildHistory(
      history: history,
      assistantMessage: assistantMessage,
    );
  }

  ({List<String> messages, List<to_rwkv.ChatBatchSlotConfig>? slotConfigs, int? forceLang})? _buildResponseStyleResumeRequest({
    required int messageId,
  }) {
    if (P.app.pageKey.q != .chat) {
      return null;
    }

    final Message? currentMessage = P.msg.pool.q[messageId];
    if (currentMessage == null) {
      return null;
    }

    final List<String>? baseHistory = _historyBeforeBotMessage(messageId: messageId);
    if (baseHistory == null || baseHistory.isEmpty) {
      return null;
    }

    final List<ResponseStyleRoute> routes = _resolveResponseStyleRoutesForMessage(currentMessage);
    if (routes.isEmpty) {
      return null;
    }

    if (routes.length == 1) {
      final ResponseStyleRoute route = routes.first;
      final String? assistantMessage = currentMessage.content.isNotEmpty ? currentMessage.content : null;
      return (
        messages: _buildSingleRouteHistory(
          history: baseHistory,
          route: route,
          assistantMessage: assistantMessage,
        ),
        slotConfigs: null,
        forceLang: route.forceLang,
      );
    }

    final (List<String> batch, bool isBatch, int batchCount, int? selectedBatch) = getBatchInfo(currentMessage.content);
    if (!isBatch) {
      return null;
    }
    if (batchCount < routes.length) {
      return null;
    }
    if (selectedBatch != null) {
      return null;
    }

    final Map<ResponseStyleRoute, String?> assistantMessages = <ResponseStyleRoute, String?>{};
    for (int i = 0; i < routes.length; i++) {
      final ResponseStyleRoute route = routes[i];
      final String rawValue = i < batch.length ? batch[i] : "";
      assistantMessages[route] = rawValue;
    }

    return (
      messages: baseHistory,
      slotConfigs: _buildResponseStyleSlotConfigs(
        history: baseHistory,
        routes: routes,
        assistantMessages: assistantMessages,
        perSlotUserMessages: _resolveResponseStylePerSlotUserMessages(
          messageId: messageId,
          routeCount: routes.length,
        ),
      ),
      forceLang: null,
    );
  }

  ({List<String> messages, List<List<String>> batchMessages})? _buildBatchResumeRequest({
    required int messageId,
  }) {
    if (P.app.pageKey.q != .chat) {
      return null;
    }

    final Message? currentMessage = P.msg.pool.q[messageId];
    if (currentMessage == null) {
      return null;
    }

    final (List<String> batch, bool isBatch, int batchCount, int? selectedBatch) = getBatchInfo(currentMessage.content);
    if (!isBatch) {
      return null;
    }
    if (batchCount <= 1) {
      return null;
    }
    if (selectedBatch != null) {
      return null;
    }

    final List<String>? baseHistory = _historyBeforeBotMessage(messageId: messageId);
    if (baseHistory == null || baseHistory.isEmpty) {
      return null;
    }

    final List<String>? perSlotUserMessages = _resolvePerSlotUserMessagesForBatch(
      messageId: messageId,
      batchCount: batchCount,
    );
    final batchMessages = <List<String>>[];
    for (int i = 0; i < batchCount; i++) {
      final String partialAssistantMessage = i < batch.length ? batch[i] : "";
      final String? perSlotUserMessage = perSlotUserMessages != null && i < perSlotUserMessages.length ? perSlotUserMessages[i] : null;
      final List<String> slotHistory = perSlotUserMessage == null
          ? <String>[...baseHistory]
          : _replaceLatestHistoryMessage(
              history: baseHistory,
              message: perSlotUserMessage,
            );
      batchMessages.add(<String>[
        ...slotHistory,
        partialAssistantMessage,
      ]);
    }

    if (batchMessages.isEmpty) {
      return null;
    }

    return (
      messages: batchMessages.first,
      batchMessages: batchMessages,
    );
  }

  void _clearResponseStyleSequentialState() {
    _responseStyleSequentialActive = false;
    _responseStyleSequentialStopRequested = false;
    _responseStyleSequentialMessageId = null;
    _responseStyleSequentialCurrentRouteIndex = 0;
    _responseStyleSequentialForceChinese = false;
    _responseStyleSequentialCurrentOutput = "";
    _responseStyleSequentialCurrentAssistantMessage = null;
    _responseStyleSequentialRoutes = const <ResponseStyleRoute>[];
    _responseStyleSequentialBaseHistory = const <String>[];
    _responseStyleSequentialCompletedOutputs = const <String>[];
  }

  String _buildResponseStyleSequentialBatchContent({
    required List<String> completedOutputs,
    String? currentOutput,
    required int totalCount,
  }) {
    final List<String> slotOutputs = List<String>.filled(totalCount, "");
    final int completedCount = math.min(completedOutputs.length, totalCount);
    for (int i = 0; i < completedCount; i++) {
      slotOutputs[i] = completedOutputs[i];
    }
    if (currentOutput != null && completedCount < totalCount) {
      slotOutputs[completedCount] = currentOutput;
    }
    return buildBatchContent(slotOutputs);
  }

  Future<void> _sendCurrentResponseStyleSequentialRoute() async {
    if (!_responseStyleSequentialActive) {
      return;
    }
    if (_responseStyleSequentialCurrentRouteIndex >= _responseStyleSequentialRoutes.length) {
      return;
    }

    final ResponseStyleRoute route = _responseStyleSequentialRoutes[_responseStyleSequentialCurrentRouteIndex];
    final List<String> requestHistory = _buildRequestHistoryForResponseStyleRoute(
      history: _responseStyleSequentialBaseHistory,
      route: route,
      assistantMessage: _responseStyleSequentialCurrentAssistantMessage,
    );
    _responseStyleSequentialCurrentAssistantMessage = null;
    await P.rwkvGeneration.sendMessages(
      requestHistory,
      forceChinese: _responseStyleSequentialForceChinese,
      forceLang: route.forceLang,
    );
  }

  Future<void> _startResponseStyleSequentialGeneration({
    required int messageId,
    required List<String> history,
    required List<ResponseStyleRoute> routes,
    required bool forceChinese,
    List<String> completedOutputs = const <String>[],
    int startRouteIndex = 0,
    String? currentAssistantMessage,
  }) async {
    await _setFastThinkingModeForResponseStyleBatch();
    _responseStyleSequentialActive = true;
    _responseStyleSequentialStopRequested = false;
    _responseStyleSequentialMessageId = messageId;
    _responseStyleSequentialCurrentRouteIndex = startRouteIndex;
    _responseStyleSequentialForceChinese = forceChinese;
    _responseStyleSequentialCurrentOutput = currentAssistantMessage ?? "";
    _responseStyleSequentialCurrentAssistantMessage = currentAssistantMessage;
    _responseStyleSequentialRoutes = <ResponseStyleRoute>[...routes];
    _responseStyleSequentialBaseHistory = <String>[...history];
    _responseStyleSequentialCompletedOutputs = <String>[...completedOutputs];
    _setReceivedTokens(
      _buildResponseStyleSequentialBatchContent(
        completedOutputs: _responseStyleSequentialCompletedOutputs,
        currentOutput: currentAssistantMessage,
        totalCount: _responseStyleSequentialRoutes.length,
      ),
      immediateUi: true,
    );
    await _sendCurrentResponseStyleSequentialRoute();
  }

  Future<void> _advanceResponseStyleSequentialGenerationAfterStop() async {
    if (!_responseStyleSequentialActive) {
      return;
    }

    final int? messageId = _responseStyleSequentialMessageId;
    if (messageId == null) {
      _clearResponseStyleSequentialState();
      return;
    }

    final String currentOutput = _responseStyleSequentialCurrentOutput;
    final List<String> nextCompletedOutputs = <String>[
      ..._responseStyleSequentialCompletedOutputs,
      currentOutput,
    ];
    _responseStyleSequentialCompletedOutputs = nextCompletedOutputs;

    final String finalizedContent = _buildResponseStyleSequentialBatchContent(
      completedOutputs: nextCompletedOutputs,
      totalCount: _responseStyleSequentialRoutes.length,
    );
    _setReceivedTokens(finalizedContent, immediateUi: true);

    if (_responseStyleSequentialStopRequested) {
      _clearResponseStyleSequentialState();
      return;
    }

    final int nextRouteIndex = _responseStyleSequentialCurrentRouteIndex + 1;
    if (nextRouteIndex >= _responseStyleSequentialRoutes.length) {
      _clearResponseStyleSequentialState();
      _fullyReceived(callingFunction: "_advanceResponseStyleSequentialGenerationAfterStop");
      return;
    }

    _responseStyleSequentialCurrentRouteIndex = nextRouteIndex;
    _responseStyleSequentialCurrentOutput = "";
    _responseStyleSequentialCurrentAssistantMessage = null;
    _scheduleRefreshLiveTokenCounts(
      messageId: messageId,
      liveBotContent: finalizedContent,
    );
    await _sendCurrentResponseStyleSequentialRoute();
  }

  bool _handleResponseStyleSequentialEvent(from_rwkv.FromRWKV event) {
    if (!_responseStyleSequentialActive) {
      return false;
    }

    final int? messageId = _responseStyleSequentialMessageId;
    if (messageId == null) {
      _clearResponseStyleSequentialState();
      return false;
    }

    switch (event) {
      case from_rwkv.GenerateStart _:
        P.rwkvGeneration.generating.q = true;
        return true;

      case from_rwkv.ResponseBufferContent res:
        _responseStyleSequentialCurrentOutput = res.responseBufferContent;
        final String liveContent = _buildResponseStyleSequentialBatchContent(
          completedOutputs: _responseStyleSequentialCompletedOutputs,
          currentOutput: res.responseBufferContent,
          totalCount: _responseStyleSequentialRoutes.length,
        );
        _setReceivedTokens(liveContent);
        if (completionMode.q) {
          return true;
        }
        _scheduleRefreshLiveTokenCounts(
          messageId: messageId,
          liveBotContent: liveContent,
        );
        _sensitiveThrottler.call(() {
          _checkSensitive(liveContent);
        });
        return true;

      case from_rwkv.GenerateStop _:
        P.rwkvGeneration.generating.q = false;
        unawaited(_advanceResponseStyleSequentialGenerationAfterStop());
        return true;

      default:
        return false;
    }
  }

  List<String> _resolveResponseStyleSequentialSlotOutputs({
    required Message message,
    required int routeCount,
  }) {
    final (List<String> batch, bool isBatch, int _, int? _) = getBatchInfo(message.content);
    if (isBatch) {
      final List<String> outputs = batch.take(routeCount).toList();
      while (outputs.length < routeCount) {
        outputs.add("");
      }
      return outputs;
    }

    final List<String> outputs = List<String>.filled(routeCount, "");
    if (message.content.isNotEmpty) {
      outputs[0] = message.content;
    }
    return outputs;
  }

  ({List<String> completedOutputs, int startRouteIndex, String? currentAssistantMessage}) _buildResponseStyleSequentialResumeState({
    required List<String> slotOutputs,
  }) {
    int lastNonEmptyIndex = -1;
    for (int i = 0; i < slotOutputs.length; i++) {
      if (slotOutputs[i].trim().isEmpty) {
        continue;
      }
      lastNonEmptyIndex = i;
    }

    if (lastNonEmptyIndex < 0) {
      return (
        completedOutputs: const <String>[],
        startRouteIndex: 0,
        currentAssistantMessage: null,
      );
    }

    final List<String> completedOutputs = <String>[];
    for (int i = 0; i < lastNonEmptyIndex; i++) {
      completedOutputs.add(slotOutputs[i]);
    }
    return (
      completedOutputs: completedOutputs,
      startRouteIndex: lastNonEmptyIndex,
      currentAssistantMessage: slotOutputs[lastNonEmptyIndex],
    );
  }

  Future<bool> _resumeResponseStyleSequentialMessage({
    required int messageId,
  }) async {
    if (P.app.pageKey.q != .chat) {
      return false;
    }

    final Message? currentMessage = P.msg.pool.q[messageId];
    if (currentMessage == null) {
      return false;
    }

    final List<ResponseStyleRoute> routes = _resolveResponseStyleRoutesForMessage(currentMessage);
    if (routes.length <= 1) {
      return false;
    }
    if (_shouldUseResponseStyleBatchExecution(routes.length)) {
      return false;
    }

    final List<String>? baseHistory = _historyBeforeBotMessage(messageId: messageId);
    if (baseHistory == null || baseHistory.isEmpty) {
      return false;
    }

    final List<String> slotOutputs = _resolveResponseStyleSequentialSlotOutputs(
      message: currentMessage,
      routeCount: routes.length,
    );
    final resumeState = _buildResponseStyleSequentialResumeState(slotOutputs: slotOutputs);

    await _startResponseStyleSequentialGeneration(
      messageId: messageId,
      history: baseHistory,
      routes: routes,
      forceChinese: false,
      completedOutputs: resumeState.completedOutputs,
      startRouteIndex: resumeState.startRouteIndex,
      currentAssistantMessage: resumeState.currentAssistantMessage,
    );
    _scheduleRefreshLiveTokenCounts(messageId: messageId, liveBotContent: receivedTokens.q);
    return true;
  }
}
