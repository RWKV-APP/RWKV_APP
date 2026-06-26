import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/web_search_prompt.dart';

void main() {
  group('splitWebSearchPrompt', () {
    test('strips one configured thinking footer from the search query', () {
      final parts = splitWebSearchPrompt(
        prompt: 'What is RWKV? (think)',
        userMsgFooter: ' (think)',
      );

      expect(parts.query, 'What is RWKV?');
      expect(parts.footer, ' (think)');
    });

    test('preserves a user-written marker before the generated footer', () {
      final parts = splitWebSearchPrompt(
        prompt: 'Explain the literal suffix (think) (think)',
        userMsgFooter: ' (think)',
      );

      expect(parts.query, 'Explain the literal suffix (think)');
      expect(parts.footer, ' (think)');
    });

    test('does not change the prompt when no configured footer is present', () {
      final parts = splitWebSearchPrompt(
        prompt: 'What is RWKV?',
        userMsgFooter: ' (think)',
      );

      expect(parts.query, 'What is RWKV?');
      expect(parts.footer, '');
    });
  });
}
