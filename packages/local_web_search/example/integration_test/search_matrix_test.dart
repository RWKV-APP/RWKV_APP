import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:local_web_search/local_web_search.dart';

const String _outputPath = String.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_OUT',
);
const int _promptLimit = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_PROMPT_LIMIT',
  defaultValue: 20,
);
const int _promptOffset = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_PROMPT_OFFSET',
);
const int _engineLimit = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_ENGINE_LIMIT',
  defaultValue: 10,
);
const int _engineOffset = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_ENGINE_OFFSET',
);
const int _profileLimit = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_PROFILE_LIMIT',
  defaultValue: 2,
);
const int _profileOffset = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_PROFILE_OFFSET',
);
const int _caseLimit = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_CASE_LIMIT',
  defaultValue: 400,
);
const int _pageLoadDelaySeconds = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_PAGE_LOAD_DELAY_SECONDS',
  defaultValue: 3,
);
const int _pageLoadTimeoutSeconds = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_PAGE_LOAD_TIMEOUT_SECONDS',
  defaultValue: 12,
);
const int _extractionAttempts = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_EXTRACTION_ATTEMPTS',
  defaultValue: 5,
);
const bool _allowFailures = bool.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_ALLOW_FAILURES',
);
const bool _forceDeepResults = bool.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_ENABLE_DEEP_RESULTS',
);
const int _maxDeepResults = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_MAX_DEEP_RESULTS',
  defaultValue: 3,
);
const int _maxDeepCharacters = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_MAX_DEEP_CHARS',
  defaultValue: 2200,
);
const int _detailPageLoadDelaySeconds = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_DETAIL_PAGE_LOAD_DELAY_SECONDS',
  defaultValue: 2,
);
const int _detailPageLoadTimeoutSeconds = int.fromEnvironment(
  'LOCAL_WEB_SEARCH_MATRIX_DETAIL_PAGE_LOAD_TIMEOUT_SECONDS',
  defaultValue: 12,
);

const List<_SummaryProfile> _summaryProfiles = <_SummaryProfile>[
  _SummaryProfile(
    id: 'standard',
    label: 'Standard Summary',
    maxSources: 5,
    enableDeepResults: false,
  ),
  _SummaryProfile(
    id: 'deep',
    label: 'Deep Summary',
    maxSources: 8,
    enableDeepResults: true,
  ),
];

const List<String> _prompts = <String>[
  '告诉我深圳有多少条狗？',
  '给我讲讲中国。',
  '中国的国土面积是多少？',
  '深圳现在大概有多少人口？',
  '广州和深圳哪个面积更大？',
  '中国有多少个省级行政区？',
  '讲讲香港的历史。',
  '深圳为什么发展这么快？',
  '中国最大的城市是哪一个？',
  '世界上人口最多的国家现在是谁？',
  '给我介绍一下 RWKV。',
  'RWKV 和 Transformer 有什么区别？',
  'Ollama 是做什么的？',
  'Claude 和 ChatGPT 有什么区别？',
  '2026 年有哪些值得关注的 AI 模型？',
  'iPhone 现在最新款是什么？',
  '比亚迪最近几年为什么增长这么快？',
  '深圳有哪些适合周末去的地方？',
  '中国高铁为什么发展得这么快？',
  '帮我查一下深圳养狗需要办什么证？',
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'runs local web search prompt by engine matrix',
    (tester) async {
      final controller = SearchBrowserController();
      final outputFile = _matrixOutputFile();
      await outputFile.parent.create(recursive: true);
      if (outputFile.existsSync()) {
        outputFile.deleteSync();
      }

      final sink = outputFile.openWrite();
      final results = <_MatrixCaseResult>[];

      await tester.pumpWidget(_MatrixHarnessApp(controller: controller));
      await _pumpUntilBrowserReady(tester, controller);

      int caseIndex = 0;
      promptLoop:
      for (
        int promptIndex = _boundedOffset(_prompts, _promptOffset);
        promptIndex < _boundedLength(_prompts, _promptOffset + _promptLimit);
        promptIndex += 1
      ) {
        final prompt = _prompts[promptIndex];
        for (
          int engineIndex = _boundedOffset(SearchEngines.all, _engineOffset);
          engineIndex <
              _boundedLength(SearchEngines.all, _engineOffset + _engineLimit);
          engineIndex += 1
        ) {
          if (caseIndex >= _caseLimit) break promptLoop;

          final engine = SearchEngines.all[engineIndex];
          for (
            int profileIndex = _boundedOffset(_summaryProfiles, _profileOffset);
            profileIndex <
                _boundedLength(
                  _summaryProfiles,
                  _profileOffset + _profileLimit,
                );
            profileIndex += 1
          ) {
            if (caseIndex >= _caseLimit) break promptLoop;

            final summaryProfile = _summaryProfiles[profileIndex];
            final startedAt = DateTime.now();
            final stopwatch = Stopwatch()..start();
            final bundle = await _runSearchCase(
              tester: tester,
              controller: controller,
              prompt: prompt,
              engine: engine,
              summaryProfile: summaryProfile,
            );
            stopwatch.stop();

            final result = _MatrixCaseResult.fromBundle(
              caseIndex: caseIndex,
              promptIndex: promptIndex,
              engineIndex: engineIndex,
              summaryProfile: summaryProfile,
              prompt: prompt,
              engine: engine,
              startedAt: startedAt,
              elapsed: stopwatch.elapsed,
              bundle: bundle,
            );
            results.add(result);
            sink.writeln(jsonEncode(result.toJson()));
            await sink.flush();

            stdout.writeln(
              '[${caseIndex + 1}] ${engine.label} | ${summaryProfile.id} | '
              '${result.status} | sources=${result.sourceCount}/'
              '${summaryProfile.maxSources} deep='
              '${result.readableDeepResultCount}/${result.deepResultCount} '
              'raw=${result.rawItemCount} | '
              'resolved=${result.resolvedEngineLabel} | ${result.query}',
            );
            caseIndex += 1;
            await _pauseBetweenCases(tester);
          }
        }
      }

      await sink.close();
      await _writeSummary(outputFile: outputFile, results: results);
      controller.dispose();

      final failures = results
          .where((result) => result.status != _MatrixStatus.passed)
          .toList();
      if (_allowFailures) return;
      expect(
        failures,
        isEmpty,
        reason: 'Matrix failures were written to ${outputFile.path}',
      );
    },
    timeout: const Timeout(Duration(hours: 4)),
  );
}

Future<void> _pauseBetweenCases(WidgetTester tester) async {
  await tester.runAsync<void>(() {
    return Future<void>.delayed(const Duration(milliseconds: 100));
  });
}

Future<SearchReferenceBundle> _runSearchCase({
  required WidgetTester tester,
  required SearchBrowserController controller,
  required String prompt,
  required SearchEngine engine,
  required _SummaryProfile summaryProfile,
}) async {
  final bundle = await tester.runAsync<SearchReferenceBundle>(() {
    return SearchReferenceService.searchWithBrowser(
      controller: controller,
      messages: <String>['User: $prompt'],
      searchEngine: engine,
      maxSources: summaryProfile.maxSources,
      pageLoadDelay: Duration(seconds: _pageLoadDelaySeconds),
      pageLoadTimeout: Duration(seconds: _pageLoadTimeoutSeconds),
      retryDelay: const Duration(seconds: 1),
      extractionAttempts: _extractionAttempts,
      enableDeepResults: summaryProfile.enableDeepResults || _forceDeepResults,
      maxDeepResults: _maxDeepResults,
      maxDeepCharactersPerResult: _maxDeepCharacters,
      detailPageLoadDelay: Duration(seconds: _detailPageLoadDelaySeconds),
      detailPageLoadTimeout: Duration(seconds: _detailPageLoadTimeoutSeconds),
    );
  });
  if (bundle == null) {
    throw StateError('Search case returned no bundle.');
  }
  return bundle;
}

Future<void> _pumpUntilBrowserReady(
  WidgetTester tester,
  SearchBrowserController controller,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (controller.canRunBrowserActions) return;
  }
  throw StateError('Browser adapter was not ready after 30 seconds.');
}

File _matrixOutputFile() {
  if (_outputPath.trim().isNotEmpty) {
    return File(_outputPath.trim());
  }
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  return File(
    '${Directory.systemTemp.path}/local_web_search_matrix/search_matrix_$timestamp.jsonl',
  );
}

Future<void> _writeSummary({
  required File outputFile,
  required List<_MatrixCaseResult> results,
}) async {
  final summaryFile = File('${outputFile.path}.md');
  final counts = <_MatrixStatus, int>{
    for (final status in _MatrixStatus.values) status: 0,
  };
  for (final result in results) {
    counts[result.status] = (counts[result.status] ?? 0) + 1;
  }
  final profileIds = <String>{};
  for (final result in results) {
    profileIds.add(result.summaryProfileId);
  }

  final buffer = StringBuffer();
  buffer.writeln('# Local Web Search Matrix');
  buffer.writeln();
  buffer.writeln('- Cases: ${results.length}');
  buffer.writeln(
    '- Summary profiles: ${profileIds.isEmpty ? "none" : profileIds.join(", ")}',
  );
  for (final status in _MatrixStatus.values) {
    buffer.writeln('- ${status.name}: ${counts[status] ?? 0}');
  }
  buffer.writeln('- JSONL: `${outputFile.path}`');
  buffer.writeln();
  buffer.writeln('## Failures');
  buffer.writeln();
  final failures = results
      .where((result) => result.status != _MatrixStatus.passed)
      .toList();
  if (failures.isEmpty) {
    buffer.writeln('No failures.');
  } else {
    for (final failure in failures) {
      buffer.writeln(
        '- #${failure.caseIndex + 1} ${failure.engineLabel} | '
        'resolved=${failure.resolvedEngineLabel} | '
        '${failure.summaryProfileId} | ${failure.status.name} | '
        'prompt="${failure.prompt}" | query="${failure.query}" | error="${failure.error ?? ''}"',
      );
    }
  }
  await summaryFile.writeAsString(buffer.toString());
}

int _boundedLength<T>(List<T> items, int requested) {
  if (requested < 0) return items.length;
  if (requested > items.length) return items.length;
  return requested;
}

int _boundedOffset<T>(List<T> items, int requested) {
  if (requested < 0) return 0;
  if (requested > items.length) return items.length;
  return requested;
}

class _MatrixHarnessApp extends StatelessWidget {
  final SearchBrowserController controller;

  const _MatrixHarnessApp({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(body: SearchBrowserPanel(controller: controller)),
    );
  }
}

enum _MatrixStatus {
  passed,
  blocked,
  humanVerification,
  externalRedirect,
  timeout,
  relevanceFailed,
  deepExtractionFailed,
  extractionFailed,
  noSources,
}

class _SummaryProfile {
  final String id;
  final String label;
  final int maxSources;
  final bool enableDeepResults;

  const _SummaryProfile({
    required this.id,
    required this.label,
    required this.maxSources,
    required this.enableDeepResults,
  });
}

class _MatrixCaseResult {
  final int caseIndex;
  final int promptIndex;
  final int engineIndex;
  final String summaryProfileId;
  final String summaryProfileLabel;
  final int maxSources;
  final String prompt;
  final String engineId;
  final String engineLabel;
  final String resolvedEngineId;
  final String resolvedEngineLabel;
  final String query;
  final _MatrixStatus status;
  final int sourceCount;
  final bool deepResultsEnabled;
  final int deepResultCount;
  final int readableDeepResultCount;
  final int deepPromptContextLength;
  final int rawItemCount;
  final String pageUrl;
  final String pageTitle;
  final String? error;
  final int elapsedMs;
  final String startedAt;
  final List<String> sourceUrls;
  final List<String> deepResultUrls;
  final List<String> deepResultErrors;
  final List<Map<String, dynamic>> rawItems;
  final Map<String, dynamic> rawDebug;

  const _MatrixCaseResult({
    required this.caseIndex,
    required this.promptIndex,
    required this.engineIndex,
    required this.summaryProfileId,
    required this.summaryProfileLabel,
    required this.maxSources,
    required this.prompt,
    required this.engineId,
    required this.engineLabel,
    required this.resolvedEngineId,
    required this.resolvedEngineLabel,
    required this.query,
    required this.status,
    required this.sourceCount,
    required this.deepResultsEnabled,
    required this.deepResultCount,
    required this.readableDeepResultCount,
    required this.deepPromptContextLength,
    required this.rawItemCount,
    required this.pageUrl,
    required this.pageTitle,
    required this.error,
    required this.elapsedMs,
    required this.startedAt,
    required this.sourceUrls,
    required this.deepResultUrls,
    required this.deepResultErrors,
    required this.rawItems,
    required this.rawDebug,
  });

  factory _MatrixCaseResult.fromBundle({
    required int caseIndex,
    required int promptIndex,
    required int engineIndex,
    required _SummaryProfile summaryProfile,
    required String prompt,
    required SearchEngine engine,
    required DateTime startedAt,
    required Duration elapsed,
    required SearchReferenceBundle bundle,
  }) {
    return _MatrixCaseResult(
      caseIndex: caseIndex,
      promptIndex: promptIndex,
      engineIndex: engineIndex,
      summaryProfileId: summaryProfile.id,
      summaryProfileLabel: summaryProfile.label,
      maxSources: summaryProfile.maxSources,
      prompt: prompt,
      engineId: engine.id,
      engineLabel: engine.label,
      resolvedEngineId: bundle.searchEngine.id,
      resolvedEngineLabel: bundle.searchEngine.label,
      query: bundle.query,
      status: _classify(bundle),
      sourceCount: bundle.sources.length,
      deepResultsEnabled: bundle.request.enableDeepResults,
      deepResultCount: bundle.deepResults.length,
      readableDeepResultCount: _readableDeepResultCount(bundle),
      deepPromptContextLength: bundle.deepPromptContext.length,
      rawItemCount: _rawItemCount(bundle.rawJson),
      pageUrl: _rawString(bundle.rawJson, 'href'),
      pageTitle: _rawString(bundle.rawJson, 'title'),
      error: bundle.error,
      elapsedMs: elapsed.inMilliseconds,
      startedAt: startedAt.toIso8601String(),
      sourceUrls: <String>[for (final source in bundle.sources) source.url],
      deepResultUrls: <String>[
        for (final result in bundle.deepResults) result.url,
      ],
      deepResultErrors: <String>[
        for (final result in bundle.deepResults)
          if (result.hasError) result.error!,
      ],
      rawItems: _rawItems(bundle.rawJson),
      rawDebug: _rawObject(bundle.rawJson, 'debug'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'caseIndex': caseIndex,
      'promptIndex': promptIndex,
      'engineIndex': engineIndex,
      'summaryProfileId': summaryProfileId,
      'summaryProfileLabel': summaryProfileLabel,
      'maxSources': maxSources,
      'prompt': prompt,
      'engineId': engineId,
      'engineLabel': engineLabel,
      'resolvedEngineId': resolvedEngineId,
      'resolvedEngineLabel': resolvedEngineLabel,
      'fallbackUsed': resolvedEngineId != engineId,
      'query': query,
      'status': status.name,
      'sourceCount': sourceCount,
      'deepResultsEnabled': deepResultsEnabled,
      'deepResultCount': deepResultCount,
      'readableDeepResultCount': readableDeepResultCount,
      'deepPromptContextLength': deepPromptContextLength,
      'rawItemCount': rawItemCount,
      'pageUrl': pageUrl,
      'pageTitle': pageTitle,
      'error': error,
      'elapsedMs': elapsedMs,
      'startedAt': startedAt,
      'sourceUrls': sourceUrls,
      'deepResultUrls': deepResultUrls,
      'deepResultErrors': deepResultErrors,
      'rawItems': rawItems,
      'rawDebug': rawDebug,
    };
  }
}

_MatrixStatus _classify(SearchReferenceBundle bundle) {
  if (bundle.hasSources && !bundle.request.enableDeepResults) {
    return _MatrixStatus.passed;
  }
  if (bundle.hasSources && bundle.request.enableDeepResults) {
    if (bundle.hasDeepResults) return _MatrixStatus.passed;
    return _MatrixStatus.deepExtractionFailed;
  }
  final error = bundle.error;
  if (error == null || error.isEmpty) return _MatrixStatus.noSources;

  final lower = error.toLowerCase();
  if (lower.contains('human') ||
      lower.contains('captcha') ||
      lower.contains('robot')) {
    return _MatrixStatus.humanVerification;
  }
  if (lower.contains('blocked') || lower.contains('unusual traffic')) {
    return _MatrixStatus.blocked;
  }
  if (lower.contains('page host') || lower.contains('page path')) {
    return _MatrixStatus.externalRedirect;
  }
  if (lower.contains('timed out')) {
    return _MatrixStatus.timeout;
  }
  if (lower.contains('did not match query')) {
    return _MatrixStatus.relevanceFailed;
  }
  return _MatrixStatus.extractionFailed;
}

int _readableDeepResultCount(SearchReferenceBundle bundle) {
  int count = 0;
  for (final result in bundle.deepResults) {
    if (!result.hasContent) continue;
    count += 1;
  }
  return count;
}

int _rawItemCount(String rawJson) {
  if (rawJson.isEmpty) return 0;
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) return 0;
    final items = decoded['items'];
    if (items is! List) return 0;
    return items.length;
  } catch (_) {
    return 0;
  }
}

String _rawString(String rawJson, String key) {
  if (rawJson.isEmpty) return '';
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) return '';
    final value = decoded[key];
    if (value is! String) return '';
    return value;
  } catch (_) {
    return '';
  }
}

List<Map<String, dynamic>> _rawItems(String rawJson) {
  if (rawJson.isEmpty) return const <Map<String, dynamic>>[];
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      return const <Map<String, dynamic>>[];
    }
    final items = decoded['items'];
    if (items is! List) return const <Map<String, dynamic>>[];
    final mapped = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is! Map) continue;
      mapped.add(Map<String, dynamic>.from(item));
    }
    return mapped;
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}

Map<String, dynamic> _rawObject(String rawJson, String key) {
  if (rawJson.isEmpty) return const <String, dynamic>{};
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) return const <String, dynamic>{};
    final value = decoded[key];
    if (value is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.from(value);
  } catch (_) {
    return const <String, dynamic>{};
  }
}
