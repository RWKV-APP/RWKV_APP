// ignore: unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/batch_settings_panel.dart';

class BatchButton extends ConsumerWidget {
  const BatchButton({super.key});

  Future<void> _onTap() async {
    qq;
    await BatchSettingsPanel.show();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    final surfaceContainer = theme.colorScheme.surfaceContainer;
    final batchEnabled = ref.watch(P.chat.batchEnabled);

    final primary = theme.colorScheme.primary;
    final s = S.of(context);

    final bgColor = batchEnabled ? primary : surfaceContainer;
    final textColor = batchEnabled ? kW : primary;
    final batchCount = ref.watch(P.chat.batchCount);
    final borderColor = batchEnabled ? primary : primary.q(.1);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
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
              if (!batchEnabled) T(s.batch_inference, s: TS(c: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
