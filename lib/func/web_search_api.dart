import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zone/func/web_search_report.dart';
import 'package:zone/model/reference.dart';
import 'package:zone/model/web_search_provider.dart';

enum WebSearchFailure implements Exception {
  missingKey,
  invalidQuery,
  unauthorized,
  balance,
  quota,
  rateLimit,
  timeout,
  unavailable,
  invalidResponse,
}

/// Search credentials only go to the selected provider's fixed HTTPS endpoint.
Future<List<Reference>> searchWebApi({
  required WebSearchProvider provider,
  required String apiKey,
  required String query,
  http.Client? client,
  Duration timeout = const Duration(seconds: 20),
  void Function(String request)? onRequest,
  void Function(int statusCode, String body)? onResponse,
}) async {
  if (provider == WebSearchProvider.browser) throw WebSearchFailure.invalidQuery;
  if (provider.requiresApiKey && apiKey.trim().isEmpty) throw WebSearchFailure.missingKey;
  final trimmedQuery = query.trim();
  final length = trimmedQuery.runes.length;
  final isDeepSeek = provider == WebSearchProvider.deepseek;
  final isZhihu = provider == WebSearchProvider.zhihuGlobal || provider == WebSearchProvider.zhihuSite;
  if (length < (isZhihu ? 2 : 1) || length > (isDeepSeek ? 128 : 100)) {
    throw WebSearchFailure.invalidQuery;
  }
  final key = provider.credentialId.isEmpty ? '' : apiKey.trim();
  final request = _webSearchRequest(provider, key, trimmedQuery);
  onRequest?.call(webSearchRequestDetails(request));
  final transport = client ?? http.Client();
  try {
    return await _readWebSearchResponse(transport, request, provider, key, onResponse).timeout(timeout);
  } on WebSearchFailure {
    rethrow;
  } on TimeoutException {
    throw WebSearchFailure.timeout;
  } catch (_) {
    // Provider bodies and transport errors can echo credentials; keep them out of logs and messages.
    throw WebSearchFailure.unavailable;
  } finally {
    if (client == null) transport.close();
  }
}

String webSearchRequestDetails(http.Request request) {
  final parameters = <String, String>{
    for (final entry in request.url.queryParameters.entries)
      if (!['api_key', 'apikey', 'key', 'token', 'access_token'].contains(entry.key.toLowerCase())) entry.key: entry.value,
  };
  final url = parameters.length == request.url.queryParameters.length
      ? request.url
      : request.url.replace(queryParameters: parameters.isEmpty ? null : parameters, query: parameters.isEmpty ? '' : null);
  return [
    '${request.method} $url',
    for (final entry in request.headers.entries)
      if (['content-type', 'x-request-timestamp'].contains(entry.key.toLowerCase())) '${entry.key}: ${entry.value}',
    if (request.body.isNotEmpty) '\n${request.body}',
  ].join('\n');
}

http.Request _webSearchRequest(WebSearchProvider provider, String key, String query) {
  final Map<String, String> parameters = switch (provider) {
    .zhihuGlobal || .zhihuSite => {'Query': query, 'Count': '3'},
    .brave => {'q': query, 'count': '3'},
    .serpapi => {'engine': 'google', 'q': query, 'api_key': key},
    .searchapi => {'engine': 'google', 'q': query},
    _ => {},
  };
  final Map<String, dynamic>? body = switch (provider) {
    .deepseek => {'query': query, 'count': 3, 'need_content': false},
    .anysearch => {'query': query, 'max_results': 3, 'format': 'json'},
    .tavily => {'query': query, 'max_results': 3, 'search_depth': 'basic', 'include_answer': false, 'include_raw_content': false},
    .exa => {
      'query': query,
      'numResults': 3,
      'type': 'auto',
      'contents': {'highlights': true},
    },
    .serper => {'q': query},
    .firecrawl => {
      'query': query,
      'limit': 3,
      'sources': ['web'],
      'highlights': false,
    },
    _ => null,
  };
  final uri = parameters.isEmpty ? provider.endpoint : provider.endpoint.replace(queryParameters: parameters);
  final request = http.Request(body == null ? 'GET' : 'POST', uri)..followRedirects = false;
  if (key.isNotEmpty && provider != .serpapi) {
    final header = switch (provider) {
      .brave => 'X-Subscription-Token',
      .exa || .serper => 'X-API-KEY',
      _ => 'Authorization',
    };
    request.headers[header] = header == 'Authorization' ? 'Bearer $key' : key;
  }
  if (provider == .zhihuGlobal || provider == .zhihuSite) {
    request.headers['X-Request-Timestamp'] = '${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
  }
  if (body == null) return request;
  request.headers['Content-Type'] = 'application/json';
  request.body = jsonEncode(body);
  return request;
}

Future<List<Reference>> _readWebSearchResponse(
  http.Client client,
  http.Request request,
  WebSearchProvider provider,
  String apiKey,
  void Function(int statusCode, String body)? onResponse,
) async {
  final response = await client.send(request);
  final failure = switch (response.statusCode) {
    401 || 403 => WebSearchFailure.unauthorized,
    402 => WebSearchFailure.balance,
    429 => WebSearchFailure.rateLimit,
    200 => null,
    _ => WebSearchFailure.unavailable,
  };
  final bytes = <int>[];
  await for (final chunk in response.stream) {
    if (bytes.length + chunk.length > 1024 * 1024) throw failure ?? WebSearchFailure.invalidResponse;
    bytes.addAll(chunk);
  }
  try {
    final text = utf8.decode(bytes);
    onResponse?.call(response.statusCode, _safeWebSearchResponse(text, apiKey));
    if (failure != null) throw failure;
    if (apiKey.isNotEmpty && (text.contains(apiKey) || text.contains(Uri.encodeComponent(apiKey)))) throw WebSearchFailure.invalidResponse;
    final payload = jsonDecode(text);
    if (payload is! Map<String, dynamic>) throw WebSearchFailure.invalidResponse;
    return parseWebSearchReferences(provider, payload);
  } on WebSearchFailure {
    rethrow;
  } catch (_) {
    throw failure ?? WebSearchFailure.invalidResponse;
  }
}

String _safeWebSearchResponse(String text, String apiKey) {
  final secrets = <String>[if (apiKey.isNotEmpty) apiKey];
  void collect(dynamic value) {
    if (value is List) {
      for (final item in value) {
        collect(item);
      }
      return;
    }
    if (value is! Map) return;
    for (final entry in value.entries) {
      final name = entry.key.toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (const {'apikey', 'accesstoken', 'refreshtoken', 'token', 'secret', 'accesssecret', 'authorization', 'password'}.contains(name)) {
        if (entry.value is String && (entry.value as String).isNotEmpty) secrets.add(entry.value as String);
      }
      collect(entry.value);
    }
  }

  try {
    collect(jsonDecode(text));
  } catch (_) {
    // Invalid JSON is still useful as a response; configured credentials stay redacted.
  }
  final safe = redactWebSearchReport(text, secrets);
  return safe.replaceAllMapped(
    RegExp(
      r'\b(api[_-]?key|access[_-]?(?:token|secret)|refresh[_-]?token|token|secret|authorization|password)\s*[=:]\s*([^\s&]+)',
      caseSensitive: false,
    ),
    (match) => '${match[1]}=[REDACTED]',
  );
}

List<Reference> parseWebSearchReferences(WebSearchProvider provider, Map<String, dynamic> payload) {
  final dynamic items;
  if (payload['error'] != null) throw WebSearchFailure.unavailable;
  switch (provider) {
    case .deepseek || .tavily || .exa:
      items = payload['results'];
    case .brave:
      final web = payload['web'];
      items = web is Map ? web['results'] : null;
    case .serper:
      items = payload['organic'];
    case .serpapi || .searchapi:
      items = payload['organic_results'];
    case .firecrawl:
      if (payload['success'] != true) throw WebSearchFailure.unavailable;
      final data = payload['data'];
      items = data is Map ? data['web'] : null;
    case .zhihuGlobal || .zhihuSite || .anysearch:
      final code = payload['Code'] ?? payload['code'];
      if (provider == .zhihuGlobal || provider == .zhihuSite) {
        if (code == 20001) throw WebSearchFailure.unauthorized;
        if (code == 30001) throw WebSearchFailure.rateLimit;
      }
      if (code != 0) throw WebSearchFailure.unavailable;
      final data = payload['Data'] ?? payload['data'];
      if (data is! Map) throw WebSearchFailure.invalidResponse;
      items = provider == .anysearch ? data['results'] : data['Items'] ?? data['items'];
    case .browser:
      throw WebSearchFailure.invalidQuery;
  }
  if (items is! List) throw WebSearchFailure.invalidResponse;
  final refs = <Reference>[];
  final seen = <String>{};
  for (final item in items.take(20)) {
    if (item is! Map) throw WebSearchFailure.invalidResponse;
    final title = item['Title'] ?? item['title'];
    final url = item['Url'] ?? item['url'] ?? item['link'];
    final summary = _webSearchExcerpt(provider, item);
    if (title is! String || url is! String || summary is! String) throw WebSearchFailure.invalidResponse;
    final parsed = Uri.tryParse(url);
    if (parsed == null || !['https', 'http'].contains(parsed.scheme) || parsed.host.isEmpty || parsed.userInfo.isNotEmpty) {
      throw WebSearchFailure.invalidResponse;
    }
    if (!seen.add(parsed.toString())) continue;
    final plainTitle = title.replaceAll(RegExp(r'</?em>', caseSensitive: false), '').trim();
    final plainSummary = summary.replaceAll(RegExp(r'</?em>', caseSensitive: false), '').trim();
    refs.add(
      Reference(
        url: parsed.toString(),
        title: String.fromCharCodes(plainTitle.runes.take(300)),
        summary: String.fromCharCodes(plainSummary.runes.take(2000)),
        publishedAt: _webSearchPublishedAt(item),
      ),
    );
    if (refs.length == 3) break;
  }
  return refs;
}

dynamic _webSearchExcerpt(WebSearchProvider provider, Map<dynamic, dynamic> item) {
  if (provider == .deepseek) {
    final summary = item['summary'];
    if (summary == null || (summary is String && summary.trim().isEmpty)) return item['snippet'] ?? '';
    return summary;
  }
  if (provider == .exa && item['highlights'] is List) {
    final highlights = item['highlights'] as List;
    if (highlights.any((value) => value is! String)) throw WebSearchFailure.invalidResponse;
    return highlights.join('\n');
  }
  return switch (provider) {
    .tavily => item['content'] ?? '',
    .brave || .firecrawl => item['description'] ?? '',
    .anysearch || .serper || .serpapi || .searchapi => item['snippet'] ?? '',
    .zhihuGlobal || .zhihuSite => item['ContentText'] ?? item['content_text'] ?? '',
    _ => '',
  };
}

String _webSearchPublishedAt(Map<dynamic, dynamic> item) {
  final date = item['date'] ?? item['publishedDate'] ?? item['published_date'];
  if (date is! String || date.length > 100 || DateTime.tryParse(date.trim()) == null) return '';
  return date.trim();
}

String webSearchApiContext(List<Reference> refs, {bool chinese = false}) {
  return [
    for (final ref in refs)
      [
        if (ref.title.isNotEmpty) ref.title,
        if (ref.publishedAt.isNotEmpty) '${chinese ? '发布日期：' : 'Published: '}${ref.publishedAt}',
        if (ref.summary.isNotEmpty) ref.summary,
      ].join('\n'),
  ].where((block) => block.isNotEmpty).join('\n\n');
}
