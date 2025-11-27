import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/store/p.dart';

class PageOcr extends ConsumerWidget {
  const PageOcr({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerCreated = ref.watch(P.ocr.controllerCreated);
    final initialized = ref.watch(P.ocr.initialized);
    return Scaffold(
      appBar: AppBar(
        title: Text("OCR"),
      ),
      body: Column(
        crossAxisAlignment: .start,
        children: [
          Text(controllerCreated ? "Controller created" : "Controller not created"),
          Text(initialized ? "Initialized" : "Not initialized"),
          if (controllerCreated && initialized) CameraPreview(P.ocr.controller),
        ],
      ),
    );
  }
}
