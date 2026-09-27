import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stale server fallback cannot replace the release catalog', () {
    final release = jsonDecode(File('release.json').readAsStringSync()) as Map<String, dynamic>;
    final bundled = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    expect(bundled['configBuild'], release['build']);
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
    expect(models.length, 47);
    for (final row in models) {
      expect(row['modelSize'], anyOf(1.5, 2.9, 7.2, 13.3));
      expect(row['availableIn'], ['modelscope', 'huggingface']);
      expect(row['url'], startsWith('HaloWang/rwkv-weights/resolve/main/artifacts/'));
    }
    final palm = models.where((dynamic row) => row['backends'].contains('palm')).toList();
    expect(palm.length, 2);
    expect(palm.map((dynamic row) => row['quantization']), everyElement('W4'));
    expect(palm.map((dynamic row) => row['sha256']).toSet(), {
      '5f5098e57ac18004d449c93b086d72559292d533e98308b86fb769308e898939',
      '2d6b7e07ca9339d4433581ab7cd7d12eb9c3a70c54de1219add7e15ab928ebb7',
    });
    final legacy = jsonDecode(File('remote/754.json').readAsStringSync());
    expect(legacy.toString(), isNot(contains('palm')));
  });
}
