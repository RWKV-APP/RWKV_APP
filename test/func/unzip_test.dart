import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zone/func/unzip.dart';

List<int> _encodeUnixArchive(Archive archive) {
  final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
  final header = ByteData.sublistView(bytes);
  int offset = header.getUint32(bytes.length - 6, Endian.little);
  for (final _ in archive) {
    // ZipEncoder writes a DOS creator flag; symlink mode bits require Unix.
    bytes[offset + 5] = 3;
    offset +=
        46 +
        header.getUint16(offset + 28, Endian.little) +
        header.getUint16(offset + 30, Endian.little) +
        header.getUint16(offset + 32, Endian.little);
  }
  expect(ZipDecoder().decodeBytes(bytes).any((file) => file.isSymbolicLink), isTrue);
  return bytes;
}

void main() {
  for (final (wrapped, config) in [(true, 'config.yaml'), (false, 'config.yaml'), (false, 'config.json')]) {
    test('loads ${wrapped ? 'wrapped' : 'flat'} model archive with $config', () async {
      final temporary = Directory.systemTemp.createTempSync('rwkv-unzip-test-');
      addTearDown(() => temporary.deleteSync(recursive: true));
      final archive = Archive();
      final prefix = wrapped ? 'model/' : '';
      archive.addFile(ArchiveFile.string('$prefix$config', 'model configuration'));
      archive.addFile(ArchiveFile.string('${prefix}weights/data.bin', 'model payload'));
      final zip = File(p.join(temporary.path, 'model.zip'));
      zip.writeAsBytesSync(ZipEncoder().encode(archive));

      final modelPath = await unzipInPlace(zip.path);

      expect(modelPath, p.join(temporary.path, 'model'));
      expect(File(p.join(modelPath, config)).readAsStringSync(), 'model configuration');
      expect(File(p.join(modelPath, 'weights/data.bin')).readAsStringSync(), 'model payload');
      expect(File(p.join(temporary.path, config)).existsSync(), isFalse);
      expect(await unzipInPlace(zip.path), modelPath);
    });
  }

  test('rejects paths outside the model directory before extraction', () async {
    final temporary = Directory.systemTemp.createTempSync('rwkv-unzip-test-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string('config.json', 'model configuration'))
      ..addFile(ArchiveFile.string('../other-model.txt', 'must not overwrite'));
    final zip = File(p.join(temporary.path, 'model.zip'));
    zip.writeAsBytesSync(ZipEncoder().encode(archive));

    await expectLater(unzipInPlace(zip.path), throwsFormatException);

    expect(File(p.join(temporary.path, 'other-model.txt')).existsSync(), isFalse);
    expect(Directory(p.join(temporary.path, 'model')).existsSync(), isFalse);
  });

  test('removes incomplete extraction and can retry the archive', () async {
    final temporary = Directory.systemTemp.createTempSync('rwkv-unzip-test-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final zip = File(p.join(temporary.path, 'model.zip'));
    final broken = Archive()
      ..addFile(ArchiveFile.string('config.json', 'configuration'))
      ..addFile(ArchiveFile.string('weights', 'conflicts with directory'))
      ..addFile(ArchiveFile.string('weights/data.bin', 'payload'));
    zip.writeAsBytesSync(ZipEncoder().encode(broken));

    await expectLater(unzipInPlace(zip.path), throwsA(isA<FileSystemException>()));

    expect(temporary.listSync().map((entry) => p.basename(entry.path)), ['model.zip']);
    final fixed = Archive()..addFile(ArchiveFile.string('config.json', 'complete configuration'));
    zip.writeAsBytesSync(ZipEncoder().encode(fixed));
    final modelPath = await unzipInPlace(zip.path);
    expect(File(p.join(modelPath, 'config.json')).readAsStringSync(), 'complete configuration');
  });

  test('rejects symbolic links outside the model directory', () async {
    final temporary = Directory.systemTemp.createTempSync('rwkv-unzip-test-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string('config.json', 'configuration'))
      ..addFile(ArchiveFile.string('escape', '../outside')..mode = 0xa1ff);
    final zip = File(p.join(temporary.path, 'model.zip'));
    zip.writeAsBytesSync(_encodeUnixArchive(archive));

    await expectLater(unzipInPlace(zip.path), throwsFormatException);

    expect(temporary.listSync().map((entry) => p.basename(entry.path)), ['model.zip']);
  });

  test('rejects entries nested under an archive symbolic link', () async {
    final temporary = Directory.systemTemp.createTempSync('rwkv-unzip-test-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string('config.json', 'configuration'))
      ..addFile(ArchiveFile.string('alias', '.')..mode = 0xa1ff)
      ..addFile(ArchiveFile.string('alias/payload.bin', 'payload'));
    final zip = File(p.join(temporary.path, 'model.zip'));
    zip.writeAsBytesSync(_encodeUnixArchive(archive));

    await expectLater(unzipInPlace(zip.path), throwsFormatException);

    expect(temporary.listSync().map((entry) => p.basename(entry.path)), ['model.zip']);
  });

  for (final escapes in [false, true]) {
    test('${escapes ? 'rejects escaping' : 'preserves internal'} resolved symbolic links', () async {
      final temporary = Directory.systemTemp.createTempSync('rwkv-unzip-test-');
      addTearDown(() => temporary.deleteSync(recursive: true));
      final outside = File(p.join(temporary.path, 'outside.txt'))..writeAsStringSync('unchanged');
      final probe = Link(p.join(temporary.path, 'probe'));
      try {
        await probe.create(outside.path);
      } on FileSystemException catch (error) {
        if (!Platform.isWindows || error.osError?.errorCode != 1314) rethrow;
        markTestSkipped('Windows does not grant symbolic-link creation privileges');
        return;
      }
      await probe.delete();
      final archive = Archive()..addFile(ArchiveFile.string('config.json', 'configuration'));
      if (escapes) {
        archive
          ..addFile(ArchiveFile.string('root-link', '.')..mode = 0xa1ff)
          ..addFile(ArchiveFile.string('alias', 'root-link/../outside.txt')..mode = 0xa1ff);
      } else {
        archive.addFile(ArchiveFile.string('alias', 'config.json')..mode = 0xa1ff);
      }
      final zip = File(p.join(temporary.path, 'model.zip'));
      zip.writeAsBytesSync(_encodeUnixArchive(archive));

      if (escapes) {
        // Windows may refuse this link target before it can be resolved.
        await expectLater(unzipInPlace(zip.path), throwsA(anyOf(isA<FormatException>(), isA<FileSystemException>())));
        expect(temporary.listSync().map((entry) => p.basename(entry.path)), unorderedEquals(['model.zip', 'outside.txt']));
        expect(outside.readAsStringSync(), 'unchanged');
        return;
      }
      final modelPath = await unzipInPlace(zip.path);
      expect(File(p.join(modelPath, 'alias')).readAsStringSync(), 'configuration');
      expect(await Link(p.join(modelPath, 'alias')).target(), 'config.json');
    });
  }
}
