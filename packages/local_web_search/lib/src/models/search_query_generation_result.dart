enum SearchMessageRole { user, assistant, system, unknown }

class SearchConversationMessage {
  final int index;
  final SearchMessageRole role;
  final String rawText;
  final String content;

  const SearchConversationMessage({
    required this.index,
    required this.role,
    required this.rawText,
    required this.content,
  });

  bool get isUser => role == .user || role == .unknown;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'index': index,
      'role': role.name,
      'rawText': rawText,
      'content': content,
    };
  }
}

class SearchQueryTerm {
  final String value;
  final double score;
  final int occurrences;
  final bool fromLatestUserMessage;
  final List<int> messageIndexes;
  final List<String> reasons;

  const SearchQueryTerm({
    required this.value,
    required this.score,
    required this.occurrences,
    required this.fromLatestUserMessage,
    required this.messageIndexes,
    required this.reasons,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      'score': score,
      'occurrences': occurrences,
      'fromLatestUserMessage': fromLatestUserMessage,
      'messageIndexes': messageIndexes,
      'reasons': reasons,
    };
  }
}

class SearchIgnoredMessage {
  final int index;
  final SearchMessageRole role;
  final String reason;
  final String preview;

  const SearchIgnoredMessage({
    required this.index,
    required this.role,
    required this.reason,
    required this.preview,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'index': index,
      'role': role.name,
      'reason': reason,
      'preview': preview,
    };
  }
}

class SearchHistoryIndexEntry {
  final int messageIndex;
  final SearchMessageRole role;
  final List<String> terms;
  final double relevanceScore;
  final String preview;

  const SearchHistoryIndexEntry({
    required this.messageIndex,
    required this.role,
    required this.terms,
    required this.relevanceScore,
    required this.preview,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageIndex': messageIndex,
      'role': role.name,
      'terms': terms,
      'relevanceScore': relevanceScore,
      'preview': preview,
    };
  }
}

class SearchRollingContext {
  final List<String> topicTerms;
  final List<String> activeEntities;
  final List<String> recentUserTerms;
  final List<String> latestUserTerms;

  const SearchRollingContext({
    required this.topicTerms,
    required this.activeEntities,
    required this.recentUserTerms,
    required this.latestUserTerms,
  });

  const SearchRollingContext.empty()
    : topicTerms = const <String>[],
      activeEntities = const <String>[],
      recentUserTerms = const <String>[],
      latestUserTerms = const <String>[];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'topicTerms': topicTerms,
      'activeEntities': activeEntities,
      'recentUserTerms': recentUserTerms,
      'latestUserTerms': latestUserTerms,
    };
  }
}

class SearchQueryGenerationResult {
  final bool shouldSearch;
  final String query;
  final String reason;
  final SearchConversationMessage? latestUserMessage;
  final List<SearchConversationMessage> parsedMessages;
  final List<SearchHistoryIndexEntry> supportingMessages;
  final List<SearchIgnoredMessage> ignoredMessages;
  final List<SearchQueryTerm> candidateTerms;
  final SearchRollingContext rollingContext;
  final bool usedHistory;

  const SearchQueryGenerationResult({
    required this.shouldSearch,
    required this.query,
    required this.reason,
    required this.latestUserMessage,
    required this.parsedMessages,
    required this.supportingMessages,
    required this.ignoredMessages,
    required this.candidateTerms,
    required this.rollingContext,
    required this.usedHistory,
  });

  const SearchQueryGenerationResult.empty()
    : shouldSearch = false,
      query = '',
      reason = 'No messages were provided.',
      latestUserMessage = null,
      parsedMessages = const <SearchConversationMessage>[],
      supportingMessages = const <SearchHistoryIndexEntry>[],
      ignoredMessages = const <SearchIgnoredMessage>[],
      candidateTerms = const <SearchQueryTerm>[],
      rollingContext = const SearchRollingContext.empty(),
      usedHistory = false;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shouldSearch': shouldSearch,
      'query': query,
      'reason': reason,
      'latestUserMessage': latestUserMessage?.toJson(),
      'usedHistory': usedHistory,
      'rollingContext': rollingContext.toJson(),
      'supportingMessages': supportingMessages
          .map((message) => message.toJson())
          .toList(),
      'ignoredMessages': ignoredMessages
          .map((message) => message.toJson())
          .toList(),
      'candidateTerms': candidateTerms.map((term) => term.toJson()).toList(),
      'parsedMessages': parsedMessages
          .map((message) => message.toJson())
          .toList(),
    };
  }
}
