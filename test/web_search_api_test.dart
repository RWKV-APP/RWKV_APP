import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zone/func/web_search_api.dart';
import 'package:zone/model/web_search_provider.dart';
import 'package:zone/model/reference.dart';

void main() {
  const testKey = 'fixture-credential';
  const item = {'title': 'RWKV', 'url': 'https://www.rwkv.com/', 'summary': 'Local inference'};

  test('keeps explicit structured source dates without guessing from titles or snippets', () {
    final refs = parseWebSearchReferences(.deepseek, {
      'results': [
        {...item, 'date': '2025-08-29T16:00:00+00:00'},
        {...item, 'url': 'https://example.com/unknown', 'title': '2026-04-20 page', 'summary': '2025 report', 'date': 'yesterday'},
        {...item, 'url': 'https://example.com/missing'},
      ],
    });
    expect(refs.first.publishedAt, '2025-08-29T16:00:00+00:00');
    expect(refs[1].publishedAt, isEmpty);
    expect(refs[2].publishedAt, isEmpty);
    final context = webSearchApiContext(refs, chinese: true);
    expect(context, startsWith('RWKV\n发布日期：2025-08-29T16:00:00+00:00\n'));
    expect('发布日期：'.allMatches(context), hasLength(1));
    expect(context, isNot(contains('请根据资料')));
    expect(Reference.fromJson(refs.first.toJson()).publishedAt, refs.first.publishedAt);
  });

  test('captures the complete response before reference limits and preserves whitespace', () async {
    final body =
        '  ${jsonEncode({
          'results': [
            for (int i = 0; i < 5; i++) {...item, 'url': 'https://example.com/$i', 'summary': '段' * 2100},
          ],
          'extra': {'trace': 'provider-data'},
        })}\n';
    String? captured;
    int? status;
    final refs = await searchWebApi(
      provider: .deepseek,
      apiKey: testKey,
      query: '深圳有多少条地铁线？',
      client: MockClient((_) async => http.Response(body, 200, headers: {'content-type': 'application/json; charset=utf-8'})),
      onResponse: (code, text) {
        status = code;
        captured = text;
      },
    );
    expect(captured, body);
    expect(status, 200);
    expect(refs, hasLength(3));
    expect(refs.first.summary.runes, hasLength(2000));
    expect(jsonDecode(captured!)['results'], hasLength(5));
  });

  test('complete error responses redact echoed and generated credentials', () async {
    for (final body in [
      jsonEncode({
        'error': 'bad $testKey',
        'api_key': 'generated-credential',
        'nested': {'access_token': 'other-credential'},
      }),
      'password=generated-credential\napi_key=other-credential\nerror=$testKey',
    ]) {
      String? captured;
      await expectLater(
        searchWebApi(
          provider: .deepseek,
          apiKey: testKey,
          query: 'RWKV',
          client: MockClient((_) async => http.Response(body, 402)),
          onResponse: (code, text) {
            expect(code, 402);
            captured = text;
          },
        ),
        throwsA(WebSearchFailure.balance),
      );
      expect(captured, isNotNull);
      for (final key in [testKey, 'generated-credential', 'other-credential']) {
        expect(captured, isNot(contains(key)));
      }
      expect(captured, contains('[REDACTED]'));
    }
  });

  test('oversized responses never expose a partial body as a complete response', () async {
    bool captured = false;
    await expectLater(
      searchWebApi(
        provider: .deepseek,
        apiKey: testKey,
        query: 'RWKV',
        client: MockClient((_) async => http.Response('x' * (1024 * 1024 + 1), 200)),
        onResponse: (_, _) => captured = true,
      ),
      throwsA(WebSearchFailure.invalidResponse),
    );
    expect(captured, isFalse);
  });

  test('Chinese reference context contains only the source fields', () {
    final refs = [
      Reference(title: '城市统计', url: 'https://example.com/statistics', summary: '2021 年已登记犬只 145702 只。'),
      Reference(title: '城市绿地', url: 'https://example.com/parks', summary: '截至 2024 年开放 80 个公园。'),
    ];
    final context = webSearchApiContext(refs, chinese: true);
    expect(
      context,
      '城市统计\n2021 年已登记犬只 145702 只。\n\n'
      '城市绿地\n截至 2024 年开放 80 个公园。',
    );
  });

  test('DeepSeek uses its fixed endpoint and returns references without exposing the key', () async {
    final client = MockClient((request) async {
      expect(request.url, WebSearchProvider.deepseek.endpoint);
      expect(request.method, 'POST');
      expect(request.followRedirects, isFalse);
      expect(request.headers['Authorization'], 'Bearer $testKey');
      expect(jsonDecode(request.body), {'query': 'RWKV', 'count': 3, 'need_content': false});
      return http.Response(
        jsonEncode({
          'results': [item],
        }),
        200,
      );
    });
    final refs = await searchWebApi(provider: .deepseek, apiKey: testKey, query: 'RWKV', client: client);
    expect(refs.single.url, item['url']);
    final context = webSearchApiContext(refs);
    expect(context, 'RWKV\nLocal inference');
    expect(context, isNot(contains(testKey)));
  });

  test('AnySearch uses anonymous JSON search and never forwards a configured credential', () async {
    final client = MockClient((request) async {
      expect(request.url, WebSearchProvider.anysearch.endpoint);
      expect(request.method, 'POST');
      expect(request.followRedirects, isFalse);
      expect(request.headers['Authorization'], isNull);
      expect(jsonDecode(request.body), {'query': 'RWKV', 'max_results': 3, 'format': 'json'});
      return http.Response(
        jsonEncode({
          'code': 0,
          'data': {
            'results': [item],
          },
        }),
        200,
      );
    });
    for (final credential in ['', testKey]) {
      final refs = await searchWebApi(provider: .anysearch, apiKey: credential, query: 'RWKV', client: client);
      expect(refs.single.url, item['url']);
      expect(WebSearchProvider.anysearch.requiresApiKey, isFalse);
    }
  });

  test('AnySearch uses the snippet even when it has a longer content field', () {
    const snippet = '2026年11月4日午后盘中：沪指涨逾1%。';
    final refs = parseWebSearchReferences(.anysearch, {
      'code': 0,
      'data': {
        'results': [
          {'title': '', 'url': 'https://example.com/market', 'snippet': snippet, 'content': '早盘：沪指震荡。$snippet'},
          {'title': 'Docs', 'url': 'https://rwkv.cn/', 'snippet': 'Snippet', 'content': ' '},
          {'title': 'Docs', 'url': 'https://rwkv.cn/docs', 'content': 'Full content only'},
        ],
      },
    });
    expect(refs.first.summary, snippet);
    expect(refs.first.title, isEmpty);
    expect(refs[1].summary, 'Snippet');
    expect(refs.last.summary, isEmpty);
    expect(webSearchApiContext(refs, chinese: true), '$snippet\n\nDocs\nSnippet\n\nDocs');
    expect(() => parseWebSearchReferences(.anysearch, {'code': -1, 'message': 'sensitive body'}), throwsA(WebSearchFailure.unavailable));
  });

  test('DeepSeek uses its summary first and falls back to the snippet if absent or blank', () {
    final refs = parseWebSearchReferences(.deepseek, {
      'results': [
        {...item, 'snippet': 'Ignored snippet'},
        {'title': 'Missing summary', 'url': 'https://example.com/absent', 'snippet': 'First fallback'},
        {'title': 'Blank summary', 'url': 'https://example.com/blank', 'summary': ' ', 'snippet': 'Second fallback'},
      ],
    });
    expect(refs.map((ref) => ref.summary), ['Local inference', 'First fallback', 'Second fallback']);
  });

  test('AnySearch quota responses never return generated credentials or switch authentication', () async {
    int requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.headers['Authorization'], isNull);
      return http.Response('username=fixture\npassword=fixture\napi_key=fixture', 402);
    });
    await expectLater(searchWebApi(provider: .anysearch, apiKey: '', query: 'RWKV', client: client), throwsA(WebSearchFailure.balance));
    expect(requests, 1);
  });

  for (final provider in [WebSearchProvider.zhihuGlobal, WebSearchProvider.zhihuSite]) {
    test('${provider.name} uses GET, timestamp and the shared credential', () async {
      final client = MockClient((request) async {
        expect(request.url.origin, 'https://developer.zhihu.com');
        expect(request.url.path, provider.endpoint.path);
        expect(request.url.queryParameters, {'Query': 'RWKV', 'Count': '3'});
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(int.tryParse(request.headers['X-Request-Timestamp']!), isNotNull);
        return http.Response(
          jsonEncode({
            'Code': 0,
            'Data': {
              'Items': [
                {'Title': '<em>RWKV</em>', 'Url': item['url'], 'ContentText': 'Reference'},
              ],
            },
          }),
          200,
        );
      });
      final refs = await searchWebApi(provider: provider, apiKey: testKey, query: 'RWKV', client: client);
      expect(refs.single.title, 'RWKV');
      expect(provider.credentialId, 'zhihu');
    });
  }

  test('missing key and overlong query make no network request', () async {
    final client = MockClient((_) async => fail('Unexpected network request'));
    await expectLater(searchWebApi(provider: .deepseek, apiKey: '', query: 'RWKV', client: client), throwsA(WebSearchFailure.missingKey));
    await expectLater(
      searchWebApi(provider: .zhihuGlobal, apiKey: testKey, query: '字' * 101, client: client),
      throwsA(WebSearchFailure.invalidQuery),
    );
  });

  for (final entry in {
    401: WebSearchFailure.unauthorized,
    403: WebSearchFailure.unauthorized,
    402: WebSearchFailure.balance,
    429: WebSearchFailure.rateLimit,
    302: WebSearchFailure.unavailable,
    500: WebSearchFailure.unavailable,
  }.entries) {
    test('HTTP ${entry.key} never exposes an echoed credential', () async {
      final client = MockClient((_) async => http.Response(testKey, entry.key));
      await expectLater(searchWebApi(provider: .deepseek, apiKey: testKey, query: 'RWKV', client: client), throwsA(entry.value));
    });
  }

  test('Zhihu HTTP 200 authentication and throttling envelopes use documented error codes', () {
    for (final provider in [WebSearchProvider.zhihuGlobal, WebSearchProvider.zhihuSite]) {
      expect(() => parseWebSearchReferences(provider, {'Code': 20001, 'Message': testKey}), throwsA(WebSearchFailure.unauthorized));
      expect(() => parseWebSearchReferences(provider, {'Code': 30001, 'Message': testKey}), throwsA(WebSearchFailure.rateLimit));
      expect(() => parseWebSearchReferences(provider, {'Code': 90001, 'Message': testKey}), throwsA(WebSearchFailure.unavailable));
    }
  });

  test('timeout is bounded and hides raw transport errors', () async {
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response('{}', 200);
    });
    await expectLater(
      searchWebApi(provider: .deepseek, apiKey: testKey, query: 'RWKV', client: client, timeout: const Duration(milliseconds: 1)),
      throwsA(WebSearchFailure.timeout),
    );
    final broken = MockClient((_) async => throw Exception(testKey));
    await expectLater(
      searchWebApi(provider: .deepseek, apiKey: testKey, query: 'RWKV', client: broken),
      throwsA(WebSearchFailure.unavailable),
    );
  });

  test('invalid schema, unsafe URLs and oversized responses are rejected', () async {
    for (final payload in [
      {'results': 'invalid'},
      {
        'results': [
          {...item, 'url': 'javascript:alert(1)'},
        ],
      },
      {
        'results': [
          {...item, 'url': 'https://user:password@example.com'},
        ],
      },
      {
        'results': [
          {...item, 'summary': 7},
        ],
      },
    ]) {
      expect(() => parseWebSearchReferences(.deepseek, payload), throwsA(WebSearchFailure.invalidResponse));
    }
    final client = MockClient((_) async => http.Response('x' * (1024 * 1024 + 1), 200));
    await expectLater(
      searchWebApi(provider: .deepseek, apiKey: testKey, query: 'RWKV', client: client),
      throwsA(WebSearchFailure.invalidResponse),
    );
  });

  test('business errors cannot become search results', () {
    expect(() => parseWebSearchReferences(.zhihuGlobal, {'Code': 123, 'Message': testKey}), throwsA(WebSearchFailure.unavailable));
  });

  test('a credential echoed inside otherwise valid results is never retained', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'results': [
            {...item, 'summary': testKey},
          ],
        }),
        200,
      ),
    );
    await expectLater(
      searchWebApi(provider: .deepseek, apiKey: testKey, query: 'RWKV', client: client),
      throwsA(WebSearchFailure.invalidResponse),
    );
  });

  test('empty results stay empty and duplicate URLs keep their first occurrence', () {
    expect(parseWebSearchReferences(.deepseek, {'results': []}), isEmpty);
    expect(webSearchApiContext([]), isEmpty);
    final refs = parseWebSearchReferences(.deepseek, {
      'results': [item, item],
    });
    expect(refs, hasLength(1));
  });
}
