// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> normalizeImageForVision(String imagePath) async {
  if (imagePath.isEmpty) return imagePath;

  final file = File(imagePath);
  if (!await file.exists()) return imagePath;

  final isWebp = await _isWebpFile(file, imagePath);
  if (!isWebp) return imagePath;

  try {
    final bytes = await file.readAsBytes();
    final jpegBytes = await compute(_convertWebpToJpeg, bytes);
    final jpegFile = await _writeJpegToAppStorage(imagePath, jpegBytes);
    return jpegFile.path;
  } catch (e, stackTrace) {
    debugPrint("Failed to convert WebP image for vision: $e");
    debugPrintStack(stackTrace: stackTrace);
    return imagePath;
  }
}

Future<bool> _isWebpFile(File file, String imagePath) async {
  final extension = path.extension(imagePath).toLowerCase();
  if (extension == ".webp") return true;

  final fileLength = await file.length();
  if (fileLength < 12) return false;

  final randomAccessFile = await file.open();
  try {
    final header = await randomAccessFile.read(12);
    return _hasWebpSignature(Uint8List.fromList(header));
  } finally {
    await randomAccessFile.close();
  }
}

bool _hasWebpSignature(Uint8List bytes) {
  if (bytes.length < 12) return false;

  return bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}

Uint8List _convertWebpToJpeg(Uint8List bytes) {
  final decoded = img.decodeWebP(bytes, frame: 0);
  if (decoded == null) {
    throw const FormatException("Unable to decode WebP image");
  }

  final image = _flattenAlpha(decoded);
  return img.encodeJpg(image, quality: 92);
}

img.Image _flattenAlpha(img.Image image) {
  if (!image.hasAlpha) return image.convert(numChannels: 3);

  final background = img.Image(width: image.width, height: image.height, numChannels: 3);
  img.fill(background, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(background, image, blend: img.BlendMode.alpha);
  return background;
}

Future<File> _writeJpegToAppStorage(String sourcePath, Uint8List jpegBytes) async {
  final supportDir = await getApplicationSupportDirectory();
  final directory = Directory(path.join(supportDir.path, "vision-images"));
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final sourceName = path.basenameWithoutExtension(sourcePath);
  final safeSourceName = sourceName.replaceAll(RegExp(r"[^a-zA-Z0-9._-]+"), "_");
  final baseName = safeSourceName.isEmpty ? "image" : safeSourceName;
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final jpegPath = path.join(directory.path, "$baseName-$timestamp.jpg");
  final jpegFile = File(jpegPath);
  await jpegFile.writeAsBytes(jpegBytes, flush: true);
  return jpegFile;
}
