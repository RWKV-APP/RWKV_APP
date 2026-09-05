import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Palm visibility follows the installed runtime capability', () {
    final model = FileInfo.fromJSON({
      'name': 'Palm capability check',
      'url': 'https://modelscope.cn/models/example/weights/resolve/0123456789012345678901234567890123456789/model.mollm',
      'fileSize': 1,
      'platforms': [Platform.operatingSystem],
      'backends': ['palm'],
    });
    final previous = P.rwkvBackend.availableBackendNames.q;
    addTearDown(() => P.rwkvBackend.availableBackendNames.q = previous);
    P.rwkvBackend.availableBackendNames.q = {'llama.cpp'};
    expect(model.available, isFalse);
    P.rwkvBackend.availableBackendNames.q = {'llama.cpp', 'palm'};
    expect(model.available, isTrue);
    P.rwkvBackend.availableBackendNames.q = {};
    expect(model.available, isFalse);
  });
}
