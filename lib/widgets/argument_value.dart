// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';

class ArgumentValue extends ConsumerWidget {
  final Argument argument;
  final void Function(Argument argument, double value) onChanged;
  final bool showTitle;
  final bool showValue;
  final EdgeInsets padding;
  final dynamic defaultValue;
  final bool enabled;
  final bool isEditingBatchParams;

  const ArgumentValue(
    this.argument,
    this.onChanged, {
    super.key,
    this.showTitle = true,
    this.showValue = true,
    this.padding = const .only(left: 12, right: 12),
    this.defaultValue,
    this.enabled = true,
    this.isEditingBatchParams = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(P.rwkv.supportedBatchSizes);
    final num builtInValue = switch (argument) {
      Argument.batchCount => ref.watch(P.chat.batchCount),
      Argument.batchVW => ref.watch(P.chat.batchVW),
      _ => ref.watch(P.rwkv.arguments(argument)),
    };
    num value = defaultValue ?? builtInValue;
    double? batchValue;
    if (isEditingBatchParams) {
      final temporary = ref.watch(ArgumentsPanel.temporary);
      if (temporary == null) return const SizedBox.shrink();
      batchValue = switch (argument) {
        Argument.temperature => temporary.temperature,
        Argument.topP => temporary.topP,
        Argument.presencePenalty => temporary.presencePenalty,
        Argument.frequencyPenalty => temporary.frequencyPenalty,
        Argument.penaltyDecay => temporary.penaltyDecay,
        _ => null,
      };
    }
    if (batchValue != null) {
      value = batchValue;
    }
    if (!argument.show) return const SizedBox.shrink();
    final qb = ref.watch(P.app.qb);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        padding.top.h,
        Row(
          children: [
            padding.left.w,
            Expanded(
              child: showTitle
                  ? Text(
                      argument.name.codeToName,
                      style: const TS(
                        s: 14,
                        w: .w500,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (showValue)
              Text(
                value.toStringAsFixed(argument.fixedDecimals),
                style: const TS(s: 14, w: .w600),
              ),
            padding.right.w,
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            padding.left.w,
            Text(
              argument.min.toStringAsFixed(argument.fixedDecimals),
              style: TS(s: 12, c: qb.q(.5)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Slider(
                activeColor: enabled ? null : Colors.grey.q(1),
                padding: .zero,
                value: (value).toDouble(),
                min: argument.min,
                max: argument.max,
                onChanged: argument.configureable ? (value) => onChanged(argument, value) : null,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              argument.max.toStringAsFixed(argument.fixedDecimals),
              style: TS(s: 12, c: qb.q(.5)),
            ),
            padding.right.w,
          ],
        ),
        padding.bottom.h,
      ],
    );
  }
}
