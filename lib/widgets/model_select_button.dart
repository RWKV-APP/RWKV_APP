import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/store/p.dart' show P;

import '../gen/l10n.dart';
import 'model_selector.dart';

class ModelSelectButton extends ConsumerWidget {
  const ModelSelectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(P.rwkv.currentModel);
    final modelDisplay = currentModel?.name ?? S.current.click_to_select_model;
    final theme = Theme.of(context);

    return Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        splashColor: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ModelSelector.show();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(modelDisplay, style: TextStyle(color: Colors.grey, fontSize: 10, height: 1)),
              const SizedBox(width: 6),
              SizedBox(
                height: 5,
                width: 8,
                child: CustomPaint(
                  painter: _TrianglePainter(color: Colors.grey),
                ),
              ),
            ],
          ),
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
