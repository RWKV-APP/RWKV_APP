import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_deep_result.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_reference_request.dart';
import 'package:local_web_search/src/models/search_reference_source.dart';
import 'package:local_web_search/src/models/search_result_item.dart';

class SearchReferenceBundle {
  static final RegExp _hanTermPattern = RegExp(
    r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]{2,}',
  );
  static final RegExp _hanTextPattern = RegExp(
    r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]+',
  );
  static final RegExp _spacePattern = RegExp(r'\s+');
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

  static const Set<String> _hanQueryStopTerms = <String>{
    '告诉我',
    '请问',
    '帮我',
    '给我',
    '现在',
    '大概',
    '目前',
    '最近',
    '几年',
    '讲讲',
    '查查',
    '看看',
    '一下',
    '有多少',
    '多少',
    '什么',
    '怎么',
    '如何',
    '为什么',
    '哪里',
    '哪个',
    '哪些',
    '是否',
    '是不是',
    '能不能',
    '可以',
    '需要',
    '更大',
    '数量',
    '总数',
    '数据',
    '情况',
    '信息',
    '介绍',
    '的是',
    '的吗',
    '吗',
    '呢',
    '的',
    '了',
    '是',
    '有',
    '条',
    '只',
    '个',
  };

  static const List<String> _hanKnownTerms = <String>[
    '中国',
    '深圳',
    '广州',
    '香港',
    '世界',
    '省级行政区',
    '国土面积',
    '陆地面积',
    '办什么证',
    '人口',
    '面积',
    '行政区',
    '高铁',
    '养犬',
    '养狗',
    '登记',
    '犬只',
    '宠物犬',
    '狗',
    '犬',
    '历史',
    '发展',
    '城市',
    '国家',
    '模型',
    '最新款',
    '比亚迪',
    '周末',
    '地方',
  ];

  static const Map<String, List<String>> _termAliases = <String, List<String>>{
    '中国': <String>['china', 'chinese', 'prc', 'people republic'],
    '巴黎': <String>['paris'],
  };

  static const Map<String, List<String>> _hanTermAliases =
      <String, List<String>>{
        '中国': <String>['中华人民共和国', '中華人民共和國', '中國'],
        '狗': <String>['犬', '犬只', '宠物', '宠物犬', '犬猫'],
        '犬': <String>['狗', '犬只', '宠物', '宠物犬', '犬猫'],
        '犬只': <String>['狗', '犬', '养犬', '宠物', '宠物犬', '犬猫'],
        '养犬': <String>['狗', '犬', '犬只', '宠物', '宠物犬', '犬猫'],
        '养狗': <String>['狗', '犬', '犬只', '养犬', '宠物犬', '犬猫'],
        '宠物': <String>['狗', '犬', '犬只', '宠物犬', '犬猫'],
      };
  static const Set<String> _dogContextTerms = <String>{
    '狗',
    '犬',
    '犬只',
    '养犬',
    '养狗',
    '宠物犬',
    '犬猫',
  };

  final SearchReferenceRequest request;
  final SearchEngine searchEngine;
  final String query;
  final List<SearchReferenceSource> sources;
  final List<SearchDeepResult> deepResults;
  final String promptContext;
  final String deepPromptContext;
  final String rawJson;
  final String? error;

  const SearchReferenceBundle({
    required this.request,
    required this.searchEngine,
    required this.query,
    required this.sources,
    required this.deepResults,
    required this.promptContext,
    required this.deepPromptContext,
    required this.rawJson,
    this.error,
  });

  const SearchReferenceBundle.empty()
    : request = const SearchReferenceRequest.empty(),
      searchEngine = SearchEngines.bing,
      query = '',
      sources = const <SearchReferenceSource>[],
      deepResults = const <SearchDeepResult>[],
      promptContext = '',
      deepPromptContext = '',
      rawJson = '',
      error = null;

  bool get hasError => error != null && error!.isNotEmpty;

  bool get hasSources => sources.isNotEmpty;

  bool get hasDeepResults {
    for (final result in deepResults) {
      if (result.hasContent) return true;
    }
    return false;
  }

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
      deepResults: const <SearchDeepResult>[],
      promptContext: _buildPromptContext(query: query, sources: sources),
      deepPromptContext: '',
      rawJson: extraction.rawJson,
      error: extraction.error ?? relevanceError,
    );
  }

  SearchReferenceBundle copyWith({
    SearchReferenceRequest? request,
    SearchEngine? searchEngine,
    String? query,
    List<SearchReferenceSource>? sources,
    List<SearchDeepResult>? deepResults,
    String? promptContext,
    String? deepPromptContext,
    String? rawJson,
    String? error,
  }) {
    return SearchReferenceBundle(
      request: request ?? this.request,
      searchEngine: searchEngine ?? this.searchEngine,
      query: query ?? this.query,
      sources: sources ?? this.sources,
      deepResults: deepResults ?? this.deepResults,
      promptContext: promptContext ?? this.promptContext,
      deepPromptContext: deepPromptContext ?? this.deepPromptContext,
      rawJson: rawJson ?? this.rawJson,
      error: error ?? this.error,
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
    terms.addAll(_hanQueryTerms(text));
    return terms;
  }

  static Set<String> _hanQueryTerms(String text) {
    final terms = <String>{};
    final matches = _hanTextPattern.allMatches(text);
    for (final match in matches) {
      String value = match.group(0) ?? '';
      if (value.isEmpty) continue;
      for (final stopTerm in _hanQueryStopTerms) {
        value = value.replaceAll(stopTerm, ' ');
      }
      final fragments = value.split(_spacePattern);
      for (final fragment in fragments) {
        final term = fragment.trim();
        if (term.isEmpty) continue;
        if (_lowSignalTerms.contains(term)) continue;
        terms.add(term);
        terms.addAll(_knownHanTerms(term));
      }
    }
    return terms;
  }

  static Set<String> _knownHanTerms(String text) {
    final terms = <String>{};
    for (final knownTerm in _hanKnownTerms) {
      if (!text.contains(knownTerm)) continue;
      bool covered = false;
      for (final selectedTerm in terms) {
        if (!selectedTerm.contains(knownTerm)) continue;
        covered = true;
        break;
      }
      if (covered) continue;
      terms.add(knownTerm);
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

  static Set<String> _hanAliasTerms(Set<String> hanTerms) {
    final aliases = <String>{};
    for (final term in hanTerms) {
      final mapped = _hanTermAliases[term];
      if (mapped == null) continue;
      for (final alias in mapped) {
        if (_lowSignalTerms.contains(alias)) continue;
        aliases.add(alias);
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

  static String buildDeepPromptContext({
    required String query,
    required List<SearchDeepResult> results,
  }) {
    final usableResults = <SearchDeepResult>[];
    for (final result in results) {
      if (!result.hasContent) continue;
      usableResults.add(result);
    }
    if (usableResults.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('Search query: $query');
    buffer.writeln();
    buffer.writeln('Deep page results for the next answer:');
    for (final result in usableResults) {
      buffer.writeln();
      buffer.writeln(result.toPromptBlock());
    }
    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request': request.toJson(),
      'searchEngine': searchEngine.toJson(),
      'query': query,
      'sources': sources.map((source) => source.toJson()).toList(),
      'deepResults': deepResults.map((result) => result.toJson()).toList(),
      'promptContext': promptContext,
      'deepPromptContext': deepPromptContext,
      'rawJson': rawJson,
      'error': error,
    };
  }
}

class _SearchRelevanceTerms {
  final Set<String> hanTerms;
  final Set<String> hanAliasTerms;
  final Set<String> latinTerms;
  final Set<String> aliasLatinTerms;
  final bool requiresDogContext;

  const _SearchRelevanceTerms({
    required this.hanTerms,
    required this.hanAliasTerms,
    required this.latinTerms,
    required this.aliasLatinTerms,
    required this.requiresDogContext,
  });

  factory _SearchRelevanceTerms.fromQuery(String query) {
    final hanTerms = SearchReferenceBundle._hanTerms(query);
    final hanAliasTerms = SearchReferenceBundle._hanAliasTerms(hanTerms);
    final latinTerms = SearchReferenceBundle._latinTokens(query);
    final aliasLatinTerms = SearchReferenceBundle._aliasTokens(hanTerms);
    return _SearchRelevanceTerms(
      hanTerms: hanTerms,
      hanAliasTerms: hanAliasTerms,
      latinTerms: latinTerms,
      aliasLatinTerms: aliasLatinTerms,
      requiresDogContext:
          _containsDogContext(hanTerms) || _containsDogContext(hanAliasTerms),
    );
  }

  bool matches(SearchResultItem item) {
    if (hanTerms.isEmpty &&
        hanAliasTerms.isEmpty &&
        latinTerms.isEmpty &&
        aliasLatinTerms.isEmpty) {
      return true;
    }

    final text = '${item.title} ${item.snippet} ${item.url}';
    if (requiresDogContext && !_textContainsDogContext(text)) return false;

    for (final term in hanTerms) {
      if (text.contains(term)) return true;
    }
    for (final term in hanAliasTerms) {
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

  static bool _containsDogContext(Set<String> terms) {
    for (final term in terms) {
      if (SearchReferenceBundle._dogContextTerms.contains(term)) return true;
    }
    return false;
  }

  static bool _textContainsDogContext(String text) {
    for (final term in SearchReferenceBundle._dogContextTerms) {
      if (text.contains(term)) return true;
    }
    return false;
  }
}
