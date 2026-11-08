import 'dart:convert';

import 'package:zone/gen/l10n.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/web_search_trace.dart';

typedef WebSearchReportSection = ({String title, String body, String? status});

WebSearchTrace webSearchTraceForReport(RefInfo reference) {
  final trace = reference.trace;
  if (trace != null) return trace;
  return WebSearchTrace.empty().copyWith(
    sources: [
      for (int index = 0; index < reference.list.length; index++)
        WebSearchTraceSource(
          rank: index + 1,
          title: reference.list[index].title,
          url: reference.list[index].url,
          summary: reference.list[index].summary,
          publishedAt: reference.list[index].publishedAt,
        ),
    ],
    error: reference.error,
  );
}

List<WebSearchReportSection> webSearchReportSections({
  required WebSearchTrace trace,
  required S strings,
  String? modelOutput,
  bool generating = false,
  bool paused = false,
  Iterable<String> redactions = const [],
}) {
  final requestStatus = <String>[
    '${strings.web_search_provider}: ${trace.searchProvider}',
    trace.request.isEmpty ? strings.web_search_report_request_missing : trace.request.split('\n\n').first,
    if (trace.error.isNotEmpty) '${strings.web_search_report_error}: ${trace.error}',
  ].join('\n\n');
  final results = trace.responses.isNotEmpty
      ? trace.responses.map((response) => response.body).join('\n\n')
      : [for (final source in trace.sources) '[${source.rank}] ${source.title}\n${source.url}\n${source.summary}'].join('\n\n');
  final resultStatus = trace.responses.isEmpty
      ? strings.web_search_report_response_missing
      : [for (final response in trace.responses) '${response.query}\nHTTP ${response.statusCode}'].join('\n\n');
  final input = _modelInputText(trace, strings);
  final status = modelOutput == null
      ? null
      : [
          generating
              ? strings.web_search_report_output_generating
              : paused
              ? strings.web_search_report_output_paused
              : strings.web_search_report_output_complete,
          if (modelOutput.isEmpty) strings.web_search_report_output_empty,
        ].join('\n');
  final sections = <WebSearchReportSection>[
    (title: strings.web_search_report_request, body: trace.query, status: requestStatus),
    (title: strings.web_search_report_results, body: results, status: resultStatus),
    (
      title: strings.web_search_report_input,
      body: input ?? trace.finalPrompt,
      status: input == null ? strings.web_search_report_input_missing : null,
    ),
    (
      title: strings.web_search_report_output,
      body: modelOutput ?? '',
      status: modelOutput == null ? strings.web_search_report_output_unavailable : status,
    ),
  ];
  return [
    for (final section in sections)
      (
        title: section.title,
        body: redactWebSearchReport(section.body, redactions),
        status: section.status == null ? null : redactWebSearchReport(section.status!, redactions),
      ),
  ];
}

String formatWebSearchReport({
  required WebSearchTrace trace,
  required S strings,
  String? modelOutput,
  bool generating = false,
  bool paused = false,
  Iterable<String> redactions = const [],
  int? section,
}) {
  final sections = webSearchReportSections(
    trace: trace,
    strings: strings,
    modelOutput: modelOutput,
    generating: generating,
    paused: paused,
    redactions: redactions,
  );
  if (section != null) return sections[section].body;
  return [
    for (int index = 0; index < sections.length; index++)
      [
        '## ${sections[index].title}',
        if (sections[index].status != null) sections[index].status!,
        _reportCodeBlock(sections[index].body),
        if (index == 0 && trace.request.isNotEmpty) ...[
          strings.web_search_report_request_details,
          _reportCodeBlock(redactWebSearchReport(trace.request, redactions)),
        ],
      ].join('\n\n'),
  ].join('\n\n');
}

String redactWebSearchReport(String text, Iterable<String> redactions) {
  final patterns = <String>{};
  for (final key in redactions) {
    if (key.isEmpty) continue;
    patterns.add(key);
    patterns.add(Uri.encodeComponent(key));
    final encoded = jsonEncode(key);
    patterns.add(encoded.substring(1, encoded.length - 1));
  }
  if (patterns.isEmpty) return text;
  final ordered = patterns.toList()..sort((a, b) => b.length.compareTo(a.length));
  return text.replaceAll(RegExp(ordered.map(RegExp.escape).join('|')), '[REDACTED]');
}

String? _modelInputText(WebSearchTrace trace, S strings) {
  final recorded = trace.modelInput['requests'];
  final requests = recorded is List ? recorded : [trace.modelInput];
  final blocks = <String>[];
  for (int requestIndex = 0; requestIndex < requests.length; requestIndex++) {
    final request = requests[requestIndex];
    if (request is! Map || request['messages'] is! List) continue;
    final messages = request['messages'] as List;
    final conversations = messages.isNotEmpty && messages.first is List ? messages : [messages];
    for (int batchIndex = 0; batchIndex < conversations.length; batchIndex++) {
      final conversation = conversations[batchIndex];
      if (conversation is! List || conversation.isEmpty || conversation.any((message) => message is! String)) continue;
      final text = conversation.cast<String>().join('\n\n');
      blocks.add(
        [
          if (requests.length > 1) strings.web_search_report_model_call(requestIndex + 1),
          if (conversations.length > 1) strings.web_search_report_model_batch(batchIndex + 1),
          text,
        ].join('\n\n'),
      );
    }
  }
  if (blocks.isNotEmpty) return blocks.join('\n\n');
  return null;
}

String _reportCodeBlock(String text) {
  int longest = 2;
  for (final match in RegExp(r'`+').allMatches(text)) {
    if (match[0]!.length > longest) longest = match[0]!.length;
  }
  final fence = '`' * (longest + 1);
  return '$fence\n$text\n$fence';
}
