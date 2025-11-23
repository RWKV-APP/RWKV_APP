import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// 通过流式读取文件，计算其 MD5 值
Future<String> calculateFileMd5(String filePath) {
  final res = compute(
    (filePath) {
      final file = File(filePath);
      // 打开文件流，并通过 md5 的 bind 方法进行处理
      final digest = md5.bind(file.openRead()).first;
      return digest.toString();
    },
    filePath,
    debugLabel: 'calculateFileMd5',
  );
  return res;
}
