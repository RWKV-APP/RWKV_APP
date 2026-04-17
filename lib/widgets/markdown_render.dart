// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/custom_widgets/selectable_adapter.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

// ignore: depend_on_referenced_packages

const int _softBreakStep = 12;
const int _softBreakMinRunLength = 24;
const int _markdownPreprocessCacheLimit = 96;
const String _softBreak = "\u200B";
final RegExp _markdownFenceLineExp = RegExp(r"^(```|~~~)");
final _markdownPreprocessCache = <String, String>{};

String _prepareMarkdownRaw(String raw) {
  final compactRaw = raw.replaceAll("\n\n", "\n").trim();
  final cached = _markdownPreprocessCache.remove(compactRaw);
  if (cached != null) {
    _markdownPreprocessCache[compactRaw] = cached;
    return cached;
  }

  final normalizedRaw = P.mdRender.normalizeLatexForMarkdown(compactRaw);
  final breakableRaw = _insertSoftBreaksInLongRuns(normalizedRaw);
  if (_markdownPreprocessCache.length >= _markdownPreprocessCacheLimit) {
    _markdownPreprocessCache.remove(_markdownPreprocessCache.keys.first);
  }
  _markdownPreprocessCache[compactRaw] = breakableRaw;
  return breakableRaw;
}

String _insertSoftBreaksInLongRuns(String raw) {
  final lines = raw.split("\n");
  final output = <String>[];
  bool insideFence = false;
  bool insideDisplayLatex = false;

  for (final String line in lines) {
    final trimmedLine = line.trim();
    if (_isMarkdownFenceLine(trimmedLine)) {
      insideFence = !insideFence;
      output.add(line);
      continue;
    }

    if (insideFence) {
      output.add(line);
      continue;
    }

    final startsDisplayLatex = trimmedLine.startsWith(r"\[");
    final endsDisplayLatex = trimmedLine.endsWith(r"\]");
    if (insideDisplayLatex || startsDisplayLatex || _containsInlineLatexDelimiter(line)) {
      output.add(line);
      if (startsDisplayLatex && !endsDisplayLatex) {
        insideDisplayLatex = true;
      }
      if (insideDisplayLatex && endsDisplayLatex) {
        insideDisplayLatex = false;
      }
      continue;
    }

    output.add(_insertSoftBreaksInLine(line));
  }

  return output.join("\n");
}

String _insertSoftBreaksInLine(String line) {
  if (line.length < _softBreakMinRunLength) return line;

  final buffer = StringBuffer();
  int runStart = 0;
  bool insertedBreaks = false;

  for (int i = 0; i < line.length; i++) {
    final codeUnit = line.codeUnitAt(i);
    if (!_isSoftBreakRunBoundary(codeUnit)) continue;
    insertedBreaks = _writeSoftBreakRun(line.substring(runStart, i), buffer) || insertedBreaks;
    buffer.writeCharCode(codeUnit);
    runStart = i + 1;
  }

  insertedBreaks = _writeSoftBreakRun(line.substring(runStart), buffer) || insertedBreaks;
  if (!insertedBreaks) return line;
  return buffer.toString();
}

bool _writeSoftBreakRun(String value, StringBuffer buffer) {
  if (value.length < _softBreakMinRunLength || value.contains("://")) {
    buffer.write(value);
    return false;
  }

  for (int i = 0; i < value.length; i++) {
    if (i > 0 && i % _softBreakStep == 0) {
      buffer.write(_softBreak);
    }
    buffer.write(value[i]);
  }
  return true;
}

bool _isSoftBreakRunBoundary(int codeUnit) {
  if (codeUnit == 0x24) return true;
  if (codeUnit == 0x5C) return true;
  if (codeUnit == 0x60) return true;
  if (codeUnit <= 0x20) return true;
  if (codeUnit == 0x85) return true;
  if (codeUnit == 0xA0) return true;
  if (codeUnit == 0x1680) return true;
  if (codeUnit >= 0x2000 && codeUnit <= 0x200A) return true;
  if (codeUnit == 0x2028) return true;
  if (codeUnit == 0x2029) return true;
  if (codeUnit == 0x202F) return true;
  if (codeUnit == 0x205F) return true;
  return codeUnit == 0x3000;
}

bool _isMarkdownFenceLine(String line) {
  if (line.isEmpty) return false;
  return _markdownFenceLineExp.hasMatch(line);
}

bool _containsInlineLatexDelimiter(String line) {
  if (line.contains(r"\(")) return true;
  if (line.contains(r"\)")) return true;
  if (line.contains(r"$$")) return true;
  return line.contains(r"$");
}

class MarkdownRender extends ConsumerWidget {
  final String raw;
  final Color? color;
  final bool useMessageLineHeight;

  const MarkdownRender({
    super.key,
    required this.raw,
    this.color,
    this.useMessageLineHeight = false,
  });

  void _onTapLink(String? href, String title) async {
    if (href == null) return;
    await launchUrl(Uri.parse(href));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final breakableRaw = _prepareMarkdownRaw(raw);
    final textScaler = MediaQuery.textScalerOf(context);
    final primary = theme.colorScheme.primary;
    const scale = Config.msgFontScale;
    final textScaleFactor = textScaler.scale(1.0);
    final effectiveScale = scale * textScaleFactor;
    final qb = ref.watch(P.app.qb);
    final effectiveMessageLineHeight = ref.watch(P.preference.effectiveMessageLineHeight);
    final messageLineHeight = useMessageLineHeight ? effectiveMessageLineHeight : null;
    final gptMarkdownStyle = TextStyle(
      color: color ?? qb,
      fontSize: Config.markdownBodyFontSize * effectiveScale,
      height: messageLineHeight,
    );

    final headerFontSizes = Config.markdownHeaderFontSizes.map((e) => e * effectiveScale).toList();

    final gptThemeData = GptMarkdownTheme.of(context).copyWith(
      h1: TextStyle(fontSize: headerFontSizes[0], fontWeight: .w500, height: messageLineHeight),
      h2: TextStyle(fontSize: headerFontSizes[1], fontWeight: .w500, height: messageLineHeight),
      h3: TextStyle(fontSize: headerFontSizes[2], fontWeight: .w500, height: messageLineHeight),
      h4: TextStyle(fontSize: headerFontSizes[3], height: messageLineHeight),
      h5: TextStyle(fontSize: headerFontSizes[4], height: messageLineHeight),
      h6: TextStyle(fontSize: headerFontSizes[5], height: messageLineHeight),
      hrHeight: 6,
    );

    final inlineComponents = <MarkdownComponent>[
      for (final MarkdownComponent component in MarkdownComponent.inlineComponents)
        if (component is ItalicMd) _SafeItalicMd() else component,
      _HtmlBreakMd(),
    ];

    final gptMarkdown = GptMarkdown(
      breakableRaw,
      onLinkTap: _onTapLink,
      style: gptMarkdownStyle,
      textScaler: .noScaling,
      inlineComponents: inlineComponents,
      latexBuilder: (context, tex, textStyle, inline) => _LatexRender(
        tex: tex,
        textStyle: textStyle,
        inline: inline,
      ),
      useDollarSignsForLatex: true,
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
      highlightBuilder: (context, text, style) => _Highlight(text: text, style: style),
    );

    return MediaQuery.withNoTextScaling(
      child: Theme(
        data: theme.copyWith(
          checkboxTheme: CheckboxThemeData(
            visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
            side: BorderSide(width: 1, color: primary),
            shape: RoundedRectangleBorder(borderRadius: .circular(4)),
            materialTapTargetSize: .shrinkWrap,
          ),
          textTheme: theme.textTheme.apply(fontSizeFactor: effectiveScale),
        ),
        child: DefaultTextStyle.merge(
          style: gptMarkdownStyle,
          child: GptMarkdownTheme(
            gptThemeData: gptThemeData,
            child: gptMarkdown,
          ),
        ),
      ),
    );
  }
}

class _LatexRender extends StatelessWidget {
  final String tex;
  final TextStyle textStyle;
  final bool inline;

  const _LatexRender({
    required this.tex,
    required this.textStyle,
    required this.inline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle.copyWith(
      color: textStyle.color ?? theme.colorScheme.onSurface,
    );
    final effectiveColor = effectiveTextStyle.color ?? theme.colorScheme.onSurface;
    final mathStyle = inline ? MathStyle.text : MathStyle.display;

    return SelectableAdapter(
      selectedText: tex,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final math = Math.tex(
            tex,
            textStyle: effectiveTextStyle,
            mathStyle: mathStyle,
            textScaleFactor: 1,
            settings: const TexParserSettings(strict: Strict.ignore),
            options: MathOptions(
              sizeUnderTextStyle: MathSize.large,
              color: effectiveColor,
              fontSize: effectiveTextStyle.fontSize ?? theme.textTheme.bodyMedium?.fontSize,
              mathFontOptions: FontOptions(
                fontFamily: "Main",
                fontWeight: effectiveTextStyle.fontWeight ?? FontWeight.normal,
                fontShape: FontStyle.normal,
              ),
              textFontOptions: FontOptions(
                fontFamily: "Main",
                fontWeight: effectiveTextStyle.fontWeight ?? FontWeight.normal,
                fontShape: FontStyle.normal,
              ),
              style: mathStyle,
            ),
            onErrorFallback: (err) {
              return Text(
                _insertSoftBreaksInLongRuns(tex),
                textDirection: Directionality.of(context),
                style: effectiveTextStyle,
              );
            },
          );
          if (!constraints.hasBoundedWidth) {
            return math;
          }
          return ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: math,
            ),
          );
        },
      ),
    );
  }
}

class _SafeItalicMd extends InlineMd {
  @override
  RegExp get exp => RegExp(
    r"(?:(?<![\w\*])\*(?![\s\*])(.+?)(?<!\s)\*(?![\w\*]))",
    dotAll: true,
  );

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final data = match?[1] ?? "";
    final conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        fontStyle: FontStyle.italic,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(context, data, conf, false),
      style: conf.style,
    );
  }
}

class _HtmlBreakMd extends InlineMd {
  _HtmlBreakMd();

  @override
  RegExp get exp => RegExp(r"<[bB][rR]\s*/?>");

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    return TextSpan(
      text: "\n",
      style: config.style,
    );
  }
}

// For inline code highlight
class _Highlight extends ConsumerWidget {
  final String text;
  final TextStyle style;
  const _Highlight({required this.text, required this.style});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    final inlineCodeBackgroundColor = appTheme.inlineCodeBackgroundColor;

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);
    return Container(
      decoration: BoxDecoration(
        color: inlineCodeBackgroundColor,
        borderRadius: .circular(6),
        border: .all(color: theme.dividerColor.q(appTheme.isLight ? .15 : .45)),
      ),
      padding: const .only(left: 4, right: 4, top: 0, bottom: 0),
      child: Text.rich(
        TextSpan(
          text: text,
          style: style.copyWith(
            fontSize: (style.fontSize ?? 14) - 2,
            fontFamily: monospaceFF,
            fontFamilyFallback: P.mdRender.codeFontFamilyFallback,
          ),
        ),
      ),
    );
  }
}

// For code block highlight
class _Code extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_Code> createState() => _CodeState();
}

class _CodeState extends ConsumerState<_Code> {
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0;

  void _onCopyPressed() async {
    Clipboard.setData(ClipboardData(text: widget.code.trim()));
    Alert.success(S.current.code_copied_to_clipboard);
  }

  /// 查找父横向滚动视图的 ScrollController
  ScrollController? _findParentHorizontalScrollController(BuildContext context) {
    ScrollController? parentController;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Scrollable) {
        final scrollable = widget;
        final controller = scrollable.controller;
        if (controller != null && controller.hasClients) {
          final position = controller.position;
          // 只查找横向滚动的父视图
          if (position.axis == Axis.horizontal) {
            parentController = controller;
            return false; // 找到后停止遍历
          }
        }
      }
      return true; // 继续向上查找
    });
    return parentController;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final scrollController = _scrollController;
      if (!scrollController.hasClients) return false;

      final position = scrollController.position;
      final currentPosition = position.pixels;
      final scrollDelta = currentPosition - _lastScrollPosition;
      _lastScrollPosition = currentPosition;

      // 检查是否到达边界
      final atLeftEdge = position.pixels <= position.minScrollExtent;
      final atRightEdge = position.pixels >= position.maxScrollExtent;

      // 如果到达边界且仍在尝试滚动，则传递给父滚动视图
      if ((atLeftEdge && scrollDelta < 0) || (atRightEdge && scrollDelta > 0)) {
        final parentController = _findParentHorizontalScrollController(context);
        if (parentController != null && parentController.hasClients) {
          final parentPosition = parentController.position;
          // 计算父滚动视图的新位置
          // 注意：scrollDelta 是子视图的滚动增量，需要传递给父视图
          // 使用 + 而不是 -，因为滚动方向应该保持一致
          final remainingDelta = scrollDelta;
          final newParentOffset = (parentPosition.pixels + remainingDelta).clamp(
            parentPosition.minScrollExtent,
            parentPosition.maxScrollExtent,
          );

          if (newParentOffset != parentPosition.pixels) {
            parentController.jumpTo(newParentOffset);
          }
        }
      }
    } else if (notification is OverscrollNotification) {
      // 处理过度滚动（到达边界后的继续滚动）
      final overscroll = notification.overscroll;
      final parentController = _findParentHorizontalScrollController(context);
      if (parentController != null && parentController.hasClients) {
        final parentPosition = parentController.position;
        // 将过度滚动的增量传递给父滚动视图
        // 使用 + 而不是 -，因为滚动方向应该保持一致
        final newParentOffset = (parentPosition.pixels + overscroll).clamp(parentPosition.minScrollExtent, parentPosition.maxScrollExtent);

        if (newParentOffset != parentPosition.pixels) {
          parentController.jumpTo(newParentOffset);
        }
      }
    } else if (notification is ScrollStartNotification) {
      // 重置位置记录
      if (_scrollController.hasClients) {
        _lastScrollPosition = _scrollController.position.pixels;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final defaultHighlighter = ref.watch(P.mdRender.highlighters(P.mdRender.defaultCodeLanguage));
    final defaultDarkHighlighter = ref.watch(P.mdRender.darkHighlighters(P.mdRender.defaultCodeLanguage));

    final highlighter = ref.watch(P.mdRender.highlighters(widget.name));
    final darkHighlighter = ref.watch(P.mdRender.darkHighlighters(widget.name));

    final dark = ref.watch(P.app.dark);

    late final Highlighter? _highlighter;

    if (dark) {
      _highlighter = darkHighlighter ?? defaultDarkHighlighter;
    } else {
      _highlighter = highlighter ?? defaultHighlighter;
    }

    late final TextSpan highlightedCode;

    if (_highlighter != null) {
      highlightedCode = _highlighter.highlight(widget.code.trim());
    } else {
      highlightedCode = TextSpan(text: widget.code.trim());
    }

    final qb = ref.watch(P.app.qb);
    final codeBlockBackgroundColor = switch (appTheme) {
      .light => qb.q(.04),
      .dim => qb.q(.08),
      .lightsOut => qb.q(.1),
    };

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return Container(
      decoration: BoxDecoration(
        color: codeBlockBackgroundColor,
        borderRadius: .circular(8),
      ),
      padding: const .only(left: 0, right: 0, top: 4, bottom: 4),
      margin: const .only(bottom: 4, top: 4),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              const SizedBox(width: 8),
              Text(
                widget.name,
                style: TS(s: 14, w: .w500, c: qb.q(.5)),
              ),
              const Spacer(),
              IconButton(
                onPressed: _onCopyPressed,
                icon: const Icon(Symbols.content_copy),
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
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: .5,
            color: theme.dividerColor.q(appTheme.isLight ? .35 : .6),
          ),
          const SizedBox(height: 4),
          NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const .only(left: 8, right: 8),
              child: Text.rich(
                highlightedCode,
                style: TextStyle(
                  fontFamily: monospaceFF,
                  fontFamilyFallback: P.mdRender.codeFontFamilyFallback,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
