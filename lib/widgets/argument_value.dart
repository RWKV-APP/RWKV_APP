// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/store/p.dart';

class ArgumentValue extends ConsumerWidget {
  final Argument argument;
  final void Function(Argument argument, double value) onChanged;
  final bool showTitle;
  final bool showValue;
  final EdgeInsets padding;
  final dynamic defaultValue;
  final bool enabled;

  const ArgumentValue(
    this.argument,
    this.onChanged, {
    super.key,
    this.showTitle = true,
    this.showValue = true,
    this.padding = const .only(left: 12, right: 12),
    this.defaultValue,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value =
        defaultValue ??
        switch (argument) {
          Argument.batchCount => ref.watch(P.chat.batchCount),
          Argument.batchVW => ref.watch(P.chat.batchVW),
          _ => ref.watch(P.rwkv.arguments(argument)),
        };
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
                  ? T(
                      argument.name.codeToName,
                      s: const TS(
                        s: 14,
                        w: .w500,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (showValue)
              T(
                value.toStringAsFixed(argument.fixedDecimals),
                s: const TS(s: 14, w: .w600),
              ),
            padding.right.w,
          ],
        ),
        4.h,
        Row(
          children: [
            padding.left.w,
            T(
              argument.min.toStringAsFixed(argument.fixedDecimals),
              s: TS(s: 12, c: qb.q(.5)),
            ),
            14.w,
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
            14.w,
            T(
              argument.max.toStringAsFixed(argument.fixedDecimals),
              s: TS(s: 12, c: qb.q(.5)),
            ),
            padding.right.w,
          ],
        ),
        padding.bottom.h,
      ],
    );
  }
}
