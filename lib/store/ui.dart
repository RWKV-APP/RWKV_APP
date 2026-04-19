part of 'p.dart';

class _UI {
  final _batchHorizontalControllers = <int, ScrollController>{};
  final _batchSlotVerticalControllers = <({int messageId, int slotIndex}), ScrollController>{};
  final _batchHorizontalScrollListeners = <int, VoidCallback>{};
  final _batchSlotMetrics = <int, ({int batchCount, double paddingLeft, double slotWidth, double viewportWidth})>{};
  final _batchScheduledViewportSyncMessageIds = <int>{};
  final _batchScheduledButtonSyncMessageIds = <int>{};
  final _batchScheduledSlotContentKeys = <({int messageId, int slotIndex})>{};
  final _batchSlotPendingData = <({int messageId, int slotIndex}), ({Message msg, String data})>{};
  final _batchSlotData = <({int messageId, int slotIndex}), String>{};
  bool _batchControllerProviderSyncScheduled = false;

  late final showingPanels = qs<Map<String, bool>>({});

  late final homeController = ScrollController(initialScrollOffset: 1);
  late final homePixels = qs(0.0);
  late final homePixelsFromBottom = qs(1.0);

  late final messageListLayoutKeys = qs<Map<String, double>>({});
  late final maxWidthAllowedForLayout = qs<double>(0.0);

  late final widthRequiredForLayout = qp<double>((ref) {
    final _messageListLayoutKeys = ref.watch(messageListLayoutKeys);
    double v = 0.0;
    for (final key in _messageListLayoutKeys.keys) {
      v += _messageListLayoutKeys[key] ?? 0.0;
    }
    return (v + 3).roundToDouble();
  });

  late final shouldUseWrapRatherThanRow = qp<bool>((ref) {
    final _widthRequiredForLayout = ref.watch(widthRequiredForLayout);
    final _maxWidthAllowedForLayout = ref.watch(maxWidthAllowedForLayout);
    return _widthRequiredForLayout > _maxWidthAllowedForLayout;
  });

  late final useBackdropFilterForInputOptions = qs(false);

  // from 0.0 to 1.0
  late final backdropFilterBgAlphaForInputOptions = qs<double>(.75);

  late final backdropFilterBgAlphaForInputOptionsDarkModifier = qp<double>((ref) {
    final appTheme = ref.watch(P.app.theme);
    return appTheme.isLight ? 1.0 : 0.7;
  });

  // from 0.0 to 32.0
  late final sigmaForBackdropFilterForInputOptions = qs<double>(8.0);

  // 现阶段不需要渲染
  late final useBackdropFilterForInputTextFields = qs(false);
  late final backdropFilterBgAlphaForInputTextFields = qs(1.0);
  late final sigmaForBackdropFilterForInputTextFields = qs(0.0);

  // from -1.0 to 1.0
  late final gradientStartForInputBar = qs<double>(0);

  // from -1.0 to 1.0
  late final gradientForInputBar = qs<double>(1);

  late final homeItemTitleHeights = qs<Map<String, double>>({});

  late final maxHeightsOfHomeItemTitle = qp<double?>((ref) {
    final _homeItemTitleHeights = ref.watch(homeItemTitleHeights);
    if (_homeItemTitleHeights.isEmpty) return null;
    double v = 0.0;
    for (final key in _homeItemTitleHeights.keys) {
      v = math.max(v, _homeItemTitleHeights[key] ?? 0.0);
    }
    return v;
  });

  late final homeItemDescriptionHeights = qs<Map<String, double>>({});
  late final maxHeightsOfHomeItemDescription = qp<double?>((ref) {
    final _homeItemDescriptionHeights = ref.watch(homeItemDescriptionHeights);
    if (_homeItemDescriptionHeights.isEmpty) return null;
    double v = 0.0;
    for (final key in _homeItemDescriptionHeights.keys) {
      v = math.max(v, _homeItemDescriptionHeights[key] ?? 0.0);
    }
    return v;
  });

  late final batchHorizontalScrollControllers = qs<Map<int, ScrollController>>({});
  late final batchSlotVerticalScrollControllers = qs<Map<({int messageId, int slotIndex}), ScrollController>>({});
  late final batchScrollButtonVisibility = qsf<int, ({bool left, bool right})>((left: false, right: false));
  late final batchVisibleSlotIndexes = qsf<int, Set<int>>(const <int>{});
  late final batchVisibleSlotIndexesSynced = qsf<int, bool>(false);
  late final batchLastBatchCount = qsf<int, int>(0);
  late final batchLastPaddingLeft = qsf<int, double>(0);
  late final batchLastSlotWidth = qsf<int, double>(0);
  late final batchLastViewportWidth = qsf<int, double>(0);
  late final batchSlotBodyCanScroll = qsf<({int messageId, int slotIndex}), bool>(false);
  late final batchSlotViewportVisible = qsff<({int messageId, int slotIndex}), bool>((ref, key) {
    final visibleSlotIndexes = ref.watch(batchVisibleSlotIndexes(key.messageId));
    return visibleSlotIndexes.contains(key.slotIndex);
  });
}

/// Private methods
extension _$UI on _UI {
  FV _init() async {
    P.app.screenWidth.l(_onScreenWidthChanged, fireImmediately: true);
    homeController.addListener(_onHomeScroll);
    P.app.pageKey.l(_onPageKeyChanged);
    P.msg.ids.l(_onMessageIdsChangedForBatchUi, fireImmediately: true);
    backdropFilterBgAlphaForInputOptions.l(_onBackdropFilterBgAlphaForInputOptionsChanged, fireImmediately: true);
    sigmaForBackdropFilterForInputOptions.l(_onSigmaForBackdropFilterForInputOptionsChanged, fireImmediately: true);
    backdropFilterBgAlphaForInputTextFields.l(_onBackdropFilterBgAlphaForInputTextFieldsChanged, fireImmediately: true);
    sigmaForBackdropFilterForInputTextFields.l(_onSigmaForBackdropFilterForInputTextFieldsChanged, fireImmediately: true);
    gradientStartForInputBar.l(_onGradientStartForInputBarChanged, fireImmediately: true);
    gradientForInputBar.l(_onGradientForInputBarChanged, fireImmediately: true);
    return;
  }

  void _onPageKeyChanged(PageKey pageKey) async {
    switch (pageKey) {
      case .home:
        homePixels.q = 0;
        homePixelsFromBottom.q = 1;
        if (homeController.hasClients) homeController.animateTo(0, duration: 200.ms, curve: Curves.easeOutCubic);

        break;
      default:
        break;
    }
  }

  void _onHomeScroll() async {
    final position = homeController.position;
    final pixels = position.pixels;
    final pixelsFromBottom = position.maxScrollExtent - pixels;
    if ((homePixels.q - pixels).abs() > 1) homePixels.q = pixels;
    if ((homePixelsFromBottom.q - pixelsFromBottom).abs() > 1) homePixelsFromBottom.q = pixelsFromBottom;
  }

  void _onScreenWidthChanged(double screenWidth) async {
    // TODO: @wangce adjust layout based on screen width
  }

  void _onBackdropFilterBgAlphaForInputOptionsChanged(double value) {
    final normalized = _normalizeAlpha(value);
    if ((normalized - value).abs() > .0001) {
      backdropFilterBgAlphaForInputOptions.q = normalized;
      return;
    }
    _syncUseBackdropFilterForInputOptions();
  }

  void _onBackdropFilterBgAlphaForInputTextFieldsChanged(double value) {
    final normalized = _normalizeAlpha(value);
    if ((normalized - value).abs() > .0001) {
      backdropFilterBgAlphaForInputTextFields.q = normalized;
      return;
    }
    _syncUseBackdropFilterForInputTextFields();
  }

  void _onSigmaForBackdropFilterForInputOptionsChanged(double value) {
    final normalized = _normalizeSigma(value);
    if ((normalized - value).abs() > .0001) {
      sigmaForBackdropFilterForInputOptions.q = normalized;
      return;
    }
    _syncUseBackdropFilterForInputOptions();
  }

  void _onSigmaForBackdropFilterForInputTextFieldsChanged(double value) {
    final normalized = _normalizeSigma(value);
    if ((normalized - value).abs() > .0001) {
      sigmaForBackdropFilterForInputTextFields.q = normalized;
      return;
    }
    _syncUseBackdropFilterForInputTextFields();
  }

  void _onGradientStartForInputBarChanged(double value) {
    final normalized = _normalizeGradient(value);
    if ((normalized - value).abs() > .0001) {
      gradientStartForInputBar.q = normalized;
      return;
    }

    final gradientEnd = gradientForInputBar.q;
    if (normalized <= gradientEnd) return;
    gradientForInputBar.q = normalized;
  }

  void _onGradientForInputBarChanged(double value) {
    final normalized = _normalizeGradient(value);
    if ((normalized - value).abs() > .0001) {
      gradientForInputBar.q = normalized;
      return;
    }

    final gradientStart = gradientStartForInputBar.q;
    if (normalized >= gradientStart) return;
    gradientStartForInputBar.q = normalized;
  }

  void _syncUseBackdropFilterForInputOptions() {
    final shouldEnable = backdropFilterBgAlphaForInputOptions.q < 1 && sigmaForBackdropFilterForInputOptions.q > 0;
    if (useBackdropFilterForInputOptions.q == shouldEnable) return;
    useBackdropFilterForInputOptions.q = shouldEnable;
  }

  void _syncUseBackdropFilterForInputTextFields() {
    final shouldEnable = backdropFilterBgAlphaForInputTextFields.q < 1 && sigmaForBackdropFilterForInputTextFields.q > 0;
    if (useBackdropFilterForInputTextFields.q == shouldEnable) return;
    useBackdropFilterForInputTextFields.q = shouldEnable;
  }

  double _normalizeAlpha(double value) {
    if (!value.isFinite) return 1;
    return value.clamp(0, 1).toDouble();
  }

  double _normalizeSigma(double value) {
    if (!value.isFinite) return 0;
    return value.clamp(0, 32).toDouble();
  }

  double _normalizeGradient(double value) {
    if (!value.isFinite) return 1;
    return value.clamp(-1, 1).toDouble();
  }
}

/// Public methods
extension $UI on _UI {
  void _onMessageIdsChangedForBatchUi(List<int> ids) {
    final activeIds = ids.toSet();
    final messageIds = <int>{};

    for (final messageId in _batchHorizontalControllers.keys) {
      messageIds.add(messageId);
    }
    for (final messageId in _batchSlotMetrics.keys) {
      messageIds.add(messageId);
    }
    for (final key in _batchSlotVerticalControllers.keys) {
      messageIds.add(key.messageId);
    }
    for (final messageId in messageIds) {
      if (activeIds.contains(messageId)) continue;
      clearBatchMessageUi(messageId: messageId);
    }
  }

  ScrollController batchMessageScrollController({required int messageId}) {
    final existing = _batchHorizontalControllers[messageId];
    if (existing != null) return existing;

    final controller = ScrollController();
    final VoidCallback listener = () {
      syncBatchMessageScrollState(messageId: messageId);
    };
    controller.addListener(listener);
    _batchHorizontalScrollListeners[messageId] = listener;
    _batchHorizontalControllers[messageId] = controller;
    _scheduleBatchControllerProviderSync();
    scheduleBatchMessageScrollButtonSync(messageId: messageId);
    return controller;
  }

  ScrollController batchSlotScrollController({
    required int messageId,
    required int slotIndex,
  }) {
    final key = (messageId: messageId, slotIndex: slotIndex);
    final existing = _batchSlotVerticalControllers[key];
    if (existing != null) return existing;

    final controller = ScrollController();
    _batchSlotVerticalControllers[key] = controller;
    _scheduleBatchControllerProviderSync();
    return controller;
  }

  void _scheduleBatchControllerProviderSync() {
    if (_batchControllerProviderSyncScheduled) return;
    _batchControllerProviderSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _batchControllerProviderSyncScheduled = false;
      _syncBatchControllerProviders();
    });
  }

  void _syncBatchControllerProviders() {
    batchHorizontalScrollControllers.q = {..._batchHorizontalControllers};
    batchSlotVerticalScrollControllers.q = {..._batchSlotVerticalControllers};
  }

  void scheduleBatchMessageScrollButtonSync({required int messageId}) {
    if (_batchScheduledButtonSyncMessageIds.contains(messageId)) return;
    _batchScheduledButtonSyncMessageIds.add(messageId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _batchScheduledButtonSyncMessageIds.remove(messageId);
      updateBatchScrollButtonVisibility(messageId: messageId);
    });
  }

  void syncBatchMessageScrollState({required int messageId}) {
    updateBatchScrollButtonVisibility(messageId: messageId);
    _syncBatchVisibleSlotIndexesFromMetrics(messageId: messageId);
  }

  void updateBatchScrollButtonVisibility({required int messageId}) {
    final controller = _batchHorizontalControllers[messageId];
    if (controller == null || !controller.hasClients) {
      _setBatchScrollButtonVisibility(
        messageId: messageId,
        left: false,
        right: false,
      );
      return;
    }

    final position = controller.position;
    final left = position.pixels > 0.5;
    final right = position.pixels < (position.maxScrollExtent - 0.5);
    _setBatchScrollButtonVisibility(
      messageId: messageId,
      left: left,
      right: right,
    );
  }

  void _setBatchScrollButtonVisibility({
    required int messageId,
    required bool left,
    required bool right,
  }) {
    final current = batchScrollButtonVisibility(messageId).q;
    if (current.left == left && current.right == right) return;
    batchScrollButtonVisibility(messageId).q = (left: left, right: right);
  }

  Future<void> scrollBatchMessageBy({
    required int messageId,
    required double delta,
  }) async {
    final controller = _batchHorizontalControllers[messageId];
    if (controller == null) return;
    if (!controller.hasClients) return;

    final position = controller.position;
    final target = (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;

    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    updateBatchScrollButtonVisibility(messageId: messageId);
  }

  Set<int> resolveBatchVisibleSlotIndexes({
    required int messageId,
    required int batchCount,
    required double paddingLeft,
    required double slotWidth,
    required double viewportWidth,
  }) {
    final controller = _batchHorizontalControllers[messageId];
    return _resolveBatchVisibleSlotIndexes(
      controller: controller,
      batchCount: batchCount,
      paddingLeft: paddingLeft,
      slotWidth: slotWidth,
      viewportWidth: viewportWidth,
    );
  }

  void scheduleBatchSlotsViewportSync({
    required int messageId,
    required int batchCount,
    required double paddingLeft,
    required double slotWidth,
    required double viewportWidth,
  }) {
    _batchSlotMetrics[messageId] = (
      batchCount: batchCount,
      paddingLeft: paddingLeft,
      slotWidth: slotWidth,
      viewportWidth: viewportWidth,
    );
    if (_batchScheduledViewportSyncMessageIds.contains(messageId)) return;
    _batchScheduledViewportSyncMessageIds.add(messageId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _batchScheduledViewportSyncMessageIds.remove(messageId);
      _applyBatchSlotMetrics(messageId: messageId);
      _syncBatchVisibleSlotIndexesFromMetrics(messageId: messageId);
      updateBatchScrollButtonVisibility(messageId: messageId);
    });
  }

  void _applyBatchSlotMetrics({required int messageId}) {
    final metrics = _batchSlotMetrics[messageId];
    if (metrics == null) return;
    if (batchLastBatchCount(messageId).q != metrics.batchCount) batchLastBatchCount(messageId).q = metrics.batchCount;
    if (batchLastPaddingLeft(messageId).q != metrics.paddingLeft) batchLastPaddingLeft(messageId).q = metrics.paddingLeft;
    if (batchLastSlotWidth(messageId).q != metrics.slotWidth) batchLastSlotWidth(messageId).q = metrics.slotWidth;
    if (batchLastViewportWidth(messageId).q != metrics.viewportWidth) batchLastViewportWidth(messageId).q = metrics.viewportWidth;
  }

  void _syncBatchVisibleSlotIndexesFromMetrics({required int messageId}) {
    final metrics = _batchSlotMetrics[messageId];
    if (metrics == null) return;
    final indexes = resolveBatchVisibleSlotIndexes(
      messageId: messageId,
      batchCount: metrics.batchCount,
      paddingLeft: metrics.paddingLeft,
      slotWidth: metrics.slotWidth,
      viewportWidth: metrics.viewportWidth,
    );
    _setBatchVisibleSlotIndexes(
      messageId: messageId,
      indexes: indexes,
    );
  }

  void _setBatchVisibleSlotIndexes({
    required int messageId,
    required Set<int> indexes,
  }) {
    final normalized = Set<int>.unmodifiable(indexes);
    final current = batchVisibleSlotIndexes(messageId).q;
    if (!_sameIntSet(current, normalized)) {
      batchVisibleSlotIndexes(messageId).q = normalized;
    }
    if (!batchVisibleSlotIndexesSynced(messageId).q) {
      batchVisibleSlotIndexesSynced(messageId).q = true;
    }
    P.chat.updateBatchViewportSlotIndexes(
      messageId: messageId,
      indexes: normalized,
    );
  }

  Set<int> _resolveBatchVisibleSlotIndexes({
    required ScrollController? controller,
    required int batchCount,
    required double paddingLeft,
    required double slotWidth,
    required double viewportWidth,
  }) {
    if (batchCount <= 0) return const <int>{};
    if (slotWidth <= 0) return const <int>{};

    final double pixels = controller != null && controller.hasClients ? controller.position.pixels : 0;
    final double effectiveViewportWidth = controller != null && controller.hasClients
        ? controller.position.viewportDimension
        : viewportWidth;
    if (effectiveViewportWidth <= 0) return const <int>{0};

    final slotExtent = slotWidth + 8.0;
    final visibleStart = pixels;
    final visibleEnd = pixels + effectiveViewportWidth;
    final firstCandidate = _clampBatchSlotIndex(((visibleStart - paddingLeft) / slotExtent).floor() - 1, batchCount);
    final lastCandidate = _clampBatchSlotIndex(((visibleEnd - paddingLeft) / slotExtent).ceil() + 1, batchCount);
    final indexes = <int>{};
    final count = math.max(0, lastCandidate - firstCandidate + 1);
    for (final slotIndex in Iterable<int>.generate(count, (index) => firstCandidate + index)) {
      final itemStart = paddingLeft + slotIndex * slotExtent;
      final itemEnd = itemStart + slotWidth;
      if (itemEnd < visibleStart) continue;
      if (itemStart > visibleEnd) continue;
      indexes.add(slotIndex);
    }
    if (indexes.isNotEmpty) return Set<int>.unmodifiable(indexes);
    return Set<int>.unmodifiable({firstCandidate});
  }

  int _clampBatchSlotIndex(int value, int batchCount) {
    if (value < 0) return 0;
    final last = batchCount - 1;
    if (value > last) return last;
    return value;
  }

  bool _sameIntSet(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  void scheduleBatchSlotContentSync({
    required Message msg,
    required int slotIndex,
    required String data,
  }) {
    final key = (messageId: msg.id, slotIndex: slotIndex);
    _batchSlotPendingData[key] = (msg: msg, data: data);
    if (_batchScheduledSlotContentKeys.contains(key)) return;
    _batchScheduledSlotContentKeys.add(key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _batchScheduledSlotContentKeys.remove(key);
      final pending = _batchSlotPendingData.remove(key);
      if (pending == null) return;
      _syncBatchSlotContent(
        key: key,
        msg: pending.msg,
        data: pending.data,
      );
    });
  }

  void _syncBatchSlotContent({
    required ({int messageId, int slotIndex}) key,
    required Message msg,
    required String data,
  }) {
    final previous = _batchSlotData[key];
    _batchSlotData[key] = data;
    if (previous != null && previous != data) {
      _maybeAutoScrollBatchSlotToBottom(
        msg: msg,
        slotIndex: key.slotIndex,
      );
    }
    _syncBatchSlotBodyCanScroll(key: key);
  }

  void _maybeAutoScrollBatchSlotToBottom({
    required Message msg,
    required int slotIndex,
  }) {
    if (!msg.changing) return;

    final key = (messageId: msg.id, slotIndex: slotIndex);
    final controller = _batchSlotVerticalControllers[key];
    if (controller == null) return;
    if (!controller.hasClients) return;

    final position = controller.position;
    if (!position.hasContentDimensions) return;

    final distanceToBottom = position.maxScrollExtent - position.pixels;
    if (distanceToBottom >= 48.0) return;
    controller.jumpTo(position.maxScrollExtent);
  }

  void _syncBatchSlotBodyCanScroll({required ({int messageId, int slotIndex}) key}) {
    final controller = _batchSlotVerticalControllers[key];
    if (controller == null) return;
    if (!controller.hasClients) return;

    final next = controller.position.maxScrollExtent > 0.5;
    if (batchSlotBodyCanScroll(key).q == next) return;
    batchSlotBodyCanScroll(key).q = next;
  }

  void onBatchSlotPreviewPressed({
    required int messageId,
    required int slotIndex,
  }) {
    P.chat.batchPreviewTarget.q = (messageId, slotIndex);
    push(.batchSlotPreview);
  }

  bool onBatchSlotVerticalScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final parent = P.chat.scrollController;
    if (!parent.hasClients) return false;
    if (notification is! OverscrollNotification) return false;

    final parentPosition = parent.position;
    final newOffset = (parentPosition.pixels - notification.overscroll).clamp(
      parentPosition.minScrollExtent,
      parentPosition.maxScrollExtent,
    );
    if (newOffset == parentPosition.pixels) return false;
    parent.jumpTo(newOffset);
    return false;
  }

  void clearBatchMessageUi({required int messageId}) {
    final horizontalController = _batchHorizontalControllers.remove(messageId);
    final horizontalListener = _batchHorizontalScrollListeners.remove(messageId);
    if (horizontalController != null && horizontalListener != null) {
      horizontalController.removeListener(horizontalListener);
    }
    horizontalController?.dispose();

    final slotKeys = <({int messageId, int slotIndex})>[];
    for (final key in _batchSlotVerticalControllers.keys) {
      if (key.messageId != messageId) continue;
      slotKeys.add(key);
    }
    for (final key in slotKeys) {
      final controller = _batchSlotVerticalControllers.remove(key);
      controller?.dispose();
      batchSlotBodyCanScroll(key).q = false;
      _batchSlotData.remove(key);
      _batchSlotPendingData.remove(key);
      _batchScheduledSlotContentKeys.remove(key);
    }
    _syncBatchControllerProviders();

    _batchSlotMetrics.remove(messageId);
    _batchScheduledViewportSyncMessageIds.remove(messageId);
    _batchScheduledButtonSyncMessageIds.remove(messageId);
    batchScrollButtonVisibility(messageId).q = (left: false, right: false);
    batchVisibleSlotIndexes(messageId).q = const <int>{};
    batchVisibleSlotIndexesSynced(messageId).q = false;
    batchLastBatchCount(messageId).q = 0;
    batchLastPaddingLeft(messageId).q = 0;
    batchLastSlotWidth(messageId).q = 0;
    batchLastViewportWidth(messageId).q = 0;
    P.chat.clearBatchViewportSlotIndexes(messageId: messageId);
  }

  Future<Res?> showPanel<Res>({
    required String key,
    required Widget Function(ScrollController scrollController) builder,
    FutureOr<void> Function()? beforeShow,
    FutureOr<void> Function(Res? res)? afterHide,
    bool isDismissible = true,
    bool isScrollControlled = true,
    double initialChildSize = .8,
    double maxChildSize = .905,
    bool expand = false,
    bool snap = false,
  }) async {
    if (showingPanels.q[key] == true) {
      qqw("$key is already showing, skipping");
      return null;
    }

    final context = getContext();
    if (context == null) {
      qqw("context is null, skipping");
      return null;
    }

    showingPanels.q[key] = true;

    await beforeShow?.call();

    final res = await showModalBottomSheet<Res>(
      // ignore: use_build_context_synchronously
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: 16.rr)),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        expand: expand,
        snap: snap,
        builder: (context, scrollController) => builder(scrollController),
      ),
    );

    await afterHide?.call(res);
    showingPanels.q[key] = false;

    return res;
  }
}
