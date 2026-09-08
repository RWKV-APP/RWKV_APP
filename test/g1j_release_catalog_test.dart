import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/file_download_source.dart';
import 'package:zone/model/file_info.dart';

void main() {
  test('G1J catalog covers populated frozen targets and preserves consumer limits', () {
    final release = jsonDecode(File('release.json').readAsStringSync()) as Map<String, dynamic>;
    final weights = release['weights'] as Map<String, dynamic>;
    final artifacts = (weights['artifacts'] as List<dynamic>).cast<Map<String, dynamic>>();
    final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = config['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
    final g1j = rows.where((row) => (row['url'] as String).contains('-g1j-')).toList();
    final buildConfig = jsonDecode(File('remote/755.json').readAsStringSync()) as Map<String, dynamic>;
    final buildRows = ((buildConfig['chat'] as Map<String, dynamic>)['model_config'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((row) => (row['url'] as String).contains('-g1j-'))
        .toList();
    expect(buildRows, g1j);
    final distributed = artifacts.where((artifact) => artifact['distribution'] != null).toList();
    final pending = artifacts.where((artifact) => artifact['distribution'] == null).toList();
    final frozenByHash = {for (final artifact in artifacts) artifact['sha256'] as String: artifact};

    expect(config['configBuild'], release['build']);
    expect(weights['releaseMode'], 'partial_release');
    expect(weights['includedSizes'], ['1.5B', '2.9B', '7.2B', '13.3B']);
    expect(artifacts, hasLength(45));
    expect(frozenByHash, hasLength(45));
    expect(g1j, hasLength(weights['catalogRowCount'] as int));
    expect(g1j, hasLength(47));
    expect(g1j.map((row) => row['sha256']).toSet(), distributed.map((row) => row['sha256']).toSet());
    expect(distributed, hasLength(weights['catalogArtifactCount'] as int));
    expect(pending, isEmpty);
    expect(distributed, hasLength(45));
    expect((release['channels'] as Map<String, dynamic>)['huggingface'], isTrue);

    final consumerKeys = <String>{};
    for (final row in g1j) {
      final file = FileInfo.fromJSON(row);
      final artifact = frozenByHash[file.sha256]!;
      final distribution = artifact['distribution'] as Map<String, dynamic>;
      final backends = row['backends'] as List<dynamic>;
      final backend = (backends.single as String).toLowerCase();
      final url = row['url'] as String;
      expect(file.backend, isNotNull);
      expect(file.fileName, artifact['filename']);
      expect(file.fileSize, artifact['fileSize']);
      expect(file.modelSize, artifact['modelSize']);
      expect(file.quantization, artifact['quantization']);
      expect(file.supportedPlatforms, artifact['platforms']);
      expect(backend, artifact['backend']);
      expect(artifact['catalogNames'], contains(file.name));
      expect(file.availableIn, [FileDownloadSource.modelscope, FileDownloadSource.huggingface]);
      expect(file.isDebug, isFalse);
      expect(distribution['stage'], 'formal');
      expect(distribution['repository'], 'HaloWang1991/rwkv-weights');
      expect(distribution['revision'], matches(RegExp(r'^[0-9a-f]{40}$')));
      final mirror = (artifact['mirrors'] as Map<String, dynamic>)['huggingface'] as Map<String, dynamic>;
      expect(mirror['stage'], 'formal');
      expect(mirror['repository'], 'HaloWang/rwkv-weights');
      expect(mirror['revision'], matches(RegExp(r'^[0-9a-f]{40}$')));
      expect(mirror['path'], distribution['path']);
      expect(url, 'HaloWang/rwkv-weights/resolve/main/${distribution['path']}');
      expect(FileDownloadSource.huggingface.resolveUrl(url), 'https://huggingface.co/$url');
      expect(
        FileDownloadSource.modelscope.resolveUrl(url),
        'https://modelscope.cn/models/HaloWang1991/rwkv-weights/resolve/master/${distribution['path']}',
      );

      final quantization = switch (backend) {
        'palm' => 'W8',
        'llamacpp' => file.modelSize == 1.5 ? 'Q6_K' : 'Q4_K_M',
        'webrwkv' => 'NF4',
        'mlx' => 'W6',
        'coreml' => 'W4',
        'qnn' || 'mtk_np7' || 'mtk_np9' => file.modelSize == 1.5 ? 'W8' : 'W4',
        _ => throw StateError('Unexpected G1J backend: $backend'),
      };
      expect(file.quantization, quantization);
      final socs = file.socLimitations.isEmpty ? ['any'] : file.socLimitations;
      for (final platform in file.supportedPlatforms) {
        for (final soc in socs) {
          expect(consumerKeys.add('${file.modelSize}/$backend/$platform/$soc'), isTrue);
        }
      }
      if (file.modelSize == 13.3) {
        expect(file.supportedPlatforms, isNot(contains('ios')));
        expect(['llamacpp', 'webrwkv', 'mlx'], contains(backend));
      }
      if (backend == 'coreml' && file.modelSize == 7.2) {
        expect(file.supportedPlatforms, ['macos']);
      }
      if (backend == 'palm') expect([1.5, 2.9], contains(file.modelSize));
      if (backend.startsWith('mtk_')) expect([1.5, 2.9], contains(file.modelSize));
    }

    for (final size in [1.5, 2.9]) {
      final sharedRows = g1j.where((row) {
        final socs = (row['socLimitations'] as List<dynamic>?) ?? [];
        return row['modelSize'] == size && (socs.contains('8s Gen 3') || socs.contains('7+ Gen 3'));
      }).toList();
      expect(sharedRows, hasLength(2));
      expect(sharedRows.map((row) => row['sha256']).toSet(), hasLength(1));
    }
    for (final artifact in artifacts.where((row) => row['backend'] == 'qnn')) {
      final filename = artifact['filename'] as String;
      final socs = artifact['socLimitations'] as List<dynamic>;
      if (filename.contains('-xelite-')) expect(socs, containsAll(['X Elite', 'X Plus', 'X1']));
      if (filename.contains('-x2elite-')) expect(socs, containsAll(['X2 Elite Extreme', 'X2 Elite', 'X2 Plus']));
    }
  });
}
