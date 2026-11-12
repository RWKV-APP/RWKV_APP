import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
  const key = 'fixture-session-personal-key';
  final storageCalls = <MethodCall>[];
  const oldStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUpAll(() async => S.load(const Locale('en')));
  setUp(() {
    storageCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(oldStorageChannel, (call) async {
      storageCalls.add(call);
      throw StateError('Credential storage must never be accessed');
    });
    P.rwkvGeneration.generating.q = false;
    P.chat.webSearchApiKeys.q = {};
    P.chat.webSearchChecks.q = {};
    P.chat.webSearchMode.q = .off;
    P.chat.webSearchProvider.q = .deepseek;
    P.chat.receiveId.q = null;
  });
  tearDown(() {
    expect(storageCalls, isEmpty);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(oldStorageChannel, null);
    P.chat.webSearchApiKeys.q = {};
    P.chat.webSearchChecks.q = {};
    P.chat.webSearchMode.q = .off;
  });

  Future<void> verify(WebSearchProvider provider) => P.chat.onVerifyAndEnableWebSearchProvider(
    provider,
    client: MockClient((_) async => http.Response('{"results":[]}', 200)),
  );

  test('enter, verify, replace and clear credentials use only current runtime state', () async {
    await P.chat.onWebSearchKeyChanged(.deepseek, key);
    await verify(.deepseek);
    expect(P.chat.webSearchApiKeys.q['deepseek'], key);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);

    await P.chat.onWebSearchKeyChanged(.deepseek, 'fixture-replacement');
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek], isNull);
    await P.chat.onWebSearchKeyChanged(.deepseek, '');
    expect(P.chat.webSearchApiKeys.q['deepseek'], isEmpty);
  });

  test('authentication failure invalidates both Zhihu scopes in memory', () async {
    await P.chat.onWebSearchKeyChanged(.zhihuGlobal, key);
    for (final scope in [WebSearchProvider.zhihuGlobal, WebSearchProvider.zhihuSite]) {
      await P.chat.onVerifyAndEnableWebSearchProvider(
        scope,
        client: MockClient((_) async => http.Response('{"code":0,"data":{"items":[]}}', 200)),
      );
    }
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    await P.chat.onWebSearchProviderFailure(.zhihuSite, .unauthorized);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchApiKeys.q['zhihu'], key);
    for (final scope in [WebSearchProvider.zhihuGlobal, WebSearchProvider.zhihuSite]) {
      expect(P.chat.webSearchChecks.q[scope]!.error, WebSearchFailure.unauthorized);
    }
  });

  test('balance, quota and rate limits retain only the current key and safe messages', () async {
    await P.chat.onWebSearchKeyChanged(.deepseek, key);
    await verify(.deepseek);
    final messages = <String>{};
    for (final failure in [WebSearchFailure.balance, WebSearchFailure.quota, WebSearchFailure.rateLimit]) {
      await P.chat.onWebSearchProviderFailure(.deepseek, failure);
      messages.add(P.chat.webSearchValidationText(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!));
    }
    expect(P.chat.webSearchApiKeys.q['deepseek'], key);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(messages, hasLength(3));
    expect(messages.any((message) => message.contains(key)), isFalse);
  });
}
