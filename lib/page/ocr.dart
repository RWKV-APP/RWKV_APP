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

    // Calculate scale to "cover" the canvas (similar to CameraPreview)
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    // Calculate offset to center the image
    final double offsetX = (size.width - imageSize.width * scale) / 2;
    final double offsetY = (size.height - imageSize.height * scale) / 2;

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw imageSize rect (Blue) - transformed
    final imageRectPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Transform the canvas to match image coordinates
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // Draw the border of the image in image space
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      imageRectPaint,
    );

    // Draw debug info (reset transform for text)
    canvas.restore();

    final debugText =
        "Img: ${imageSize.width.toInt()}x${imageSize.height.toInt()}\n"
        "Canvas: ${size.width.toInt()}x${size.height.toInt()}\n"
        "Scale: ${scale.toStringAsFixed(3)} (X:${scaleX.toStringAsFixed(3)}, Y:${scaleY.toStringAsFixed(3)})";

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

    // Draw BBoxes
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    for (final box in bboxes) {
      final rect = Rect.fromLTWH(
        box.x.toDouble(),
        box.y.toDouble(),
        box.width.toDouble(),
        box.height.toDouble(),
      );
      canvas.drawRect(rect, paint);
    }
    canvas.restore();

    // Draw texts separately to maintain readable font size
    for (final box in bboxes) {
      // Map box coordinates to screen coordinates
      final double left = box.x * scale + offsetX;
      final double bottom = (box.y + box.height) * scale + offsetY;

      final textPainter = TextPainter(
        text: TextSpan(
          text: box.text,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 10, // Fixed readable size
            backgroundColor: Colors.white54,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left, bottom));
    }
  }

  @override
  bool shouldRepaint(covariant _BBoxPainter oldDelegate) {
    return oldDelegate.bboxes != bboxes || oldDelegate.imageSize != imageSize;
  }
}
