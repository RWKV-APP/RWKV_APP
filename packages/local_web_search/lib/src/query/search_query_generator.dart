import 'dart:convert';
import 'dart:math';

import 'package:local_web_search/src/models/search_query_generation_result.dart';

class SearchQueryGeneratorConfig {
  final int maxQueryLength;
  final int maxLatestTerms;
  final int maxHistoryTerms;
  final int maxSupportingMessages;
  final int maxCandidateTerms;

  const SearchQueryGeneratorConfig({
    this.maxQueryLength = 160,
    this.maxLatestTerms = 10,
    this.maxHistoryTerms = 5,
    this.maxSupportingMessages = 4,
    this.maxCandidateTerms = 24,
  });
}

class SearchQueryGenerator {
  static const String _rwkvUserMessageModifierSeparator =
      'G7!k9#rVq2@Xz8LpY4m%';

  static final RegExp _rolePrefixPattern = RegExp(
    r'^\s*([A-Za-z][A-Za-z _-]{0,31}|用户|助手|系统)\s*[:：]\s*(.*)$',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _whitespacePattern = RegExp(r'\s+');
  static final RegExp _codeFencePattern = RegExp(r'```+');
  static final RegExp _urlPattern = RegExp(r'https?://[^\s)>\]]+');
  static final RegExp _tokenPattern = RegExp(
    r'[A-Za-z][A-Za-z0-9._/+:#-]{1,}|[0-9]+(?:\.[0-9]+)+|[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]{2,}',
  );
  static final RegExp _hanOnlyPattern = RegExp(
    r'^[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]+$',
  );
  static final RegExp _contextReferencePattern = RegExp(
    r'\b(this|that|it|they|those|these|above|previous|same)\b|这个|它|他们|它们|上面|刚才|前面|继续|同样|这个问题',
    caseSensitive: false,
  );
  static final RegExp _historyBlockingActionPattern = RegExp(
    r'^\s*(write|draft|translate|summarize|rewrite|polish|act as|roleplay|create|build|make|implement)\b|^\s*(请|帮我|你帮我)?\s*(写|改写|润色|翻译|总结|扮演|继续写|创建|制作|实现|生成|策划)',
    caseSensitive: false,
  );
  static final RegExp _opaqueStandalonePattern = RegExp(
    r'^\s*[A-Za-z0-9+/=_-]{24,}\s*$',
  );
  static final RegExp _mathWorkoutPattern = RegExp(
    r'\b(derivative|integral|limit definition|first principles|algebraic step)\b|函数|求导|导数|定积分|极大值|极小值|极值|计算步骤|完整步骤',
    caseSensitive: false,
  );
  static final RegExp _casualShortPattern = RegExp(
    r'^\s*(hi|hello|hey|thanks|thank you|ok|okay|yes|no|continue|go on|lol|ha+|你好|您好|谢谢|好的|可以|继续|收到|嗯|哦|行|哈+)\s*[。.!！?？]*\s*$',
    caseSensitive: false,
  );
  static final RegExp _laughTokenPattern = RegExp(
    r'^(ha)+h?$|^哈+$',
    caseSensitive: false,
  );
  static final RegExp _queryShellPrefixPattern = RegExp(
    r'^\s*(please\s+)?((can|could|would)\s+you\s+)?(help\s+me\s+)?(search\s+for|look\s+up|find|帮我|请|麻烦|能不能|你能不能|搜索一下|查一下|查找|搜一下|给我讲讲|我讲讲|讲讲|介绍一下|给我介绍一下|说说|给我说说|聊聊|告诉我)\s*',
    caseSensitive: false,
  );

  static final Set<String> _stopWords = <String>{
    'a',
    'about',
    'after',
    'an',
    'and',
    'are',
    'as',
    'before',
    'by',
    'can',
    'complete',
    'could',
    'create',
    'do',
    'document',
    'describe',
    'does',
    'doesn',
    'explain',
    'feature',
    'find',
    'for',
    'from',
    'get',
    'help',
    'how',
    'if',
    'he',
    'her',
    'him',
    'his',
    'i',
    "i'm",
    "i've",
    'in',
    'into',
    'is',
    'it',
    'me',
    'need',
    'needs',
    'of',
    'on',
    'or',
    'own',
    'over',
    'only',
    'one',
    'page',
    'please',
    'provide',
    'reference',
    'references',
    'reliable',
    'result',
    'results',
    'source',
    'sources',
    'summaries',
    'summary',
    'that',
    'the',
    'this',
    'their',
    'them',
    'they',
    'to',
    'up',
    'url',
    'urls',
    'use',
    'uses',
    'using',
    'return',
    'what',
    'when',
    'where',
    'why',
    'without',
    'with',
    'would',
    'you',
    'your',
    '一下',
    '一个',
    '这个',
    '什么',
    '包含',
    '如何',
    '怎么',
    '我们',
    '可以',
    '帮我',
    '请问',
  };

  static final Set<String> _lowSignalTerms = <String>{
    'coming',
    'getting',
    'hear',
    'heard',
    'heavily',
    'my',
    'often',
    'repeating',
    'thinks',
    'things',
    'very',
    "doesn't",
    'doesnt',
  };

  static final List<String> _chineseSplitMarkers = <String>[
    '而非仅仅是',
    '不仅仅是',
    '过一段时间',
    '重点放在',
    '因为',
    '包括',
    '包含',
    '以及',
    '或者',
    '还是',
    '但是',
    '并且',
    '然后',
    '而非',
    '不是',
    '一想到',
    '一聊',
    '全都',
    '这样来说',
    '用代码实现一个简单',
    '用代码实现',
    '实现一个简单',
    '请帮我',
    '你帮我',
    '帮我',
    '请问',
    '请',
    '解释',
    '把这个',
    '如何',
    '怎么',
    '利用',
    '进行',
    '中的',
    '让我能',
    '而不是',
    '让',
    '和',
    '与',
    '或',
    '但',
    '把',
    '给',
    '就',
  ];

  static final List<String> _chineseNoiseFragments = <String>[
    '我最近在',
    '我每次',
    '我想找',
    '我想',
    '想要不要',
    '要不要',
    '把这个',
    '让我能',
    '而不是',
    '这个问题',
    '这样来说',
    '上有什么坑',
    '有什么坑',
    '有哪些坑',
    '一想到',
    '一聊',
    '先怂',
    '就',
    '这本书',
    '读的',
    '内容',
    '大部分',
    '全都',
    '要算进去',
    '算进去',
    '做一个',
    '实现一个',
    '给我讲讲',
    '我讲讲',
    '讲讲',
    '介绍一下',
    '给我介绍一下',
    '说说',
    '给我说说',
    '聊聊',
    '告诉我',
    '列一份',
    '拆成',
    '谈话',
    '比较',
    '冷静地',
    '冷静的',
    '即可',
    '仅仅是',
    '没有任何',
    '是不是',
    '头大',
    '总觉得自己像在',
    '自己像在',
    '求人',
    '上来',
    '对方',
    '三部分',
    '聊',
    '的',
    '但',
    '因为',
  ];

  static final List<String> _chineseTrimPrefixes = <String>[
    '现在',
    '关于',
    '请用',
    '请求',
    '请',
    '解释',
    '用代码',
    '因为',
    '但是',
    '但',
    '而非',
    '不是',
    '帮我',
    '你帮我',
    '给我讲讲',
    '我讲讲',
    '讲讲',
    '介绍一下',
    '给我介绍一下',
    '说说',
    '给我说说',
    '聊聊',
    '告诉我',
    '我最近在',
    '我想找',
    '我想',
    '实现一个',
    '孩子即将',
    '即将',
  ];

  static final List<String> _chineseTrimSuffixes = <String>[
    '的话',
    '这个问题',
    '这个场景',
    '这个谈话',
    '这本书',
    '之后',
    '上',
    '呢',
    '吗',
    '了',
  ];

  const SearchQueryGenerator._();

  static SearchQueryGenerationResult build(
    List<String> messages, {
    SearchQueryGeneratorConfig config = const SearchQueryGeneratorConfig(),
  }) {
    final parsedMessages = parseMessages(messages);
    if (parsedMessages.isEmpty) {
      return const SearchQueryGenerationResult.empty();
    }

    final latestUserMessage = _latestUserMessage(parsedMessages);
    if (latestUserMessage == null) {
      return SearchQueryGenerationResult(
        shouldSearch: false,
        query: '',
        reason: 'No user message was found.',
        latestUserMessage: null,
        parsedMessages: parsedMessages,
        supportingMessages: const <SearchHistoryIndexEntry>[],
        ignoredMessages: _ignoredMessages(
          parsedMessages,
          latestUserIndex: null,
        ),
        candidateTerms: const <SearchQueryTerm>[],
        rollingContext: const SearchRollingContext.empty(),
        usedHistory: false,
      );
    }

    final index = _buildIndex(parsedMessages);
    final latestTerms = _extractSearchTerms(latestUserMessage.content);
    final needsHistory = _needsHistoryAssist(
      latestUserMessage.content,
      latestTerms,
    );
    final supportingMessages = _supportingMessages(
      parsedMessages: parsedMessages,
      latestUserMessage: latestUserMessage,
      index: index,
      latestTerms: latestTerms,
      needsHistory: needsHistory,
      maxSupportingMessages: config.maxSupportingMessages,
    );
    final rollingContext = _buildRollingContext(
      parsedMessages: parsedMessages,
      latestUserMessage: latestUserMessage,
      index: index,
      latestTerms: latestTerms,
    );
    final candidateTerms = _scoreTerms(
      latestUserMessage: latestUserMessage,
      latestTerms: latestTerms,
      supportingMessages: supportingMessages,
      rollingContext: rollingContext,
      maxCandidateTerms: config.maxCandidateTerms,
    );
    final query = _buildQueryFromTerms(
      latestTerms: latestTerms,
      candidateTerms: candidateTerms,
      needsHistory: needsHistory,
      config: config,
      latestFallback: latestUserMessage.content,
    );
    final shouldSearch = query.isNotEmpty;

    return SearchQueryGenerationResult(
      shouldSearch: shouldSearch,
      query: query,
      reason: _buildReason(
        shouldSearch: shouldSearch,
        needsHistory: needsHistory,
        latestTerms: latestTerms,
        supportingMessages: supportingMessages,
      ),
      latestUserMessage: latestUserMessage,
      parsedMessages: parsedMessages,
      supportingMessages: supportingMessages,
      ignoredMessages: _ignoredMessages(
        parsedMessages,
        latestUserIndex: latestUserMessage.index,
      ),
      candidateTerms: candidateTerms,
      rollingContext: rollingContext,
      usedHistory: shouldSearch && supportingMessages.isNotEmpty,
    );
  }

  static List<SearchConversationMessage> parseLines(String text) {
    return parseMessages(const LineSplitter().convert(text));
  }

  static List<SearchConversationMessage> parseMessages(List<String> messages) {
    final parsed = <SearchConversationMessage>[];
    for (int index = 0; index < messages.length; index += 1) {
      final raw = messages[index].trim();
      if (raw.isEmpty) continue;
      final parsedRole = _parseRoleAndContent(raw);
      final content = _normalizeMessageContent(parsedRole.content);
      if (content.isEmpty) continue;
      parsed.add(
        SearchConversationMessage(
          index: index,
          role: parsedRole.role,
          rawText: raw,
          content: content,
        ),
      );
    }
    return parsed;
  }

  static ({SearchMessageRole role, String content}) _parseRoleAndContent(
    String raw,
  ) {
    final match = _rolePrefixPattern.firstMatch(raw);
    if (match == null) {
      return (role: .unknown, content: raw);
    }

    final roleText = (match.group(1) ?? '').trim().toLowerCase();
    final content = match.group(2) ?? '';
    if (roleText == 'user' ||
        roleText == 'human' ||
        roleText == 'me' ||
        roleText == '用户') {
      return (role: .user, content: content);
    }
    if (roleText == 'assistant' ||
        roleText == 'bot' ||
        roleText == 'model' ||
        roleText == '助手') {
      return (role: .assistant, content: content);
    }
    if (roleText == 'system' || roleText == '系统') {
      return (role: .system, content: content);
    }
    return (role: .unknown, content: content);
  }

  static SearchConversationMessage? _latestUserMessage(
    List<SearchConversationMessage> messages,
  ) {
    for (int index = messages.length - 1; index >= 0; index -= 1) {
      final message = messages[index];
      if (message.isUser) return message;
    }
    return null;
  }

  static String _normalizeMessageContent(String text) {
    final withoutModifier = text.split(_rwkvUserMessageModifierSeparator).first;
    final withoutCodeFences = withoutModifier.replaceAll(
      _codeFencePattern,
      ' ',
    );
    final compact = withoutCodeFences
        .replaceAll(_whitespacePattern, ' ')
        .replaceAll('\u0000', ' ')
        .trim();
    return _trimSentencePunctuation(compact);
  }

  static List<SearchHistoryIndexEntry> _buildIndex(
    List<SearchConversationMessage> messages,
  ) {
    final entries = <SearchHistoryIndexEntry>[];
    for (final message in messages) {
      final terms = _extractSearchTerms(message.content);
      if (terms.isEmpty) continue;
      entries.add(
        SearchHistoryIndexEntry(
          messageIndex: message.index,
          role: message.role,
          terms: terms,
          relevanceScore: 0,
          preview: _preview(message.content),
        ),
      );
    }
    return entries;
  }

  static SearchRollingContext _buildRollingContext({
    required List<SearchConversationMessage> parsedMessages,
    required SearchConversationMessage latestUserMessage,
    required List<SearchHistoryIndexEntry> index,
    required List<String> latestTerms,
  }) {
    final userEntries = <SearchHistoryIndexEntry>[];
    for (final entry in index) {
      if (entry.messageIndex == latestUserMessage.index) continue;
      if (entry.role != .user && entry.role != .unknown) continue;
      userEntries.add(entry);
    }

    final weightedTerms = <String, double>{};
    for (final entry in userEntries) {
      final recency = _recencyWeight(entry.messageIndex, parsedMessages.length);
      for (final term in entry.terms) {
        weightedTerms[term] = (weightedTerms[term] ?? 0) + recency;
      }
    }

    final sortedTerms = weightedTerms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topicTerms = sortedTerms.map((entry) => entry.key).take(8).toList();
    final activeEntities = sortedTerms
        .where((entry) => _looksLikeEntity(entry.key))
        .map((entry) => entry.key)
        .take(8)
        .toList();
    final recentUserTerms = <String>[];
    for (final entry in userEntries.reversed.take(3)) {
      for (final term in entry.terms) {
        if (recentUserTerms.contains(term)) continue;
        recentUserTerms.add(term);
      }
    }

    return SearchRollingContext(
      topicTerms: topicTerms,
      activeEntities: activeEntities,
      recentUserTerms: recentUserTerms.take(12).toList(),
      latestUserTerms: latestTerms.take(12).toList(),
    );
  }

  static bool _needsHistoryAssist(
    String latestContent,
    List<String> latestTerms,
  ) {
    if (_contextReferencePattern.hasMatch(latestContent)) return true;
    if (latestTerms.length <= 2) return true;
    return latestContent.trim().length <= 18;
  }

  static List<SearchHistoryIndexEntry> _supportingMessages({
    required List<SearchConversationMessage> parsedMessages,
    required SearchConversationMessage latestUserMessage,
    required List<SearchHistoryIndexEntry> index,
    required List<String> latestTerms,
    required bool needsHistory,
    required int maxSupportingMessages,
  }) {
    final latestKeys = latestTerms.map(_termKey).toSet();
    final scored = <SearchHistoryIndexEntry>[];
    for (final entry in index) {
      if (entry.messageIndex >= latestUserMessage.index) continue;
      if (entry.role != .user && entry.role != .unknown) continue;
      final sourceMessage = _messageForIndex(
        parsedMessages,
        entry.messageIndex,
      );
      if (latestTerms.isEmpty &&
          sourceMessage != null &&
          _blocksPureReferenceHistory(sourceMessage.content)) {
        continue;
      }

      double score = _recencyWeight(entry.messageIndex, parsedMessages.length);
      for (final term in entry.terms) {
        if (latestKeys.contains(_termKey(term))) score += 6;
        if (_looksLikeEntity(term)) score += 2;
      }
      if (needsHistory) score += 5;
      if (score <= 0) continue;

      scored.add(
        SearchHistoryIndexEntry(
          messageIndex: entry.messageIndex,
          role: entry.role,
          terms: entry.terms,
          relevanceScore: score,
          preview: entry.preview,
        ),
      );
    }
    scored.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return scored.take(maxSupportingMessages).toList();
  }

  static SearchConversationMessage? _messageForIndex(
    List<SearchConversationMessage> messages,
    int messageIndex,
  ) {
    for (final message in messages) {
      if (message.index == messageIndex) return message;
    }
    return null;
  }

  static bool _blocksPureReferenceHistory(String content) {
    if (_mathWorkoutPattern.hasMatch(content)) return true;
    if (_opaqueStandalonePattern.hasMatch(content)) return true;
    return _historyBlockingActionPattern.hasMatch(content);
  }

  static List<SearchQueryTerm> _scoreTerms({
    required SearchConversationMessage latestUserMessage,
    required List<String> latestTerms,
    required List<SearchHistoryIndexEntry> supportingMessages,
    required SearchRollingContext rollingContext,
    required int maxCandidateTerms,
  }) {
    final scoredTerms = <String, _MutableScoredTerm>{};

    void addTerm({
      required String term,
      required double score,
      required int messageIndex,
      required String reason,
      required bool fromLatest,
    }) {
      final normalized = _normalizeTerm(term);
      if (!_isUsefulTerm(normalized)) return;
      final key = _termKey(normalized);
      final current = scoredTerms[key] ?? _MutableScoredTerm(value: normalized);
      current.score += score;
      current.occurrences += 1;
      current.fromLatestUserMessage =
          current.fromLatestUserMessage || fromLatest;
      if (!current.messageIndexes.contains(messageIndex)) {
        current.messageIndexes.add(messageIndex);
      }
      if (!current.reasons.contains(reason)) {
        current.reasons.add(reason);
      }
      if (_looksLikeEntity(normalized)) {
        current.score += 4;
        if (!current.reasons.contains('entity')) current.reasons.add('entity');
      }
      scoredTerms[key] = current;
    }

    for (final term in latestTerms) {
      addTerm(
        term: term,
        score: 100,
        messageIndex: latestUserMessage.index,
        reason: 'latest_user_message',
        fromLatest: true,
      );
    }

    for (final entry in supportingMessages) {
      for (final term in entry.terms) {
        addTerm(
          term: term,
          score: 18 + entry.relevanceScore,
          messageIndex: entry.messageIndex,
          reason: 'history_support',
          fromLatest: false,
        );
      }
    }

    for (final term in rollingContext.activeEntities) {
      addTerm(
        term: term,
        score: 12,
        messageIndex: latestUserMessage.index,
        reason: 'rolling_context_entity',
        fromLatest: false,
      );
    }

    final sorted = scoredTerms.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted
        .take(maxCandidateTerms)
        .map(
          (term) => SearchQueryTerm(
            value: term.value,
            score: _roundScore(term.score),
            occurrences: term.occurrences,
            fromLatestUserMessage: term.fromLatestUserMessage,
            messageIndexes: List<int>.unmodifiable(term.messageIndexes),
            reasons: List<String>.unmodifiable(term.reasons),
          ),
        )
        .toList();
  }

  static String _buildQueryFromTerms({
    required List<String> latestTerms,
    required List<SearchQueryTerm> candidateTerms,
    required bool needsHistory,
    required SearchQueryGeneratorConfig config,
    required String latestFallback,
  }) {
    final queryTerms = <String>[];
    final seen = <String>{};

    void add(String term) {
      final normalized = _normalizeTerm(term);
      if (!_isUsefulTerm(normalized)) return;
      final key = _termKey(normalized);
      if (seen.contains(key)) return;
      seen.add(key);
      queryTerms.add(normalized);
    }

    final prioritizedLatestTerms = _prioritizeLatestTerms(latestTerms);
    for (final term in prioritizedLatestTerms.take(config.maxLatestTerms)) {
      add(term);
    }

    final historyTerms = candidateTerms.where((term) {
      if (term.fromLatestUserMessage) return false;
      if (needsHistory) return true;
      return term.reasons.contains('rolling_context_entity') &&
          term.score >= 18;
    });
    for (final term in historyTerms.take(config.maxHistoryTerms)) {
      add(term.value);
    }

    if (queryTerms.isEmpty) {
      return _fitQueryLength(
        _stripQueryShell(latestFallback),
        config.maxQueryLength,
      );
    }
    return _fitQueryLength(queryTerms.join(' '), config.maxQueryLength);
  }

  static List<String> _prioritizeLatestTerms(List<String> latestTerms) {
    final entityTerms = <String>[];
    final otherTerms = <String>[];
    for (final term in latestTerms) {
      if (_looksLikeEntity(term)) {
        entityTerms.add(term);
        continue;
      }
      otherTerms.add(term);
    }
    return <String>[...entityTerms, ...otherTerms];
  }

  static String _buildReason({
    required bool shouldSearch,
    required bool needsHistory,
    required List<String> latestTerms,
    required List<SearchHistoryIndexEntry> supportingMessages,
  }) {
    if (!shouldSearch) {
      return 'No query could be built from the latest user message.';
    }
    if (needsHistory && supportingMessages.isNotEmpty) {
      return 'Latest user message needs lightweight history support.';
    }
    if (latestTerms.isNotEmpty) {
      return 'Latest user message is specific enough for a direct query.';
    }
    return 'Built from normalized latest user message.';
  }

  static List<SearchIgnoredMessage> _ignoredMessages(
    List<SearchConversationMessage> messages, {
    required int? latestUserIndex,
  }) {
    final ignored = <SearchIgnoredMessage>[];
    for (final message in messages) {
      if (message.index == latestUserIndex) continue;
      if (message.role == .assistant || message.role == .system) {
        ignored.add(
          SearchIgnoredMessage(
            index: message.index,
            role: message.role,
            reason: 'assistant_or_system_message',
            preview: _preview(message.content),
          ),
        );
        continue;
      }
      ignored.add(
        SearchIgnoredMessage(
          index: message.index,
          role: message.role,
          reason: 'history_candidate_or_low_weight',
          preview: _preview(message.content),
        ),
      );
    }
    return ignored;
  }

  static List<String> _extractSearchTerms(String text) {
    final clean = _stripQueryShell(_normalizeMessageContent(text));
    final opaqueTerm = _normalizeTerm(clean);
    if (_opaqueStandalonePattern.hasMatch(opaqueTerm)) {
      return <String>[_fitQueryLength(opaqueTerm, 80)];
    }
    final terms = <String>[];
    final seenKeys = <String>{};
    final matches = _tokenPattern.allMatches(clean);
    for (final match in matches) {
      final term = match.group(0);
      if (term == null) continue;
      final expandedTerms = _expandSearchTerm(term);
      for (final expandedTerm in expandedTerms) {
        final normalized = _normalizeTerm(expandedTerm);
        if (!_isUsefulTerm(normalized)) continue;
        final key = _termKey(normalized);
        if (seenKeys.contains(key)) continue;
        seenKeys.add(key);
        terms.add(normalized);
      }
    }
    if (terms.isNotEmpty) return terms;
    final fallbackTerm = _normalizeTerm(clean);
    if (fallbackTerm.isNotEmpty &&
        !_casualShortPattern.hasMatch(clean) &&
        _isUsefulTerm(fallbackTerm)) {
      return <String>[_fitQueryLength(fallbackTerm, 80)];
    }
    return const <String>[];
  }

  static List<String> _expandSearchTerm(String term) {
    final normalized = _normalizeTerm(term);
    if (!_isLongChineseTerm(normalized)) return <String>[normalized];

    final phrases = _splitChineseTerm(normalized);
    if (phrases.isEmpty) return <String>[normalized];
    return phrases;
  }

  static bool _isLongChineseTerm(String term) {
    return term.length > 10 && _hanOnlyPattern.hasMatch(term);
  }

  static List<String> _splitChineseTerm(String term) {
    final pieces = <String>[term];
    for (final marker in _chineseSplitMarkers) {
      final nextPieces = <String>[];
      for (final piece in pieces) {
        final splitPieces = piece.split(marker);
        for (final splitPiece in splitPieces) {
          nextPieces.add(splitPiece);
        }
      }
      pieces
        ..clear()
        ..addAll(nextPieces);
    }

    final phrases = <String>[];
    final seen = <String>{};
    for (final piece in pieces) {
      final phrase = _cleanChinesePhrase(piece);
      if (phrase.length < 2) continue;
      if (phrase.length > 14) continue;
      if (seen.contains(phrase)) continue;
      seen.add(phrase);
      phrases.add(phrase);
    }
    return phrases;
  }

  static String _cleanChinesePhrase(String phrase) {
    String cleaned = phrase.trim();
    for (final fragment in _chineseNoiseFragments) {
      cleaned = cleaned.replaceAll(fragment, '');
    }
    bool changed = true;
    while (changed) {
      changed = false;
      for (final prefix in _chineseTrimPrefixes) {
        if (!cleaned.startsWith(prefix)) continue;
        cleaned = cleaned.substring(prefix.length).trim();
        changed = true;
      }
      for (final suffix in _chineseTrimSuffixes) {
        if (!cleaned.endsWith(suffix)) continue;
        cleaned = cleaned.substring(0, cleaned.length - suffix.length).trim();
        changed = true;
      }
    }
    return cleaned;
  }

  static String _stripQueryShell(String text) {
    String stripped = text.trim();
    for (int i = 0; i < 2; i += 1) {
      final next = stripped.replaceFirst(_queryShellPrefixPattern, '').trim();
      if (next == stripped) break;
      stripped = next;
    }
    return stripped;
  }

  static String _normalizeTerm(String term) {
    final withoutUrl = term.replaceAll(_urlPattern, ' ');
    final normalized = withoutUrl
        .replaceAll(_whitespacePattern, ' ')
        .replaceAll(RegExp(r'^[\s`"“”‘’.,;:!?。！？、，；：()\[\]{}<>]+'), '')
        .replaceAll(RegExp(r'[\s`"“”‘’.,;:!?。！？、，；：()\[\]{}<>]+$'), '')
        .trim();
    final withoutContextPrefix = normalized
        .replaceFirst(RegExp(r'^(这个在|那个在|这个|那个|这些|那些|它们|他们|它|上面|刚才|前面|继续)'), '')
        .trim();
    if (_hanOnlyPattern.hasMatch(withoutContextPrefix)) {
      return _cleanChinesePhrase(withoutContextPrefix);
    }
    return withoutContextPrefix;
  }

  static bool _isUsefulTerm(String term) {
    if (term.isEmpty) return false;
    final key = _termKey(term);
    if (_stopWords.contains(key)) return false;
    if (_lowSignalTerms.contains(key)) return false;
    if (_laughTokenPattern.hasMatch(key)) return false;
    if (key.length <= 1) return false;
    if (RegExp(r'^\d+$').hasMatch(key)) return false;
    return true;
  }

  static bool _looksLikeEntity(String term) {
    if (RegExp(r'[A-Z]{2,}').hasMatch(term)) return true;
    if (RegExp(r'^[A-Z][A-Za-z0-9._/+:#-]{2,}$').hasMatch(term)) {
      return true;
    }
    if (RegExp(r'[A-Za-z]+[0-9][A-Za-z0-9._/+:#-]*').hasMatch(term)) {
      return true;
    }
    if (term.contains('_') || term.contains('.') || term.contains('-')) {
      return true;
    }
    return term.length >= 12 && !term.contains(' ');
  }

  static double _recencyWeight(int messageIndex, int messageCount) {
    final distance = max(0, messageCount - 1 - messageIndex);
    return max(1, 12 - distance).toDouble();
  }

  static String _termKey(String term) {
    return term.toLowerCase();
  }

  static String _fitQueryLength(String query, int maxLength) {
    final compact = query.replaceAll(_whitespacePattern, ' ').trim();
    if (compact.length <= maxLength) return compact;
    final words = compact.split(' ');
    final selected = <String>[];
    for (final word in words) {
      final next = <String>[...selected, word].join(' ');
      if (next.length > maxLength) break;
      selected.add(word);
    }
    if (selected.isNotEmpty) return selected.join(' ');
    return compact.substring(0, maxLength).trim();
  }

  static String _trimSentencePunctuation(String text) {
    return text.replaceAll(RegExp(r'[.!?。！？]+$'), '').trim();
  }

  static String _preview(String text) {
    final compact = text.replaceAll(_whitespacePattern, ' ').trim();
    if (compact.length <= 120) return compact;
    return '${compact.substring(0, 120).trim()}...';
  }

  static double _roundScore(double score) {
    return (score * 10).roundToDouble() / 10;
  }
}

class _MutableScoredTerm {
  final String value;
  double score = 0;
  int occurrences = 0;
  bool fromLatestUserMessage = false;
  final List<int> messageIndexes = <int>[];
  final List<String> reasons = <String>[];

  _MutableScoredTerm({required this.value});
}
