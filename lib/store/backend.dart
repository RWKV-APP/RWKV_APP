part of 'p.dart';

const _httpPort = 52345;
const _websocketPort = 52346;

const _headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, PATCH, DELETE',
  'Access-Control-Allow-Headers': 'X-Requested-With,content-type,Authorization',
};

enum BackendState {
  starting,
  running,
  stopping,
  stopped;

  String get name => switch (this) {
    starting => "启动中",
    running => "运行中",
    stopping => "停止中",
    stopped => "已停止",
  };
}

class _Backend {
  late final httpPort = qs(_httpPort);
  late final httpServer = qs<HttpServer?>(null);
  late final httpState = qs(BackendState.stopped);

  late final websocketPort = qs(_websocketPort);
  late final websocketServer = qs<HttpServer?>(null);
  late final websocketState = qs(BackendState.stopped);
  late final websocketReceivedCount = qs(0);
  late final websocketSentCount = qs(0);

  late final runningTasks = qs<Set<String>>({});
  late final taskHandledCount = qs(0);
  late final taskReceivedCount = qs(0);

  late final _webSocketHandler = shelf_ws.webSocketHandler((ws_channel.WebSocketChannel channel, _) {
    channel.stream.listen(
      (message) => _onData(channel, message),
      onDone: () => _onDone(channel),
      onError: (error, stackTrace) => _onError(channel, error, stackTrace),
    );
  });
}

/// Private methods
extension _$Backend on _Backend {
  FV _init() async {
    final isDesktop = P.app.isDesktop.q;
    if (!isDesktop) return;
    qq;
  }

  Future<shelf.Response> _onHttpRequest(shelf.Request request) async {
    if (request.method == 'OPTIONS') {
      return shelf.Response.ok(null, headers: _headers);
    }

    taskReceivedCount.q++;

    final requestBody = await request.readAsString();
    final json = jsonDecode(requestBody);
    final source = json['source'];
    final logic = json['logic'];
    final url = json['url'];

    try {
      switch (logic) {
        case 'translate':
          return shelf.Response.badRequest(body: 'Not implemented: $logic', headers: _headers, encoding: utf8);
        case 'loop':
          runningTasks.q = {...runningTasks.q, source};
          final translation = P.translator._getOnTimeTranslation(source, url: url);
          final body = jsonEncode({
            'source': source,
            'translation': translation.replaceAll(_endString, ""),
            'timestamp': HF.microseconds,
          });
          runningTasks.q = runningTasks.q.where((e) => e != source).toSet();
          taskHandledCount.q++;
          return shelf.Response.ok(body, headers: _headers, encoding: utf8);
        default:
          return shelf.Response.badRequest(body: 'Invalid logic: $logic', headers: _headers, encoding: utf8);
      }
    } catch (e) {
      qqe(e);
      return shelf.Response.internalServerError(body: 'logic failed: $logic', headers: _headers, encoding: utf8);
    }
  }

  void _onData(ws_channel.WebSocketChannel channel, dynamic data) async {
    final json = jsonDecode(data);
    final source = json['source'];
    final logic = json['logic'];
    final url = json['url'];

    websocketReceivedCount.q++;

    try {
      switch (logic) {
        case 'translate':
          // TODO: 加入翻译队列
          // TODO: 队列元素的选择逻辑应该是: 先选择屏幕中间的元素
          runningTasks.q = {...runningTasks.q, source};
          final translation = await P.translator._getFullTranslation(json);
          final responseBody = jsonEncode({
            'source': source,
            'translation': translation.replaceAll(_endString, ""),
            'url': url,
            'timestamp': HF.microseconds,
          });
          runningTasks.q = runningTasks.q.where((e) => e != source).toSet();
          taskHandledCount.q++;
          channel.sink.add(responseBody);
          websocketSentCount.q++;
        case 'loop':
          runningTasks.q = {...runningTasks.q, source};
          final translation = P.translator._getOnTimeTranslation(source);
          final body = jsonEncode({
            'source': source,
            'translation': translation.replaceAll(_endString, ""),
            'url': url,
            'timestamp': HF.microseconds,
          });
          runningTasks.q = runningTasks.q.where((e) => e != source).toSet();
          taskHandledCount.q++;
          channel.sink.add(body);
          websocketSentCount.q++;
        case "tab_actived":
          final tab = HF.json(json["tab"]);
          final id = tab["id"];
          final url = tab["url"];
          final title = tab["title"];
          final windowId = tab["windowId"];
          final lastAccessed = tab["lastAccessed"] ?? -1.0;
          if (id == null && url == null && title == null && windowId == null && windowId == null && lastAccessed == null) return;
          P.translator.activeBrowserTab.q = BrowserTab(
            id: id,
            url: url,
            title: title,
            windowId: windowId ?? -1,
            lastAccessed: (lastAccessed ?? -1.0).toDouble(),
          );
        case "tab_size_change":
          final tab = HF.json(json["tab"]);
          final id = tab["id"];
          final innerHeight = tab["innerHeight"];
          final outerHeight = tab["outerHeight"];
          final innerWidth = tab["innerWidth"];
          final outerWidth = tab["outerWidth"];
          final scrollTop = tab["scrollTop"];
          final scrollLeft = tab["scrollLeft"];
          final scrollHeight = tab["scrollHeight"];
          final scrollWidth = tab["scrollWidth"];
          P.translator.browserTabOuterSize.q = {
            ...P.translator.browserTabOuterSize.q,
            id: Size(outerWidth.toDouble(), outerHeight.toDouble()),
          };
          P.translator.browserTabInnerSize.q = {
            ...P.translator.browserTabInnerSize.q,
            id: Size(innerWidth.toDouble(), innerHeight.toDouble()),
          };
          P.translator.browserTabScrollRect.q = {
            ...P.translator.browserTabScrollRect.q,
            id: Rect.fromLTWH(
              scrollLeft.toDouble(),
              scrollTop.toDouble(),
              scrollWidth.toDouble(),
              scrollHeight.toDouble(),
            ),
          };
        case "windows_all":
          final windows = HF.listJSON(json["windows"]);
          final _windows = windows
              .map(
                (e) => BrowserWindow(
                  id: e["id"],
                  left: e["left"],
                  top: e["top"],
                  width: e["width"],
                  height: e["height"],
                  state: e["state"],
                  type: e["type"],
                  focused: e["focused"],
                ),
              )
              .toList();
          P.translator.browserWindows.q = _windows;
        case "tabs_all":
          final tabs = HF.listJSON(json["tabs"]);
          final _tabs = tabs
              .map(
                (e) => BrowserTab(
                  id: e["id"] ?? -1,
                  url: e["url"] ?? "",
                  title: e["title"] ?? "",
                  windowId: e["windowId"] ?? -1,
                  lastAccessed: e["lastAccessed"] ?? -1,
                ),
              )
              .toList();
          P.translator.browserTabs.q = _tabs;
        default:
          channel.sink.add(jsonEncode({'error': 'Invalid logic: $logic'}));
          websocketSentCount.q++;
      }
    } catch (e) {
      qqe(e);
      qqe(json);
      qqe(logic);
      channel.sink.add(jsonEncode({'error': 'logic failed: $logic'}));
      websocketSentCount.q++;
    }
  }

  void _onDone(ws_channel.WebSocketChannel channel) async {
    qqw("WebSocket done");
  }

  void _onError(ws_channel.WebSocketChannel channel, Object error, StackTrace stackTrace) async {
    qqe(error);
  }
}

/// Public methods
extension $Backend on _Backend {
  FV start() async {
    final isDesktop = P.app.isDesktop.q;
    if (!isDesktop) return;

    if (httpState.q == BackendState.running) {
      qqw("Backend is running");
      Alert.warning("Backend is running");
      return;
    }

    if (httpState.q == BackendState.starting) {
      qqw("Backend is already starting");
      Alert.warning("Backend is already starting");
      return;
    }

    if (httpState.q == BackendState.stopping) {
      qqw("Backend is stopping");
      Alert.warning("Backend is stopping");
      return;
    }

    qq;

    final port = httpPort.q;
    final url = "http://localhost:$port";
    httpState.q = BackendState.starting;

    try {
      // final handler = shelf.Pipeline().addHandler(_echoRequest);
      httpServer.q = await shelf_io.serve(_onHttpRequest, 'localhost', port);
      httpServer.q?.autoCompress = true;

      httpState.q = BackendState.running;
      qqr("Backend started at $url");
      Alert.success("Backend started");
    } catch (e) {
      qqe(e);
      httpState.q = BackendState.stopped;
      Alert.error("Failed to start backend");
    }

    try {
      final port = websocketPort.q;
      final url = "ws://localhost:$port";
      websocketState.q = BackendState.starting;
      websocketServer.q = await shelf_io.serve(_webSocketHandler, 'localhost', port);
      websocketServer.q?.autoCompress = true;
      websocketState.q = BackendState.running;
      qqr("Backend started at $url");
      Alert.success("Backend started");
    } catch (e) {
      qqe(e);
      websocketState.q = BackendState.stopped;
      Alert.error("Failed to start backend");
    }
  }

  FV stop() async {
    final isDesktop = P.app.isDesktop.q;
    if (!isDesktop) return;
    qq;
    if (httpServer.q == null) {
      qqw("Backend is not running");
      Alert.warning("Backend is not running");
      return;
    }
    httpServer.q!.close();
    httpServer.q = null;
    httpState.q = BackendState.stopped;
    httpServer.q = null;
    qqr("Backend stopped");
    Alert.success("Backend stopped");
  }
}
