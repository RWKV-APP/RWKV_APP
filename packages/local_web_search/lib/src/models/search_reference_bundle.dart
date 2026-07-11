import 'package:local_web_search/src/models/search_extraction_result.dart';
import 'package:local_web_search/src/models/search_deep_result.dart';
import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_reference_request.dart';
import 'package:local_web_search/src/models/search_reference_source.dart';
import 'package:local_web_search/src/models/search_result_item.dart';
import 'package:local_web_search/src/query/search_query_generator.dart';

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
  static final RegExp _sameDayRelativeTimePattern = RegExp(
    r'刚刚|\d+\s*(?:分钟|小时)前|\btoday\b|\b\d+\s+(?:minute|hour)s?\s+ago\b',
    caseSensitive: false,
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
    DateTime? currentDate,
  }) {
    final resolvedCurrentDate = currentDate ?? DateTime.now();
    final sourceLimit = request.maxSources < 0 ? 0 : request.maxSources;
    final sources = <SearchReferenceSource>[];
    final relevanceTerms = _SearchRelevanceTerms.fromQuery(query);
    final trustSearchRanking = SearchQueryGenerator.isTimeSensitiveNewsQuery(
      query,
    );
    int rank = 1;
    for (final item in extraction.items) {
      if (sources.length >= sourceLimit) break;
      if (!trustSearchRanking && !relevanceTerms.matches(item)) continue;
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
      promptContext: _buildPromptContext(
        query: query,
        sources: sources,
        currentDate: resolvedCurrentDate,
      ),
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
    required DateTime currentDate,
  }) {
    if (sources.isEmpty) return '';

    final buffer = StringBuffer();
    _writeTemporalInstructions(
      buffer: buffer,
      query: query,
      currentDate: currentDate,
    );
    _writeFreshnessVerificationForSources(
      buffer: buffer,
      query: query,
      currentDate: currentDate,
      sources: sources,
    );
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
    DateTime? currentDate,
  }) {
    final usableResults = <SearchDeepResult>[];
    for (final result in results) {
      if (!result.hasContent) continue;
      usableResults.add(result);
    }
    if (usableResults.isEmpty) return '';

    final resolvedCurrentDate = currentDate ?? DateTime.now();
    final buffer = StringBuffer();
    _writeTemporalInstructions(
      buffer: buffer,
      query: query,
      currentDate: resolvedCurrentDate,
    );
    _writeFreshnessVerificationForDeepResults(
      buffer: buffer,
      query: query,
      currentDate: resolvedCurrentDate,
      results: usableResults,
    );
    buffer.writeln('Search query: $query');
    buffer.writeln();
    buffer.writeln('Deep page results for the next answer:');
    for (final result in usableResults) {
      buffer.writeln();
      buffer.writeln(result.toPromptBlock());
    }
    return buffer.toString().trimRight();
  }

  static void _writeTemporalInstructions({
    required StringBuffer buffer,
    required String query,
    required DateTime currentDate,
  }) {
    final month = currentDate.month.toString().padLeft(2, '0');
    final day = currentDate.day.toString().padLeft(2, '0');
    final isoDate = '${currentDate.year}-$month-$day';
    final hasHan = _hanTextPattern.hasMatch(query);
    if (hasHan) {
      buffer.writeln(
        '当前日期: ${currentDate.year}年${currentDate.month}月${currentDate.day}日 ($isoDate)',
      );
    } else {
      buffer.writeln('Current date: $isoDate');
    }

    if (!SearchQueryGenerator.isTimeSensitiveNewsQuery(query)) {
      buffer.writeln();
      return;
    }

    if (hasHan) {
      buffer.writeln(
        '时效要求: 用户所说的“今天”或“今日”均指上述当前日期。只陈述来源明确支持的日期和事实；不得把模型记忆中的旧年份当作今天，不得编造日期或新闻。来源不足时必须明确说明。',
      );
      buffer.writeln('引用要求: 每条具体新闻使用 [来源 N] 标注，并在回答末尾列出实际使用的来源标题和 URL。');
    } else {
      buffer.writeln(
        'Freshness requirement: Today means the current date above. Only state dates and facts explicitly supported by the sources. Do not substitute old model knowledge or invent dates or news. Clearly say when the sources are insufficient.',
      );
      buffer.writeln(
        'Citation requirement: Mark each specific news item with [Source N], then list the titles and URLs actually used.',
      );
    }
    buffer.writeln();
  }

  static void _writeFreshnessVerificationForSources({
    required StringBuffer buffer,
    required String query,
    required DateTime currentDate,
    required List<SearchReferenceSource> sources,
  }) {
    if (!SearchQueryGenerator.isTimeSensitiveNewsQuery(query)) return;
    final evidenceRanks = <int>[];
    for (final source in sources) {
      final text = '${source.title} ${source.summary} ${source.url}';
      if (!_hasSameDayEvidence(text, currentDate)) continue;
      evidenceRanks.add(source.rank);
    }
    _writeFreshnessVerification(
      buffer: buffer,
      currentDate: currentDate,
      evidenceRanks: evidenceRanks,
      sourceCount: sources.length,
      hasHan: _hanTextPattern.hasMatch(query),
      sourceLabel: '来源',
    );
  }

  static void _writeFreshnessVerificationForDeepResults({
    required StringBuffer buffer,
    required String query,
    required DateTime currentDate,
    required List<SearchDeepResult> results,
  }) {
    if (!SearchQueryGenerator.isTimeSensitiveNewsQuery(query)) return;
    final evidenceRanks = <int>[];
    for (final result in results) {
      final text = '${result.title} ${result.markdown} ${result.url}';
      if (!_hasSameDayEvidence(text, currentDate)) continue;
      evidenceRanks.add(result.rank);
    }
    _writeFreshnessVerification(
      buffer: buffer,
      currentDate: currentDate,
      evidenceRanks: evidenceRanks,
      sourceCount: results.length,
      hasHan: _hanTextPattern.hasMatch(query),
      sourceLabel: 'Deep',
    );
  }

  static void _writeFreshnessVerification({
    required StringBuffer buffer,
    required DateTime currentDate,
    required List<int> evidenceRanks,
    required int sourceCount,
    required bool hasHan,
    required String sourceLabel,
  }) {
    final month = currentDate.month.toString().padLeft(2, '0');
    final day = currentDate.day.toString().padLeft(2, '0');
    final isoDate = '${currentDate.year}-$month-$day';
    if (evidenceRanks.isEmpty) {
      if (hasHan) {
        buffer.writeln(
          '当日证据核验: $sourceCount 个来源中，没有来源能从标题、摘要、正文或 URL 确认发布/更新于 $isoDate。禁止将这些来源列为“今日新闻”；回答必须明确说明当前检索没有找到可验证的当日新闻证据。',
        );
      } else {
        buffer.writeln(
          'Same-day evidence check: None of the $sourceCount sources can be verified from its title, summary, content, or URL as published or updated on $isoDate. Do not list them as today\'s news. State clearly that the search found no verifiable same-day news evidence.',
        );
      }
      buffer.writeln();
      return;
    }

    final labels = <String>[];
    for (final rank in evidenceRanks) {
      labels.add('[$sourceLabel $rank]');
    }
    if (hasHan) {
      buffer.writeln(
        '当日证据核验: 只有 ${labels.join('、')} 可从现有文本确认与 $isoDate 同日。今日新闻列表只能使用这些来源；其余来源只能标为背景资料或旧信息。',
      );
    } else {
      buffer.writeln(
        'Same-day evidence check: Only ${labels.join(', ')} can be verified from the available text as current on $isoDate. Use only these for today\'s news; label all others as background or older information.',
      );
    }
    buffer.writeln();
  }

  static bool _hasSameDayEvidence(String text, DateTime currentDate) {
    if (_sameDayRelativeTimePattern.hasMatch(text)) return true;
    final month = currentDate.month.toString().padLeft(2, '0');
    final day = currentDate.day.toString().padLeft(2, '0');
    final datePatterns = <String>{
      '${currentDate.year}年${currentDate.month}月${currentDate.day}日',
      '${currentDate.year}年$month月$day日',
      '${currentDate.year}-$month-$day',
      '${currentDate.year}/$month/$day',
      '${currentDate.year}.$month.$day',
      '${currentDate.year}$month$day',
    };
    final lower = text.toLowerCase();
    for (final pattern in datePatterns) {
      if (lower.contains(pattern.toLowerCase())) return true;
    }
    return false;
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
