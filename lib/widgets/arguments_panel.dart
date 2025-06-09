// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/route/method.dart';
import 'package:zone/state/p.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    return ClipRRect(
      borderRadius: 16.r,
      child: C(
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
                        s.session_configuration,
                        s: const TS(s: 16, w: FW.w500),
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
                children: const [
                  _SamplerOptions(),
                  _Value(Argument.temperature),
                  _Value(Argument.topK),
                  _Value(Argument.topP),
                  _Value(Argument.presencePenalty),
                  _Value(Argument.frequencyPenalty),
                  _Value(Argument.penaltyDecay),
                  _CompletionOptions(),
                  _Value(Argument.maxLength),
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
    return C(
      margin: const EI.s(h: 12),
      decoration: BD(color: qb.q(.1), borderRadius: 8.r),
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
    return C(
      margin: const EI.s(h: 12),
      decoration: BD(color: qb.q(.1), borderRadius: 8.r),
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

extension _ArgumentGaimon on Argument {
  bool get enableGaimon => switch (this) {
    Argument.temperature => true,
    Argument.topK => true,
    Argument.topP => true,
    Argument.presencePenalty => true,
    Argument.frequencyPenalty => true,
    Argument.penaltyDecay => true,
    Argument.maxLength => false,
  };
}

class _Value extends ConsumerWidget {
  final Argument argument;

  const _Value(this.argument);

  void _onChanged(double value) {
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
    final value = ref.watch(P.rwkv.arguments(argument));
    if (!argument.show) return const SizedBox.shrink();
    final qb = ref.watch(P.app.qb);
    return Column(
      crossAxisAlignment: CAA.stretch,
      children: [
        12.h,
        Row(
          children: [
            12.w,
            Expanded(
              child: T(
                argument.name.codeToName,
                s: const TS(
                  s: 14,
                  w: FW.w500,
                ),
              ),
            ),
            T(value.toStringAsFixed(argument.fixedDecimals), s: const TS(s: 14, w: FW.w600)),
            12.w,
          ],
        ),
        4.h,
        Row(
          children: [
            12.w,
            T(
              argument.min.toStringAsFixed(argument.fixedDecimals),
              s: TS(s: 12, c: qb.q(.5)),
            ),
            14.w,
            Expanded(
              child: Slider(
                padding: EI.zero,
                value: value,
                min: argument.min,
                max: argument.max,
                onChanged: argument.configureable ? _onChanged : null,
              ),
            ),
            14.w,
            T(
              argument.max.toStringAsFixed(argument.fixedDecimals),
              s: TS(s: 12, c: qb.q(.5)),
            ),
            12.w,
          ],
        ),
        12.h,
      ],
    );
  }
}
