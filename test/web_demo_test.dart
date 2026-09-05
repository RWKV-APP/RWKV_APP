import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/config.dart';
import 'package:zone/func/web_demo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  group('Web Demo prompt helpers', () {
    test('uses a raw HTML only default prompt template', () {
      final prompt = buildWebDemoPrompt(template: webDemoDefaultPromptTemplate, request: 'make a clock');

      expect(prompt, contains('make a clock'));
      expect(prompt, contains('Return raw HTML only.'));
      expect(prompt, contains('Do not include Markdown fences'));
      expect(prompt, contains('Assistant: <think></think>'));
    });

    test('builds an edit prompt with the current HTML context', () {
      final prompt = buildWebDemoEditPrompt(
        html: '<!doctype html><html><body>Old</body></html>',
        instruction: 'make it blue',
      );

      expect(prompt, contains('Modify the HTML below'));
      expect(prompt, contains('make it blue'));
      expect(prompt, contains('Return raw HTML only.'));
      expect(prompt, contains('Do not include Markdown fences'));
      expect(prompt, contains('<!doctype html><html><body>Old</body></html>'));
    });
  });

  group('Web Demo backend helpers', () {
    test('labels and caps the three generation paths', () {
      expect(webDemoBackendIsCloud(WebDemoBackendMode.cloud7b), isTrue);
      expect(webDemoBackendIsCloud(WebDemoBackendMode.cloud13b), isTrue);
      expect(webDemoBackendIsCloud(WebDemoBackendMode.localAlbatross), isFalse);
      expect(webDemoBackendIsCloud(WebDemoBackendMode.localRwkvMobile), isFalse);

      expect(webDemoMaxBatchSizeForBackend(WebDemoBackendMode.cloud7b), 30);
      expect(webDemoMaxBatchSizeForBackend(WebDemoBackendMode.cloud13b), 30);
      expect(webDemoMaxBatchSizeForBackend(WebDemoBackendMode.localAlbatross), 10);
      expect(webDemoMaxBatchSizeForBackend(WebDemoBackendMode.localRwkvMobile), 30);

      expect(webDemoBackendLabel(WebDemoBackendMode.cloud7b), 'Official cloud 7.2B');
      expect(webDemoBackendLabel(WebDemoBackendMode.localAlbatross), 'Local Albatross');
      expect(webDemoBackendLabel(WebDemoBackendMode.localRwkvMobile), 'Local RWKV Mobile');
    });

    test('recovers backend mode from stored Web Demo model names', () {
      expect(webDemoBackendModeForModelName('Official RWKV Web Demo 13.3B'), WebDemoBackendMode.cloud13b);
      expect(webDemoBackendModeForModelName('Official RWKV Web Demo 7.2B'), WebDemoBackendMode.cloud7b);
      expect(webDemoBackendModeForModelName('Local Albatross'), WebDemoBackendMode.localAlbatross);
      expect(webDemoBackendModeForModelName('Albatross'), WebDemoBackendMode.localAlbatross);
      expect(webDemoBackendModeForModelName('Local RWKV Mobile - RWKV7 13B'), WebDemoBackendMode.localRwkvMobile);
      expect(webDemoBackendModeForModelName('RWKV7-G1'), WebDemoBackendMode.localRwkvMobile);
    });

    test('persists the preferred concurrency', () async {
      SharedPreferences.setMockInitialValues({});

      await P.preference.saveWebDemoBatchSize(12);

      expect(await P.preference.loadWebDemoBatchSize(), 12);
    });
  });

  group('extractWebDemoHtmlDocuments', () {
    test('extracts a plain complete HTML document', () {
      const output = 'prefix\n<!doctype html><html><body>Hello</body></html>\nnotes';

      final documents = extractWebDemoHtmlDocuments(output);

      expect(documents, hasLength(1));
      expect(documents.first.html, '<!doctype html><html><body>Hello</body></html>');
      expect(documents.first.complete, isTrue);
    });

    test('extracts only after the thinking tag when present', () {
      const output = '''
<!doctype html><html><body>Hidden</body></html>
</think>
text
<!doctype html><html><body>Visible</body></html>
''';

      final document = extractFirstWebDemoHtml(output);

      expect(document?.html, '<!doctype html><html><body>Visible</body></html>');
    });

    test('keeps a partial HTML document while marking it incomplete', () {
      const output = '</think>\n<!doctype html><html><body><h1>Still streaming</h1>';

      final documents = extractWebDemoHtmlDocuments(output);

      expect(documents, hasLength(1));
      expect(documents.first.html, '<!doctype html><html><body><h1>Still streaming</h1>');
      expect(documents.first.complete, isFalse);
    });

    test('rejects HTML that has no body tag', () {
      const output = '</think>\n<!doctype html><html><head><title>No body</title></head></html>';

      final documents = extractWebDemoHtmlDocuments(output);

      expect(documents, isEmpty);
    });

    test('extracts multiple complete candidate documents', () {
      const output = '''
</think>
<!doctype html><html><body>One</body></html>
noise
<!doctype html><html><body>Two</body></html>
''';

      final documents = extractWebDemoHtmlDocuments(output);

      expect(documents, hasLength(2));
      expect(documents[0].html, '<!doctype html><html><body>One</body></html>');
      expect(documents[1].html, '<!doctype html><html><body>Two</body></html>');
    });

    test('falls back to an html document without doctype', () {
      const output = '</think>\n<html><body>No doctype</body></html>';

      final documents = extractWebDemoHtmlDocuments(output);

      expect(documents, hasLength(1));
      expect(documents.first.html, '<html><body>No doctype</body></html>');
    });

    test('extracts HTML wrapped in a markdown code fence', () {
      const output = '''
</think>
```html
<!doctype html><html><body>Fenced</body></html>
```
''';

      final document = extractFirstWebDemoHtml(output);

      expect(document?.html, '<!doctype html><html><body>Fenced</body></html>');
    });

    test('extracts HTML from a prose lead-in and markdown code fence', () {
      const output = '''
</think>
# 打游戏的网站 - HTML实现
下面是完整的HTML代码实现：
```html
<!DOCTYPE html>
<html><body>Game site</body></html>
```
''';

      final document = extractFirstWebDemoHtml(output);

      expect(document?.html, '<!DOCTYPE html>\n<html><body>Game site</body></html>');
    });
  });

  group('extractWebDemoCloudChoiceContents', () {
    test('reads RWKV Lightning batch choices in order', () {
      final choices = extractWebDemoCloudChoiceContents({
        'choices': [
          {
            'index': 1,
            'message': {'content': 'second'},
          },
          {
            'index': 0,
            'message': {'content': 'first'},
          },
        ],
      });

      expect(choices, hasLength(2));
      expect(choices.first.index, 1);
      expect(choices.first.content, 'second');
      expect(choices.last.index, 0);
      expect(choices.last.content, 'first');
    });

    test('reads OpenAI text and streaming delta choices', () {
      final choices = extractWebDemoCloudChoiceContents({
        'choices': [
          {'text': 'plain text'},
          {
            'delta': {'content': 'delta text'},
          },
        ],
      });

      expect(choices.map((choice) => choice.content), ['plain text', 'delta text']);
    });

    test('maps shuffled cloud choices back to batch slots', () {
      const prompt = 'User: Write HTML: page\n\nAssistant: <think></think';
      final outputs = buildWebDemoCloudChoiceOutputs(
        batchSize: 3,
        prompt: prompt,
        choices: const [
          WebDemoCloudChoice(index: 2, content: '<!doctype html><html><body>Three</body></html>'),
          WebDemoCloudChoice(index: 0, content: '<!doctype html><html><body>One</body></html>'),
          WebDemoCloudChoice(index: 1, content: '<!doctype html><html><body>Two</body></html>'),
        ],
      );

      expect(outputs, [
        '<!doctype html><html><body>One</body></html>',
        '<!doctype html><html><body>Two</body></html>',
        '<!doctype html><html><body>Three</body></html>',
      ]);
    });
  });

  group('splitWebDemoBatchContent', () {
    test('splits stored batch candidates using the app batch marker', () {
      final content = [
        '<!doctype html><html><body>One</body></html>',
        '<!doctype html><html><body>Two</body></html>',
      ].join(Config.batchMarker);

      final parts = splitWebDemoBatchContent(content);

      expect(parts, hasLength(2));
      expect(parts.first, '<!doctype html><html><body>One</body></html>');
      expect(parts.last, '<!doctype html><html><body>Two</body></html>');
    });
  });

  group('Web Demo result actions', () {
    test('copies result source to clipboard', () async {
      final copiedTexts = <String>[];
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method != 'Clipboard.setData') return null;
        final arguments = Map<String, dynamic>.from(call.arguments as Map);
        copiedTexts.add(arguments['text'] as String);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });
      const result = WebDemoResult(
        index: 0,
        raw: '<!doctype html><html><body>Copy me</body></html>',
        streaming: false,
      );

      await P.webDemo.copyResultSource(result);

      expect(copiedTexts, ['<!doctype html><html><body>Copy me</body></html>']);
    });

    test('prepares continuation from existing HTML', () async {
      P.webDemo.pendingHtmlContext.q = null;
      P.webDemo.promptInput.q = '';
      P.webDemo.promptController.text = '';

      await P.webDemo.prepareContinuation(
        html: '<!doctype html><html><body>Old page</body></html>',
      );

      expect(P.webDemo.pendingHtmlContext.q, '<!doctype html><html><body>Old page</body></html>');
      expect(P.webDemo.promptInput.q, 'Modify this page: ');
      expect(P.webDemo.promptController.text, 'Modify this page: ');
    });

    test('saves HTML into the web demo directory', () async {
      final root = Directory.systemTemp.createTempSync('rwkv_web_demo_test_');
      final previousDocumentsDir = P.app.documentsDir.q;
      const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        expect(call.method, 'getApplicationDocumentsDirectory');
        return root.path;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(pathProviderChannel, null);
        P.app.documentsDir.q = previousDocumentsDir;
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      P.app.documentsDir.q = root;

      final file = await P.webDemo.saveHtml(
        html: '<!doctype html><html><body>Saved page</body></html>',
        label: 'unit',
      );

      expect(file.existsSync(), isTrue);
      expect(file.parent.path, '${root.path}${Platform.pathSeparator}web_demo');
      expect(file.readAsStringSync(), '<!doctype html><html><body>Saved page</body></html>');
      expect(P.webDemo.lastSavedHtmlPath.q, file.path);
    });

    test('stops an active cloud run and marks streaming results complete', () async {
      P.msg.ids.q = [];
      P.msg.msgNode.q = MsgNode(0);
      P.rwkvGeneration.generating.q = true;
      P.webDemo.active.q = true;
      P.webDemo.currentRun.q = WebDemoRun(
        prompt: 'make html',
        createdAt: DateTime(2026),
        backendMode: WebDemoBackendMode.cloud7b,
        batchSize: 1,
        rawDecodeParams: '{}',
      );
      P.webDemo.results.q = const <WebDemoResult>[
        WebDemoResult(index: 0, raw: '<html><body>Streaming</body>', streaming: true),
      ];

      await P.webDemo.stopActive();

      expect(P.webDemo.active.q, isFalse);
      expect(P.rwkvGeneration.generating.q, isFalse);
      expect(P.webDemo.results.q.first.streaming, isFalse);
    });

    test('hydrates previous batch results from conversation history', () {
      P.webDemo.active.q = false;
      const firstHtml = '<!doctype html><html><body>One</body></html>';
      const secondHtml = '<!doctype html><html><body>Two</body></html>';
      final batchContent = '$firstHtml${Config.batchMarker}$secondHtml';
      final root = MsgNode(0);
      final userNode = root.rootAdd(MsgNode(100));
      userNode.add(MsgNode(101));
      P.msg.msgNode.q = root;
      P.msg.pool.q = {
        100: const Message(id: 100, content: 'make two pages', isMine: true, paused: false),
        101: Message(
          id: 101,
          content: batchContent,
          isMine: false,
          paused: false,
          modelName: 'Official RWKV Web Demo 13.3B',
          runningMode: 'web_demo',
          rawDecodeParams: '{}',
        ),
      };

      P.webDemo.hydrateFromCurrentConversation(force: true);

      expect(P.webDemo.results.q, hasLength(2));
      expect(P.webDemo.results.q.first.raw, firstHtml);
      expect(P.webDemo.results.q.last.raw, secondHtml);
      expect(P.webDemo.currentRun.q?.prompt, 'make two pages');
      expect(P.webDemo.currentRun.q?.backendMode, WebDemoBackendMode.cloud13b);
    });
  });
}
