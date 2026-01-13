import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/store/p.dart' show P, $RWKV;
import 'package:zone/widgets/arguments_panel.dart';

import 'package:zone/gen/l10n.dart';
import 'package:zone/widgets/decode_param_type_button.dart';
import 'model_selector.dart';

class ModelSelectButton extends ConsumerWidget {
  const ModelSelectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(P.rwkv.latestModel);
    final decodeParamType = ref.watch(P.rwkv.decodeParamType);
    final s = S.of(context);
    final modelDisplay = currentModel?.name ?? s.click_to_select_model;
    final theme = Theme.of(context);

    final decodeParamName =
        {
          DecodeParamType.defaults: s.default_,
          DecodeParamType.creative: s.creative,
          DecodeParamType.conservative: s.conservative.split('(')[0].trim(),
          DecodeParamType.fixed: s.fixed,
          DecodeParamType.comprehensive: s.comprehensive,
          DecodeParamType.unknown: s.custom,
        }[decodeParamType] ??
        s.custom;

    final batchEnabled = ref.watch(P.chat.batchEnabled);

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
                ModelSelector.show();
              },
              child: Padding(
                padding: const .symmetric(horizontal: 8, vertical: 4),
                child: Text(modelDisplay, style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500)),
              ),
            ),
            if (currentModel == null)
              SizedBox(
                height: 5,
                width: 8,
                child: CustomPaint(
                  painter: _TrianglePainter(color: Colors.grey),
                ),
              ),
            if (currentModel == null) const SizedBox(width: 8),
            if (currentModel != null) const VerticalDivider(thickness: 1, width: 1),
            if (currentModel != null && !batchEnabled)
              DecodeParamTypeButton(
                decodeParamType: decodeParamType,
                child: Padding(
                  padding: const .symmetric(horizontal: 12, vertical: 4),
                  child: Text(decodeParamName, style: const TextStyle(fontSize: 10, height: 1)),
                ),
                onSelected: (v) {
                  if (v == DecodeParamType.unknown) {
                    ArgumentsPanel.show(context);
                  } else {
                    P.rwkv.syncSamplerParamsFromDefault(v);
                  }
                },
              ),

            if (currentModel != null && batchEnabled)
              InkWell(
                onTap: () {
                  P.rwkv.onBatchInferenceTapped();
                },
                child: Padding(
                  padding: const .symmetric(horizontal: 8, vertical: 4),
                  child: Text("  " + s.batch_inference_short + "  ", style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
