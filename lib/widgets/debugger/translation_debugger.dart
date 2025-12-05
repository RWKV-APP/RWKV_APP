// ignore_for_file: dead_code

import 'package:zone/store/p.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

class TranslationDebugger extends ConsumerWidget {
  const TranslationDebugger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(P.rwkv.currentModel);
    final isPreviewPaused = ref.watch(P.ocr.isPreviewPaused);
    final isRecordingPaused = ref.watch(P.ocr.isRecordingPaused);
    final isRecordingVideo = ref.watch(P.ocr.isRecordingVideo);
    final isStreamingImages = ref.watch(P.ocr.isStreamingImages);
    final paddingTop = ref.watch(P.app.paddingTop);
    final pageKey = ref.watch(P.app.pageKey);
    final paragraphs = ref.watch(P.ocr.paragraphs);
    final previewPauseOrientation = ref.watch(P.ocr.previewPauseOrientation);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final translations = ref.watch(P.ocr.translations);
    final onScreenTexts = ref.watch(P.ocr.onScreenTexts);
    final batchTaskLines = ref.watch(P.ocr.batchTaskLines);
    final batchTranslations = ref.watch(P.ocr.batchTranslations);

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Material(
          textStyle: TS(
            ff: "Monospace",
            c: qw,
            s: 8,
          ),
          color: Colors.transparent,
          child: SizedBox(
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .end,
                children:
                    [
                      paddingTop.h,
                      T("pageKey".codeToName),
                      T(pageKey.toString()),
                      T("currentModel".codeToName),
                      T(currentModel?.fileName ?? "null"),
                      T("isRecordingVideo".codeToName),
                      T(isRecordingVideo.toString()),
                      T("isStreamingImages".codeToName),
                      T(isStreamingImages.toString()),
                      T("isPreviewPaused".codeToName),
                      T(isPreviewPaused.toString()),
                      T("previewPauseOrientation".codeToName),
                      T(previewPauseOrientation?.toString() ?? "null"),
                      T("paragraphs".codeToName + " Count"),
                      T(paragraphs.length.toString()),
                      T("onScreenTexts".codeToName + " Count"),
                      T(onScreenTexts.length.toString()),
                      T("batchTaskLines".codeToName + " Count"),
                      T(batchTaskLines.length.toString()),
                      T("batchTranslations".codeToName + " Count"),
                      T(batchTranslations.length.toString()),
                    ].indexMap((index, e) {
                      return Container(
                        margin: .only(top: index % 2 == 0 ? 0 : 1),
                        decoration: BoxDecoration(color: qb.q(.66)),
                        child: e,
                      );
                    }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
