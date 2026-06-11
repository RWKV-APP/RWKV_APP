import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/albatross_protocol.dart';

void main() {
  group('shouldShowAlbatrossEntry', () {
    test('requires Windows x64 and NVIDIA GPU name', () {
      expect(
        shouldShowAlbatrossEntry(
          isWindows: true,
          isWindowsX64: true,
          gpuName: 'NVIDIA GeForce RTX 4090',
        ),
        isTrue,
      );
      expect(
        shouldShowAlbatrossEntry(
          isWindows: true,
          isWindowsX64: false,
          gpuName: 'NVIDIA GeForce RTX 4090',
        ),
        isFalse,
      );
      expect(
        shouldShowAlbatrossEntry(
          isWindows: true,
          isWindowsX64: true,
          gpuName: 'AMD Radeon',
        ),
        isFalse,
      );
    });
  });

  group('buildAlbatrossCompletionPrompt', () {
    test('renders alternating chat history for continuation', () {
      final prompt = buildAlbatrossCompletionPrompt(const <String>[
        'Hello',
        'Hi',
        'How are you?',
      ]);

      expect(prompt, 'User: Hello\n\nAssistant: Hi\n\nUser: How are you?\n\nAssistant:');
    });

    test('strips thinking content from assistant history', () {
      final prompt = buildAlbatrossCompletionPrompt(const <String>[
        'Solve it',
        '<think>hidden</think>\nVisible answer',
      ]);

      expect(prompt, 'User: Solve it\n\nAssistant: Visible answer\n\nAssistant:');
    });
  });

  group('AlbatrossSseParser', () {
    test('parses split SSE chunks and done marker', () {
      final parser = AlbatrossSseParser();

      final first = parser.add('data: {"choices":[{"index":0,"delta":{"content":"你"}}]');
      expect(first, isEmpty);

      final second = parser.add('}\n\ndata: [DONE]\n\n');
      expect(second.length, 2);
      expect(second.first.done, isFalse);
      expect(second.first.choices.single.index, 0);
      expect(second.first.choices.single.content, '你');
      expect(second.last.done, isTrue);
    });

    test('keeps batch choice indexes', () {
      final parser = AlbatrossSseParser();
      final events = parser.add(
        'data: {"choices":[{"index":0,"delta":{"content":"A"}},{"index":2,"delta":{"content":"C"}}]}\n\n',
      );

      expect(events.single.choices.map((choice) => choice.index), <int>[0, 2]);
      expect(events.single.choices.map((choice) => choice.content), <String>['A', 'C']);
    });
  });
}
