import 'dart:async';

import 'package:local_web_search/src/browser/search_browser_controller.dart';
import 'package:local_web_search/src/models/search_deep_result.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_reference_bundle.dart';
import 'package:local_web_search/src/models/search_reference_source.dart';
import 'package:local_web_search/src/query/search_query_generator.dart';
import 'package:local_web_search/src/reference/search_reference_builder.dart';

class SearchReferenceService {
  const SearchReferenceService._();

  static Future<SearchReferenceBundle> searchWithBrowser({
    required SearchBrowserController controller,
    required List<String> messages,
    SearchEngine searchEngine = SearchEngines.bing,
    int maxSources = SearchReferenceBuilder.defaultMaxSources,
    Duration pageLoadDelay = const Duration(seconds: 3),
    Duration pageLoadTimeout = const Duration(seconds: 12),
    Duration retryDelay = const Duration(seconds: 1),
    int extractionAttempts = 5,
    bool enableDeepResults = false,
    int maxDeepResults = 3,
    int maxDeepCharactersPerResult = 2200,
    Duration detailPageLoadDelay = const Duration(seconds: 2),
    Duration detailPageLoadTimeout = const Duration(seconds: 12),
    DateTime? currentDate,
  }) async {
    final resolvedCurrentDate = currentDate ?? DateTime.now();
    final queryGeneration = SearchQueryGenerator.build(
      messages,
      currentDate: resolvedCurrentDate,
    );
    final query = queryGeneration.query;
    if (query.isEmpty) {
      return _buildFailureBundle(
        controller: controller,
        messages: messages,
        searchEngine: searchEngine,
        query: query,
        message: queryGeneration.reason,
        enableDeepResults: enableDeepResults,
        maxDeepResults: maxDeepResults,
        maxDeepCharactersPerResult: maxDeepCharactersPerResult,
        currentDate: resolvedCurrentDate,
      );
    }

    if (!controller.canRunBrowserActions) {
      return _buildFailureBundle(
        controller: controller,
        messages: messages,
        searchEngine: searchEngine,
        query: query,
        message: 'Browser adapter is not ready.',
        enableDeepResults: enableDeepResults,
        maxDeepResults: maxDeepResults,
        maxDeepCharactersPerResult: maxDeepCharactersPerResult,
        currentDate: resolvedCurrentDate,
      );
    }

    controller.clearReferenceBundle();
    final bundle = await _searchWithEngine(
      controller: controller,
      messages: messages,
      searchEngine: searchEngine,
      query: query,
      maxSources: maxSources,
      pageLoadDelay: pageLoadDelay,
      pageLoadTimeout: pageLoadTimeout,
      retryDelay: retryDelay,
      extractionAttempts: extractionAttempts,
      enableDeepResults: enableDeepResults,
      maxDeepResults: maxDeepResults,
      maxDeepCharactersPerResult: maxDeepCharactersPerResult,
      currentDate: resolvedCurrentDate,
    );
    if (bundle.hasSources) {
      final hydratedBundle = await hydrateDeepResultsForBundle(
        controller: controller,
        bundle: bundle,
        detailPageLoadDelay: detailPageLoadDelay,
        detailPageLoadTimeout: detailPageLoadTimeout,
        currentDate: resolvedCurrentDate,
      );
      controller.markReferenceBundle(hydratedBundle);
      return hydratedBundle;
    }

    if (_shouldTryFallbackSearch(bundle)) {
      for (final fallbackEngine in _fallbackEngines(searchEngine)) {
        final fallbackBundle = await _searchWithEngine(
          controller: controller,
          messages: messages,
          searchEngine: fallbackEngine,
          query: query,
          maxSources: maxSources,
          pageLoadDelay: pageLoadDelay,
          pageLoadTimeout: pageLoadTimeout,
          retryDelay: retryDelay,
          extractionAttempts: extractionAttempts,
          enableDeepResults: enableDeepResults,
          maxDeepResults: maxDeepResults,
          maxDeepCharactersPerResult: maxDeepCharactersPerResult,
          currentDate: resolvedCurrentDate,
        );
        if (!fallbackBundle.hasSources) continue;
        final hydratedFallbackBundle = await hydrateDeepResultsForBundle(
          controller: controller,
          bundle: fallbackBundle,
          detailPageLoadDelay: detailPageLoadDelay,
          detailPageLoadTimeout: detailPageLoadTimeout,
          currentDate: resolvedCurrentDate,
        );
        controller.markReferenceBundle(hydratedFallbackBundle);
        return hydratedFallbackBundle;
      }
    }

    controller.markReferenceBundle(bundle);
    return bundle;
  }

  static Future<SearchReferenceBundle> _searchWithEngine({
    required SearchBrowserController controller,
    required List<String> messages,
    required SearchEngine searchEngine,
    required String query,
    required int maxSources,
    required Duration pageLoadDelay,
    required Duration pageLoadTimeout,
    required Duration retryDelay,
    required int extractionAttempts,
    required bool enableDeepResults,
    required int maxDeepResults,
    required int maxDeepCharactersPerResult,
    required DateTime currentDate,
  }) async {
    try {
      await controller
          .loadSearch(engine: searchEngine, query: query)
          .timeout(pageLoadTimeout);
    } on TimeoutException {
      return _buildFailureBundle(
        controller: controller,
        messages: messages,
        searchEngine: searchEngine,
        query: query,
        message:
            'Search page load timed out after ${pageLoadTimeout.inSeconds} seconds.',
        maxSources: maxSources,
        enableDeepResults: enableDeepResults,
        maxDeepResults: maxDeepResults,
        maxDeepCharactersPerResult: maxDeepCharactersPerResult,
        currentDate: currentDate,
      );
    } catch (error) {
      return _buildFailureBundle(
        controller: controller,
        messages: messages,
        searchEngine: searchEngine,
        query: query,
        message: error.toString(),
        maxSources: maxSources,
        enableDeepResults: enableDeepResults,
        maxDeepResults: maxDeepResults,
        maxDeepCharactersPerResult: maxDeepCharactersPerResult,
        currentDate: currentDate,
      );
    }

    await _waitForSearchPage(
      controller: controller,
      searchEngine: searchEngine,
      minimumWait: pageLoadDelay,
      timeout: pageLoadTimeout,
    );

    final attempts = extractionAttempts < 1 ? 1 : extractionAttempts;
    SearchExtractionResult extraction = const SearchExtractionResult.empty();
    for (int attempt = 0; attempt < attempts; attempt += 1) {
      if (attempt > 0 && retryDelay > Duration.zero) {
        await Future<void>.delayed(retryDelay);
      }
      try {
        extraction = (await controller.runSerpExtraction().timeout(
          pageLoadTimeout,
          onTimeout: () => SearchExtractionResult.failure(
            'SERP extraction timed out after ${pageLoadTimeout.inSeconds} seconds.',
          ),
        )).validatedForEngine(searchEngine);
      } catch (error) {
        extraction = SearchExtractionResult.failure(error.toString());
      }
      if (extraction.hasItems || extraction.hasError) {
        break;
      }
    }

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: messages,
      searchEngine: searchEngine,
      query: query,
      extraction: extraction,
      maxSources: maxSources,
      enableDeepResults: enableDeepResults,
      maxDeepResults: maxDeepResults,
      maxDeepCharactersPerResult: maxDeepCharactersPerResult,
      currentDate: currentDate,
    );
    return bundle;
  }

  static SearchReferenceBundle _buildFailureBundle({
    required SearchBrowserController controller,
    required List<String> messages,
    required SearchEngine searchEngine,
    required String query,
    required String message,
    int maxSources = SearchReferenceBuilder.defaultMaxSources,
    bool enableDeepResults = false,
    int maxDeepResults = 3,
    int maxDeepCharactersPerResult = 2200,
    DateTime? currentDate,
  }) {
    final extraction = SearchExtractionResult.failure(message);
    final bundle = SearchReferenceBuilder.buildBundle(
      messages: messages,
      searchEngine: searchEngine,
      query: query,
      extraction: extraction,
      maxSources: maxSources,
      enableDeepResults: enableDeepResults,
      maxDeepResults: maxDeepResults,
      maxDeepCharactersPerResult: maxDeepCharactersPerResult,
      currentDate: currentDate,
    );
    controller.markError(message);
    controller.markReferenceBundle(bundle);
    return bundle;
  }

  static Future<SearchReferenceBundle> hydrateDeepResultsForBundle({
    required SearchBrowserController controller,
    required SearchReferenceBundle bundle,
    required Duration detailPageLoadDelay,
    required Duration detailPageLoadTimeout,
    DateTime? currentDate,
  }) async {
    if (!bundle.request.enableDeepResults) return bundle;
    if (!bundle.hasSources) return bundle;

    final maxResults = bundle.request.maxDeepResults < 0
        ? 0
        : bundle.request.maxDeepResults;
    if (maxResults == 0) return bundle;

    final results = <SearchDeepResult>[];
    int readableResults = 0;
    for (final source in bundle.sources) {
      if (readableResults >= maxResults) break;
      if (!_canReadSourceUrl(source.url)) {
        results.add(
          SearchDeepResult.failure(
            source: source,
            message: 'Deep extraction skipped unreadable source URL.',
          ),
        );
        continue;
      }

      final result = await _runDeepExtractionForSource(
        controller: controller,
        source: source,
        maxCharacters: bundle.request.maxDeepCharactersPerResult,
        detailPageLoadDelay: detailPageLoadDelay,
        detailPageLoadTimeout: detailPageLoadTimeout,
      );
      results.add(result);
      if (result.hasContent) {
        readableResults += 1;
      }
      controller.markReferenceBundle(
        bundle.copyWith(
          deepResults: List<SearchDeepResult>.unmodifiable(results),
          deepPromptContext: SearchReferenceBundle.buildDeepPromptContext(
            query: bundle.query,
            results: results,
            currentDate: currentDate,
          ),
        ),
      );
    }

    return bundle.copyWith(
      deepResults: List<SearchDeepResult>.unmodifiable(results),
      deepPromptContext: SearchReferenceBundle.buildDeepPromptContext(
        query: bundle.query,
        results: results,
        currentDate: currentDate,
      ),
    );
  }

  static Future<SearchDeepResult> _runDeepExtractionForSource({
    required SearchBrowserController controller,
    required SearchReferenceSource source,
    required int maxCharacters,
    required Duration detailPageLoadDelay,
    required Duration detailPageLoadTimeout,
  }) async {
    SearchDeepResult? latestFailure;
    for (final url in _candidateDeepUrls(source.url)) {
      final sourceForAttempt = SearchReferenceSource(
        rank: source.rank,
        title: source.title,
        url: url,
        summary: source.summary,
      );
      try {
        await controller.loadUrl(url).timeout(detailPageLoadTimeout);
        await _waitForDetailPage(
          controller: controller,
          minimumWait: detailPageLoadDelay,
          timeout: detailPageLoadTimeout,
        );
        if (!_currentPageMatchesSource(
          currentUrl: controller.currentUrl,
          sourceUrl: url,
        )) {
          latestFailure = SearchDeepResult.failure(
            source: sourceForAttempt,
            message:
                'Deep page navigation ended at "${controller.currentUrl}" instead of "$url".',
          );
          continue;
        }
        return controller
            .runDeepExtraction(
              source: sourceForAttempt,
              maxCharacters: maxCharacters,
            )
            .timeout(
              detailPageLoadTimeout,
              onTimeout: () => SearchDeepResult.failure(
                source: sourceForAttempt,
                message:
                    'Deep extraction timed out after ${detailPageLoadTimeout.inSeconds} seconds.',
              ),
            );
      } on TimeoutException {
        latestFailure = SearchDeepResult.failure(
          source: sourceForAttempt,
          message:
              'Deep page load timed out after ${detailPageLoadTimeout.inSeconds} seconds.',
        );
      } catch (error) {
        latestFailure = SearchDeepResult.failure(
          source: sourceForAttempt,
          message: error.toString(),
        );
      }
    }
    return latestFailure ??
        SearchDeepResult.failure(
          source: source,
          message: 'Deep extraction did not attempt a readable source URL.',
        );
  }

  static Future<void> _waitForSearchPage({
    required SearchBrowserController controller,
    required SearchEngine searchEngine,
    required Duration minimumWait,
    required Duration timeout,
  }) async {
    if (minimumWait > Duration.zero) {
      await Future<void>.delayed(minimumWait);
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final currentUrl = controller.currentUrl;
      if (_currentUrlMatchesEngine(currentUrl, searchEngine) &&
          !controller.loading) {
        return;
      }
      if (currentUrl.isNotEmpty && !controller.loading) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  static Future<void> _waitForDetailPage({
    required SearchBrowserController controller,
    required Duration minimumWait,
    required Duration timeout,
  }) async {
    if (minimumWait > Duration.zero) {
      await Future<void>.delayed(minimumWait);
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (controller.currentUrl.isNotEmpty && !controller.loading) return;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  static bool _canReadSourceUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return false;
    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return false;
    if (parsed.host.isEmpty) return false;
    return true;
  }

  static List<String> _candidateDeepUrls(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return <String>[url];
    if (parsed.scheme.toLowerCase() != 'http') return <String>[url];
    final secureUrl = parsed.replace(scheme: 'https').toString();
    if (secureUrl == url) return <String>[url];
    return <String>[secureUrl, url];
  }

  static bool _currentPageMatchesSource({
    required String currentUrl,
    required String sourceUrl,
  }) {
    final current = Uri.tryParse(currentUrl);
    final source = Uri.tryParse(sourceUrl);
    if (current == null || source == null) return false;
    if (current.host.isEmpty || source.host.isEmpty) return false;

    final currentHost = current.host.toLowerCase();
    final sourceHost = source.host.toLowerCase();
    if (currentHost != sourceHost &&
        !currentHost.endsWith('.$sourceHost') &&
        !sourceHost.endsWith('.$currentHost')) {
      return false;
    }

    final sourcePath = source.path;
    if (sourcePath.isEmpty || sourcePath == '/') return true;
    final currentPath = current.path;
    if (currentPath == sourcePath) return true;
    if (currentPath.startsWith(sourcePath)) return true;
    if (currentPath.isNotEmpty &&
        currentPath != '/' &&
        sourcePath.startsWith(currentPath)) {
      return true;
    }
    return false;
  }

  static bool _currentUrlMatchesEngine(String url, SearchEngine searchEngine) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    final targetHost = searchEngine.host.toLowerCase();
    return host == targetHost || host.endsWith('.$targetHost');
  }

  static bool _shouldTryFallbackSearch(SearchReferenceBundle bundle) {
    if (bundle.hasSources) return false;
    final error = bundle.error?.toLowerCase() ?? '';
    if (error.isEmpty) return false;
    if (error.contains('browser adapter') ||
        error.contains('search query is empty') ||
        error.contains('no user message')) {
      return false;
    }
    if (error.contains('did not match query')) return true;
    if (error.contains('blocked')) return true;
    if (error.contains('captcha')) return true;
    if (error.contains('human')) return true;
    if (error.contains('robot')) return true;
    if (error.contains('unusual traffic')) return true;
    if (error.contains('page host')) return true;
    if (error.contains('page path')) return true;
    if (error.contains('timed out')) return true;
    return false;
  }

  static List<SearchEngine> _fallbackEngines(SearchEngine primaryEngine) {
    return <SearchEngine>[
      SearchEngines.bing,
      SearchEngines.duckDuckGo,
      SearchEngines.brave,
      SearchEngines.yahoo,
      SearchEngines.sogou,
    ].where((engine) => engine.id != primaryEngine.id).toList();
  }
}
