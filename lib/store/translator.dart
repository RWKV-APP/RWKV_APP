part of 'p.dart';

const _initialSource = "This is a test.";
const _initialResult = "";

class _Translator {
  late final source = qs(_initialSource);
  late final textEditingController = TextEditingController(text: _initialSource);
  late final result = qs(_initialResult);
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
        result.q = res.responseBufferContent;
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
}

/// Public methods
extension $Translator on _Translator {
  FV onPressTest() async {
    qq;
    P.rwkv.send(to_rwkv.SetPrompt(""));
    P.rwkv.sendMessages([source.q]);
  }
}
