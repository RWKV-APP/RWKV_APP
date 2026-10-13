import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zone/func/local_model_discovery.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('coreai-discovery-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<Directory> package(String name, {Map<String, Object?> overrides = const {}}) async {
    final directory = Directory(p.join(root.path, name));
    await Directory(p.join(directory.path, 'rwkv.aimodel')).create(recursive: true);
    await File(p.join(directory.path, 'rwkv.aimodel', 'main.mlirb')).writeAsBytes([1, 2, 3]);
    await File(p.join(directory.path, 'config.json')).writeAsString(
      jsonEncode({
        'format_version': 1,
        'backend': 'coreai',
        'model_version': 7,
        'precision': 'float16',
        'model_file': 'rwkv.aimodel',
        ...overrides,
      }),
    );
    return directory;
  }

  test('Core AI discovery is opt-in and accepts a model or its parent folder', () async {
    final model = await package('model');
    await File(p.join(root.path, 'existing.pth')).writeAsBytes([1]);
    final ordinary = await discoverLocalModelFiles(root.path);
    expect(ordinary.files.map((file) => file.kind), [LocalModelFileKind.pth]);
    final parent = await discoverLocalModelFiles(root.path, includeCoreAI: true);
    expect(parent.files.where((file) => file.kind == LocalModelFileKind.coreai).single.path, model.path);
    final direct = await discoverLocalModelFiles(model.path, includeCoreAI: true);
    expect(direct.files.single.coreAIPrecision, 'FP16');
    expect(direct.files.single.fileSize, 3);
  });

  test('weight compression is distinguished from computation and state precision', () async {
    for (final bits in [4, 8]) {
      final model = await package(
        'w$bits',
        overrides: {
          'precision': 'float32',
          'activation_precision': 'float32',
          'state_precision': 'float32',
          'quantization': 'w$bits',
          'quantization_scheme': 'symmetric',
          'quantization_group_size': 32,
        },
      );
      final result = await discoverLocalModelFiles(model.path, includeCoreAI: true);
      expect(result.files.single.coreAIPrecision, 'W${bits}A32 / S32 / g32');
    }
  });

  test('inconsistent quantization metadata is rejected', () async {
    final valid = <String, Object>{
      'precision': 'float32',
      'activation_precision': 'float32',
      'state_precision': 'float32',
      'quantization': 'w8',
      'quantization_scheme': 'symmetric',
      'quantization_group_size': 32,
    };
    final invalid = [
      {'quantization': 'w6'},
      {'quantization_group_size': 0},
      {'quantization_group_size': '32'},
      {'activation_precision': 'float16'},
      {'activation_precision': 'mixed_float16_float32', 'matmul_precision': 'float32'},
      {'state_precision': 'float16'},
      {'quantization_scheme': 'unknown'},
    ];
    for (final (index, override) in invalid.indexed) {
      final model = await package('invalid-$index', overrides: {...valid, ...override});
      expect((await discoverLocalModelFiles(model.path, includeCoreAI: true)).files, isEmpty);
    }
  });

  test('mixed matmuls retain an explicit FP32 state label', () async {
    final model = await package(
      'mixed',
      overrides: {
        'precision': 'float32',
        'activation_precision': 'mixed_float16_float32',
        'matmul_precision': 'float16',
        'state_precision': 'float32',
        'quantization': 'w8',
        'quantization_scheme': 'symmetric',
        'quantization_group_size': 32,
      },
    );
    final result = await discoverLocalModelFiles(model.path, includeCoreAI: true);
    expect(result.files.single.coreAIPrecision, 'W8A16/32 / S32 / g32');
  });

  test('LUT6 requires a codebook recipe and displays channel grouping', () async {
    final metadata = <String, Object>{
      'precision': 'float32',
      'activation_precision': 'mixed_float16_float32',
      'matmul_precision': 'float16',
      'state_precision': 'float32',
      'quantization': 'lut6',
      'quantization_scheme': 'kmeans_lut',
      'quantization_granularity': 'per_grouped_channel',
      'quantization_group_size': 32,
    };
    final model = await package('lut6', overrides: metadata);
    expect((await discoverLocalModelFiles(model.path, includeCoreAI: true)).files.single.coreAIPrecision, 'LUT6A16/32 / S32 / cg32');
    final mixedMetadata = {
      ...metadata,
      'quantization': 'lut6-w8',
      'integer_fallback': {'bits': 8, 'scheme': 'symmetric', 'group_size': 32},
      'lut_weight_num_threshold': 1048576,
    };
    final mixed = await package('lut6-w8', overrides: mixedMetadata);
    expect((await discoverLocalModelFiles(mixed.path, includeCoreAI: true)).files.single.coreAIPrecision, 'LUT6+W8A16/32 / S32 / cg32,g32');
    final badMixed = await package('bad-mixed', overrides: {...mixedMetadata, 'integer_fallback': null});
    expect((await discoverLocalModelFiles(badMixed.path, includeCoreAI: true)).files, isEmpty);
    final badThreshold = await package('bad-threshold', overrides: {...mixedMetadata, 'integer_prepass_weight_num_threshold': 512});
    expect((await discoverLocalModelFiles(badThreshold.path, includeCoreAI: true)).files, isEmpty);
    for (final (i, override) in [
      {'quantization_scheme': 'symmetric'},
      {'quantization_granularity': 'per_block'},
      {'quantization': 'w8'},
    ].indexed) {
      final invalid = await package('invalid-lut-$i', overrides: {...metadata, ...override});
      expect((await discoverLocalModelFiles(invalid.path, includeCoreAI: true)).files, isEmpty);
    }
  });

  test('W4+W8 labels require the declared integer mixture', () async {
    final metadata = <String, Object>{
      'precision': 'float32',
      'activation_precision': 'mixed_float16_float32',
      'matmul_precision': 'float16',
      'state_precision': 'float32',
      'quantization': 'w4-w8',
      'quantization_scheme': 'symmetric',
      'quantization_group_size': 32,
      'integer_fallback': {'bits': 8, 'scheme': 'symmetric', 'group_size': 32},
      'w4_weight_num_threshold': 8388608,
      'integer_prepass_weight_num_threshold': 67108864,
    };
    final model = await package('w4-w8', overrides: metadata);
    expect((await discoverLocalModelFiles(model.path, includeCoreAI: true)).files.single.coreAIPrecision, 'W4+W8A16/32 / S32 / g32,g32');
    final invalid = await package('bad-w4-w8', overrides: {...metadata, 'integer_fallback': null});
    expect((await discoverLocalModelFiles(invalid.path, includeCoreAI: true)).files, isEmpty);
  });

  test('incomplete, malformed and incompatible packages remain hidden', () async {
    final missing = await package('missing');
    await File(p.join(missing.path, 'rwkv.aimodel', 'main.mlirb')).delete();
    final malformed = await package('malformed');
    await File(p.join(malformed.path, 'config.json')).writeAsString('{');
    await package('wrong-version', overrides: {'model_version': 6});
    await package('wrong-format', overrides: {'format_version': 2});
    await package('wrong-backend', overrides: {'backend': 'mlx'});
    await package('wrong-precision', overrides: {'precision': 'int4'});
    await package('outside-package', overrides: {'model_file': '../rwkv.aimodel'});
    final result = await discoverLocalModelFiles(root.path, includeCoreAI: true);
    expect(result.files, isEmpty);
    expect(result.hasError, isFalse);
  });
}
