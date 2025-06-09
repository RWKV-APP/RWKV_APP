part of 'p.dart';

enum ContentType {
  /// application/json
  json,

  /// application/x-www-form-urlencoded
  urlencoded,
}

/// Error actions
enum _EA {
  alert,

  /// jump to sign in page if token expired
  signOut,

  /// Print error in console
  console,
}

final _httpClient = http.Client();

Future<T?> Function<T extends http.BaseResponse>(
  Future<T> response, {
  required Uri uri,
  required Map<String, String> headers,
  required List<_EA> ea,
  Encoding? encoding,
})
_errorWrapper =
    <T extends http.BaseResponse>(
      Future<T> response, {
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

// ignore: unused_element
Future<Object?> _post(
  String url, {
  Map<String, dynamic> query = const {},
  Map<String, dynamic> body = const {},
  ContentType contentType = ContentType.json,
  List<_EA>? ea = const [_EA.signOut, _EA.console],
  Duration timeout = Config.timeout,
  bool requireSigned = false,
}) async {
  if (requireSigned) {
    await HF.wait(1);
    final signed = false;
    if (!signed) return null;
  }

  ea = ea ?? [];

  while (url.startsWith("/")) {
    url = url.substring(1);
  }
  final r = Config.domain.split("://");
  final uri = Uri(
    scheme: r[0],
    host: r[1],
    path: url,
    queryParameters: query.isNotEmpty ? query.allString : null,
  );

  final headers = _buildHeaders();
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
  Map<String, String> headers = const {},
}) async* {
  ea = ea ?? [];

  while (url.startsWith("/")) {
    url = url.substring(1);
  }
  final r = Config.domain.split("://");
  final uri = Uri(
    scheme: r[0],
    host: r[1],
    path: url,
    queryParameters: query.isNotEmpty ? query.allString : null,
  );

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

  final Stream<String> stream = res.stream.transform(utf8.decoder).where((event) {
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
}) async {
  ea = ea ?? [];
  final r = Config.domain.split("://");
  final uri = Uri(
    scheme: r[0],
    host: r[1],
    path: url,
    queryParameters: query.isNotEmpty ? query.allString : null,
  );
  final headers = _buildHeaders();
  final request = http.MultipartRequest("POST", uri);

  headers.forEach((k, v) {
    request.headers[k] = v;
  });

  body.forEach((k, v) {
    request.fields[k] = v.toString();
  });

  files.forEach((f) async {
    final http.MultipartFile file = await http.MultipartFile.fromPath("file", f.path);
    request.files.add(file);
  });

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
}) async {
  ea = ea ?? [];
  try {
    final uri = Uri.parse(Config.domain + url);
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
}) async {
  ea = ea ?? [];
  try {
    while (url.startsWith("/")) {
      url = url.substring(1);
    }
    final r = Config.domain.split("://");
    Uri uri = Uri(
      scheme: r[0],
      host: r[1],
      path: url,
      queryParameters: query.isNotEmpty ? query.allString : null,
    );
    if (url.startsWith("http://") || url.startsWith("https://")) {
      uri = Uri.parse(url);
    }
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
}) async {
  ea = ea ?? [];
  final r = Config.domain.split("://");
  final uri = Uri(
    scheme: r[0],
    host: r[1],
    path: url,
    queryParameters: query.isNotEmpty ? query.allString : null,
  );
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
  final Map<String, String> header = {};
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
        final body = jsonDecode(res.body);
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

  final signout = ea.contains(_EA.signOut);

  return body;

  // if (code == 0) {
  //   return body;
  // }

  // switch (code) {
  //   case 100020:
  //     if (logError) qqe("Token expired");
  //   case 100021:
  //     if (logError) qqe("Token expired");
  //   default:
  //     if (alert) {
  //       final msg = body["msg"];
  //       if (msg is String) Alert.error(msg);
  //     }
  //     if (logError) qqe("Code is not 0");
  //     if (logError) qqe("Calling: ${res.request?.method} ${res.request?.url.path}");
  //     if (logError) qqe("$body");
  // }

  // return null;
}
