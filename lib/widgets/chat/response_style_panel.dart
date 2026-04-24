// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/response_style.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/form_item.dart';

class ResponseStylePanel extends ConsumerWidget {
  static final _shown = qs(false);

  static Future<void> show() async {
    if (_shown.q) {
      return;
    }
    _shown.q = true;
    final context = getContext();
    if (context == null || !context.mounted) {
      _shown.q = false;
      return;
    }
    final isMobile = P.app.isMobile.q;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: isMobile ? .5 : .56,
          maxChildSize: isMobile ? .7 : .72,
          minChildSize: isMobile ? .36 : .42,
          expand: false,
          snap: false,
          builder: (context, scrollController) {
            return ResponseStylePanel(scrollController: scrollController);
          },
        );
      },
    );
    _shown.q = false;
  }

  final ScrollController? scrollController;

  const ResponseStylePanel({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Scaffold(
        backgroundColor: appTheme.settingBg,
        appBar: AppBar(
          title: Text(
            s.response_style,
            style: theme.textTheme.titleMedium,
          ),
          automaticallyImplyLeading: false,
          backgroundColor: appTheme.settingBg,
          actions: [
            Padding(
              padding: const .only(right: 8),
              child: IconButton(
                onPressed: () {
                  pop();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
        body: ListView(
          controller: scrollController,
          padding: const .only(left: 12, right: 12, bottom: 12),
          children: [
            for (int index = 0; index < ResponseStyleRoute.values.length; index++)
              _ResponseStyleRouteItem(
                route: ResponseStyleRoute.values[index],
                isSectionStart: index == 0,
                isSectionEnd: index == ResponseStyleRoute.values.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _ResponseStyleRouteItem extends ConsumerWidget {
  final ResponseStyleRoute route;
  final bool isSectionStart;
  final bool isSectionEnd;

  const _ResponseStyleRouteItem({
    required this.route,
    this.isSectionStart = false,
    this.isSectionEnd = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final responseStyle = ref.watch(P.chat.responseStyle);
    final enabled = responseStyle.enabledFor(route);
    final bool disableToggle = route.isDefaultRoute && responseStyle.isDefault;

    return FormItem(
      isSectionStart: isSectionStart,
      isSectionEnd: isSectionEnd,
      title: route.label,
      subtitle: route.detail(s),
      showArrow: false,
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: disableToggle
            ? null
            : (bool value) {
                P.chat.onResponseStyleRouteChanged(route: route, enabled: value);
              },
      ),
      infoWidget: Padding(
        padding: const .only(right: 8),
        child: Text(
          enabled ? s.enabled : s.disabled,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
