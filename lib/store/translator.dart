part of 'p.dart';

const _initialSource = "This is a test.";
const _initialResult = "";
const _endString = "hlcc_h2evlj_[END]_hlcc_j12hcnu2";
const _maxCachedPairsCount = 10000;

enum ServeMode {
  hoverLoop,
  full,
}

class _URLCompleter {
  final String? url;
  final Completer<String> completer;

  _URLCompleter({required this.url, required this.completer});
}

class _Translator {
  late final source = qs(_initialSource);
  late final textEditingController = TextEditingController(text: _initialSource);
  late final result = qs(_initialResult);
  late final translations = qs<Map<String, String>>({});
  late final runningTaskKey = qs<String?>(null);
  late final isGenerating = qs(false);
  late final serveMode = qs(ServeMode.hoverLoop);

  /// 等待中的翻译任务
  late final completerPool = qs(<String, _URLCompleter>{});

  late final highlightUrl = qs<String?>(null);

  late final browserTabs = qs<List<BrowserTab>>([]);
  late final activeBrowserTab = qs<BrowserTab?>(null);
}

/// Private methods
extension _$Translator on _Translator {
  FV _init() async {
    textEditingController.addListener(_onTextEditingControllerValueChanged);
    source.l(_onTextChanged);
    P.app.pageKey.l(_onPageKeyChanged);
    P.rwkv.broadcastStream.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
    P.translator.runningTaskKey.l(_onRunningTaskKeyChanged);
  }

  void _onTextEditingControllerValueChanged() {
    final textInController = textEditingController.text;
    if (source.q != textInController) source.q = textInController;
  }

  void _onTextChanged(String next) {
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
  }

  void _onPageKeyChanged(PageKey pageKey) {
    qq;
  }

  void _onRunningTaskKeyChanged(String? next) {
    final textInController = textEditingController.text;
    if (next != null && next != textInController) textEditingController.text = next;
  }

  void _handleResponseBufferContent(from_rwkv.ResponseBufferContent res) {
    // 得到的翻译
    final content = res.responseBufferContent;
    // 更新 result
    result.q = content;
    // TODO: 复杂任务的准确映射?
    // 更新 caches
    final request = res.toRWKV as to_rwkv.GetResponseBufferContent;
    final key = request.messages.firstOrNull;
    if (key == null) {
      qqw("key is null");
      return;
    }
    // 更新 translations
    translations.q = {...translations.q, key: content};
  }

  void _handleIsGenerating(from_rwkv.IsGenerating res) {
    final generatingStateFromEvent = res.isGenerating;
    final generatingStateInFrontend = isGenerating.q;

    isGenerating.q = generatingStateFromEvent;

    // 状态由生成中变为非生成中, 则认为是结束信号
    final isStopEvent = generatingStateInFrontend && !generatingStateFromEvent;
    if (!isStopEvent) return;
    _appendEndStringAndStartNewTask();
  }

  void _appendEndStringAndStartNewTask() {
    // 拼接完结末尾
    final key = runningTaskKey.q;
    final translation = translations.q[key];

    if (key == null) {
      qqw("key is null");
      return;
    }

    if (translation == null) {
      qqw("translation is null");
      return;
    }

    translations.q = {...translations.q, key: translation + _endString};

    final c = completerPool.q[key];
    if (c != null) {
      c.completer.complete(translation + _endString);
      completerPool.q = completerPool.q..removeWhere((k, v) => k == key);
    }
    runningTaskKey.q = null;

    // 如果 translations 超过最大缓存数量, 移除最早的条目
    if (translations.q.length > _maxCachedPairsCount) {
      translations.q.remove(translations.q.keys.first);
    }

    final hasUnfinishedCompleter = completerPool.q.isNotEmpty;
    if (hasUnfinishedCompleter) {
      final currentUrl = highlightUrl.q;
      final pool = completerPool.q;
      // 优先执行当前 url 的请求
      // 因为用户肯定是对当前 url 的翻译感兴趣
      final nextKey = pool.keys.firstWhereOrNull((k) => pool[k]?.url == currentUrl) ?? pool.keys.firstOrNull;
      if (nextKey != null) {
        HF.wait(1).then((_) => _startNewTask(nextKey));
      }
    }
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        _handleResponseBufferContent(res);
      case from_rwkv.IsGenerating res:
        _handleIsGenerating(res);
      default:
        break;
    }
  }

  void _onStreamDone() async {
    qq;
    final key = runningTaskKey.q;
    if (key != null && translations.q.containsKey(key)) {
      translations.q[key] = (translations.q[key] ?? "") + _endString;
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    qq;
  }

  void _startNewTask(String sourceKey) {
    P.rwkv.stop();
    runningTaskKey.q = sourceKey;
    P.rwkv.sendMessages(
      [sourceKey],
      getIsGeneratingRate: 1,
      getResponseBufferContentRate: .1,
    );
  }

  /// 1. 如果 runningTaskKey 不是 sourceKey, 停止 LLM, 开启新的任务
  /// 2. 如果 runningTaskKey 是 sourceKey, `translations.q[sourceKey]`
  /// 3. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 为空, 开启新的任务
  /// 4. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 未完结, 开启新的任务
  /// 5. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 已完结, 返回字符串
  ///
  /// 对 [完结] 的定义: 字符串末尾拼接了 `_endString`
  String _getOnTimeTranslation(String sourceKey, {String? url}) {
    final currentRunningTask = runningTaskKey.q;
    final existingTranslation = translations.q[sourceKey];

    final isEnded = existingTranslation?.endsWith(_endString) ?? false;
    if (isEnded) return existingTranslation?.replaceAll(_endString, "") ?? "";

    final isRunning = currentRunningTask == sourceKey;
    if (isRunning) return existingTranslation?.replaceAll(_endString, "") ?? "";

    // not running, not ended
    _startNewTask(sourceKey);

    return existingTranslation?.replaceAll(_endString, "") ?? "";
  }

  Future<String> _getFullTranslation(String sourceKey, {String? url}) async {
    qq;
    final existingTranslation = translations.q[sourceKey];

    final isEnded = existingTranslation?.endsWith(_endString) ?? false;
    if (isEnded) return existingTranslation?.replaceAll(_endString, "") ?? "";

    final existCompleter = completerPool.q[sourceKey];
    if (existCompleter != null) return await existCompleter.completer.future;

    final completer = Completer<String>();
    completerPool.q = Map.from(completerPool.q)..[sourceKey] = _URLCompleter(url: url, completer: completer);

    if (runningTaskKey.q == null) _startNewTask(sourceKey);

    return completer.future;
  }
}

/// Public methods
extension $Translator on _Translator {
  FV onPressTest() async {
    _startNewTask(source.q);
  }

  FV debugCheck() async {
    final runningTaskKey = this.runningTaskKey.q;
    final translations = this.translations.q;
    final completerPool = this.completerPool.q;
    final highlightUrl = this.highlightUrl.q;
    final browserTabs = this.browserTabs.q;
    final activeBrowserTab = this.activeBrowserTab.q;

    debugger();
  }
}
