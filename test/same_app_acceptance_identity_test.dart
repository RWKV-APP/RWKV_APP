import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App acceptance keeps the canonical identity and has no hidden model runner', () {
    final buildGradle = File('android/app/build.gradle').readAsStringSync();
    final mainManifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final debugManifest = File('android/app/src/debug/AndroidManifest.xml').readAsStringSync();
    final mainDart = File('lib/main.dart').readAsStringSync();
    final argsDart = File('lib/args.dart').readAsStringSync();
    final storeDart = File('lib/store/p.dart').readAsStringSync();

    expect(buildGradle, contains('applicationId = "com.rwkvzone.chat"'));
    expect(buildGradle, isNot(contains('applicationIdSuffix')));
    expect(mainManifest, contains('android:label="RWKV Chat"'));
    expect(debugManifest, isNot(contains('<application')));
    expect(debugManifest, isNot(contains('RWKV Chat Debug')));
    expect(File('lib/store/modelscope_debug_acceptance.dart').existsSync(), isFalse);
    expect(mainDart, isNot(contains('runModelScopeDebugAcceptance')));
    expect(argsDart, isNot(contains('modelScopeDebugAcceptance')));
    expect(storeDart, isNot(contains('modelscope_debug_acceptance')));
  });
}
