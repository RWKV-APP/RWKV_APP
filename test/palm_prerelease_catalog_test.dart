import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/file_download_source.dart';

void main() {
  test('large PALM G1J TMP entries preserve immutable identities and platform exclusions', () {
    final config = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final rows = ((config['chat'] as Map<String, dynamic>)['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();
    final largePalm = rows
        .where(
          (row) =>
              (row['url'] as String).contains('-g1j-') &&
              (row['backends'] as List<dynamic>).contains('palm') &&
              [7.2, 13.3].contains(row['modelSize']),
        )
        .toList();
    expect(largePalm, hasLength(2));
    expect(largePalm.map((row) => row['modelSize']).toSet(), {7.2, 13.3});
    final identities = {
      7.2: (4472681412, 'b2c5d8ac261f82ddeb9f02050d1c0dfca3051190b3343a2225b8d1e46da23b72'),
      13.3: (7821527428, '988de80e1cac2a7e3ba43bebeb303706dd96fef33d683bdcfa6ad236029ee438'),
    };
    for (final row in largePalm) {
      final size = row['modelSize'] as num;
      final identity = identities[size]!;
      final url = row['url'] as String;
      final fileName = Uri.parse(url).pathSegments.last;
      expect(row['backends'], ['palm']);
      expect(row['quantization'], 'W4');
      expect(row['platforms'], unorderedEquals(['windows', 'linux', 'macos', if (size == 7.2) 'android']));
      expect(row['fileSize'], identity.$1);
      expect(row['sha256'], identity.$2);
      expect(row['availableIn'], ['modelscope']);
      expect(row['isDebug'] ?? false, isFalse);
      expect(
        url,
        matches(RegExp(r'^https://modelscope\.cn/models/HaloWang1991/rwkv-weights-tmp/resolve/[0-9a-f]{40}/artifacts/rwkv7/chat/')),
      );
      expect(url.endsWith('/${size}b/palm/${fileName}'), isTrue);
      expect(fileName, 'rwkv7-g1j-${size}b-20260831-ctx16384-w4mixg128-bg128-r20260917-ctx256.mollm');
      expect(FileDownloadSource.modelscope.resolveUrl(url), url);
    }
  });
}
