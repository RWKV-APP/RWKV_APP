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
    expect(models.length, 31);
    for (final row in models) {
      expect(row['modelSize'], anyOf(1.5, 2.9));
      expect(row['availableIn'], ['modelscope']);
      expect(row['backends'].toString(), isNot(contains('mtk')));
      expect(row['url'], contains('/rwkv-weights/resolve/45a3a40322397e470a937d16b24aec5895bb6a8e/'));
    }
    final legacy = jsonDecode(File('remote/754.json').readAsStringSync());
    expect(legacy.toString(), isNot(contains('palm')));
  });
}
