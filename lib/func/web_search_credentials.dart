import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zone/func/web_search_api.dart';
import 'package:zone/model/web_search_provider.dart';

typedef SavedSearchCredential = ({String key, Set<WebSearchProvider> verified});

class WebSearchCredentialStore {
  static const storageKey = 'rwkv.chat.search.credentials.v1';
  static const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'rwkv_chat_search', resetOnError: false),
    iOptions: IOSOptions(accountName: 'rwkv.chat.search', accessibility: KeychainAccessibility.unlocked_this_device),
    // This App has no shared Keychain group or cross-device credential sync.
    mOptions: MacOsOptions(accountName: 'rwkv.chat.search', usesDataProtectionKeychain: false),
  );

  final FlutterSecureStorage storage;
  Future<void>? _pending;

  WebSearchCredentialStore({this.storage = secureStorage});

  Future<Map<String, SavedSearchCredential>> load() async {
    if (_pending != null) await _pending;
    try {
      return await _read();
    } catch (_) {
      throw WebSearchFailure.storage;
    }
  }

  Future<void> save(WebSearchProvider provider, String key) => _update((entries) {
    if (provider.credentialId.isEmpty || key.trim().isEmpty || key.length > 4096) {
      throw const FormatException('Invalid search credential');
    }
    final existing = entries[provider.credentialId];
    entries[provider.credentialId] = (
      key: key,
      verified: {if (existing != null && existing.key == key) ...existing.verified, provider},
    );
    return true;
  });

  Future<void> remove(String credentialId) => _update((entries) => entries.remove(credentialId) != null);

  Future<void> invalidate(WebSearchProvider provider) => _update((entries) {
    final existing = entries[provider.credentialId];
    if (existing == null || existing.verified.isEmpty) return false;
    entries[provider.credentialId] = (key: existing.key, verified: {});
    return true;
  });

  Future<void> _update(bool Function(Map<String, SavedSearchCredential>) change) async {
    final previous = _pending;
    final completed = Completer<void>();
    _pending = completed.future;
    try {
      if (previous != null) await previous;
      final entries = await _read();
      if (!change(entries)) return;
      if (entries.isEmpty) {
        await storage.delete(key: storageKey);
        if (await storage.read(key: storageKey) != null) throw WebSearchFailure.storage;
        return;
      }
      final encoded = jsonEncode({
        'version': 1,
        'providers': {
          for (final entry in entries.entries)
            entry.key: {'key': entry.value.key, 'verified': entry.value.verified.map((provider) => provider.name).toList()},
        },
      });
      await storage.write(key: storageKey, value: encoded);
      if (await storage.read(key: storageKey) != encoded) throw WebSearchFailure.storage;
    } catch (_) {
      throw WebSearchFailure.storage;
    } finally {
      completed.complete();
    }
  }

  Future<Map<String, SavedSearchCredential>> _read() async {
    final raw = await storage.read(key: storageKey);
    if (raw == null) return {};
    if (raw.length > 65536) throw const FormatException('Invalid search credential storage');
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['version'] != 1 || decoded['providers'] is! Map) {
      throw const FormatException('Invalid search credential storage');
    }
    final providers = decoded['providers'] as Map;
    final entries = <String, SavedSearchCredential>{};
    for (final id in WebSearchProvider.values.map((provider) => provider.credentialId).where((id) => id.isNotEmpty).toSet()) {
      final value = providers[id];
      if (value == null) continue;
      if (value is! Map || value['key'] is! String || value['verified'] is! List) {
        throw const FormatException('Invalid search credential storage');
      }
      final key = (value['key'] as String).trim();
      if (key.isEmpty || key.length > 4096 || (value['verified'] as List).any((name) => name is! String)) {
        throw const FormatException('Invalid search credential storage');
      }
      entries[id] = (
        key: key,
        verified: {
          for (final provider in WebSearchProvider.values)
            if (provider.credentialId == id && (value['verified'] as List).contains(provider.name)) provider,
        },
      );
    }
    return entries;
  }
}
