part of 'p.dart';

extension $ChatWebSearch on _Chat {
  String searchProviderLabel(WebSearchProvider provider) => switch (provider) {
    .browser => S.current.web_search_browser,
    .deepseek => 'DeepSeek',
    .anysearch => 'AnySearch',
    .tavily => 'Tavily',
    .brave => 'Brave Search',
    .exa => 'Exa',
    .serper => 'Serper',
    .serpapi => 'SerpApi',
    .searchapi => 'SearchApi',
    .firecrawl => 'Firecrawl',
    .zhihuGlobal => S.current.web_search_zhihu_global,
    .zhihuSite => S.current.web_search_zhihu_site,
  };

  void onWebSearchProviderChanged(WebSearchProvider provider) {
    if (P.rwkvGeneration.generating.q) return;
    onWebSearchSettingsClosed();
    webSearchProvider.q = provider;
    if (!_webSearchVerified(provider)) webSearchMode.q = .off;
    localWebSearchPanelEnabled.q = provider == .browser && webSearchMode.q != .off && P.app.isDesktop.q;
  }

  Future<void> onWebSearchKeyChanged(WebSearchProvider provider, String value) async {
    if (P.rwkvGeneration.generating.q) return;
    if (provider.credentialId.isEmpty) return;
    final key = value.trim();
    if (webSearchApiKeys.q[provider.credentialId] == key) return;
    webSearchApiKeys.q = {...webSearchApiKeys.q, provider.credentialId: key};
    webSearchChecks.q = {
      for (final entry in webSearchChecks.q.entries)
        if (entry.key.credentialId != provider.credentialId) entry.key: entry.value,
    };
    if ((provider.requiresApiKey || key.isNotEmpty) && provider.credentialId == webSearchProvider.q.credentialId) {
      webSearchMode.q = .off;
    }
  }

  String searchProviderDescription(WebSearchProvider provider) => switch (provider) {
    .zhihuGlobal => S.current.web_search_zhihu_web_description,
    .zhihuSite => S.current.web_search_zhihu_site_description,
    _ => '',
  };

  String searchProviderAllowance(WebSearchProvider provider) => switch (provider) {
    .tavily => S.current.web_search_tavily_allowance,
    .brave => S.current.web_search_brave_allowance,
    .exa => S.current.web_search_exa_allowance,
    .serper => S.current.web_search_serper_allowance,
    .serpapi => S.current.web_search_serpapi_allowance,
    .searchapi => S.current.web_search_searchapi_allowance,
    .firecrawl => S.current.web_search_firecrawl_allowance,
    _ => '',
  };

  void onWebSearchSettingsTapped({WebSearchProvider? provider, BuildContext? context}) {
    if (P.rwkvGeneration.generating.q) return;
    WebSearchSettingsPanel.show(provider: provider, context: context);
  }

  Future<void> onWebSearchProviderEnabledChanged(WebSearchProvider provider, bool enabled) async {
    if (P.rwkvGeneration.generating.q) return;
    if (webSearchChecks.q.values.any((value) => value.isLoading)) return;
    if (enabled && !_webSearchVerified(provider)) {
      await onVerifyAndEnableWebSearchProvider(provider);
      return;
    }
    onWebSearchProviderChanged(provider);
    onSwitchWebSearchMode(enabled ? .search : .off);
  }

  bool _webSearchVerified(WebSearchProvider provider) {
    final key = webSearchApiKeys.q[provider.credentialId] ?? '';
    if (!provider.requiresApiKey && key.isEmpty) return true;
    if (key.isEmpty) return false;
    return webSearchChecks.q[provider]?.asData?.value == crypto.sha256.convert(utf8.encode(key)).toString();
  }

  void onWebSearchSettingsClosed() {
    if (!webSearchChecks.q.values.any((value) => value.isLoading)) return;
    webSearchChecks.q = {
      for (final entry in webSearchChecks.q.entries)
        if (!entry.value.isLoading) entry.key: entry.value,
    };
  }

  String webSearchValidationText(AsyncValue<String> check) {
    if (check.isLoading) return S.current.web_search_validating;
    if (check.hasError) return _webSearchFailureMessage(check.error is WebSearchFailure ? check.error as WebSearchFailure : .unavailable);
    return S.current.web_search_validation_success;
  }

  Future<void> onVerifyAndEnableWebSearchProvider(WebSearchProvider provider, {http.Client? client}) async {
    if (P.rwkvGeneration.generating.q || provider == .browser) return;
    if (webSearchChecks.q.values.any((value) => value.isLoading)) return;
    final key = webSearchApiKeys.q[provider.credentialId] ?? '';
    if (provider.requiresApiKey && key.isEmpty) {
      webSearchChecks.q = {...webSearchChecks.q, provider: AsyncError<String>(WebSearchFailure.missingKey, StackTrace.empty)};
      return;
    }
    final checking = AsyncLoading<String>();
    final generationId = receiveId.q;
    webSearchChecks.q = {...webSearchChecks.q, provider: checking};
    WebSearchFailure? failure;
    try {
      await searchWebApi(provider: provider, apiKey: key, query: 'RWKV', client: client);
    } catch (error) {
      failure = error is WebSearchFailure ? error : .unavailable;
    }
    if (!identical(webSearchChecks.q[provider], checking)) return;
    if ((webSearchApiKeys.q[provider.credentialId] ?? '') != key || P.rwkvGeneration.generating.q || receiveId.q != generationId) {
      onWebSearchSettingsClosed();
      return;
    }
    if (failure != null) {
      await onWebSearchProviderFailure(provider, failure);
      if (webSearchProvider.q == provider) webSearchMode.q = .off;
      return;
    }
    webSearchChecks.q = {...webSearchChecks.q, provider: AsyncData<String>(crypto.sha256.convert(utf8.encode(key)).toString())};
    onWebSearchProviderChanged(provider);
    onSwitchWebSearchMode(.search);
  }

  void _invalidateWebSearchCredential(WebSearchProvider provider) {
    webSearchChecks.q = {
      for (final entry in webSearchChecks.q.entries)
        if (entry.key.credentialId != provider.credentialId) entry.key: entry.value,
      for (final value in WebSearchProvider.values)
        if (value.credentialId == provider.credentialId) value: AsyncError<String>(WebSearchFailure.unauthorized, StackTrace.empty),
    };
  }

  Future<void> onWebSearchProviderFailure(WebSearchProvider provider, WebSearchFailure failure, {bool notify = false}) async {
    webSearchChecks.q = {...webSearchChecks.q, provider: AsyncError<String>(failure, StackTrace.empty)};
    if (failure == .unauthorized) _invalidateWebSearchCredential(provider);
    if (webSearchProvider.q == provider && (failure == .unauthorized || failure == .balance || failure == .quota)) {
      webSearchMode.q = .off;
      localWebSearchPanelEnabled.q = false;
    }
    if (!notify) return;
    Alert.warning('${searchProviderLabel(provider)}: ${_webSearchFailureMessage(failure)}');
  }

  Future<void> onWebSearchProviderLinkTapped(WebSearchProvider provider, {bool manageKey = false, bool pricing = false}) async {
    final uri = pricing
        ? provider.pricingUrl!
        : manageKey
        ? provider.keyManagementUrl
        : provider.documentationUrl;
    try {
      if (await launchUrl(uri, mode: .externalApplication)) return;
    } catch (_) {
      // Only show a local message; platform errors are not useful setup guidance.
    }
    Alert.error(S.current.web_search_link_failed);
  }

  void onSwitchWebSearchMode(WebSearchMode mode, {BuildContext? context}) async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if ((Platform.isAndroid || Platform.isIOS) && webSearchProvider.q == .browser) {
      webSearchMode.q = WebSearchMode.off;
      localWebSearchPanelEnabled.q = false;
      return;
    }
    final provider = webSearchProvider.q;
    if (mode != .off && !_webSearchVerified(provider)) {
      webSearchMode.q = .off;
      localWebSearchPanelEnabled.q = false;
      onWebSearchSettingsTapped(provider: provider, context: context);
      return;
    }
    webSearchMode.q = mode;
    if (mode == WebSearchMode.off) {
      onWebSearchSettingsClosed();
      localWebSearchPanelEnabled.q = false;
      return;
    }
    if (P.app.isDesktop.q && provider == .browser) {
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
    webSearchProvider.q = .browser;

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

  Future<void> onWebSearchModeTapped(BuildContext context) async {
    if (P.rwkvGeneration.generating.q) return;
    P.app.hapticLight();
    final selected = webSearchMode.q == .off ? 'off' : webSearchProvider.q.name;
    final result = await WebSearchProviderSheet.show(context, selected: selected);
    if (result == null || !context.mounted || P.rwkvGeneration.generating.q) return;
    if (result == 'settings') {
      onWebSearchSettingsTapped(context: context);
      return;
    }
    if (result == 'off') {
      onSwitchWebSearchMode(.off);
      return;
    }
    final provider = WebSearchProvider.values.byName(result);
    onWebSearchProviderChanged(provider);
    onSwitchWebSearchMode(.search, context: context);
  }

  Future<List<String>> _historyWithWebSearch(int receiveId, List<String> allMessage) async {
    if (webSearchMode.q == WebSearchMode.off) return allMessage;
    if ((Platform.isAndroid || Platform.isIOS) && webSearchProvider.q == .browser) return allMessage;

    final searchingRef = RefInfo.empty().copyWith(enable: true);
    _updateMessageById(id: receiveId, reference: searchingRef);
    final result = await _historyWithWebSearchResult(allMessage);
    _updateMessageById(id: receiveId, reference: result.ref);
    return result.history;
  }

  Future<List<List<String>>> _batchHistoriesWithWebSearch(
    int receiveId,
    List<List<String>> batchMessages,
  ) async {
    if (webSearchMode.q == WebSearchMode.off) return batchMessages;
    if ((Platform.isAndroid || Platform.isIOS) && webSearchProvider.q == .browser) return batchMessages;

    final searchingRef = RefInfo.empty().copyWith(enable: true);
    _updateMessageById(id: receiveId, reference: searchingRef);

    final histories = <List<String>>[];
    final refs = <RefInfo>[];
    for (final batchMessage in batchMessages) {
      if (!P.rwkvGeneration.generating.q || this.receiveId.q != receiveId || _pauseFinalizingMessageId == receiveId) break;
      final result = await _historyWithWebSearchResult(batchMessage);
      histories.add(result.history);
      refs.add(result.ref);
      final combined = _combineWebSearchRefs(refs);
      _updateMessageById(id: receiveId, reference: combined);
    }

    final combined = _combineWebSearchRefs(refs);
    _updateMessageById(id: receiveId, reference: combined);
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
      final localWebSearch = webSearchProvider.q == .browser
          ? await _runLocalWebSearchForPrompt(allMessage: history, query: promptParts.query)
          : await _runApiWebSearchForPrompt(query: promptParts.query);
      if (localWebSearch != null) {
        ref = localWebSearch.ref;
        if (localWebSearch.promptContext.isNotEmpty) {
          history.removeLast();
          final template = P.preference.promptTemplate;
          final msg =
              buildWebSearchPrompt(
                template: isZh ? template.webSearchChineseTemplate : template.webSearchTemplate,
                context: localWebSearch.promptContext,
                question: promptParts.query,
                chinese: isZh,
              ) +
              promptParts.footer;
          history.add(msg);
          ref = _refWithWebSearchFinalPrompt(ref: ref, finalPrompt: msg);
        } else {
          ref = _refWithWebSearchFinalPrompt(ref: ref, finalPrompt: history.last);
        }
        return (history: history, ref: ref);
      }

      throw WebSearchFailure.unavailable;
    } catch (e) {
      final error = e is WebSearchFailure ? _webSearchFailureMessage(e) : e.toString();
      ref = ref.copyWith(error: error);
      if (webSearchProvider.q == .browser) qqe(e);
    }

    return (history: history, ref: ref);
  }

  String _webSearchFailureMessage(WebSearchFailure failure) => switch (failure) {
    .missingKey => S.current.web_search_missing_key,
    .invalidQuery => S.current.web_search_invalid_query,
    .unauthorized => S.current.web_search_unauthorized,
    .balance => S.current.web_search_balance,
    .quota => S.current.web_search_quota,
    .rateLimit => S.current.web_search_rate_limit,
    .timeout => S.current.web_search_timeout,
    .invalidResponse => S.current.web_search_invalid_response,
    .unavailable => S.current.web_search_unavailable,
  };

  Future<({RefInfo ref, String promptContext})> _runApiWebSearchForPrompt({required String query}) async {
    final provider = webSearchProvider.q;
    final searchQuery = buildWebSearchApiQuery(query, maxLength: provider == .deepseek ? 128 : 100);
    String request = '';
    final responses = <WebSearchTraceResponse>[];
    String error = '';
    List<Reference> refs = const [];
    localWebSearchRunning.q = true;
    try {
      refs = await searchWebApi(
        provider: provider,
        apiKey: webSearchApiKeys.q[provider.credentialId] ?? '',
        query: searchQuery,
        onRequest: (value) => request = value,
        onResponse: (statusCode, body) => responses.add(WebSearchTraceResponse(query: searchQuery, statusCode: statusCode, body: body)),
      );
    } on WebSearchFailure catch (failure) {
      error = _webSearchFailureMessage(failure);
      await onWebSearchProviderFailure(provider, failure, notify: true);
    } finally {
      localWebSearchRunning.q = false;
    }
    final isZh = P.preference.currentLangIsZh.q;
    final context = webSearchApiContext(refs, chinese: isZh);
    if (refs.isEmpty && error.isEmpty) error = S.current.web_search_no_results;
    final trace =
        _remoteWebSearchTrace(
          endpoint: provider.endpoint.toString(),
          query: searchQuery,
          userQuery: query,
          requestDetail: request,
          refs: refs,
          searchResult: context,
          finalPrompt: '',
        ).copyWith(
          searchProvider: searchProviderLabel(provider),
          searchEngineId: provider.name,
          searchEngineLabel: searchProviderLabel(provider),
          userQuery: query,
          error: error,
          request: request,
          responses: responses,
        );
    final safeTrace = WebSearchTrace.fromJson(redactWebSearchPayload(trace.toJson(), webSearchApiKeys.q.values));
    return (ref: RefInfo(list: refs, enable: true, error: error, trace: safeTrace), promptContext: context);
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

  String _promptContextFromLocalWebSearchBundle({required SearchReferenceBundle bundle, required bool deepResultsEnabled}) {
    if (deepResultsEnabled) {
      final deepContext = [
        for (final result in bundle.deepResults)
          if (result.hasContent) '${result.title}\n${result.markdown.trim()}',
      ].join('\n\n');
      if (deepContext.isNotEmpty) return deepContext;
    }
    return [
      for (final source in bundle.sources) [source.title, if (source.summary.isNotEmpty) source.summary].join('\n'),
    ].join('\n\n');
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
        detail: 'Search context was injected into the user message before response-style processing.',
      ),
    ];
    return ref.copyWith(
      trace: trace.copyWith(finalPrompt: redactWebSearchReport(finalPrompt, webSearchApiKeys.q.values), steps: nextSteps),
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
    String? userQuery,
    String requestDetail = 'top_n=3',
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
          publishedAt: ref.publishedAt,
        ),
      );
    }
    return WebSearchTrace(
      searchProvider: 'Remote Web Search API',
      searchEngineId: 'remote_search',
      searchEngineLabel: 'Remote Search',
      userQuery: userQuery ?? query,
      query: query,
      searchUrl: endpoint,
      pageUrl: endpoint,
      pageTitle: '',
      extractedItemCount: refs.length,
      sourceLimit: 3,
      sources: sources,
      steps: <WebSearchTraceStep>[
        WebSearchTraceStep(title: 'Input captured', detail: userQuery ?? query),
        if (userQuery != null && userQuery != query) WebSearchTraceStep(title: 'Query generated', detail: query),
        WebSearchTraceStep(
          title: 'Remote search requested',
          detail: requestDetail,
        ),
        WebSearchTraceStep(
          title: 'Reference summaries received',
          detail: searchResult,
        ),
        if (finalPrompt.isNotEmpty)
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
    if (traces.length == 1) return traces.first.copyWith(sourceGroups: [traces.first.sources]);

    final sources = <WebSearchTraceSource>[];
    for (int i = 0; i < references.length; i += 1) {
      final ref = references[i];
      sources.add(
        WebSearchTraceSource(
          rank: i + 1,
          title: ref.title,
          url: ref.url,
          summary: ref.summary,
          publishedAt: ref.publishedAt,
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
      request: traces.map((trace) => trace.request).where((text) => text.isNotEmpty).join('\n\n'),
      responses: [for (final trace in traces) ...trace.responses],
      sourceGroups: [for (final trace in traces) trace.sources],
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

  void onWebSearchModelRequest(to_rwkv.ToRWKV request) {
    final id = receiveId.q;
    final message = P.msg.pool.q[id];
    final trace = message?.reference.trace;
    if (id == null || message == null || trace == null || !message.changing || P.app.demoType.q != .chat) return;
    final input = webSearchModelRequest(request);
    if (input == null) return;
    final captured = appendWebSearchModelRequest(
      trace: trace,
      request: input,
      redactions: webSearchApiKeys.q.values,
    );
    _updateMessageById(
      id: id,
      reference: message.reference.copyWith(trace: captured),
    );
  }

  Future<void> onCopyWebSearchReport(int messageId, {int? section}) async {
    final message = P.msg.pool.q[messageId];
    if (message == null) return;
    final trace = webSearchTraceForReport(message.reference);
    if (!trace.hasData) return;
    final text = formatWebSearchReport(
      trace: trace,
      strings: S.current,
      modelOutput: message.content,
      generating: message.changing,
      paused: message.paused,
      redactions: webSearchApiKeys.q.values,
      section: section,
    );
    await Clipboard.setData(ClipboardData(text: text));
    Alert.success(S.current.chat_copied_to_clipboard);
  }
}
