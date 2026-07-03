import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_reference_request.dart';
import 'package:local_web_search/src/models/search_reference_source.dart';

class SearchReferenceBundle {
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
      searchEngine = SearchEngines.google,
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
    int rank = 1;
    for (final item in extraction.items) {
      if (sources.length >= sourceLimit) break;
      sources.add(
        SearchReferenceSource.fromSearchResultItem(rank: rank, item: item),
      );
      rank += 1;
    }

    return SearchReferenceBundle(
      request: request,
      searchEngine: searchEngine,
      query: query,
      sources: sources,
      promptContext: _buildPromptContext(query: query, sources: sources),
      rawJson: extraction.rawJson,
      error: extraction.error,
    );
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
