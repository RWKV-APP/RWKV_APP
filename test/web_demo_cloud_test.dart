import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zone/func/web_demo_cloud.dart';

void main() {
  const headers = {'CF-Access-Client-Id': 'test-id', 'CF-Access-Client-Secret': 'test-secret'};

  test('discovers model and routes independent choice-zero streams to both previews', () async {
    int requests = 0;
    int generations = 0;
    final outputs = ['', ''];
    final client = MockClient((request) async {
      requests++;
      expect(request.followRedirects, isFalse);
      expect(request.headers['CF-Access-Client-Secret'], 'test-secret');
      if (request.method == 'GET') {
        expect(request.url.path, '/v1/models');
        return http.Response('{"data":[{"id":"live-model"}]}', 200);
      }
      final body = jsonDecode(request.body);
      expect(body['model'], 'live-model');
      expect(body['n'], 1);
      expect(body['temperature'], 0.01);
      expect(body['messages'][0]['content'], 'make HTML');
      final slot = generations++;
      await Future<void>.delayed(Duration(milliseconds: slot == 0 ? 20 : 1));
      return http.Response(
        'data: {"choices":[{"index":0,"delta":{"content":"HTML-$slot"}}]}\n\n'
        'data: [DONE]\n\n',
        200,
      );
    });
    addTearDown(client.close);
    await generateWebDemoCloudBatch(
      client: client,
      endpoint: Uri.parse(webDemo13BEndpoint),
      headers: headers,
      prompt: 'make HTML',
      batchSize: 2,
      decodeParams: {'temperature': 0, 'max_tokens': 64},
      onDelta: (index, delta) => outputs[index] += delta,
    );
    expect(requests, 3);
    expect(outputs, ['HTML-0', 'HTML-1']);
  });

  test('rejects other origins before sending credentials and rejects failed or truncated responses', () async {
    int requests = 0;
    int status = 200;
    final client = MockClient((request) async {
      requests++;
      if (request.method == 'GET') return http.Response('{"data":[{"id":"live-model"}]}', 200);
      return http.Response('data: {"choices":[{"delta":{"content":"partial"}}]}\n\n', status);
    });
    addTearDown(client.close);
    Future<void> run(String url) => generateWebDemoCloudBatch(
      client: client,
      endpoint: Uri.parse(url),
      headers: headers,
      prompt: 'make HTML',
      batchSize: 1,
      decodeParams: {},
      onDelta: (_, _) {},
    );
    await expectLater(run('https://api-7b.rwkvos.com.attacker.invalid/v1/chat/completions'), throwsArgumentError);
    await expectLater(run(webDemo7BEndpoint.replaceFirst('https:', 'http:')), throwsArgumentError);
    expect(requests, 0);
    await expectLater(run(webDemo7BEndpoint), throwsStateError);
    status = 403;
    await expectLater(run(webDemo7BEndpoint), throwsStateError);
    status = 302;
    await expectLater(run(webDemo7BEndpoint), throwsStateError);
  });

  test('uses bundled configuration without local setup and permits complete local overrides', () async {
    final directory = await Directory.systemTemp.createTemp('web-demo-auth-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/$webDemoCloudflareConfigName');
    final bundled = bundledWebDemoCloudflareHeaders;
    const configured = bool.hasEnvironment('CF-Access-Client-Id') && bool.hasEnvironment('CF-Access-Client-Secret');
    expect(bundled.isNotEmpty, configured);
    expect(await readWebDemoCloudflareHeaders(file), bundled);
    await file.writeAsString(jsonEncode({...headers, 'unrelated': 'ignored'}));
    expect(await readWebDemoCloudflareHeaders(file), headers);
    await file.writeAsString(jsonEncode({'CF-Access-Client-Id': 'id-only'}));
    expect(await readWebDemoCloudflareHeaders(file), bundled);
    await file.writeAsString('{invalid');
    expect(await readWebDemoCloudflareHeaders(file), bundled);
    await file.writeAsString(jsonEncode({...headers, 'CF-Access-Client-Secret': 'invalid\nheader'}));
    expect(await readWebDemoCloudflareHeaders(file), bundled);
  });
}
