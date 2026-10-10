import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/file_download_source.dart';
import 'package:zone/model/file_info.dart';

void main() {
  test('current release maps each frozen formal artifact to compatible catalog consumers', () {
    final release = jsonDecode(File('release.json').readAsStringSync()) as Map<String, dynamic>;
    final weights = release['weights'] as Map<String, dynamic>;
    final artifacts = (weights['artifacts'] as List<dynamic>).cast<Map<String, dynamic>>();
    final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final rows = ((config['chat'] as Map<String, dynamic>)['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
    final snapshot = jsonDecode(File('remote/${release['build']}.json').readAsStringSync());
    expect(config['configBuild'], release['build']);
    expect(snapshot, config);
    expect(artifacts, hasLength(weights['artifactCount'] as int));
    expect(artifacts.map((row) => row['sha256']).toSet(), hasLength(artifacts.length));
    expect(rows.where((row) => (row['platforms'] as List<dynamic>).isEmpty), isEmpty);
    for (final artifact in artifacts) {
      final consumers = rows.where((row) => row['sha256'] == artifact['sha256']).toList();
      expect(consumers, isNotEmpty);
      for (final row in consumers) {
        final file = FileInfo.fromJSON(row);
        expect(file.fileName, artifact['filename']);
        expect(file.fileSize, artifact['fileSize']);
        expect(file.modelSize, artifact['modelSize']);
        expect(file.quantization, artifact['quantization']);
        expect(file.supportedPlatforms, artifact['platforms']);
        expect((row['backends'] as List<dynamic>).single.toString().toLowerCase(), artifact['backend']);
        expect(file.isDebug, isFalse);
        expect(file.availableIn, [FileDownloadSource.modelscope, FileDownloadSource.huggingface]);
        final distribution = artifact['distribution'] as Map<String, dynamic>;
        final mirror = (artifact['mirrors'] as Map<String, dynamic>)['huggingface'] as Map<String, dynamic>;
        expect(distribution['stage'], 'formal');
        expect(mirror['stage'], 'formal');
        expect(distribution['revision'], matches(RegExp(r'^[0-9a-f]{40}$')));
        expect(mirror['revision'], matches(RegExp(r'^[0-9a-f]{40}$')));
        expect(mirror['path'], distribution['path']);
        expect(row['url'], 'HaloWang/rwkv-weights/resolve/main/${distribution['path']}');
        expect(FileDownloadSource.modelscope.resolveUrl(row['url'] as String),
            'https://modelscope.cn/models/HaloWang1991/rwkv-weights/resolve/master/${distribution['path']}');
      }
    }
  });

  test('historical build 755 retains its complete G1j cohort', () {
    final config = jsonDecode(File('remote/755.json').readAsStringSync()) as Map<String, dynamic>;
    final rows = ((config['chat'] as Map<String, dynamic>)['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
    final g1j = rows.where((row) => (row['url'] as String).contains('-g1j-')).toList();
    expect(config['configBuild'], 755);
    expect(g1j, hasLength(47));
    expect(g1j.map((row) => row['sha256']).toSet(), hasLength(45));
    expect(rows.where((row) => (row['platforms'] as List<dynamic>).isEmpty), isEmpty);
  });

  test('G1k release accounts for every MLX size and removes each superseded consumer', () {
    final release = jsonDecode(File('release.json').readAsStringSync()) as Map<String, dynamic>;
    final weights = release['weights'] as Map<String, dynamic>;
    final artifacts = (weights['artifacts'] as List<dynamic>).cast<Map<String, dynamic>>();
    final pending = (weights['pendingArtifacts'] as List<dynamic>? ?? <dynamic>[]).cast<Map<String, dynamic>>();
    final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final rows = ((config['chat'] as Map<String, dynamic>)['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
    final publishedMlx = artifacts.where((row) => row['backend'] == 'mlx').toList();
    final pendingMlx = pending.where((row) => row['backend'] == 'mlx').toList();
    expect([...publishedMlx, ...pendingMlx].map((row) => row['modelSize']), unorderedEquals([1.5, 2.9, 7.2, 13.3]));
    expect(weights['requiredArtifactCount'], 40);
    expect(artifacts.length + pending.length, weights['requiredArtifactCount']);
    expect(weights['releaseMode'] == 'complete_release', pending.isEmpty);
    for (final artifact in publishedMlx) {
      final size = artifact['modelSize'];
      final consumers = rows.where((row) => row['sha256'] == artifact['sha256']).toList();
      expect(consumers, hasLength(1));
      expect(consumers.single['name'], 'RWKV7-G1k ${size}B (MLX)');
      expect(consumers.single['platforms'], size == 13.3 ? ['macos'] : ['macos', 'ios']);
      expect(rows.where((row) => row['modelSize'] == size &&
          (row['backends'] as List<dynamic>).contains('mlx') &&
          RegExp(r'G1[ij]', caseSensitive: false).hasMatch(row['name'] as String)), isEmpty);
    }
    final tinyMlx = rows.where((row) => (row['backends'] as List<dynamic>).contains('mlx') &&
        [0.1, 0.4].contains(row['modelSize'])).toList();
    expect(tinyMlx.map((row) => row['modelSize']), unorderedEquals([0.1, 0.4]));
  });
}
