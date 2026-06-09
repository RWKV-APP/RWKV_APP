// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/func/gguf_metadata.dart';
import 'package:zone/func/local_chat_model_filter.dart';
import 'package:zone/func/local_model_discovery.dart';
import 'package:zone/model/file_info.dart';

void main() {
  group('GgufMetadataReader', () {
    test('reads RWKV architecture metadata', () async {
      final tempDir = await Directory.systemTemp.createTemp('gguf_metadata_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final file = await _writeBytes(
        tempDir,
        'rwkv.gguf',
        _buildGgufBytes(
          architecture: 'rwkv7',
          name: 'RWKV Local Test',
          fileType: 15,
          sizeLabel: '0.4B',
          contextLength: 8192,
        ),
      );

      final metadata = await GgufMetadataReader.read(file.path);

      expect(metadata, isNotNull);
      expect(metadata!.architecture, 'rwkv7');
      expect(metadata.name, 'RWKV Local Test');
      expect(metadata.quantization, 'Q4_K_M');
      expect(metadata.sizeLabel, '0.4B');
      expect(metadata.rwkvContextLength, 8192);
      expect(metadata.isRwkvArchitecture, isTrue);
    });

    test('rejects non RWKV architecture metadata', () async {
      final tempDir = await Directory.systemTemp.createTemp('gguf_metadata_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final file = await _writeBytes(
        tempDir,
        'llama.gguf',
        _buildGgufBytes(
          architecture: 'llama',
          name: 'Llama Local Test',
        ),
      );

      final metadata = await GgufMetadataReader.read(file.path);

      expect(metadata, isNotNull);
      expect(metadata!.isRwkvArchitecture, isFalse);
    });

    test('returns null for bad magic and truncated files', () async {
      final tempDir = await Directory.systemTemp.createTemp('gguf_metadata_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final badMagic = await _writeBytes(
        tempDir,
        'bad_magic.gguf',
        _buildGgufBytes(
          architecture: 'rwkv',
          name: 'Bad Magic',
          magic: 'NOPE',
        ),
      );
      final truncated = await _writeBytes(tempDir, 'truncated.gguf', ascii.encode('GGUF'));

      expect(await GgufMetadataReader.read(badMagic.path), isNull);
      expect(await GgufMetadataReader.read(truncated.path), isNull);
    });

    test('returns metadata with unavailable RWKV flag when architecture is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp('gguf_metadata_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final file = await _writeBytes(
        tempDir,
        'missing_architecture.gguf',
        _buildGgufBytes(name: 'No Architecture'),
      );

      final metadata = await GgufMetadataReader.read(file.path);

      expect(metadata, isNotNull);
      expect(metadata!.architecture, isNull);
      expect(metadata.isRwkvArchitecture, isFalse);
    });
  });

  group('discoverLocalModelFiles', () {
    test('returns pth files and RWKV gguf files only', () async {
      final tempDir = await Directory.systemTemp.createTemp('local_model_discovery_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      await _writeBytes(tempDir, 'model.pth', <int>[1, 2, 3]);
      await _writeBytes(
        tempDir,
        'rwkv.gguf',
        _buildGgufBytes(
          architecture: 'rwkv7',
          name: 'rwkv7-g1g-1.5b-20260526-ctx8192.pth',
          fileType: 15,
          sizeLabel: '0.4B',
          contextLength: 8192,
          blockCount: 12,
        ),
      );
      await _writeBytes(
        tempDir,
        'llama.gguf',
        _buildGgufBytes(
          architecture: 'llama',
          name: 'Llama GGUF',
        ),
      );
      await _writeBytes(tempDir, 'notes.txt', utf8.encode('ignore me'));

      final result = await discoverLocalModelFiles(tempDir.path);
      final fileNames = result.files.map((file) => file.fileName).toSet();
      final kinds = {
        for (final file in result.files) file.fileName: file.kind,
      };

      expect(result.hasError, isFalse);
      expect(fileNames, <String>{'model.pth', 'rwkv.gguf'});
      expect(kinds['model.pth'], LocalModelFileKind.pth);
      expect(kinds['rwkv.gguf'], LocalModelFileKind.rwkvGguf);
      final rwkvFile = result.files.firstWhere((file) => file.fileName == 'rwkv.gguf');
      expect(rwkvFile.displayName, 'rwkv.gguf');
      expect(rwkvFile.ggufName, 'rwkv7-g1g-1.5b-20260526-ctx8192.pth');
      expect(rwkvFile.ggufQuantization, 'Q4_K_M');
      expect(rwkvFile.ggufSizeLabel, '0.4B');
      expect(rwkvFile.ggufContextLength, 8192);
      expect(rwkvFile.ggufBlockCount, 12);
    });
  });

  group('local chat model filter', () {
    test('extracts known Chat, See, and Talk file names from config including state files', () {
      final config = <String, dynamic>{
        "chat": {
          "model_config": [
            {
              "name": "Chat Model",
              "url": "owner/repo/resolve/main/gguf/chat.gguf",
              "fileSize": 1,
              "platforms": ["macos"],
              "state": [
                {
                  "name": "Chat State",
                  "fileName": "chat-state.gguf",
                  "url": "owner/repo/resolve/main/gguf/chat-state.gguf",
                  "fileSize": 1,
                },
              ],
            },
          ],
        },
        "tts": {
          "model_config": [
            {
              "name": "Talk Core",
              "url": "owner/repo/resolve/main/multimodal/sparktts/talk.gguf",
              "fileSize": 1,
              "platforms": ["macos"],
              "state": [
                {
                  "name": "Talk State",
                  "fileName": "talk-state.st",
                  "url": "owner/repo/resolve/main/multimodal/sparktts/talk-state.st",
                  "fileSize": 1,
                },
              ],
            },
          ],
        },
        "world": {
          "model_config": [
            {
              "name": "See Model",
              "url": "owner/repo/resolve/main/multimodal/model/rwkv-vl/see.gguf",
              "fileSize": 1,
              "platforms": ["macos"],
              "state": [
                {
                  "name": "See State",
                  "fileName": "see-state.gguf",
                  "url": "owner/repo/resolve/main/multimodal/model/rwkv-vl/see-state.gguf",
                  "fileSize": 1,
                },
              ],
            },
          ],
        },
      };

      final fileNames = localChatExcludedConfigFileNamesFromConfig(config);

      expect(fileNames, containsAll(<String>["chat.gguf", "chat-state.gguf", "talk.gguf", "talk-state.st", "see.gguf", "see-state.gguf"]));
    });

    test('hides known Chat, See, and Talk local GGUF files only', () {
      final excludedFileNames = <String>{"chat.gguf", "see.gguf", "talk.gguf", "same-name.pth"};

      expect(
        shouldShowLocalChatModelFile(
          fileInfo: _localGgufFile("custom.gguf"),
          excludedConfigFileNames: excludedFileNames,
        ),
        isTrue,
      );
      expect(
        shouldShowLocalChatModelFile(
          fileInfo: _localGgufFile("chat.gguf"),
          excludedConfigFileNames: excludedFileNames,
        ),
        isFalse,
      );
      expect(
        shouldShowLocalChatModelFile(
          fileInfo: _localGgufFile("see.gguf"),
          excludedConfigFileNames: excludedFileNames,
        ),
        isFalse,
      );
      expect(
        shouldShowLocalChatModelFile(
          fileInfo: _localGgufFile("talk.gguf"),
          excludedConfigFileNames: excludedFileNames,
        ),
        isFalse,
      );
      expect(
        shouldShowLocalChatModelFile(
          fileInfo: _localPthFile("same-name.pth"),
          excludedConfigFileNames: excludedFileNames,
        ),
        isTrue,
      );
    });
  });
}

Future<File> _writeBytes(Directory directory, String fileName, List<int> bytes) async {
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return file;
}

FileInfo _localGgufFile(String fileName) {
  return _localFile(fileName: fileName, fromLocalGgufFile: true);
}

FileInfo _localPthFile(String fileName) {
  return _localFile(fileName: fileName, fromLocalGgufFile: false);
}

FileInfo _localFile({
  required String fileName,
  required bool fromLocalGgufFile,
}) {
  return FileInfo(
    name: fileName,
    fileName: fileName,
    fileType: FileType.weights,
    fileSize: 1,
    raw: "/tmp/$fileName",
    isDebug: false,
    backend: null,
    sha256: null,
    modelSize: null,
    quantization: null,
    updatedAt: null,
    timestamp: null,
    date: null,
    fromPthFile: !fromLocalGgufFile,
    fromLocalGgufFile: fromLocalGgufFile,
  );
}

List<int> _buildGgufBytes({
  String? architecture,
  String? name,
  int? fileType,
  String? sizeLabel,
  int? contextLength,
  int? architectureVersion,
  int? blockCount,
  String magic = 'GGUF',
}) {
  final builder = BytesBuilder();
  builder.add(ascii.encode(magic));
  _addUint32(builder, 3);
  _addUint64(builder, 0);

  final entries = <(String key, Object value)>[];
  if (architecture != null) {
    entries.add(('general.architecture', architecture));
  }
  if (name != null) {
    entries.add(('general.name', name));
  }
  if (fileType != null) {
    entries.add(('general.file_type', fileType));
  }
  if (sizeLabel != null) {
    entries.add(('general.size_label', sizeLabel));
  }
  if (architectureVersion != null) {
    entries.add(('rwkv.architecture_version', architectureVersion));
  }
  if (contextLength != null) {
    entries.add(('rwkv.context_length', contextLength));
  }
  if (blockCount != null) {
    entries.add(('rwkv.block_count', blockCount));
  }

  _addUint64(builder, entries.length);
  for (final entry in entries) {
    _addString(builder, entry.$1);
    if (entry.$2 is String) {
      _addUint32(builder, 8);
      _addString(builder, entry.$2 as String);
    } else if (entry.$2 is int) {
      _addUint32(builder, 10);
      _addUint64(builder, entry.$2 as int);
    }
  }

  return builder.toBytes();
}

void _addString(BytesBuilder builder, String value) {
  final bytes = utf8.encode(value);
  _addUint64(builder, bytes.length);
  builder.add(bytes);
}

void _addUint32(BytesBuilder builder, int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  builder.add(data.buffer.asUint8List());
}

void _addUint64(BytesBuilder builder, int value) {
  final data = ByteData(8)..setUint64(0, value, Endian.little);
  builder.add(data.buffer.asUint8List());
}
