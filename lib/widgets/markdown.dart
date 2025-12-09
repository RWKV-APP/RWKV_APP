import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart' show OrderedListView;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class MarkdownRenderer extends ConsumerWidget {
  final String raw;
  final Color? color;
  const MarkdownRenderer({super.key, required this.raw, this.color});

  void _onTapLink(String? href, String title) async {
    if (href == null) return;
    await launchUrl(Uri.parse(href));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const scale = Config.msgFontScale;
    final gptMarkdownStyle = TextStyle(
      color: color,
      fontSize: Config.markdownBodyFontSize * scale,
    );

    final headerFontSizes = Config.markdownHeaderFontSizes.map((e) => e * scale).toList();

    final gptThemeData = GptMarkdownTheme.of(context).copyWith(
      h1: TextStyle(fontSize: headerFontSizes[0], fontWeight: FontWeight.w500),
      h2: TextStyle(fontSize: headerFontSizes[1], fontWeight: FontWeight.w500),
      h3: TextStyle(fontSize: headerFontSizes[2], fontWeight: FontWeight.w500),
      h4: TextStyle(fontSize: headerFontSizes[3]),
      h5: TextStyle(fontSize: headerFontSizes[4]),
      h6: TextStyle(fontSize: headerFontSizes[5]),
      hrLineThickness: 0,
    );

    final GptMarkdown gptMarkdown = GptMarkdown(
      raw.replaceAll("\n\n", "\n"),
      onLinkTap: _onTapLink,
      style: gptMarkdownStyle,
      addNewLineAfterH1: false,
      orderedListBuilder: (context, no, child, config) => OrderedListView(
        no: "$no.",
        textDirection: config.textDirection,
        style: (config.style ?? const TextStyle()),
        child: child,
      ),
      codeBuilder: (context, name, code, closed) {
        P.mdRender.tryToLoadLanguageHighlighter(name);
        return _Code(
          context: context,
          name: name,
          code: code.trim(),
          closed: closed,
        );
      },
    );

    return Theme(
      data: ThemeData(
        checkboxTheme: CheckboxThemeData(
          visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
          side: BorderSide(width: 1, color: primary),
          shape: RoundedRectangleBorder(borderRadius: .circular(4)),
          materialTapTargetSize: .shrinkWrap,
        ),
        textTheme: theme.textTheme.apply(fontSizeFactor: scale),
      ),
      child: GptMarkdownTheme(
        gptThemeData: gptThemeData,
        child: gptMarkdown,
      ),
    );
  }
}

class _Code extends ConsumerWidget {
  final BuildContext context;
  final String name;
  final String code;
  final bool closed;

  const _Code({
    required this.context,
    required this.name,
    required this.code,
    required this.closed,
  });

  void _onCopyPressed() async {
    Clipboard.setData(ClipboardData(text: code.trim()));
    Alert.success(S.current.code_copied_to_clipboard);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultHighlighter = ref.watch(P.mdRender.highlighters(P.mdRender.defaultCodeLanguage));
    final defaultDarkHighlighter = ref.watch(P.mdRender.darkHighlighters(P.mdRender.defaultCodeLanguage));

    final highlighter = ref.watch(P.mdRender.highlighters(name));
    final darkHighlighter = ref.watch(P.mdRender.darkHighlighters(name));

    final dark = ref.watch(P.app.dark);

    late final Highlighter? _highlighter;

    if (dark) {
      _highlighter = darkHighlighter ?? defaultDarkHighlighter;
    } else {
      _highlighter = highlighter ?? defaultHighlighter;
    }

    late final TextSpan highlightedCode;

    if (_highlighter != null) {
      highlightedCode = _highlighter.highlight(code.trim());
    } else {
      highlightedCode = TextSpan(text: code.trim());
    }

    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    return C(
      decoration: BoxDecoration(
        color: dark ? qw.q(.5) : qb.q(.04),
        borderRadius: .circular(8),
      ),
      padding: .only(left: 0, right: 0, top: 4, bottom: 4),
      margin: .only(bottom: 4, top: 4),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              8.w,
              T(
                name,
                s: TS(s: 14, w: .w500, c: qb.q(.5)),
              ),
              Spacer(),
              IconButton(
                onPressed: _onCopyPressed,
                icon: const Icon(Icons.copy),
                color: qb.q(.5),
                iconSize: 20,
                style: IconButton.styleFrom(
                  padding: .zero,
                  visualDensity: const VisualDensity(horizontal: 1, vertical: 1),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  splashFactory: NoSplash.splashFactory,
                ),
                tooltip: S.current.copy_code,
              ),
              4.w,
            ],
          ),
          4.h,
          Divider(
            color: qb.q(.1),
            thickness: 1,
            height: 1,
            indent: 0,
            endIndent: 0,
          ),
          4.h,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: .only(left: 8, right: 8),
            child: Text.rich(
              highlightedCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontFamilyFallback: [
                  'Menlo', // iOS, macOS
                  'Roboto Mono', // Android
                  'Consolas', // Windows
                  'DejaVu Sans Mono', // Linux
                  'Courier New', // Fallback
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
