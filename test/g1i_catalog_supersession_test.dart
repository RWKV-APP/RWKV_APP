import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current G1i Apple release excludes CoreML and keeps 13.3B off iOS', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    Map<String, dynamic> row(String name) => rows.singleWhere((entry) => entry['name'] == name);

    final g1iRows = rows.where((entry) => (entry['name'] as String).contains('RWKV7-G1i')).toList();
    final appleRows = g1iRows.where((entry) => (entry['backends'] as List<dynamic>).single != 'qnn').toList();
    final mobileAppleRows = appleRows.where((entry) => entry['modelSize'] != 13.3).toList();
    final macOnly13bRows = appleRows.where((entry) => entry['modelSize'] == 13.3).toList();

    expect(g1iRows, hasLength(15));
    expect(appleRows, hasLength(12));
    expect(mobileAppleRows, hasLength(9));
    expect(macOnly13bRows, hasLength(3));
    expect(
      g1iRows.where((entry) => (entry['backends'] as List<dynamic>).contains('coreml')),
      isEmpty,
    );
    for (final g1i in mobileAppleRows) {
      expect(g1i['platforms'], containsAll(<String>['macos', 'ios']));
    }
    for (final g1i in macOnly13bRows) {
      expect(g1i['platforms'], contains('macos'));
      expect(g1i['platforms'], isNot(contains('ios')));
    }
    for (final g1i in appleRows) {
      expect(g1i['platforms'], isNot(contains('macos_debug')));
      expect(g1i['isDebug'], isNull);
      expect(g1i['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
      expect(g1i['url'], isNot(startsWith('http://')));
      expect(g1i['url'], isNot(startsWith('https://')));
      expect(g1i['url'], contains('-g1i-'));
      expect(g1i['sha256'], isNotEmpty);
    }

    expect(row('RWKV7-G1h 1.5B (WebRWKV)')['platforms'], <String>['web']);
    expect(row('RWKV7-G1h 2.9B (WebRWKV)')['platforms'], <String>['web']);

    final g1fCoreMlRows = rows.where((entry) {
      final name = entry['name'] as String;
      final backends = (entry['backends'] as List<dynamic>?) ?? const <dynamic>[];
      return name.contains('RWKV7-G1f') && backends.contains('coreml');
    }).toList();
    expect(g1fCoreMlRows, hasLength(2));
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

  test('accepted G1i llama.cpp rows replace the equivalent Linux G1h slots', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    const expected = <({String name, double modelSize, String quantization, String sha256})>[
      (
        name: 'RWKV7-G1i 1.5B',
        modelSize: 1.5,
        quantization: 'Q6_K',
        sha256: '65ff6b972c74b1f2ec6860e43ec63d55a9488b49fe82e708a79849360f279c2f',
      ),
      (
        name: 'RWKV7-G1i 2.9B',
        modelSize: 2.9,
        quantization: 'Q4_K_M',
        sha256: 'f1e240ec025d8522cacf7edd01a7514b694dc80dfefd8b3bfdd69ced5456cb0f',
      ),
      (
        name: 'RWKV7-G1i 7.2B',
        modelSize: 7.2,
        quantization: 'Q4_K_M',
        sha256: '4fcbee4a0442cecb99662daeb936e7cdb0a0f90b3f276f24b14a2465c33b759a',
      ),
      (
        name: 'RWKV7-G1i 13.3B',
        modelSize: 13.3,
        quantization: 'Q4_K_M',
        sha256: '1f3fc76d83f6649b10df552526ab2c951d2ac7adec6d72bf8caef5291ad680d3',
      ),
    ];

    for (final item in expected) {
      final g1i = rows.singleWhere((entry) => entry['name'] == item.name);
      expect(g1i['modelSize'], item.modelSize);
      expect(g1i['quantization'], item.quantization);
      expect(g1i['platforms'], contains('linux'));
      expect(g1i['backends'], <String>['llamacpp']);
      expect(g1i['sha256'], item.sha256);
      expect(
        rows.where((entry) => entry['name'] == item.name.replaceFirst('G1i', 'G1h')),
        isEmpty,
      );
    }
  });
}
