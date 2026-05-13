import 'package:flutter_test/flutter_test.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

void main() {
  group('markdown latex normalizer', () {
    test('wraps standalone latex lines into a display block', () {
      final raw = [
        '推导如下：',
        r"u_{\nu}^{(\alpha)}'(kr) + \frac{\alpha}{r} u_{\nu}^{(\alpha)}(kr) = 0",
        '下一步',
      ].join('\n');

      final normalized = P.mdRender.normalizeLatexForMarkdown(raw);

      expect(
        normalized,
        [
          '推导如下：',
          r"\[",
          r"u_{\nu}^{(\alpha)}'(kr) + \frac{\alpha}{r} u_{\nu}^{(\alpha)}(kr) = 0",
          r"\]",
          '下一步',
        ].join('\n'),
      );
    });

    test('groups consecutive latex lines into one display block', () {
      final raw = [
        r"u_{\nu}^{(\alpha)}'(kr) + \frac{\alpha}{r} u_{\nu}^{(\alpha)}(kr) = 0",
        r"x^{\alpha - 1} u_{\nu}^{(\alpha)}'(x) - \frac{\alpha}{x} u_{\nu}^{(\alpha)}(x) = 0",
      ].join('\n');

      final normalized = P.mdRender.normalizeLatexForMarkdown(raw);

      expect(
        normalized,
        [
          r"\[",
          r"u_{\nu}^{(\alpha)}'(kr) + \frac{\alpha}{r} u_{\nu}^{(\alpha)}(kr) = 0",
          r"x^{\alpha - 1} u_{\nu}^{(\alpha)}'(x) - \frac{\alpha}{x} u_{\nu}^{(\alpha)}(x) = 0",
          r"\]",
        ].join('\n'),
      );
    });

    test('temporarily closes an unfinished display block for streaming render', () {
      final raw = [
        r"\[",
        r"\frac{\hbar^2}{2m_e}",
      ].join('\n');

      final normalized = P.mdRender.normalizeLatexForMarkdown(raw);

      expect(
        normalized,
        [
          r"\[",
          r"\frac{\hbar^2}{2m_e}",
          r"\]",
        ].join('\n'),
      );
    });

    test('does not alter fenced code blocks', () {
      final raw = [
        '```tex',
        r"\frac{a}{b}",
        '```',
      ].join('\n');

      final normalized = P.mdRender.normalizeLatexForMarkdown(raw);

      expect(normalized, raw);
    });
  });

  group('streaming markdown split', () {
    test('keeps completed regular paragraphs stable before the tail', () {
      final raw = [
        '第一段已经完成。',
        '',
        '第二段还在生成',
      ].join('\n');

      final split = splitStreamingMarkdown(raw);

      expect(split.stableBlocks, ['第一段已经完成。\n\n']);
      expect(split.tail, '第二段还在生成');
    });

    test('keeps an unclosed fenced code block in the tail', () {
      final raw = [
        '```dart',
        'print(1);',
      ].join('\n');

      final split = splitStreamingMarkdown(raw);

      expect(split.stableBlocks, isEmpty);
      expect(split.tail, raw);
    });

    test('marks a closed fenced code block as stable', () {
      final raw = [
        '```dart',
        'print(1);',
        '```',
        'tail',
      ].join('\n');

      final split = splitStreamingMarkdown(raw);

      expect(
        split.stableBlocks,
        [
          [
            '```dart',
            'print(1);',
            '```',
            '',
          ].join('\n'),
        ],
      );
      expect(split.tail, 'tail');
    });

    test('keeps an unclosed display latex block in the tail', () {
      final raw = [
        r"\[",
        r"\frac{a}{b}",
      ].join('\n');

      final split = splitStreamingMarkdown(raw);

      expect(split.stableBlocks, isEmpty);
      expect(split.tail, raw);
    });

    test('marks a closed display latex block as stable', () {
      final raw = [
        r"\[",
        r"\frac{a}{b}",
        r"\]",
        'tail',
      ].join('\n');

      final split = splitStreamingMarkdown(raw);

      expect(
        split.stableBlocks,
        [
          [
            r"\[",
            r"\frac{a}{b}",
            r"\]",
            '',
          ].join('\n'),
        ],
      );
      expect(split.tail, 'tail');
    });

    test('keeps a completed table stable before the next line', () {
      final raw = [
        '| A | B |',
        '| - | - |',
        '| 1 | 2 |',
        'tail',
      ].join('\n');

      final split = splitStreamingMarkdown(raw);

      expect(
        split.stableBlocks,
        [
          [
            '| A | B |',
            '| - | - |',
            '| 1 | 2 |',
            '',
          ].join('\n'),
        ],
      );
      expect(split.tail, 'tail');
    });

    test('uses lightweight text for a simple streaming tail', () {
      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown('plain streaming text'), isFalse);
    });

    test('uses full markdown for a complex streaming tail', () {
      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown('- item'), isTrue);
      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown('[RWKV](https://rwkv.com)'), isTrue);
    });
  });
}
