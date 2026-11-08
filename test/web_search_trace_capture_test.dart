import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:zone/func/web_search_api.dart';
import 'package:zone/func/web_search_model_input.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/web_search_provider.dart';
import 'package:zone/model/web_search_trace.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stale searched reply cannot receive another flow model request', () {
    final message = Message(
      id: 72,
      content: 'finished',
      isMine: false,
      paused: false,
      reference: RefInfo.empty().copyWith(trace: WebSearchTrace.empty()),
    );
    final request = to_rwkv.ChatAsync(['unrelated'], enableReasoning: false, forceReasoning: false, addGenerationPrompt: true, modelID: 1);
    P.chat.receiveId.q = message.id;
    P.msg.pool.q = {message.id: message};
    P.app.demoType.q = .chat;
    P.chat.onWebSearchModelRequest(request);
    expect(P.msg.pool.q[message.id], same(message));
    P.msg.pool.q = {message.id: message.copyWith(changing: true)};
    P.app.demoType.q = .see;
    P.chat.onWebSearchModelRequest(request);
    expect(P.msg.pool.q[message.id]!.reference.trace!.modelInput, isEmpty);
    P.chat.receiveId.q = null;
    P.msg.pool.q = {};
    P.app.demoType.q = .chat;
  });
  test('capture freezes the complete final messages and actual flags, preserving engine defaults', () {
    final messages = ['earlier question', 'earlier answer', '  🐕  sources\nfinal question\n[style]'];
    final request = to_rwkv.ChatAsync(
      messages,
      enableReasoning: false,
      forceReasoning: false,
      addGenerationPrompt: true,
      modelID: 42,
      forceLang: 1,
    );
    final input = webSearchModelRequest(request)!;
    expect(input['messages'], messages);
    expect(input['requestId'], request.requestId);
    expect(input['enableReasoning'], false);
    expect(input['addGenerationPrompt'], true);
    expect(input['maxLength'], isNull);
    expect(input['forceLang'], 1);
    messages.add('later mutation');
    expect((input['messages'] as List).length, 3);
  });

  test('batch captures each message slot and distinct reasoning/language settings', () {
    final request = to_rwkv.ChatBatchAsync.withSlotConfigs(
      [
        const to_rwkv.ChatBatchSlotConfig(messages: ['first'], enableReasoning: true, forceReasoning: true, forceLang: 1),
        const to_rwkv.ChatBatchSlotConfig(messages: ['second  🐕'], forceLang: 0),
      ],
      modelID: 8,
      maxLength: 64,
    );
    final input = webSearchModelRequest(request)!;
    expect(input['batchSize'], 2);
    expect(input['maxLength'], 64);
    expect(input['messages'], [
      ['first'],
      ['second  🐕'],
    ]);
    final slots = input['slotConfigs'] as List;
    expect(slots[0]['forceReasoning'], true);
    expect(slots[1]['forceReasoning'], false);
    expect(slots[1]['forceLang'], 0);
  });

  test('subsequent requests and safe input survive conversation serialization without changing real requests', () {
    const secret = 'fixture-"secret';
    final messages = ['  🐕  $secret\n${Uri.encodeComponent(secret)}'];
    final request = to_rwkv.ChatAsync(messages, enableReasoning: true, forceReasoning: false, addGenerationPrompt: true, modelID: 1);
    WebSearchTrace trace = WebSearchTrace.empty().copyWith(request: 'POST https://example.com\n$secret', finalPrompt: messages.single);
    for (int index = 0; index < 2; index++) {
      trace = appendWebSearchModelRequest(
        trace: trace,
        request: webSearchModelRequest(request)!,
        redactions: [secret],
      );
    }
    final reference = RefInfo.empty().copyWith(enable: true, trace: trace);
    final saved = reference.serialize();
    expect(saved, isNot(contains(Uri.encodeComponent(secret))));
    expect(saved, isNot(contains(jsonEncode(secret).substring(1, jsonEncode(secret).length - 1))));
    final restored = RefInfo.deserialize(saved).trace!;
    final requests = restored.modelInput['requests'] as List;
    expect(requests.length, 2);
    expect(requests.first['messages'], ['  🐕  [REDACTED]\n[REDACTED]']);
    expect(requests.first.keys, isNot(contains('configuredMaxLength')));
    expect(requests.first.keys, isNot(contains('capturedAt')));
    expect(requests.first['maxLength'], isNull);
    expect(restored.modelInput.keys, ['requests']);
    expect(restored.request, contains('[REDACTED]'));
    expect(request.messages.single, contains(secret));
    expect(messages.single, contains(secret));
  });

  test('legacy traces keep absence of actual request capture and redaction preserves numeric options', () {
    final legacy = WebSearchTrace.fromJson({'query': 'dogs', 'finalPrompt': 'old prompt'});
    expect(legacy.modelInput, isEmpty);
    expect(legacy.request, isEmpty);
    final safe = redactWebSearchPayload({'value': 1, 'flag': true, 'message': '1'}, ['1']);
    expect(safe, {'value': 1, 'flag': true, 'message': '[REDACTED]'});
  });

  for (final provider in WebSearchProvider.values.where((value) => value != .browser)) {
    test('${provider.name} records the actual safe request even when the provider fails', () async {
      const key = 'fixture-private-key';
      String? captured;
      final client = MockClient((request) async {
        expect(captured, webSearchRequestDetails(request));
        expect(captured, startsWith('${request.method} ${request.url.origin}${request.url.path}'));
        if (provider != .serpapi) expect(captured!.split('\n').first, '${request.method} ${request.url}');
        expect(captured, isNot(contains(key)));
        expect(captured, isNot(contains('api_key=')));
        expect(captured, isNot(contains('Authorization')));
        expect(captured, isNot(contains('X-API-KEY')));
        if (provider == .anysearch) expect(captured, contains('"max_results":3,"format":"json"'));
        if (provider == .zhihuGlobal || provider == .zhihuSite) expect(captured!.toLowerCase(), contains('x-request-timestamp:'));
        return http.Response('sensitive remote error $key', 402);
      });
      await expectLater(
        searchWebApi(provider: provider, apiKey: key, query: '深圳有多少条狗', client: client, onRequest: (value) => captured = value),
        throwsA(WebSearchFailure.balance),
      );
      expect(captured, isNotNull);
    });
  }
}
