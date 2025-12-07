import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/bbox.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

class PageOcr extends ConsumerWidget {
  const PageOcr({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final image = ref.watch(P.ocr.image);
    final screenWidth = ref.watch(P.app.screenWidth);
    final enToZh = ref.watch(P.ocr.enToZh);
    final showTranslation = ref.watch(P.ocr.showTranslation);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.ocr_title),
        actions: [
          if (image != null) ...[
            // Toggle Visibility
            IconButton(
              icon: Icon(showTranslation ? Icons.visibility : Icons.visibility_off),
              tooltip: showTranslation ? s.hide_translations : s.show_translations,
              onPressed: () {
                P.ocr.toggleShowTranslation();
              },
            ),
            // Language Swap
            TextButton.icon(
              onPressed: () {
                P.ocr.toggleLanguage();
              },
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: Text(enToZh ? s.en_to_zh : s.zh_to_en),
            ),
            // Retake / Gallery
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              tooltip: s.pick_from_gallery,
              onPressed: () {
                P.ocr.pickFromGallery();
              },
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: s.take_photo,
              onPressed: () {
                P.ocr.takePhoto();
              },
            ),
            // Close
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: s.close,
              onPressed: () {
                P.ocr.clearImage();
              },
            ),
          ],
          if (image == null)
            TextButton(
              onPressed: () {
                push(.translator);
              },
              child: Text(s.offline_translator),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: .center,
        children: [
          screenWidth.w,
          if (image != null) Expanded(child: _ImageView(image: image)) else const Expanded(child: _Guide()),
        ],
      ),
    );
  }
}

class _ImageView extends ConsumerWidget {
  final XFile image;
  const _ImageView({required this.image});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          maxScale: 5.0,
          minScale: 0.1,
          child: Stack(
            children: [
              SizedBox.expand(
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox.expand(
                child: _OcrOverlay(),
              ),
            ],
          ),
        );
      },
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
    final showTranslation = ref.watch(P.ocr.showTranslation);

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
            showTranslation: showTranslation,
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
  final bool showTranslation;

  const _BBoxPainter({
    required this.words,
    required this.lines,
    required this.paragraphs,
    required this.imageSize,
    required this.translations,
    required this.showTranslation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero) return;

    // Calculate scale to "contain" the canvas
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;
    // Use min scale for contain
    final double scale = scaleX < scaleY ? scaleX : scaleY;

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

      // Only draw translations if showTranslation is true
      if (showTranslation) {
        for (final box in boxes) {
          final translation = translations[box.text];
          if (translation != null) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: translation,
                style: TextStyle(fontSize: 8, color: kB),
              ),
              textDirection: TextDirection.ltr,
            );
            // 限制最大宽度为 BBox 的显示宽度
            textPainter.layout(maxWidth: box.width.toDouble() * scale);
            textPainter.paint(
              canvas,
              Offset(
                box.x.toDouble() * scale + offsetX,
                box.y.toDouble() * scale + offsetY,
              ),
            );
          }
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
        oldDelegate.imageSize != imageSize ||
        oldDelegate.translations != translations ||
        oldDelegate.showTranslation != showTranslation;
  }
}

class _Guide extends ConsumerWidget {
  const _Guide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
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
                Text.rich(
                  textAlign: .center,
                  TextSpan(
                    children: [
                      TextSpan(text: s.ocr_guide_text(s.take_photo)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              GD(
                onTap: P.ocr.takePhoto,
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
                      s.camera,
                      s: TS(c: qw, s: 16, w: .w600),
                      textAlign: .center,
                    ),
                  ),
                ),
              ),
              GD(
                onTap: P.ocr.pickFromGallery,
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
                      s.gallery,
                      s: TS(c: qw, s: 16, w: .w600),
                      textAlign: .center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          paddingBottom.h,
        ],
      ),
    );
  }
}
