import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('uses full markdown for an unclosed backtick code fence', () {
      final raw = [
        '```dart',
        'print(1);',
      ].join('\n');

      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown(raw), isTrue);
    });

    test('keeps unsupported unclosed tilde fences lightweight', () {
      final raw = [
        '~~~dart',
        'print(1);',
      ].join('\n');

      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown(raw), isFalse);
    });

    test('keeps unclosed display latex lightweight', () {
      final raw = [
        r"\[",
        r"\frac{a}{b}",
      ].join('\n');

      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown(raw), isFalse);
    });

    test('uses full markdown for a complex streaming tail', () {
      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown('- item'), isTrue);
      expect(shouldRenderStreamingMarkdownTailAsFullMarkdown('[RWKV](https://rwkv.com)'), isTrue);
    });
  });

  testWidgets('renders and highlights an unclosed backtick code fence while streaming', (tester) async {
    await P.mdRender.tryToLoadLanguageHighlighter('dart');

    const partialCode = 'final value = 1;';
    await _pumpStreamingMarkdown(
      tester: tester,
      raw: '```dart\n$partialCode',
    );

    expect(find.text('dart'), findsOneWidget);
    expect(find.byIcon(Symbols.content_copy), findsOneWidget);
    expect(find.textContaining('```'), findsNothing);
    _expectHighlightedCode(tester, partialCode);

    const appendedCode = 'final value = 10;\nprint(value);';
    await _pumpStreamingMarkdown(
      tester: tester,
      raw: '```dart\n$appendedCode',
    );

    expect(find.byIcon(Symbols.content_copy), findsOneWidget);
    _expectHighlightedCode(tester, appendedCode);

    await _pumpStreamingMarkdown(
      tester: tester,
      raw: '```dart\n$appendedCode\n```',
    );

    expect(find.byIcon(Symbols.content_copy), findsOneWidget);
    expect(find.textContaining('```'), findsNothing);
    _expectHighlightedCode(tester, appendedCode);
  });

  testWidgets('keeps an unclosed backtick code fence plain when markdown is disabled', (tester) async {
    const raw = '```dart\nprint(1);';
    await _pumpStreamingMarkdown(
      tester: tester,
      raw: raw,
      renderMarkdown: false,
    );

    expect(find.byIcon(Symbols.content_copy), findsNothing);
    expect(find.text(raw), findsOneWidget);
  });

  testWidgets('keeps emoji surrogate pairs intact when inserting soft breaks', (tester) async {
    const raw = '''作为AI助手，我每天都在处理各种各样的问题——从哲学思辨到物理公式，从诗歌创作到编程代码，总有那么些挑战我逻辑极限、考验我算力的小伙伴们呢~ 😊
不过您放心，我虽然无法像人类一样“蠢”（毕竟我的核心代码里只写着高效运行），但遇到模糊、歧义或者特别冷门的问题时，偶尔会卡顿一下，需要您再稍微描述清楚点才能帮您搞定。👀
**您现在遇到了什么难题？我很乐意用尽全部计算资源为您服务哦！🚀**''';

    await _pumpStreamingMarkdown(
      tester: tester,
      raw: raw,
      streaming: false,
    );

    final renderedText = tester.widgetList<RichText>(find.byType(RichText)).map((RichText richText) => richText.text.toPlainText()).join();
    expect(_containsUnpairedSurrogate(renderedText), isFalse);
    expect(renderedText.replaceAll('\u200B', ''), contains('😊'));
    expect(renderedText.replaceAll('\u200B', ''), contains('👀'));
    expect(renderedText.replaceAll('\u200B', ''), contains('您现在遇到了什么难题？'));
  });
}

Future<void> _pumpStreamingMarkdown({
  required WidgetTester tester,
  required String raw,
  bool renderMarkdown = true,
  bool streaming = true,
}) async {
  P.app.preferredThemeMode.q = ThemeMode.light;
  P.app.theme.q = .light;
  P.app.qb.q = Colors.black;
  P.app.qw.q = Colors.white;
  P.preference.preferredMessageLineHeight.q = 1.2;
  P.preference.renderMarkdownAndLatexEnabled.q = renderMarkdown;

  await tester.pumpWidget(
    StateWrapper(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: StreamingMarkdownRender(
            raw: raw,
            streaming: streaming,
            useMessageLineHeight: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectHighlightedCode(WidgetTester tester, String code) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  for (final richText in richTexts) {
    if (richText.text.toPlainText() != code) continue;
    expect(_hasColoredTextSpan(richText.text), isTrue);
    return;
  }
  fail('Could not find rendered code: $code');
}

bool _hasColoredTextSpan(InlineSpan span) {
  if (span is! TextSpan) return false;
  if (span.style?.color != null && (span.text?.isNotEmpty ?? false)) return true;

  final children = span.children;
  if (children == null) return false;
  for (final child in children) {
    if (_hasColoredTextSpan(child)) return true;
  }
  return false;
}

bool _containsUnpairedSurrogate(String value) {
  for (int index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) return true;
    if (codeUnit < 0xD800 || codeUnit > 0xDBFF) continue;
    if (index + 1 >= value.length) return true;

    final nextCodeUnit = value.codeUnitAt(index + 1);
    if (nextCodeUnit < 0xDC00 || nextCodeUnit > 0xDFFF) return true;
    index++;
  }
  return false;
}
