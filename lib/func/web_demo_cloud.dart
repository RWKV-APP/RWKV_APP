import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:zone/func/albatross_protocol.dart';

const String webDemo7BEndpoint = 'https://api-7b.rwkvos.com/v1/chat/completions';
const String webDemo13BEndpoint = 'https://api-13b.rwkvos.com/v1/chat/completions';
const String webDemoCloudflareConfigName = 'web-demo-cloudflare.json';
const Duration _requestTimeout = Duration(seconds: 120);

bool isWebDemoCloudflareEndpoint(Uri uri) {
  return uri.toString() == webDemo7BEndpoint || uri.toString() == webDemo13BEndpoint;
}

Map<String, String> get bundledWebDemoCloudflareHeaders => _validatedCloudflareHeaders(const {
  'CF-Access-Client-Id': String.fromEnvironment('CF-Access-Client-Id'),
  'CF-Access-Client-Secret': String.fromEnvironment('CF-Access-Client-Secret'),
});

Map<String, String> _validatedCloudflareHeaders(Object? decoded) {
  if (decoded is! Map) return {};
  final headers = <String, String>{};
  for (final key in ['CF-Access-Client-Id', 'CF-Access-Client-Secret']) {
    final value = decoded[key];
    if (value is! String || value.trim().isEmpty || value.contains(RegExp(r'[\r\n]'))) return {};
    headers[key] = value.trim();
  }
  return headers;
}

Future<Map<String, String>> readWebDemoCloudflareHeaders(File file) async {
  if (!await file.exists()) return bundledWebDemoCloudflareHeaders;
  try {
    final headers = _validatedCloudflareHeaders(jsonDecode(await file.readAsString()));
    return headers.isNotEmpty ? headers : bundledWebDemoCloudflareHeaders;
  } on FormatException {
    return bundledWebDemoCloudflareHeaders;
  }
}

Future<void> generateWebDemoCloudBatch({
  required http.Client client,
  required Uri endpoint,
  required Map<String, String> headers,
  required String prompt,
  required int batchSize,
  required Map<String, Object?> decodeParams,
  required void Function(int index, String delta) onDelta,
}) async {
  if (!isWebDemoCloudflareEndpoint(endpoint)) throw ArgumentError('Unsupported Web Demo cloud endpoint');
  if (batchSize < 1 || batchSize > 30) throw ArgumentError('Invalid Web Demo preview count');
  final modelsRequest = http.Request('GET', endpoint.resolve('/v1/models'))
    ..followRedirects = false
    ..headers.addAll(headers);
  final modelsResponse = await client.send(modelsRequest).timeout(_requestTimeout);
  if (modelsResponse.statusCode != 200) throw StateError('Web Demo models: HTTP ${modelsResponse.statusCode}');
  final modelsBody = await modelsResponse.stream.bytesToString().timeout(_requestTimeout);
  final decoded = jsonDecode(modelsBody);
  final models = decoded is Map ? decoded['data'] : null;
  final firstModel = models is List && models.isNotEmpty ? models.first : null;
  final model = firstModel is Map ? firstModel['id'] : null;
  if (model is! String || model.trim().isEmpty) throw StateError('Web Demo service returned no model');

  await Future.wait(
    List.generate(batchSize, (index) async {
      final temperature = decodeParams['temperature'];
      final request = http.Request('POST', endpoint)
        ..followRedirects = false
        ..headers.addAll({...headers, 'Accept': 'text/event-stream', 'Content-Type': 'application/json'})
        ..body = jsonEncode({
          ...decodeParams,
          // The cloud services reject zero temperature; keep other sampler values unchanged.
          if (temperature is num && temperature <= 0) 'temperature': 0.01,
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'stream': true,
          'n': 1,
        });
      final response = await client.send(request).timeout(_requestTimeout);
      if (response.statusCode != 200) throw StateError('Web Demo preview ${index + 1}: HTTP ${response.statusCode}');
      final parser = AlbatrossSseParser();
      bool hasContent = false;
      bool finished = false;
      await for (final chunk in response.stream.transform(utf8.decoder).timeout(_requestTimeout)) {
        for (final event in parser.add(chunk)) {
          if (event.done) {
            if (!hasContent) throw StateError('Web Demo preview ${index + 1}: empty response');
            return;
          }
          for (final choice in event.choices) {
            if (choice.index != 0) continue;
            if (choice.content.isNotEmpty) {
              hasContent = true;
              onDelta(index, choice.content);
            }
            if (choice.finishReason != null) finished = true;
          }
        }
      }
      if (!hasContent || !finished) throw StateError('Web Demo preview ${index + 1}: incomplete response');
    }),
    eagerError: true,
  );
}
