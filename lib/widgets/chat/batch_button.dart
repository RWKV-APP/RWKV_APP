// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class BatchButton extends ConsumerWidget {
  const BatchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    final surfaceContainer = theme.colorScheme.surfaceContainer;
    final batchEnabled = ref.watch(P.chat.batchEnabled);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);

    final primary = theme.colorScheme.primary;
    final s = S.of(context);

    final bgColor = batchEnabled ? primary : surfaceContainer;
    final textColor = batchEnabled ? qw.q(1) : qb.q(.667);
    final batchCount = ref.watch(P.chat.batchCount);
    final borderColor = batchEnabled ? primary : primary.q(.1);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: P.rwkv.onBatchInferenceTapped,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: 60.r,
            border: Border.all(color: borderColor),
          ),
          padding: const EI.o(h: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (batchEnabled) T(s.batch_inference_button(batchCount), s: TS(c: textColor)),
              if (!batchEnabled) T(s.batch_inference_short, s: TS(c: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
