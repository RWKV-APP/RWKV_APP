// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

class LogPanel extends ConsumerWidget {
  static Future<void> show(BuildContext context) async {
    if (P.rwkv.logPanelShown.q) return;
    P.rwkv.logPanelShown.q = true;
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
    P.rwkv.refreshRuntimeLog();
  }

  void _onClosePressed() {
    pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtimeLog = ref.watch(P.rwkv.runtimeLog);
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
                  child: T("Refresh"),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CAA.center,
                    mainAxisAlignment: MAA.center,
                    children: [
                      const Icon(Icons.tune),
                      12.w,
                      T(
                        "Runtime Log Panel",
                        s: const TS(s: 16, w: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: _onClosePressed,
                  child: T("Close"),
                ),
                8.w,
              ],
            ),
            12.h,
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: T(runtimeLog),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
