import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stale server fallback cannot replace the release catalog', () {
    final previous = P.app.buildNumber.q;
    addTearDown(() => P.app.buildNumber.q = previous);
    P.app.buildNumber.q = '755';
    expect(P.app.acceptsConfig({'configBuild': 755}), isTrue);
    for (final value in [null, 754, 756, '755', 755.0]) {
      expect(P.app.acceptsConfig({'configBuild': value}), isFalse);
    }
    final catalog = jsonDecode(File('remote/755.json').readAsStringSync()) as Map<String, dynamic>;
    expect(P.app.acceptsConfig(catalog), isTrue);
    final models = (catalog['chat']['model_config'] as List).where((dynamic row) => (row['url'] as String).contains('g1j'));
    expect(models.length, 22);
    for (final row in models) {
      expect(row['modelSize'], anyOf(1.5, 2.9));
      expect(row['availableIn'], ['modelscope']);
      expect(row['backends'].toString(), isNot(contains('mtk')));
      final isQnnCanary = row['backends'].contains('qnn') && row['modelSize'] == 2.9;
      if (isQnnCanary) {
        expect(row['quantization'], 'W8');
        expect(row['url'], contains('/rwkv-weights-tmp/resolve/5b9edcb13b27c28376a89ecfb94b7d3c57424698/'));
      } else {
        expect(row['url'], matches(r'^https://modelscope.cn/models/HaloWang1991/rwkv-weights/resolve/[a-f0-9]{40}/'));
      }
    }
    final palm = models.where((dynamic row) => row['backends'].contains('palm')).toList();
    expect(palm.length, 2);
    expect(palm.map((dynamic row) => row['quantization']), everyElement('W8'));
    expect(palm.map((dynamic row) => row['sha256']).toSet(), {
      '309233828ec88b9ff406d66db2f4e1e37fa846330f96cb9f0639d2047fae57f5',
      '4dac69c1edc3ed66bcbb8eae20cab11669af6f42dbd6f86ef0b6d3a5f0c84ba7',
    });
    final legacy = jsonDecode(File('remote/754.json').readAsStringSync());
    expect(legacy.toString(), isNot(contains('palm')));
  });
}
