part of 'p.dart';

/// Error actions
enum _EA {
  alert,

  /// jump to sign in page if token expired
  signOut,

  /// Print error in console
  console,
}

final _httpClient = http.Client();

Future<ResponseT?> Function<ResponseT extends http.BaseResponse>(
  Future<ResponseT> response, {
  required Uri uri,
  required Map<String, String> headers,
  required List<_EA> ea,
  Encoding? encoding,
})
_errorWrapper =
    <ResponseT extends http.BaseResponse>(
      Future<ResponseT> response, {
      required Uri uri,
      required Map<String, String> headers,
      required List<_EA> ea,
      Encoding? encoding,
    }) async {
      try {
        return await response;
      } catch (e) {
        qqe("$uri");
        qqe("$e");
        if (ea.contains(_EA.alert)) {
          Alert.error(S.current.network_error + (kDebugMode ? " $uri" : ""));
        }
        return null;
      }
    };

Uri _buildUri(
  String url, {
  Map<String, dynamic> query = const {},
  String? domain,
}) {
  if (url.startsWith("https://") || url.startsWith("http://")) {
    final uri = Uri.parse(url);
    final mergedQuery = {...uri.queryParameters, ...query.allString};
    return uri.replace(queryParameters: mergedQuery.isEmpty ? null : mergedQuery);
  }

  while (url.startsWith("/")) {
    url = url.substring(1);
  }

  final base = Uri.parse(domain ?? Config.domain);
  final mergedQuery = {...base.queryParameters, ...query.allString};
  final basePath = base.path.replaceFirst(RegExp(r"/$"), "");
  final nextPath = [basePath, url].where((segment) => segment.isNotEmpty).join("/");

  return base.replace(
    path: nextPath,
    queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
  );
}

// ignore: unused_element
Future<Object?> _post(
  String url, {
  Map<String, dynamic> query = const {},
  Map<String, dynamic> body = const {},
  ContentType contentType = ContentType.json,
  List<_EA>? ea = const [_EA.signOut, _EA.console],
  Duration timeout = Config.timeout,
  String? domain,
  bool requireSigned = false,
  String token = "",
}) async {
  if (requireSigned) {
    await 1.msLater;
    final signed = false;
    if (!signed) return null;
  }

  ea = ea ?? [];
  final uri = _buildUri(url, query: query, domain: domain);

  final headers = _buildHeaders();
  headers['Token'] = token;
  late final Object? findlBody;
  switch (contentType) {
    case ContentType.json:
      headers["Content-Type"] = "application/json; charset=utf-8";
      headers["Accept"] = "application/json; charset=utf-8";
      findlBody = jsonEncode(body.withoutNull);
    case ContentType.urlencoded:
      headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8";
      headers["Accept"] = "application/x-www-form-urlencoded; charset=utf-8";
      findlBody = body.withoutNull;
  }

  final res = await _errorWrapper(
    _httpClient.post(uri, headers: headers, body: findlBody).timeout(timeout),
    uri: uri,
    headers: headers,
    ea: ea,
  );

  if (res == null) return null;

  final resBody = _deal(res, ea: ea);
  return resBody;
}

// ignore: unused_element
Stream<String> _postStreaming(
  String url, {
  Map<String, dynamic> query = const {},
  Map<String, dynamic> body = const {},
  ContentType contentType = ContentType.json,
  List<_EA>? ea = const [_EA.signOut, _EA.console],
  Duration timeout = Config.timeout,
  String? domain,
  Map<String, String> headers = const {},
}) async* {
  ea = ea ?? [];
  final uri = _buildUri(url, query: query, domain: domain);

  final finalHeaders = {..._buildHeaders(), ...headers};
  switch (contentType) {
    case ContentType.json:
      finalHeaders["Content-Type"] = "application/json";
    case ContentType.urlencoded:
      finalHeaders["Content-Type"] = "application/x-www-form-urlencoded";
  }

  final request = http.Request('POST', uri);
  request.headers.addAll(finalHeaders);
  request.body = jsonEncode(body);

  final res = await _errorWrapper(
    _httpClient.send(request).timeout(timeout),
    uri: uri,
    headers: finalHeaders,
    ea: ea,
  );

  if (res == null) return;

  if (res.statusCode != 200) {
    return;
  }

  final stream = res.stream.transform(utf8.decoder).where((event) {
    return event.isNotEmpty;
  });

  yield* stream;
}

// ignore: unused_element
Future<Object?> _postMultipart(
  String url, {
  Map<String, dynamic> query = const {},
  Map<String, dynamic> body = const {},
  List<File> files = const [],
  List<_EA>? ea = const [_EA.signOut, _EA.console],
  Duration timeout = Config.timeout,
  String? domain,
}) async {
  ea = ea ?? [];
  final uri = _buildUri(url, query: query, domain: domain);
  final headers = _buildHeaders();
  final request = http.MultipartRequest("POST", uri);

  for (final entry in headers.entries) {
    request.headers[entry.key] = entry.value;
  }

  for (final entry in body.entries) {
    request.fields[entry.key] = entry.value.toString();
  }

  for (final f in files) {
    final file = await http.MultipartFile.fromPath("file", f.path);
    request.files.add(file);
  }

  final res = await _errorWrapper(
    request.send().timeout(timeout),
    uri: uri,
    headers: headers,
    ea: ea,
  );

  if (res == null) return null;
  final resBody = await _dealStream(res, ea: ea);
  return resBody;
}

// ignore: unused_element
Future<Object?> _put(
  String url, {
  Map<String, dynamic> body = const {},
  ContentType contentType = ContentType.json,
  List<_EA>? ea = const [_EA.signOut, _EA.console],
  Duration timeout = Config.timeout,
  String? domain,
}) async {
  ea = ea ?? [];
  try {
    final uri = _buildUri(url, domain: domain);
    final headers = _buildHeaders();
    late final Object? findlBody;
    switch (contentType) {
      case ContentType.json:
        headers["Content-Type"] = "application/json; charset=utf-8";
        headers["Accept"] = "application/json; charset=utf-8";
        findlBody = jsonEncode(body);
      case ContentType.urlencoded:
        headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8";
        headers["Accept"] = "application/x-www-form-urlencoded; charset=utf-8";
        findlBody = body;
    }

    final res = await _errorWrapper(
      _httpClient.put(uri, headers: headers, body: findlBody).timeout(timeout),
      uri: uri,
      headers: headers,
      ea: ea,
    );
    if (res == null) return null;
    return _deal(res, ea: ea);
  } catch (e) {
    if (ea.contains(_EA.console)) {
      qqe("$e");
      qqe(url);
      if (body.isNotEmpty) qqe("$body");
    }
    if (ea.contains(_EA.alert)) Alert.error("Network error");
  }
  return null;
}

// ignore: unused_element
Future<Object?> _get(
  String url, {
  Map<String, dynamic> query = const {},
  ContentType contentType = ContentType.json,
  List<_EA>? ea = const [_EA.signOut, _EA.console],
  Duration timeout = Config.timeout,
  String? domain,
}) async {
  ea = ea ?? [];
  try {
    final uri = _buildUri(url, query: query, domain: domain);
    final headers = _buildHeaders();
    switch (contentType) {
      case ContentType.json:
        headers["Content-Type"] = "application/json; charset=utf-8";
        headers["Accept"] = "application/json; charset=utf-8";
      case ContentType.urlencoded:
        headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8";
        headers["Accept"] = "application/x-www-form-urlencoded; charset=utf-8";
    }

    final res = await _errorWrapper(
      _httpClient.get(uri, headers: headers).timeout(timeout),
      uri: uri,
      headers: headers,
      ea: ea,
    );
    if (res == null) return null;
    final resBody = _deal(res, ea: ea);
    return resBody;
  } catch (e) {
    if (ea.contains(_EA.console)) {
      qqe("$e");
      qqe("GET");
      qqe("_get");
      qqe(url);
      if (query.isNotEmpty) qqe("$query");
    }
    if (ea.contains(_EA.alert)) Alert.error("Network error");
  }
  return null;
}

// ignore: unused_element
Future<Object?> _delete(
  String url, {
  Map<String, dynamic> query = const {},
  Map<String, dynamic> body = const {},
  ContentType contentType = ContentType.json,
  List<_EA>? ea = const [_EA.signOut, _EA.console],
  Duration timeout = Config.timeout,
  String? domain,
}) async {
  ea = ea ?? [];
  final uri = _buildUri(url, query: query, domain: domain);
  final headers = _buildHeaders();
  late final Object? findlBody;
  switch (contentType) {
    case ContentType.json:
      headers["Content-Type"] = "application/json; charset=utf-8";
      headers["Accept"] = "application/json; charset=utf-8";
      findlBody = jsonEncode(body);
    case ContentType.urlencoded:
      headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8";
      headers["Accept"] = "application/x-www-form-urlencoded; charset=utf-8";
      findlBody = body;
  }
  final res = await _errorWrapper(
    _httpClient.delete(uri, headers: headers, body: findlBody).timeout(timeout),
    uri: uri,
    headers: headers,
    ea: ea,
  );
  if (res == null) return null;
  final resBody = _deal(res, ea: ea);
  return resBody;
}

Map<String, String> _buildHeaders() {
  final header = <String, String>{};
  header["Application-Build-Number"] = P.app.buildNumber.q;
  header["Application-Version"] = P.app.version.q;
  header["Operating-System"] = Platform.operatingSystem;
  header["Operating-System-Version"] = Platform.operatingSystemVersion;
  header["x-api-key"] = Config.xApiKey;
  return header;
}

VoidCallback _networkingErrorAlert = () {
  qqe("Server Error");
};

dynamic _deal(
  http.Response res, {
  List<_EA>? ea = const [_EA.signOut, _EA.console],
}) {
  ea = ea ?? [];
  late final dynamic body;

  try {
    body = jsonDecode(res.body);
  } catch (e) {
    if (ea.contains(_EA.console)) {
      if (kDebugMode) {
        qqe("Can not decode json string");
        qqe(res.body);
        print("😡 ${"statusCode".codeToName}: ${res.contentLength}");
        print("😡 ${"statusCode".codeToName}: ${res.statusCode}");
        final request = res.request;
        if (request != null) {
          print("😡 ${"method".codeToName}: ${request.method}");
          print("😡 ${"path".codeToName}: ${request.url.path}");
          print("😡 ${"query".codeToName}: ${request.url.query}");
          print("😡 Headers: ${request.headers.map((k, v) => MapEntry(k, v.substring(30)))}");
        }
      }
      if (kDebugMode) if (res.body.isNotEmpty) print("😡 ${res.body}");
    }
    if (ea.contains(_EA.alert)) _networkingErrorAlert.call();
    throw Exception("Network error");
  }

  return _sharedDeal(res, body, ea: ea);
}

Future<dynamic> _dealStream(
  http.StreamedResponse res, {
  List<_EA>? ea = const [_EA.signOut, _EA.console],
}) async {
  ea = ea ?? [];
  late final dynamic body;
  // Listen to the response stream and collect the bytes
  final streamBody = <int>[];
  await for (var byte in res.stream) {
    streamBody.addAll(byte);
  }

  try {
    final utf8Body = utf8.decode(streamBody);
    body = jsonDecode(utf8Body);
  } catch (e) {
    if (ea.contains(_EA.console)) {
      if (kDebugMode) {
        print("😡 Can not decode json string");
        final request = res.request;
        if (request != null) {
          print("😡 Calling: ${request.method} ${request.url.path}");
          print("😡 Headers: ${request.headers.map((k, v) => MapEntry(k, v.substring(30)))}");
        }
      }
    }
    if (ea.contains(_EA.alert)) _networkingErrorAlert.call();
    return null;
  }

  return _sharedDeal(res, body, ea: ea);
}

dynamic _sharedDeal(
  http.BaseResponse res,
  dynamic body, {
  List<_EA>? ea = const [_EA.signOut, _EA.console],
}) {
  ea = ea ?? [];
  final statusCode = res.statusCode;
  // final codeString = body["code"].toString();
  // final code = int.tryParse(codeString);

  final logError = ea.contains(_EA.console);
  final alert = ea.contains(_EA.alert);

  if (statusCode != 200) {
    if (logError) {
      qqe("Http code is not 200");
      qqe("Calling: ${res.request?.method} ${res.request?.url.path}");
      qqe("$body");
    }
    if (alert) Alert.error(S.current.server_error);
    return null;
  }

  return body;
}
