import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/web_search_prompt.dart';

void main() {
  test('exact old defaults adopt the materials-first template while custom content survives', () {
    expect(webSearchPromptTemplate('%s\n请根据以上信息回答:\n%s'), defaultWebSearchChineseTemplate);
    expect(webSearchPromptTemplate('%s\n\n请根据以上信息回答:\n%s'), defaultWebSearchChineseTemplate);
    expect(webSearchPromptTemplate('%s\nPlease answer according to the above information:\n%s'), defaultWebSearchTemplate);
    expect(webSearchPromptTemplate('%s\n\nPlease answer according to the above information:\n%s'), defaultWebSearchTemplate);
    expect(webSearchPromptTemplate('材料：\n%s\n\n问题：%s'), defaultWebSearchChineseTemplate);
    expect(webSearchPromptTemplate('Material:\n%s\n\nQuestion: %s'), defaultWebSearchTemplate);
    expect(webSearchPromptTemplate('Custom %s / %s'), 'Custom %s / %s');
    expect(webSearchPromptTemplate('No placeholder'), 'No placeholder');
    expect(webSearchPromptTemplate('%s\n\nCustom instruction\n%s\nfooter'), '%s\n\nCustom instruction\n%s\nfooter');
  });

  test('default prompt connects the material to the unchanged question on its own line', () {
    for (final chinese in [true, false]) {
      final prompt = buildWebSearchPrompt(
        template: '',
        context: 'Source\n18 lines in 2025.',
        question: 'Metro question?',
        chinese: chinese,
        now: DateTime(2026, 11, 2),
      );
      expect(
        prompt,
        chinese
            ? '材料：\nSource\n18 lines in 2025.\n\n结合以上信息回答下面的问题\n\nMetro question?'
            : 'Material:\nSource\n18 lines in 2025.\n\nAnswer the following question using the information above\n\nMetro question?',
      );
    }
    expect(buildWebSearchPrompt(template: 'Custom %s / %s', context: 'source', question: 'question'), 'Custom source / question');
    expect(
      buildWebSearchPrompt(template: r'%3$s / %1$s / %2$s', context: 'source', question: 'question', now: DateTime(2026, 11, 2)),
      '2026-11-02 / source / question',
    );
  });
  test('API queries preserve the question and its statistical scope when it fits', () {
    for (final question in ['深圳有多少条狗？', '广州有多少只猫？', 'How many residents live in Oslo?']) {
      expect(buildWebSearchApiQuery('  $question  ', maxLength: 100), question);
    }
  });

  test('overlong API queries still use the existing bounded query generator', () {
    final question = List.filled(10, 'RWKV local inference documentation').join(' ');
    final query = buildWebSearchApiQuery(question, maxLength: 100);
    expect(query.runes.length, lessThanOrEqualTo(100));
    expect(query, contains('RWKV'));
  });

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
