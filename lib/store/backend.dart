part of 'p.dart';

const _port = 52345;

const _headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, PATCH, DELETE',
  'Access-Control-Allow-Headers': 'X-Requested-With,content-type,Authorization',
};

enum BackendState { starting, running, stopping, stopped }

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
    if (request.method == 'OPTIONS') {
      return shelf.Response.ok(null, headers: _headers);
    }

    final requestBody = await request.readAsString();
    final json = jsonDecode(requestBody);
    final text = json['text'];
    final logic = json['logic'];

    try {
      switch (logic) {
        case 'translate':
          // TODO: 加入翻译队列
          // TODO: 队列元素的选择逻辑应该是: 先选择屏幕中间的元素
          await HF.wait(HF.randomInt(min: 100, max: 500));
          final responseBody = jsonEncode({
            'text': text,
            'translation': '✅',
            'timestamp': HF.microseconds,
          });
          return shelf.Response.ok(responseBody, headers: _headers, encoding: utf8);
        case 'loop':
          final translation = P.translator._getOnTimeTranslation(text);
          final body = jsonEncode({
            'text': text,
            'translation': translation,
            'timestamp': HF.microseconds,
          });
          return shelf.Response.ok(body, headers: _headers, encoding: utf8);
        default:
          return shelf.Response.badRequest(body: 'Invalid logic: $logic', headers: _headers, encoding: utf8);
      }
    } catch (e) {
      return shelf.Response.internalServerError(body: 'logic failed: $logic', headers: _headers, encoding: utf8);
    }
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
