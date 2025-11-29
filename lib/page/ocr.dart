import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/model/bbox.dart';
import 'package:zone/store/p.dart';

class PageOcr extends ConsumerWidget {
  const PageOcr({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerCreated = ref.watch(P.ocr.controllerCreated);
    final initialized = ref.watch(P.ocr.initialized);
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR"),
      ),
      body: Column(
        crossAxisAlignment: .start,
        children: [
          Text(controllerCreated ? "Controller created" : "Controller not created"),
          Text(initialized ? "Initialized" : "Not initialized"),
          if (controllerCreated && initialized)
            Expanded(
              child: CameraPreview(
                P.ocr.controller,
                child: const _OcrOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}

class _OcrOverlay extends ConsumerWidget {
  const _OcrOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(P.ocr.words);
    final imageSize = ref.watch(P.ocr.imageSize);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BBoxPainter(words, imageSize),
        );
      },
    );
  }
}

class _BBoxPainter extends CustomPainter {
  final Set<BBox> bboxes;
  final Size imageSize;

  _BBoxPainter(this.bboxes, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero) return;

    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw imageSize rect (Blue)
    final imageRectPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      imageRectPaint,
    );

    // Draw debug info
    final debugText =
        "Img: ${imageSize.width.toInt()}x${imageSize.height.toInt()}\n"
        "Canvas: ${size.width.toInt()}x${size.height.toInt()}\n"
        "Scale: ${scaleX.toStringAsFixed(3)}x${scaleY.toStringAsFixed(3)}";

    final debugTextPainter = TextPainter(
      text: TextSpan(
        text: debugText,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    debugTextPainter.layout();
    debugTextPainter.paint(canvas, const Offset(10, 10));

    for (final box in bboxes) {
      final rect = Rect.fromLTWH(
        box.x * scaleX,
        box.y * scaleY,
        box.width * scaleX,
        box.height * scaleY,
      );
      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: box.text,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 6,
            backgroundColor: Colors.white54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.bottom));
    }
  }

  @override
  bool shouldRepaint(covariant _BBoxPainter oldDelegate) {
    return oldDelegate.bboxes != bboxes || oldDelegate.imageSize != imageSize;
  }
}
