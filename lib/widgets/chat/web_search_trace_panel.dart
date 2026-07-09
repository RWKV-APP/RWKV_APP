// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/model/web_search_trace.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

class WebSearchTracePanel extends ConsumerWidget {
  static const String panelKey = 'WebSearchTracePanel';

  final WebSearchTrace trace;
  final ScrollController scrollController;

  const WebSearchTracePanel._({
    required this.trace,
    required this.scrollController,
  });

  static Future<void> show(WebSearchTrace trace) async {
    await P.ui.showPanel(
      key: panelKey,
      initialChildSize: .82,
      maxChildSize: .93,
      builder: (scrollController) {
        return WebSearchTracePanel._(
          trace: trace,
          scrollController: scrollController,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final grayscaleTheme = _traceGrayscaleTheme(theme);
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    final strings = _TraceStrings(currentLangIsZh);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return Theme(
      data: grayscaleTheme,
      child: ClipRRect(
        borderRadius: const .only(
          topLeft: .circular(16),
          topRight: .circular(16),
        ),
        child: Column(
          children: [
            _TracePanelBar(title: strings.title),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: .only(left: 14, right: 14, bottom: 18 + paddingBottom),
                physics: const BouncingScrollPhysics(),
                children: [
                  _TraceOverview(trace: trace, strings: strings),
                  _TraceSectionTitle(title: strings.steps),
                  _TraceSteps(steps: trace.steps),
                  _TraceSectionTitle(title: strings.pages),
                  _TraceSources(
                    sources: trace.sources,
                    emptyText: strings.noPages,
                  ),
                  _TraceSectionTitle(title: strings.referenceData),
                  _TraceTextBlock(
                    text: trace.promptContext,
                    emptyText: strings.noReferenceData,
                  ),
                  _TraceSectionTitle(title: strings.finalPrompt),
                  _TraceTextBlock(
                    text: trace.finalPrompt,
                    emptyText: strings.noPrompt,
                  ),
                  if (trace.error.isNotEmpty) ...[
                    _TraceSectionTitle(title: strings.error),
                    _TraceTextBlock(text: trace.error, emptyText: ''),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TracePanelBar extends ConsumerWidget {
  final String title;

  const _TracePanelBar({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      constraints: const BoxConstraints(minHeight: kToolbarHeight - 4),
      padding: const .only(left: 14, right: 4, top: 4),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        border: Border(
          bottom: BorderSide(color: qb.withValues(alpha: .12), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.manage_search, color: _traceTextColor(theme)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _traceTextColor(theme),
                fontWeight: .w600,
              ),
            ),
          ),
          IconButton(
            onPressed: pop,
            icon: Icon(Icons.close, color: _traceTextColor(theme)),
          ),
        ],
      ),
    );
  }
}

class _TraceOverview extends StatelessWidget {
  final WebSearchTrace trace;
  final _TraceStrings strings;

  const _TraceOverview({required this.trace, required this.strings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const .only(top: 14, bottom: 8),
      padding: const .all(12),
      decoration: BoxDecoration(
        color: _traceOverviewColor(theme),
        borderRadius: .circular(8),
        border: Border.all(color: _traceBorderColor(theme), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _TraceKeyValue(label: strings.provider, value: trace.searchProvider),
          _TraceKeyValue(label: strings.searchEngine, value: trace.searchEngineLabel),
          _TraceKeyValue(label: strings.userQuery, value: trace.userQuery),
          _TraceKeyValue(label: strings.generatedQuery, value: trace.query),
          _TraceKeyValue(label: strings.searchUrl, value: trace.searchUrl),
          _TraceKeyValue(label: strings.parsedPageUrl, value: trace.pageUrl),
          _TraceKeyValue(label: strings.parsedPageTitle, value: trace.pageTitle),
          _TraceKeyValue(
            label: strings.counts,
            value: '${trace.sources.length}/${trace.sourceLimit} ${strings.kept}, ${trace.extractedItemCount} ${strings.parsed}',
          ),
        ],
      ),
    );
  }
}

class _TraceKeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _TraceKeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _traceDisplayText(value);

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _traceMutedTextColor(theme),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _traceTextColor(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceSectionTitle extends StatelessWidget {
  final String title;

  const _TraceSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const .only(top: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: _traceTextColor(theme),
          fontWeight: .w700,
        ),
      ),
    );
  }
}

class _TraceSteps extends StatelessWidget {
  final List<WebSearchTraceStep> steps;

  const _TraceSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;
    if (steps.isEmpty) return const _TraceEmptyText(text: '-');

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (int i = 0; i < steps.length; i += 1) _TraceStepItem(index: i + 1, step: steps[i]),
      ],
    );
  }
}

class _TraceStepItem extends StatelessWidget {
  final int index;
  final WebSearchTraceStep step;

  const _TraceStepItem({
    required this.index,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawTitle = step.title.trim().isEmpty ? 'Step $index' : step.title;
    final title = _traceDisplayText(rawTitle);
    final detail = _traceDisplayText(step.detail);

    return Container(
      margin: const .only(bottom: 8),
      padding: const .all(10),
      decoration: BoxDecoration(
        color: _traceItemColor(theme),
        borderRadius: .circular(8),
        border: Border.all(color: _traceBorderColor(theme), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: .center,
            decoration: BoxDecoration(
              shape: .circle,
              color: _traceBadgeColor(theme),
            ),
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: _traceBadgeTextColor(theme),
                fontWeight: .w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _traceTextColor(theme),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _traceMutedTextColor(theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceSources extends StatelessWidget {
  final List<WebSearchTraceSource> sources;
  final String emptyText;

  const _TraceSources({required this.sources, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;
    if (sources.isEmpty) return _TraceEmptyText(text: emptyText);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final source in sources) _TraceSourceItem(source: source),
      ],
    );
  }
}

class _TraceSourceItem extends StatelessWidget {
  final WebSearchTraceSource source;

  const _TraceSourceItem({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const .only(bottom: 8),
      padding: const .all(10),
      decoration: BoxDecoration(
        color: _traceItemColor(theme),
        borderRadius: .circular(8),
        border: Border.all(color: _traceBorderColor(theme), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            crossAxisAlignment: .start,
            children: [
              Text(
                '#${source.rank}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _traceTextColor(theme),
                  fontWeight: .w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  _traceDisplayText(source.title),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _traceTextColor(theme),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            _traceDisplayText(source.url),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _traceTextColor(theme),
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            _traceDisplayText(source.summary),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _traceMutedTextColor(theme),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceTextBlock extends StatelessWidget {
  final String text;
  final String emptyText;

  const _TraceTextBlock({required this.text, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = _traceDisplayText(text.trim().isEmpty ? emptyText : text);
    if (displayText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const .all(10),
      decoration: BoxDecoration(
        color: _traceItemColor(theme),
        borderRadius: .circular(8),
        border: Border.all(color: _traceBorderColor(theme), width: 0.5),
      ),
      child: SelectableText(
        displayText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: _traceTextColor(theme),
          fontFamily: 'monospace',
          height: 1.35,
        ),
      ),
    );
  }
}

class _TraceEmptyText extends StatelessWidget {
  final String text;

  const _TraceEmptyText({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: _traceMutedTextColor(theme),
      ),
    );
  }
}

bool _traceIsDark(ThemeData theme) => theme.brightness == Brightness.dark;

ThemeData _traceGrayscaleTheme(ThemeData theme) {
  final scheme = _traceGrayscaleScheme(theme.brightness);
  return theme.copyWith(
    colorScheme: scheme,
    disabledColor: _traceIsDark(theme) ? const Color(0xFF777777) : const Color(0xFFB8B8B8),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.onSurface,
    ),
  );
}

ColorScheme _traceGrayscaleScheme(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF808080),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFE8E8E8),
      onPrimary: const Color(0xFF111111),
      primaryContainer: const Color(0xFF3A3A3A),
      onPrimaryContainer: const Color(0xFFF2F2F2),
      surface: const Color(0xFF101010),
      onSurface: const Color(0xFFF0F0F0),
      surfaceContainer: const Color(0xFF252525),
      surfaceContainerLow: const Color(0xFF202020),
      surfaceContainerHighest: const Color(0xFF303030),
      onSurfaceVariant: const Color(0xFFC0C0C0),
      outline: const Color(0xFF707070),
      outlineVariant: const Color(0xFF444444),
      error: const Color(0xFFE0E0E0),
      onError: const Color(0xFF101010),
    );
  }

  return ColorScheme.fromSeed(seedColor: const Color(0xFF808080)).copyWith(
    primary: const Color(0xFF202020),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFE0E0E0),
    onPrimaryContainer: const Color(0xFF202020),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF202020),
    surfaceContainer: const Color(0xFFEEEEEE),
    surfaceContainerLow: const Color(0xFFF2F2F2),
    surfaceContainerHighest: const Color(0xFFE0E0E0),
    onSurfaceVariant: const Color(0xFF666666),
    outline: const Color(0xFF8A8A8A),
    outlineVariant: const Color(0xFFC8C8C8),
    error: const Color(0xFF202020),
    onError: const Color(0xFFFFFFFF),
  );
}

final RegExp _traceColorGlyphPattern = RegExp(
  r'[\u{1F1E6}-\u{1FAFF}\u{2600}-\u{27BF}]',
  unicode: true,
);

String _traceDisplayText(String text) {
  final normalized = text.replaceAll(_traceColorGlyphPattern, '').replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
  if (normalized.isEmpty) return '-';
  return normalized;
}

Color _traceTextColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFFF2F2F2);
  return const Color(0xFF202020);
}

Color _traceMutedTextColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFFB8B8B8);
  return const Color(0xFF666666);
}

Color _traceOverviewColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFF252525);
  return const Color(0xFFEEEEEE);
}

Color _traceItemColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFF202020);
  return const Color(0xFFF2F2F2);
}

Color _traceBorderColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFF444444);
  return const Color(0xFFD0D0D0);
}

Color _traceBadgeColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFF404040);
  return const Color(0xFFE0E0E0);
}

Color _traceBadgeTextColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFFF2F2F2);
  return const Color(0xFF202020);
}

class _TraceStrings {
  final bool zh;

  const _TraceStrings(this.zh);

  String get title => zh ? 'Web Search 运行步骤' : 'Web Search Run Details';
  String get provider => zh ? '搜索来源' : 'Provider';
  String get searchEngine => zh ? 'Search Engine' : 'Search Engine';
  String get userQuery => zh ? '用户输入' : 'User Query';
  String get generatedQuery => zh ? '生成的 Query' : 'Generated Query';
  String get searchUrl => zh ? '搜索 URL' : 'Search URL';
  String get parsedPageUrl => zh ? '解析页面 URL' : 'Parsed Page URL';
  String get parsedPageTitle => zh ? '解析页面标题' : 'Parsed Page Title';
  String get counts => zh ? '结果数量' : 'Counts';
  String get kept => zh ? '已采用' : 'kept';
  String get parsed => zh ? '已解析' : 'parsed';
  String get steps => zh ? '运行步骤' : 'Run Steps';
  String get pages => zh ? '解析到的页面' : 'Parsed Pages';
  String get noPages => zh ? '没有可展示的页面' : 'No pages to show.';
  String get referenceData => zh ? 'Reference Data' : 'Reference Data';
  String get noReferenceData => zh ? '没有 Reference Data' : 'No Reference Data.';
  String get finalPrompt => zh ? '最终 Prompt' : 'Final Prompt';
  String get noPrompt => zh ? '没有可展示的 Prompt' : 'No prompt to show.';
  String get error => zh ? '错误' : 'Error';
}
