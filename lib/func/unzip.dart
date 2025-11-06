import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:halo/halo.dart';

/// 在 zip 文件所在的位置解压缩
Future<String> unzipInPlace(String modelPath) async {
  final start = HF.milliseconds;
  qqq("unzipInPlace start");
  final modelDir = modelPath.substring(0, modelPath.lastIndexOf('/'));
  final modelPathWithoutZip = modelPath.substring(0, modelPath.lastIndexOf('.zip'));
  final exists = await File(modelPathWithoutZip).exists();

  if (exists) await File(modelPathWithoutZip).delete();

  final inputStream = InputFileStream(modelPath);

  final archive = ZipDecoder().decodeStream(inputStream);
  final symbolicLinks = [];

  for (final file in archive) {
    if (file.isSymbolicLink) {
      symbolicLinks.add(file);
      continue;
    }
    if (file.isFile) {
      final outputStream = OutputFileStream(modelDir + '/' + file.name);

      file.writeContent(outputStream);

      await outputStream.close();
    } else {
      await Directory(modelDir + '/' + file.name).create(recursive: true);
    }
  }

  for (final entity in symbolicLinks) {
    final link = Link(modelDir + '/' + entity.fullPathName);
    await link.create(entity.symbolicLink!, recursive: true);
  }

  final end = HF.milliseconds;
  qqq("unzipInPlace time cost: ${end - start}ms");
  qqq("unzipInPlace end");
  return modelPathWithoutZip;
}
