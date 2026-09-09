// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

// Project imports:
import 'package:zone/func/debug_trace.dart';

/// 在 zip 文件所在的位置解压缩
Future<String> unzipInPlace(String modelPath) async {
  return await compute(_unzipInPlaceIsolate, modelPath);
}

/// 在 isolate 中执行解压缩的顶级函数
Future<String> _unzipInPlaceIsolate(String modelPath) async {
  final start = DateTime.now().millisecondsSinceEpoch;
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
  Directory? staging;

  try {
    final archive = ZipDecoder().decodeStream(inputStream);
    final folderPrefix = '${p.basename(modelPathWithoutZip)}/';
    final wrapped = archive.any((file) => file.name.startsWith(folderPrefix));
    final extractionRoot = wrapped ? modelDir : modelPathWithoutZip;
    final modelRoot = p.normalize(p.absolute(modelPathWithoutZip));

    String outputPath(String name) {
      final path = p.normalize(p.absolute(p.join(extractionRoot, name)));
      if (path != modelRoot && !p.isWithin(modelRoot, path)) {
        throw FormatException('Archive entry escapes the model directory: $name');
      }
      return path;
    }

    final links = archive.where((file) => file.isSymbolicLink).toList();
    final linkPaths = links.map((file) => outputPath(file.name)).toList();
    // Validate every destination before writing files or creating links.
    for (final file in archive) {
      final path = outputPath(file.name);
      if (linkPaths.any((linkPath) => p.isWithin(linkPath, path))) {
        throw FormatException('Archive entry is nested under a symbolic link: ${file.name}');
      }
      if (file.isSymbolicLink) {
        final target = p.normalize(p.join(p.dirname(path), file.symbolicLink!));
        if (p.isAbsolute(file.symbolicLink!) || (target != modelRoot && !p.isWithin(modelRoot, target))) {
          throw FormatException('Archive link escapes the model directory: ${file.name}');
        }
      }
    }

    // Only a fully extracted archive becomes a reusable model directory.
    final temporary = await Directory(modelDir).createTemp('.${p.basename(modelRoot)}.unzip-');
    staging = temporary;
    String stagedPath(String name) => p.join(temporary.path, p.relative(outputPath(name), from: modelRoot));

    for (final file in archive.where((file) => !file.isSymbolicLink)) {
      final path = stagedPath(file.name);
      if (file.isFile) {
        await Directory(p.dirname(path)).create(recursive: true);
        final outputStream = OutputFileStream(path);
        try {
          file.writeContent(outputStream);
        } finally {
          await outputStream.close();
        }
      } else {
        await Directory(path).create(recursive: true);
      }
    }

    for (final file in links) {
      await Link(stagedPath(file.name)).create(file.symbolicLink!, recursive: true);
    }
    final resolvedRoot = await temporary.resolveSymbolicLinks();
    for (final file in links) {
      // Resolve actual links too: lexical normalization alone misses link/../ escapes.
      final target = await Link(stagedPath(file.name)).resolveSymbolicLinks();
      if (target != resolvedRoot && !p.isWithin(resolvedRoot, target)) {
        throw FormatException('Archive link resolves outside the model directory: ${file.name}');
      }
    }
    await temporary.rename(modelPathWithoutZip);
  } finally {
    await inputStream.close();
    if (staging != null && await staging.exists()) {
      await staging.delete(recursive: true);
    }
  }

  final end = DateTime.now().millisecondsSinceEpoch;
  qqq("time cost: ${end - start}ms");
  qqq("end");
  return modelPathWithoutZip;
}
