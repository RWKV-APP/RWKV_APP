import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/bbox.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_selector.dart';

class PageOcr extends ConsumerWidget {
  const PageOcr({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerCreated = ref.watch(P.ocr.controllerCreated);
    final initialized = ref.watch(P.ocr.initialized);
    final screenWidth = ref.watch(P.app.screenWidth);
    final isPreviewPaused = ref.watch(P.ocr.isPreviewPaused);
    final shouldRenderCamera = controllerCreated && initialized && !isPreviewPaused;
    qqq(controllerCreated);
    qqq(initialized);
    qqq(isPreviewPaused);
    qqq(shouldRenderCamera);
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR"),
        actions: [
          TextButton(
            onPressed: () {
              push(.translator);
            },
            child: const Text("Offline Translatior"),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: .center,
        children: [
          screenWidth.w,
          if (shouldRenderCamera) const Expanded(child: _Camera()),
          if (!shouldRenderCamera) const Expanded(child: _Guide()),
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
    final lines = ref.watch(P.ocr.lines);
    final paragraphs = ref.watch(P.ocr.paragraphs);
    final imageSize = ref.watch(P.ocr.imageSize);
    final translations = ref.watch(P.ocr.translations);
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BBoxPainter(
            words: words,
            lines: lines,
            paragraphs: paragraphs,
            imageSize: imageSize,
            translations: translations,
          ),
        );
      },
    );
  }
}

class _BBoxPainter extends CustomPainter {
  final Set<BBox> words;
  final Set<BBox> lines;
  final Set<BBox> paragraphs;
  final Size imageSize;
  final Map<String, String> translations;

  const _BBoxPainter({
    required this.words,
    required this.lines,
    required this.paragraphs,
    required this.imageSize,
    required this.translations,
  });

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
        "Scale: ${scale.toStringAsFixed(3)} (X:${scaleX.toStringAsFixed(3)}, Y:${scaleY.toStringAsFixed(3)})\n"
        "P:${paragraphs.length} L:${lines.length} W:${words.length}";

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

    // Helper to draw bboxes and text
    void _drawBBoxes({
      required Set<BBox> boxes,
      required Color color,
      required double strokeWidth,
      required bool printTargetText,
      required Map<String, String> translations,
    }) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      // Draw BBoxes
      canvas.save();
      canvas.translate(offsetX, offsetY);
      canvas.scale(scale);

      for (final box in boxes) {
        final rect = Rect.fromLTWH(
          box.x.toDouble(),
          box.y.toDouble(),
          box.width.toDouble(),
          box.height.toDouble(),
        );
        canvas.drawRect(rect, paint);
      }
      canvas.restore();

      for (final box in boxes) {
        final translation = translations[box.text];
        if (translation != null) {
          final textPainter = TextPainter(
            text: TextSpan(text: translation),
          );
        }
      }

      // Draw texts separately to maintain readable font size
      if (printTargetText) {
        for (final box in boxes) {
          // Map box coordinates to screen coordinates
          final double left = box.x * scale + offsetX;
          final double bottom = (box.y + box.height) * scale + offsetY;

          final textPainter = TextPainter(
            text: TextSpan(
              text: box.text,
              style: TextStyle(
                color: color,
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
    }

    // Draw in order: Paragraphs -> Lines -> Words
    // Use different stroke widths to make them visible when overlapping
    _drawBBoxes(
      boxes: paragraphs,
      color: Colors.blue,
      strokeWidth: 1.0,
      printTargetText: false,
      translations: translations,
    );
    // _drawBBoxes(lines, Colors.green, 1.0, true);
    // _drawBBoxes(words, Colors.red, 1.0, true);
  }

  @override
  bool shouldRepaint(covariant _BBoxPainter oldDelegate) {
    return oldDelegate.words != words ||
        oldDelegate.lines != lines ||
        oldDelegate.paragraphs != paragraphs ||
        oldDelegate.imageSize != imageSize;
  }
}

class _Guide extends ConsumerWidget {
  const _Guide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.paddingBottom);
    final screenWidth = ref.watch(P.app.screenWidth);
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final qw = ref.watch(P.app.qw);
    return Container(
      // decoration: BD(color: Colors.red.q(.2)),
      child: Column(
        crossAxisAlignment: .center,
        mainAxisAlignment: .center,
        children: [
          Container(
            // decoration: BD(color: Colors.red.q(.2)),
            padding: const .all(32),
            width: screenWidth,
            height: screenWidth,
            child: Column(
              crossAxisAlignment: .center,
              mainAxisAlignment: .center,
              children: [
                FaIcon(FontAwesomeIcons.camera, size: 48, color: qb.q(.6667)),
                16.h,
                const Text.rich(
                  textAlign: .center,
                  TextSpan(
                    children: [
                      TextSpan(text: "Click "),
                      TextSpan(
                        text: "Start",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: .bold,
                        ),
                      ),
                      TextSpan(
                        text: " to open the camera on your phone. RWKV can now translate the text you see in the camera.",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GD(
            onTap: P.ocr.onTapStart,
            child: C(
              decoration: BD(
                // border: Border.all(color: Colors.blue, width: 1),
                borderRadius: 48.r,
                color: primary.q(1),
                boxShadow: [BoxShadow(color: kB.q(.33), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              height: 96,
              width: 96,
              child: Center(
                child: T(
                  "Start",
                  s: TS(c: qw, s: 24, w: .w600),
                ),
              ),
            ),
          ),
          paddingBottom.h,
        ],
      ),
    );
  }
}

class _Camera extends ConsumerWidget {
  const _Camera();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: CameraPreview(
            P.ocr.controller,
            child: const _OcrOverlay(),
          ),
        ),
        const _CameraControls(),
      ],
    );
  }
}

class _CameraControls extends ConsumerWidget {
  const _CameraControls();

  Future<void> _onSelectWeightsTap() async {
    ModelSelector.show();
  }

  Future<void> _onModeTap() async {
    qr;
  }

  Future<void> _onStopTap() async {
    qr;
    P.ocr.onTapStop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.paddingBottom);

    return SizedBox(
      height: paddingBottom + 100,
      child: Row(
        mainAxisAlignment: .center,
        crossAxisAlignment: .center,
        spacing: 8,
        children: [
          GD(
            onTap: _onModeTap,
            child: C(
              decoration: BD(
                color: Colors.red.q(.2),
              ),
              padding: const .all(8),
              child: const T("Mode"),
            ),
          ),
          GD(
            onTap: _onStopTap,
            child: C(
              decoration: BD(
                color: Colors.blue.q(.2),
              ),
              padding: const .all(8),
              child: const T("Stop"),
            ),
          ),
          GD(
            onTap: _onSelectWeightsTap,
            child: C(
              decoration: BD(
                color: Colors.green.q(.2),
              ),
              padding: const .all(8),
              child: const T("Select Weights"),
            ),
          ),
        ],
      ),
    );
  }
}
