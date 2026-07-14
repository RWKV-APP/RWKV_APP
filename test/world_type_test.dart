// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/file_info.dart';
import 'package:zone/model/world_type.dart';

void main() {
  test('keeps the latest JSON RWKV-VL 8 Gen 5 model registered for display', () {
    final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final world = config['world'] as Map<String, dynamic>;
    final modelConfigs = (world['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
    final modelConfig = modelConfigs.singleWhere((entry) {
      final name = entry['name'];
      if (name is! String || !name.contains('RWKV-VL')) return false;

      final socLimitations = entry['socLimitations'];
      if (socLimitations is! List<dynamic>) return false;

      return socLimitations.contains('8 Gen 5');
    });
    final fileInfo = FileInfo.fromJSON(modelConfig);

    expect(fileInfo.worldType, WorldType.modrwkvV3);
    expect(WorldType.modrwkvV3.socPairs, contains(('8 Gen 5', fileInfo.fileName)));
  });
}
