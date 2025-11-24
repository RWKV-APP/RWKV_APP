// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/sampler_and_penalty_param.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/argument_value.dart';

class ArgumentsPanel extends ConsumerWidget {
  static final temporary = qs<SamplerAndPenaltyParam?>(null);

  static Future<SamplerAndPenaltyParam?> show(
    BuildContext context, {
    bool isEditingBatchParams = false,
    String? title,
    SamplerAndPenaltyParam? temporarySamplerAndPenaltyParam,
  }) async {
    if (P.rwkv.argumentsPanelShown.q) return null;
    P.rwkv.argumentsPanelShown.q = true;

    if (isEditingBatchParams) {
      if (temporarySamplerAndPenaltyParam == null) {
        P.rwkv.argumentsPanelShown.q = false;
        qqe("temporarySamplerAndPenaltyParam is null");
        return null;
      }
      temporary.q = temporarySamplerAndPenaltyParam;
    } else {
      temporary.q = null;
    }

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
            return ArgumentsPanel(
              scrollController: scrollController,
              isEditingBatchParams: isEditingBatchParams,
              title: title,
            );
          },
        );
      },
    );
    P.rwkv.argumentsPanelShown.q = false;
    return temporary.q;
  }

  const ArgumentsPanel({
    super.key,
    required this.scrollController,
    this.isEditingBatchParams = false,
    this.title,
  });

  final ScrollController scrollController;

  final bool isEditingBatchParams;
  final String? title;

  void _onChanged(Argument argument, double value) {
    double rawNewValue = double.parse(value.toStringAsFixed(argument.fixedDecimals));
    if (argument.step != null) {
      rawNewValue = (rawNewValue / argument.step!).round() * argument.step!;
    }

    if (isEditingBatchParams) {
      final temporary = ArgumentsPanel.temporary.q;
      if (temporary == null) return;
      final currentValue = switch (argument) {
        Argument.temperature => temporary.temperature,
        Argument.topP => temporary.topP,
        Argument.presencePenalty => temporary.presencePenalty,
        Argument.frequencyPenalty => temporary.frequencyPenalty,
        Argument.penaltyDecay => temporary.penaltyDecay,
        _ => null,
      };

      // debugger();

      if (currentValue == null || currentValue == rawNewValue) return;
      if (argument.enableGaimon) P.app.hapticLight();
      ArgumentsPanel.temporary.q = temporary.copyWith(
        temperature: argument == Argument.temperature ? rawNewValue.toDouble() : temporary.temperature,
        topP: argument == Argument.topP ? rawNewValue.toDouble() : temporary.topP,
        presencePenalty: argument == Argument.presencePenalty ? rawNewValue.toDouble() : temporary.presencePenalty,
        frequencyPenalty: argument == Argument.frequencyPenalty ? rawNewValue.toDouble() : temporary.frequencyPenalty,
        penaltyDecay: argument == Argument.penaltyDecay ? rawNewValue.toDouble() : temporary.penaltyDecay,
      );
    } else {
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    return ClipRRect(
      borderRadius: 16.r,
      child: Container(
        margin: const .only(top: 8),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                8.w,
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: () {
                    pop();
                  },
                  child: T(s.cancel),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: .center,
                    mainAxisAlignment: .center,
                    children: [
                      const Icon(Icons.tune),
                      12.w,
                      T(
                        title ?? s.model_settings,
                        s: const TS(s: 16, w: .w500),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(iconSize: 16),
                  onPressed: () {
                    pop();
                  },
                  child: T(s.apply),
                ),
                8.w,
              ],
            ),
            12.h,
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: .only(bottom: paddingBottom),
                children: [
                  const _SamplerOptions(),
                  ArgumentValue(Argument.temperature, _onChanged, isEditingBatchParams: isEditingBatchParams),
                  ArgumentValue(Argument.topK, _onChanged, isEditingBatchParams: isEditingBatchParams),
                  ArgumentValue(Argument.topP, _onChanged, isEditingBatchParams: isEditingBatchParams),
                  ArgumentValue(Argument.presencePenalty, _onChanged, isEditingBatchParams: isEditingBatchParams),
                  ArgumentValue(Argument.frequencyPenalty, _onChanged, isEditingBatchParams: isEditingBatchParams),
                  ArgumentValue(Argument.penaltyDecay, _onChanged, isEditingBatchParams: isEditingBatchParams),
                  if (!isEditingBatchParams) const _CompletionOptions(),
                  if (!isEditingBatchParams) ArgumentValue(Argument.maxLength, _onChanged),
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
      margin: const .symmetric(horizontal: 12),
      decoration: BoxDecoration(color: qb.q(.1), borderRadius: 8.r),
      child: Row(
        children: [
          12.w,
          Expanded(child: T("Sampler Options" + (reasoning ? " (Reason)" : ""))),
          TextButton(
            style: TextButton.styleFrom(
              padding: .zero,
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
      margin: const .symmetric(horizontal: 12),
      decoration: BoxDecoration(color: qb.q(.1), borderRadius: 8.r),
      child: Row(
        children: [
          12.w,
          Expanded(child: T("Completion Options" + (reasoning ? " (Reason)" : ""))),
          TextButton(
            style: TextButton.styleFrom(
              padding: .zero,
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
