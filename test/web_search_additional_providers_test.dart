import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zone/func/web_search_api.dart';
import 'package:zone/model/web_search_provider.dart';

void main() {
  const key = 'fixture-personal-search-key';
  const url = 'https://wiki.rwkv.com/';
  const excerpt = 'RWKV documentation';
  final payloads = <WebSearchProvider, Map<String, dynamic>>{
    .tavily: {
      'results': [
        {'title': 'RWKV', 'url': url, 'content': excerpt},
      ],
    },
    .brave: {
      'web': {
        'results': [
          {'title': 'RWKV', 'url': url, 'description': excerpt},
        ],
      },
    },
    .exa: {
      'results': [
        {
          'title': 'RWKV',
          'url': url,
          'highlights': [excerpt],
        },
      ],
    },
    .serper: {
      'organic': [
        {'title': 'RWKV', 'link': url, 'snippet': excerpt},
      ],
    },
    .serpapi: {
      'organic_results': [
        {'title': 'RWKV', 'link': url, 'snippet': excerpt},
      ],
    },
    .searchapi: {
      'organic_results': [
        {'title': 'RWKV', 'link': url, 'snippet': excerpt},
      ],
    },
    .firecrawl: {
      'success': true,
      'data': {
        'web': [
          {'title': 'RWKV', 'url': url, 'description': excerpt},
        ],
      },
    },
  };

  for (final entry in payloads.entries) {
    final provider = entry.key;
    test('${provider.name} uses the official contract and normalizes source references', () async {
      final client = MockClient((request) async {
        expect(request.url.origin + request.url.path, provider.endpoint.toString());
        expect(request.followRedirects, isFalse);
        switch (provider) {
          case .tavily:
            expect(request.headers['Authorization'], 'Bearer $key');
            expect(jsonDecode(request.body), {
              'query': 'RWKV',
              'max_results': 3,
              'search_depth': 'basic',
              'include_answer': false,
              'include_raw_content': false,
            });
          case .brave:
            expect(request.method, 'GET');
            expect(request.headers['X-Subscription-Token'], key);
            expect(request.url.queryParameters, {'q': 'RWKV', 'count': '3'});
          case .exa:
            expect(request.headers['X-API-KEY'], key);
            expect(jsonDecode(request.body), {
              'query': 'RWKV',
              'numResults': 3,
              'type': 'auto',
              'contents': {'highlights': true},
            });
          case .serper:
            expect(request.headers['X-API-KEY'], key);
            expect(jsonDecode(request.body), {'q': 'RWKV'});
          case .serpapi:
            expect(request.method, 'GET');
            expect(request.url.queryParameters, {'engine': 'google', 'q': 'RWKV', 'api_key': key});
            expect(request.headers['Authorization'], isNull);
          case .searchapi:
            expect(request.method, 'GET');
            expect(request.headers['Authorization'], 'Bearer $key');
            expect(request.url.queryParameters, {'engine': 'google', 'q': 'RWKV'});
          case .firecrawl:
            expect(request.headers['Authorization'], 'Bearer $key');
            expect(jsonDecode(request.body), {
              'query': 'RWKV',
              'limit': 3,
              'sources': ['web'],
              'highlights': false,
            });
          default:
            fail('Unexpected provider');
        }
        if (request.body.isNotEmpty) expect(request.method, 'POST');
        return http.Response(jsonEncode(entry.value), 200);
      });
      final refs = await searchWebApi(provider: provider, apiKey: key, query: 'RWKV', client: client);
      expect(refs.single.url, url);
      expect(refs.single.title, 'RWKV');
      expect(refs.single.summary, excerpt);
      expect(webSearchApiContext(refs), isNot(contains(key)));
    });

    test('${provider.name} does not retain echoed keys or provider error bodies', () async {
      final echoed = jsonDecode(jsonEncode(entry.value).replaceAll(excerpt, key)) as Map<String, dynamic>;
      await expectLater(
        searchWebApi(
          provider: provider,
          apiKey: key,
          query: 'RWKV',
          client: MockClient((_) async => http.Response(jsonEncode(echoed), 200)),
        ),
        throwsA(WebSearchFailure.invalidResponse),
      );
      await expectLater(
        searchWebApi(provider: provider, apiKey: key, query: 'RWKV', client: MockClient((_) async => http.Response(key, 429))),
        throwsA(WebSearchFailure.rateLimit),
      );
      final unsafe = jsonDecode(jsonEncode(entry.value).replaceAll(url, 'javascript:alert(1)')) as Map<String, dynamic>;
      expect(() => parseWebSearchReferences(provider, unsafe), throwsA(WebSearchFailure.invalidResponse));
    });

    if (!provider.requiresApiKey) continue;
    test('${provider.name} requires the individual user key before networking', () async {
      await expectLater(
        searchWebApi(provider: provider, apiKey: '', query: 'RWKV', client: MockClient((_) async => fail('Unexpected network request'))),
        throwsA(WebSearchFailure.missingKey),
      );
    });
  }

  test('Firecrawl anonymous mode sends no authentication and parses the actual response shape', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], isNull);
      return http.Response(jsonEncode(payloads[WebSearchProvider.firecrawl]), 200);
    });
    final refs = await searchWebApi(provider: .firecrawl, apiKey: '', query: 'RWKV', client: client);
    expect(refs.single.url, url);
  });

  test('all additional providers return at most three distinct references', () {
    for (final entry in payloads.entries) {
      final many = jsonDecode(jsonEncode(entry.value)) as Map<String, dynamic>;
      final rows =
          (many['results'] ??
                  (many['web'] as Map?)?['results'] ??
                  many['organic'] ??
                  many['organic_results'] ??
                  (many['data'] as Map?)?['web'])
              as List;
      final item = Map<String, dynamic>.from(rows.single as Map);
      rows.clear();
      for (final i in [1, 2, 3, 4]) {
        rows.add({...item, 'url': '$url$i', 'link': '$url$i'});
      }
      expect(parseWebSearchReferences(entry.key, many), hasLength(3));
    }
  });
}
