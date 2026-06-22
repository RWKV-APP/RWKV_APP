part of 'p.dart';

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
  bool _responseStyleSequentialActive = false;
  bool _responseStyleSequentialStopRequested = false;
  int? _responseStyleSequentialMessageId;
  int _responseStyleSequentialCurrentRouteIndex = 0;
  bool _responseStyleSequentialForceChinese = false;
  String _responseStyleSequentialCurrentOutput = "";
  String? _responseStyleSequentialCurrentAssistantMessage;
  List<ResponseStyleRoute> _responseStyleSequentialRoutes = const <ResponseStyleRoute>[];
  List<String> _responseStyleSequentialBaseHistory = const <String>[];
  List<String> _responseStyleSequentialCompletedOutputs = const <String>[];
  Timer? _fakeBatchInferenceBenchmarkTimer;
  Timer? _markdownFlickerReproTimer;
  Timer? _visibleReceivedTokensTimer;
  int? _fakeBatchInferenceBenchmarkMessageId;
  int? _markdownFlickerReproMessageId;
  List<int> _markdownFlickerReproCursors = const <int>[];
  List<_FakeBatchInferenceBenchmarkSlotState> _fakeBatchInferenceBenchmarkSlotStates = const <_FakeBatchInferenceBenchmarkSlotState>[];
  int _fakeBatchInferenceBenchmarkSlotIndex = 0;
  int _fakeBatchInferenceBenchmarkTick = 0;
  Map<int, int> _fakeBatchInferenceBenchmarkFixedTargetsBySlot = const <int, int>{};
  String _latestVisibleReceivedTokens = "";
  int? _pauseFinalizingMessageId;
  bool _sensitiveCheckRunning = false;
  String? _pendingSensitiveContent;
  int? _pendingSensitiveReceiveId;
  final math.Random _fakeBatchInferenceBenchmarkRandom = math.Random();

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final textInInput = qs("");
  late final inputBarDebuggerShown = qs(false);

  late final prefillPercentage = qs(0.0);

  /// TODO: Should be moved to state/rwkv.dart
  late final receivedTokens = qs("");
  late final visibleReceivedTokens = qs("");

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

  late final responseStyle = qs(const ResponseStyleState());

  late final batchEnabled = qs(Args.enableBatchInference);
  late final batchCount = qs<int>(Argument.batchCount.defaults.toInt());
  late final fakeBatchInferenceBenchmarkEnabled = qs(false);

  /// (messageId, slotIndex) 指向当前预览页要展示的 batch slot
  late final batchPreviewTarget = qs<(int, int)?>(null);
  late final batchViewportSlotIndexes = qs<({int messageId, Set<int> indexes})?>(null);

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

  late final batchInferenceAvailable = qp((ref) {
    final albatrossCanUse = ref.watch(P.albatrossRuntime.canUse);
    if (albatrossCanUse) return true;

    final isLegacyAlbatrossLoaded = ref.watch(P.rwkvContext.isLegacyAlbatrossLoaded);
    if (isLegacyAlbatrossLoaded) return true;

    final currentModel = ref.watch(P.rwkvModel.latest);
    return currentModel?.supportsBatchInference ?? false;
  });

  late final effectiveBatchEnabled = qp((ref) {
    final batchInferenceAvailable = ref.watch(this.batchInferenceAvailable);
    if (!batchInferenceAvailable) return false;

    final responseStyle = ref.watch(this.responseStyle);
    if (responseStyle.activeCount > 1) {
      return true;
    }
    return ref.watch(batchEnabled);
  });

  late final effectiveBatchCount = qp((ref) {
    final batchInferenceAvailable = ref.watch(this.batchInferenceAvailable);
    if (!batchInferenceAvailable) return 1;

    final responseStyle = ref.watch(this.responseStyle);
    if (responseStyle.activeCount > 1) {
      return responseStyle.activeCount;
    }
    return ref.watch(batchCount);
  });
}
