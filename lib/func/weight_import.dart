import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:zone/func/gguf_metadata.dart';

enum WeightImportFailure implements Exception {
  configurationNotLoaded,
  unsupported,
  fileExists,
  invalidName,
  noData,
  sizeMismatch,
}

/// Keeps bytes-only picker results on disk only for the duration of an import.
class PreparedWeightFile {
  final File file;
  final String name;
  final Directory? _temporaryDirectory;

  PreparedWeightFile._(this.file, this.name, this._temporaryDirectory);

  static Future<PreparedWeightFile> prepare({
    File? sourceFile,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    if (fileName.isEmpty ||
        fileName == '.' ||
        fileName == '..' ||
        p.posix.basename(fileName) != fileName ||
        p.windows.basename(fileName) != fileName) {
      throw WeightImportFailure.invalidName;
    }
    if (sourceFile != null) {
      if (!await sourceFile.exists()) throw const FileSystemException('File not found');
      return PreparedWeightFile._(sourceFile, fileName, null);
    }
    if (fileBytes == null) throw WeightImportFailure.noData;
    final directory = await Directory.systemTemp.createTemp('rwkv-import-');
    try {
      final file = await File(p.join(directory.path, fileName)).writeAsBytes(fileBytes, flush: true);
      return PreparedWeightFile._(file, fileName, directory);
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<bool> get isRwkvGguf async {
    if (p.extension(name).toLowerCase() != '.gguf') return false;
    final metadata = await GgufMetadataReader.read(file.path);
    return metadata?.isRwkvArchitecture ?? false;
  }

  /// Stage in the destination filesystem, then replace with a single rename.
  /// Never delete the original before the replacement is completely written.
  Future<void> save({
    required String targetPath,
    required bool catalogued,
    bool allowUncataloguedGguf = false,
    bool overwrite = false,
    int? expectedSize,
    Future<void> Function()? beforeReplace,
  }) async {
    if (!catalogued && (!allowUncataloguedGguf || !await isRwkvGguf)) {
      throw WeightImportFailure.unsupported;
    }
    final target = File(targetPath);
    if (!overwrite && await target.exists()) throw WeightImportFailure.fileExists;
    await target.parent.create(recursive: true);
    final staging = await target.parent.createTemp('.rwkv-import-');
    try {
      final staged = await file.copy(p.join(staging.path, name));
      if (expectedSize != null && expectedSize > 0 && await staged.length() != expectedSize) {
        throw WeightImportFailure.sizeMismatch;
      }
      if (!catalogued && ((await GgufMetadataReader.read(staged.path))?.isRwkvArchitecture != true)) {
        throw WeightImportFailure.unsupported;
      }
      // Recheck after the copy: another operation may have created this name.
      if (!overwrite && await target.exists()) throw WeightImportFailure.fileExists;
      if (overwrite && beforeReplace != null) await beforeReplace();
      await staged.rename(target.path);
    } finally {
      await staging.delete(recursive: true);
    }
  }

  Future<void> dispose() async {
    await _temporaryDirectory?.delete(recursive: true);
  }
}
