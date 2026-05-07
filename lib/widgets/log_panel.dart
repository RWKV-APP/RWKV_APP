// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/func/format_debug_panel_text.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/debug_text_display_settings_section.dart';

class LogPanel extends ConsumerWidget {
  static const String panelKey = 'LogPanel';

  static Future<void> show() async {
    await P.ui.showPanel(
      key: panelKey,
      beforeShow: () async {
        P.rwkvDebug.logPanelShown.q = true;
        P.rwkvDebug.refreshRuntimeLog();
      },
      afterHide: (_) {
        P.rwkvDebug.logPanelShown.q = false;
      },
      initialChildSize: .8,
      maxChildSize: .905,
      builder: (scrollController) => LogPanel(scrollController: scrollController),
    );
  }

  const LogPanel({super.key, required this.scrollController});

  final ScrollController scrollController;

  static double get _listPadding => P.app.isMobile.q ? 8 : 12;

  void _onRefreshPressed() {
    Alert.info(S.current.refreshed);
    P.rwkvDebug.refreshRuntimeLog();
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: 200.ms,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final renderNewlineDirectly = ref.watch(P.rwkvDebug.renderNewlineDirectly);
    final renderSpaceSymbol = ref.watch(P.rwkvDebug.renderSpaceSymbol);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final showPrefillLogOnly = ref.watch(P.rwkvDebug.showPrefillLogOnly);
    final rawRuntimeLog = ref.watch(P.rwkvDebug.runtimeLog);
    final runtimeLog = rawRuntimeLog.where((log) => showPrefillLogOnly ? log.isPrefill : true).toList();
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _LogPanelBar(
            listPadding: _listPadding,
            onRefresh: _onRefreshPressed,
          ),
          Expanded(
            child: runtimeLog.isEmpty
                ? Center(
                    child: Text(
                      S.current.runtime_log_panel,
                      style: TS(c: qb.q(.5), s: 14),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: runtimeLog.length,
                    padding: .only(
                      left: _listPadding,
                      top: 8,
                      right: _listPadding,
                      bottom: _listPadding + 16,
                    ),
                    itemBuilder: (context, index) {
                      final log = runtimeLog[index];
                      final textStyle = TS(c: qb.q(.9), s: 12).copyWith(
                        fontFamily: 'monospace',
                        fontFamilyFallback: const ['Menlo', 'Monaco', 'Courier'],
                      );
                      final symbolTextColor = textStyle.color ?? qb.q(.9);
                      final formattedContentSpan = buildDebugPanelTextSpan(
                        text: log.content,
                        baseStyle: textStyle,
                        renderNewlineDirectly: renderNewlineDirectly,
                        renderSpaceSymbol: renderSpaceSymbol,
                        spaceTextColor: symbolTextColor,
                        spaceBackgroundColor: kC,
                        newlineTextColor: symbolTextColor,
                        newlineBackgroundColor: kC,
                      );
                      return Container(
                        decoration: BoxDecoration(
                          color: appTheme.settingItem,
                          borderRadius: .circular(8),
                          border: .all(color: qb.q(.2), width: .5),
                        ),
                        padding: const .symmetric(horizontal: 10, vertical: 8),
                        margin: const .only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Row(
                              children: [
                                Text(log.tag, style: const TS(w: .w700, s: 13)),
                                if (log.isPrefill) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: kCG.q(.25),
                                      borderRadius: .circular(4),
                                    ),
                                    padding: const .symmetric(horizontal: 6, vertical: 2),
                                    child: const Text('Prefill', style: TS(w: .w700, s: 11)),
                                  ),
                                ],
                                const Spacer(),
                                if (log.dateTimeString.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: qb.q(.15),
                                      borderRadius: .circular(4),
                                    ),
                                    padding: const .symmetric(horizontal: 6, vertical: 2),
                                    child: Text(
                                      log.dateTimeString,
                                      style: TS(c: qb.q(.85), w: .w600, s: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText.rich(
                              formattedContentSpan,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: .only(left: _listPadding, right: _listPadding, top: 8, bottom: 8 + paddingBottom),
            decoration: BoxDecoration(
              color: appTheme.settingItem,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant, width: .5),
              ),
            ),
            child: const DebugTextDisplaySettingsSection(includePrefillLogOnlySetting: true),
          ),
        ],
      ),
    );
  }
}

class _LogPanelBar extends ConsumerWidget {
  final double listPadding;
  final VoidCallback onRefresh;

  const _LogPanelBar({
    required this.listPadding,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);

    return Container(
      constraints: const BoxConstraints(minHeight: kToolbarHeight - 4),
      padding: const .only(top: 4),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        border: Border(
          bottom: BorderSide(color: qb.q(.12), width: .5),
        ),
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          listPadding.w,
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: S.current.refresh,
            style: IconButton.styleFrom(visualDensity: .compact),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: .center,
              mainAxisAlignment: .center,
              children: [
                Icon(Icons.terminal_rounded, size: 20, color: appTheme.primary),
                const SizedBox(width: 10),
                Text(
                  S.current.runtime_log_panel,
                  style: const TS(s: 18, w: .w600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: pop,
            icon: const Icon(Icons.close_rounded),
            tooltip: S.current.close,
            style: IconButton.styleFrom(visualDensity: .compact),
          ),
          (listPadding + 4).w,
        ],
      ),
    );
  }
}
