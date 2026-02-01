part of 'p.dart';

class _UI {
  final showing = qs<Map<String, bool>>({});
}

/// Private methods
extension _$UI on _UI {
  FV _init() async {}
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
    if (showing.q[key] == true) {
      qqw("$key is already showing, skipping");
      return null;
    }

    final context = getContext();
    if (context == null) {
      qqw("context is null, skipping");
      return null;
    }

    showing.q[key] = true;

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
    showing.q[key] = false;

    return res;
  }
}
