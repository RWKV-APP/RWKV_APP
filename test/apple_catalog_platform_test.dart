import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogs use real Apple platform names and never macos_debug', () {
    final catalogFiles = Directory('remote').listSync().whereType<File>().where((file) => file.path.endsWith('.json')).toList();

    expect(catalogFiles, isNotEmpty);
    for (final file in catalogFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('macos_debug')), reason: file.path);
      jsonDecode(source);
    }

    final fileInfoSource = File('lib/model/file_info.dart').readAsStringSync();
    expect(fileInfoSource, isNot(contains('macos_debug')));
  });
}
