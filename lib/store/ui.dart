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
}

/// Private methods
extension _$UI on _UI {
  FV _init() async {
    P.app.screenWidth.l(_onScreenWidthChanged, fireImmediately: true);
    homeController.addListener(_onHomeScroll);
    P.app.pageKey.l(_onPageKeyChanged);
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
}

/// Public methods
extension $UI on _UI {
  Future<Res?> showPanel<Res>({
    required String key,
    required Widget Function(ScrollController scrollController) builder,
    FutureOr<void> Function()? beforeShow,
    FutureOr<void> Function(Res? res)? afterHide,
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
