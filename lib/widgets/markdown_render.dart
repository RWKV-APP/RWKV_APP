import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart' show OrderedListView;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';


class MarkdownRender extends ConsumerWidget {
  final String raw;
  final Color? color;
  const MarkdownRender({super.key, required this.raw, this.color});

  void _onTapLink(String? href, String title) async {
    if (href == null) return;
    await launchUrl(Uri.parse(href));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const scale = Config.msgFontScale;
    final qb = ref.watch(P.app.qb);
    final gptMarkdownStyle = TextStyle(
      color: color ?? qb,
      fontSize: Config.markdownBodyFontSize * scale,
    );

    final headerFontSizes = Config.markdownHeaderFontSizes.map((e) => e * scale).toList();

    final gptThemeData = GptMarkdownTheme.of(context).copyWith(
      h1: TextStyle(fontSize: headerFontSizes[0], fontWeight: .w500),
      h2: TextStyle(fontSize: headerFontSizes[1], fontWeight: .w500),
      h3: TextStyle(fontSize: headerFontSizes[2], fontWeight: .w500),
      h4: TextStyle(fontSize: headerFontSizes[3]),
      h5: TextStyle(fontSize: headerFontSizes[4]),
      h6: TextStyle(fontSize: headerFontSizes[5]),
      hrHeight: 6,
    );

    final GptMarkdown gptMarkdown = GptMarkdown(
      raw.replaceAll("\n\n", "\n").trim(),
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
      highlightBuilder: (context, text, style) => _Highlight(text: text, style: style),
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

// For inline code highlight
class _Highlight extends ConsumerWidget {
  final String text;
  final TextStyle style;
  const _Highlight({required this.text, required this.style});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(P.app.dark);
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);
    final preferredMonospaceFont = ref.watch(P.preference.preferredMonospaceFont);
    final effectiveMonospaceFont = P.font.getEffectiveMonospaceFont(preferredMonospaceFont);
    return C(
      decoration: BoxDecoration(
        color: dark ? qw.q(.5) : qb.q(.04),
        borderRadius: .circular(6),
        border: Border.all(color: dark ? qb.q(.2) : qb.q(.2)),
      ),
      padding: const .only(left: 4, right: 4, top: 0, bottom: 0),
      child: Text.rich(
        TextSpan(
          text: text,
          style: style.copyWith(
            fontSize: (style.fontSize ?? 14) - 2,
            fontFamily: effectiveMonospaceFont,
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

    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);
    final preferredMonospaceFont = ref.watch(P.preference.preferredMonospaceFont);
    final effectiveMonospaceFont = P.font.getEffectiveMonospaceFont(preferredMonospaceFont);

    return C(
      decoration: BoxDecoration(
        color: dark ? qw.q(.5) : qb.q(.04),
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
              8.w,
              T(
                widget.name,
                s: TS(s: 14, w: .w500, c: qb.q(.5)),
              ),
              const Spacer(),
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
          NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const .only(left: 8, right: 8),
              child: Text.rich(
                highlightedCode,
                style: TextStyle(
                  fontFamily: effectiveMonospaceFont,
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
