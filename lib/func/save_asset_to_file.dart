// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/services.dart';

Future<bool> saveAssetToFile(String assetPath, String targetPath) async {
  final rawAssetFile = await rootBundle.load(assetPath);
  final bytes = rawAssetFile.buffer.asUint8List();
  final file = File(targetPath);
  if (await file.exists()) {
    final existingSize = await file.length();
    if (existingSize == bytes.lengthInBytes) return false;
  }
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
  return true;
}
