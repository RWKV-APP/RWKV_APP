class SearchReferenceRequest {
  final List<String> messages;
  final int maxSources;

  const SearchReferenceRequest({required this.messages, this.maxSources = 8});

  const SearchReferenceRequest.empty()
    : messages = const <String>[],
      maxSources = 8;

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
    };
  }
}
