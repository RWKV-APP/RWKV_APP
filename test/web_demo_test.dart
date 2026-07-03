import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/config.dart';
import 'package:zone/func/web_demo.dart';
import 'package:zone/store/p.dart';

void main() {
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
}
