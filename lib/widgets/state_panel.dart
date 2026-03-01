// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

class StatePanel extends ConsumerWidget {
  static const String panelKey = 'StatePanel';

  static Future<void> show() async {
    await P.ui.showPanel(
      key: panelKey,
      beforeShow: () async {
        P.rwkv.statePanelShown.q = true;
        P.rwkv.refreshStatePanel();
      },
      afterHide: (_) {
        P.rwkv.statePanelShown.q = false;
      },
      initialChildSize: .8,
      maxChildSize: .905,
      builder: (scrollController) => StatePanel(scrollController: scrollController),
    );
  }

  const StatePanel({super.key, required this.scrollController});

  final ScrollController scrollController;

  static double get _listPadding => P.app.isMobile.q ? 8 : 12;

  void _onRefreshPressed() {
    Alert.info(S.current.refreshed);
    P.rwkv.refreshStatePanel();
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
    final stateLogList = ref.watch(P.rwkv.stateLogList);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final showEscapeCharacters = ref.watch(P.rwkv.showEscapeCharacters);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _StatePanelBar(
            listPadding: _listPadding,
            onRefresh: _onRefreshPressed,
          ),
          Expanded(
            child: stateLogList.isEmpty
                ? Center(
                    child: Text(
                      S.current.state_panel,
                      style: TS(c: qb.q(.5), s: 14),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: stateLogList.length,
                    padding: .only(
                      left: _listPadding,
                      top: 8,
                      right: _listPadding,
                      bottom: _listPadding + 16,
                    ),
                    itemBuilder: (context, index) {
                      final log = stateLogList[index];
                      final text = showEscapeCharacters ? log.text.replaceAll('\\n', '\n') : log.text;
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
                            Text(
                              'Text:',
                              style: TS(c: qb.q(.7), w: .w700, s: 12),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              text,
                              style: TS(c: qb.q(.9), s: 12).copyWith(
                                fontFamily: 'monospace',
                                fontFamilyFallback: const ['Menlo', 'Monaco', 'Courier'],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Life Span:',
                              style: TS(c: qb.q(.7), w: .w700, s: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              log.lifeSpan.toString(),
                              style: TS(c: qb.q(.85), s: 13),
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
                top: BorderSide(color: qb.q(.15), width: .5),
              ),
            ),
            child: _StateOptionRow(
              label: S.current.show_escape_characters,
              value: showEscapeCharacters,
              valueLabel: showEscapeCharacters ? S.current.line_break_rendered : S.current.escape_characters_rendered,
              onChanged: () {
                P.rwkv.showEscapeCharacters.q = !P.rwkv.showEscapeCharacters.q;
                P.rwkv.refreshStatePanel();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePanelBar extends ConsumerWidget {
  final double listPadding;
  final VoidCallback onRefresh;

  const _StatePanelBar({
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
                Icon(Icons.dashboard_rounded, size: 20, color: appTheme.primary),
                const SizedBox(width: 10),
                Text(
                  S.current.state_panel,
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

class _StateOptionRow extends ConsumerWidget {
  final String label;
  final bool value;
  final String valueLabel;
  final VoidCallback onChanged;

  const _StateOptionRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged,
        borderRadius: .circular(8),
        child: Padding(
          padding: const .symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Text(
                      label,
                      style: TS(c: qb.q(.9), s: 14, w: .w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valueLabel,
                      style: TS(c: qb.q(.6), s: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
