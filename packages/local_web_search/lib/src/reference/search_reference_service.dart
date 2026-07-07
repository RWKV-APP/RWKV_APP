import 'package:local_web_search/src/browser/search_browser_controller.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_reference_bundle.dart';
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
  }) async {
    final queryGeneration = SearchQueryGenerator.build(messages);
    final query = queryGeneration.query;
    if (query.isEmpty) {
      final extraction = SearchExtractionResult.failure(queryGeneration.reason);
      final bundle = SearchReferenceBuilder.buildBundle(
        messages: messages,
        searchEngine: searchEngine,
        query: query,
        extraction: extraction,
        maxSources: maxSources,
      );
      controller.markReferenceBundle(bundle);
      return bundle;
    }

    if (!controller.canRunBrowserActions) {
      const extraction = SearchExtractionResult.failure(
        'Browser adapter is not ready.',
      );
      final bundle = SearchReferenceBuilder.buildBundle(
        messages: messages,
        searchEngine: searchEngine,
        query: query,
        extraction: extraction,
        maxSources: maxSources,
      );
      controller.markReferenceBundle(bundle);
      return bundle;
    }

    controller.clearReferenceBundle();
    await controller.loadSearch(engine: searchEngine, query: query);
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
      extraction = (await controller.runSerpExtraction()).validatedForEngine(
        searchEngine,
      );
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
    );
    controller.markReferenceBundle(bundle);
    return bundle;
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
      if (_currentUrlMatchesEngine(controller.currentUrl, searchEngine) &&
          !controller.loading) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  static bool _currentUrlMatchesEngine(String url, SearchEngine searchEngine) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    final targetHost = searchEngine.host.toLowerCase();
    return host == targetHost || host.endsWith('.$targetHost');
  }
}
