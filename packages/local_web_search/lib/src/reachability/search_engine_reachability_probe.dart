import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_engine_availability.dart';

typedef SearchEngineProbeRequest =
    Future<SearchEngineProbeResponse> Function({
      required Uri uri,
      required Duration timeout,
    });

class SearchEngineProbeResponse {
  final int statusCode;
  final Uri finalUri;
  final String body;

  const SearchEngineProbeResponse({
    required this.statusCode,
    required this.finalUri,
    required this.body,
  });
}

class SearchEngineReachabilityProbe {
  static const int _maxResponseBytes = 128 * 1024;
  static const List<String> _verificationUriMarkers = <String>[
    '/sorry/',
    '/showcaptcha',
    '/captcha-block',
    '/captcha/',
    'wappass.baidu.com/static/captcha',
  ];
  static const List<String> _verificationBodyMarkers = <String>[
    'our systems have detected unusual traffic',
    'verify you are human',
    'verification required',
    'id="captcha-form"',
    'class="g-recaptcha"',
    '请输入验证码',
    '百度安全验证',
    '人机验证',
  ];

  final Duration timeout;
  final String probeQuery;
  final int attempts;
  final SearchEngineProbeRequest? request;

  const SearchEngineReachabilityProbe({
    this.timeout = const Duration(seconds: 5),
    this.probeQuery = 'RWKV',
    this.attempts = 2,
    this.request,
  });

  Future<SearchEngineAvailability> probe(SearchEngine engine) async {
    final stopwatch = Stopwatch()..start();
    SearchEngineAvailability? lastFailure;
    final attemptCount = attempts < 1 ? 1 : attempts;

    for (int attempt = 0; attempt < attemptCount; attempt += 1) {
      try {
        final uri = Uri.parse(engine.buildSearchUrl(probeQuery));
        final response = await (request ?? _requestPage)(
          uri: uri,
          timeout: timeout,
        );
        final availability = evaluate(
          engine: engine,
          response: response,
          elapsed: stopwatch.elapsed,
        );
        if (availability.isAvailable) {
          stopwatch.stop();
          return availability;
        }
        lastFailure = availability;
        if (!_isRetryableStatus(response.statusCode)) {
          stopwatch.stop();
          return availability;
        }
      } on TimeoutException catch (error) {
        lastFailure = SearchEngineAvailability.unavailable(
          engine: engine,
          error: 'Timed out: $error',
          elapsed: stopwatch.elapsed,
        );
      } on SocketException catch (error) {
        lastFailure = SearchEngineAvailability.unavailable(
          engine: engine,
          error: error.message,
          elapsed: stopwatch.elapsed,
        );
      } on Object catch (error) {
        lastFailure = SearchEngineAvailability.unavailable(
          engine: engine,
          error: error.toString(),
          elapsed: stopwatch.elapsed,
        );
      }
    }

    stopwatch.stop();
    return lastFailure ??
        SearchEngineAvailability.unavailable(
          engine: engine,
          error: 'No probe response was received.',
          elapsed: stopwatch.elapsed,
        );
  }

  static SearchEngineAvailability evaluate({
    required SearchEngine engine,
    required SearchEngineProbeResponse response,
    required Duration elapsed,
  }) {
    final statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 400) {
      return SearchEngineAvailability.unavailable(
        engine: engine,
        statusCode: statusCode,
        error: 'HTTP $statusCode',
        elapsed: elapsed,
      );
    }

    if (!_hostMatchesEngine(response.finalUri.host, engine.host)) {
      return SearchEngineAvailability.unavailable(
        engine: engine,
        statusCode: statusCode,
        error: 'Redirected to ${response.finalUri.host}.',
        elapsed: elapsed,
      );
    }

    if (_looksLikeHumanVerification(response)) {
      return SearchEngineAvailability.unavailable(
        engine: engine,
        statusCode: statusCode,
        error: 'Human verification page detected.',
        elapsed: elapsed,
      );
    }

    return SearchEngineAvailability.available(
      engine: engine,
      statusCode: statusCode,
      elapsed: elapsed,
    );
  }

  static Future<SearchEngineProbeResponse> _requestPage({
    required Uri uri,
    required Duration timeout,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    client.userAgent =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36';

    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      );
      request.headers.set(
        HttpHeaders.acceptLanguageHeader,
        'zh-CN,zh;q=0.9,en;q=0.8',
      );

      final response = await request.close().timeout(timeout);
      final finalUri = _resolveRedirects(uri, response.redirects);
      final body = await _readResponseBody(response).timeout(timeout);
      return SearchEngineProbeResponse(
        statusCode: response.statusCode,
        finalUri: finalUri,
        body: body,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<String> _readResponseBody(HttpClientResponse response) async {
    final bytes = BytesBuilder(copy: false);
    int byteCount = 0;
    await for (final chunk in response) {
      final remaining = _maxResponseBytes - byteCount;
      if (remaining <= 0) break;
      if (chunk.length <= remaining) {
        bytes.add(chunk);
        byteCount += chunk.length;
        continue;
      }
      bytes.add(chunk.sublist(0, remaining));
      byteCount += remaining;
      break;
    }
    return utf8.decode(bytes.takeBytes(), allowMalformed: true);
  }

  static Uri _resolveRedirects(Uri initialUri, List<RedirectInfo> redirects) {
    Uri resolved = initialUri;
    for (final redirect in redirects) {
      resolved = resolved.resolveUri(redirect.location);
    }
    return resolved;
  }

  static bool _hostMatchesEngine(String actualHost, String expectedHost) {
    final normalizedActual = actualHost.toLowerCase();
    final labels = expectedHost.toLowerCase().split('.');
    final suffix = labels.length > 2
        ? labels.sublist(labels.length - 2).join('.')
        : expectedHost.toLowerCase();
    return normalizedActual == suffix || normalizedActual.endsWith('.$suffix');
  }

  static bool _looksLikeHumanVerification(SearchEngineProbeResponse response) {
    final uriText = response.finalUri.toString().toLowerCase();
    for (final marker in _verificationUriMarkers) {
      if (uriText.contains(marker)) return true;
    }

    final bodyText = response.body.toLowerCase();
    for (final marker in _verificationBodyMarkers) {
      if (bodyText.contains(marker)) return true;
    }
    return false;
  }

  static bool _isRetryableStatus(int statusCode) {
    return statusCode >= 500;
  }
}
