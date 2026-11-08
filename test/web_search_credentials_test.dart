import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/func/web_search_api.dart';
import 'package:zone/model/web_search_mode.dart';
import 'package:zone/model/web_search_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zone/func/web_search_credentials.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'fixture-saved-personal-key';
  setUpAll(() async => S.load(const Locale('en')));
  setUp(() {
    P.rwkvGeneration.generating.q = false;
    P.chat.webSearchMode.q = .off;
    P.chat.receiveId.q = null;
  });

  test('verified credentials and independent Zhihu scopes survive a new store', () async {
    final storage = SearchStorageFixture();
    final first = WebSearchCredentialStore(storage: storage);
    await first.save(.deepseek, key);
    await first.save(.zhihuGlobal, 'fixture-zhihu');
    await first.save(.zhihuSite, 'fixture-zhihu');
    final restarted = WebSearchCredentialStore(storage: storage);
    final saved = await restarted.load();
    expect(saved['deepseek']!.key, key);
    expect(saved['deepseek']!.verified, {WebSearchProvider.deepseek});
    expect(saved['zhihu']!.verified, {WebSearchProvider.zhihuGlobal, WebSearchProvider.zhihuSite});
    await restarted.save(.zhihuSite, 'fixture-replacement');
    expect((await restarted.load())['zhihu']!.verified, {WebSearchProvider.zhihuSite});
    await restarted.remove('zhihu');
    expect((await restarted.load()).keys, ['deepseek']);
    await restarted.remove('deepseek');
    expect(storage.value, isNull);
  });

  test('a later clear waits for a pending save and wins across restart', () async {
    final storage = SearchStorageFixture()..writeGate = Completer<void>();
    final vault = WebSearchCredentialStore(storage: storage);
    final save = vault.save(.deepseek, key);
    await storage.writeStarted.future;
    final remove = vault.remove('deepseek');
    storage.writeGate!.complete();
    await Future.wait([save, remove]);
    expect(await WebSearchCredentialStore(storage: storage).load(), isEmpty);
  });

  test('editing a new credential does not delete an absent native vault', () async {
    final storage = SearchStorageFixture()..failDelete = true;
    final vault = WebSearchCredentialStore(storage: storage);
    await vault.remove('deepseek');
    await vault.invalidate(.deepseek);
    expect(await vault.load(), isEmpty);
    await vault.save(.deepseek, key);
    await expectLater(vault.remove('deepseek'), throwsA(WebSearchFailure.storage));
  });

  test('storage failures are redacted, do not fall back and permit retry', () async {
    final storage = SearchStorageFixture()..failWrite = true;
    final vault = WebSearchCredentialStore(storage: storage);
    await expectLater(vault.save(.deepseek, key), throwsA(WebSearchFailure.storage));
    expect(storage.value, isNull);
    storage.failWrite = false;
    await vault.save(.deepseek, key);
    final retained = storage.value;
    storage.failDelete = true;
    await expectLater(vault.remove('deepseek'), throwsA(WebSearchFailure.storage));
    expect(storage.value, retained);
    storage.failDelete = false;
    await vault.remove('deepseek');
    expect(await vault.load(), isEmpty);
    storage.ignoreWrite = true;
    await expectLater(vault.save(.deepseek, key), throwsA(WebSearchFailure.storage));
  });

  test('malformed vaults are preserved rather than overwritten', () async {
    final storage = SearchStorageFixture()..value = '{"version":1,"providers":{"deepseek":{"key":42}}}';
    final original = storage.value;
    final vault = WebSearchCredentialStore(storage: storage);
    await expectLater(vault.load(), throwsA(WebSearchFailure.storage));
    await expectLater(vault.save(.deepseek, key), throwsA(WebSearchFailure.storage));
    expect(storage.value, original);
  });

  test('App startup restores verified keys without enabling search or another request', () async {
    final storage = await resetSearchStorage();
    await P.chat.webSearchCredentialStore.save(.deepseek, key);
    P.chat.webSearchApiKeys.q = {};
    P.chat.webSearchChecks.q = {};
    P.chat.webSearchCredentialStore = WebSearchCredentialStore(storage: storage);
    await P.chat.restoreWebSearchCredentials();
    expect(P.chat.webSearchApiKeys.q['deepseek'], key);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    P.chat.onWebSearchProviderChanged(.deepseek);
    P.chat.onSwitchWebSearchMode(.search);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!.hasValue, isTrue);
  });

  test('verification saves only after success; changed and cleared keys stay removed', () async {
    final storage = await resetSearchStorage();
    P.chat.webSearchProvider.q = .deepseek;
    await P.chat.onWebSearchKeyChanged(.deepseek, key);
    expect(storage.value, isNull);
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: MockClient((_) async => http.Response('{"results":[]}', 200)));
    expect((await P.chat.webSearchCredentialStore.load())['deepseek']!.key, key);
    await P.chat.onWebSearchKeyChanged(.deepseek, 'fixture-replacement');
    expect(await P.chat.webSearchCredentialStore.load(), isEmpty);
    await P.chat.onWebSearchKeyChanged(.deepseek, '');
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
  });

  test('failed secure save cannot activate or claim success and can be retried', () async {
    final storage = await resetSearchStorage();
    P.chat.webSearchProvider.q = .deepseek;
    await P.chat.onWebSearchKeyChanged(.deepseek, key);
    storage.failWrite = true;
    final client = MockClient((_) async => http.Response('{"results":[]}', 200));
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: client);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!.error, WebSearchFailure.storage);
    expect(P.chat.webSearchStorageError.q, isTrue);
    storage.failWrite = false;
    await P.chat.onVerifyAndEnableWebSearchProvider(.deepseek, client: client);
    expect(P.chat.webSearchMode.q, WebSearchMode.search);
  });

  test('expired authentication invalidates both Zhihu scopes but retains the saved key', () async {
    await resetSearchStorage();
    await P.chat.webSearchCredentialStore.save(.zhihuGlobal, key);
    await P.chat.webSearchCredentialStore.save(.zhihuSite, key);
    await P.chat.restoreWebSearchCredentials();
    P.chat.onWebSearchProviderChanged(.zhihuSite);
    P.chat.onSwitchWebSearchMode(.search);
    await P.chat.onWebSearchProviderFailure(.zhihuSite, .unauthorized);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    final saved = (await P.chat.webSearchCredentialStore.load())['zhihu']!;
    expect(saved.key, key);
    expect(saved.verified, isEmpty);
    for (final scope in [WebSearchProvider.zhihuGlobal, WebSearchProvider.zhihuSite]) {
      expect(P.chat.webSearchChecks.q[scope]!.error, WebSearchFailure.unauthorized);
    }
  });

  test('balance, quota and rate limits have distinct safe recovery messages', () async {
    await resetSearchStorage();
    await P.chat.webSearchCredentialStore.save(.deepseek, key);
    await P.chat.restoreWebSearchCredentials();
    P.chat.onWebSearchProviderChanged(.deepseek);
    P.chat.onSwitchWebSearchMode(.search);
    await P.chat.onWebSearchProviderFailure(.deepseek, .balance);
    expect(P.chat.webSearchMode.q, WebSearchMode.off);
    expect(P.chat.webSearchValidationText(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!), S.current.web_search_balance);
    expect((await P.chat.webSearchCredentialStore.load())['deepseek']!.key, key);
    final messages = <String>{};
    for (final failure in [WebSearchFailure.balance, WebSearchFailure.quota, WebSearchFailure.rateLimit]) {
      await P.chat.onWebSearchProviderFailure(.deepseek, failure);
      messages.add(P.chat.webSearchValidationText(P.chat.webSearchChecks.q[WebSearchProvider.deepseek]!));
    }
    expect(messages, hasLength(3));
    expect(messages.any((message) => message.contains(key)), isFalse);
  });
}

Future<SearchStorageFixture> resetSearchStorage() async {
  try {
    await P.chat.webSearchCredentialStore.load();
  } catch (_) {}
  final storage = SearchStorageFixture();
  P.chat.webSearchCredentialStore = WebSearchCredentialStore(storage: storage);
  P.chat.webSearchApiKeys.q = {};
  P.chat.webSearchChecks.q = {};
  P.chat.webSearchStorageError.q = false;
  P.chat.webSearchKeysLoading.q = false;
  await P.chat.restoreWebSearchCredentials();
  return storage;
}

class SearchStorageFixture extends FlutterSecureStorage {
  String? value;
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;
  bool ignoreWrite = false;
  Completer<void>? writeGate;
  final writeStarted = Completer<void>();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failRead) throw StateError('fixture-private-storage-error');
    return value;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    await writeGate?.future;
    if (failWrite) throw StateError('fixture-private-storage-error');
    if (ignoreWrite) return;
    this.value = value;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failDelete) throw StateError('fixture-private-storage-error');
    value = null;
  }
}
