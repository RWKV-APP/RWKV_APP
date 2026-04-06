import 'package:flutter_test/flutter_test.dart';
import 'package:zone/store/p.dart';

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
}
