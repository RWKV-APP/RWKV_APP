import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/custom_widgets/code_field.dart' show CodeField;
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart' show OrderedListView;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/config.dart';

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
      codeBuilder: (context, name, code, closed) => CodeField(
        name: "Code",
        codes: code,
        backgroundColor: const Color(0xFF1E1E1E),
        textColor: const Color(0xFFE0E0E0),
      ),
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
