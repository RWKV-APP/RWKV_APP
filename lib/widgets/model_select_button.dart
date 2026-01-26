import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/store/p.dart' show P, $RWKV;

import 'package:zone/gen/l10n.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/triangle_painter.dart';

class ModelSelectButton extends ConsumerWidget {
  const ModelSelectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(P.rwkv.latestModel);
    final s = S.of(context);
    final theme = Theme.of(context);

    final batchEnabled = ref.watch(P.chat.batchEnabled);

    final screenWidth = ref.watch(P.app.screenWidth);

    String modelDisplay = currentModel?.name ?? s.click_to_select_model;

    if (screenWidth < 400) {
      modelDisplay = modelDisplay.replaceAll(RegExp(r"\([^)]*\)"), "");
    }

    return Ink(
      decoration: BoxDecoration(
        borderRadius: .circular(16),
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            InkWell(
              borderRadius: const .horizontal(left: .circular(16)),
              onTap: () {
                ModelSelector.show(preferredDemoType: .chat);
              },
              child: Padding(
                padding: const .symmetric(horizontal: 8, vertical: 4),
                child: Text(modelDisplay, style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500)),
              ),
            ),
            if (currentModel == null) ...[
              SizedBox(
                height: 5,
                width: 8,
                child: CustomPaint(
                  painter: TrianglePainter(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (currentModel != null && batchEnabled) ...[
              const VerticalDivider(thickness: 1, width: 1),
              InkWell(
                borderRadius: const .horizontal(right: .circular(16)),
                onTap: P.rwkv.onBatchInferenceTapped,
                child: Padding(
                  padding: const .symmetric(horizontal: 8, vertical: 4),
                  child: Text("  " + s.batch_inference_short + "  ", style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
