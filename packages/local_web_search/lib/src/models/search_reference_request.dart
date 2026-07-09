class SearchReferenceRequest {
  final List<String> messages;
  final int maxSources;
  final bool enableDeepResults;
  final int maxDeepResults;
  final int maxDeepCharactersPerResult;

  const SearchReferenceRequest({
    required this.messages,
    this.maxSources = 8,
    this.enableDeepResults = false,
    this.maxDeepResults = 3,
    this.maxDeepCharactersPerResult = 2200,
  });

  const SearchReferenceRequest.empty()
    : messages = const <String>[],
      maxSources = 8,
      enableDeepResults = false,
      maxDeepResults = 3,
      maxDeepCharactersPerResult = 2200;

  List<String> get normalizedMessages {
    final normalized = <String>[];
    for (final message in messages) {
      final trimmed = message.trim();
      if (trimmed.isEmpty) continue;
      normalized.add(trimmed);
    }
    return normalized;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messages': normalizedMessages,
      'maxSources': maxSources,
      'enableDeepResults': enableDeepResults,
      'maxDeepResults': maxDeepResults,
      'maxDeepCharactersPerResult': maxDeepCharactersPerResult,
    };
  }
}
