import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zone/func/web_search_api.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/web_search_mode.dart';
import 'package:zone/model/web_search_provider.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'fixture-validation-key';
  final success = http.Response(
    jsonEncode({
      'results': [
        {'title': 'RWKV', 'url': 'https://wiki.rwkv.com/', 'summary': 'Documentation'},
      ],
    }),
    200,
  );

  setUpAll(() async => S.load(const Locale('en')));
  setUp(() async {
    P.chat.webSearchApiKeys.q = {};
    P.chat.webSearchChecks.q = {};
    P.chat.webSearchMode.q = .off;
    P.chat.webSearchProvider.q = .deepseek;
    P.chat.receiveId.q = null;
    P.rwkvGeneration.generating.q = false;
    P.chat.webSearchApiKeys.q = {};
  });
  tearDown(() {
    P.chat.onWebSearchSettingsClosed();
    P.chat.webSearchApiKeys.q = {};
    P.chat.webSearchChecks.q = {};
    P.chat.webSearchMode.q = .off;
    P.chat.webSearchProvider.q = .zhihuGlobal;
    P.chat.receiveId.q = null;
    P.rwkvGeneration.generating.q = false;
  });

  test('verification probes the selected provider once and enables only after valid results', () async {
    final response = Completer<http.Response>();
    final entered = Completer<void>();
    int count = 0;
    P.chat.onWebSearchKeyChanged(.deepseek, key);
    final client = MockClient((request) {
      count++;
      expect(request.url, WebSearchProvider.deepseek.endpoint);
      expect(request.headers['Authorization'], 'Bearer $key');
      expect(jsonDecode(request.body)['query'], 'RWKV');
      entered.complete();
      return response.future;
    });
    final pending = P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: client);
    await entered.future;
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!.isLoading, isTrue);
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: client);
    expect(count, 1);
    response.complete(success);
    await pending;
    expect(P.chat.webSearchProvider.q, WebSearchProvider.deepseek);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    final fingerprint = P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!.asData!.value;
    expect(fingerprint, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(fingerprint, isNot(key));
    P.chat.onSwitchWebSearchMode(.off);
    P.chat.onSwitchWebSearchMode(.search);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    expect(count, 1);
    P.chat.onWebSearchKeyChanged(.deepseek, ' $key ');
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    P.chat.onWebSearchKeyChanged(.deepseek, 'fixture-changed-key');
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek], isNull);
  });

  test('a missing required key makes no verification request', () async {
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) async => fail('Unexpected network')));
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!.error, WebSearchFailure.missingKey);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
  });

  for (final entry in {401: WebSearchFailure.unauthorized, 429: WebSearchFailure.rateLimit, 500: WebSearchFailure.unavailable}.entries) {
    test('HTTP ${entry.key} stays off, redacts error bodies and permits retry', () async {
      P.chat.onWebSearchKeyChanged(.deepseek, key);
      await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) async => http.Response(key, entry.key)));
      final state = P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!;
      expect(state.error, entry.value);
      expect(P.chat.webSearchValidationText(state), isNot(contains(key)));
      expect(P.chat.webSearchMode.q, WebSearchMode.off);
      await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) async => success));
      expect(P.chat.webSearchMode.q, WebSearchMode.search);
    });
  }

  test('HTTP 200 needs a supported response, not only a status code', () async {
    P.chat.onWebSearchKeyChanged(.deepseek, key);
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) async => http.Response('{}', 200)));
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!.error, WebSearchFailure.invalidResponse);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) async => http.Response('{"results":[]}', 200)));
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
  });

  test('failed revalidation turns off that active service and preserves another active service', () async {
    P.chat.onWebSearchKeyChanged(.deepseek, key);
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) async => success));
    final denied = MockClient((_) async => http.Response('denied', 401));
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: denied);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    P.chat.onWebSearchProviderChanged(.anysearch);
    P.chat.onSwitchWebSearchMode(.search);
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: denied);
    expect(P.chat.webSearchProvider.q, WebSearchProvider.anysearch);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
  });

  for (final action in ['close', 'key', 'provider', 'off', 'generation', 'completed-generation']) {
    test('$action prevents stale verification from enabling search', () async {
      final response = Completer<http.Response>();
      final entered = Completer<void>();
      P.chat.onWebSearchKeyChanged(.deepseek, key);
      final pending = P.chat.onVerifyAndEnableWebSearchProvider(
        .deepseek,
        client: MockClient((_) {
          entered.complete();
          return response.future;
        }),
      );
      await entered.future;
      switch (action) {
        case 'close':
          P.chat.onWebSearchSettingsClosed();
        case 'key':
          P.chat.onWebSearchKeyChanged(.deepseek, 'fixture-new-key');
        case 'provider':
          P.chat.onWebSearchProviderChanged(.anysearch);
        case 'off':
          P.chat.onSwitchWebSearchMode(.off);
        case 'generation':
          P.rwkvGeneration.generating.q = true;
        case 'completed-generation':
          P.chat.receiveId.q = 1001;
      }
      response.complete(success);
      await pending;
      expect(P.chat.webSearchMode.q, WebSearchMode.off);
      expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]?.hasValue ?? false, isFalse);
    });
  }

  test('a cancelled attempt cannot complete a newer verification attempt', () async {
    final first = Completer<http.Response>();
    final second = Completer<http.Response>();
    P.chat.onWebSearchKeyChanged(.deepseek, key);
    final old = P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) => first.future));
    P.chat.onWebSearchSettingsClosed();
    final current = P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) => second.future));
    first.complete(success);
    await old;
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!.isLoading, isTrue);
    second.complete(success);
    await current;
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
  });

  test('Zhihu scopes verify independently and a shared-key edit invalidates both', () async {
    final client = MockClient((_) async => http.Response('{"Code":0,"Data":{"Items":[]}}', 200));
    P.chat.onWebSearchKeyChanged(.zhihuGlobal, key);
    await P.chat.onVerifyAndEnableWebSearchProvider(.zhihuGlobal, client: client);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.zhihuGlobal]!.hasValue, isTrue);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.zhihuSite], isNull);
    await P.chat.onVerifyAndEnableWebSearchProvider(.zhihuSite, client: client);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.zhihuSite]!.hasValue, isTrue);
    P.chat.onWebSearchKeyChanged(.zhihuGlobal, 'fixture-new-shared-key');
    expect(P.chat.webSearchChecks.q, isEmpty);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
  });
}
