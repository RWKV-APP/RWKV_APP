import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zone/func/local_model_discovery.dart';
import 'package:zone/func/weight_import.dart';

Uint8List _gguf(String architecture) {
  final bytes = BytesBuilder();
  void u32(int value) => bytes.add((ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List());
  void u64(int value) => bytes.add((ByteData(8)..setUint64(0, value, Endian.little)).buffer.asUint8List());
  void string(String value) {
    final encoded = utf8.encode(value);
    u64(encoded.length);
    bytes.add(encoded);
  }

  bytes.add(ascii.encode('GGUF'));
  u32(3);
  u64(0);
  u64(1);
  string('general.architecture');
  u32(8);
  string(architecture);
  return bytes.takeBytes();
}

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('weight-import-test-');
  });
  tearDown(() => directory.delete(recursive: true));

  test('catalogued files keep existing admission; unknown GGUF is denied by default', () async {
    final file = await PreparedWeightFile.prepare(fileBytes: Uint8List.fromList([1, 2]), fileName: 'known.bin');
    addTearDown(file.dispose);
    final target = p.join(directory.path, file.name);
    await file.save(targetPath: target, catalogued: true);
    expect(await File(target).readAsBytes(), [1, 2]);
    final rwkv = await PreparedWeightFile.prepare(fileBytes: _gguf('rwkv7'), fileName: 'unknown.gguf');
    addTearDown(rwkv.dispose);
    await expectLater(
      rwkv.save(targetPath: p.join(directory.path, rwkv.name), catalogued: false),
      throwsA(WeightImportFailure.unsupported),
    );
  });

  test('bytes and path imports recover from disk, and deletion survives rescan', () async {
    final bytes = _gguf('rwkv7');
    final prepared = await PreparedWeightFile.prepare(fileBytes: bytes, fileName: 'unknown.gguf');
    final temporaryPath = prepared.file.path;
    final target = p.join(directory.path, prepared.name);
    try {
      expect(await prepared.isRwkvGguf, isTrue);
      await prepared.save(targetPath: target, catalogued: false, allowUncataloguedGguf: true);
    } finally {
      await prepared.dispose();
    }
    expect(await File(temporaryPath).exists(), isFalse);
    final pathFile = await PreparedWeightFile.prepare(sourceFile: File(target), fileName: 'copy.gguf');
    await pathFile.save(targetPath: p.join(directory.path, 'copy.gguf'), catalogued: false, allowUncataloguedGguf: true);
    await pathFile.dispose();
    final restored = await discoverLocalModelFiles(directory.path);
    expect(restored.files.map((file) => file.fileName), containsAll(['unknown.gguf', 'copy.gguf']));
    expect(restored.files.every((file) => file.kind == LocalModelFileKind.rwkvGguf), isTrue);
    await File(target).delete();
    expect((await discoverLocalModelFiles(directory.path)).files.map((file) => file.fileName), ['copy.gguf']);
  });

  test('force flag still rejects non-RWKV, malformed, unsupported version and wrong extension', () async {
    final badVersion = _gguf('rwkv7');
    ByteData.sublistView(badVersion).setUint32(4, 100, Endian.little);
    for (final (name, bytes) in [
      ('llama.gguf', _gguf('llama')),
      ('bad.gguf', Uint8List.fromList(ascii.encode('GGUF'))),
      ('version.gguf', badVersion),
      ('rwkv.bin', _gguf('rwkv7')),
    ]) {
      final file = await PreparedWeightFile.prepare(fileBytes: bytes, fileName: name);
      final temporaryPath = file.file.path;
      try {
        expect(await file.isRwkvGguf, isFalse);
        await expectLater(
          file.save(targetPath: p.join(directory.path, name), catalogued: false, allowUncataloguedGguf: true),
          throwsA(WeightImportFailure.unsupported),
        );
      } finally {
        await file.dispose();
      }
      expect(await File(temporaryPath).exists(), isFalse);
    }
    expect(await directory.list().toList(), isEmpty);
  });

  test('force import does not overwrite; staged size/copy failure preserves original', () async {
    final target = await File(p.join(directory.path, 'model.gguf')).writeAsBytes([4, 5, 6]);
    final file = await PreparedWeightFile.prepare(fileBytes: _gguf('rwkv7'), fileName: 'model.gguf');
    addTearDown(file.dispose);
    await expectLater(
      file.save(targetPath: target.path, catalogued: false, allowUncataloguedGguf: true),
      throwsA(WeightImportFailure.fileExists),
    );
    await expectLater(
      file.save(targetPath: target.path, catalogued: true, overwrite: true, expectedSize: 999),
      throwsA(WeightImportFailure.sizeMismatch),
    );
    expect(await target.readAsBytes(), [4, 5, 6]);
    expect((await directory.list().toList()).length, 1);
    await file.save(targetPath: target.path, catalogued: false, allowUncataloguedGguf: true, overwrite: true);
    expect(await target.readAsBytes(), _gguf('rwkv7'));
    await file.file.delete();
    await expectLater(file.save(targetPath: target.path, catalogued: true, overwrite: true), throwsA(isA<FileSystemException>()));
    expect(await target.readAsBytes(), _gguf('rwkv7'));
    expect((await directory.list().toList()).length, 1);
  });

  test('cancelled bytes-only preparation cleans up and rejects escaping filenames', () async {
    final file = await PreparedWeightFile.prepare(fileBytes: _gguf('rwkv'), fileName: 'cancelled.gguf');
    final temporaryPath = file.file.path;
    await file.dispose();
    expect(await File(temporaryPath).exists(), isFalse);
    for (final name in ['', '..', '../escape.gguf', r'..\escape.gguf']) {
      await expectLater(PreparedWeightFile.prepare(fileBytes: _gguf('rwkv'), fileName: name), throwsA(WeightImportFailure.invalidName));
    }
  });

  test('replacement waits for a complete staged file and preserves the original if release fails', () async {
    final target = await File(p.join(directory.path, 'model.gguf')).writeAsBytes([1, 2]);
    final file = await PreparedWeightFile.prepare(fileBytes: _gguf('rwkv7'), fileName: 'model.gguf');
    addTearDown(file.dispose);
    bool called = false;
    await expectLater(
      file.save(
        targetPath: target.path,
        catalogued: false,
        allowUncataloguedGguf: true,
        overwrite: true,
        beforeReplace: () async {
          called = true;
          final staging = (await directory.list().toList()).whereType<Directory>().single;
          expect(await File(p.join(staging.path, file.name)).readAsBytes(), _gguf('rwkv7'));
          expect(await target.readAsBytes(), [1, 2]);
          throw StateError('model is still in use');
        },
      ),
      throwsStateError,
    );
    expect(called, isTrue);
    expect(await target.readAsBytes(), [1, 2]);
    expect((await directory.list().toList()).length, 1);
  });
}
