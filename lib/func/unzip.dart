// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:archive/archive_io.dart';
import 'package:halo/halo.dart';
import 'package:path/path.dart' as p;

/// 在 zip 文件所在的位置解压缩
Future<String> unzipInPlace(String modelPath) async {
  return await compute(_unzipInPlaceIsolate, modelPath);
}

/// 在 isolate 中执行解压缩的顶级函数
Future<String> _unzipInPlaceIsolate(String modelPath) async {
  final start = HF.milliseconds;
  qqq("start");
  final modelDir = p.dirname(modelPath);
  final modelPathWithoutZip = p.withoutExtension(modelPath);
  final exists = await File(modelPathWithoutZip).exists();
  final folderExists = await Directory(modelPathWithoutZip).exists();

  if (exists || folderExists) {
    qqq("file or folder already exists: $modelPathWithoutZip");
    return modelPathWithoutZip;
  }

  final inputStream = InputFileStream(modelPath);

  final archive = ZipDecoder().decodeStream(inputStream);
  final symbolicLinks = [];

  for (final file in archive) {
    if (file.isSymbolicLink) {
      symbolicLinks.add(file);
      continue;
    }
    if (file.isFile) {
      final filePath = p.join(modelDir, file.name);
      final parentDir = Directory(p.dirname(filePath));
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      final outputStream = OutputFileStream(filePath);

      file.writeContent(outputStream);

      await outputStream.close();
    } else {
      await Directory(p.join(modelDir, file.name)).create(recursive: true);
    }
  }

  for (final entity in symbolicLinks) {
    final link = Link(p.join(modelDir, entity.fullPathName));
    await link.create(entity.symbolicLink!, recursive: true);
  }

  final end = HF.milliseconds;
  qqq("time cost: ${end - start}ms");
  qqq("end");
  return modelPathWithoutZip;
}
