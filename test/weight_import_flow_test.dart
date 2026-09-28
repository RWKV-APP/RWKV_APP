import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/config.dart';
import 'package:zone/func/weight_import.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/folder.dart';
import 'package:zone/store/p.dart';

Uint8List _rwkvHeader() {
  final bytes = BytesBuilder();
  void u32(int value) => bytes.add((ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List());
  void u64(int value) => bytes.add((ByteData(8)..setUint64(0, value, Endian.little)).buffer.asUint8List());
  void string(String value) {
    final encoded = utf8.encode(value);
    u64(encoded.length);
    bytes.add(encoded);
  }

  bytes.add(ascii.encode('GGUF'));
  u32(3);
  u64(0);
  u64(1);
  string('general.architecture');
  u32(8);
  string('rwkv7');
  return bytes.takeBytes();
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (int i = 0; i < 500 && !ready(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('real import flow separates configuration, per-file consent, overwrite and batch failures', (tester) async {
    final root = await tester.runAsync(() => Directory.systemTemp.createTemp('weight-flow-'));
    final models = Directory(p.join(root!.path, Config.mobileModelsDirName));
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const picker = MethodChannel('miguelruivo.flutter.plugins.filepicker');
    final previousDocuments = P.app.documentsDir.q;
    P.app.documentsDir.q = root;
    addTearDown(() async {
      messenger.setMockMethodCallHandler(picker, null);
      messenger.setMockMessageHandler('flutter/assets', null);
      P.app.documentsDir.q = previousDocuments;
      P.remote.localGgufWeights.q = {};
      P.pth.folders.q = [];
      await root.delete(recursive: true);
    });
    await S.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    await expectLater(
      P.remote.importWeightFile(fileBytes: _rwkvHeader(), fileName: 'unknown.gguf', allowUncataloguedGguf: true),
      throwsA(WeightImportFailure.configurationNotLoaded),
    );

    final config = <String, dynamic>{
      'configBuild': 1,
      for (final kind in ['chat', 'tts', 'world', 'sudoku', 'othello', 'roleplay']) kind: {'model_config': <dynamic>[]},
    };
    config['chat']['model_config'].add({
      'name': 'Known',
      'url': 'https://example.com/known.bin',
      'fileSize': 2,
      'platforms': [Platform.operatingSystem],
    });
    config['roleplay']['model_config'].add({
      'name': 'Catalogued on another platform',
      'url': 'https://example.com/catalogued.gguf',
      'fileSize': _rwkvHeader().length,
      'platforms': [Platform.isWindows ? 'macos' : 'windows'],
    });
    final encoded = jsonEncode(config);
    SharedPreferences.setMockInitialValues({'configForAllDemosKey_1': encoded});
    P.app.buildNumber.q = '1';
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      if (utf8.decode(message!.buffer.asUint8List()) != 'remote/latest.json') return null;
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(encoded)));
    });
    await tester.runAsync(() async {
      await models.create();
      await File(p.join(models.path, 'replace.gguf')).writeAsBytes([8, 9]);
      await File(p.join(models.path, 'catalogued.gguf')).writeAsBytes(_rwkvHeader());
      await P.app.syncConfig();
    });
    messenger.setMockMethodCallHandler(picker, (call) async {
      expect(call.method, 'custom');
      expect(call.arguments['allowMultipleSelection'], isTrue);
      return [
        for (final name in ['skip.gguf', 'known.bin', 'bad.gguf', 'replace.gguf', 'new.gguf'])
          {
            'name': name,
            'size': name.endsWith('.bin') ? 2 : _rwkvHeader().length,
            'bytes': name == 'known.bin'
                ? Uint8List.fromList([1, 2])
                : name == 'bad.gguf'
                ? Uint8List(4)
                : _rwkvHeader(),
          },
      ];
    });
    (int, int, List<String>)? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await P.remote.pickAndImportWeightFiles(context: context);
              },
              child: const Text('Import'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Import'));
    await _until(tester, () => find.textContaining('skip.gguf').evaluate().isNotEmpty);
    await tester.tap(find.text('取消'));
    await _until(tester, () => find.textContaining('replace.gguf').evaluate().isNotEmpty);
    await tester.tap(find.text('强制导入'));
    await _until(tester, () => find.text(S.current.overwrite).evaluate().isNotEmpty);
    await tester.tap(find.text('取消'));
    await _until(tester, () => find.textContaining('new.gguf').evaluate().isNotEmpty);
    await tester.tap(find.text('强制导入'));
    await _until(tester, () => result != null);
    expect(result!.$1, 2);
    expect(result!.$2, 1);
    expect(result!.$3.single, startsWith('bad.gguf:'));
    await tester.runAsync(() async {
      expect(await File(p.join(models.path, 'replace.gguf')).readAsBytes(), [8, 9]);
      expect(await File(p.join(models.path, 'skip.gguf')).exists(), isFalse);
      expect(await File(p.join(models.path, 'known.bin')).readAsBytes(), [1, 2]);
      P.remote.localGgufWeights.q = {};
      await P.remote.refreshLocalGgufFiles();
      final imported = P.remote.localGgufWeights.q.single;
      expect(imported.fileName, 'new.gguf');
      P.pth.folders.q = [
        Folder(path: models.path, state: .loaded, files: [imported]),
      ];
      await P.remote.deleteFile(fileInfo: imported);
      expect(P.remote.localGgufWeights.q, isEmpty);
      expect(P.pth.folders.q.single.files.map((file) => file.fileName), ['catalogued.gguf']);
      expect(await File(imported.raw).exists(), isFalse);
    });
    // Drain the existing transient alert timers.
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
  });
}
