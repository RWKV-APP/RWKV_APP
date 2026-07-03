import 'dart:async';
import 'dart:io';

import 'package:local_web_search/src/models/search_engine.dart';
import 'package:local_web_search/src/models/search_engine_availability.dart';

class SearchEngineReachabilityProbe {
  final Duration timeout;
  final String probeQuery;

  const SearchEngineReachabilityProbe({
    this.timeout = const Duration(seconds: 5),
    this.probeQuery = 'RWKV',
  });

  Future<SearchEngineAvailability> probe(SearchEngine engine) async {
    final stopwatch = Stopwatch()..start();
    final client = HttpClient();
    client.connectionTimeout = timeout;
    client.userAgent =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15';

    try {
      final uri = Uri.parse(engine.buildSearchUrl(probeQuery));
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      );
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');

      final response = await request.close().timeout(timeout);
      stopwatch.stop();
      client.close(force: true);

      final statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 500) {
        return SearchEngineAvailability.available(
          engine: engine,
          statusCode: statusCode,
          elapsed: stopwatch.elapsed,
        );
      }

      return SearchEngineAvailability.unavailable(
        engine: engine,
        statusCode: statusCode,
        error: 'HTTP $statusCode',
        elapsed: stopwatch.elapsed,
      );
    } on TimeoutException catch (error) {
      stopwatch.stop();
      client.close(force: true);
      return SearchEngineAvailability.unavailable(
        engine: engine,
        error: 'Timed out: $error',
        elapsed: stopwatch.elapsed,
      );
    } on SocketException catch (error) {
      stopwatch.stop();
      client.close(force: true);
      return SearchEngineAvailability.unavailable(
        engine: engine,
        error: error.message,
        elapsed: stopwatch.elapsed,
      );
    } on Object catch (error) {
      stopwatch.stop();
      client.close(force: true);
      return SearchEngineAvailability.unavailable(
        engine: engine,
        error: error.toString(),
        elapsed: stopwatch.elapsed,
      );
    }
  }
}
