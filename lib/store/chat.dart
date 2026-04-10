part of 'p.dart';

enum _UserMessageMenuAction {
  edit,
  copy,
  deleteCurrentBranch,
}

const String _expressionModeGuSuffix = " 请用文言文回答。";
const String _expressionModeMaoAssistantPrefix = "<think>喵";
const String _expressionModeMaoUserSuffix = " 请用可爱的猫咪口吻回答，多使用“喵”，保持猫风格。";

class _Chat {
  // ===========================================================================
  // Instance
  // ===========================================================================

  /// The scroll controller of the chat page message list
  late final scrollController = ScrollController();

  late final listAtTop = qs(true);

  /// The text editing controller of the chat page input
  late final textEditingController = TextEditingController(text: "");

  /// The focus node of the chat page input
  late final focusNode = FocusNode();

  late final _sensitiveThrottler = Throttler(milliseconds: 333, trailing: true);
  late final _liveTokenCountThrottler = Throttler(milliseconds: 997, trailing: true);
  int _refreshTokenCountEpoch = 0;
  bool _expressionSequentialActive = false;
  bool _expressionSequentialStopRequested = false;
  int? _expressionSequentialMessageId;
  int _expressionSequentialCurrentRouteIndex = 0;
  bool _expressionSequentialForceChinese = false;
  String _expressionSequentialCurrentOutput = "";
  String? _expressionSequentialCurrentAssistantMessage;
  List<ExpressionRoute> _expressionSequentialRoutes = const <ExpressionRoute>[];
  List<String> _expressionSequentialBaseHistory = const <String>[];
  List<String> _expressionSequentialCompletedOutputs = const <String>[];

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final textInInput = qs("");
  late final inputBarDebuggerShown = qs(false);

  late final prefillPercentage = qs(0.0);

  /// TODO: Should be moved to state/rwkv.dart
  late final receivedTokens = qs("");

  late final inputHeight = qs(77.0);

  late final ttsBottomHeight = qs(0.0);

  late final receiveId = qs<int?>(null);

  late final hasFocus = qs(false);

  late final _autoPauseId = qs<int?>(null);

  // TODO: Should be moved to state/msg.dart in the future
  late final sharingSelectedMsgIds = qs<Set<int>>({});

  // TODO: Should be moved to state/msg.dart in the future
  late final isSharing = qs(false);

  late final completionMode = qs(false);

  late final webSearchMode = qs(WebSearchMode.off);

  late final expressionMode = qs(const ExpressionModeState());

  late final batchEnabled = qs(Args.enableBatchInference);
  late final batchCount = qs<int>(Argument.batchCount.defaults.toInt());
  late final batchVW = qs<int>(Argument.batchVW.defaults.toInt());

  /// 当前需要在 AppBar 新对话按钮上展示引导的会话 id
  late final newConversationGuideConversationId = qs<int?>(null);

  /// 已经触发过 token 超限提示的会话集合（纯内存态）
  late final tokenReminderShownConversationIds = qs<Set<int>>({});

  /// 正在后台自动加载上次使用的模型
  late final isAutoLoadingModel = qs(false);

  // ===========================================================================
  // Provider
  // ===========================================================================

  late final inputHasContent = qp((ref) {
    final textInInput = ref.watch(this.textInInput);
    return textInInput.trim().isNotEmpty;
  });

  late final effectiveBatchEnabled = qp((ref) {
    final expressionMode = ref.watch(this.expressionMode);
    if (expressionMode.activeCount > 1) {
      return true;
    }
    return ref.watch(batchEnabled);
  });

  late final effectiveBatchCount = qp((ref) {
    final expressionMode = ref.watch(this.expressionMode);
    if (expressionMode.activeCount > 1) {
      return expressionMode.activeCount;
    }
    return ref.watch(batchCount);
  });
}

/// Public methods
extension $Chat on _Chat {
  void clearMessages() {
    P.msg._clear();
  }

  Future<void> onDeleteBranchPressed({
    required Message msg,
  }) async {
    if (P.rwkv.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final targetNode = P.msg.msgNode.q.findNodeByMsgId(msg.id);
    final parentNode = targetNode?.parent;
    if (targetNode == null || parentNode == null) {
      Alert.warning(S.current.please_select_a_branch_to_continue_the_conversation);
      return;
    }

    final siblings = parentNode.children;
    if (siblings.length <= 1) {
      return;
    }

    final targetIndex = siblings.indexWhere((MsgNode node) => node.id == msg.id);
    if (targetIndex < 0) {
      Alert.warning(S.current.please_select_a_branch_to_continue_the_conversation);
      return;
    }

    final context = getContext();
    if (context == null) return;
    final s = S.of(context);
    final confirmResult = await showOkCancelAlertDialog(
      context: context,
      title: s.delete_branch_title,
      message: s.delete_branch_confirmation_message,
      okLabel: s.delete,
      cancelLabel: s.cancel,
      isDestructiveAction: true,
    );
    if (confirmResult != OkCancelResult.ok) return;

    final deletedIds = _collectSubtreeIds(targetNode);
    final deletedIdSet = deletedIds.toSet();

    parentNode.children.removeAt(targetIndex);
    if (parentNode.latest?.id == msg.id) {
      if (parentNode.children.isEmpty) {
        parentNode.latest = null;
      } else {
        final settledIndex = targetIndex >= parentNode.children.length ? parentNode.children.length - 1 : targetIndex;
        parentNode.latest = parentNode.children[settledIndex];
      }
    }

    final nextPool = <int, Message>{...P.msg.pool.q};
    for (final deletedId in deletedIds) {
      nextPool.remove(deletedId);
    }
    P.msg.pool.q = nextPool;

    P.msg.clearBottomDetailsStateByMessageIds(messageIds: deletedIds);
    P.msg.clearBottomTokensCountByMessageIds(messageIds: deletedIds);

    final latestClickedMessage = P.msg.latestClicked.q;
    if (latestClickedMessage != null && deletedIdSet.contains(latestClickedMessage.id)) {
      P.msg.latestClicked.q = null;
    }

    final selectedSharingIds = sharingSelectedMsgIds.q;
    final filteredSharingIds = selectedSharingIds.where((int id) => !deletedIdSet.contains(id)).toSet();
    if (filteredSharingIds.length != selectedSharingIds.length) {
      sharingSelectedMsgIds.q = filteredSharingIds;
    }
    if (filteredSharingIds.length < 2) {
      isSharing.q = false;
    }

    final editingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (editingIndex != null) {
      final editingMessage = P.msg.findByIndex(editingIndex);
      if (editingMessage != null && deletedIdSet.contains(editingMessage.id)) {
        P.msg.editingOrRegeneratingIndex.q = null;
      }
    }

    final currentReceiveId = receiveId.q;
    if (currentReceiveId != null && deletedIdSet.contains(currentReceiveId)) {
      receiveId.q = null;
      receivedTokens.q = "";
    }

    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    await P.conversation._syncNode();

    try {
      await P.app._db.deleteMsgsByCreateAtInUS(deletedIds);
      Alert.success(S.current.delete_finished);
    } catch (e) {
      qqe("delete branch failed: $e");
      Alert.error("Delete failed");
    }
  }

  List<int> _collectSubtreeIds(MsgNode rootNode) {
    final ids = <int>[];
    final stack = <MsgNode>[rootNode];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      ids.add(node.id);
      for (final child in node.children) {
        stack.add(child);
      }
    }
    return ids;
  }

  void onSwitchWebSearchMode(WebSearchMode mode) async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    webSearchMode.q = mode;
  }

  Future<void> onWebSearchModeTapped() async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final context = getContext();
    if (context == null) return;

    P.app.hapticLight();

    final s = S.current;
    final current = webSearchMode.q;
    final actionPairs = <({String label, WebSearchMode key})>[
      (label: s.off, key: .off),
      (label: s.web_search, key: .search),
      (label: s.deep_web_search, key: .deepSearch),
    ];

    final actions = actionPairs.map((entry) {
      final isCurrent = entry.key == current;
      final label = isCurrent ? "☑ ${entry.label}" : entry.label;
      final key = entry.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final selectedMode = await showModalActionSheet<WebSearchMode>(
      context: context,
      title: s.web_search,
      message: "${s.web_search} / ${s.deep_web_search}",
      cancelLabel: s.cancel,
      actions: actions,
    );

    if (selectedMode == null) return;

    onSwitchWebSearchMode(selectedMode);
  }

  Future<void> onExpressionModeTapped() async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final model = P.rwkv.latestModel.q;
    if (model == null) {
      ModelSelector.show();
      return;
    }

    final context = getContext();
    if (context == null) return;

    P.app.hapticLight();
    await ExpressionModePanel.show();
  }

  Future<void> onExpressionRouteChanged({
    required ExpressionRoute route,
    required bool enabled,
  }) async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final ExpressionModeState currentState = expressionMode.q;
    if (currentState.enabledFor(route) == enabled) {
      return;
    }
    if (!currentState.canToggle(route, enabled)) {
      resetExpressionMode();
      Alert.info(S.current.expression_mode_auto_switched_to_jin);
      return;
    }

    final ExpressionModeState nextState = currentState.copyWithRoute(route, enabled);
    if (!_canUseExpressionRouteCount(nextState.activeCount)) {
      final bool wantsToReplaceSingleRoute = enabled && currentState.activeCount == 1 && !currentState.enabledFor(route);
      if (wantsToReplaceSingleRoute) {
        final ExpressionModeState replacementState = ExpressionModeState(
          jinEnabled: route == ExpressionRoute.jin,
          guEnabled: route == ExpressionRoute.gu,
          maoEnabled: route == ExpressionRoute.mao,
        );
        await _applyExpressionModeState(replacementState);
        return;
      }
      Alert.warning(S.current.expression_mode_batch_not_supported(nextState.activeCount));
      return;
    }

    await _applyExpressionModeState(nextState);
  }

  void resetExpressionMode() {
    expressionMode.q = const ExpressionModeState();
    batchEnabled.q = false;
    batchCount.q = Argument.batchCount.defaults.toInt();
  }

  Future<void> _applyExpressionModeState(
    ExpressionModeState state,
  ) async {
    await _syncBatchStateForExpressionMode(activeCount: state.activeCount);
    expressionMode.q = state;
  }

  Future<void> _syncBatchStateForExpressionMode({
    required int activeCount,
  }) async {
    if (activeCount <= 1) {
      batchEnabled.q = false;
      batchCount.q = Argument.batchCount.defaults.toInt();
      return;
    }
    if (!batchEnabled.q) {
      await onBatchInferenceSwitchChanged(true, triggeredByExpressionMode: true);
    }
    if (batchCount.q == activeCount) {
      return;
    }
    batchCount.q = activeCount;
  }

  bool _canUseExpressionRouteCount(int activeCount) {
    if (activeCount <= 0) {
      return false;
    }
    final model = P.rwkv.latestModel.q;
    if (model == null) {
      return false;
    }
    if (activeCount <= 1) {
      return true;
    }
    return _supportsExpressionBatchExecution(activeCount);
  }

  bool _supportsExpressionBatchExecution(int activeCount) {
    if (activeCount <= 1) {
      return false;
    }
    final model = P.rwkv.latestModel.q;
    if (model == null) {
      return false;
    }
    if (!model.tags.contains('batch')) {
      return false;
    }

    final supportedBatchSizes = P.rwkv.supportedBatchSizes.q;
    if (supportedBatchSizes.isEmpty) {
      return true;
    }

    return supportedBatchSizes.max >= activeCount;
  }

  bool _shouldUseExpressionBatchExecution(int activeCount) {
    return _supportsExpressionBatchExecution(activeCount);
  }

  List<String> _applySuffixToLatestUserMessage(
    List<String> history,
    String suffix,
  ) {
    final List<String> next = <String>[...history];
    if (next.isEmpty) {
      return next;
    }
    if (next.length.isEven) {
      return next;
    }
    next[next.length - 1] = "${next.last}$suffix";
    return next;
  }

  List<ExpressionRoute> _resolveExpressionRoutesForMessage(Message message) {
    final List<String>? labels = message.batchSlotLabels;
    if (labels == null || labels.isEmpty) {
      return expressionMode.q.enabledRoutesInOrder;
    }
    final List<ExpressionRoute> routes = <ExpressionRoute>[];
    for (final String label in labels) {
      final ExpressionRoute? route = expressionRouteFromLabel(label);
      if (route == null) {
        continue;
      }
      routes.add(route);
    }
    if (routes.isEmpty) {
      return expressionMode.q.enabledRoutesInOrder;
    }
    return routes;
  }

  List<String> _buildSingleRouteHistory({
    required List<String> history,
    required ExpressionRoute route,
    String? assistantMessage,
  }) {
    late final List<String> nextHistory;
    switch (route) {
      case .jin:
        nextHistory = <String>[...history];
      case .gu:
        nextHistory = _applySuffixToLatestUserMessage(history, _expressionModeGuSuffix);
      case .mao:
        nextHistory = _applySuffixToLatestUserMessage(history, _expressionModeMaoUserSuffix);
    }

    if (assistantMessage == null) {
      return nextHistory;
    }
    return <String>[
      ...nextHistory,
      assistantMessage,
    ];
  }

  List<to_rwkv.ChatBatchSlotConfig> _buildExpressionModeSlotConfigs({
    required List<String> history,
    required List<ExpressionRoute> routes,
    Map<ExpressionRoute, String?>? assistantPrefixes,
  }) {
    final bool batchRequiresAssistantPrefixes =
        routes.contains(ExpressionRoute.mao) || (assistantPrefixes?.values.any((String? prefix) => prefix != null) ?? false);

    return <to_rwkv.ChatBatchSlotConfig>[
      for (final ExpressionRoute route in routes)
        to_rwkv.ChatBatchSlotConfig(
          messages: _buildSingleRouteHistory(history: history, route: route),
          assistantPrefix: switch (route) {
            // 猫路使用 assistant prefix 时，整个 batch 都需要显式进入 assistant turn。
            // 否则今/古两路会被 runtime 当成“继续用户最后一句”，表现为复读问题本身。
            ExpressionRoute.jin => assistantPrefixes?[route] ?? (batchRequiresAssistantPrefixes ? "" : null),
            ExpressionRoute.gu => assistantPrefixes?[route] ?? (batchRequiresAssistantPrefixes ? "" : null),
            ExpressionRoute.mao => assistantPrefixes?[route] ?? _expressionModeMaoAssistantPrefix,
          },
        ),
    ];
  }

  List<String> _buildRequestHistoryForExpressionRoute({
    required List<String> history,
    required ExpressionRoute route,
    String? assistantMessage,
  }) {
    final String? resolvedAssistantMessage = switch (route) {
      ExpressionRoute.jin => assistantMessage,
      ExpressionRoute.gu => assistantMessage,
      ExpressionRoute.mao => assistantMessage ?? _expressionModeMaoAssistantPrefix,
    };
    return _buildSingleRouteHistory(
      history: history,
      route: route,
      assistantMessage: resolvedAssistantMessage,
    );
  }

  ({List<String> messages, List<to_rwkv.ChatBatchSlotConfig>? slotConfigs})? _buildExpressionModeResumeRequest({
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

    final List<ExpressionRoute> routes = _resolveExpressionRoutesForMessage(currentMessage);
    if (routes.isEmpty) {
      return null;
    }

    if (routes.length == 1) {
      final ExpressionRoute route = routes.first;
      final String? assistantMessage;
      if (currentMessage.content.isNotEmpty) {
        assistantMessage = currentMessage.content;
      } else if (route == ExpressionRoute.mao) {
        assistantMessage = _expressionModeMaoAssistantPrefix;
      } else {
        assistantMessage = null;
      }
      return (
        messages: _buildSingleRouteHistory(
          history: baseHistory,
          route: route,
          assistantMessage: assistantMessage,
        ),
        slotConfigs: null,
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

    final Map<ExpressionRoute, String?> assistantPrefixes = <ExpressionRoute, String?>{};
    for (int i = 0; i < routes.length; i++) {
      final ExpressionRoute route = routes[i];
      final String? rawValue = i < batch.length ? batch[i] : null;
      if (route == ExpressionRoute.mao) {
        assistantPrefixes[route] = rawValue == null || rawValue.isEmpty ? _expressionModeMaoAssistantPrefix : rawValue;
        continue;
      }
      assistantPrefixes[route] = rawValue;
    }

    return (
      messages: baseHistory,
      slotConfigs: _buildExpressionModeSlotConfigs(
        history: baseHistory,
        routes: routes,
        assistantPrefixes: assistantPrefixes,
      ),
    );
  }

  void _clearExpressionSequentialState() {
    _expressionSequentialActive = false;
    _expressionSequentialStopRequested = false;
    _expressionSequentialMessageId = null;
    _expressionSequentialCurrentRouteIndex = 0;
    _expressionSequentialForceChinese = false;
    _expressionSequentialCurrentOutput = "";
    _expressionSequentialCurrentAssistantMessage = null;
    _expressionSequentialRoutes = const <ExpressionRoute>[];
    _expressionSequentialBaseHistory = const <String>[];
    _expressionSequentialCompletedOutputs = const <String>[];
  }

  String _buildExpressionSequentialBatchContent({
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
    return slotOutputs.join(Config.batchMarker) + Config.batchMarker + "-1";
  }

  Future<void> _sendCurrentExpressionSequentialRoute() async {
    if (!_expressionSequentialActive) {
      return;
    }
    if (_expressionSequentialCurrentRouteIndex >= _expressionSequentialRoutes.length) {
      return;
    }

    final ExpressionRoute route = _expressionSequentialRoutes[_expressionSequentialCurrentRouteIndex];
    final List<String> requestHistory = _buildRequestHistoryForExpressionRoute(
      history: _expressionSequentialBaseHistory,
      route: route,
      assistantMessage: _expressionSequentialCurrentAssistantMessage,
    );
    _expressionSequentialCurrentAssistantMessage = null;
    await P.rwkv.sendMessages(
      requestHistory,
      forceChinese: _expressionSequentialForceChinese,
    );
  }

  Future<void> _startExpressionSequentialGeneration({
    required int messageId,
    required List<String> history,
    required List<ExpressionRoute> routes,
    required bool forceChinese,
    List<String> completedOutputs = const <String>[],
    int startRouteIndex = 0,
    String? currentAssistantMessage,
  }) async {
    _expressionSequentialActive = true;
    _expressionSequentialStopRequested = false;
    _expressionSequentialMessageId = messageId;
    _expressionSequentialCurrentRouteIndex = startRouteIndex;
    _expressionSequentialForceChinese = forceChinese;
    _expressionSequentialCurrentOutput = currentAssistantMessage ?? "";
    _expressionSequentialCurrentAssistantMessage = currentAssistantMessage;
    _expressionSequentialRoutes = <ExpressionRoute>[...routes];
    _expressionSequentialBaseHistory = <String>[...history];
    _expressionSequentialCompletedOutputs = <String>[...completedOutputs];
    receivedTokens.q = _buildExpressionSequentialBatchContent(
      completedOutputs: _expressionSequentialCompletedOutputs,
      currentOutput: currentAssistantMessage,
      totalCount: _expressionSequentialRoutes.length,
    );
    await _sendCurrentExpressionSequentialRoute();
  }

  Future<void> _advanceExpressionSequentialGenerationAfterStop() async {
    if (!_expressionSequentialActive) {
      return;
    }

    final int? messageId = _expressionSequentialMessageId;
    if (messageId == null) {
      _clearExpressionSequentialState();
      return;
    }

    final String currentOutput = _expressionSequentialCurrentOutput;
    final List<String> nextCompletedOutputs = <String>[
      ..._expressionSequentialCompletedOutputs,
      currentOutput,
    ];
    _expressionSequentialCompletedOutputs = nextCompletedOutputs;

    final String finalizedContent = _buildExpressionSequentialBatchContent(
      completedOutputs: nextCompletedOutputs,
      totalCount: _expressionSequentialRoutes.length,
    );
    receivedTokens.q = finalizedContent;

    if (_expressionSequentialStopRequested) {
      _clearExpressionSequentialState();
      return;
    }

    final int nextRouteIndex = _expressionSequentialCurrentRouteIndex + 1;
    if (nextRouteIndex >= _expressionSequentialRoutes.length) {
      _clearExpressionSequentialState();
      _fullyReceived(callingFunction: "_advanceExpressionSequentialGenerationAfterStop");
      return;
    }

    _expressionSequentialCurrentRouteIndex = nextRouteIndex;
    _expressionSequentialCurrentOutput = "";
    _expressionSequentialCurrentAssistantMessage = null;
    _scheduleRefreshLiveTokenCounts(
      messageId: messageId,
      liveBotContent: finalizedContent,
    );
    await _sendCurrentExpressionSequentialRoute();
  }

  bool _handleExpressionSequentialEvent(from_rwkv.FromRWKV event) {
    if (!_expressionSequentialActive) {
      return false;
    }

    final int? messageId = _expressionSequentialMessageId;
    if (messageId == null) {
      _clearExpressionSequentialState();
      return false;
    }

    switch (event) {
      case from_rwkv.GenerateStart _:
        P.rwkv.generating.q = true;
        return true;

      case from_rwkv.ResponseBufferContent res:
        _expressionSequentialCurrentOutput = res.responseBufferContent;
        final String liveContent = _buildExpressionSequentialBatchContent(
          completedOutputs: _expressionSequentialCompletedOutputs,
          currentOutput: res.responseBufferContent,
          totalCount: _expressionSequentialRoutes.length,
        );
        receivedTokens.q = liveContent;
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
        P.rwkv.generating.q = false;
        unawaited(_advanceExpressionSequentialGenerationAfterStop());
        return true;

      default:
        return false;
    }
  }

  List<String> _resolveExpressionSequentialSlotOutputs({
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

  ({List<String> completedOutputs, int startRouteIndex, String? currentAssistantMessage}) _buildExpressionSequentialResumeState({
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

  Future<bool> _resumeExpressionSequentialMessage({
    required int messageId,
  }) async {
    if (P.app.pageKey.q != .chat) {
      return false;
    }

    final Message? currentMessage = P.msg.pool.q[messageId];
    if (currentMessage == null) {
      return false;
    }

    final List<ExpressionRoute> routes = _resolveExpressionRoutesForMessage(currentMessage);
    if (routes.length <= 1) {
      return false;
    }
    if (_shouldUseExpressionBatchExecution(routes.length)) {
      return false;
    }

    final List<String>? baseHistory = _historyBeforeBotMessage(messageId: messageId);
    if (baseHistory == null || baseHistory.isEmpty) {
      return false;
    }

    final List<String> slotOutputs = _resolveExpressionSequentialSlotOutputs(
      message: currentMessage,
      routeCount: routes.length,
    );
    final resumeState = _buildExpressionSequentialResumeState(slotOutputs: slotOutputs);

    await _startExpressionSequentialGeneration(
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

  // TODO: 适时去掉 preferredDemoType
  Future<void> onSendButtonPressed({
    required DemoType preferredDemoType,
  }) async {
    final textToSend = textInInput.q.trim();

    if (P.app.demoType.q == .tts) {
      await P.talk.gen();
      return;
    }

    qq;
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    final inSee = P.app.pageKey.q == .see;
    if (inSee) {
      final hasAtLeastOneImage = P.msg.hasAtLeastOneImage.q;
      final imagePath = P.see.imagePath.q;
      if (!hasAtLeastOneImage && imagePath == null) {
        Alert.info(S.current.please_select_an_image_first);

        if (focusNode.hasFocus) {
          focusNode.unfocus();
        }

        final imagePath = await showImageSelector();
        if (imagePath == null) return;
        P.see.imagePath.q = imagePath;
        return;
      }
    }

    if (!inputHasContent.q) {
      Alert.info(S.current.chat_empty_message);
      return;
    }

    MsgNode? parentNode = P.msg.msgNode.q.wholeLatestNode;
    final parentMsg = P.msg.pool.q[parentNode.id];
    if (parentMsg != null && parentMsg.type == MessageType.text && !parentMsg.isMine && getIsBatch(parentMsg.content)) {
      final selection = P.msg.batchSelection(parentMsg).q;
      if (selection == null) {
        Alert.info(S.current.please_select_a_branch_to_continue_the_conversation, position: AlertPosition.top);
        return;
      }
    }

    focusNode.unfocus();
    textInInput.q = "";

    final _editingBotMessage = P.msg.editingBotMessage.q;

    if (_editingBotMessage) {
      final id = HF.milliseconds;
      final currentMessages = [...P.msg.list.q];
      final _editingIndex = P.msg.editingOrRegeneratingIndex.q!;
      final currentMessage = currentMessages[_editingIndex];
      receiveId.q = id;

      final newMsg = Message(
        id: id,
        content: textToSend,
        isMine: false,
        changing: false,
        paused: currentMessage.paused,
        modelName: currentMessage.modelName,
        runningMode: currentMessage.runningMode,
      );

      P.msg._syncMsg(id, newMsg);
      final userMsgNode = P.msg.msgNode.q.findParentByMsgId(currentMessage.id);
      if (userMsgNode == null) {
        qqe("We should found a user message node before a bot message node");
        return;
      }
      userMsgNode.add(MsgNode(id));
      P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
      P.conversation._syncNode();
      P.msg.editingOrRegeneratingIndex.q = null;
      Alert.success(S.current.bot_message_edited);
      return;
    }

    if (inSee) {
      final imagePath = P.see.imagePath.q;
      final isPureText = imagePath == null;

      if (P.rwkv.generating.q) {
        // qqw("TODO:");
        // 1. 添加 message 至 queue
        // 2. 在 ui 上渲染 queue
        // 3. 等待 prefill 完成后, 马上发送消息
        P.see.waitingText.q = textToSend;
        P.see.waitingImagePath.q = imagePath;
        P.see.imagePath.q = null;
        return;
      }

      if (isPureText) {
        await send(textToSend);
      } else {
        P.see.imagePath.q = null;
        if (P.msg.hasAtLeastOneImage.q) {
          P.msg._clear();
          await 10.msLater;
          P.rwkv.clearStates();
          await 10.msLater;
        }
        await send("", type: MessageType.userImage, imageUrl: imagePath);
        await 50.msLater;
        final finalTextToSend = "<image>$imagePath</image>" + textToSend.trim();
        await send(finalTextToSend);
      }
    } else {
      await send(textToSend);
    }
  }

  Future<void> onEditingComplete() async {
    qq;
  }

  Future<void> onKeyboardSubmitted(String aString) async {
    qqq(aString);
    final textToSend = textInInput.q.trim();

    final generating = P.rwkv.generating.q;

    if (generating) {
      Alert.info("Please wait for the previous message to be generated");
      return;
    }

    if (P.app.demoType.q == .tts) {
      await P.talk.gen();
      return;
    }

    if (textToSend.isEmpty) return;
    textInInput.q = "";
    focusNode.unfocus();
    await send(textToSend);
  }

  void cancelEditing({bool clearInput = false}) {
    final editingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (editingIndex == null && !clearInput) return;
    P.msg.editingOrRegeneratingIndex.q = null;
    if (!clearInput) return;
    textEditingController.clear();
    textInInput.q = "";
  }

  Future<void> onTapMessageList() async {
    qq;
    focusNode.unfocus();
    P.talk.dismissAllShown();
    cancelEditing(clearInput: true);
  }

  Future<void> onTapClearInput() async {
    qq;
    cancelEditing(clearInput: true);
  }

  Future<void> onTapEditInUserMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final content = P.msg.list.q[index].contentAndTails[0];
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  void onMessageTapped(Message msg) {
    if (P.rwkv.currentWorldType.q != null) {
      Focus.of(getContext()!).unfocus();
    }
    focusNode.unfocus();
    P.talk.dismissAllShown();
    P.msg.latestClicked.q = msg;
    if (msg.type == MessageType.ttsGeneration) {
      if (P.see.playing.q) {
        P.see.stopPlaying();
      } else {
        if (msg.changing) Alert.info(S.current.playing_partial_generated_audio);
        P.see.play(path: msg.audioUrl!);
      }
    }
  }

  void onCopyUserMessage(Message msg) {
    Alert.success(S.current.chat_copied_to_clipboard);
    if (msg.ttsTarget != null) {
      Clipboard.setData(ClipboardData(text: msg.ttsTarget!.replaceAll(Config.userMsgModifierSep, "").trim()));
      return;
    }
    final content = msg.content.replaceAll(Config.userMsgModifierSep, "").trim();
    if (content.isEmpty) {
      Alert.warning("No content to copy");
      return;
    }
    Clipboard.setData(ClipboardData(text: content));
  }

  Future<void> showUserMessageContextMenu({
    required BuildContext context,
    required bool canEdit,
    required bool canCopy,
    required int index,
    required Message msg,
  }) async {
    final canDeleteCurrentBranch = P.msg.siblingCount(msg) > 1;
    if (!canEdit && !canCopy && !canDeleteCurrentBranch) return;
    if (!P.app.isMobile.q) return;

    final selectedAction = await _showMobileUserMessageMenu(
      context: context,
      canEdit: canEdit,
      canCopy: canCopy,
      canDeleteCurrentBranch: canDeleteCurrentBranch,
    );
    if (selectedAction == null) return;

    if (selectedAction == .edit) {
      await onTapEditInUserMessageBubble(index: index);
      return;
    }

    if (selectedAction == .copy) {
      onCopyUserMessage(msg);
      return;
    }

    if (selectedAction == .deleteCurrentBranch) {
      await onDeleteBranchPressed(msg: msg);
    }
  }

  Future<_UserMessageMenuAction?> _showMobileUserMessageMenu({
    required BuildContext context,
    required bool canEdit,
    required bool canCopy,
    required bool canDeleteCurrentBranch,
  }) async {
    final s = S.of(context);
    final actions = <SheetAction<_UserMessageMenuAction>>[
      if (canEdit) SheetAction(label: s.edit, key: .edit),
      if (canCopy) SheetAction(label: s.copy_text, key: .copy),
      if (canDeleteCurrentBranch) SheetAction(label: s.delete_current_branch, key: .deleteCurrentBranch),
    ];

    return showModalActionSheet<_UserMessageMenuAction>(
      context: context,
      cancelLabel: s.cancel,
      actions: actions,
    );
  }

  Future<void> onTapEditInBotMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final content = P.msg.list.q[index].content;
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  Future<void> onRegeneratePressed({required int index, required DemoType preferredDemoType}) async {
    qqq("index: $index");
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    final userMessage = P.msg.list.q[index - 1];
    P.msg.editingOrRegeneratingIndex.q = index;
    textInInput.q = "";
    focusNode.unfocus();
    final content = userMessage.contentAndTails.first;
    await send(content, isRegenerate: true);
  }

  Future<void> scrollToBottom({Duration? duration, bool? animate = true}) async {
    await scrollTo(offset: 0, duration: duration, animate: animate);
  }

  Future<void> scrollTo({required double offset, Duration? duration, bool? animate = true}) async {
    if (scrollController.hasClients == false) return;
    if (scrollController.offset == offset) return;
    if (animate == true) {
      await scrollController.animateTo(
        offset,
        duration: duration ?? 300.ms,
        curve: Curves.easeInOut,
      );
    } else {
      scrollController.jumpTo(offset);
    }
  }

  Future<void> startNewChat() async {
    if (P.rwkv.generating.q) await onStopButtonPressed();
    await 100.msLater;
    // Alert.success(S.current.new_chat_started);
    dismissNewConversationGuide();
    P.msg._clear();
    P.rwkv.clearStates();
    P.conversation.currentCreatedAtUS.q = P.msg.msgNode.q.createAtInUS;
  }

  void dismissNewConversationGuide() {
    if (newConversationGuideConversationId.q == null) return;
    newConversationGuideConversationId.q = null;
  }

  void toggleCompletionMode() {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    final r = !completionMode.q;
    completionMode.q = r;
    P.rwkv.setGenerateMode(r);
  }

  Future<void> stopCompletion() async {
    P.rwkv.stop();
  }

  /// 拼装消息, 调用 rwkv 的 sendMessages 方法
  Future<void> send(
    String raw, {
    MessageType type = MessageType.text,
    String? imageUrl,
    String? audioUrl,
    int? audioLength,
    bool withHistory = true,
    bool isRegenerate = false,
  }) async {
    assert(!raw.contains(Config.userMsgModifierSep));

    raw = raw.trim();
    String message = raw;

    if (!checkModelSelection(preferredDemoType: .chat)) return;
    _clearExpressionSequentialState();

    final currentModel = P.rwkv.latestModel.q!;

    final thinkingMode = P.rwkv.thinkingMode.q;

    MsgNode? parentNode = P.msg.msgNode.q.wholeLatestNode;
    final editingOrRegeneratingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (editingOrRegeneratingIndex != null) {
      final currentMessage = P.msg.findByIndex(editingOrRegeneratingIndex);
      if (currentMessage == null) {
        qqe("currentMessage is null");
        return;
      }

      if (isRegenerate) {
        parentNode = P.msg.msgNode.q.findParentByMsgId(currentMessage.id);
      } else {
        // 以该消息的父节点作为新消息的父结点
        parentNode = P.msg.msgNode.q.findParentByMsgId(currentMessage.id);
      }

      if (parentNode == null) {
        qqe("parentNode is null");
        return;
      }
    }

    late final Message? userMsg;

    final id = HF.milliseconds;

    if (thinkingMode.userMsgFooter.isNotEmpty) {
      message = message + thinkingMode.userMsgFooter;
    }

    final parentMsg = P.msg.pool.q[parentNode.id];
    if (isRegenerate) {
      // 重新生成 Bot 消息, 所以, 不添加新的用户消息
      userMsg = parentMsg;
      // 但是, 需要移除旧的 bot 消息
      parentNode.latest = null;
      if (parentMsg != null) {
        final newContent = parentMsg.content + Config.userMsgModifierSep + thinkingMode.userMsgFooter;
        final newUserMsg = parentMsg.copyWith(content: newContent);
        P.msg._syncMsg(parentMsg.id, newUserMsg);
      }
    } else {
      // 新增或编辑了用户消息

      if (parentMsg != null && parentMsg.type == MessageType.text && !parentMsg.isMine && getIsBatch(parentMsg.content)) {
        final selection = P.msg.batchSelection(parentMsg).q;
        if (selection != null) {
          final finalizedContent = parentMsg.content.split(Config.batchMarker)[selection];
          final finalizedMsg = parentMsg.copyWith(
            content: finalizedContent,
            clearBatchSlotLabels: true,
          );
          P.msg._syncMsg(parentMsg.id, finalizedMsg);

          // 重新计算 token count（从 batch 全量变为单 slot）
          unawaited(
            _refreshTokenCountsForMessage(
              messageId: parentMsg.id,
              overrideBotContent: finalizedContent,
              persistToMessage: true,
            ),
          );

          // Also finalize the paired user batch message if it exists
          final userParentNode = P.msg.msgNode.q.findParentByMsgId(parentMsg.id);
          if (userParentNode != null) {
            final userParentMsg = P.msg.pool.q[userParentNode.id];
            if (userParentMsg != null && userParentMsg.isMine) {
              final userParts = userParentMsg.content.split(Config.userMsgModifierSep);
              final userRawContent = userParts[0];
              final userTail = userParts.length > 1 ? userParts.sublist(1).join(Config.userMsgModifierSep) : "";
              if (getIsBatch(userRawContent)) {
                final userBatch = userRawContent.split(Config.batchMarker);
                if (selection < userBatch.length) {
                  final selectedQuestion = userBatch[selection];
                  final finalizedUserContent = userTail.isNotEmpty
                      ? selectedQuestion + Config.userMsgModifierSep + userTail
                      : selectedQuestion;
                  P.msg._syncMsg(userParentMsg.id, userParentMsg.copyWith(content: finalizedUserContent));
                }
              }
            }
          }
        } else {
          Alert.info(S.current.please_select_a_branch_to_continue_the_conversation, position: AlertPosition.bottom);
          return;
        }
      }

      final storedContent = raw + Config.userMsgModifierSep + thinkingMode.userMsgFooter;
      userMsg = Message(
        id: id,
        content: storedContent,
        isMine: true,
        type: type,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        audioLength: audioLength,
        paused: false,
      );
      P.msg._syncMsg(id, userMsg);
      parentNode = parentNode.add(MsgNode(id));
    }

    // 更新消息 id 列表
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();

    34.msLater.then((_) {
      scrollToBottom();
    });

    if (type == MessageType.userImage) {
      // 在之前的操作中已经注入了 LLM 了
      return;
    }

    P.msg.clearBottomDetailsStateInScope(scope: "chat_bot_message_bottom");

    final receiveId = HF.milliseconds + 1;
    this.receiveId.q = receiveId;

    List<String> history = withHistory ? _history() : <String>[];

    P.msg.editingOrRegeneratingIndex.q = null;

    receivedTokens.q = "";
    P.rwkv.generating.q = true;
    _liveTokenCountThrottler.cancel();

    final receiveMsg = Message(
      id: receiveId,
      content: "",
      isMine: false,
      changing: true,
      paused: false,
      modelName: currentModel.name,
      runningMode: thinkingMode.toString(),
      rawDecodeParams: _resolveDecodeParamsSnapshotRaw(),
      batchSlotLabels: P.app.pageKey.q == .chat && expressionMode.q.activeCount > 1 ? expressionMode.q.enabledLabelsInOrder : null,
    );

    P.msg.pool.q[receiveId] = receiveMsg;
    parentNode.add(MsgNode(receiveId));
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
    _scheduleRefreshLiveTokenCounts(messageId: receiveId, liveBotContent: "");

    history = withHistory ? await _historyWithWebSearch(receiveId, history) : [message];
    final inSee = P.app.pageKey.q == .see;
    final forceChinese = inSee && message.containsChinese;

    if (!inSee) {
      final List<ExpressionRoute> routes = expressionMode.q.enabledRoutesInOrder;
      if (routes.length > 1) {
        if (_shouldUseExpressionBatchExecution(routes.length)) {
          final List<to_rwkv.ChatBatchSlotConfig> slotConfigs = _buildExpressionModeSlotConfigs(
            history: history,
            routes: routes,
          );
          P.rwkv.sendMessages(
            history,
            forceChinese: forceChinese,
            overrideBatchSlotConfigs: slotConfigs,
          );
          _checkSensitive(raw);
          return;
        }
        final int currentReceiveId = this.receiveId.q!;
        unawaited(
          _startExpressionSequentialGeneration(
            messageId: currentReceiveId,
            history: history,
            routes: routes,
            forceChinese: forceChinese,
          ),
        );
        _checkSensitive(raw);
        return;
      }

      final ExpressionRoute route = routes.first;
      final List<String> singleRouteHistory = _buildRequestHistoryForExpressionRoute(
        history: history,
        route: route,
      );
      P.rwkv.sendMessages(
        singleRouteHistory,
        batchSize: batchEnabled.q ? batchCount.q : 1,
        forceChinese: forceChinese,
      );
      _checkSensitive(raw);
      return;
    }

    final batchSize = inSee ? 1 : (batchEnabled.q ? batchCount.q : 1);
    P.rwkv.sendMessages(history, batchSize: batchSize, forceChinese: forceChinese);

    _checkSensitive(raw);
  }

  Future<void> onStopButtonPressed({bool wantHaptic = true}) async {
    qqq("receiveId: ${receiveId.q}");
    if (wantHaptic) P.app.hapticLight();
    await 1.msLater;
    final id = receiveId.q;
    if (id == null) {
      qqw("message id is null");
      return;
    }
    if (!P.rwkv.generating.q) {
      return;
    }
    _pauseMessageById(id: id);
  }

  Future<void> resumeMessageById({required int id, bool withHaptic = true}) async {
    qq;
    if (withHaptic) P.app.hapticLight();
    _clearExpressionSequentialState();
    receiveId.q = id;
    _updateMessageById(
      id: id,
      changing: true,
      paused: false,
      callingFunction: "resumeMessageById",
    );
    _liveTokenCountThrottler.cancel();
    final bool resumedSequentially = await _resumeExpressionSequentialMessage(messageId: id);
    if (resumedSequentially) {
      return;
    }
    final expressionResumeRequest = _buildExpressionModeResumeRequest(messageId: id);
    if (expressionResumeRequest != null) {
      P.rwkv.sendMessages(
        expressionResumeRequest.messages,
        batchSize: expressionResumeRequest.slotConfigs == null && batchEnabled.q ? batchCount.q : 1,
        overrideBatchSlotConfigs: expressionResumeRequest.slotConfigs,
      );
      _scheduleRefreshLiveTokenCounts(messageId: id, liveBotContent: receivedTokens.q);
      return;
    }
    P.rwkv.sendMessages(_history(), batchSize: batchEnabled.q ? batchCount.q : 1);
    _scheduleRefreshLiveTokenCounts(messageId: id, liveBotContent: receivedTokens.q);
  }

  Future<void> onBatchInferenceSwitchChanged(
    bool value, {
    bool triggeredByExpressionMode = false,
  }) async {
    if (!triggeredByExpressionMode) {
      P.app.hapticLight();
      if (expressionMode.q.activeCount > 1) {
        resetExpressionMode();
        return;
      }
    }
    batchEnabled.q = value;
    if (!value) {
      batchCount.q = Argument.batchCount.defaults.toInt();
      return;
    }

    final temperature = P.rwkv.arguments(Argument.temperature).q;
    final topP = P.rwkv.arguments(Argument.topP).q;
    final presencePenalty = P.rwkv.arguments(Argument.presencePenalty).q;
    final frequencyPenalty = P.rwkv.arguments(Argument.frequencyPenalty).q;
    final penaltyDecay = P.rwkv.arguments(Argument.penaltyDecay).q;

    final newValue = List<SamplerAndPenaltyParam>.generate(
      100,
      (index) => SamplerAndPenaltyParam(
        temperature: temperature,
        topP: topP,
        presencePenalty: presencePenalty,
        frequencyPenalty: frequencyPenalty,
        penaltyDecay: penaltyDecay,
      ),
    );

    P.rwkv.frontendBatchParams.q = newValue;
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    P.rwkv.send(
      to_rwkv.SetSamplerAndPenaltyParams(
        temperatures: newValue.map((e) => e.temperature).toList(),
        topKs: newValue.map((_) => 500.0).toList(),
        topPs: newValue.map((e) => e.topP).toList(),
        presencePenalties: newValue.map((e) => e.presencePenalty).toList(),
        frequencyPenalties: newValue.map((e) => e.frequencyPenalty).toList(),
        penaltyDecays: newValue.map((e) => e.penaltyDecay).toList(),
        modelID: modelID,
      ),
    );
    final currentBatchCount = batchCount.q;
    P.rwkv.send(to_rwkv.GetSamplerAndPenaltyParams(batchSize: currentBatchCount, modelID: modelID));
  }

  void onManualBatchCountChanged(int value) {
    if (batchCount.q == value) {
      return;
    }
    batchCount.q = value;
    if (expressionMode.q.activeCount > 1 && value != expressionMode.q.activeCount) {
      resetExpressionMode();
    }
  }

  Future<void> tryLoadLastChatModel() async {
    await 500.msLater;

    final last = P.preference.lastChatModel.q;
    if (last == null) {
      ModelSelector.show(showNeko: P.app.pageKey.q == .neko);
      return;
    }

    final String savedFileName = last["fileName"];
    final int savedFileSize = last["fileSize"];

    final fileInfo = P.remote.chatWeights.q.firstWhereOrNull(
      (e) => e.fileName == savedFileName && e.fileSize == savedFileSize,
    );
    final localFile = fileInfo != null ? P.remote.locals(fileInfo).q : null;

    if (fileInfo == null || localFile == null || !localFile.hasFile || fileInfo.backend == null) {
      ModelSelector.show(showNeko: P.app.pageKey.q == .neko);
      return;
    }

    // 以上校验通过，确认将要自动加载，开始显示加载动画
    isAutoLoadingModel.q = true;
    try {
      P.rwkv.clearStates();
      await P.rwkv.loadChat(fileInfo: fileInfo);

      final batchAllowed = fileInfo.tags.contains("batch");
      if (!batchAllowed) {
        if (expressionMode.q.activeCount > 1) {
          resetExpressionMode();
        } else {
          batchEnabled.q = false;
          batchCount.q = Argument.batchCount.defaults.toInt();
        }
      } else if (expressionMode.q.activeCount > 1) {
        await _syncBatchStateForExpressionMode(activeCount: expressionMode.q.activeCount);
      }

      final isTranslate = fileInfo.tags.contains("translate");
      final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
      if (modelID == null) return;

      if (isTranslate) {
        if (P.translator.enToZh.q) {
          P.rwkv.send(to_rwkv.SetUserRole("English", modelID: modelID));
          P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "Chinese", modelID: modelID));
        } else {
          P.rwkv.send(to_rwkv.SetUserRole("Chinese", modelID: modelID));
          P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "English", modelID: modelID));
        }
        await P.rwkv.setModelConfig(thinkingMode: .none, prompt: "<EOD>", setPrompt: true);
        P.backend.start();
      } else {
        P.rwkv.send(to_rwkv.SetUserRole("User", modelID: modelID));
        P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "Assistant", modelID: modelID));
      }

      if (!isTranslate) {
        if (P.rwkv.currentModelIsBefore20250922.q) {
          P.rwkv.setModelConfig(thinkingMode: .lighting);
        } else {
          P.rwkv.setModelConfig(thinkingMode: .fast);
        }
      }

      for (var i = 0; i < 3; i++) {
        (500 * i).msLater.then((_) {
          P.rwkv.send(to_rwkv.GetSupportedBatchSizes(modelID: modelID));
        });
      }
    } catch (e) {
      qqe("Failed to auto load chat model: $e");
      ModelSelector.show(showNeko: P.app.pageKey.q == .neko);
    } finally {
      isAutoLoadingModel.q = false;
    }
  }
}

/// Private methods
extension _$Chat on _Chat {
  Future<void> _init() async {
    switch (P.app.demoType.q) {
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
        return;
      case .chat:
      case .tts:
      case .see:
    }
    qq;

    textEditingController.addListener(_onTextEditingControllerValueChanged);
    textInInput.l(_onTextChanged);

    P.app.pageKey.l(_onPageKeyChanged);

    P.rwkv.oldBroadcastStream.listen(_onOldStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
    final event = P.rwkv.broadcastStream;
    event.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);

    /// update the conversation subtitle
    event
        .whereType<from_rwkv.ResponseBufferContent>()
        .where((e) => P.msg.list.q.length <= 2)
        .throttleTime(const Duration(milliseconds: 500), trailing: true, leading: true)
        .listen((e) {
          final r = e.responseBufferContent.replaceAll('\n', '').replaceAll('</think>', '').replaceAll('<think>', '');
          P.conversation.updateCurrentConvSubtitle(r);
        });

    P.see.audioFileStreamController.stream.listen(_onNewFileReceived);
    focusNode.addListener(_onFocusNodeChanged);
    hasFocus.q = focusNode.hasFocus;
    P.app.lifecycleState.lb(_onLifecycleStateChanged);

    P.rwkv.supportedBatchSizes.l(_onSupportedBatchSizesChanged);

    batchCount.l(_onBatchCountChanged);
    batchVW.l(_onBatchVWChanged);
    _loadBatchVW();

    scrollController.addListener(_onScroll);
    P.msg.ids.l(_onMessageIdsChangedForTokenCount);
    _onMessageIdsChangedForTokenCount(P.msg.ids.q);
  }

  void _onScroll() async {
    if (scrollController.hasClients == false) return;
    final position = scrollController.position;
    final extentAfter = position.extentAfter;
    if (extentAfter > 0) {
      listAtTop.q = false;
    } else {
      listAtTop.q = true;
    }
  }

  void _onConversationTokenCountObserved({
    required int? conversationTokensCount,
  }) {
    if (conversationTokensCount == null) return;
    final int currentEffectiveBatchCount = effectiveBatchEnabled.q ? effectiveBatchCount.q : 1;
    final int threshold = Config.newConversationTokenReminderThreshold * currentEffectiveBatchCount;
    if (conversationTokensCount < threshold) return;

    final conversationId = P.msg.msgNode.q.createAtInUS;
    final shownConversationIds = tokenReminderShownConversationIds.q;
    if (shownConversationIds.contains(conversationId)) return;

    tokenReminderShownConversationIds.q = {
      ...shownConversationIds,
      conversationId,
    };
    newConversationGuideConversationId.q = conversationId;
    Alert.info(S.current.conversation_token_limit_recommend_new_chat);
  }

  void _onBatchCountChanged(int value) async {
    if (expressionMode.q.activeCount > 1 && value != expressionMode.q.activeCount) {
      resetExpressionMode();
    }

    late final List<SamplerAndPenaltyParam> newFrontendBatchParams;
    newFrontendBatchParams = [
      ...P.rwkv.frontendBatchParams.q,
      P.rwkv.frontendBatchParams.q.last,
    ];

    P.rwkv.frontendBatchParams.q = newFrontendBatchParams;
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    P.rwkv.send(
      to_rwkv.SetSamplerAndPenaltyParams(
        temperatures: newFrontendBatchParams.map((e) => e.temperature).toList(),
        topKs: newFrontendBatchParams.map((_) => 500.0).toList(),
        topPs: newFrontendBatchParams.map((e) => e.topP).toList(),
        presencePenalties: newFrontendBatchParams.map((e) => e.presencePenalty).toList(),
        frequencyPenalties: newFrontendBatchParams.map((e) => e.frequencyPenalty).toList(),
        penaltyDecays: newFrontendBatchParams.map((e) => e.penaltyDecay).toList(),
        modelID: modelID,
      ),
    );
    P.rwkv.send(to_rwkv.GetSamplerAndPenaltyParams(batchSize: value, modelID: modelID));
  }

  void _onBatchVWChanged(int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt("halo_state.batchVW", value);
  }

  void _loadBatchVW() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getInt("halo_state.batchVW");
    if (saved != null) batchVW.q = saved;
  }

  void _onSupportedBatchSizesChanged(List<int> supportedBatchSizes) {
    if (supportedBatchSizes.isEmpty) {
      batchEnabled.q = false;
      batchCount.q = Argument.batchCount.defaults.toInt();
      if (expressionMode.q.activeCount > 1) {
        expressionMode.q = const ExpressionModeState();
      }
      return;
    }
    final max = supportedBatchSizes.max;
    if (expressionMode.q.activeCount > 1 && max < expressionMode.q.activeCount) {
      resetExpressionMode();
      return;
    }
    if (max < batchCount.q) batchCount.q = max;
  }

  Future<void> _checkSensitive(String content) async {
    final isSensitive = await P.guard.isSensitive(content);
    if (!isSensitive) return;

    final id = receiveId.q;
    if (id == null) {
      qqe("receiveId is null");
      return;
    }

    await 1.msLater;

    _pauseMessageById(id: id, isSensitive: true);
  }

  void _onLifecycleStateChanged(AppLifecycleState? previous, AppLifecycleState next) {
    if (P.app.isDesktop.q) return;
    final isToBackground = next == AppLifecycleState.paused || next == AppLifecycleState.hidden;
    if (isToBackground) {
      if (receiveId.q != null && _autoPauseId.q == null && P.rwkv.generating.q == true) {
        _autoPauseId.q = receiveId.q!;
        _pauseMessageById(id: receiveId.q!);
      }
    } else {
      if (_autoPauseId.q != null) {
        resumeMessageById(id: _autoPauseId.q!, withHaptic: false);
        _autoPauseId.q = null;
      }
    }
    qqq("autoPauseId: ${_autoPauseId.q}, receiveId: ${receiveId.q}, state: $next");
  }

  /// 获取历史记录
  List<String> _history() {
    final messages = P.msg.list.q.where((msg) => msg.type == MessageType.text).toList();

    if (messages.isEmpty) return [];

    // 如果只有一条消息，使用模板
    if (messages.length == 1) {
      final template = P.preference.promptTemplate.newChatTemplate.trim();
      if (template.isNotEmpty) {
        return template.split("\n\n").where((e) => e.isNotEmpty).toList();
      }
    }

    final result = <String>[];

    // 按用户消息和机器人消息配对处理
    for (int i = 0; i < messages.length; i += 2) {
      final userMsg = messages[i];
      final botMsg = i + 1 < messages.length ? messages[i + 1] : null;

      // 处理用户消息
      final String userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
      result.add(userContent);

      // 处理机器人消息（如果存在）
      if (botMsg != null) {
        final botContent = botMsg.getHistoryContent();
        result.add(botContent);
      }
    }

    return result;
  }

  List<String>? _historyBeforeBotMessage({required int messageId}) {
    final MsgNode? targetNode = P.msg.msgNode.q.findNodeByMsgId(messageId);
    final MsgNode? parentNode = targetNode?.parent;
    if (targetNode == null || parentNode == null) {
      return null;
    }

    final List<int> idsFromTargetToRoot = P.msg.msgNode.q.msgIdsFrom(parentNode);
    final List<int> orderedPathIds = idsFromTargetToRoot.reversed.where((int id) => id != 0).toList();
    if (orderedPathIds.isEmpty) {
      return null;
    }

    final List<Message> scopedMessages = <Message>[];
    for (final int id in orderedPathIds) {
      final Message? pathMessage = P.msg.pool.q[id];
      if (pathMessage == null) {
        continue;
      }
      if (pathMessage.type != MessageType.text) {
        continue;
      }
      scopedMessages.add(pathMessage);
    }
    if (scopedMessages.isEmpty) {
      return null;
    }

    final List<String> history = <String>[];
    final bool isSingleTurnPath = scopedMessages.length == 1 && scopedMessages.first.isMine;
    if (isSingleTurnPath) {
      final String template = P.preference.promptTemplate.newChatTemplate.trim();
      if (template.isNotEmpty) {
        history.addAll(template.split("\n\n").where((String entry) => entry.isNotEmpty));
      }
    }

    for (int i = 0; i < scopedMessages.length; i = i + 2) {
      final Message userMsg = scopedMessages[i];
      final Message? botMsg = i + 1 < scopedMessages.length ? scopedMessages[i + 1] : null;

      final String userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
      history.add(userContent);

      if (botMsg == null) {
        continue;
      }
      history.add(botMsg.getHistoryContent());
    }

    return history;
  }

  Future<void> _pauseMessageById({required int id, bool isSensitive = false}) async {
    qq;

    final msg = P.msg.pool.q[id];
    if (msg == null) {
      qqw("message not found");
      return;
    }

    if (msg.paused) {
      qqw("message already paused");
      return;
    }

    final (double? snapshotPrefillSpeed, double? snapshotDecodeSpeed) = _currentSpeedSnapshotForStore();
    final finalPrefillSpeed = snapshotPrefillSpeed ?? msg.prefillSpeed;
    final finalDecodeSpeed = snapshotDecodeSpeed ?? msg.decodeSpeed;
    final currentGeneratedContent = id == receiveId.q ? receivedTokens.q : msg.content;
    final finalizedContent = currentGeneratedContent.isNotEmpty ? currentGeneratedContent : msg.content;

    _liveTokenCountThrottler.cancel();
    if (_expressionSequentialActive && _expressionSequentialMessageId == id) {
      _expressionSequentialStopRequested = true;
    }
    P.rwkv.stop();

    final newMsg = msg.copyWith(
      content: finalizedContent,
      paused: true,
      changing: false,
      isSensitive: isSensitive,
      prefillSpeed: finalPrefillSpeed,
      decodeSpeed: finalDecodeSpeed,
    );
    P.msg._syncMsg(id, newMsg);
    unawaited(
      _refreshTokenCountsForMessage(
        messageId: id,
        overrideBotContent: finalizedContent,
        persistToMessage: true,
      ),
    );

    unawaited(P.telemetry.maybeReport(
      prefillSpeed: finalPrefillSpeed,
      decodeSpeed: finalDecodeSpeed,
    ));
  }

  Future<void> _onFocusNodeChanged() async {
    hasFocus.q = focusNode.hasFocus;
  }

  Future<void> _onNewFileReceived((File, int) event) async {
    final demoType = P.app.demoType.q;

    if (demoType == .tts || demoType == .chat) {
      final (file, length) = event;
      final path = file.path;
      qqq("new file received: $path, length: $length");
      P.talk.selectSourceAudioPath.q = path;
      P.talk.selectedSpkName.q = null;
    }
  }

  void _onPageKeyChanged(PageKey pageKey) async {
    final model = P.rwkv.latestModel.q;
    final isTTS = model?.isTTS ?? false;
    final isSee = model?.worldType != null;
    switch (pageKey) {
      case .completion:
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) await P.rwkv._releaseAllModels();
        break;
      case .chat:
        P.rwkv.updateSystemPrompt();
        P.app.demoType.q = .chat;
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) {
          P.rwkv.currentWorldType.q = null;
          await P.rwkv._releaseAllModels();
        }
        break;
      case .talk:
        if (!isTTS) {
          P.rwkv.currentGroupInfo.q = null;
          await P.rwkv._releaseAllModels();
        }
        break;
      default:
        break;
    }
    textInInput.q = "";
    textEditingController.text = "";
    focusNode.unfocus();
    hasFocus.q = false;
  }

  void _onTextEditingControllerValueChanged() {
    final textInController = textEditingController.text.replaceAll(Config.userMsgModifierSep, "");
    if (textInInput.q != textInController) textInInput.q = textInController;
  }

  void _onTextChanged(String next) {
    // qqq("_onTextChanged");
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
  }

  void _fullyReceived({String? callingFunction}) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator || pageKey == .ocr || pageKey == .benchmark || pageKey == .completion) return;
    qqq("callingFunction: $callingFunction");
    _liveTokenCountThrottler.cancel();

    final id = receiveId.q;

    if (id == null) {
      qqw("receiveId is null");
      return;
    }

    if (id == Config.chatPrefillId) return;

    final currentMessage = P.msg.pool.q[id];
    if (currentMessage == null) {
      qqe("message not found when fully received: $id");
      return;
    }

    if (!currentMessage.changing) {
      qqq("skip fullyReceived for non-changing message: $id");
      return;
    }

    final receivedTokens = this.receivedTokens.q;
    final (double? snapshotPrefillSpeed, double? snapshotDecodeSpeed) = _currentSpeedSnapshotForStore();
    final finalPrefillSpeed = snapshotPrefillSpeed ?? currentMessage.prefillSpeed;
    final finalDecodeSpeed = snapshotDecodeSpeed ?? currentMessage.decodeSpeed;

    _updateMessageById(
      id: id,
      content: receivedTokens,
      changing: false,
      prefillSpeed: finalPrefillSpeed,
      decodeSpeed: finalDecodeSpeed,
      callingFunction: callingFunction,
    );
    unawaited(
      _refreshTokenCountsForMessage(
        messageId: id,
        overrideBotContent: receivedTokens,
        persistToMessage: true,
      ),
    );

    _prefillAfterReply();

    unawaited(P.telemetry.maybeReport(
      prefillSpeed: finalPrefillSpeed,
      decodeSpeed: finalDecodeSpeed,
    ));
  }

  static final _thinkTagRegex = RegExp(r'<think>[\s\S]*?</think>');

  void _prefillAfterReply() {
    final pageKey = P.app.pageKey.q;
    if (pageKey != .chat) return;

    final messages = P.msg.list.q.where((msg) => msg.type == MessageType.text).toList();
    if (messages.isEmpty) return;
    if (messages.length % 2 != 0) return;

    final history = <String>[];
    for (int i = 0; i < messages.length; i += 2) {
      final userMsg = messages[i];
      final botMsg = i + 1 < messages.length ? messages[i + 1] : null;

      history.add(userMsg.getContentForHistoryWithRef(botMsg?.reference));

      if (botMsg != null) {
        final content = botMsg.content.replaceAll(_thinkTagRegex, '').trim();
        history.add(content);
      }
    }

    receiveId.q = Config.chatPrefillId;
    P.rwkv.sendMessages(history, maxLength: 0);
  }

  /// Update a message by id
  ///
  /// Should follow [Message] class
  void _updateMessageById({
    required int id,
    String? content,
    bool? isMine,
    bool? changing,
    MessageType? type,
    String? imageUrl,
    String? audioUrl,
    int? audioLength,
    bool? isReasoning,
    bool? paused,
    String? callingFunction,
    bool? isSensitive,
    RefInfo? reference,
    double? prefillSpeed,
    double? decodeSpeed,
    int? messageTokensCount,
    int? conversationTokensCount,
  }) {
    if (completionMode.q) {
      return;
    }

    if (id == Config.seePrefillId) {
      qqw("see prefill id: $id");
      return;
    }

    if (id == Config.chatPrefillId) {
      qqw("chat prefill id: $id");
      return;
    }

    final msg = P.msg.pool.q[id];
    if (msg == null) {
      qqe("message not found: id: $id");
      Sentry.captureException(Exception("message not found, callingFunction: $callingFunction"), stackTrace: StackTrace.current);
      return;
    }
    final newMsg = msg.copyWith(
      content: content,
      isMine: isMine,
      changing: changing,
      type: type,
      reference: reference,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      audioLength: audioLength,
      isReasoning: isReasoning,
      paused: paused,
      isSensitive: isSensitive,
      prefillSpeed: prefillSpeed,
      decodeSpeed: decodeSpeed,
      messageTokensCount: messageTokensCount,
      conversationTokensCount: conversationTokensCount,
    );
    P.msg._syncMsg(id, newMsg);
  }

  (double? prefillSpeed, double? decodeSpeed) _currentSpeedSnapshotForStore() {
    final currentPrefillSpeed = P.rwkv.prefillSpeed.q;
    final currentDecodeSpeed = P.rwkv.decodeSpeed.q;
    final snapshotPrefillSpeed = currentPrefillSpeed > 0 ? currentPrefillSpeed : null;
    final snapshotDecodeSpeed = currentDecodeSpeed > 0 ? currentDecodeSpeed : null;
    return (snapshotPrefillSpeed, snapshotDecodeSpeed);
  }

  void _onMessageIdsChangedForTokenCount(List<int> messageIds) {
    _refreshTokenCountEpoch = _refreshTokenCountEpoch + 1;
    final epoch = _refreshTokenCountEpoch;
    unawaited(_refreshMissingTokenCountsForMessages(messageIds: messageIds, epoch: epoch));
  }

  Future<void> _refreshMissingTokenCountsForMessages({
    required List<int> messageIds,
    required int epoch,
  }) async {
    for (final messageId in messageIds) {
      if (epoch != _refreshTokenCountEpoch) return;
      final message = P.msg.pool.q[messageId];
      if (message == null || message.isMine || message.type != MessageType.text) continue;
      final existingMessageCount = P.msg.getBottomMessageTokensCount(messageId: messageId);
      final existingConversationCount = P.msg.getBottomConversationTokensCount(messageId: messageId);
      final persistedMessageCount = message.messageTokensCount;
      final persistedConversationCount = message.conversationTokensCount;
      final hasCachedCount = existingMessageCount != null && existingConversationCount != null;
      final hasPersistedCount = persistedMessageCount != null && persistedConversationCount != null;
      if (hasCachedCount || hasPersistedCount) {
        final observedConversationCount = persistedConversationCount ?? existingConversationCount;
        _onConversationTokenCountObserved(conversationTokensCount: observedConversationCount);
        if (!message.changing && hasPersistedCount && !hasCachedCount) {
          P.msg.setBottomTokensCount(
            messageId: messageId,
            messageTokensCount: persistedMessageCount,
            conversationTokensCount: persistedConversationCount,
          );
        }
        continue;
      }
      final overrideBotContent = message.changing && receiveId.q == messageId ? receivedTokens.q : null;
      await _refreshTokenCountsForMessage(
        messageId: messageId,
        overrideBotContent: overrideBotContent,
        persistToMessage: !message.changing,
      );
    }
  }

  void _scheduleRefreshLiveTokenCounts({
    required int messageId,
    required String liveBotContent,
  }) {
    _liveTokenCountThrottler.call(() {
      final latestMessage = P.msg.pool.q[messageId];
      if (latestMessage == null || !latestMessage.changing) return;
      unawaited(_refreshTokenCountsForMessage(messageId: messageId, overrideBotContent: liveBotContent));
    });
  }

  Future<void> _refreshTokenCountsForMessage({
    required int messageId,
    String? overrideBotContent,
    bool persistToMessage = false,
  }) async {
    final message = P.msg.pool.q[messageId];
    if (message == null || message.isMine || message.type != MessageType.text) return;

    String botContent = overrideBotContent ?? message.content;
    if (botContent.isEmpty && messageId == receiveId.q) {
      botContent = receivedTokens.q;
    }

    final history = _historyForTokenCountUntilMessage(
      messageId: messageId,
      overrideBotContent: botContent,
    );
    if (history == null || history.isEmpty) return;

    final counts = await Future.wait([
      P.rwkv.calculateTokensCountRaw(text: botContent),
      P.rwkv.calculateTokensCountFromMessages(messages: history),
    ]);
    final messageTokensCount = counts[0];
    final conversationTokensCount = counts[1];
    if (messageTokensCount == null && conversationTokensCount == null) return;
    final latestMessage = P.msg.pool.q[messageId];
    if (latestMessage == null) return;
    final observedConversationTokensCount = conversationTokensCount ?? latestMessage.conversationTokensCount;
    _onConversationTokenCountObserved(conversationTokensCount: observedConversationTokensCount);

    P.msg.setBottomTokensCount(
      messageId: messageId,
      messageTokensCount: messageTokensCount,
      conversationTokensCount: conversationTokensCount,
    );

    if (!persistToMessage) return;

    final resolvedMessageTokensCount = messageTokensCount ?? latestMessage.messageTokensCount;
    final resolvedConversationTokensCount = conversationTokensCount ?? latestMessage.conversationTokensCount;
    if (resolvedMessageTokensCount == null && resolvedConversationTokensCount == null) return;

    final noMessageCountChanges = resolvedMessageTokensCount == latestMessage.messageTokensCount;
    final noConversationCountChanges = resolvedConversationTokensCount == latestMessage.conversationTokensCount;
    if (noMessageCountChanges && noConversationCountChanges) return;

    final updatedMessage = latestMessage.copyWith(
      messageTokensCount: resolvedMessageTokensCount,
      conversationTokensCount: resolvedConversationTokensCount,
    );
    await P.msg._syncMsg(messageId, updatedMessage);
  }

  List<String>? _historyForTokenCountUntilMessage({
    required int messageId,
    String? overrideBotContent,
  }) {
    final targetNode = P.msg.msgNode.q.findNodeByMsgId(messageId);
    if (targetNode == null) return null;
    final idsFromTargetToRoot = P.msg.msgNode.q.msgIdsFrom(targetNode);
    final orderedPathIds = idsFromTargetToRoot.reversed.where((int id) => id != 0).toList();
    if (orderedPathIds.isEmpty) return null;

    final scopedMessages = <Message>[];
    for (final id in orderedPathIds) {
      final pathMessage = P.msg.pool.q[id];
      if (pathMessage == null) continue;
      if (pathMessage.type != MessageType.text) continue;
      scopedMessages.add(pathMessage);
    }
    if (scopedMessages.isEmpty) return null;

    final history = <String>[];
    final isSingleTurnPath = scopedMessages.length == 2 && scopedMessages.first.isMine;
    if (isSingleTurnPath) {
      final template = P.preference.promptTemplate.newChatTemplate.trim();
      if (template.isNotEmpty) {
        final templateMessages = template.split("\n\n").where((String entry) => entry.isNotEmpty).toList();
        history.addAll(templateMessages);
      }
    }
    for (int i = 0; i < scopedMessages.length; i = i + 2) {
      final Message userMsg = scopedMessages[i];
      final Message? botMsg = i + 1 < scopedMessages.length ? scopedMessages[i + 1] : null;

      final String userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
      history.add(userContent);

      if (botMsg == null) continue;

      String botContent = botMsg.getHistoryContent();
      if (botMsg.id == messageId && overrideBotContent != null) {
        botContent = overrideBotContent;
      }
      history.add(botContent);
    }
    return history;
  }

  String? _resolveDecodeParamsSnapshotRaw() {
    final backendParams = P.rwkv.backendBatchParams.q;
    if (backendParams.isNotEmpty) return backendParams.rawDecodeParams;

    final frontendParams = P.rwkv.frontendBatchParams.q;
    if (frontendParams.isNotEmpty) return frontendParams.rawDecodeParams;

    final currentParam = SamplerAndPenaltyParam(
      temperature: P.rwkv.arguments(Argument.temperature).q,
      topP: P.rwkv.arguments(Argument.topP).q,
      presencePenalty: P.rwkv.arguments(Argument.presencePenalty).q,
      frequencyPenalty: P.rwkv.arguments(Argument.frequencyPenalty).q,
      penaltyDecay: P.rwkv.arguments(Argument.penaltyDecay).q,
    );
    return <SamplerAndPenaltyParam>[currentParam].rawDecodeParams;
  }

  @Deprecated("Use _onStreamEvent instead")
  void _onOldStreamEvent(LLMEvent event) {
    if (P.askQuestion.interceptingEvents.q) return;

    switch (event.type) {
      case _RWKVMessageType.isGenerating:
        final isGenerating = event.content == "true";
        P.rwkv.generating.q = isGenerating;
        if (!isGenerating && !completionMode.q) _fullyReceived(callingFunction: "_onStreamEvent:isGenerating");
        break;

      case _RWKVMessageType.streamResponse:
        receivedTokens.q = event.content;
        P.rwkv.generating.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    if (P.askQuestion.interceptingEvents.q) return;
    if (_handleExpressionSequentialEvent(event)) return;

    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        receivedTokens.q = res.responseBufferContent;
        if (completionMode.q) return;
        final currentReceiveId = receiveId.q;
        if (currentReceiveId != null) {
          _scheduleRefreshLiveTokenCounts(
            messageId: currentReceiveId,
            liveBotContent: res.responseBufferContent,
          );
        }
        _sensitiveThrottler.call(() {
          _checkSensitive(res.responseBufferContent);
        });
        break;

      case from_rwkv.ResponseBatchBufferContent res:
        final responseBufferContent = res.responseBufferContent.join(Config.batchMarker) + Config.batchMarker + "-1";
        receivedTokens.q = responseBufferContent;
        if (completionMode.q) return;
        final currentReceiveId = receiveId.q;
        if (currentReceiveId != null) {
          _scheduleRefreshLiveTokenCounts(
            messageId: currentReceiveId,
            liveBotContent: responseBufferContent,
          );
        }
        _sensitiveThrottler.call(() {
          _checkSensitive(responseBufferContent);
        });
        break;

      case from_rwkv.GenerateStop _:
        receivedTokens.q = "";
        P.rwkv.generating.q = false;
        break;

      case from_rwkv.GenerateStart _:
        receivedTokens.q = "";
        P.rwkv.generating.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamDone() async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    qq;
    _liveTokenCountThrottler.cancel();
    _clearExpressionSequentialState();
    final demoType = P.app.demoType.q;
    if (demoType != .chat && demoType != .see) return;
    P.rwkv.generating.q = false;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    qqe("error: $error");
    _liveTokenCountThrottler.cancel();
    _clearExpressionSequentialState();
    if (!kDebugMode) Sentry.captureException(error, stackTrace: stackTrace);
    final demoType = P.app.demoType.q;
    if (demoType != .chat && demoType != .see) return;
    P.rwkv.generating.q = false;
  }

  Future<List<String>> _historyWithWebSearch(int receiveId, List<String> allMessage) async {
    RefInfo ref = RefInfo.empty();
    final isZh = P.preference.currentLangIsZh.q;

    if (webSearchMode.q != WebSearchMode.off) {
      ref = ref.copyWith(enable: true);
      try {
        final prompt = allMessage.last;
        final deepSearch = webSearchMode.q == WebSearchMode.deepSearch;
        _updateMessageById(id: receiveId, reference: ref);
        final resp =
            await _post(
                  'https://auth.rwkvos.com/api/internet_search',
                  token: 'x8rYbL3KfGp2Nq1zT9wVvJ0iQ5sUoAeX7HcM4',
                  body: {
                    "query": prompt,
                    "top_n": 3,
                    'is_deepsearch': deepSearch,
                  },
                ).timeout(const Duration(seconds: 10))
                as dynamic;
        qqq('web search mode: ${webSearchMode.q}');
        final refs = (resp['data'] as Iterable).map((e) => Reference.fromJson(e)).toList();
        ref = ref.copyWith(list: refs);
        final searchResult = refs.map((e) => e.summary).join("\n");
        allMessage.removeLast();
        final template = P.preference.promptTemplate;
        final msg = sprintf(isZh ? template.webSearchChineseTemplate : template.webSearchTemplate, [searchResult, prompt]);
        allMessage.add(msg);
      } catch (e) {
        ref = ref.copyWith(error: e.toString());
        qqe(e);
      }
    }
    50.msLater.then((_) {
      _updateMessageById(id: receiveId, reference: ref);
    });

    return allMessage;
  }
}
