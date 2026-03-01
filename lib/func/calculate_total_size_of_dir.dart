// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

/// 在 isolate 中计算指定目录下所有文件的总大小, 递归遍历所有文件, 文件夹
Future<int> calculateTotalSizeOfDir(String dirPath) {
  return compute(
    _calculateTotalSizeOfDirIsolate,
    dirPath,
    debugLabel: 'calculateTotalSizeOfDir',
  );
}

Future<int> _calculateTotalSizeOfDirIsolate(String dirPath) async {
  final dir = Directory(dirPath);
  if (!await dir.exists()) return 0;

  var total = 0;

  // 递归遍历目录下的所有文件和文件夹
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final stat = await entity.stat();
      total += stat.size;
    }
  }

  return total;
}

