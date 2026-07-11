// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:local_web_search/local_web_search.dart';
import 'package:local_web_search/src/browser/in_app_web_view_adapter.dart';

class _FakeBrowserDelegate implements SearchBrowserControllerDelegate {
  String? loadedUrl;
  final loadedUrls = <String>[];
  Object? scriptResult;
  Object? Function(String url)? scriptResultForUrl;

  @override
  bool get supportsBrowserActions => true;

  @override
  Future<Object?> evaluateJavaScript(String source) async {
    final _ = source;
    return scriptResult;
  }

  @override
  Future<void> loadUrl(String url) async {
    loadedUrl = url;
    loadedUrls.add(url);
    final resultForUrl = scriptResultForUrl;
    if (resultForUrl == null) return;
    scriptResult = resultForUrl(url);
  }
}

void main() {
  test('only main-frame WebView errors affect the page state', () {
    expect(webViewErrorAffectsMainPage(true), isTrue);
    expect(webViewErrorAffectsMainPage(false), isFalse);
    expect(webViewErrorAffectsMainPage(null), isFalse);
  });

  test('loadGoogleSearch builds a Google search URL', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    controller.attach(delegate);

    await controller.loadGoogleSearch('RWKV Chat search');

    expect(
      delegate.loadedUrl,
      'https://www.google.com/search?igu=1&hl=en&num=10&q=RWKV+Chat+search',
    );
    expect(controller.currentUrl, delegate.loadedUrl);
  });

  test('SearchEngines exposes ten selectable engines', () {
    expect(SearchEngines.all.length, 10);
    expect(SearchEngines.all.map((engine) => engine.id), contains('google'));
    expect(SearchEngines.all.map((engine) => engine.id), contains('bing'));
    expect(SearchEngines.all.map((engine) => engine.id), contains('baidu'));
  });

  test('reachability probe accepts a same-engine search response', () async {
    final probe = SearchEngineReachabilityProbe(
      attempts: 1,
      request: ({required uri, required timeout}) async {
        final _ = (uri, timeout);
        return SearchEngineProbeResponse(
          statusCode: 200,
          finalUri: Uri.parse('https://www.google.com/search?q=RWKV'),
          body: '<html><title>RWKV - Google Search</title></html>',
        );
      },
    );

    final availability = await probe.probe(SearchEngines.google);

    expect(availability.isAvailable, true);
    expect(availability.statusCode, 200);
  });

  test('reachability probe rejects cross-engine redirects', () async {
    final probe = SearchEngineReachabilityProbe(
      attempts: 1,
      request: ({required uri, required timeout}) async {
        final _ = (uri, timeout);
        return SearchEngineProbeResponse(
          statusCode: 200,
          finalUri: Uri.parse('https://www.bing.com/'),
          body: '<html><title>Bing</title></html>',
        );
      },
    );

    final availability = await probe.probe(SearchEngines.ecosia);

    expect(availability.isUnavailable, true);
    expect(availability.error, contains('Redirected to www.bing.com'));
  });

  test('reachability probe rejects human verification pages', () async {
    final probe = SearchEngineReachabilityProbe(
      attempts: 1,
      request: ({required uri, required timeout}) async {
        final _ = (uri, timeout);
        return SearchEngineProbeResponse(
          statusCode: 200,
          finalUri: Uri.parse('https://yandex.com/showcaptcha?cc=1'),
          body: '<html><title>Verification required</title></html>',
        );
      },
    );

    final availability = await probe.probe(SearchEngines.yandex);

    expect(availability.isUnavailable, true);
    expect(availability.error, contains('Human verification page'));
  });

  test('reachability probe retries transient failures', () async {
    int requestCount = 0;
    final probe = SearchEngineReachabilityProbe(
      attempts: 2,
      request: ({required uri, required timeout}) async {
        final _ = (uri, timeout);
        requestCount += 1;
        if (requestCount == 1) {
          throw TimeoutException('temporary timeout');
        }
        return SearchEngineProbeResponse(
          statusCode: 202,
          finalUri: Uri.parse('https://duckduckgo.com/?q=RWKV'),
          body: '<html><title>RWKV at DuckDuckGo</title></html>',
        );
      },
    );

    final availability = await probe.probe(SearchEngines.duckDuckGo);

    expect(requestCount, 2);
    expect(availability.isAvailable, true);
    expect(availability.statusCode, 202);
  });

  test('visibleSearchEngines hides only confirmed unavailable engines', () {
    final availability = <String, SearchEngineAvailability>{
      SearchEngines.google.id: SearchEngineAvailability.unavailable(
        engine: SearchEngines.google,
        error: 'Timed out.',
      ),
      SearchEngines.bing.id: SearchEngineAvailability.available(
        engine: SearchEngines.bing,
        statusCode: 200,
        elapsed: const Duration(milliseconds: 20),
      ),
      SearchEngines.baidu.id: SearchEngineAvailability.checking(
        SearchEngines.baidu,
      ),
    };

    final visible = visibleSearchEngines(
      engines: <SearchEngine>[
        SearchEngines.google,
        SearchEngines.bing,
        SearchEngines.baidu,
      ],
      availability: availability,
    );

    expect(visible, <SearchEngine>[SearchEngines.bing, SearchEngines.baidu]);
  });

  test('resolveVisibleSearchEngine replaces an unavailable selection', () {
    final availability = <String, SearchEngineAvailability>{
      SearchEngines.google.id: SearchEngineAvailability.unavailable(
        engine: SearchEngines.google,
        error: 'Connection failed.',
      ),
      SearchEngines.bing.id: SearchEngineAvailability.available(
        engine: SearchEngines.bing,
        statusCode: 200,
        elapsed: const Duration(milliseconds: 20),
      ),
    };

    final selected = resolveVisibleSearchEngine(
      selectedEngine: SearchEngines.google,
      engines: <SearchEngine>[SearchEngines.google, SearchEngines.bing],
      availability: availability,
    );

    expect(selected, SearchEngines.bing);
  });

  test('loadSearch builds selected engine URL', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    controller.attach(delegate);

    await controller.loadSearch(
      engine: SearchEngines.bing,
      query: 'RWKV Chat search',
    );

    expect(
      delegate.loadedUrl,
      'https://www.bing.com/search?count=10&setlang=en-US&mkt=en-US&q=RWKV+Chat+search',
    );
  });

  test('loadSearch builds localized Bing URL for Chinese queries', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    controller.attach(delegate);

    await controller.loadSearch(engine: SearchEngines.bing, query: '中国');

    expect(
      delegate.loadedUrl,
      'https://www.bing.com/search?count=10&setlang=zh-Hans&mkt=zh-CN&q=%E4%B8%AD%E5%9B%BD',
    );
  });

  test('loadSearch normalizes Sogou Chinese question URLs', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    controller.attach(delegate);

    await controller.loadSearch(
      engine: SearchEngines.sogou,
      query: '中国 国土面积 数量',
    );

    expect(
      delegate.loadedUrl,
      'https://www.sogou.com/web?query=%E4%B8%AD%E5%9B%BD%E7%9A%84%E5%9B%BD%E5%9C%9F%E9%9D%A2%E7%A7%AF%E6%98%AF%E5%A4%9A%E5%B0%91',
    );
  });

  test('loadSearch preserves mixed Latin terms for Sogou URLs', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    controller.attach(delegate);

    await controller.loadSearch(
      engine: SearchEngines.sogou,
      query: 'RWKV Transformer 区别',
    );

    expect(
      delegate.loadedUrl,
      'https://www.sogou.com/web?query=RWKV+Transformer+%E5%8C%BA%E5%88%AB',
    );
  });

  test('runSerpExtraction parses script JSON', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    delegate.scriptResult = '''
{"href":"https://www.bing.com/search?q=RWKV","title":"RWKV - Bing","items":[{"title":"RWKV","url":"https://www.rwkv.com/","snippet":"RWKV language model"}]}
''';
    controller.attach(delegate);

    final result = await controller.runSerpExtraction();

    expect(result.hasError, false);
    expect(result.items.length, 1);
    expect(result.items.first.title, 'RWKV');
    expect(result.items.first.url, 'https://www.rwkv.com/');
    expect(result.pageUrl, 'https://www.bing.com/search?q=RWKV');
    expect(result.pageTitle, 'RWKV - Bing');
  });

  test('runDeepExtraction parses page markdown JSON', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    delegate.scriptResult = '''
{"href":"https://example.com/china","title":"China overview","markdown":"# China\\nChina is a country in East Asia.","rawTextLength":120,"markdownLength":42}
''';
    controller.attach(delegate);

    const source = SearchReferenceSource(
      rank: 1,
      title: 'China',
      url: 'https://example.com/china',
      summary: 'China overview',
    );
    final result = await controller.runDeepExtraction(source: source);

    expect(result.hasContent, true);
    expect(result.title, 'China overview');
    expect(result.url, 'https://example.com/china');
    expect(result.markdown, contains('# China'));
    expect(result.toPromptBlock(), contains('Extracted page content'));
  });

  test('SearchExtractionResult rejects stale engine pages', () {
    final result = SearchExtractionResult.fromJavaScriptResult('''
{"href":"https://www.bing.com/search?q=RWKV","title":"RWKV - Bing","items":[{"title":"RWKV","url":"https://www.rwkv.com/","snippet":"RWKV language model"}]}
''');

    final validated = result.validatedForEngine(SearchEngines.google);

    expect(validated.hasError, true);
    expect(validated.items, isEmpty);
    expect(validated.error, contains('did not match Google'));
    expect(validated.pageUrl, 'https://www.bing.com/search?q=RWKV');
  });

  test('SearchExtractionResult rejects non-result pages on the same host', () {
    final result = SearchExtractionResult.fromJavaScriptResult('''
{"href":"https://yandex.com/showcaptcha?retpath=search","title":"Captcha","items":[{"title":"Help","url":"https://example.com/","snippet":"captcha page link"}]}
''');

    final validated = result.validatedForEngine(SearchEngines.yandex);

    expect(validated.hasError, true);
    expect(validated.items, isEmpty);
    expect(validated.error, contains('search path'));
  });

  test('SearchExtractionResult preserves script-level blocked-page errors', () {
    final result = SearchExtractionResult.fromJavaScriptResult('''
{"href":"https://www.bing.com/search?q=RWKV","title":"One last step","error":"Search page requires human verification.","items":[{"title":"Help","url":"https://example.com/","snippet":"not an organic result"}]}
''');

    expect(result.hasError, true);
    expect(result.items, isEmpty);
    expect(result.error, 'Search page requires human verification.');
    expect(result.pageTitle, 'One last step');
  });

  test('SearchExtractionResult reports invalid JSON', () {
    final result = SearchExtractionResult.fromJavaScriptResult('not-json');

    expect(result.hasError, true);
    expect(result.items, isEmpty);
    expect(result.rawJson, 'not-json');
  });

  test('SearchExtractionResult cleans and deduplicates script items', () {
    final result = SearchExtractionResult.fromJavaScriptResult('''
{"href":"https://www.google.com/search?q=RWKV","title":"RWKV - Google Search","items":[{"title":" Result \\n One ","url":"https://Example.com/path?utm_source=x&id=42#section","snippet":" first \\n snippet "},{"title":"Duplicate","url":"https://example.com/path?id=42&utm_medium=y#other","snippet":"dupe"},{"title":"","url":"https://valid.example/","snippet":"empty title"},{"title":"Mail","url":"mailto:test@example.com","snippet":"invalid scheme"}]}
''');

    expect(result.hasError, false);
    expect(result.items.length, 1);
    expect(result.items.first.title, 'Result One');
    expect(result.items.first.url, 'https://example.com/path?id=42');
    expect(result.items.first.snippet, 'first snippet');
  });

  test('SearchExtractionResult preserves non-UTF8 percent-encoded queries', () {
    final result = SearchExtractionResult.fromJavaScriptResult('''
{"href":"https://yandex.com/search/?text=dog","title":"dog - Yandex","items":[{"title":"深圳流浪狗吧-百度贴吧","url":"https://tieba.baidu.com/f?kw=%C9%EE%DB%DA%C1%F7%C0%CB%B9%B7","snippet":"贴吧结果"}]}
''');

    expect(result.hasError, false);
    expect(result.items.length, 1);
    expect(
      result.items.first.url,
      'https://tieba.baidu.com/f?kw=%C9%EE%DB%DA%C1%F7%C0%CB%B9%B7',
    );
  });

  test('SearchExtractionResult caps script items at ten', () {
    final rawItems = <Map<String, String>>[];
    for (int index = 0; index < 12; index += 1) {
      rawItems.add(<String, String>{
        'title': 'Item $index',
        'url': 'https://example.com/result-$index',
        'snippet': 'Snippet $index',
      });
    }

    final result = SearchExtractionResult.fromJavaScriptResult(
      jsonEncode(<String, Object>{
        'href': 'https://www.google.com/search?q=RWKV',
        'title': 'RWKV - Google Search',
        'items': rawItems,
      }),
    );

    expect(result.hasError, false);
    expect(result.items.length, 10);
    expect(result.items.last.title, 'Item 9');
  });

  test('SearchReferenceBuilder builds a query from message history', () {
    final query = SearchReferenceBuilder.buildQuery(<String>[
      'User: RWKV Chat needs local web search.',
      'Assistant: Use an in-app browser.',
      'User: Find Google results with URLs and summaries.',
    ]);

    expect(query, contains('Google'));
    expect(query, contains('RWKV'));
    expect(query, isNot(contains('URLs')));
  });

  test('SearchReferenceBuilder skips assistant-only implementation terms', () {
    final query = SearchReferenceBuilder.buildQuery(<String>[
      'User: RWKV Chat needs local web search.',
      'Assistant: Open Google Search in an embedded browser.',
      'User: Find reliable URLs and summaries for RWKV Chat web search.',
    ]);

    expect(query, isNot(contains('Open Google')));
    expect(query, isNot(contains('Find reliable')));
    expect(query, isNot(contains('needs')));
    expect(query, isNot(contains('feature')));
    expect(query, isNot(contains('feature.')));
    expect(query, contains('RWKV Chat'));
  });

  test('SearchReferenceBuilder prioritizes latest user vocabulary', () {
    final messages = <String>[
      'User: 我们先讨论一个很长的思想史背景。',
      'Assistant: 我可以先解释概念谱系。',
      'User: 中世纪经院哲学里有很多分支。',
      'Assistant: 我会避免直接跳到实现细节。',
      'User: 现在换成柏拉图式对话，苏格拉底如何讨论正义和灵魂？',
    ];

    final query = SearchReferenceBuilder.buildQuery(messages);

    expect(query, contains('柏拉图式对话'));
    expect(query, contains('苏格拉底'));
    expect(query, contains('正义'));
    expect(query, isNot(contains('Assistant')));
  });

  test('SearchQueryGenerator builds queries for casual short messages', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: 你好G7!k9#rVq2@Xz8LpY4m%',
    ]);
    final laugh = SearchQueryGenerator.build(<String>['User: 哈哈哈']);

    expect(result.shouldSearch, true);
    expect(result.query, '你好');
    expect(result.latestUserMessage?.content, '你好');
    expect(laugh.shouldSearch, true);
    expect(laugh.query, '哈哈哈');
  });

  test('SearchQueryGenerator builds a query for simple Chinese prompts', () {
    final result = SearchQueryGenerator.build(<String>['User: 给我讲讲中国']);

    expect(result.shouldSearch, true);
    expect(result.query, '中国');
  });

  test('SearchQueryGenerator date-grounds Chinese current news queries', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: 今天最新新闻有哪些',
    ], currentDate: DateTime(2026, 7, 10));

    expect(result.shouldSearch, true);
    expect(result.query, '2026年7月10日 今日 最新 新闻');
    expect(SearchQueryGenerator.isTimeSensitiveNewsQuery(result.query), true);
  });

  test('SearchQueryGenerator date-grounds English current news queries', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: What are the latest news headlines today?',
    ], currentDate: DateTime(2026, 7, 10));

    expect(result.shouldSearch, true);
    expect(result.query, '2026-07-10 latest news');
  });

  test('SearchQueryGenerator keywordizes Chinese dog count prompts', () {
    final result = SearchQueryGenerator.build(<String>['User: 告诉我深圳有多少条狗？']);

    expect(result.shouldSearch, true);
    expect(result.query, '深圳 养犬 登记 犬只 数量');
  });

  test('SearchQueryGenerator keywordizes Chinese dog license prompts', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: 帮我查一下深圳养狗需要办什么证？',
    ]);

    expect(result.shouldSearch, true);
    expect(result.query, '深圳 狗证 办理 养犬登记');
  });

  test('SearchQueryGenerator compacts RWKV Transformer comparison prompts', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: RWKV 和 Transformer 有什么区别？',
    ]);

    expect(result.shouldSearch, true);
    expect(result.query, 'RWKV vs Transformer');
  });

  test('SearchQueryGenerator expands bare RWKV introduction prompts', () {
    final result = SearchQueryGenerator.build(<String>['User: 给我介绍一下 RWKV。']);

    expect(result.shouldSearch, true);
    expect(result.query, 'RWKV language model');
  });

  test('SearchQueryGenerator avoids treating recent years as quantity', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: 比亚迪最近几年为什么增长这么快？',
    ]);

    expect(result.shouldSearch, true);
    expect(result.query, '比亚迪 增长 原因');
  });

  test('SearchQueryGenerator splits compact Chinese quantity prompts', () {
    final area = SearchQueryGenerator.build(<String>['User: 中国的国土面积是多少？']);
    final population = SearchQueryGenerator.build(<String>[
      'User: 深圳现在大概有多少人口？',
    ]);
    final regions = SearchQueryGenerator.build(<String>['User: 中国有多少个省级行政区？']);

    expect(area.shouldSearch, true);
    expect(area.query, '中国 国土面积 数量');
    expect(population.shouldSearch, true);
    expect(population.query, '深圳 人口 数量');
    expect(regions.shouldSearch, true);
    expect(regions.query, '中国 省级行政区 数量');
  });

  test('SearchQueryGenerator uses lightweight history for references', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: RWKV Chat local web search uses Google and Bing result pages.',
      'Assistant: We can extract URLs from the DOM.',
      'User: 这个在 macOS 上有什么坑？',
    ]);

    expect(result.shouldSearch, true);
    expect(result.usedHistory, true);
    expect(result.query, contains('macOS'));
    expect(result.query, contains('RWKV'));
    expect(result.query, contains('Google'));
    expect(result.query, isNot(contains('上有什么坑')));
    expect(result.supportingMessages, isNotEmpty);
    expect(result.rollingContext.activeEntities, contains('RWKV'));
  });

  test('SearchQueryGenerator can search from pure context references', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: RWKV Chat local web search uses Google and Bing result pages.',
      'Assistant: We can extract URLs from the DOM.',
      'User: 这个有什么坑？',
    ]);

    expect(result.shouldSearch, true);
    expect(result.usedHistory, true);
    expect(result.query, contains('RWKV'));
    expect(result.query, contains('Google'));
    expect(result.query, contains('Bing'));
    expect(result.query, isNot(contains('有什么坑')));
  });

  test('SearchQueryGenerator searches context references without history', () {
    final result = SearchQueryGenerator.build(<String>['User: 这个有什么坑？']);

    expect(result.shouldSearch, true);
    expect(result.query, '这个有什么坑');
    expect(result.usedHistory, false);
  });

  test('SearchQueryGenerator searches pure references after prior tasks', () {
    final htmlTask = SearchQueryGenerator.build(<String>[
      'User: Create a single-file HTML page with polished layout.',
      'Assistant: Done.',
      'User: 这个有什么坑？',
    ]);
    final mathTask = SearchQueryGenerator.build(<String>[
      'User: 请求函数 f(x)=x³-3x 的极大值和极小值，包括求导、令导数为零、判断极值类型的完整步骤？',
      'Assistant: 我可以逐步计算。',
      'User: 这个有什么坑？',
    ]);
    final opaqueTask = SearchQueryGenerator.build(<String>[
      'User: 3OHseuuRnX+m+BrJ28/oVYhxXWShsMwHHKSZBkUNzQJZq6P6',
      'Assistant: OK.',
      'User: 这个有什么坑？',
    ]);

    expect(htmlTask.shouldSearch, true);
    expect(htmlTask.query, isNotEmpty);
    expect(mathTask.shouldSearch, true);
    expect(mathTask.query, isNotEmpty);
    expect(opaqueTask.shouldSearch, true);
    expect(opaqueTask.query, isNotEmpty);
  });

  test('SearchQueryGenerator searches under-specific history references', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: 打游戏的网站',
      'Assistant: 你想做哪类游戏网站？',
      'User: 这个有什么坑？',
    ]);

    expect(result.shouldSearch, true);
    expect(result.query, isNotEmpty);
    expect(result.usedHistory, true);
  });

  test('SearchQueryGenerator handles RWKV Chat database sample prompts', () {
    final goroutines = SearchQueryGenerator.build(<String>[
      'User: Explain what Goroutines are in the Go language and how they differ from traditional threads. Use a simple concurrent code example.',
    ]);
    final moonlight = SearchQueryGenerator.build(<String>[
      'User: 植物如何利用月夜中的微弱月光进行光合作用?G7!k9#rVq2@Xz8LpY4m%',
    ]);
    final pressRelease = SearchQueryGenerator.build(<String>[
      'User: Write a press release for the launch of a new generation drone, intended for major tech media outlets.',
    ]);

    expect(goroutines.shouldSearch, true);
    expect(goroutines.query, contains('Goroutines'));
    expect(goroutines.query, contains('Go'));
    expect(goroutines.query, contains('threads'));
    expect(moonlight.shouldSearch, true);
    expect(moonlight.query, contains('植物'));
    expect(moonlight.query, isNot(contains('G7!k9')));
    expect(pressRelease.shouldSearch, true);
    expect(pressRelease.query, contains('press'));
  });

  test(
    'SearchQueryGenerator removes task shell words from mixed explain prompts',
    () {
      final result = SearchQueryGenerator.build(<String>[
        'User: 解释发布-订阅（Publish-Subscribe）设计模式。用代码实现一个简单的事件总线，包含 on, off, emit 方法。',
      ]);

      expect(result.shouldSearch, true);
      expect(result.query, contains('发布'));
      expect(result.query, contains('订阅'));
      expect(result.query, contains('Publish-Subscribe'));
      expect(result.query, contains('事件总线'));
      expect(result.query, isNot(contains('解释发布')));
      expect(result.query, isNot(contains('用代码实现一个简单')));
    },
  );

  test('SearchQueryGenerator searches opaque tokens and roleplay prompts', () {
    final opaque = SearchQueryGenerator.build(<String>[
      'User: 3OHseuuRnX+m+BrJ28/oVYhxXWShsMwHHKSZBkUNzQJZq6P6',
    ]);
    final roleplay = SearchQueryGenerator.build(<String>[
      'User: 请扮演一个挑剔的甲方客户，我来向你汇报我的产品方案。',
    ]);

    expect(opaque.shouldSearch, true);
    expect(opaque.query, '3OHseuuRnX+m+BrJ28/oVYhxXWShsMwHHKSZBkUNzQJZq6P6');
    expect(roleplay.shouldSearch, true);
    expect(roleplay.query, isNotEmpty);
  });

  test('SearchQueryGenerator searches pure math workout prompts', () {
    final derivative = SearchQueryGenerator.build(<String>[
      'User: 请求函数 f(x)=x³-3x 的极大值和极小值，包括求导、令导数为零、判断极值类型的完整步骤？',
    ]);
    final firstPrinciples = SearchQueryGenerator.build(<String>[
      'User: Using the limit definition of the derivative, find the derivative of f(x)=x^2+3x. Show every algebraic step.',
    ]);

    expect(derivative.shouldSearch, true);
    expect(derivative.query, isNotEmpty);
    expect(firstPrinciples.shouldSearch, true);
    expect(firstPrinciples.query, isNotEmpty);
  });

  test('SearchQueryGenerator trims low-signal words from advice queries', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: My teenagers are getting very vocal about current political issues, often repeating things they hear online. How do I encourage critical thinking?',
    ]);

    expect(result.shouldSearch, true);
    expect(result.query, contains('teenagers'));
    expect(result.query, contains('political'));
    expect(result.query, contains('online'));
    expect(result.query, isNot(contains('getting')));
    expect(result.query, isNot(contains('very')));
    expect(result.query, isNot(contains('often')));
    expect(result.query, isNot(contains('they')));
  });

  test('SearchQueryGenerator compresses long Chinese advice queries', () {
    final abroad = SearchQueryGenerator.build(<String>[
      'User: 孩子即将出国留学，请帮我列一份行前准备清单，重点放在心理建设和文化适应上，而非仅仅是物品清单',
    ]);
    final secondChild = SearchQueryGenerator.build(<String>[
      'User: 我最近在想要不要生二胎，但这个问题一想到就头大，因为钱、精力、住房、老人帮忙程度全都要算进去。你帮我做一个讨论框架，让我能和另一半比较冷静地聊，而不是一聊就情绪上来',
    ]);

    expect(abroad.shouldSearch, true);
    expect(abroad.query, contains('出国留学'));
    expect(abroad.query, contains('行前准备清单'));
    expect(abroad.query, contains('心理建设'));
    expect(abroad.query, contains('文化适应'));
    expect(abroad.query, isNot(contains('请帮我列一份')));
    expect(secondChild.shouldSearch, true);
    expect(secondChild.query, contains('生二胎'));
    expect(secondChild.query, contains('老人帮忙程度'));
    expect(secondChild.query, contains('讨论框架'));
    expect(secondChild.query, isNot(contains('我最近在想要不要')));
  });

  test('SearchReferenceBuilder creates prompt data from extracted results', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: 'RWKV Language Model',
          url: 'https://www.rwkv.com/',
          snippet: 'RWKV is an RNN with LLM performance.',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: Explain RWKV.'],
      query: 'RWKV language model',
      extraction: extraction,
    );

    expect(bundle.sources.length, 1);
    expect(bundle.sources.first.summary, contains('RNN'));
    expect(bundle.promptContext, contains('Search query: RWKV language model'));
    expect(bundle.promptContext, contains('https://www.rwkv.com/'));
  });

  test('SearchReferenceBuilder retains ranked current-news results', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: '国内要闻',
          url: 'https://example.com/china',
          snippet: '全国新闻摘要。',
        ),
        SearchResultItem(
          title: '国际动态',
          url: 'https://example.com/world',
          snippet: '全球事件更新。',
        ),
        SearchResultItem(
          title: '财经市场',
          url: 'https://example.com/finance',
          snippet: '市场信息汇总。',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 今天最新新闻有哪些'],
      query: '2026年7月10日 今日 最新 新闻',
      extraction: extraction,
      currentDate: DateTime(2026, 7, 10),
    );

    expect(bundle.hasError, false);
    expect(bundle.sources.length, 3);
    expect(bundle.promptContext, contains('当前日期: 2026年7月10日'));
    expect(bundle.promptContext, contains('不得编造日期或新闻'));
    expect(bundle.promptContext, contains('每条具体新闻使用 [来源 N]'));
    expect(bundle.promptContext, contains('没有来源能从标题、摘要、正文或 URL 确认'));
    expect(bundle.promptContext, contains('禁止将这些来源列为“今日新闻”'));
  });

  test('current-news prompt identifies only same-day source evidence', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: '2026年7月10日要闻',
          url: 'https://example.com/news/20260710',
          snippet: '刚刚发布的当日新闻摘要。',
        ),
        SearchResultItem(
          title: '2026年回顾',
          url: 'https://example.com/archive',
          snippet: '2026年6月24日发布。',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 今天最新新闻有哪些'],
      query: '2026年7月10日 今日 最新 新闻',
      extraction: extraction,
      currentDate: DateTime(2026, 7, 10),
    );

    expect(bundle.promptContext, contains('只有 [来源 1]'));
    expect(bundle.promptContext, contains('其余来源只能标为背景资料或旧信息'));
  });

  test('deep prompt keeps current-news date and evidence requirements', () {
    const deepResult = SearchDeepResult(
      rank: 1,
      title: '今日要闻',
      url: 'https://example.com/news',
      markdown: '# 今日要闻\n已核实的新闻内容。',
      rawTextLength: 30,
      markdownLength: 20,
    );

    final context = SearchReferenceBundle.buildDeepPromptContext(
      query: '2026年7月10日 今日 最新 新闻',
      results: const <SearchDeepResult>[deepResult],
      currentDate: DateTime(2026, 7, 10),
    );

    expect(context, contains('当前日期: 2026年7月10日'));
    expect(context, contains('不得编造日期或新闻'));
    expect(context, contains('没有来源能从标题、摘要、正文或 URL 确认'));
    expect(context, contains('Deep page results'));
  });

  test('reference diagnostics summarizes the active search bundle', () {
    const result = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: '今日要闻',
          url: 'https://example.com/news',
          snippet: '新闻摘要。',
        ),
      ],
      rawJson: '{"items":[]}',
    );
    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 今天最新新闻有哪些'],
      searchEngine: SearchEngines.brave,
      query: '2026年7月10日 今日 最新 新闻',
      extraction: result,
      currentDate: DateTime(2026, 7, 10),
    );

    final summary = referenceDiagnosticsSummary(bundle: bundle, result: result);

    expect(summary, contains('Brave: Usable'));
    expect(summary, contains('1 kept, 1 parsed'));
    expect(summary, contains('2026年7月10日'));
    expect(summary, isNot(contains('No diagnostics yet')));
  });

  test('SearchReferenceBuilder filters unrelated extracted results', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: 'Axis Max Life Insurance',
          url: 'https://www.maxlifeinsurance.com/',
          snippet: 'Offers protection plans and retirement information.',
        ),
        SearchResultItem(
          title: 'Publish-subscribe pattern',
          url: 'https://example.com/pubsub',
          snippet:
              'The publish subscribe design pattern routes events through a bus.',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 解释发布-订阅设计模式'],
      query: 'Publish-Subscribe 发布 订阅 设计模式 简单事件总线',
      extraction: extraction,
    );

    expect(bundle.hasError, false);
    expect(bundle.sources.length, 1);
    expect(bundle.sources.first.title, 'Publish-subscribe pattern');
    expect(bundle.sources.first.url, 'https://example.com/pubsub');
  });

  test('SearchReferenceBuilder reports unrelated result pages', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: 'Axis Max Life Insurance',
          url: 'https://www.maxlifeinsurance.com/',
          snippet: 'Offers protection plans and retirement information.',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 给我讲讲中国'],
      query: '中国',
      extraction: extraction,
    );

    expect(bundle.hasError, true);
    expect(bundle.sources, isEmpty);
    expect(bundle.error, contains('did not match query'));
  });

  test('SearchReferenceBuilder matches common Chinese query aliases', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: 'China overview',
          url: 'https://example.com/china',
          snippet: 'China is a country in East Asia.',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 给我讲讲中国'],
      query: '中国',
      extraction: extraction,
    );

    expect(bundle.hasError, false);
    expect(bundle.sources.length, 1);
  });

  test('SearchReferenceBuilder matches Chinese regional script aliases', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: '中華人民共和國- 維基百科',
          url: 'https://zh.wikipedia.org/zh-hk/china',
          snippet: '其後被世界多數國家承認為中國的唯一合法政權。',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 给我讲讲中国'],
      query: '中国',
      extraction: extraction,
    );

    expect(bundle.hasError, false);
    expect(bundle.sources.length, 1);
  });

  test('SearchReferenceBuilder matches Chinese question terms', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: '深圳官方发布犬只登记数据',
          url: 'https://example.com/shenzhen-dogs',
          snippet: '截至 2023 年 5 月，全市登记犬只 23.8 万只。',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 告诉我深圳有多少条狗？'],
      query: '深圳有多少条狗',
      extraction: extraction,
    );

    expect(bundle.hasError, false);
    expect(bundle.sources.length, 1);
    expect(bundle.sources.first.title, '深圳官方发布犬只登记数据');
  });

  test('SearchReferenceBuilder matches dog and canine aliases', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: '犬只登记管理数据',
          url: 'https://example.com/canine-registration',
          snippet: '本年度登记犬只数量持续更新。',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final bundle = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 狗数量'],
      query: '狗数量',
      extraction: extraction,
    );

    expect(bundle.hasError, false);
    expect(bundle.sources.length, 1);
    expect(bundle.sources.first.title, '犬只登记管理数据');
  });

  test(
    'SearchReferenceBuilder rejects city-only results for dog questions',
    () {
      const extraction = SearchExtractionResult(
        items: <SearchResultItem>[
          SearchResultItem(
            title: '深圳市_百度百科',
            url: 'https://baike.baidu.com/item/shenzhen',
            snippet: '深圳市的前身是宝安县，是广东省辖地级市。',
          ),
        ],
        rawJson: '{"items":[]}',
      );

      final bundle = SearchReferenceBuilder.buildBundle(
        messages: <String>['User: 告诉我深圳有多少条狗？'],
        query: '深圳 养犬 登记 犬只 数量',
        extraction: extraction,
      );

      expect(bundle.hasError, true);
      expect(bundle.sources, isEmpty);
    },
  );

  test('SearchReferenceBuilder matches compact Chinese quantity terms', () {
    const extraction = SearchExtractionResult(
      items: <SearchResultItem>[
        SearchResultItem(
          title: '国情_中国政府网',
          url: 'https://www.gov.cn/guoqing/',
          snippet: '中国陆地总面积约960万平方千米。',
        ),
        SearchResultItem(
          title: '深圳市统计局人口数据',
          url: 'https://tjj.sz.gov.cn/',
          snippet: '深圳市常住人口数据持续发布。',
        ),
      ],
      rawJson: '{"items":[]}',
    );

    final area = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 中国的国土面积是多少？'],
      query: '中国国土面积 数量',
      extraction: extraction,
    );
    final population = SearchReferenceBuilder.buildBundle(
      messages: <String>['User: 深圳现在大概有多少人口？'],
      query: '深圳现在大概人口 数量',
      extraction: extraction,
    );

    expect(area.hasError, false);
    expect(area.sources.length, 1);
    expect(area.sources.first.title, '国情_中国政府网');
    expect(population.hasError, false);
    expect(population.sources.length, 1);
    expect(population.sources.first.title, '深圳市统计局人口数据');
  });

  test(
    'SearchReferenceService loads search page and stores latest bundle',
    () async {
      final controller = SearchBrowserController();
      final delegate = _FakeBrowserDelegate();
      delegate.scriptResult = '''
{"href":"https://www.bing.com/search?q=RWKV","title":"RWKV - Bing","items":[{"title":"RWKV","url":"https://www.rwkv.com/","snippet":"RWKV language model"}]}
''';
      controller.attach(delegate);

      final bundle = await SearchReferenceService.searchWithBrowser(
        controller: controller,
        messages: <String>[
          'User: Find reliable sources about RWKV language model.',
        ],
        pageLoadDelay: Duration.zero,
        retryDelay: Duration.zero,
      );

      expect(delegate.loadedUrl, contains('https://www.bing.com/search'));
      expect(bundle.sources.length, 1);
      expect(bundle.promptContext, contains('RWKV language model'));
      expect(controller.latestReferenceBundle.sources.length, 1);
    },
  );

  test('SearchReferenceService reads deep page results when enabled', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    delegate.scriptResultForUrl = (url) {
      if (url.contains('www.bing.com/search')) {
        return '''
{"href":"https://www.bing.com/search?q=%E4%B8%AD%E5%9B%BD","title":"China - Bing","items":[{"title":"China overview","url":"https://example.com/china","snippet":"China is a country in East Asia."}]}
''';
      }
      if (url == 'https://example.com/china') {
        return '''
{"href":"https://example.com/china","title":"China overview page","markdown":"# China\\nChina has provinces, cities, and a large population.","rawTextLength":320,"markdownLength":58}
''';
      }
      return '''
{"href":"$url","title":"Empty","markdown":"","rawTextLength":0,"markdownLength":0,"error":"Unexpected URL"}
''';
    };
    controller.attach(delegate);

    final bundle = await SearchReferenceService.searchWithBrowser(
      controller: controller,
      messages: <String>['User: 给我讲讲中国'],
      pageLoadDelay: Duration.zero,
      retryDelay: Duration.zero,
      enableDeepResults: true,
      detailPageLoadDelay: Duration.zero,
    );

    expect(delegate.loadedUrls.length, 2);
    expect(delegate.loadedUrls.first, contains('www.bing.com/search'));
    expect(delegate.loadedUrls.last, 'https://example.com/china');
    expect(bundle.hasError, false);
    expect(bundle.sources.length, 1);
    expect(bundle.hasDeepResults, true);
    expect(bundle.deepResults.length, 1);
    expect(bundle.deepPromptContext, contains('Deep page results'));
    expect(bundle.deepPromptContext, contains('China has provinces'));
    expect(controller.latestReferenceBundle.hasDeepResults, true);
  });

  test(
    'SearchReferenceService skips deep page results when disabled',
    () async {
      final controller = SearchBrowserController();
      final delegate = _FakeBrowserDelegate();
      delegate.scriptResultForUrl = (url) {
        return '''
{"href":"https://www.bing.com/search?q=%E4%B8%AD%E5%9B%BD","title":"China - Bing","items":[{"title":"China overview","url":"https://example.com/china","snippet":"China is a country in East Asia."}]}
''';
      };
      controller.attach(delegate);

      final bundle = await SearchReferenceService.searchWithBrowser(
        controller: controller,
        messages: <String>['User: 给我讲讲中国'],
        pageLoadDelay: Duration.zero,
        retryDelay: Duration.zero,
      );

      expect(delegate.loadedUrls.length, 1);
      expect(bundle.sources.length, 1);
      expect(bundle.deepResults, isEmpty);
      expect(bundle.deepPromptContext, isEmpty);
    },
  );

  test(
    'SearchReferenceService keeps reading sources after a deep miss',
    () async {
      final controller = SearchBrowserController();
      final delegate = _FakeBrowserDelegate();
      delegate.scriptResultForUrl = (url) {
        if (url.contains('www.bing.com/search')) {
          return '''
{"href":"https://www.bing.com/search?q=%E4%B8%AD%E5%9B%BD","title":"China - Bing","items":[{"title":"Bad China mirror","url":"https://bad.example/china","snippet":"China overview"},{"title":"China overview","url":"https://example.com/china","snippet":"China overview"}]}
''';
        }
        if (url == 'https://bad.example/china') {
          return '''
{"href":"https://bad.example/china","title":"Bad China mirror","markdown":"","rawTextLength":0,"markdownLength":0,"error":"Deep extraction found no readable page content."}
''';
        }
        return '''
{"href":"https://example.com/china","title":"China overview","markdown":"# China\\nReadable page content.","rawTextLength":180,"markdownLength":32}
''';
      };
      controller.attach(delegate);

      final bundle = await SearchReferenceService.searchWithBrowser(
        controller: controller,
        messages: <String>['User: 给我讲讲中国'],
        pageLoadDelay: Duration.zero,
        retryDelay: Duration.zero,
        enableDeepResults: true,
        maxDeepResults: 1,
        detailPageLoadDelay: Duration.zero,
      );

      expect(bundle.sources.length, 2);
      expect(bundle.deepResults.length, 2);
      expect(bundle.deepResults.first.hasError, true);
      expect(bundle.deepResults.last.hasContent, true);
      expect(bundle.deepPromptContext, contains('Readable page content'));
    },
  );

  test('SearchReferenceService searches simple Chinese prompts', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    delegate.scriptResult = '''
{"href":"https://www.bing.com/search?q=%E7%BB%99%E6%88%91%E8%AE%B2%E8%AE%B2%E4%B8%AD%E5%9B%BD","title":"China - Bing","items":[{"title":"China","url":"https://example.com/china","snippet":"China overview"}]}
''';
    controller.attach(delegate);

    final bundle = await SearchReferenceService.searchWithBrowser(
      controller: controller,
      messages: <String>['User: 给我讲讲中国'],
      pageLoadDelay: Duration.zero,
      retryDelay: Duration.zero,
    );

    expect(delegate.loadedUrl, contains('https://www.bing.com/search'));
    expect(delegate.loadedUrl, contains('%E4%B8%AD%E5%9B%BD'));
    expect(bundle.hasError, false);
    expect(bundle.sources.length, 1);
  });

  test(
    'SearchReferenceService retries relevance failures with a fallback engine',
    () async {
      final controller = SearchBrowserController();
      final delegate = _FakeBrowserDelegate();
      delegate.scriptResultForUrl = (url) {
        if (url.contains('duckduckgo.com')) {
          return '''
{"href":"https://duckduckgo.com/?q=%E6%B7%B1%E5%9C%B3+%E5%85%BB%E7%8A%AC+%E7%99%BB%E8%AE%B0+%E7%8A%AC%E5%8F%AA+%E6%95%B0%E9%87%8F","title":"深圳 养犬 登记 犬只 数量 at DuckDuckGo","items":[{"title":"深圳登记犬只达23.8万只","url":"https://cgj.sz.gov.cn/zjcg/zh/content/post_10616673.html","snippet":"深圳登记犬只达23.8万只，市民可了解犬只芯片、疫苗注射、犬只办证及养犬健康等知识。"}]}
''';
        }
        return '''
{"href":"https://www.bing.com/search?q=%E6%B7%B1%E5%9C%B3+%E5%85%BB%E7%8A%AC+%E7%99%BB%E8%AE%B0+%E7%8A%AC%E5%8F%AA+%E6%95%B0%E9%87%8F","title":"深圳 养犬 登记 犬只 数量 - 搜索","items":[{"title":"深圳市_百度百科","url":"https://baike.baidu.com/item/%E6%B7%B1%E5%9C%B3%E5%B8%82/11044365","snippet":"深圳市地处中国华南地区，广东南部。"}]}
''';
      };
      controller.attach(delegate);

      final bundle = await SearchReferenceService.searchWithBrowser(
        controller: controller,
        messages: <String>['User: 告诉我深圳有多少条狗？'],
        searchEngine: SearchEngines.bing,
        pageLoadDelay: Duration.zero,
        retryDelay: Duration.zero,
      );

      expect(delegate.loadedUrls.length, 2);
      expect(delegate.loadedUrls.first, contains('www.bing.com/search'));
      expect(delegate.loadedUrls.last, contains('duckduckgo.com'));
      expect(bundle.searchEngine, SearchEngines.duckDuckGo);
      expect(bundle.hasError, false);
      expect(bundle.sources.length, 1);
      expect(bundle.sources.first.title, '深圳登记犬只达23.8万只');
      expect(controller.latestReferenceBundle.sources.length, 1);
    },
  );

  test(
    'SearchReferenceService retries blocked pages with a fallback engine',
    () async {
      final controller = SearchBrowserController();
      final delegate = _FakeBrowserDelegate();
      delegate.scriptResultForUrl = (url) {
        if (url.contains('www.bing.com')) {
          return '''
{"href":"https://www.bing.com/search?q=%E4%B8%AD%E5%9B%BD","title":"中国 - 搜索","items":[{"title":"中国概况","url":"https://example.com/china","snippet":"中国是位于东亚的国家。"}]}
''';
        }
        return '''
{"href":"https://www.google.com/sorry/index?continue=https://www.google.com/search?q=%E4%B8%AD%E5%9B%BD","title":"About this page","error":"Search page blocked automated traffic.","items":[{"title":"Learn more","url":"https://support.google.com/websearch/answer/86640","snippet":"captcha"}]}
''';
      };
      controller.attach(delegate);

      final bundle = await SearchReferenceService.searchWithBrowser(
        controller: controller,
        messages: <String>['User: 给我讲讲中国'],
        searchEngine: SearchEngines.google,
        pageLoadDelay: Duration.zero,
        retryDelay: Duration.zero,
      );

      expect(delegate.loadedUrls.length, 2);
      expect(delegate.loadedUrls.first, contains('www.google.com/search'));
      expect(delegate.loadedUrls.last, contains('www.bing.com/search'));
      expect(bundle.searchEngine, SearchEngines.bing);
      expect(bundle.hasError, false);
      expect(bundle.sources.length, 1);
      expect(bundle.sources.first.title, '中国概况');
      expect(controller.latestReferenceBundle.searchEngine, SearchEngines.bing);
    },
  );

  test('SearchReferenceService reports missing browser adapter', () async {
    final controller = SearchBrowserController();

    final bundle = await SearchReferenceService.searchWithBrowser(
      controller: controller,
      messages: <String>[
        'User: Find reliable sources about RWKV language model.',
      ],
      pageLoadDelay: Duration.zero,
      retryDelay: Duration.zero,
    );

    expect(bundle.hasError, true);
    expect(bundle.error, contains('Browser adapter is not ready'));
    expect(controller.latestReferenceBundle.hasError, true);
  });
}
