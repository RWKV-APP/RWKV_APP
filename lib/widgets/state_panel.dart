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
  static final _nReplaced = qs(false);

  static Future<void> show(BuildContext context) async {
    if (P.rwkv.statePanelShown.q) return;
    P.rwkv.statePanelShown.q = true;
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
    StatePanel._nReplaced.q = !StatePanel._nReplaced.q;
    P.rwkv.refreshStatePanel();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateLogList = ref.watch(P.rwkv.stateLogList);
    final qb = ref.watch(P.app.qb);
    final nReplaced = ref.watch(StatePanel._nReplaced);
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
                      12.w,
                      T(
                        S.current.state_panel,
                        s: const TS(s: 16, w: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onNReplacedPressed,
                  child: T("换行符显示"),
                ),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onClosePressed,
                  child: T(S.current.close),
                ),
                8.w,
              ],
            ),
            12.h,
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: stateLogList.length,
                padding: EI.o(b: 8),
                itemBuilder: (context, index) {
                  final log = stateLogList[index];
                  final text = nReplaced ? log.text.replaceAll("\\n", "\n") : log.text;
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
                        Text(text),
                        4.h,
                        Row(
                          children: [
                            Text("Life Span: "),
                            Text(log.lifeSpan.toString()),
                          ],
                        ),
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
