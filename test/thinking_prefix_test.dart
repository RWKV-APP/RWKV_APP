// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/func/thinking_prefix.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/thinking_mode.dart';

void main() {
  group('usesCompactFastThinkingPrefix', () {
    test('keeps G1g on the legacy prefix', () {
      final fileInfo = _fileInfo(
        name: 'RWKV7-G1g 1.5B',
        fileName: 'rwkv7-g1g-1.5b-20260526-Q6_K.gguf',
      );

      expect(usesCompactFastThinkingPrefix(fileInfo), isFalse);
    });

    test('uses the compact prefix for G1h and later lettered families', () {
      final g1h = _fileInfo(
        name: 'RWKV7-G1h 1.5B',
        fileName: 'renamed.gguf',
      );
      final g1i = _fileInfo(
        name: 'Renamed model',
        fileName: 'rwkv7-g1i-1.5b.gguf',
      );

      expect(usesCompactFastThinkingPrefix(g1h), isTrue);
      expect(usesCompactFastThinkingPrefix(g1i), isTrue);
    });

    test('uses the 2026-07-10 weight date as the inclusive cutoff', () {
      final before = _fileInfo(
        name: 'Custom model',
        fileName: 'custom-20260709.gguf',
      );
      final atCutoff = _fileInfo(
        name: 'Custom model',
        fileName: 'custom-20260710.gguf',
      );

      expect(usesCompactFastThinkingPrefix(before), isFalse);
      expect(usesCompactFastThinkingPrefix(atCutoff), isTrue);
    });

    test('prefers the embedded weight date over a newer artifact date', () {
      final fileInfo = _fileInfo(
        name: 'Custom model',
        fileName: 'custom-20260526.gguf',
        date: DateTime.utc(2026, 7, 12),
      );

      expect(usesCompactFastThinkingPrefix(fileInfo), isFalse);
    });

    test('keeps a known legacy family on the old prefix after repackaging', () {
      final fileInfo = _fileInfo(
        name: 'RWKV7-G1d 0.4B',
        fileName: 'renamed.gguf',
        date: DateTime.utc(2026, 7, 12),
      );

      expect(usesCompactFastThinkingPrefix(fileInfo), isFalse);
    });

    test('falls back to the artifact date when identity has no family or date', () {
      final before = _fileInfo(
        name: 'Custom model',
        fileName: 'custom.gguf',
        date: DateTime.utc(2026, 7, 9),
      );
      final after = _fileInfo(
        name: 'Custom model',
        fileName: 'custom.gguf',
        date: DateTime.utc(2026, 7, 12),
      );

      expect(usesCompactFastThinkingPrefix(before), isFalse);
      expect(usesCompactFastThinkingPrefix(after), isTrue);
    });

    test('classifies every current G1g and G1h chat artifact correctly', () {
      final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
      final chat = config['chat'] as Map<String, dynamic>;
      final modelConfigs = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
      final g1gModels = modelConfigs.where((modelConfig) => (modelConfig['name'] as String).toLowerCase().contains('g1g'));
      final g1hModels = modelConfigs.where((modelConfig) => (modelConfig['name'] as String).toLowerCase().contains('g1h'));

      expect(g1gModels, isNotEmpty);
      expect(g1hModels, isNotEmpty);
      for (final modelConfig in g1gModels) {
        expect(
          usesCompactFastThinkingPrefix(FileInfo.fromJSON(modelConfig)),
          isFalse,
          reason: modelConfig['name'] as String,
        );
      }
      for (final modelConfig in g1hModels) {
        expect(
          usesCompactFastThinkingPrefix(FileInfo.fromJSON(modelConfig)),
          isTrue,
          reason: modelConfig['name'] as String,
        );
      }
    });
  });

  group('thinkingTokenForModel', () {
    test('changes only the default Fast prefix for eligible models', () {
      final fileInfo = _fileInfo(
        name: 'RWKV7-G1h 1.5B',
        fileName: 'rwkv7-g1h-1.5b-20260710-Q6_K.gguf',
      );

      expect(
        thinkingTokenForModel(
          thinkingMode: ThinkingMode.fast,
          configuredThinkingToken: ThinkingMode.fast.header,
          fileInfo: fileInfo,
        ),
        compactFastThinkingPrefix,
      );
      expect(
        thinkingTokenForModel(
          thinkingMode: ThinkingMode.fast,
          configuredThinkingToken: '<custom-fast>',
          fileInfo: fileInfo,
        ),
        '<custom-fast>',
      );
      expect(
        thinkingTokenForModel(
          thinkingMode: ThinkingMode.fastWithSpacePrefix,
          configuredThinkingToken: ThinkingMode.fastWithSpacePrefix.header,
          fileInfo: fileInfo,
        ),
        ThinkingMode.fastWithSpacePrefix.header,
      );
    });

    test('keeps the default Fast prefix for legacy models', () {
      final fileInfo = _fileInfo(
        name: 'RWKV7-G1g 1.5B',
        fileName: 'rwkv7-g1g-1.5b-20260526-Q6_K.gguf',
      );

      expect(
        thinkingTokenForModel(
          thinkingMode: ThinkingMode.fast,
          configuredThinkingToken: ThinkingMode.fast.header,
          fileInfo: fileInfo,
        ),
        ThinkingMode.fast.header,
      );
    });
  });
}

FileInfo _fileInfo({
  required String name,
  required String fileName,
  DateTime? date,
}) {
  return FileInfo(
    name: name,
    fileName: fileName,
    fileType: FileType.weights,
    fileSize: 1,
    raw: '/tmp/$fileName',
    isDebug: false,
    backend: null,
    sha256: null,
    modelSize: null,
    quantization: null,
    updatedAt: null,
    timestamp: date == null ? null : date.millisecondsSinceEpoch ~/ 1000,
    date: date,
  );
}
