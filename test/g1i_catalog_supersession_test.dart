import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('G1i replaces the equivalent G1h iOS WebRWKV slots', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    Map<String, dynamic> row(String name) => rows.singleWhere((entry) => entry['name'] == name);

    for (final size in ['1.5B', '2.9B']) {
      final g1i = row('RWKV7-G1i $size (WebRWKV)');
      expect(g1i['platforms'], containsAll(<String>['ios', 'macos', 'windows']));
      expect(g1i['isDebug'], isNull);
      expect(g1i['quantization'], 'NF4');
      expect(g1i['backends'], <String>['webRwkv']);
      expect(g1i['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
      expect(g1i['url'], isNot(startsWith('http://')));
      expect(g1i['url'], isNot(startsWith('https://')));
      expect(g1i['url'], contains('-g1i-'));
      expect(g1i['sha256'], isNotEmpty);

      final g1h = row('RWKV7-G1h $size (WebRWKV)');
      expect(g1h['platforms'], <String>['web']);
    }

    for (final size in ['7.2B', '13.3B']) {
      final g1i = row('RWKV7-G1i $size (WebRWKV)');
      expect(g1i['platforms'], isNot(contains('ios')));
    }
  });

  test('G1i replaces the equivalent G1g 7.2B 8 Gen 3 QNN slot', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    final g1i = rows.singleWhere((entry) => entry['name'] == 'RWKV7-G1i 7.2B (8 Gen 3)');
    expect(g1i['modelSize'], 7.2);
    expect(g1i['quantization'], 'w4a16');
    expect(g1i['platforms'], <String>['android']);
    expect(g1i['backends'], <String>['qnn']);
    expect(g1i['tags'], containsAll(<String>['reason', 'npu']));
    expect(g1i['socLimitations'], <String>['8 Gen 3']);
    expect(g1i['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
    expect(g1i['sha256'], isNotEmpty);

    expect(
      rows.where((entry) => entry['name'] == 'RWKV7-G1g 7.2B (8 Gen 3)'),
      isEmpty,
    );
  });
}
