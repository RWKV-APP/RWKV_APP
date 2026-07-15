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
      return url is String && url.contains('rwkv-vl-1.5v100m-finevisionmax-');
    });

    expect(legacyFiles, hasLength(13));
    expect(fineVisionMaxFiles, hasLength(13));
    for (final modelConfig in fineVisionMaxFiles) {
      expect(FileInfo.fromJSON(modelConfig).worldType, WorldType.fineVisionMax);
    }
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

    for (final worldType in [WorldType.modrwkvV3, WorldType.fineVisionMax]) {
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
      return url is String && url.contains('rwkv-vl-1.5v100m-finevisionmax-') && tags is List<dynamic> && tags.contains('encoder');
    });
    final legacyConfig = <String, dynamic>{
      'name': 'Legacy RWKV-VL',
      'url': 'mollysama/rwkv-mobile-models/resolve/main/rwkv-vl-0.4B-260625-q8_0.gguf',
      'fileSize': 1,
      'platforms': ['macos'],
      'backends': ['llamacpp'],
    };

    expect(FileInfo.fromJSON(coreConfig).usesFlowerTemplate, isTrue);
    expect(FileInfo.fromJSON(encoderConfig).usesFlowerTemplate, isFalse);
    expect(FileInfo.fromJSON(legacyConfig).usesFlowerTemplate, isFalse);
  });
}
