import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final gptMarkdownStyle = TextStyle(color: color, fontSize: 14 * 1.1);

    final rawTheme = GptMarkdownTheme.of(context);

    final headerFontSizes = [
      rawTheme.h6?.fontSize ?? 14,
      15,
      16,
      17,
      18,
      19,
    ].reversed.map((e) => e.toDouble() * 1.1).toList();

    final gptThemeData = GptMarkdownTheme.of(context).copyWith(
      h1: TextStyle(fontSize: headerFontSizes[0]),
      h2: TextStyle(fontSize: headerFontSizes[1]),
      h3: TextStyle(fontSize: headerFontSizes[2]),
      h4: TextStyle(fontSize: headerFontSizes[3]),
      h5: TextStyle(fontSize: headerFontSizes[4]),
      h6: TextStyle(fontSize: headerFontSizes[5]),
      hrLineThickness: 0,
    );

    final GptMarkdown gptMarkdown = GptMarkdown(
      raw.replaceAll("\n\n", "\n"),
      onLinkTap: _onTapLink,
      style: gptMarkdownStyle,
    );

    return Theme(
      data: ThemeData(
        checkboxTheme: CheckboxThemeData(
          visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
          side: BorderSide(width: 1, color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          materialTapTargetSize: .shrinkWrap,
        ),
        textTheme: theme.textTheme.apply(fontSizeFactor: 1.1),
      ),
      child: GptMarkdownTheme(
        gptThemeData: gptThemeData,
        child: gptMarkdown,
      ),
    );
  }
}
