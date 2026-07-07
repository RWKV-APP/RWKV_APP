final class WebSearchTrace {
  final String searchProvider;
  final String searchEngineId;
  final String searchEngineLabel;
  final String userQuery;
  final String query;
  final String searchUrl;
  final String pageUrl;
  final String pageTitle;
  final int extractedItemCount;
  final int sourceLimit;
  final List<WebSearchTraceSource> sources;
  final List<WebSearchTraceStep> steps;
  final String promptContext;
  final String finalPrompt;
  final String error;

  const WebSearchTrace({
    required this.searchProvider,
    required this.searchEngineId,
    required this.searchEngineLabel,
    required this.userQuery,
    required this.query,
    required this.searchUrl,
    required this.pageUrl,
    required this.pageTitle,
    required this.extractedItemCount,
    required this.sourceLimit,
    required this.sources,
    required this.steps,
    required this.promptContext,
    required this.finalPrompt,
    required this.error,
  });

  factory WebSearchTrace.fromJson(dynamic json) {
    if (json is! Map) return WebSearchTrace.empty();
    return WebSearchTrace(
      searchProvider: json['searchProvider']?.toString() ?? '',
      searchEngineId: json['searchEngineId']?.toString() ?? '',
      searchEngineLabel: json['searchEngineLabel']?.toString() ?? '',
      userQuery: json['userQuery']?.toString() ?? '',
      query: json['query']?.toString() ?? '',
      searchUrl: json['searchUrl']?.toString() ?? '',
      pageUrl: json['pageUrl']?.toString() ?? '',
      pageTitle: json['pageTitle']?.toString() ?? '',
      extractedItemCount: (json['extractedItemCount'] as num?)?.toInt() ?? 0,
      sourceLimit: (json['sourceLimit'] as num?)?.toInt() ?? 0,
      sources: (json['sources'] as Iterable?)?.map(WebSearchTraceSource.fromJson).toList() ?? const <WebSearchTraceSource>[],
      steps: (json['steps'] as Iterable?)?.map(WebSearchTraceStep.fromJson).toList() ?? const <WebSearchTraceStep>[],
      promptContext: json['promptContext']?.toString() ?? '',
      finalPrompt: json['finalPrompt']?.toString() ?? '',
      error: json['error']?.toString() ?? '',
    );
  }

  factory WebSearchTrace.empty() {
    return const WebSearchTrace(
      searchProvider: '',
      searchEngineId: '',
      searchEngineLabel: '',
      userQuery: '',
      query: '',
      searchUrl: '',
      pageUrl: '',
      pageTitle: '',
      extractedItemCount: 0,
      sourceLimit: 0,
      sources: <WebSearchTraceSource>[],
      steps: <WebSearchTraceStep>[],
      promptContext: '',
      finalPrompt: '',
      error: '',
    );
  }

  bool get hasData {
    return searchProvider.isNotEmpty ||
        searchEngineLabel.isNotEmpty ||
        query.isNotEmpty ||
        pageUrl.isNotEmpty ||
        sources.isNotEmpty ||
        steps.isNotEmpty ||
        promptContext.isNotEmpty ||
        finalPrompt.isNotEmpty ||
        error.isNotEmpty;
  }

  WebSearchTrace copyWith({
    String? searchProvider,
    String? searchEngineId,
    String? searchEngineLabel,
    String? userQuery,
    String? query,
    String? searchUrl,
    String? pageUrl,
    String? pageTitle,
    int? extractedItemCount,
    int? sourceLimit,
    List<WebSearchTraceSource>? sources,
    List<WebSearchTraceStep>? steps,
    String? promptContext,
    String? finalPrompt,
    String? error,
  }) {
    return WebSearchTrace(
      searchProvider: searchProvider ?? this.searchProvider,
      searchEngineId: searchEngineId ?? this.searchEngineId,
      searchEngineLabel: searchEngineLabel ?? this.searchEngineLabel,
      userQuery: userQuery ?? this.userQuery,
      query: query ?? this.query,
      searchUrl: searchUrl ?? this.searchUrl,
      pageUrl: pageUrl ?? this.pageUrl,
      pageTitle: pageTitle ?? this.pageTitle,
      extractedItemCount: extractedItemCount ?? this.extractedItemCount,
      sourceLimit: sourceLimit ?? this.sourceLimit,
      sources: sources ?? this.sources,
      steps: steps ?? this.steps,
      promptContext: promptContext ?? this.promptContext,
      finalPrompt: finalPrompt ?? this.finalPrompt,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'searchProvider': searchProvider,
      'searchEngineId': searchEngineId,
      'searchEngineLabel': searchEngineLabel,
      'userQuery': userQuery,
      'query': query,
      'searchUrl': searchUrl,
      'pageUrl': pageUrl,
      'pageTitle': pageTitle,
      'extractedItemCount': extractedItemCount,
      'sourceLimit': sourceLimit,
      'sources': sources.map((source) => source.toJson()).toList(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'promptContext': promptContext,
      'finalPrompt': finalPrompt,
      'error': error,
    };
  }
}

final class WebSearchTraceSource {
  final int rank;
  final String title;
  final String url;
  final String summary;

  const WebSearchTraceSource({
    required this.rank,
    required this.title,
    required this.url,
    required this.summary,
  });

  factory WebSearchTraceSource.fromJson(dynamic json) {
    if (json is! Map) return WebSearchTraceSource.empty();
    return WebSearchTraceSource(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
    );
  }

  factory WebSearchTraceSource.empty() {
    return const WebSearchTraceSource(rank: 0, title: '', url: '', summary: '');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rank': rank,
      'title': title,
      'url': url,
      'summary': summary,
    };
  }
}

final class WebSearchTraceStep {
  final String title;
  final String detail;

  const WebSearchTraceStep({required this.title, required this.detail});

  factory WebSearchTraceStep.fromJson(dynamic json) {
    if (json is! Map) return WebSearchTraceStep.empty();
    return WebSearchTraceStep(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }

  factory WebSearchTraceStep.empty() {
    return const WebSearchTraceStep(title: '', detail: '');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'detail': detail};
  }
}
