import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zone/func/model_generation_catalog.dart';

Map<String, dynamic> model(
  String generation, {
  String backend = 'coreml',
  double size = 2.9,
  List<String> platforms = const ['ios', 'macos'],
  List<String>? socs,
  String variant = '',
  bool debug = false,
  String quantization = 'W4',
}) => {
  'name': 'RWKV7-G1$generation ${size}B $variant',
  'modelSize': size,
  'backends': [backend],
  'platforms': platforms,
  'quantization': quantization,
  if (socs != null) 'socLimitations': socs,
  if (debug) 'isDebug': true,
};

void main() {
  test(
    'every bundled catalog contains only the latest covered generations',
    () {
      final root =
          Directory.current.path.endsWith('${Platform.pathSeparator}tools')
          ? Directory.current.parent
          : Directory.current;
      final files = Directory('${root.path}/remote')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      expect(files, isNotEmpty);
      for (final file in files) {
        final config =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(
          normalizeModelGenerationCatalog(config),
          config,
          reason: file.path,
        );
      }
    },
  );

  test(
    'all inference backends and operating systems retire older generations',
    () {
      for (final backend in [
        'coreml',
        'mlx',
        'qnn',
        'mtk_np9',
        'llamacpp',
        'webRwkv',
        'mnn',
        'ncnn',
        'custom',
      ]) {
        for (final platform in [
          'ios',
          'macos',
          'windows',
          'android',
          'linux',
          'web',
        ]) {
          final rows = [
            for (final generation in ['i', 'j', 'k'])
              model(generation, backend: backend, platforms: [platform]),
          ];
          expect(normalizeModelGenerationConsumers(rows), [rows.last]);
          expect(latestModelGenerations(rows, (row) => row), [rows.last]);
        }
      }
    },
  );

  test('precision does not retain an older generation', () {
    final rows = [
      model('j', quantization: 'Q4_K_M'),
      model('k', quantization: 'Q6_K'),
    ];
    expect(normalizeModelGenerationConsumers(rows), [rows.last]);
  });

  test('backend and size remain separate consumers', () {
    final rows = [
      model('j', backend: 'mlx'),
      model('k'),
      model('i', size: 1.5),
    ];
    expect(normalizeModelGenerationConsumers(rows), rows);
  });

  test('a newer chip package never removes unrelated chip coverage', () {
    final old = model(
      'j',
      backend: 'qnn',
      platforms: ['android'],
      socs: ['8 Gen 3', '8 Elite'],
    );
    final newest = model(
      'k',
      backend: 'qnn',
      platforms: ['android'],
      socs: ['8 Gen 3'],
    );
    final normalized = normalizeModelGenerationConsumers([old, newest]);
    expect(normalized.first['socLimitations'], ['8 Elite']);
    expect(normalized.last, newest);
    expect(old['socLimitations'], ['8 Gen 3', '8 Elite']);
  });

  test('new platform coverage trims only matching older platforms', () {
    final old = model(
      'h',
      backend: 'webRwkv',
      platforms: ['web', 'ios', 'macos'],
    );
    final newest = model('k', backend: 'webRwkv', platforms: ['ios', 'macos']);
    final normalized = normalizeModelGenerationConsumers([old, newest]);
    expect(normalized.first['platforms'], ['web']);
    expect(normalized.last, newest);
  });

  test('specialized families are not replaced by a general chat model', () {
    final rows = [
      model('c', variant: 'Translate'),
      model('', variant: 'Neko'),
      model('k'),
    ];
    expect(normalizeModelGenerationConsumers(rows), rows);
  });

  test('alphabetical series handles z to aa and numeric series changes', () {
    final rows = [model('z'), model('aa')];
    expect(normalizeModelGenerationConsumers(rows), [rows.last]);
    final olderSeries = {...model('z'), 'name': 'RWKV7-G0z 2.9B'};
    expect(normalizeModelGenerationConsumers([olderSeries, model('a')]), [
      model('a'),
    ]);
  });

  test('Debug-only candidates cannot remove a released catalog model', () {
    final formal = model('j');
    final debug = model('k', debug: true);
    expect(normalizeModelGenerationConsumers([formal, debug]), [formal, debug]);
    expect(latestModelGenerations([formal, debug], (row) => row), [debug]);
  });

  test(
    'dated vision revisions keep component roles and model sizes separate',
    () {
      Map<String, dynamic> vision(String date, String component, double size) =>
          {
            'name': 'RWKV-VL-$date ${size}B Vision $component',
            'backends': ['mnn'],
            'platforms': ['ios', 'macos'],
            'tags': [component.toLowerCase()],
          };
      final old = vision('260625', 'Encoder', 1.5);
      final adapter = vision('260625', 'Adapter', 1.5);
      final tiny = vision('260625', 'Encoder', 0.4);
      final newest = vision('260815', 'Encoder', 1.5);
      expect(normalizeModelGenerationConsumers([old, adapter, tiny, newest]), [
        adapter,
        tiny,
        newest,
      ]);
    },
  );

  test('a narrower brand exclusion cannot publish overlapping generations', () {
    final old = model('j');
    final newest = {
      ...model('k'),
      'unsupportedSocBrand': ['snapdragon'],
    };
    expect(
      () => normalizeModelGenerationConsumers([old, newest]),
      throwsStateError,
    );
  });

  test('a generic older package needs explicit remaining chip coverage', () {
    final old = model('j', platforms: ['android']);
    final newest = model('k', platforms: ['android'], socs: ['8 Gen 3']);
    expect(
      () => normalizeModelGenerationConsumers([old, newest]),
      throwsStateError,
    );
    expect(latestModelGenerations([old, newest], (row) => row), [newest]);
  });

  test(
    'all sections normalize independently and repeated normalization is stable',
    () {
      final config = <String, dynamic>{
        'configBuild': 763,
        for (final section in [
          'chat',
          'roleplay',
          'world',
          'tts',
          'othello',
          'sudoku',
        ])
          section: {
            'model_config': [model('i'), model('k')],
            'other': [null, 'kept'],
          },
      };
      final normalized = normalizeModelGenerationCatalog(config);
      for (final section in [
        'chat',
        'roleplay',
        'world',
        'tts',
        'othello',
        'sudoku',
      ]) {
        expect(normalized[section]['model_config'], [model('k')]);
        expect(normalized[section]['other'], [null, 'kept']);
      }
      expect(
        jsonEncode(normalizeModelGenerationCatalog(normalized)),
        jsonEncode(normalized),
      );
      expect(config['chat']['model_config'], hasLength(2));
    },
  );

  test(
    'unknown revisions are preserved and ordering remains deterministic',
    () {
      final unknown = {...model(''), 'name': 'Unversioned model'};
      final rows = [model('k'), unknown, model('i')];
      expect(latestModelGenerations(rows, (row) => row), [rows.first, unknown]);
      expect(catalogModelGeneration(unknown), isNull);
    },
  );
}
