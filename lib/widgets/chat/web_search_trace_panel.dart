import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/func/web_search_report.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/web_search_trace.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

class WebSearchTracePanel extends ConsumerWidget {
  static const String panelKey = 'WebSearchTracePanel';

  final int messageId;
  final WebSearchTrace trace;
  final ScrollController scrollController;
  final bool responseOnly;

  const WebSearchTracePanel({
    super.key,
    required this.messageId,
    required this.trace,
    required this.scrollController,
    this.responseOnly = false,
  });

  static Future<void> show({required int messageId, required WebSearchTrace trace, bool responseOnly = false}) async {
    await P.ui.showPanel(
      key: responseOnly ? '$panelKey.response' : panelKey,
      initialChildSize: .82,
      maxChildSize: .93,
      builder: (scrollController) => WebSearchTracePanel(
        messageId: messageId,
        trace: trace,
        scrollController: scrollController,
        responseOnly: responseOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = S.of(context);
    final message = ref.watch(P.msg.pool.select((pool) => pool[messageId]));
    final redactions = ref.watch(P.chat.webSearchApiKeys).values;
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final sections = webSearchReportSections(
      trace: message == null ? trace : webSearchTraceForReport(message.reference),
      strings: strings,
      modelOutput: message?.content,
      generating: message?.changing ?? false,
      paused: message?.paused ?? false,
      redactions: redactions,
    );

    return Theme(
      data: _traceGrayscaleTheme(theme),
      child: ClipRRect(
        borderRadius: const .only(topLeft: .circular(16), topRight: .circular(16)),
        child: Column(
          children: [
            _TracePanelBar(messageId: messageId, canCopy: message != null, responseOnly: responseOnly),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: .only(left: 14, right: 14, top: 14, bottom: 18 + paddingBottom),
                physics: const BouncingScrollPhysics(),
                children: [
                  for (int index = 0; index < sections.length; index++)
                    if (!responseOnly || index == 1)
                      _TraceReportSection(
                        messageId: messageId,
                        index: index,
                        section: sections[index],
                        canCopy: message != null,
                        trace: message == null ? trace : webSearchTraceForReport(message.reference),
                        responseOnly: responseOnly,
                      ),
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
  final int messageId;
  final bool canCopy;
  final bool responseOnly;

  const _TracePanelBar({required this.messageId, required this.canCopy, required this.responseOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      constraints: const BoxConstraints(minHeight: kToolbarHeight - 4),
      padding: const .only(left: 14, right: 4, top: 4),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        border: Border(bottom: BorderSide(color: qb.withValues(alpha: .12), width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.manage_search, color: _traceTextColor(theme)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              responseOnly ? strings.web_search_report_full_response : strings.web_search_report_title,
              style: theme.textTheme.titleMedium?.copyWith(color: _traceTextColor(theme), fontWeight: .w600),
            ),
          ),
          IconButton(
            tooltip: responseOnly ? strings.copy_text : strings.web_search_report_copy_all,
            onPressed: canCopy ? () => P.chat.onCopyWebSearchReport(messageId, section: responseOnly ? 1 : null) : null,
            color: _traceTextColor(theme),
            icon: const Icon(Icons.copy_all),
          ),
          IconButton(
            tooltip: strings.close,
            onPressed: pop,
            icon: Icon(Icons.close, color: _traceTextColor(theme)),
          ),
        ],
      ),
    );
  }
}

class _TraceReportSection extends StatelessWidget {
  final int messageId;
  final int index;
  final WebSearchReportSection section;
  final bool canCopy;
  final WebSearchTrace trace;
  final bool responseOnly;

  const _TraceReportSection({
    required this.messageId,
    required this.index,
    required this.section,
    required this.canCopy,
    required this.trace,
    required this.responseOnly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = S.of(context);

    return Padding(
      padding: const .only(bottom: 20),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleSmall?.copyWith(color: _traceTextColor(theme), fontWeight: .w700),
                ),
              ),
              IconButton(
                tooltip: '${strings.copy_text}: ${section.title}',
                onPressed: canCopy ? () => P.chat.onCopyWebSearchReport(messageId, section: index) : null,
                color: _traceTextColor(theme),
                icon: const Icon(Icons.copy, size: 20),
              ),
            ],
          ),
          if (section.status != null) Text(section.status!, style: theme.textTheme.bodySmall?.copyWith(color: _traceTextColor(theme))),
          const SizedBox(height: 6),
          Container(
            padding: const .all(10),
            decoration: BoxDecoration(
              color: _traceIsDark(theme) ? const Color(0xFF202020) : const Color(0xFFF2F2F2),
              borderRadius: .circular(8),
              border: Border.all(color: _traceIsDark(theme) ? const Color(0xFF444444) : const Color(0xFFD0D0D0), width: 0.5),
            ),
            child: SelectableText(
              section.body,
              maxLines: index == 1 && !responseOnly ? 12 : null,
              style: theme.textTheme.bodySmall?.copyWith(color: _traceTextColor(theme), fontFamily: 'monospace', height: 1.35),
            ),
          ),
          if (index == 1 && !responseOnly && trace.responses.isNotEmpty)
            Align(
              alignment: .centerLeft,
              child: TextButton.icon(
                onPressed: () => WebSearchTracePanel.show(messageId: messageId, trace: trace, responseOnly: true),
                icon: const Icon(Icons.open_in_full, size: 16),
                label: Text(strings.web_search_report_full_response),
              ),
            ),
        ],
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

Color _traceTextColor(ThemeData theme) {
  if (_traceIsDark(theme)) return const Color(0xFFF2F2F2);
  return const Color(0xFF202020);
}
