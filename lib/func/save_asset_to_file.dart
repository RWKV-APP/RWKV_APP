import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

Future<void> saveAssetToFile(String assetPath, String targetPath) async {
  final rawAssetFile = await rootBundle.load(assetPath);
  final bytes = rawAssetFile.buffer.asUint8List();
  final file = File(targetPath);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
}
