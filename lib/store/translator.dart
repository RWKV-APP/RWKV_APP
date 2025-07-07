part of 'p.dart';

const _initialSource = "This is a test.";
const _initialResult = "";
const _endString = "hlcc_[END]_hlcc";
const _maxCachedPairsCount = 1;

class _Translator {
  late final source = qs(_initialSource);
  late final textEditingController = TextEditingController(text: _initialSource);
  late final result = qs(_initialResult);
  late final translations = qs<LinkedHashMap<String, String>>(LinkedHashMap());
  late final runningTaskKey = qs<String?>(null);
  late final isGenerating = qs(false);
}

/// Private methods
extension _$Translator on _Translator {
  FV _init() async {
    textEditingController.addListener(_onTextEditingControllerValueChanged);
    source.l(_onTextChanged);
    P.app.pageKey.l(_onPageKeyChanged);
    P.rwkv.broadcastStream.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
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

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    // qqq("onStreamEvent: $event");
    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        // 得到的翻译
        final content = res.responseBufferContent;
        // 更新 result
        result.q = content;
        // TODO: 复杂任务的准确映射?
        // 更新 caches
        final request = res.toRWKV as to_rwkv.GetResponseBufferContent;
        final key = request.messages.firstOrNull;
        if (key == null) return;
        // 更新 translations
        translations.q = LinkedHashMap.from({...translations.q, key: content});
        qqr("translations: ${translations.q.toString()}");
        break;
      case from_rwkv.IsGenerating res:
        final isGenerating = res.isGenerating;

        final currentIsGenerating = this.isGenerating.q;
        final isStopEvent = currentIsGenerating && !isGenerating;
        if (isStopEvent) {
          // 拼接完结末尾
          final key = runningTaskKey.q;
          final translation = translations.q[key];
          if (translation != null) {
            translations.q = LinkedHashMap.from({
              ...translations.q,
              key: translation + _endString,
            });
          }

          runningTaskKey.q = null;

          // 如果 translations 超过最大缓存数量, 移除最早的条目
          if (translations.q.length > _maxCachedPairsCount) {
            translations.q.remove(translations.q.keys.first);
          }
        }

        this.isGenerating.q = isGenerating;
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

  void _startNewTask(String sourceKey) {
    P.rwkv.stop();
    runningTaskKey.q = sourceKey;
    P.rwkv.sendMessages([sourceKey]);
  }

  /// 1. 如果 runningTaskKey 不是 sourceKey, 停止 LLM, 开启新的任务
  /// 2. 如果 runningTaskKey 是 sourceKey, `translations.q[sourceKey]`
  /// 3. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 为空, 开启新的任务
  /// 4. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 未完结, 开启新的任务
  /// 5. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 已完结, 返回字符串
  ///
  /// 对 [完结] 的定义: 字符串末尾拼接了 `_endString`
  String _getTranslation(String sourceKey) {
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
}

/// Public methods
extension $Translator on _Translator {
  FV onPressTest() async {
    _startNewTask(source.q);
  }
}
