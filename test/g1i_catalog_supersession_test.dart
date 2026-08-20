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
    const appleBackends = <String>{'llamacpp', 'webRwkv', 'mlx'};
    final appleRows = g1iRows.where((entry) => appleBackends.contains((entry['backends'] as List<dynamic>).single)).toList();
    final mobileAppleRows = appleRows.where((entry) => entry['modelSize'] != 13.3).toList();
    final macOnly13bRows = appleRows.where((entry) => entry['modelSize'] == 13.3).toList();

    expect(g1iRows, hasLength(42));
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

  test('G1i replaces the equivalent G1g 7.2B Snapdragon QNN slots', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    for (final soc in <String>['8 Gen 3', '8s Gen 3']) {
      final g1i = rows.singleWhere((entry) => entry['name'] == 'RWKV7-G1i 7.2B ($soc)');
      expect(g1i['modelSize'], 7.2);
      expect(g1i['quantization'], 'w4a16');
      expect(g1i['platforms'], <String>['android']);
      expect(g1i['backends'], <String>['qnn']);
      expect(g1i['tags'], containsAll(<String>['reason', 'npu']));
      expect(g1i['socLimitations'], <String>[soc]);
      expect(g1i['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
      expect(g1i['sha256'], isNotEmpty);

      expect(
        rows.where((entry) => entry['name'] == 'RWKV7-G1g 7.2B ($soc)'),
        isEmpty,
      );
    }
  });

  test('G1i replaces equivalent G1h QNN slots supported by the current Android engine', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    const expectedRows = <String, Map<String, Object>>{
      'RWKV7-G1i 1.5B (8 Elite Gen5)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '8 Elite Gen5'},
      'RWKV7-G1i 1.5B (8 Gen 5)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '8 Gen 5'},
      'RWKV7-G1i 1.5B (8 Elite)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '8 Elite'},
      'RWKV7-G1i 1.5B (8s Gen 3)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '8s Gen 3'},
      'RWKV7-G1i 1.5B (7+ Gen 3)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '7+ Gen 3'},
      'RWKV7-G1i 1.5B (8 Gen 2)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '8 Gen 2'},
      'RWKV7-G1i 1.5B (8+ Gen 1)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '8+ Gen 1'},
      'RWKV7-G1i 1.5B (888)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '888'},
      'RWKV7-G1i 1.5B (778)': {'modelSize': 1.5, 'quantization': 'w8a16', 'soc': '778'},
      'RWKV7-G1i 2.9B (8 Elite Gen5)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '8 Elite Gen5'},
      'RWKV7-G1i 2.9B (8 Gen 5)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '8 Gen 5'},
      'RWKV7-G1i 2.9B (8 Elite)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '8 Elite'},
      'RWKV7-G1i 2.9B (8s Gen 3)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '8s Gen 3'},
      'RWKV7-G1i 2.9B (7+ Gen 3)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '7+ Gen 3'},
      'RWKV7-G1i 2.9B (8 Gen 2)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '8 Gen 2'},
      'RWKV7-G1i 2.9B (8+ Gen 1)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '8+ Gen 1'},
      'RWKV7-G1i 2.9B (888)': {'modelSize': 2.9, 'quantization': 'w4a16', 'soc': '888'},
    };

    for (final entry in expectedRows.entries) {
      final row = rows.singleWhere((candidate) => candidate['name'] == entry.key);
      expect(row['modelSize'], entry.value['modelSize']);
      expect(row['quantization'], entry.value['quantization']);
      expect(row['platforms'], <String>['android']);
      expect(row['backends'], <String>['qnn']);
      expect(row['socLimitations'], <String>[entry.value['soc']! as String]);
      expect(row['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
      expect(row['sha256'], isNotEmpty);

      final replacedName = entry.key.replaceFirst('RWKV7-G1i', 'RWKV7-G1h');
      expect(rows.where((candidate) => candidate['name'] == replacedName), isEmpty);
    }
  });

  test('G1i replaces equivalent G1h Dimensity 9500 NP9 slots', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    const expectedRows = <String, Map<String, Object>>{
      'RWKV7-G1i 1.5B (Dimensity 9500)': {'modelSize': 1.5, 'quantization': 'w8a16'},
      'RWKV7-G1i 2.9B (Dimensity 9500)': {'modelSize': 2.9, 'quantization': 'w4a16'},
    };

    for (final entry in expectedRows.entries) {
      final row = rows.singleWhere((candidate) => candidate['name'] == entry.key);
      expect(row['modelSize'], entry.value['modelSize']);
      expect(row['quantization'], entry.value['quantization']);
      expect(row['platforms'], <String>['android']);
      expect(row['backends'], <String>['mtk_np9']);
      expect(row['tags'], containsAll(<String>['reason', 'npu', 'batch']));
      expect(row['socLimitations'], <String>['Dimensity 9500']);
      expect(row['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
      expect(row['url'], contains('/mtk_np9/'));
      expect(row['sha256'], isNotEmpty);

      final replacedName = entry.key.replaceFirst('RWKV7-G1i', 'RWKV7-G1h');
      expect(rows.where((candidate) => candidate['name'] == replacedName), isEmpty);
    }
  });

  test('G1i replaces the equivalent G1h Dimensity 9300 NP7 slot', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    final row = rows.singleWhere((candidate) => candidate['name'] == 'RWKV7-G1i 1.5B (Dimensity 9300)');
    expect(row['modelSize'], 1.5);
    expect(row['quantization'], 'w8a16');
    expect(row['platforms'], <String>['android']);
    expect(row['backends'], <String>['mtk_np7']);
    expect(row['tags'], containsAll(<String>['reason', 'npu']));
    expect(row['socLimitations'], <String>['Dimensity 9300']);
    expect(row['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
    expect(row['url'], contains('/mtk_np7/'));
    expect(
      row['url'],
      endsWith('rwkv7-g1i-1.5b-20260805-ctx16384-mt6989-np7-sdk7.0.8-ncc7.3.15-a16w8-prefill32.rmpack'),
    );
    expect(row['fileSize'], 1676345344);
    expect(row['sha256'], 'ddf7687ec5bea11ff3746e8e01390a5be97c80c3a02c0fe38c15c04d3861bf70');

    expect(
      rows.where((candidate) => candidate['name'] == 'RWKV7-G1h 1.5B (Dimensity 9300)'),
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

  test('G1i replaces equivalent G1h Snapdragon X Windows QNN slots', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    const expectedRows = <String, Map<String, Object>>{
      'RWKV7-G1i 1.5B (X Elite)': {
        'modelSize': 1.5,
        'quantization': 'w8a16',
        'socs': <String>['X Elite', 'X Plus', 'X1'],
      },
      'RWKV7-G1i 1.5B (X2 Elite)': {
        'modelSize': 1.5,
        'quantization': 'w8a16',
        'socs': <String>['X2 Elite Extreme', 'X2 Elite', 'X2 Plus'],
      },
      'RWKV7-G1i 2.9B (X Elite)': {
        'modelSize': 2.9,
        'quantization': 'w4a16',
        'socs': <String>['X Elite', 'X Plus', 'X1'],
      },
      'RWKV7-G1i 2.9B (X2 Elite)': {
        'modelSize': 2.9,
        'quantization': 'w4a16',
        'socs': <String>['X2 Elite Extreme', 'X2 Elite', 'X2 Plus'],
      },
    };

    for (final entry in expectedRows.entries) {
      final row = rows.singleWhere((candidate) => candidate['name'] == entry.key);
      expect(row['modelSize'], entry.value['modelSize']);
      expect(row['quantization'], entry.value['quantization']);
      expect(row['platforms'], <String>['windows']);
      expect(row['backends'], <String>['qnn']);
      expect(row['tags'], containsAll(<String>['reason', 'npu', 'batch']));
      expect(row['socLimitations'], entry.value['socs']);
      expect(row['url'], startsWith('HaloWang/rwkv-weights/resolve/main/'));
      expect(row['url'], contains('-requant-20260814.rmpack'));
      expect(row['sha256'], isNotEmpty);

      final replacedName = entry.key.replaceFirst('RWKV7-G1i', 'RWKV7-G1h');
      expect(rows.where((candidate) => candidate['name'] == replacedName), isEmpty);
    }
  });

  test('G1i 7.2B Snapdragon X rows use the formal dual-repository path', () {
    final json = jsonDecode(File('remote/latest.json').readAsStringSync()) as Map<String, dynamic>;
    final chat = json['chat'] as Map<String, dynamic>;
    final rows = (chat['model_config'] as List<dynamic>).cast<Map<String, dynamic>>();

    const expectedRows = <String, Map<String, Object>>{
      'RWKV7-G1i 7.2B (X Elite)': {
        'fileSize': 4867481600,
        'sha256': '9eb4d1e191bacb3a2998412ac4d4dbac4ec8199c15a4e9f4372635608ea95c0d',
        'socs': <String>['X Elite', 'X Plus', 'X1'],
      },
      'RWKV7-G1i 7.2B (X2 Elite)': {
        'fileSize': 4887171072,
        'sha256': '9883f708d5c9675eb672de278a27ca588153ec61b39061ab2df88804f92f6549',
        'socs': <String>['X2 Elite Extreme', 'X2 Elite', 'X2 Plus'],
      },
    };

    for (final entry in expectedRows.entries) {
      final row = rows.singleWhere((candidate) => candidate['name'] == entry.key);
      expect(row['modelSize'], 7.2);
      expect(row['quantization'], 'w4a16');
      expect(row['platforms'], <String>['windows']);
      expect(row['backends'], <String>['qnn']);
      expect(row['tags'], containsAll(<String>['reason', 'npu', 'batch']));
      expect(row['availableIn'], isNull);
      expect(row['socLimitations'], entry.value['socs']);
      expect(
        row['url'],
        startsWith('HaloWang/rwkv-weights/resolve/main/artifacts/'),
      );
      expect(row['url'], isNot(contains('rwkv-weights-tmp')));
      expect(row['fileSize'], entry.value['fileSize']);
      expect(row['sha256'], entry.value['sha256']);
    }
  });
}
