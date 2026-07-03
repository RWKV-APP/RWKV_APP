// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:local_web_search/local_web_search.dart';

class _FakeBrowserDelegate implements SearchBrowserControllerDelegate {
  String? loadedUrl;
  Object? scriptResult;

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
  }
}

void main() {
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
      'https://www.bing.com/search?count=10&setlang=en-US&q=RWKV+Chat+search',
    );
  });

  test('runSerpExtraction parses script JSON', () async {
    final controller = SearchBrowserController();
    final delegate = _FakeBrowserDelegate();
    delegate.scriptResult = '''
{"href":"https://www.google.com/search?q=RWKV","title":"RWKV - Google Search","items":[{"title":"RWKV","url":"https://www.rwkv.com/","snippet":"RWKV language model"}]}
''';
    controller.attach(delegate);

    final result = await controller.runSerpExtraction();

    expect(result.hasError, false);
    expect(result.items.length, 1);
    expect(result.items.first.title, 'RWKV');
    expect(result.items.first.url, 'https://www.rwkv.com/');
    expect(result.pageUrl, 'https://www.google.com/search?q=RWKV');
    expect(result.pageTitle, 'RWKV - Google Search');
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

  test('SearchQueryGenerator disables casual short messages', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: 你好G7!k9#rVq2@Xz8LpY4m%',
    ]);
    final laugh = SearchQueryGenerator.build(<String>['User: 哈哈哈']);

    expect(result.shouldSearch, false);
    expect(result.query, isEmpty);
    expect(result.latestUserMessage?.content, '你好');
    expect(laugh.shouldSearch, false);
    expect(laugh.query, isEmpty);
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

  test('SearchQueryGenerator skips context references without history', () {
    final result = SearchQueryGenerator.build(<String>['User: 这个有什么坑？']);

    expect(result.shouldSearch, false);
    expect(result.query, isEmpty);
    expect(result.usedHistory, false);
  });

  test('SearchQueryGenerator skips pure references after offline tasks', () {
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

    expect(htmlTask.shouldSearch, false);
    expect(htmlTask.query, isEmpty);
    expect(mathTask.shouldSearch, false);
    expect(mathTask.query, isEmpty);
    expect(opaqueTask.shouldSearch, false);
    expect(opaqueTask.query, isEmpty);
  });

  test('SearchQueryGenerator skips under-specific history references', () {
    final result = SearchQueryGenerator.build(<String>[
      'User: 打游戏的网站',
      'Assistant: 你想做哪类游戏网站？',
      'User: 这个有什么坑？',
    ]);

    expect(result.shouldSearch, false);
    expect(result.query, isEmpty);
    expect(result.usedHistory, false);
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
    expect(pressRelease.shouldSearch, false);
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

  test('SearchQueryGenerator ignores opaque tokens and roleplay prompts', () {
    final opaque = SearchQueryGenerator.build(<String>[
      'User: 3OHseuuRnX+m+BrJ28/oVYhxXWShsMwHHKSZBkUNzQJZq6P6',
    ]);
    final roleplay = SearchQueryGenerator.build(<String>[
      'User: 请扮演一个挑剔的甲方客户，我来向你汇报我的产品方案。',
    ]);

    expect(opaque.shouldSearch, false);
    expect(opaque.query, isEmpty);
    expect(roleplay.shouldSearch, false);
    expect(roleplay.query, isEmpty);
  });

  test('SearchQueryGenerator skips pure math workout prompts', () {
    final derivative = SearchQueryGenerator.build(<String>[
      'User: 请求函数 f(x)=x³-3x 的极大值和极小值，包括求导、令导数为零、判断极值类型的完整步骤？',
    ]);
    final firstPrinciples = SearchQueryGenerator.build(<String>[
      'User: Using the limit definition of the derivative, find the derivative of f(x)=x^2+3x. Show every algebraic step.',
    ]);

    expect(derivative.shouldSearch, false);
    expect(derivative.query, isEmpty);
    expect(firstPrinciples.shouldSearch, false);
    expect(firstPrinciples.query, isEmpty);
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
}
