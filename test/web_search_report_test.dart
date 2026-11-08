import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/web_search_report.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/web_search_trace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => S.load(const Locale('en')));

  test('four sections preserve recorded input, source order and raw output', () {
    const prompt = '  🐕  two spaces\n\tindented\n```example```\n';
    const output = '  答案 🐕\n\n\t145702  registered\n';
    final trace = _trace().copyWith(
      finalPrompt: prompt,
      modelInput: {
        'messages': ['earlier question', 'earlier answer', prompt],
      },
    );
    final sections = webSearchReportSections(trace: trace, strings: S.current, modelOutput: output);

    expect(sections.map((section) => section.title), [
      '1. Search request',
      '2. Search results',
      '3. Final model input',
      '4. Model output',
    ]);
    expect(sections[0].body, trace.query);
    expect(sections[0].status, contains(trace.searchProvider));
    expect(sections[1].body.indexOf('[1] First'), lessThan(sections[1].body.indexOf('[2] Second')));
    expect(sections[1].body, isNot(contains('Normalized titles, URLs and excerpts')));
    expect(sections[1].status, S.current.web_search_report_response_missing);
    expect(sections[2].body, 'earlier question\n\nearlier answer\n\n$prompt');
    expect(sections[2].body, isNot(contains(S.current.web_search_report_native_note)));
    expect(sections[3].body, endsWith(output));
    final report = formatWebSearchReport(trace: trace, strings: S.current, modelOutput: output);
    expect(report, contains('````\n${sections[2].body}\n````'));
    expect(report, contains(output));
  });

  test('one-section copy shares the same body and does not include other sections', () {
    final sections = webSearchReportSections(trace: _trace(), strings: S.current, modelOutput: 'actual output');
    final report = formatWebSearchReport(trace: _trace(), strings: S.current, modelOutput: 'actual output', section: 1);

    expect(report, sections[1].body);
    expect(report, isNot(contains('## ${sections[0].title}')));
    expect(report, isNot(contains('actual output')));
  });

  test('legacy and unavailable records disclose missing captures', () {
    final trace = WebSearchTrace.empty().copyWith(finalPrompt: 'saved  injected 🐕 message');
    final sections = webSearchReportSections(trace: trace, strings: S.current);

    expect(sections[0].body, isEmpty);
    expect(sections[0].status, contains(S.current.web_search_report_request_missing));
    expect(sections[2].status, contains(S.current.web_search_report_input_missing));
    expect(sections[2].body, 'saved  injected 🐕 message');
    expect(sections[3].body, isEmpty);
    expect(sections[3].status, S.current.web_search_report_output_unavailable);
  });

  test('output status distinguishes generating, paused, finished and empty', () {
    for (final scenario in [
      (generating: true, paused: false, expected: S.current.web_search_report_output_generating),
      (generating: false, paused: true, expected: S.current.web_search_report_output_paused),
      (generating: false, paused: false, expected: S.current.web_search_report_output_complete),
    ]) {
      final sections = webSearchReportSections(
        trace: _trace(),
        strings: S.current,
        modelOutput: 'unchanged  🐕\n',
        generating: scenario.generating,
        paused: scenario.paused,
      );
      expect(sections[3].body, 'unchanged  🐕\n');
      expect(sections[3].status, scenario.expected);
    }
    final empty = webSearchReportSections(trace: _trace(), strings: S.current, modelOutput: '');
    expect(empty[3].body, isEmpty);
    expect(empty[3].status, contains(S.current.web_search_report_output_empty));
    expect(empty[3].body, isNot(contains(S.current.web_search_report_output_unavailable)));
  });

  test('configured credentials are redacted in raw, URL and JSON representations only', () {
    const key = 'test-"quoted\\secret';
    final encoded = jsonEncode(key);
    final escaped = encoded.substring(1, encoded.length - 1);
    final raw = '🐕  $key\n${Uri.encodeComponent(key)}\n$escaped\n\tunchanged';
    final trace = _trace().copyWith(
      userQuery: raw,
      modelInput: {
        'messages': [raw],
      },
    );
    final report = formatWebSearchReport(trace: trace, strings: S.current, modelOutput: raw, redactions: [key]);

    expect(report, isNot(contains(key)));
    expect(report, isNot(contains(Uri.encodeComponent(key))));
    expect(report, isNot(contains(escaped)));
    expect(report, contains('[REDACTED]'));
    expect(report, contains('🐕  [REDACTED]'));
    expect(report, contains('\n\tunchanged'));
    expect(trace.userQuery, raw);
    final input = webSearchReportSections(trace: trace, strings: S.current, modelOutput: raw, redactions: [key])[2].body;
    expect(input, '🐕  [REDACTED]\n[REDACTED]\n[REDACTED]\n\tunchanged');
  });

  test('saved diagnostic envelopes show only actual text and never duplicate the injected prompt', () {
    const prompt = '  Read captureBoundary as a user word.\nThen answer.\n';
    final trace = _trace().copyWith(
      finalPrompt: 'older injected prompt before style processing',
      modelInput: {
        'captureBoundary': 'diagnostic boundary',
        'nativeChatTemplateAvailable': false,
        'requests': [
          {
            'type': 'ChatAsync',
            'messages': [prompt],
            'capturedAt': 'diagnostic timestamp',
            'configuredMaxLength': 10000,
            'configuredDecodeParams': 'diagnostic settings',
            'maxLength': null,
          },
        ],
      },
    );
    final body = webSearchReportSections(trace: trace, strings: S.current)[2].body;
    expect(body, prompt);
    final report = formatWebSearchReport(trace: trace, strings: S.current, section: 2);
    expect(report, prompt);
    expect(report, isNot(contains('diagnostic')));
    expect(report, isNot(contains('older injected')));
  });

  test('sequential and batch calls preserve all actual messages in order with readable grouping', () {
    final trace = _trace().copyWith(
      modelInput: {
        'requests': [
          {
            'messages': ['first  request\n'],
          },
          {
            'messages': [
              ['question A', 'answer A', 'follow-up A'],
              ['question B 🐕'],
            ],
          },
        ],
      },
    );
    final body = webSearchReportSections(trace: trace, strings: S.current)[2].body;
    expect(
      body,
      '${S.current.web_search_report_model_call(1)}\n\nfirst  request\n\n\n'
      '${S.current.web_search_report_model_call(2)}\n\n${S.current.web_search_report_model_batch(1)}\n\n'
      'question A\n\nanswer A\n\nfollow-up A\n\n'
      '${S.current.web_search_report_model_call(2)}\n\n${S.current.web_search_report_model_batch(2)}\n\nquestion B 🐕',
    );
  });

  test('metadata alone is not mistaken for captured input', () {
    final trace = _trace().copyWith(modelInput: {'captureBoundary': 'metadata without messages'});
    final section = webSearchReportSections(trace: trace, strings: S.current)[2];
    expect(section.body, isEmpty);
    expect(section.status, S.current.web_search_report_input_missing);
  });

  test('failed searches retain the recorded request and safe error', () {
    final trace = WebSearchTrace.empty().copyWith(request: 'POST https://example.com/search\n{"query":"dogs"}', error: 'Search timed out.');
    final report = formatWebSearchReport(trace: trace, strings: S.current, modelOutput: 'answer without references');

    expect(report, contains(trace.request));
    expect(report, contains(trace.error));
    expect(report, contains(S.current.web_search_report_response_missing));
    expect(report, contains(S.current.web_search_report_input_missing));
  });

  test('raw responses survive serialization and copy without notes or normalized clipping', () {
    const body = '  {"results":[{"extra":"preserved"}],"request_id":"server-id"}\n';
    final trace = WebSearchTrace.fromJson(
      jsonDecode(
        jsonEncode(
          _trace()
              .copyWith(
                responses: const [WebSearchTraceResponse(query: '深圳有多少条地铁线？', statusCode: 200, body: body)],
              )
              .toJson(),
        ),
      ),
    );
    expect(trace.responses.single.body, body);
    expect(trace.responses.single.query, '深圳有多少条地铁线？');
    expect(trace.responses.single.statusCode, 200);
    final sections = webSearchReportSections(trace: trace, strings: S.current);
    expect(sections[1].body, body);
    expect(sections[1].status, contains('HTTP 200'));
    expect(formatWebSearchReport(trace: trace, strings: S.current, section: 1), body);
    final all = formatWebSearchReport(trace: trace, strings: S.current);
    expect(all, contains(body));
    expect(all, contains(trace.request));
    expect(sections[0].body, trace.query);
  });
}

WebSearchTrace _trace() => WebSearchTrace.empty().copyWith(
  searchProvider: 'AnySearch',
  query: '深圳 犬只 数量',
  userQuery: '深圳有多少条狗？',
  request: 'POST https://example.com/search\n{"query":"深圳 犬只 数量","max_results":3}',
  sources: const [
    WebSearchTraceSource(rank: 1, title: 'First', url: 'https://example.com/first', summary: 'First  excerpt 🐕.'),
    WebSearchTraceSource(rank: 2, title: 'Second', url: 'https://example.com/second', summary: 'Second excerpt.'),
  ],
  promptContext: '[1] First  excerpt 🐕.\n[2] Second excerpt.',
);
