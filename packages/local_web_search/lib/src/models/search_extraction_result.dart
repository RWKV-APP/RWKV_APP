// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_result_item.dart';

class SearchExtractionResult {
  static final RegExp _whitespacePattern = RegExp(r'\s+');
  static const int _maxItems = 10;
  static const int _maxTitleLength = 180;
  static const int _maxSnippetLength = 360;
  static const Set<String> _trackingQueryParams = <String>{
    'fbclid',
    'gclid',
    'mc_cid',
    'mc_eid',
    'msclkid',
    'yclid',
  };

  final List<SearchResultItem> items;
  final String rawJson;
  final String pageUrl;
  final String pageTitle;
  final String? error;

  const SearchExtractionResult({
    required this.items,
    required this.rawJson,
    this.pageUrl = '',
    this.pageTitle = '',
    this.error,
  });

  const SearchExtractionResult.empty()
    : items = const <SearchResultItem>[],
      rawJson = '',
      pageUrl = '',
      pageTitle = '',
      error = null;

  const SearchExtractionResult.failure(
    String message, {
    String raw = '',
    this.pageUrl = '',
    this.pageTitle = '',
  }) : items = const <SearchResultItem>[],
       rawJson = raw,
       error = message;

  SearchExtractionResult validatedForEngine(SearchEngine engine) {
    if (hasError) return this;

    final parsed = Uri.tryParse(pageUrl);
    if (parsed == null || parsed.host.isEmpty) {
      return SearchExtractionResult.failure(
        'Extraction did not report a page URL.',
        raw: rawJson,
        pageUrl: pageUrl,
        pageTitle: pageTitle,
      );
    }

    final host = parsed.host.toLowerCase();
    final expectedHost = engine.host.toLowerCase();
    if (host == expectedHost || host.endsWith('.$expectedHost')) {
      final expectedPath = engine.path.toLowerCase();
      if (expectedPath == '/' ||
          parsed.path.toLowerCase().startsWith(expectedPath)) {
        return this;
      }

      return SearchExtractionResult.failure(
        'Extraction page path "${parsed.path}" did not match ${engine.label} search path "$expectedPath".',
        raw: rawJson,
        pageUrl: pageUrl,
        pageTitle: pageTitle,
      );
    }

    return SearchExtractionResult.failure(
      'Extraction page host "$host" did not match ${engine.label} host "$expectedHost".',
      raw: rawJson,
      pageUrl: pageUrl,
      pageTitle: pageTitle,
    );
  }

  const SearchExtractionResult._failureItemsOnly(String message)
    : items = const <SearchResultItem>[],
      rawJson = '',
      pageUrl = '',
      pageTitle = '',
      error = message;

  bool get hasError => error != null && error!.isNotEmpty;

  bool get hasItems => items.isNotEmpty;

  factory SearchExtractionResult.fromJavaScriptResult(Object? value) {
    if (value == null) {
      return const SearchExtractionResult._failureItemsOnly(
        'Script returned no result.',
      );
    }

    final raw = value is String ? value : jsonEncode(value);

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return SearchExtractionResult.failure(
          'Script result is not a JSON object.',
          raw: raw,
        );
      }

      final pageUrl = decoded['href'] as String? ?? '';
      final pageTitle = decoded['title'] as String? ?? '';
      final scriptError = decoded['error'] as String? ?? '';
      if (scriptError.isNotEmpty) {
        return SearchExtractionResult.failure(
          scriptError,
          raw: raw,
          pageUrl: pageUrl,
          pageTitle: pageTitle,
        );
      }

      final rawItems = decoded['items'];
      if (rawItems is! List) {
        return SearchExtractionResult.failure(
          'Script result does not contain an items list.',
          raw: raw,
          pageUrl: pageUrl,
          pageTitle: pageTitle,
        );
      }

      final items = <SearchResultItem>[];
      final seenUrls = <String>{};
      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;
        final item = _cleanItem(
          SearchResultItem.fromJson(Map<String, dynamic>.from(rawItem)),
        );
        if (item == null) continue;
        if (seenUrls.contains(item.url)) continue;
        seenUrls.add(item.url);
        items.add(item);
        if (items.length >= _maxItems) break;
      }

      return SearchExtractionResult(
        items: items,
        rawJson: raw,
        pageUrl: pageUrl,
        pageTitle: pageTitle,
      );
    } catch (error) {
      return SearchExtractionResult.failure(error.toString(), raw: raw);
    }
  }

  static SearchResultItem? _cleanItem(SearchResultItem item) {
    final title = _fitText(item.title, _maxTitleLength);
    final url = _normalizeItemUrl(item.url);
    final snippet = _fitText(item.snippet, _maxSnippetLength);
    if (title.isEmpty || url.isEmpty) return null;
    return SearchResultItem(title: title, url: url, snippet: snippet);
  }

  static String _normalizeItemUrl(String rawUrl) {
    final parsed = Uri.tryParse(rawUrl.trim());
    if (parsed == null || parsed.host.isEmpty) return '';
    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return '';

    final filteredQuery = _filteredQuery(parsed.queryParametersAll);
    final int? port = parsed.hasPort ? parsed.port : null;
    return Uri(
      scheme: scheme,
      userInfo: parsed.userInfo,
      host: parsed.host.toLowerCase(),
      port: port,
      path: parsed.path,
      query: filteredQuery.isEmpty ? null : filteredQuery,
    ).toString();
  }

  static String _filteredQuery(Map<String, List<String>> queryParameters) {
    final pairs = <String>[];
    final keys = queryParameters.keys.toList()..sort();
    for (final key in keys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.startsWith('utm_')) continue;
      if (_trackingQueryParams.contains(lowerKey)) continue;
      final values = queryParameters[key] ?? const <String>[];
      for (final value in values) {
        pairs.add(
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
        );
      }
    }
    return pairs.join('&');
  }

  static String _fitText(String text, int maxLength) {
    final compact = text.replaceAll(_whitespacePattern, ' ').trim();
    if (compact.length <= maxLength) return compact;
    return compact.substring(0, maxLength).trim();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(),
      'rawJson': rawJson,
      'pageUrl': pageUrl,
      'pageTitle': pageTitle,
      'error': error,
    };
  }
}
