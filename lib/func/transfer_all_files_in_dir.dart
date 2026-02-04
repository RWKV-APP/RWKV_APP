import 'dart:io';

import 'package:path/path.dart' as p;

/// 将 [sourceDirPath] 下所有的文件 / 文件夹递归地移动至 [targetDirPath] 下
Future<void> transferAllFilesInDir(String sourceDirPath, String targetDirPath) async {
  final sourceDir = Directory(sourceDirPath);
  if (!await sourceDir.exists()) return;
  final targetDir = Directory(targetDirPath);
  await targetDir.create(recursive: true);

  await for (final entity in sourceDir.list()) {
    final name = p.basename(entity.path);
    final destPath = p.join(targetDirPath, name);
    if (entity is File) {
      final destFile = File(destPath);
      if (await destFile.exists()) await destFile.delete();
      await entity.rename(destPath);
    } else if (entity is Directory) {
      await transferAllFilesInDir(entity.path, destPath);
      await entity.delete(recursive: true);
    }
  }
}
