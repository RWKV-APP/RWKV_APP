// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/custom_widgets/selectable_adapter.dart';
import 'package:gpt_markdown/custom_widgets/unordered_ordered_list.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:zone/func/shortcuts.dart';
import 'package:zone/widgets/alert.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

const int _softBreakStep = 12;
const int _softBreakMinRunLength = 24;
const int _markdownPreprocessCacheLimit = 96;
const int _streamingMarkdownStableBlockTargetChars = 640;
const String _softBreak = "\u200B";
const String _markdownFenceBacktick = "```";
const String _markdownFenceTilde = "~~~";
final RegExp _markdownFenceLineExp = RegExp(r"^(```|~~~)");
final RegExp _streamingTailFullMarkdownLineExp = RegExp(r"^\s{0,3}(#{1,6}(\s|$)|[-*+]\s+|\d+[.)]\s+|>\s+|\|)");
final RegExp _streamingTailInlineCodeExp = RegExp(r"`[^`]+`");
final RegExp _streamingTailLinkExp = RegExp(r"\[[^\]]+\]\([^)]+\)");
final _markdownPreprocessCache = <String, String>{};
const double _kInlineLatexDownwardShift = 1.5;

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
  final double inlineLatexVerticalPaddingFactor;

  const MarkdownRender({
    super.key,
    required this.raw,
    this.color,
    this.useMessageLineHeight = false,
    this.inlineLatexVerticalPaddingFactor = 0,
  });

  void _onTapLink(String? href, String title) async {
    if (href == null) return;
    await launchUrl(Uri.parse(href));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final primary = theme.colorScheme.primary;
    const scale = Config.msgFontScale;
    final textScaleFactor = textScaler.scale(1.0);
    final effectiveScale = scale * textScaleFactor;
    final qb = ref.watch(P.app.qb);
    final renderMarkdownAndLatexEnabled = ref.watch(P.preference.renderMarkdownAndLatexEnabled);
    final effectiveMessageLineHeight = ref.watch(P.preference.effectiveMessageLineHeight);
    final messageLineHeight = useMessageLineHeight ? effectiveMessageLineHeight : null;
    final gptMarkdownStyle = TextStyle(
      color: color ?? qb,
      fontSize: Config.markdownBodyFontSize * effectiveScale,
      height: messageLineHeight,
    );

    if (!renderMarkdownAndLatexEnabled) {
      return SelectableText(
        raw,
        style: gptMarkdownStyle,
        textScaler: .noScaling,
      );
    }

    final breakableRaw = _prepareMarkdownRaw(raw);

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
        inlineLatexVerticalPaddingFactor: inlineLatexVerticalPaddingFactor,
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
      tableBuilder: (context, tableRows, textStyle, config) => _MarkdownTable(
        tableRows: tableRows,
        config: config,
      ),
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

class StreamingMarkdownSplit {
  final List<String> stableBlocks;
  final String tail;

  const StreamingMarkdownSplit({
    required this.stableBlocks,
    required this.tail,
  });
}

class StreamingMarkdownRender extends ConsumerStatefulWidget {
  final String raw;
  final Color? color;
  final bool streaming;
  final bool useMessageLineHeight;
  final double inlineLatexVerticalPaddingFactor;
  final bool debugTintStableBlocks;
  final Color debugStableBlockTint;

  const StreamingMarkdownRender({
    super.key,
    required this.raw,
    required this.streaming,
    this.color,
    this.useMessageLineHeight = false,
    this.inlineLatexVerticalPaddingFactor = 0,
    this.debugTintStableBlocks = false,
    this.debugStableBlockTint = Colors.transparent,
  });

  @override
  ConsumerState<StreamingMarkdownRender> createState() => _StreamingMarkdownRenderState();
}

class _StreamingMarkdownRenderState extends ConsumerState<StreamingMarkdownRender> {
  final _stableBlockCache = <_StreamingMarkdownStableBlockCacheEntry>[];

  @override
  void didUpdateWidget(covariant StreamingMarkdownRender oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streaming == widget.streaming) return;
    if (widget.streaming) return;
    _clearStableCache();
  }

  void _clearStableCache() {
    _stableBlockCache.clear();
  }

  List<Widget> _stableMarkdownBlockWidgets(List<String> rawBlocks) {
    _trimStableBlockCache(rawBlocks.length);
    final widgets = <Widget>[];
    for (int i = 0; i < rawBlocks.length; i++) {
      widgets.add(
        _stableMarkdownBlockWidget(
          index: i,
          raw: rawBlocks[i],
        ),
      );
    }
    return widgets;
  }

  void _trimStableBlockCache(int count) {
    if (_stableBlockCache.length <= count) return;
    _stableBlockCache.removeRange(count, _stableBlockCache.length);
  }

  Widget _stableMarkdownBlockWidget({
    required int index,
    required String raw,
  }) {
    if (index < _stableBlockCache.length) {
      final cached = _stableBlockCache[index];
      if (cached.matches(
        raw: raw,
        color: widget.color,
        useMessageLineHeight: widget.useMessageLineHeight,
        inlineLatexVerticalPaddingFactor: widget.inlineLatexVerticalPaddingFactor,
        debugTintStableBlocks: widget.debugTintStableBlocks,
        debugStableBlockTint: widget.debugStableBlockTint,
      )) {
        return cached.widget;
      }
    }

    final markdown = MarkdownRender(
      raw: raw,
      color: widget.color,
      useMessageLineHeight: widget.useMessageLineHeight,
      inlineLatexVerticalPaddingFactor: widget.inlineLatexVerticalPaddingFactor,
    );

    final cached = _StreamingMarkdownStableBlockCacheEntry(
      raw: raw,
      color: widget.color,
      useMessageLineHeight: widget.useMessageLineHeight,
      inlineLatexVerticalPaddingFactor: widget.inlineLatexVerticalPaddingFactor,
      debugTintStableBlocks: widget.debugTintStableBlocks,
      debugStableBlockTint: widget.debugStableBlockTint,
      widget: _debugTintStableMarkdown(markdown),
    );
    if (index < _stableBlockCache.length) {
      _stableBlockCache[index] = cached;
      return cached.widget;
    }
    _stableBlockCache.add(cached);
    return cached.widget;
  }

  Widget _debugTintStableMarkdown(Widget child) {
    if (!kDebugMode) return child;
    if (!widget.debugTintStableBlocks) return child;
    return ColoredBox(
      color: widget.debugStableBlockTint,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    if (!widget.streaming) {
      return MarkdownRender(
        raw: widget.raw,
        color: widget.color,
        useMessageLineHeight: widget.useMessageLineHeight,
        inlineLatexVerticalPaddingFactor: widget.inlineLatexVerticalPaddingFactor,
      );
    }

    final split = splitStreamingMarkdown(widget.raw);
    if (split.stableBlocks.isEmpty) {
      return _StreamingMarkdownTail(
        raw: split.tail,
        color: widget.color,
        useMessageLineHeight: widget.useMessageLineHeight,
        inlineLatexVerticalPaddingFactor: widget.inlineLatexVerticalPaddingFactor,
      );
    }

    final children = _stableMarkdownBlockWidgets(split.stableBlocks);
    if (split.tail.isNotEmpty) {
      children.add(
        _StreamingMarkdownTail(
          raw: split.tail,
          color: widget.color,
          useMessageLineHeight: widget.useMessageLineHeight,
          inlineLatexVerticalPaddingFactor: widget.inlineLatexVerticalPaddingFactor,
        ),
      );
    }

    if (children.length == 1) return children.first;

    return Column(
      crossAxisAlignment: .stretch,
      children: children,
    );
  }
}

class _StreamingMarkdownStableBlockCacheEntry {
  final String raw;
  final Color? color;
  final bool useMessageLineHeight;
  final double inlineLatexVerticalPaddingFactor;
  final bool debugTintStableBlocks;
  final Color debugStableBlockTint;
  final Widget widget;

  const _StreamingMarkdownStableBlockCacheEntry({
    required this.raw,
    required this.color,
    required this.useMessageLineHeight,
    required this.inlineLatexVerticalPaddingFactor,
    required this.debugTintStableBlocks,
    required this.debugStableBlockTint,
    required this.widget,
  });

  bool matches({
    required String raw,
    required Color? color,
    required bool useMessageLineHeight,
    required double inlineLatexVerticalPaddingFactor,
    required bool debugTintStableBlocks,
    required Color debugStableBlockTint,
  }) {
    if (this.raw != raw) return false;
    if (this.color != color) return false;
    if (this.useMessageLineHeight != useMessageLineHeight) return false;
    if (this.inlineLatexVerticalPaddingFactor != inlineLatexVerticalPaddingFactor) return false;
    if (this.debugTintStableBlocks != debugTintStableBlocks) return false;
    return this.debugStableBlockTint == debugStableBlockTint;
  }
}

class _StreamingMarkdownTail extends ConsumerWidget {
  final String raw;
  final Color? color;
  final bool useMessageLineHeight;
  final double inlineLatexVerticalPaddingFactor;

  const _StreamingMarkdownTail({
    required this.raw,
    required this.color,
    required this.useMessageLineHeight,
    required this.inlineLatexVerticalPaddingFactor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;

    if (raw.isEmpty) return const SizedBox.shrink();

    final renderMarkdownAndLatexEnabled = ref.watch(P.preference.renderMarkdownAndLatexEnabled);
    if (renderMarkdownAndLatexEnabled && shouldRenderStreamingMarkdownTailAsFullMarkdown(raw)) {
      return MarkdownRender(
        raw: raw,
        color: color,
        useMessageLineHeight: useMessageLineHeight,
        inlineLatexVerticalPaddingFactor: inlineLatexVerticalPaddingFactor,
      );
    }

    final textScaler = MediaQuery.textScalerOf(context);
    const scale = Config.msgFontScale;
    final textScaleFactor = textScaler.scale(1.0);
    final effectiveScale = scale * textScaleFactor;
    final qb = ref.watch(P.app.qb);
    final effectiveMessageLineHeight = ref.watch(P.preference.effectiveMessageLineHeight);
    final messageLineHeight = useMessageLineHeight ? effectiveMessageLineHeight : null;

    return Text(
      raw,
      style: TextStyle(
        color: color ?? qb,
        fontSize: Config.markdownBodyFontSize * effectiveScale,
        height: messageLineHeight,
      ),
      textScaler: .noScaling,
    );
  }
}

StreamingMarkdownSplit splitStreamingMarkdown(String raw) {
  if (raw.isEmpty) return const StreamingMarkdownSplit(stableBlocks: <String>[], tail: "");

  final boundaries = _stableStreamingMarkdownBoundaries(raw);
  if (boundaries.isEmpty) {
    return StreamingMarkdownSplit(stableBlocks: const <String>[], tail: raw);
  }

  final stableEnd = boundaries.last.offset;
  if (stableEnd <= 0) {
    return StreamingMarkdownSplit(stableBlocks: const <String>[], tail: raw);
  }
  return StreamingMarkdownSplit(
    stableBlocks: _stableStreamingMarkdownBlocks(
      raw: raw,
      boundaries: boundaries,
      stableEnd: stableEnd,
    ),
    tail: stableEnd >= raw.length ? "" : raw.substring(stableEnd),
  );
}

List<String> _stableStreamingMarkdownBlocks({
  required String raw,
  required List<({int offset, bool hard})> boundaries,
  required int stableEnd,
}) {
  final blocks = <String>[];
  int blockStart = 0;

  for (final boundary in boundaries) {
    if (boundary.offset > stableEnd) break;
    if (boundary.offset <= blockStart) continue;

    final shouldCloseBlock =
        boundary.hard || boundary.offset - blockStart >= _streamingMarkdownStableBlockTargetChars || boundary.offset >= stableEnd;
    if (!shouldCloseBlock) continue;

    blocks.add(raw.substring(blockStart, boundary.offset));
    blockStart = boundary.offset;
  }

  if (blockStart < stableEnd) {
    blocks.add(raw.substring(blockStart, stableEnd));
  }
  if (blocks.isNotEmpty) return blocks;
  return <String>[raw.substring(0, stableEnd)];
}

List<({int offset, bool hard})> _stableStreamingMarkdownBoundaries(String raw) {
  final boundaries = <({int offset, bool hard})>[];
  bool insideFence = false;
  String fenceMarker = "";
  bool insideDisplayLatex = false;
  bool insideDollarLatex = false;
  bool previousLineWasTable = false;
  int lineStart = 0;

  while (lineStart < raw.length) {
    int lineEnd = raw.indexOf("\n", lineStart);
    if (lineEnd == -1) lineEnd = raw.length;

    final line = raw.substring(lineStart, lineEnd);
    final trimmedLine = line.trim();
    final hasTrailingNewline = lineEnd < raw.length;
    final lineBoundary = lineEnd < raw.length ? lineEnd + 1 : lineEnd;

    final fenceBoundary = _resolveStreamingFenceBoundary(
      trimmedLine: trimmedLine,
      lineBoundary: lineBoundary,
      insideFence: insideFence,
      fenceMarker: fenceMarker,
    );
    if (fenceBoundary != null) {
      insideFence = fenceBoundary.insideFence;
      fenceMarker = fenceBoundary.fenceMarker;
      final lastSafeBoundary = fenceBoundary.lastSafeBoundary;
      if (lastSafeBoundary != null) {
        _addStableStreamingMarkdownBoundary(
          boundaries: boundaries,
          offset: lastSafeBoundary,
          hard: true,
        );
      }
      lineStart = lineBoundary;
      continue;
    }

    if (insideFence) {
      lineStart = lineBoundary;
      continue;
    }

    final latexBoundary = _resolveStreamingLatexBoundary(
      trimmedLine: trimmedLine,
      lineBoundary: lineBoundary,
      insideDisplayLatex: insideDisplayLatex,
      insideDollarLatex: insideDollarLatex,
    );
    insideDisplayLatex = latexBoundary.insideDisplayLatex;
    insideDollarLatex = latexBoundary.insideDollarLatex;
    if (latexBoundary.handled) {
      final lastSafeBoundary = latexBoundary.lastSafeBoundary;
      if (lastSafeBoundary != null) {
        _addStableStreamingMarkdownBoundary(
          boundaries: boundaries,
          offset: lastSafeBoundary,
          hard: true,
        );
      }
      lineStart = lineBoundary;
      continue;
    }

    if (trimmedLine.isEmpty) {
      previousLineWasTable = false;
      _addStableStreamingMarkdownBoundary(
        boundaries: boundaries,
        offset: lineBoundary,
        hard: true,
      );
      lineStart = lineBoundary;
      continue;
    }

    final isTableLine = _isStreamingMarkdownTableLine(trimmedLine);
    if (isTableLine) {
      previousLineWasTable = true;
      lineStart = lineBoundary;
      continue;
    }

    if (previousLineWasTable) {
      previousLineWasTable = false;
      _addStableStreamingMarkdownBoundary(
        boundaries: boundaries,
        offset: lineStart,
        hard: true,
      );
    }

    if (hasTrailingNewline) {
      _addStableStreamingMarkdownBoundary(
        boundaries: boundaries,
        offset: lineBoundary,
        hard: false,
      );
    }
    lineStart = lineBoundary;
  }

  return boundaries;
}

void _addStableStreamingMarkdownBoundary({
  required List<({int offset, bool hard})> boundaries,
  required int offset,
  required bool hard,
}) {
  if (offset <= 0) return;
  if (boundaries.isEmpty) {
    boundaries.add((offset: offset, hard: hard));
    return;
  }

  final last = boundaries.last;
  if (last.offset != offset) {
    boundaries.add((offset: offset, hard: hard));
    return;
  }

  if (!hard || last.hard) return;
  boundaries[boundaries.length - 1] = (offset: offset, hard: true);
}

({bool insideFence, String fenceMarker, int? lastSafeBoundary})? _resolveStreamingFenceBoundary({
  required String trimmedLine,
  required int lineBoundary,
  required bool insideFence,
  required String fenceMarker,
}) {
  if (!_markdownFenceLineExp.hasMatch(trimmedLine)) return null;
  if (!insideFence) {
    final marker = trimmedLine.startsWith(_markdownFenceTilde) ? _markdownFenceTilde : _markdownFenceBacktick;
    return (insideFence: true, fenceMarker: marker, lastSafeBoundary: null);
  }

  if (!trimmedLine.startsWith(fenceMarker)) {
    return (insideFence: insideFence, fenceMarker: fenceMarker, lastSafeBoundary: null);
  }

  return (insideFence: false, fenceMarker: "", lastSafeBoundary: lineBoundary);
}

({bool handled, bool insideDisplayLatex, bool insideDollarLatex, int? lastSafeBoundary}) _resolveStreamingLatexBoundary({
  required String trimmedLine,
  required int lineBoundary,
  required bool insideDisplayLatex,
  required bool insideDollarLatex,
}) {
  if (insideDisplayLatex) {
    final closed = trimmedLine.endsWith(r"\]");
    return (
      handled: true,
      insideDisplayLatex: !closed,
      insideDollarLatex: insideDollarLatex,
      lastSafeBoundary: closed ? lineBoundary : null,
    );
  }

  if (insideDollarLatex) {
    final closed = trimmedLine.endsWith(r"$$");
    return (
      handled: true,
      insideDisplayLatex: insideDisplayLatex,
      insideDollarLatex: !closed,
      lastSafeBoundary: closed ? lineBoundary : null,
    );
  }

  if (trimmedLine.startsWith(r"\[") && !trimmedLine.endsWith(r"\]")) {
    return (
      handled: true,
      insideDisplayLatex: true,
      insideDollarLatex: false,
      lastSafeBoundary: null,
    );
  }

  if (trimmedLine.startsWith(r"\[") && trimmedLine.endsWith(r"\]")) {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: false,
      lastSafeBoundary: lineBoundary,
    );
  }

  if (trimmedLine.startsWith(r"$$") && !trimmedLine.endsWith(r"$$")) {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: true,
      lastSafeBoundary: null,
    );
  }

  if (trimmedLine == r"$$") {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: true,
      lastSafeBoundary: null,
    );
  }

  if (trimmedLine.startsWith(r"$$") && trimmedLine.endsWith(r"$$") && trimmedLine.length > 2) {
    return (
      handled: true,
      insideDisplayLatex: false,
      insideDollarLatex: false,
      lastSafeBoundary: lineBoundary,
    );
  }

  return (
    handled: false,
    insideDisplayLatex: false,
    insideDollarLatex: false,
    lastSafeBoundary: null,
  );
}

bool _isStreamingMarkdownTableLine(String line) {
  if (!line.contains("|")) return false;
  final cells = line.split("|");
  if (cells.length < 3) return false;
  return true;
}

bool shouldRenderStreamingMarkdownTailAsFullMarkdown(String raw) {
  if (raw.isEmpty) return false;
  if (_hasUnclosedStreamingMarkdownFence(raw)) return false;
  if (_hasUnclosedStreamingDisplayLatex(raw)) return false;

  final trimmed = raw.trimLeft();
  if (trimmed.isEmpty) return false;
  if (_streamingTailFullMarkdownLineExp.hasMatch(trimmed)) return true;
  if (_streamingTailInlineCodeExp.hasMatch(trimmed)) return true;
  if (_streamingTailLinkExp.hasMatch(trimmed)) return true;
  if (trimmed.contains(r"\(")) return true;
  if (trimmed.contains(r"\)")) return true;
  if (trimmed.contains(r"\[")) return true;
  if (trimmed.contains(r"\]")) return true;
  if (trimmed.contains("<br")) return true;
  return trimmed.contains("<BR");
}

bool _hasUnclosedStreamingMarkdownFence(String raw) {
  bool insideFence = false;
  String fenceMarker = "";
  final lines = raw.split("\n");

  for (final line in lines) {
    final trimmedLine = line.trim();
    if (!_markdownFenceLineExp.hasMatch(trimmedLine)) continue;

    if (!insideFence) {
      insideFence = true;
      fenceMarker = trimmedLine.startsWith(_markdownFenceTilde) ? _markdownFenceTilde : _markdownFenceBacktick;
      continue;
    }

    if (!trimmedLine.startsWith(fenceMarker)) continue;
    insideFence = false;
    fenceMarker = "";
  }

  return insideFence;
}

bool _hasUnclosedStreamingDisplayLatex(String raw) {
  bool insideDisplayLatex = false;
  bool insideDollarLatex = false;
  final lines = raw.split("\n");

  for (final line in lines) {
    final trimmedLine = line.trim();

    if (insideDisplayLatex) {
      if (trimmedLine.endsWith(r"\]")) insideDisplayLatex = false;
      continue;
    }

    if (insideDollarLatex) {
      if (trimmedLine.endsWith(r"$$")) insideDollarLatex = false;
      continue;
    }

    if (trimmedLine.startsWith(r"\[") && !trimmedLine.endsWith(r"\]")) {
      insideDisplayLatex = true;
      continue;
    }

    if (trimmedLine == r"$$") {
      insideDollarLatex = true;
      continue;
    }

    if (trimmedLine.startsWith(r"$$") && !trimmedLine.endsWith(r"$$")) {
      insideDollarLatex = true;
    }
  }

  return insideDisplayLatex || insideDollarLatex;
}

ScrollController? _findParentHorizontalScrollController(BuildContext context) {
  ScrollController? parentController;
  context.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is! Scrollable) return true;
    final controller = widget.controller;
    if (controller == null) return true;
    if (!controller.hasClients) return true;
    final position = controller.position;
    if (position.axis != Axis.horizontal) return true;
    parentController = controller;
    return false;
  });
  return parentController;
}

class _ForwardingHorizontalScrollView extends StatefulWidget {
  final Widget child;

  const _ForwardingHorizontalScrollView({
    required this.child,
  });

  @override
  State<_ForwardingHorizontalScrollView> createState() => _ForwardingHorizontalScrollViewState();
}

class _ForwardingHorizontalScrollViewState extends State<_ForwardingHorizontalScrollView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification is! OverscrollNotification) return false;
    final parentController = _findParentHorizontalScrollController(context);
    if (parentController == null) return false;
    if (!parentController.hasClients) return false;
    final parentPosition = parentController.position;
    final newOffset = (parentPosition.pixels + notification.overscroll).clamp(
      parentPosition.minScrollExtent,
      parentPosition.maxScrollExtent,
    );
    if (newOffset == parentPosition.pixels) return false;
    parentController.jumpTo(newOffset);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: widget.child,
        ),
      ),
    );
  }
}

class _MarkdownTable extends StatelessWidget {
  final List<CustomTableRow> tableRows;
  final GptMarkdownConfig config;

  const _MarkdownTable({
    required this.tableRows,
    required this.config,
  });

  TableCellVerticalAlignment get _defaultVerticalAlignment {
    return TableCellVerticalAlignment.middle;
  }

  Widget _buildCell(BuildContext context, CustomTableField field) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: MdWidget(
        context,
        field.data.trim(),
        false,
        config: config,
      ),
    );

    switch (field.alignment) {
      case TextAlign.center:
        content = Center(child: content);
        break;
      case TextAlign.right:
        content = Align(
          alignment: Alignment.centerRight,
          child: content,
        );
        break;
      case TextAlign.left:
      default:
        content = Align(
          alignment: Alignment.centerLeft,
          child: content,
        );
        break;
    }

    return content;
  }

  TableRow _buildRow(BuildContext context, CustomTableRow row) {
    final theme = Theme.of(context);
    return TableRow(
      decoration: row.isHeader
          ? BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            )
          : null,
      children: [
        for (final field in row.fields) _buildCell(context, field),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ForwardingHorizontalScrollView(
      child: Table(
        textDirection: config.textDirection,
        defaultColumnWidth: CustomTableColumnWidth(),
        defaultVerticalAlignment: _defaultVerticalAlignment,
        border: TableBorder.all(
          width: 1,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          for (final row in tableRows) _buildRow(context, row),
        ],
      ),
    );
  }
}

class _LatexRender extends StatelessWidget {
  final String tex;
  final TextStyle textStyle;
  final bool inline;
  final double inlineLatexVerticalPaddingFactor;

  const _LatexRender({
    required this.tex,
    required this.textStyle,
    required this.inline,
    required this.inlineLatexVerticalPaddingFactor,
  });

  double _resolveInlineVerticalPadding(BuildContext context, TextStyle effectiveTextStyle) {
    if (!inline) return 0;
    if (inlineLatexVerticalPaddingFactor <= 0) return 0;

    final theme = Theme.of(context);
    final fontSize = effectiveTextStyle.fontSize ?? theme.textTheme.bodyMedium?.fontSize ?? Config.markdownBodyFontSize;
    final padding = fontSize * inlineLatexVerticalPaddingFactor;

    if (padding < 1) return 1;
    if (padding > 4) return 4;
    return padding;
  }

  double _resolveAlphabeticBaseline(BuildContext context, TextStyle effectiveTextStyle, double inlineVerticalPadding) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: "x",
        style: effectiveTextStyle,
      ),
      textDirection: Directionality.of(context),
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();

    final theme = Theme.of(context);
    final fallbackFontSize = effectiveTextStyle.fontSize ?? theme.textTheme.bodyMedium?.fontSize ?? Config.markdownBodyFontSize;
    final textBaseline = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final downwardShift = inlineLatexVerticalPaddingFactor > 0 ? _kInlineLatexDownwardShift : 0.0;
    if (textBaseline <= 0) {
      final fallbackBaseline = fallbackFontSize * .8 + inlineVerticalPadding - downwardShift;
      if (fallbackBaseline < 1) return 1;
      return fallbackBaseline;
    }

    final shiftedBaseline = textBaseline + inlineVerticalPadding - downwardShift;
    if (shiftedBaseline < 1) return 1;
    return shiftedBaseline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle.copyWith(
      color: textStyle.color ?? theme.colorScheme.onSurface,
    );
    final effectiveColor = effectiveTextStyle.color ?? theme.colorScheme.onSurface;
    final mathStyle = inline ? MathStyle.text : MathStyle.display;
    final inlineVerticalPadding = _resolveInlineVerticalPadding(context, effectiveTextStyle);
    final alphabeticBaseline = _resolveAlphabeticBaseline(
      context,
      effectiveTextStyle,
      inlineVerticalPadding,
    );

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
                fontWeight: effectiveTextStyle.fontWeight ?? .normal,
                fontShape: FontStyle.normal,
              ),
              textFontOptions: FontOptions(
                fontFamily: "Main",
                fontWeight: effectiveTextStyle.fontWeight ?? .normal,
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

          final Widget scrollChild;
          if (!constraints.hasBoundedWidth) {
            scrollChild = math;
          } else {
            scrollChild = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: math,
            );
          }

          Widget child = scrollChild;
          if (inlineVerticalPadding > 0) {
            child = Padding(
              padding: EdgeInsets.symmetric(vertical: inlineVerticalPadding),
              child: child,
            );
          }

          if (!inline) {
            return child;
          }

          return _InlineLatexBaselineProxy(
            baseline: alphabeticBaseline,
            child: child,
          );
        },
      ),
    );
  }
}

class _InlineLatexBaselineProxy extends SingleChildRenderObjectWidget {
  final double baseline;

  const _InlineLatexBaselineProxy({
    required this.baseline,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderInlineLatexBaselineProxy(baseline: baseline);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final proxy = renderObject as _RenderInlineLatexBaselineProxy;
    proxy.baseline = baseline;
  }
}

class _RenderInlineLatexBaselineProxy extends RenderProxyBox {
  _RenderInlineLatexBaselineProxy({
    required this._baseline,
  });

  double _baseline;

  set baseline(double value) {
    if (_baseline == value) return;
    _baseline = value;
    markNeedsLayout();
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    if (baseline != TextBaseline.alphabetic) {
      return super.computeDistanceToActualBaseline(baseline);
    }
    return _baseline;
  }

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    if (baseline != TextBaseline.alphabetic) {
      return super.computeDryBaseline(constraints, baseline);
    }
    return _baseline;
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
