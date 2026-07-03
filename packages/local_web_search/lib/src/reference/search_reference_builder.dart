import 'dart:convert';

import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_reference_bundle.dart';
import 'package:local_web_search/src/models/search_reference_request.dart';
import 'package:local_web_search/src/query/search_query_generator.dart';

class SearchReferenceBuilder {
  static const int defaultMaxSources = 8;

  const SearchReferenceBuilder._();

  static List<String> parseMessageLines(String text) {
    final messages = <String>[];
    final lines = const LineSplitter().convert(text);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      messages.add(trimmed);
    }
    return messages;
  }

  static String buildQuery(List<String> messages) {
    return SearchQueryGenerator.build(messages).query;
  }

  static SearchReferenceBundle buildBundle({
    required List<String> messages,
    SearchEngine searchEngine = SearchEngines.google,
    required String query,
    required SearchExtractionResult extraction,
    int maxSources = defaultMaxSources,
  }) {
    return SearchReferenceBundle.fromExtraction(
      request: SearchReferenceRequest(
        messages: messages,
        maxSources: maxSources,
      ),
      searchEngine: searchEngine,
      query: query,
      extraction: extraction,
    );
  }
}
