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

class StatePanel extends ConsumerWidget {
  static Future<void> show(BuildContext context) async {
    if (P.rwkv.statePanelShown.q) return;
    P.rwkv.statePanelShown.q = true;
    P.rwkv.refreshStatePanel();
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
            return StatePanel(scrollController: scrollController);
          },
        );
      },
    );
    P.rwkv.statePanelShown.q = false;
  }

  const StatePanel({super.key, required this.scrollController});

  final ScrollController scrollController;

  void _onRefreshPressed() {
    Alert.info(S.current.refreshed);
    P.rwkv.refreshStatePanel();
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: 200.ms,
      curve: Curves.easeInOut,
    );
  }

  void _onClosePressed() {
    pop();
  }

  void _onNReplacedPressed() {
    P.rwkv.showEscapeCharacters.q = !P.rwkv.showEscapeCharacters.q;
    P.rwkv.refreshStatePanel();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateLogList = ref.watch(P.rwkv.stateLogList);
    final qb = ref.watch(P.app.qb);
    final showEscapeCharacters = ref.watch(P.rwkv.showEscapeCharacters);
    return ClipRRect(
      borderRadius: 16.r,
      child: Container(
        margin: const EI.o(t: 8),
        child: Column(
          crossAxisAlignment: CAA.stretch,
          children: [
            Row(
              children: [
                8.w,
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onRefreshPressed,
                  child: T(S.current.refresh),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CAA.center,
                    mainAxisAlignment: MAA.center,
                    children: [
                      const Icon(Icons.tune),
                      4.w,
                      T(
                        S.current.state_panel,
                        s: const TS(s: 16, w: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onClosePressed,
                  child: T(S.current.close),
                ),
                8.w,
              ],
            ),
            Row(
              children: [
                8.w,
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onNReplacedPressed,
                  child: T(
                    S.current.show_escape_characters +
                        ": " +
                        (showEscapeCharacters ? S.current.line_break_rendered : S.current.escape_characters_rendered),
                  ),
                ),
                8.w,
              ],
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: stateLogList.length,
                padding: EI.o(b: 8),
                itemBuilder: (context, index) {
                  final log = stateLogList[index];
                  final text = showEscapeCharacters ? log.text.replaceAll("\\n", "\n") : log.text;
                  return Container(
                    decoration: BD(
                      border: Border.all(color: qb.q(.5)),
                      borderRadius: 8.r,
                    ),
                    padding: EI.a(4),
                    margin: EI.o(l: 8, r: 8, t: 4, b: 4),
                    child: Column(
                      crossAxisAlignment: CAA.start,
                      children: [
                        Text("Text: ", style: TS(w: FontWeight.w700)),
                        Text(text),
                        4.h,
                        Text("Life Span: ", style: TS(w: FontWeight.w700)),
                        Text(log.lifeSpan.toString()),
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
