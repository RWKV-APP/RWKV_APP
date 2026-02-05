// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

class LogPanel extends ConsumerWidget {
  static Future<void> show(BuildContext context) async {
    if (P.rwkv.logPanelShown.q) return;
    P.rwkv.logPanelShown.q = true;
    P.rwkv.refreshRuntimeLog();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .8,
          maxChildSize: .9,
          expand: false,
          snap: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return LogPanel(scrollController: scrollController);
          },
        );
      },
    );
    P.rwkv.logPanelShown.q = false;
  }

  const LogPanel({super.key, required this.scrollController});

  final ScrollController scrollController;

  void _onRefreshPressed() {
    Alert.info(S.current.refreshed);
    P.rwkv.refreshRuntimeLog();
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: 200.ms,
      curve: Curves.easeInOut,
    );
  }

  void _onClosePressed() {
    pop();
  }

  void _onShowEscapeCharactersPressed() {
    P.rwkv.showEscapeCharacters.q = !P.rwkv.showEscapeCharacters.q;
    P.rwkv.refreshStatePanel();
  }

  void _onShowPrefillLogOnlyPressed() {
    P.rwkv.showPrefillLogOnly.q = !P.rwkv.showPrefillLogOnly.q;
    P.rwkv.refreshRuntimeLog();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showEscapeCharacters = ref.watch(P.rwkv.showEscapeCharacters);
    final qb = ref.watch(P.app.qb);
    ref.watch(P.app.qw);
    final showPrefillLogOnly = ref.watch(P.rwkv.showPrefillLogOnly);
    final rawRuntimeLog = ref.watch(P.rwkv.runtimeLog);
    final runtimeLog = rawRuntimeLog.where((log) => showPrefillLogOnly ? log.isPrefill : true).toList();
    return ClipRRect(
      borderRadius: .circular(16),
      child: Container(
        margin: const .only(top: 8),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onRefreshPressed,
                  child: Text(S.current.refresh),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: .center,
                    mainAxisAlignment: .center,
                    children: [
                      const Icon(Icons.tune),
                      const SizedBox(width: 12),
                      Text(
                        S.current.runtime_log_panel,
                        style: const TS(s: 16, w: .w500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onClosePressed,
                  child: Text(S.current.close),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onShowEscapeCharactersPressed,
                  child: Text(
                    S.current.show_escape_characters +
                        ": " +
                        (showEscapeCharacters ? S.current.line_break_rendered : S.current.escape_characters_rendered),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onShowPrefillLogOnlyPressed,
                  child: Text(
                    S.current.show_prefill_log_only + ": " + (showPrefillLogOnly ? S.current.enabled : S.current.disabled),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: runtimeLog.length,
                padding: const .only(left: 4, top: 4, right: 4, bottom: 4),
                itemBuilder: (context, index) {
                  final log = runtimeLog[index];
                  final content = showEscapeCharacters ? log.content.replaceAll("\\n", "\n") : log.content;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: .circular(4),
                      border: .all(color: qb),
                    ),
                    padding: const .symmetric(horizontal: 4, vertical: 4),
                    margin: const .only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Row(
                          children: [
                            Text(log.tag, style: const TS(w: .w700)),
                            if (log.isPrefill) ...[
                              const SizedBox(width: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: kCG.q(.3),
                                  borderRadius: .circular(4),
                                ),
                                padding: const .symmetric(horizontal: 2),
                                child: const Text("Prefill", style: TS(w: .w700)),
                              ),
                            ],
                            const Spacer(),
                            if (log.dateTimeString.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: kCG.q(.3),
                                  borderRadius: .circular(4),
                                ),
                                padding: const .symmetric(horizontal: 2),
                                child: Text(log.dateTimeString, style: const TS(w: .w600)),
                              ),
                          ],
                        ),
                        Text(content),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
