part of 'p.dart';

class _UI {
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
}

/// Private methods
extension _$UI on _UI {
  FV _init() async {
    P.app.screenWidth.l(_onScreenWidthChanged, fireImmediately: true);
    homeController.addListener(_onHomeScroll);
    P.app.pageKey.l(_onPageKeyChanged);
    backdropFilterBgAlphaForInputOptions.l(_onBackdropFilterBgAlphaForInputOptionsChanged, fireImmediately: true);
    sigmaForBackdropFilterForInputOptions.l(_onSigmaForBackdropFilterForInputOptionsChanged, fireImmediately: true);
    backdropFilterBgAlphaForInputTextFields.l(_onBackdropFilterBgAlphaForInputTextFieldsChanged, fireImmediately: true);
    sigmaForBackdropFilterForInputTextFields.l(_onSigmaForBackdropFilterForInputTextFieldsChanged, fireImmediately: true);
    gradientStartForInputBar.l(_onGradientStartForInputBarChanged, fireImmediately: true);
    gradientForInputBar.l(_onGradientForInputBarChanged, fireImmediately: true);
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
