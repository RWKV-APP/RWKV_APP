part of 'p.dart';

extension $ChatWebSearch on _Chat {
  void onSwitchWebSearchMode(WebSearchMode mode) async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      webSearchMode.q = WebSearchMode.off;
      localWebSearchPanelEnabled.q = false;
      return;
    }
    webSearchMode.q = mode;
    if (mode == WebSearchMode.off) {
      localWebSearchPanelEnabled.q = false;
      return;
    }
    if (P.app.isDesktop.q) {
      localWebSearchPanelEnabled.q = true;
    }
  }

  void onToggleLocalWebSearchPanel() {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (!P.app.isDesktop.q) return;

    final enabled = !localWebSearchPanelEnabled.q;
    localWebSearchPanelEnabled.q = enabled;
    if (enabled && webSearchMode.q == WebSearchMode.off) {
      webSearchMode.q = WebSearchMode.search;
    }
  }

  void onLocalWebSearchEngineChanged(SearchEngine engine) {
    localWebSearchEngine.q = engine;
  }

  void onLocalWebSearchDeepResultsEnabledChanged(bool enabled) {
    localWebSearchDeepResultsEnabled.q = enabled;
  }

  void onLocalWebSearchBundleChanged(SearchReferenceBundle bundle) {
    localWebSearchBundle.q = bundle;
  }

  void onWebSearchModeTapped() {
    if (Platform.isAndroid || Platform.isIOS) return;

    final loading = P.rwkvModel.loading.q;
    if (loading) return;

    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    P.app.hapticLight();
    final nextMode = webSearchMode.q == WebSearchMode.off ? WebSearchMode.search : WebSearchMode.off;
    onSwitchWebSearchMode(nextMode);
  }

  Future<List<String>> _historyWithWebSearch(int receiveId, List<String> allMessage) async {
    if (webSearchMode.q == WebSearchMode.off) return allMessage;
    if (Platform.isAndroid || Platform.isIOS) return allMessage;

    final searchingRef = RefInfo.empty().copyWith(enable: true);
    _updateMessageById(id: receiveId, reference: searchingRef);
    final result = await _historyWithWebSearchResult(allMessage);
    unawaited(_updateWebSearchReferenceAfterDelay(receiveId: receiveId, ref: result.ref));
    return result.history;
  }

  Future<List<List<String>>> _batchHistoriesWithWebSearch(
    int receiveId,
    List<List<String>> batchMessages,
  ) async {
    if (webSearchMode.q == WebSearchMode.off) return batchMessages;
    if (Platform.isAndroid || Platform.isIOS) return batchMessages;

    final searchingRef = RefInfo.empty().copyWith(enable: true);
    _updateMessageById(id: receiveId, reference: searchingRef);

    final histories = <List<String>>[];
    final refs = <RefInfo>[];
    for (final batchMessage in batchMessages) {
      final result = await _historyWithWebSearchResult(batchMessage);
      histories.add(result.history);
      refs.add(result.ref);
      final combined = _combineWebSearchRefs(refs);
      _updateMessageById(id: receiveId, reference: combined);
    }

    final combined = _combineWebSearchRefs(refs);
    unawaited(_updateWebSearchReferenceAfterDelay(receiveId: receiveId, ref: combined));
    return histories;
  }

  Future<({List<String> history, RefInfo ref})> _historyWithWebSearchResult(List<String> allMessage) async {
    final history = <String>[...allMessage];
    RefInfo ref = RefInfo.empty().copyWith(enable: true);
    final isZh = P.preference.currentLangIsZh.q;

    try {
      if (history.isEmpty) {
        return (history: history, ref: ref.copyWith(error: "No user message was found."));
      }
      final prompt = history.last;
      final promptParts = splitWebSearchPrompt(
        prompt: prompt,
        userMsgFooter: P.rwkvParams.thinkingMode.q.userMsgFooter,
      );
      final localWebSearch = await _runLocalWebSearchForPrompt(
        allMessage: history,
        query: promptParts.query,
      );
      if (localWebSearch != null) {
        ref = localWebSearch.ref;
        if (localWebSearch.promptContext.isNotEmpty) {
          history.removeLast();
          final template = P.preference.promptTemplate;
          final msg =
              sprintf(isZh ? template.webSearchChineseTemplate : template.webSearchTemplate, [
                localWebSearch.promptContext,
                promptParts.query,
              ]) +
              promptParts.footer;
          history.add(msg);
          ref = _refWithWebSearchFinalPrompt(ref: ref, finalPrompt: msg);
        } else {
          ref = _refWithWebSearchFinalPrompt(ref: ref, finalPrompt: history.last);
        }
        return (history: history, ref: ref);
      }

      final resp =
          await _post(
                'https://auth.rwkvos.com/api/internet_search',
                token: 'x8rYbL3KfGp2Nq1zT9wVvJ0iQ5sUoAeX7HcM4',
                body: {
                  "query": promptParts.query,
                  "top_n": 3,
                },
              ).timeout(const Duration(seconds: 10))
              as dynamic;
      qqq('web search mode: ${webSearchMode.q}');
      final refs = (resp['data'] as Iterable).map((e) => Reference.fromJson(e)).toList();
      ref = ref.copyWith(list: refs);
      final searchResult = refs.map((e) => e.summary).join("\n");
      history.removeLast();
      final template = P.preference.promptTemplate;
      final msg =
          sprintf(isZh ? template.webSearchChineseTemplate : template.webSearchTemplate, [searchResult, promptParts.query]) +
          promptParts.footer;
      history.add(msg);
      ref = RefInfo(
        list: refs,
        enable: true,
        error: "",
        trace: _remoteWebSearchTrace(
          endpoint: 'https://auth.rwkvos.com/api/internet_search',
          query: promptParts.query,
          refs: refs,
          searchResult: searchResult,
          finalPrompt: msg,
        ),
      );
    } catch (e) {
      ref = ref.copyWith(error: e.toString());
      qqe(e);
    }

    return (history: history, ref: ref);
  }

  RefInfo _combineWebSearchRefs(List<RefInfo> refs) {
    if (refs.isEmpty) return RefInfo.empty();

    final references = <Reference>[];
    final seenKeys = <String>{};
    final errors = <String>[];
    final traces = <WebSearchTrace>[];
    bool enable = false;

    for (final ref in refs) {
      enable = enable || ref.enable;
      if (ref.error.isNotEmpty) {
        errors.add(ref.error);
      }
      final trace = ref.trace;
      if (trace != null && trace.hasData) {
        traces.add(trace);
      }
      for (final item in ref.list) {
        final key = item.url.isNotEmpty ? item.url : "${item.title}\n${item.summary}";
        if (seenKeys.contains(key)) continue;
        seenKeys.add(key);
        references.add(item);
      }
    }

    return RefInfo(
      list: references,
      enable: enable,
      error: references.isEmpty ? errors.join("\n") : "",
      trace: _combineWebSearchTraces(
        traces: traces,
        references: references,
        error: references.isEmpty ? errors.join("\n") : "",
      ),
    );
  }

  Future<({RefInfo ref, String promptContext})?> _runLocalWebSearchForPrompt({
    required List<String> allMessage,
    required String query,
  }) async {
    if (!P.app.isDesktop.q) return null;
    if (!localWebSearchPanelEnabled.q) return null;

    localWebSearchRunning.q = true;
    try {
      final messages = _localWebSearchMessagesForPrompt(query: query);
      localWebSearchMessages.q = messages;
      const maxSources = 5;
      final deepResultsEnabled = localWebSearchDeepResultsEnabled.q;
      final bundle = await SearchReferenceService.searchWithBrowser(
        controller: localWebSearchController,
        messages: messages,
        searchEngine: localWebSearchEngine.q,
        maxSources: maxSources,
        enableDeepResults: deepResultsEnabled,
      );
      qqq(
        'local web search: engine=${bundle.searchEngine.id}, query=${bundle.query}, sources=${bundle.sources.length}, error=${bundle.error ?? ""}',
      );
      if (bundle.sources.isNotEmpty) {
        qqq(
          'local web search sources: ${bundle.sources.map((source) => source.url).join(" | ")}',
        );
      }
      localWebSearchBundle.q = bundle;
      final promptContext = _promptContextFromLocalWebSearchBundle(
        bundle: bundle,
        deepResultsEnabled: deepResultsEnabled,
      );
      final ref = RefInfo(
        list: _referencesFromLocalWebSearchBundle(bundle),
        enable: true,
        error: bundle.error ?? "",
        trace: _localWebSearchTrace(
          bundle: bundle,
          userQuery: query,
          sourceLimit: maxSources,
          promptContext: promptContext,
        ),
      );
      return (ref: ref, promptContext: promptContext);
    } catch (e) {
      qqe(e);
      return (
        ref: RefInfo.empty().copyWith(
          enable: true,
          error: e.toString(),
          trace: _failedLocalWebSearchTrace(query: query, error: e.toString()),
        ),
        promptContext: "",
      );
    } finally {
      localWebSearchRunning.q = false;
    }
  }

  List<String> _localWebSearchMessagesForPrompt({required String query}) {
    return <String>["User: $query"];
  }

  String _promptContextFromLocalWebSearchBundle({
    required SearchReferenceBundle bundle,
    required bool deepResultsEnabled,
  }) {
    if (deepResultsEnabled && bundle.deepPromptContext.isNotEmpty) {
      return bundle.deepPromptContext;
    }
    return bundle.promptContext;
  }

  List<Reference> _referencesFromLocalWebSearchBundle(SearchReferenceBundle bundle) {
    final references = <Reference>[];
    for (final source in bundle.sources) {
      references.add(
        Reference(
          url: source.url,
          title: source.title,
          summary: source.toPromptBlock(),
        ),
      );
    }
    return references;
  }

  RefInfo _refWithWebSearchFinalPrompt({
    required RefInfo ref,
    required String finalPrompt,
  }) {
    final trace = ref.trace;
    if (trace == null) return ref;
    final nextSteps = <WebSearchTraceStep>[
      ...trace.steps,
      const WebSearchTraceStep(
        title: 'Prompt constructed',
        detail: 'The prompt below was passed to the inference engine.',
      ),
    ];
    return ref.copyWith(
      trace: trace.copyWith(finalPrompt: finalPrompt, steps: nextSteps),
    );
  }

  WebSearchTrace _localWebSearchTrace({
    required SearchReferenceBundle bundle,
    required String userQuery,
    required int sourceLimit,
    required String promptContext,
  }) {
    final searchUrl = bundle.searchEngine.buildSearchUrl(bundle.query);
    final extractedItemCount = _itemsLengthFromRawJson(bundle.rawJson);
    final sources = <WebSearchTraceSource>[];
    for (final source in bundle.sources) {
      sources.add(
        WebSearchTraceSource(
          rank: source.rank,
          title: source.title,
          url: source.url,
          summary: source.summary,
        ),
      );
    }
    final steps = <WebSearchTraceStep>[
      WebSearchTraceStep(
        title: 'Input captured',
        detail: userQuery,
      ),
      WebSearchTraceStep(
        title: 'Query generated',
        detail: bundle.query.isEmpty ? userQuery : bundle.query,
      ),
      WebSearchTraceStep(
        title: 'Search engine selected',
        detail: bundle.searchEngine.label,
      ),
      WebSearchTraceStep(
        title: 'Search page loaded',
        detail: searchUrl,
      ),
      WebSearchTraceStep(
        title: 'Result page parsed',
        detail: '${bundle.sources.length} source(s) kept from $extractedItemCount parsed result(s).',
      ),
      if (bundle.request.enableDeepResults)
        WebSearchTraceStep(
          title: 'Deep result pages parsed',
          detail:
              '${bundle.deepResults.where((result) => result.hasContent).length} readable page(s) from ${bundle.deepResults.length} attempted page(s).',
        ),
      if (bundle.error != null && bundle.error!.isNotEmpty)
        WebSearchTraceStep(
          title: 'Search reported an issue',
          detail: bundle.error!,
        ),
    ];
    return WebSearchTrace(
      searchProvider: 'Local Web Search',
      searchEngineId: bundle.searchEngine.id,
      searchEngineLabel: bundle.searchEngine.label,
      userQuery: userQuery,
      query: bundle.query,
      searchUrl: searchUrl,
      pageUrl: _pageUrlFromRawJson(bundle.rawJson),
      pageTitle: _pageTitleFromRawJson(bundle.rawJson),
      extractedItemCount: extractedItemCount,
      sourceLimit: sourceLimit,
      sources: sources,
      steps: steps,
      promptContext: promptContext,
      finalPrompt: '',
      error: bundle.error ?? '',
    );
  }

  WebSearchTrace _failedLocalWebSearchTrace({
    required String query,
    required String error,
  }) {
    return WebSearchTrace(
      searchProvider: 'Local Web Search',
      searchEngineId: localWebSearchEngine.q.id,
      searchEngineLabel: localWebSearchEngine.q.label,
      userQuery: query,
      query: query,
      searchUrl: localWebSearchEngine.q.buildSearchUrl(query),
      pageUrl: '',
      pageTitle: '',
      extractedItemCount: 0,
      sourceLimit: 5,
      sources: const <WebSearchTraceSource>[],
      steps: <WebSearchTraceStep>[
        WebSearchTraceStep(title: 'Input captured', detail: query),
        WebSearchTraceStep(title: 'Search failed', detail: error),
      ],
      promptContext: '',
      finalPrompt: '',
      error: error,
    );
  }

  WebSearchTrace _remoteWebSearchTrace({
    required String endpoint,
    required String query,
    required List<Reference> refs,
    required String searchResult,
    required String finalPrompt,
  }) {
    final sources = <WebSearchTraceSource>[];
    for (int i = 0; i < refs.length; i += 1) {
      final ref = refs[i];
      sources.add(
        WebSearchTraceSource(
          rank: i + 1,
          title: ref.title,
          url: ref.url,
          summary: ref.summary,
        ),
      );
    }
    return WebSearchTrace(
      searchProvider: 'Remote Web Search API',
      searchEngineId: 'remote_search',
      searchEngineLabel: 'Remote Search',
      userQuery: query,
      query: query,
      searchUrl: endpoint,
      pageUrl: endpoint,
      pageTitle: '',
      extractedItemCount: refs.length,
      sourceLimit: 3,
      sources: sources,
      steps: <WebSearchTraceStep>[
        WebSearchTraceStep(title: 'Input captured', detail: query),
        const WebSearchTraceStep(
          title: 'Remote search requested',
          detail: 'top_n=3',
        ),
        WebSearchTraceStep(
          title: 'Reference summaries received',
          detail: searchResult,
        ),
        const WebSearchTraceStep(
          title: 'Prompt constructed',
          detail: 'The prompt below was passed to the inference engine.',
        ),
      ],
      promptContext: searchResult,
      finalPrompt: finalPrompt,
      error: '',
    );
  }

  WebSearchTrace? _combineWebSearchTraces({
    required List<WebSearchTrace> traces,
    required List<Reference> references,
    required String error,
  }) {
    if (traces.isEmpty) return null;
    if (traces.length == 1) return traces.first;

    final sources = <WebSearchTraceSource>[];
    for (int i = 0; i < references.length; i += 1) {
      final ref = references[i];
      sources.add(
        WebSearchTraceSource(
          rank: i + 1,
          title: ref.title,
          url: ref.url,
          summary: ref.summary,
        ),
      );
    }
    final steps = <WebSearchTraceStep>[
      WebSearchTraceStep(
        title: 'Batch Web Search completed',
        detail: '${traces.length} search request(s) were combined.',
      ),
    ];
    for (int i = 0; i < traces.length; i += 1) {
      final trace = traces[i];
      steps.add(
        WebSearchTraceStep(
          title: 'Batch item ${i + 1}',
          detail: '${trace.searchEngineLabel}: ${trace.query}\n${trace.sources.length} source(s)',
        ),
      );
    }
    return WebSearchTrace(
      searchProvider: 'Batch Web Search',
      searchEngineId: traces.first.searchEngineId,
      searchEngineLabel: traces.map((trace) => trace.searchEngineLabel).toSet().join(', '),
      userQuery: traces.map((trace) => trace.userQuery).join('\n\n'),
      query: traces.map((trace) => trace.query).join('\n\n'),
      searchUrl: traces.map((trace) => trace.searchUrl).toSet().join('\n'),
      pageUrl: traces.map((trace) => trace.pageUrl).where((url) => url.isNotEmpty).toSet().join('\n'),
      pageTitle: '',
      extractedItemCount: traces.fold<int>(0, (sum, trace) => sum + trace.extractedItemCount),
      sourceLimit: traces.fold<int>(0, (sum, trace) => sum + trace.sourceLimit),
      sources: sources,
      steps: steps,
      promptContext: traces.map((trace) => trace.promptContext).where((text) => text.isNotEmpty).join('\n\n'),
      finalPrompt: traces.map((trace) => trace.finalPrompt).where((text) => text.isNotEmpty).join('\n\n'),
      error: error,
    );
  }

  String _pageUrlFromRawJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return '';
      return decoded['href']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _pageTitleFromRawJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return '';
      return decoded['title']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  int _itemsLengthFromRawJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return 0;
      final items = decoded['items'];
      if (items is! Iterable) return 0;
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _updateWebSearchReferenceAfterDelay({
    required int receiveId,
    required RefInfo ref,
  }) async {
    await 50.msLater;
    _updateMessageById(id: receiveId, reference: ref);
  }
}
