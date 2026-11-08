enum WebSearchProvider {
  browser,
  deepseek,
  zhihuGlobal,
  zhihuSite,
  anysearch,
  tavily,
  brave,
  exa,
  serper,
  serpapi,
  searchapi,
  firecrawl;

  bool get requiresApiKey => credentialId.isNotEmpty && this != firecrawl;

  Uri get keyManagementUrl => switch (this) {
    deepseek => Uri.https('platform.deepseek.com', '/api_keys'),
    zhihuGlobal || zhihuSite => Uri.https('developer.zhihu.com', '/profile'),
    tavily => Uri.https('app.tavily.com', '/home'),
    brave => Uri.https('api-dashboard.search.brave.com', '/app/keys'),
    exa => Uri.https('dashboard.exa.ai', '/api-keys'),
    serper => Uri.https('serper.dev', '/'),
    serpapi => Uri.https('serpapi.com', '/manage-api-key'),
    searchapi => Uri.https('www.searchapi.io', '/'),
    firecrawl => Uri.https('www.firecrawl.dev', '/app/api-keys'),
    browser || anysearch => throw StateError('This search mode does not require a key'),
  };

  Uri get documentationUrl => switch (this) {
    deepseek => Uri.https('api-docs.deepseek.com', '/'),
    zhihuGlobal || zhihuSite => Uri.https('developer.zhihu.com', '/docs', {'key': 'authorization'}),
    anysearch => Uri.https('www.anysearch.com', '/docs/auth'),
    tavily => Uri.https('docs.tavily.com', '/documentation/api-reference/endpoint/search'),
    brave => Uri.https('api-dashboard.search.brave.com', '/documentation/web-search/get-started'),
    exa => Uri.https('exa.ai', '/docs/reference/search'),
    serper => Uri.https('serper.dev', '/playground'),
    serpapi => Uri.https('serpapi.com', '/search-api'),
    searchapi => Uri.https('www.searchapi.io', '/docs/google'),
    firecrawl => Uri.https('docs.firecrawl.dev', '/features/search'),
    browser => throw StateError('Browser search has no API documentation'),
  };

  String get credentialId => switch (this) {
    browser || anysearch => '',
    deepseek => 'deepseek',
    zhihuGlobal || zhihuSite => 'zhihu',
    tavily || brave || exa || serper || serpapi || searchapi || firecrawl => name,
  };

  Uri? get pricingUrl => switch (this) {
    tavily => Uri.https('docs.tavily.com', '/documentation/api-credits'),
    brave => Uri.https('api-dashboard.search.brave.com', '/documentation/pricing'),
    exa => Uri.https('exa.ai', '/pricing'),
    serper => Uri.https('serper.dev', '/'),
    serpapi => Uri.https('serpapi.com', '/pricing'),
    searchapi => Uri.https('www.searchapi.io', '/'),
    firecrawl => Uri.https('www.firecrawl.dev', '/pricing'),
    _ => null,
  };

  Uri get endpoint => switch (this) {
    browser => throw StateError('Browser search has no API endpoint'),
    deepseek => Uri.https('api.deepseek.com', '/v1/tools/search'),
    zhihuGlobal => Uri.https('developer.zhihu.com', '/api/v1/content/global_search'),
    zhihuSite => Uri.https('developer.zhihu.com', '/api/v1/content/zhihu_search'),
    anysearch => Uri.https('api.anysearch.com', '/v1/search'),
    tavily => Uri.https('api.tavily.com', '/search'),
    brave => Uri.https('api.search.brave.com', '/res/v1/web/search'),
    exa => Uri.https('api.exa.ai', '/search'),
    serper => Uri.https('google.serper.dev', '/search'),
    serpapi => Uri.https('serpapi.com', '/search.json'),
    searchapi => Uri.https('www.searchapi.io', '/api/v1/search'),
    firecrawl => Uri.https('api.firecrawl.dev', '/v2/search'),
  };
}
