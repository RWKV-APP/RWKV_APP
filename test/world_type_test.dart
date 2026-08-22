// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/file_info.dart';
import 'package:zone/model/world_type.dart';

void main() {
  final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
  final world = config['world'] as Map<String, dynamic>;
  final modelConfigs = (world['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

  test('keeps both RWKV-VL generations in the latest JSON', () {
    final legacyFiles = modelConfigs.where((entry) {
      final url = entry['url'];
      return url is String && url.contains('rwkv-vl-0.4B-260625');
    });
    final fineVisionMaxFiles = modelConfigs.where((entry) {
      final url = entry['url'];
      return url is String && url.contains('rwkv-vl-1.5v100m-finevisionmax-') && !url.contains('thinking-preview-260815');
    });

    expect(legacyFiles, hasLength(13));
    expect(fineVisionMaxFiles, hasLength(13));
    for (final modelConfig in fineVisionMaxFiles) {
      expect(FileInfo.fromJSON(modelConfig).worldType, WorldType.fineVisionMax);
    }
  });

  test('publishes Thinking Preview with the RWKV-VL 260625 support matrix', () {
    final previewConfigs = modelConfigs.where((entry) {
      final url = entry['url'];
      return url is String && url.contains('rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-');
    }).toList();
    final previewFiles = previewConfigs.map(FileInfo.fromJSON).toList();
    const expectedPlatforms = {'macos', 'linux', 'android', 'ios', 'windows'};
    final expectedSpecialized = [
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-8elite.rmpack',
        platform: 'android',
        backend: 'qnn',
        socs: ['8 Elite'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-8elitegen5.rmpack',
        platform: 'android',
        backend: 'qnn',
        socs: ['8 Elite Gen5'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-8gen5.rmpack',
        platform: 'android',
        backend: 'qnn',
        socs: ['8 Gen 5'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-8gen2.rmpack',
        platform: 'android',
        backend: 'qnn',
        socs: ['8 Gen 2'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-8gen3.rmpack',
        platform: 'android',
        backend: 'qnn',
        socs: ['8 Gen 3'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-8sgen3.rmpack',
        platform: 'android',
        backend: 'qnn',
        socs: ['8s Gen 3'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-xelite-nocustomop.rmpack',
        platform: 'windows',
        backend: 'qnn',
        socs: ['X Elite', 'X Plus', 'X1'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-x2elite-nocustomop.rmpack',
        platform: 'windows',
        backend: 'qnn',
        socs: ['X2 Elite Extreme', 'X2 Elite', 'X2 Plus'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-MT6989.rmpack',
        platform: 'android',
        backend: 'mtk_np7',
        socs: ['Dimensity 9300'],
      ),
      (
        fileName: 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-mt6993-np9-sdk9.0.10-a16w8-prefill16-batch.rmpack',
        platform: 'android',
        backend: 'mtk_np9',
        socs: ['Dimensity 9500'],
      ),
    ];

    expect(previewConfigs, hasLength(13));
    expect(
      previewConfigs.every((config) {
        final url = config['url'];
        return url is String &&
            url.startsWith('HaloWang/rwkv-weights/resolve/main/') &&
            !url.startsWith('http://') &&
            !url.startsWith('https://');
      }),
      isTrue,
    );
    expect(previewConfigs.every((config) => !config.containsKey('isDebug')), isTrue);
    expect(
      previewConfigs.every((config) => config['sha256'] is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(config['sha256'] as String)),
      isTrue,
    );
    expect(previewFiles.every((file) => file.worldType == WorldType.fineVisionMaxThinkingPreview), isTrue);
    expect(previewFiles.where((file) => file.isEncoder), hasLength(1));
    expect(previewFiles.where((file) => file.isAdapter), hasLength(1));
    expect(previewFiles.where((file) => !file.isEncoder && !file.isAdapter), hasLength(11));

    final genericFiles = previewFiles.where((file) => file.backend?.name == 'mnn' || file.backend?.name == 'llamacpp').toList();
    expect(genericFiles, hasLength(3));
    expect(genericFiles.every((file) => file.supportedPlatforms.toSet().containsAll(expectedPlatforms)), isTrue);
    expect(genericFiles.every((file) => file.socLimitations.isEmpty), isTrue);

    for (final expected in expectedSpecialized) {
      final config = previewConfigs.singleWhere((entry) => (entry['url'] as String).endsWith(expected.fileName));
      expect(config['platforms'], [expected.platform]);
      expect(config['backends'], [expected.backend]);
      expect(config['socLimitations'], expected.socs);
      expect(config['tags'], containsAll(['npu', 'core', 'thinking']));
      expect(config['quantization'], 'W8');
    }

    expect(previewFiles.every((file) => !file.isDebug), isTrue);
    expect(WorldType.fineVisionMaxThinkingPreview.socPairs, hasLength(15));
    expect(
      WorldType.fineVisionMaxThinkingPreview.socPairs,
      contains(('X Plus', 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-xelite-nocustomop.rmpack')),
    );
    expect(
      WorldType.fineVisionMaxThinkingPreview.socPairs,
      contains(('X2 Elite Extreme', 'rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-rwkv-a16w8-x2elite-nocustomop.rmpack')),
    );
    expect(
      WorldType.fineVisionMaxThinkingPreview.socPairs,
      contains(('Dimensity 9500', expectedSpecialized.last.fileName)),
    );
  });

  test('registers both 8 Gen 5 core weights for display', () {
    final legacyConfig = modelConfigs.singleWhere((entry) {
      final url = entry['url'];
      return url is String && url.endsWith('rwkv-vl-0.4B-260625-a16w8-8gen5.rmpack');
    });
    final fineVisionMaxConfig = modelConfigs.singleWhere((entry) {
      final url = entry['url'];
      return url is String && url.endsWith('rwkv-vl-1.5v100m-finevisionmax-rwkv-a16w8-8gen5.rmpack');
    });
    final legacyFileInfo = FileInfo.fromJSON(legacyConfig);
    final fineVisionMaxFileInfo = FileInfo.fromJSON(fineVisionMaxConfig);

    expect(WorldType.modrwkvV3.socPairs, contains(('8 Gen 5', legacyFileInfo.fileName)));
    expect(WorldType.fineVisionMax.socPairs, contains(('8 Gen 5', fineVisionMaxFileInfo.fileName)));
  });

  test('keeps RWKV-VL dependency groups separate', () {
    final fileInfos = modelConfigs.map(FileInfo.fromJSON);

    for (final worldType in [
      WorldType.modrwkvV3,
      WorldType.fineVisionMax,
      WorldType.fineVisionMaxThinkingPreview,
    ]) {
      final group = fileInfos.where((fileInfo) => fileInfo.worldType == worldType);
      expect(group.where((fileInfo) => fileInfo.isEncoder), hasLength(1));
      expect(group.where((fileInfo) => fileInfo.isAdapter), hasLength(1));
    }
  });

  test('enables the flower template only for FineVisionMax core weights', () {
    final coreConfig = modelConfigs.singleWhere((entry) {
      final url = entry['url'];
      return url is String && url.endsWith('rwkv-vl-1.5v100m-finevisionmax-Q8_0.gguf');
    });
    final encoderConfig = modelConfigs.singleWhere((entry) {
      final url = entry['url'];
      final tags = entry['tags'];
      return url is String &&
          url.endsWith('rwkv-vl-1.5v100m-finevisionmax-vision-encoder.mnn') &&
          tags is List<dynamic> &&
          tags.contains('encoder');
    });
    final previewCoreConfig = modelConfigs.singleWhere((entry) {
      final url = entry['url'];
      return url is String && url.endsWith('rwkv-vl-1.5v100m-finevisionmax-thinking-preview-260815-Q8_0.gguf');
    });
    final legacyConfig = <String, dynamic>{
      'name': 'Legacy RWKV-VL',
      'url': 'mollysama/rwkv-mobile-models/resolve/main/rwkv-vl-0.4B-260625-q8_0.gguf',
      'fileSize': 1,
      'platforms': ['macos'],
      'backends': ['llamacpp'],
    };

    expect(FileInfo.fromJSON(coreConfig).usesFlowerTemplate, isTrue);
    expect(FileInfo.fromJSON(previewCoreConfig).usesFlowerTemplate, isTrue);
    expect(FileInfo.fromJSON(encoderConfig).usesFlowerTemplate, isFalse);
    expect(FileInfo.fromJSON(legacyConfig).usesFlowerTemplate, isFalse);
  });
}
