part of 'p.dart';

class _Msg {
  /// The pool of messages
  late final pool = qs<Map<int, Message>>({});

  /// All message ids rendering in the chat page message list
  late final ids = qs<List<int>>([]);

  /// The latest clicked message
  late final latestClicked = qs<Message?>(null);

  /// The index of the message being edited or regenerating
  late final editingOrRegeneratingIndex = qs<int?>(null);

  /// The node of the message list
  MsgNode _msgNode = MsgNode(0);

  /// The list of messages rendering in the chat page message list
  late final list = qp<List<Message>>((ref) {
    final ids = ref.watch(this.ids);
    final pool = ref.watch(this.pool);
    return ids.m((id) => pool[id]).withoutNull;
  });

  late final editingBotMessage = qp<bool>((ref) {
    final editingIndex = ref.watch(editingOrRegeneratingIndex);
    if (editingIndex == null) return false;
    final list = ref.watch(this.list);
    return list[editingIndex].isMine == false;
  });

  /// The key of it is the id of the message
  late final cotDisplayState = qsf<int, CoTDisplayState>(CoTDisplayState.showCotHeaderAndCotContent);
}

/// Private methods
extension _$Msg on _Msg {
  FV _init() async {
    switch (P.app.demoType.q) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        return;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
    }
    qq;
  }

  Message? findByIndex(int index) {
    final currentMessages = [...list.q];
    if (index < 0 || index >= currentMessages.length) return null;
    return currentMessages[index];
  }

  void _clear() {
    P.conversation._syncNode();
    ids.q = [];
    _msgNode = MsgNode(0);
  }
}

/// Public methods
extension $Msg on _Msg {
  int siblingCount(Message msg) {
    final parent = _msgNode.findParentByMsgId(msg.id);
    if (parent == null) return 1;
    return parent.children.length;
  }

  List<int> siblingIds(Message msg) {
    final parent = _msgNode.findParentByMsgId(msg.id);
    if (parent == null) return [];
    return parent.children.map((e) => e.id).toList();
  }

  void onTapSwitchAtIndex(
    int index, {
    required bool isBack,
    required Message msg,
  }) {
    final parent = _msgNode.findParentByMsgId(msg.id);
    if (parent == null) {
      qqe("parent is null");
      return;
    }
    final siblingIds = parent.children.map((e) => e.id).toList();
    final siblingIndex = siblingIds.indexOf(msg.id);
    if (siblingIndex == -1) {
      qqe("siblingIndex is -1");
      return;
    }
    if (siblingIds.length == 1) {
      qqe("No siblings to switch");
      return;
    }
    final newIndex = siblingIndex + (isBack ? -1 : 1);
    if (newIndex < 0 || newIndex >= siblingIds.length) {
      qqe("newIndex is out of range");
      return;
    }
    parent.latest = parent.children[newIndex];
    ids.q = _msgNode.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
  }
}
