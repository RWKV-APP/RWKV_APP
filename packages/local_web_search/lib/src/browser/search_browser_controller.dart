// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_reference_bundle.dart';
import 'package:local_web_search/src/scripts/serp_extraction_script.dart';

abstract interface class SearchBrowserControllerDelegate {
  bool get supportsBrowserActions;

  Future<void> loadUrl(String url);

  Future<Object?> evaluateJavaScript(String source);
}

class SearchBrowserController extends ChangeNotifier {
  SearchBrowserControllerDelegate? _delegate;
  String _currentUrl = '';
  bool _loading = false;
  String? _error;
  SearchReferenceBundle _latestReferenceBundle =
      const SearchReferenceBundle.empty();

  String get currentUrl => _currentUrl;

  bool get loading => _loading;

  String? get error => _error;

  bool get canRunBrowserActions => _delegate?.supportsBrowserActions ?? false;

  SearchReferenceBundle get latestReferenceBundle => _latestReferenceBundle;

  void attach(SearchBrowserControllerDelegate delegate) {
    _delegate = delegate;
    _error = null;
    notifyListeners();
  }

  void detach(SearchBrowserControllerDelegate delegate) {
    if (_delegate != delegate) return;
    _delegate = null;
  }

  Future<void> loadUrl(String input) async {
    final delegate = _delegate;
    if (delegate == null) {
      _error = 'Browser adapter is not ready.';
      notifyListeners();
      return;
    }

    final url = _normalizeInputUrl(input);
    _currentUrl = url;
    _error = null;
    notifyListeners();
    await delegate.loadUrl(url);
  }

  Future<void> loadGoogleSearch(String query) async {
    await loadSearch(engine: SearchEngines.google, query: query);
  }

  Future<void> loadSearch({
    required SearchEngine engine,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _error = 'Search query is empty.';
      notifyListeners();
      return;
    }

    await loadUrl(engine.buildSearchUrl(trimmed));
  }

  Future<SearchExtractionResult> runSerpExtraction() async {
    final delegate = _delegate;
    if (delegate == null) {
      return const SearchExtractionResult.failure(
        'Browser adapter is not ready.',
      );
    }

    try {
      final result = await delegate.evaluateJavaScript(serpExtractionScript);
      return SearchExtractionResult.fromJavaScriptResult(result);
    } catch (error) {
      return SearchExtractionResult.failure(error.toString());
    }
  }

  void markLoading(bool loading) {
    if (_loading == loading) return;
    _loading = loading;
    notifyListeners();
  }

  void markCurrentUrl(String? url) {
    if (url == null || url.isEmpty) return;
    if (_currentUrl == url) return;
    _currentUrl = url;
    notifyListeners();
  }

  void markError(String? error) {
    if (_error == error) return;
    _error = error;
    notifyListeners();
  }

  void markReferenceBundle(SearchReferenceBundle bundle) {
    _latestReferenceBundle = bundle;
    notifyListeners();
  }

  void clearReferenceBundle() {
    markReferenceBundle(const SearchReferenceBundle.empty());
  }

  String _normalizeInputUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }
}
