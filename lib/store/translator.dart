part of 'p.dart';

const _initialSource = "This is a test.";
const _initialResult = "";

class _Translator {
  late final source = qs(_initialSource);
  late final textEditingController = TextEditingController(text: _initialSource);
  late final result = qs(_initialResult);
  late final translations = qs<LinkedHashMap<String, String>>(LinkedHashMap());
  late final runningTaskKey = qs<String?>(null);
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
    qq;
    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        final content = res.responseBufferContent;
        result.q = content;
        final request = res.toRWKV as to_rwkv.GetResponseBufferContent;
        final sourceKey = request.messages.firstOrNull;
        if (sourceKey == null) return;
        translations.q[sourceKey] = content;
        break;
      default:
        break;
    }
  }

  void _onStreamDone() async {
    qq;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    qq;
  }

  /// 1. 如果 runningTaskKey 不是 sourceKey, 停止 LLM, 开启新的任务
  /// 2. 如果 runningTaskKey 是 sourceKey, `translations.q[sourceKey]`
  /// 3. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 为空, 开启新的任务
  /// 4. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 未完结, 开启新的任务
  /// 5. 如果 runningTaskKey 是 null, 如果 `translations.q[sourceKey]` 已完结, 返回字符串
  String _getTranslation(String sourceKey) {
    return translations.q[sourceKey] ?? "";
  }
}

/// Public methods
extension $Translator on _Translator {
  FV onPressTest() async {
    qq;
    P.rwkv.send(to_rwkv.SetPrompt(""));
    P.rwkv.sendMessages([source.q]);
  }
}
