// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/argument_value.dart';

// TODO: @wangce move it to pages/panel
class ArgumentsPanel extends ConsumerWidget {
  static Future<void> show(BuildContext context) async {
    if (P.rwkv.argumentsPanelShown.q) return;
    P.rwkv.argumentsPanelShown.q = true;
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
            return ArgumentsPanel(scrollController: scrollController);
          },
        );
      },
    );
    P.rwkv.argumentsPanelShown.q = false;
  }

  const ArgumentsPanel({super.key, required this.scrollController});

  final ScrollController scrollController;

  void _onChanged(Argument argument, double value) {
    double rawNewValue = double.parse(value.toStringAsFixed(argument.fixedDecimals));
    if (argument.step != null) {
      rawNewValue = (rawNewValue / argument.step!).round() * argument.step!;
    }
    final currentValue = P.rwkv.arguments(argument).q;
    if (currentValue == rawNewValue) return;
    if (argument.enableGaimon) P.app.hapticLight();
    P.rwkv.arguments(argument).q = rawNewValue;
    if (argument == Argument.maxLength) {
      P.rwkv.argumentUpdatingDebouncer.call(() {
        P.rwkv.syncMaxLength();
      });
    } else {
      P.rwkv.argumentUpdatingDebouncer.call(() {
        P.rwkv.syncSamplerParams();
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    return ClipRRect(
      borderRadius: 16.r,
      child: Container(
        margin: const EI.o(t: 8),
        child: Column(
          crossAxisAlignment: CAA.stretch,
          children: [
            Row(
              children: [
                4.w,
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EI.zero,
                    iconSize: 16,
                  ),
                  onPressed: () {
                    pop();
                  },
                  child: T(s.cancel),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CAA.center,
                    mainAxisAlignment: MAA.center,
                    children: [
                      const Icon(Icons.tune),
                      12.w,
                      T(
                        s.model_settings,
                        s: const TS(s: 16, w: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EI.zero,
                    iconSize: 16,
                  ),
                  onPressed: () {
                    pop();
                  },
                  child: T(s.apply),
                ),
                4.w,
              ],
            ),
            12.h,
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EI.o(b: paddingBottom),
                children: [
                  _SamplerOptions(),
                  ArgumentValue(Argument.temperature, _onChanged),
                  ArgumentValue(Argument.topK, _onChanged),
                  ArgumentValue(Argument.topP, _onChanged),
                  ArgumentValue(Argument.presencePenalty, _onChanged),
                  ArgumentValue(Argument.frequencyPenalty, _onChanged),
                  ArgumentValue(Argument.penaltyDecay, _onChanged),
                  _CompletionOptions(),
                  ArgumentValue(Argument.maxLength, _onChanged),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SamplerOptions extends ConsumerWidget {
  const _SamplerOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final reasoning = ref.watch(P.rwkv.reasoning);
    final qb = ref.watch(P.app.qb);
    return Container(
      margin: const EI.s(h: 12),
      decoration: BoxDecoration(color: qb.q(.1), borderRadius: 8.r),
      child: Row(
        children: [
          12.w,
          Expanded(child: T("Sampler Options" + (reasoning ? " (Reason)" : ""))),
          TextButton(
            style: TextButton.styleFrom(
              padding: EI.zero,
              iconSize: 16,
            ),
            onPressed: () {
              P.rwkv.resetSamplerParams(enableReasoning: reasoning);
            },
            child: T(s.reset),
          ),
        ],
      ),
    );
  }
}

class _CompletionOptions extends ConsumerWidget {
  const _CompletionOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final reasoning = ref.watch(P.rwkv.reasoning);
    return Container(
      margin: const EI.s(h: 12),
      decoration: BoxDecoration(color: qb.q(.1), borderRadius: 8.r),
      child: Row(
        children: [
          12.w,
          Expanded(child: T("Completion Options" + (reasoning ? " (Reason)" : ""))),
          TextButton(
            style: TextButton.styleFrom(
              padding: EI.zero,
              iconSize: 16,
            ),
            onPressed: () {
              P.rwkv.resetMaxLength(enableReasoning: reasoning);
            },
            child: T(s.reset),
          ),
        ],
      ),
    );
  }
}
