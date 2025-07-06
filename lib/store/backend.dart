part of 'p.dart';

const _port = 52345;

enum BackendState {
  starting,
  running,
  stopping,
  stopped,
}

class _Backend {
  late final port = qs(_port);
  late final state = qs(BackendState.stopped);
  late final server = qs<HttpServer?>(null);
}

/// Private methods
extension _$Backend on _Backend {
  FV _init() async {
    final isDesktop = P.app.isDesktop.q;
    if (!isDesktop) return;
    qq;
  }

  Future<shelf.Response> _echoRequest(shelf.Request request) async {
    qr;

    final headers = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, PATCH, DELETE',
      'Access-Control-Allow-Headers': 'X-Requested-With,content-type,Authorization',
    };

    if (request.method == 'OPTIONS') {
      return shelf.Response.ok(null, headers: headers);
    }

    final requestBody = await request.readAsString();
    qqr("requestBody: $requestBody");
    final body = jsonEncode({
      'message': 'Hello, world!',
    });
    return shelf.Response.ok(
      body,
      headers: headers,
      encoding: utf8,
    );
  }
}

/// Public methods
extension $Backend on _Backend {
  FV start() async {
    final isDesktop = P.app.isDesktop.q;
    if (!isDesktop) return;

    if (state.q == BackendState.running) {
      qqw("Backend is running");
      Alert.warning("Backend is running");
      return;
    }

    if (state.q == BackendState.starting) {
      qqw("Backend is already starting");
      Alert.warning("Backend is already starting");
      return;
    }

    if (state.q == BackendState.stopping) {
      qqw("Backend is stopping");
      Alert.warning("Backend is stopping");
      return;
    }

    qq;

    final port = this.port.q;

    final url = "http://localhost:$port";

    state.q = BackendState.starting;

    try {
      // final handler = shelf.Pipeline().addHandler(_echoRequest);
      server.q = await shelf_io.serve(_echoRequest, 'localhost', port);
      server.q?.autoCompress = true;
      state.q = BackendState.running;
      qqr("Backend started at $url");
      Alert.success("Backend started");
    } catch (e) {
      qqe(e);
      state.q = BackendState.stopped;
      Alert.error("Failed to start backend");
    }
  }

  FV stop() async {
    final isDesktop = P.app.isDesktop.q;
    if (!isDesktop) return;
    qq;
    if (server.q == null) {
      qqw("Backend is not running");
      Alert.warning("Backend is not running");
      return;
    }
    server.q!.close();
    server.q = null;
    state.q = BackendState.stopped;
    server.q = null;
    qqr("Backend stopped");
    Alert.success("Backend stopped");
  }
}
