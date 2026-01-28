// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/bottom_interactions.dart';

class BatchButton extends ConsumerWidget {
  const BatchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = BottomInteractions.calculateButtonHeight(context);
    final batchEnabled = ref.watch(P.chat.batchEnabled);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    // Design colors: light gray fill unselected, light green fill selected
    final lightGrayFill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7);
    const darkGrayText = Color(0xFF636366);
    const greenColor = Color(0xFF34C759); // Green for selected state
    // Light green for selected background (solid color, not transparency)
    final lightGreenFill = isDark ? const Color(0xFF2E3D32) : const Color(0xFFE8F5E9);

    final bgColor = batchEnabled ? lightGreenFill : lightGrayFill;
    final textColor = batchEnabled ? (isDark ? greenColor : const Color(0xFF2E7D32)) : darkGrayText;
    final border = batchEnabled ? Border.all(color: greenColor.withOpacity(0.5)) : null;
    final batchCount = ref.watch(P.chat.batchCount);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: P.rwkv.onBatchInferenceTapped,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: 60.r,
            border: border,
          ),
          padding: const .symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              if (batchEnabled) T(s.batch_inference_button(batchCount), s: TS(c: textColor, s: 12, height: 1, w: .w500)),
              if (!batchEnabled) T(s.batch_inference_short, s: TS(c: textColor, s: 12, height: 1, w: .w500)),
            ],
          ),
        ),
      ),
    );
  }
}
