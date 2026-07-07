import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_reference_request.dart';
import 'package:local_web_search/src/models/search_reference_source.dart';
import 'package:local_web_search/src/models/search_result_item.dart';

class SearchReferenceBundle {
  static final RegExp _hanTermPattern = RegExp(
    r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]{2,}',
  );
  static final RegExp _latinTokenPattern = RegExp(r'[a-z0-9][a-z0-9+#]{1,}');
  static final RegExp _punctuationPattern = RegExp(
    r'[^a-z0-9+#\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]+',
  );

  static const Set<String> _lowSignalTerms = <String>{
    'about',
    'and',
    'for',
    'from',
    'how',
    'off',
    'the',
    'with',
    '方法',
  };

  static const Map<String, List<String>> _termAliases = <String, List<String>>{
    '中国': <String>['china', 'chinese', 'prc', 'people republic'],
    '巴黎': <String>['paris'],
  };

  final SearchReferenceRequest request;
  final SearchEngine searchEngine;
  final String query;
  final List<SearchReferenceSource> sources;
  final String promptContext;
  final String rawJson;
  final String? error;

  const SearchReferenceBundle({
    required this.request,
    required this.searchEngine,
    required this.query,
    required this.sources,
    required this.promptContext,
    required this.rawJson,
    this.error,
  });

  const SearchReferenceBundle.empty()
    : request = const SearchReferenceRequest.empty(),
      searchEngine = SearchEngines.bing,
      query = '',
      sources = const <SearchReferenceSource>[],
      promptContext = '',
      rawJson = '',
      error = null;

  bool get hasError => error != null && error!.isNotEmpty;

  bool get hasSources => sources.isNotEmpty;

  factory SearchReferenceBundle.fromExtraction({
    required SearchReferenceRequest request,
    required SearchEngine searchEngine,
    required String query,
    required SearchExtractionResult extraction,
  }) {
    final sourceLimit = request.maxSources < 0 ? 0 : request.maxSources;
    final sources = <SearchReferenceSource>[];
    final relevanceTerms = _SearchRelevanceTerms.fromQuery(query);
    int rank = 1;
    for (final item in extraction.items) {
      if (sources.length >= sourceLimit) break;
      if (!relevanceTerms.matches(item)) continue;
      sources.add(
        SearchReferenceSource.fromSearchResultItem(rank: rank, item: item),
      );
      rank += 1;
    }
    final relevanceError =
        extraction.error == null &&
            extraction.items.isNotEmpty &&
            sources.isEmpty &&
            sourceLimit > 0
        ? 'Search results did not match query "$query".'
        : null;

    return SearchReferenceBundle(
      request: request,
      searchEngine: searchEngine,
      query: query,
      sources: sources,
      promptContext: _buildPromptContext(query: query, sources: sources),
      rawJson: extraction.rawJson,
      error: extraction.error ?? relevanceError,
    );
  }

  static Set<String> _hanTerms(String text) {
    final terms = <String>{};
    final matches = _hanTermPattern.allMatches(text);
    for (final match in matches) {
      final value = match.group(0);
      if (value == null) continue;
      if (_lowSignalTerms.contains(value)) continue;
      terms.add(value);
    }
    return terms;
  }

  static Set<String> _latinTokens(String text) {
    final normalized = text.toLowerCase().replaceAll(_punctuationPattern, ' ');
    final tokens = <String>{};
    final matches = _latinTokenPattern.allMatches(normalized);
    for (final match in matches) {
      final value = match.group(0);
      if (value == null) continue;
      if (_lowSignalTerms.contains(value)) continue;
      tokens.add(value);
    }
    return tokens;
  }

  static Set<String> _aliasTokens(Set<String> hanTerms) {
    final aliases = <String>{};
    for (final term in hanTerms) {
      final mapped = _termAliases[term];
      if (mapped == null) continue;
      for (final alias in mapped) {
        aliases.addAll(_latinTokens(alias));
      }
    }
    return aliases;
  }

  static String _buildPromptContext({
    required String query,
    required List<SearchReferenceSource> sources,
  }) {
    if (sources.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('Search query: $query');
    buffer.writeln();
    buffer.writeln('Reference sources for the next answer:');
    for (final source in sources) {
      buffer.writeln();
      buffer.writeln(source.toPromptBlock());
    }
    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request': request.toJson(),
      'searchEngine': searchEngine.toJson(),
      'query': query,
      'sources': sources.map((source) => source.toJson()).toList(),
      'promptContext': promptContext,
      'rawJson': rawJson,
      'error': error,
    };
  }
}

class _SearchRelevanceTerms {
  final Set<String> hanTerms;
  final Set<String> latinTerms;
  final Set<String> aliasLatinTerms;

  const _SearchRelevanceTerms({
    required this.hanTerms,
    required this.latinTerms,
    required this.aliasLatinTerms,
  });

  factory _SearchRelevanceTerms.fromQuery(String query) {
    final hanTerms = SearchReferenceBundle._hanTerms(query);
    final latinTerms = SearchReferenceBundle._latinTokens(query);
    final aliasLatinTerms = SearchReferenceBundle._aliasTokens(hanTerms);
    return _SearchRelevanceTerms(
      hanTerms: hanTerms,
      latinTerms: latinTerms,
      aliasLatinTerms: aliasLatinTerms,
    );
  }

  bool matches(SearchResultItem item) {
    if (hanTerms.isEmpty && latinTerms.isEmpty && aliasLatinTerms.isEmpty) {
      return true;
    }

    final text = '${item.title} ${item.snippet} ${item.url}';
    for (final term in hanTerms) {
      if (text.contains(term)) return true;
    }

    final itemTokens = SearchReferenceBundle._latinTokens(text);
    for (final term in latinTerms) {
      if (itemTokens.contains(term)) return true;
    }
    for (final term in aliasLatinTerms) {
      if (itemTokens.contains(term)) return true;
    }
    return false;
  }
}
