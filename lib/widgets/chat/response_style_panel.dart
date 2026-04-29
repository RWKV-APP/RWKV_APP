// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/response_style.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';

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
          initialChildSize: isMobile ? .7 : .62,
          maxChildSize: isMobile ? .8 : .72,
          minChildSize: isMobile ? .6 : .52,
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = MediaQuery.paddingOf(context).bottom;
            final cardExtent = constraints.maxWidth < 420 ? 88.0 : 92.0;

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const .only(left: 12, right: 12, bottom: 12),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            mainAxisExtent: cardExtent,
                          ),
                          delegate: SliverChildListDelegate.fixed(
                            <Widget>[
                              for (final route in ResponseStyleRoute.values) _ResponseStyleRouteCard(route: route),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: .only(left: 12, right: 12, bottom: 12 + bottomPadding),
                  child: const Column(
                    mainAxisSize: .min,
                    children: [
                      _ResponseStyleRandomQuestionsButton(),
                      SizedBox(height: 8),
                      _ResponseStyleSelectAllButton(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResponseStyleRandomQuestionsButton extends ConsumerWidget {
  const _ResponseStyleRandomQuestionsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final responseStyle = ref.watch(P.chat.responseStyle);
    final count = responseStyle.activeCount;

    return SizedBox(
      width: double.infinity,
      height: 42,
      child: FilledButton.icon(
        onPressed: P.chat.onResponseStyleRandomQuestionsTapped,
        icon: const Icon(Icons.shuffle),
        label: Text(
          s.response_style_random_questions(count),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: .w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: .circular(8)),
        ),
      ),
    );
  }
}

class _ResponseStyleSelectAllButton extends ConsumerWidget {
  const _ResponseStyleSelectAllButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final responseStyle = ref.watch(P.chat.responseStyle);
    final allSelected = responseStyle.hasAllRoutes;
    final foregroundColor = allSelected ? qb.q(.35) : qb.q(.78);
    final borderColor = allSelected ? qb.q(.12) : qb.q(.22);
    final backgroundColor = allSelected ? qb.q(.045) : (appTheme.isLight ? appTheme.qb14 : appTheme.qb12);

    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: allSelected ? null : P.chat.onAllResponseStyleRoutesSelected,
        icon: const Icon(Icons.done_all),
        label: Text(
          s.select_all,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: .w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor,
          side: BorderSide(color: borderColor, width: .8),
          shape: RoundedRectangleBorder(borderRadius: .circular(8)),
        ),
      ),
    );
  }
}

class _ResponseStyleRouteCard extends ConsumerWidget {
  final ResponseStyleRoute route;

  const _ResponseStyleRouteCard({
    required this.route,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final responseStyle = ref.watch(P.chat.responseStyle);
    final enabled = responseStyle.enabledFor(route);
    final bool disableToggle = route.isDefaultRoute && responseStyle.isDefault;
    final selectedBackgroundColor = appTheme.isLight ? appTheme.qb14 : appTheme.qb12;
    final backgroundColor = enabled ? selectedBackgroundColor : appTheme.settingItem;
    final borderColor = enabled ? qb.q(.42) : qb.q(.11);
    final titleColor = enabled ? qb.q(.95) : qb.q(.9);
    final detailColor = enabled ? qb.q(.68) : qb.q(.56);

    return Semantics(
      button: true,
      checked: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: .circular(8),
          onTap: disableToggle
              ? null
              : () {
                  P.chat.onResponseStyleRouteChanged(route: route, enabled: !enabled);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const .only(left: 12, top: 10, right: 10, bottom: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: .circular(8),
              border: .all(color: borderColor, width: enabled ? 1 : .6),
            ),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        route.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TS(c: titleColor, s: 21, w: .w700, height: 1),
                      ),
                    ),
                    _ResponseStyleCheckMark(enabled: enabled),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  route.detail(s),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: detailColor,
                    fontWeight: .w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponseStyleCheckMark extends ConsumerWidget {
  final bool enabled;

  const _ResponseStyleCheckMark({
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final backgroundColor = enabled ? qb.q(.78) : Colors.transparent;
    final borderColor = enabled ? qb.q(.78) : qb.q(.28);
    final iconSize = (theme.iconTheme.size ?? 24) - 8;
    final iconColor = appTheme.qb15;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: .circular(6),
        border: .all(color: borderColor, width: 1.6),
      ),
      child: enabled
          ? Icon(
              Icons.check,
              color: iconColor,
              size: iconSize,
            )
          : null,
    );
  }
}
