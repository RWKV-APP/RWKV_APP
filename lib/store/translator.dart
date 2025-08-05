part of 'p.dart';

const _initialSource = "This is a test.";
const _initialResult = "";
const _endString = "hlcc_h2evlj_[END]_hlcc_j12hcnu2";

enum ServeMode {
  hoverLoop,
  full,
}

class _URLCompleter {
  final String? url;
  final int? tabId;
  final Completer<String> completer;
  final int? priority;
  final String? nodeName;
  final int? tick;

  const _URLCompleter({
    required this.url,
    required this.tabId,
    required this.completer,
    required this.priority,
    required this.nodeName,
    required this.tick,
  });
}

class _Translator {
  // TODO: 性能问题, 需要优化
  /// 翻译结果内存缓存
  late final translations = qs<Map<String, String>>({});
  late final translationCountInSandbox = qs(0);
  late final _saveTranslationsThrottler = Throttler(milliseconds: 10000, trailing: true);

  late final source = qs(_initialSource);
  late final textEditingController = TextEditingController(text: _initialSource);
  late final result = qs(_initialResult);
  late final resultTextEditingController = TextEditingController(text: _initialResult);

  late final runningTaskKey = qs<String?>(null);
  late final runningTaskTabId = qs<int?>(null);
  late final runningTaskUrl = qs<String?>(null);
  late final isGenerating = qs(false);
  late final serveMode = qs(ServeMode.hoverLoop);

  /// 每个 tab 中, 等待翻译的翻译任务, 以需要被翻译的原始字符串为 key, 以 _URLCompleter 为 value
  late final pool = qsf<BrowserTab, Map<String, _URLCompleter>>({});

  /// 所有已经打开了的标签页
  late final browserTabs = qs<List<BrowserTab>>([]);

  /// 当前激活的标签页
  late final activedTab = qs<BrowserTab?>(null);

  /// 每个 Window 中, 最新的标签页
  late final latestTabs = qs<Map<int, BrowserTab>>({});

  late final browserTabOuterSize = qs<Map<int, Size>>({});
  late final browserTabInnerSize = qs<Map<int, Size>>({});
  late final browserTabScrollRect = qs<Map<int, Rect>>({});

  late final browserWindows = qs<List<BrowserWindow>>([]);
  late final latestTaskTag = qs<int>(0);

  late final Timer _taskCheckingTimer;
}

/// Private methods
extension _$Translator on _Translator {
  FV _init() async {
    final isDesktop = P.app.isDesktop.q;
    textEditingController.addListener(_onTextEditingControllerValueChanged);
    source.l(_onTextChanged);
    result.l(_onResultChanged);
    P.app.pageKey.l(_onPageKeyChanged);
    P.rwkv.broadcastStream.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
    runningTaskKey.l(_onRunningTaskKeyChanged);
    translations.l(_onTranslationsChanged);

    isGenerating.l(_onIsGeneratingChanged);
    latestTaskTag.l(_onLatestTaskTagChanged);

    if (isDesktop) browserTabs.l(_onBrowserTabsChanged);

    await _loadTranslationsFromFile();

    if (isDesktop) {
      _taskCheckingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _checkTask();
      });
    }
  }

  void _checkTask() async {
    final model = P.rwkv.currentModel.q;
    if (model == null) return;
    final wsRunning = P.backend.websocketState.q == BackendState.running;
    if (!wsRunning) return;
    final httpRunning = P.backend.httpState.q == BackendState.running;
    if (!httpRunning) return;

    final isGenerating = this.isGenerating.q;
    if (isGenerating) return;
    await HF.wait(100);
    final isGenerating2 = this.isGenerating.q;
    if (isGenerating2) return;
    final key = _selectNextTaskKey();
    if (key == null) return;
    _startNewTask(key);
  }

  void _onBrowserTabsChanged(List<BrowserTab> next) {
    final Map<int, BrowserTab> latestTabs = {};
    for (final tab in next) {
      final windowId = tab.windowId;
      latestTabs[windowId] = tab;
    }
    this.latestTabs.q = latestTabs;
  }

  void _onIsGeneratingChanged(bool next) {
    if (next) return;
    final key = _selectNextTaskKey();
    if (key == null) return;
    _startNewTask(key);
  }

  void _onLatestTaskTagChanged(int next) {
    final isGenerating = this.isGenerating.q;
    if (isGenerating) return;
    final key = _selectNextTaskKey();
    if (key == null) return;
    _startNewTask(key);
  }

  void _onTranslationsChanged(Map<String, String> next) async {
    _saveTranslationsThrottler.call(() async {
      await _saveTranslationsToFile();
    });
  }

  Future<void> _loadTranslationsFromFile() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final file = File('${documentsDir.path}/translator_cache.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final translations = jsonDecode(content).cast<String, String>();
        this.translations.q = translations;
        translationCountInSandbox.q = translations.length;
      }
    } catch (e) {
      // 如果文件读取失败，使用空缓存
      translations.q = {};
      translationCountInSandbox.q = 0;
    }
  }

  Future<void> _saveTranslationsToFile() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final file = File('${documentsDir.path}/translator_cache.json');
      Map<String, String> existTranslation = {};
      if (await file.exists()) {
        final content = await file.readAsString();
        existTranslation = jsonDecode(content).cast<String, String>();
      }

      final translations = this.translations.q;
      final newTranslations = {...existTranslation, ...translations};
      final jsonContent = jsonEncode(newTranslations);
      await file.writeAsString(jsonContent);
      translationCountInSandbox.q = newTranslations.length;
    } catch (e) {
      // 保存失败时的错误处理
      qqw("Failed to save translations to file: $e");
    }
  }

  void _onTextEditingControllerValueChanged() {
    final textInController = textEditingController.text;
    if (source.q != textInController) source.q = textInController;
  }

  void _onTextChanged(String next) {
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
  }

  void _onResultChanged(String next) {
    final textInController = resultTextEditingController.text;
    if (next != textInController) resultTextEditingController.text = next;
  }

  void _onPageKeyChanged(PageKey pageKey) {
    qq;
    switch (pageKey) {
      case PageKey.translator:
        final currentModel = P.rwkv.currentModel.q;
        if (currentModel == null) {
          HF.wait(500).then((_) {
            ModelSelector.show();
          });
        } else {
          if (!currentModel.tags.contains("translate")) {
            P.rwkv.currentModel.q = null;
            Alert.info(S.current.please_load_model_first);
            HF.wait(500).then((_) {
              ModelSelector.show();
            });
            return;
          }
        }
        break;
      default:
        break;
    }
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

    translations.q = {
      ...translations.q,
      key: translation + _endString,
    };

    // 在所有任务中, 寻找指定的 completer, 并完成它
    final browserTabs = this.browserTabs.q;
    for (final tab in browserTabs) {
      final pool = this.pool(tab).q;
      final urlCompleter = pool[key];
      if (urlCompleter == null) continue;
      urlCompleter.completer.complete(translation + _endString);
      final newPool = Map.from(pool)..remove(key);
      this.pool(tab).q = {...newPool};
    }

    runningTaskKey.q = null;

    final nextKey = _selectNextTaskKey();
    if (nextKey == null) return;
    HF.wait(0).then((_) => _startNewTask(nextKey));
  }

  String? _selectNextTaskKey() {
    final activedTab = this.activedTab.q;
    final latestTabs = this.latestTabs.q;
    final browserTabs = this.browserTabs.q;

    if (browserTabs.isEmpty) {
      runningTaskUrl.q = null;
      runningTaskTabId.q = null;
      return null;
    }

    if (activedTab != null) {
      final pool = this.pool(activedTab).q;
      if (pool.isNotEmpty) {
        final result = pool.keys.first;
        final urlCompleter = pool[result];
        runningTaskUrl.q = urlCompleter?.url;
        runningTaskTabId.q = urlCompleter?.tabId;
        return result;
      }
    }

    for (final entry in latestTabs.entries) {
      final tab = entry.value;
      final pool = this.pool(tab).q;
      if (pool.isNotEmpty) {
        final result = pool.keys.first;
        final urlCompleter = pool[result];
        runningTaskUrl.q = urlCompleter?.url;
        runningTaskTabId.q = urlCompleter?.tabId;
        return result;
      }
    }

    for (final tab in browserTabs) {
      final pool = this.pool(tab).q;
      if (pool.isNotEmpty) {
        final result = pool.keys.first;
        final urlCompleter = pool[result];
        runningTaskUrl.q = urlCompleter?.url;
        runningTaskTabId.q = urlCompleter?.tabId;
        return result;
      }
    }

    runningTaskUrl.q = null;
    runningTaskTabId.q = null;
    return null;
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

  void _startNewTask(String source) {
    P.rwkv.stop();
    runningTaskKey.q = source;
    P.rwkv.sendMessages(
      [source],
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

  Future<String> _getFullTranslation(JSON json) async {
    final source = json['source'] as String;
    final url = json['url'] as String;
    final tabId = json['tabId'] as int;
    final priority = json['priority'] as int;
    final nodeName = json['nodeName'] as String;
    final tick = json['tick'] as int;
    final windowId = json['windowId'] as int;

    // 如果内存缓存中已存在
    final existingTranslation = translations.q[source];
    final isEnded = existingTranslation?.endsWith(_endString) ?? false;
    if (isEnded) return existingTranslation?.replaceAll(_endString, "") ?? "";

    final key = BrowserTab(
      id: tabId,
      url: url,
      windowId: windowId,
      title: "",
      lastAccessed: -1,
    );

    _URLCompleter? urlCompleter = pool(key).q[source];
    if (urlCompleter != null) {
      latestTaskTag.q++;
      return await urlCompleter.completer.future;
    }

    urlCompleter = _URLCompleter(
      url: url,
      tabId: tabId,
      completer: Completer<String>(),
      priority: priority,
      nodeName: nodeName,
      tick: tick,
    );

    pool(key).q = {
      ...pool(key).q,
      source: urlCompleter,
    };

    latestTaskTag.q++;
    return await urlCompleter.completer.future;
  }
}

/// Public methods
extension $Translator on _Translator {
  FV onPressTest() async {
    final s = S.current;
    if (!P.rwkv.loaded.q) {
      Alert.info(s.please_load_model_first);
      ModelSelector.show();
      return;
    }
    result.q = "";
    resultTextEditingController.text = "";
    _startNewTask(source.q);
  }

  void debugCheck() {
    final runningTaskKey = this.runningTaskKey.q;
    final translations = this.translations.q;
    final browserTabs = this.browserTabs.q;
    final activeBrowserTab = activedTab.q;
    final pools = browserTabs.map((tab) => pool(tab).q).where((pool) => pool.isNotEmpty).toList();
  }
}
