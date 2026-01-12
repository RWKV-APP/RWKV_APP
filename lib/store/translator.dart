part of 'p.dart';

const _initialSourceEn =
    """RWKV (pronounced RwaKuv) is an RNN with great LLM performance, which can also be directly trained like a GPT transformer (parallelizable). We are at RWKV-7 "Goose".
    
So it's combining the best of RNN and transformer - great performance, linear time, constant space (no kv-cache), fast training, infinite ctx_len, and free sentence embedding.""";
const _initialResult = "";
const _endString = "hlcc_h2evlj_[END]_hlcc_j12hcnu2";

class _Translator {
  // ===========================================================================
  // Instance
  // ===========================================================================

  // TODO: 性能问题, 需要优化
  late final _saveTranslationsThrottler = Throttler(milliseconds: 10000, trailing: true);

  late final textEditingController = TextEditingController(text: _initialSourceEn);
  late final resultTextEditingController = TextEditingController(text: _initialResult);

  /// 批量任务的定时器
  Timer? _batchTaskTimer;

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  /// 翻译结果内存缓存
  late final translations = qs<Map<String, String>>({});
  late final translationCountInSandbox = qs(0);

  late final source = qs(_initialSourceEn);
  late final result = qs(_initialResult);

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

  late final enToZh = qs(true);

  /// 是否启用并行（批量）翻译，由用户控制，但会根据输入自动联动
  late final batchEnabled = qs(false);

  /// 是否允许自动联动批量开关（用户手动切换后将关闭自动联动）
  late final batchAuto = qs(true);

  /// 当前批量任务的原始行列表（用于多行翻译）
  late final batchTaskLines = qs<List<String>>([]);

  /// 批量任务中每一行的翻译结果
  late final batchTranslations = qs<Map<int, String>>({});
}

/// Private methods
extension _$Translator on _Translator {
  Future<void> _init() async {
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
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _checkTask();
      });
    }
  }

  void _checkTask() async {
    final model = P.rwkv.latestModel.q;
    if (model == null) return;
    final wsRunning = P.backend.websocketState.q == BackendState.running;
    if (!wsRunning) return;
    final httpRunning = P.backend.httpState.q == BackendState.running;
    if (!httpRunning) return;

    final isGenerating = this.isGenerating.q;
    if (isGenerating) return;
    await Future.delayed(const Duration(milliseconds: 100));
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
    // 根据输入是否为多行，自动联动批量开关（仅在 batchAuto 开启时）
    if (batchAuto.q) {
      final lines = textInController.trim().split('\n').where((e) => e.trim().isNotEmpty).toList();
      final isMulti = lines.length > 1;
      if (isMulti && !batchEnabled.q) batchEnabled.q = true;
      if (!isMulti && batchEnabled.q) batchEnabled.q = false;
    }
  }

  void _onTextChanged(String next) {
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
    // 根据输入是否为多行，自动联动批量开关（仅在 batchAuto 开启时）
    if (batchAuto.q) {
      final lines = next.trim().split('\n').where((e) => e.trim().isNotEmpty).toList();
      final isMulti = lines.length > 1;
      if (isMulti && !batchEnabled.q) batchEnabled.q = true;
      if (!isMulti && batchEnabled.q) batchEnabled.q = false;
    }
  }

  void _onResultChanged(String next) {
    final textInController = resultTextEditingController.text;
    if (next != textInController) resultTextEditingController.text = next;
  }

  Future<void> _onPageKeyChanged(PageKey pageKey) async {
    switch (pageKey) {
      case .translator:
      case .ocr:
        P.app.demoType.q = .chat;
        final currentModel = P.rwkv.latestModel.q;
        if (currentModel == null) {
          Future.delayed(const Duration(milliseconds: 500)).then((_) {
            ModelSelector.show();
          });
        } else {
          if (!currentModel.tags.contains("translate")) {
            await P.rwkv._releaseAllModels();
            Alert.info(S.current.please_load_model_first);
            Future.delayed(const Duration(milliseconds: 500)).then((_) {
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
    qr;
    // 得到的翻译
    final content = res.responseBufferContent;
    // 更新 result
    result.q = content;
    // TODO: 复杂任务的准确映射?
    // 更新 caches
    final request = res.req as to_rwkv.GetResponseBufferContent;
    final key = request.messages.firstOrNull;
    if (key == null) {
      qqw("key is null");
      return;
    }
    // 更新 translations
    translations.q = {...translations.q, key: content};
  }

  void _handleIsGenerating(from_rwkv.IsGenerating res) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .see || pageKey == .talk || pageKey == .chat) return;
    final generatingStateFromEvent = res.isGenerating;
    final generatingStateInFrontend = isGenerating.q;

    isGenerating.q = generatingStateFromEvent;

    // 状态由生成中变为非生成中, 则认为是结束信号
    final isStopEvent = generatingStateInFrontend && !generatingStateFromEvent;
    if (!isStopEvent) return;

    // 如果是批量任务，处理批量任务的结束
    if (batchTaskLines.q.isNotEmpty) {
      _appendBatchEndString();
    } else {
      _appendEndStringAndStartNewTask();
    }
  }

  void _appendBatchEndString() {
    qw;
    final batchLines = batchTaskLines.q;
    if (batchLines.isEmpty) return;

    // 清理定时器
    if (_batchTaskTimer != null) {
      _batchTaskTimer!.cancel();
      _batchTaskTimer = null;
    }

    // 将所有行的翻译结果用换行符连接起来
    final combinedResult = <String>[];
    for (var i = 0; i < batchLines.length; i++) {
      final translation = batchTranslations.q[i] ?? "";
      combinedResult.add(translation);
    }
    final finalResult = combinedResult.join("\n");

    // 更新 result
    result.q = finalResult;

    // 清空批量任务状态
    batchTaskLines.q = [];
    batchTranslations.q = {};
    runningTaskKey.q = null;
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
      final newPool = {...Map.from(pool)..remove(key)};
      this.pool(tab).q = {...newPool};
    }

    runningTaskKey.q = null;

    final nextKey = _selectNextTaskKey();
    if (nextKey == null) return;
    Future.delayed(const Duration(milliseconds: 0)).then((_) => _startNewTask(nextKey));
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
    final pageKey = P.app.pageKey.q;
    if (pageKey == .chat || pageKey == .talk || pageKey == .benchmark || pageKey == .ocr) return;
    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        // 只有在非批量模式下才处理单行响应
        if (batchTaskLines.q.isEmpty) _handleResponseBufferContent(res);
        break;
      case from_rwkv.ResponseBatchBufferContent res:
        _handleBatchResponseBufferContent(res);
        break;
      case from_rwkv.IsGenerating res:
        _handleIsGenerating(res);
        break;
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

  void _startBatchTask(List<String> lines) {
    qq;
    P.rwkv.stop();

    // 清理之前的定时器
    if (_batchTaskTimer != null) {
      _batchTaskTimer!.cancel();
      _batchTaskTimer = null;
    }

    batchTranslations.q = {};
    final batchSize = lines.length;

    // 设置 runningTaskKey 为整个输入文本，用于标识当前任务
    runningTaskKey.q = lines.join("\n");

    // 为每一行创建消息列表
    final batchMessages = <List<String>>[];
    for (var line in lines) {
      batchMessages.add([line.trim()]);
    }

    // 使用批量模式发送：每个批次是一条独立的消息列表
    final thinkingMode = P.rwkv.thinkingMode.q;
    final reasoning = thinkingMode.hasThinkTag;
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    P.rwkv.send(
      to_rwkv.ChatBatchAsync(
        batchMessages,
        enableReasoning: reasoning,
        forceReasoning: thinkingMode.forceReasoning,
        batchSize: batchSize,
        modelID: modelID,
      ),
    );

    // 启动定时器获取响应
    _batchTaskTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      // 获取批量响应（无参数版本会返回所有批次的响应）
      P.rwkv.send(to_rwkv.GetBatchResponseBufferContent(messages: [], modelID: modelID));
      P.rwkv.send(to_rwkv.GetIsGenerating(modelID: modelID));
      P.rwkv.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    });
  }

  void _handleBatchResponseBufferContent(from_rwkv.ResponseBatchBufferContent res) {
    qr;

    final responseBufferContents = res.responseBufferContent;
    final batchLines = batchTaskLines.q;

    if (batchLines.isEmpty) {
      return;
    }

    // 更新每一行的翻译结果
    final updatedTranslations = <int, String>{};
    for (var i = 0; i < responseBufferContents.length && i < batchLines.length; i++) {
      updatedTranslations[i] = responseBufferContents[i];
    }

    batchTranslations.q = {...batchTranslations.q, ...updatedTranslations};

    // 将所有行的翻译结果用换行符连接起来
    final combinedResult = <String>[];
    for (var i = 0; i < batchLines.length; i++) {
      final translation = batchTranslations.q[i] ?? "";
      combinedResult.add(translation);
    }
    final finalResult = combinedResult.join("\n");

    result.q = finalResult;
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

  Future<String> _getFullTranslation(Map<String, dynamic> json) async {
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
  Future<void> onPressTest() async {
    final s = S.current;
    if (!P.rwkv.loaded.q) {
      Alert.info(s.please_load_model_first);
      ModelSelector.show();
      return;
    }
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    // 确保角色与方向一致
    if (enToZh.q) {
      P.rwkv.send(to_rwkv.SetUserRole("English", modelID: modelID));
      P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "Chinese", modelID: modelID));
    } else {
      P.rwkv.send(to_rwkv.SetUserRole("Chinese", modelID: modelID));
      P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "English", modelID: modelID));
    }
    result.q = "";
    resultTextEditingController.text = "";
    batchTranslations.q = {};
    batchTaskLines.q = [];

    final sourceText = source.q.trim();
    if (sourceText.isEmpty) return;

    // 如果用户关闭了批量，则不进行任何换行分割，直接单次翻译
    if (!batchEnabled.q) {
      _startNewTask(sourceText);
      return;
    }

    // 批量开启的情况下才进行换行分割
    final lines = sourceText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final isMulti = lines.length > 1;

    // 单行时强制关闭批量
    if (!isMulti && batchEnabled.q) {
      batchEnabled.q = false;
      _startNewTask(sourceText);
      return;
    }

    if (isMulti) {
      // 多行 + 已启用批量
      batchTaskLines.q = lines;
      _startBatchTask(lines);
    } else {
      // 单行 或 用户关闭了批量
      _startNewTask(sourceText);
    }
  }

  void debugCheck() {
    final runningTaskKey = this.runningTaskKey.q;
    final translations = this.translations.q;
    final browserTabs = this.browserTabs.q;
    final activeBrowserTab = activedTab.q;
    final pools = browserTabs.map((tab) => pool(tab).q).where((pool) => pool.isNotEmpty).toList();
  }

  void onDirectionButtonPressed() async {
    enToZh.q = !enToZh.q;
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    if (enToZh.q) {
      P.rwkv.send(to_rwkv.SetUserRole("English", modelID: modelID));
      P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "Chinese", modelID: modelID));
    } else {
      P.rwkv.send(to_rwkv.SetUserRole("Chinese", modelID: modelID));
      P.rwkv.send(to_rwkv.SetResponseRole(responseRole: "English", modelID: modelID));
    }

    // 将下方结果文本移动到上方输入；若结果为空，则会清空上方，实现“清除全部”
    final resultText = resultTextEditingController.text.trim();
    source.q = resultText;
    result.q = "";
    resultTextEditingController.text = "";
    // 清理批量状态
    batchTaskLines.q = [];
    batchTranslations.q = {};
    runningTaskKey.q = null;

    // 若上下文本均为空，且为 EN -> ZH 模式，则填充示例英文文本
    final srcNow = source.q.trim();
    final resNow = result.q.trim();
    if (srcNow.isEmpty && resNow.isEmpty && enToZh.q) {
      source.q = _initialSourceEn;
    }
  }

  void onBatchToggle(bool next) {
    final src = source.q;
    final lines = src.trim().split('\n').where((e) => e.trim().isNotEmpty).toList();
    final isMulti = lines.length > 1;
    if (!isMulti && next) {
      Alert.info(S.current.this_model_does_not_support_batch_inference); // 重用已有提示文案
      batchEnabled.q = false;
      return;
    }
    batchEnabled.q = next;
  }
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
