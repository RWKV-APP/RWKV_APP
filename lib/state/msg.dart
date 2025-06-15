part of 'p.dart';

class _Msg {
  /// The pool of messages
  late final pool = qs<Map<int, Message>>({});

  /// All message ids rendering in the chat page message list
  ///
  /// Source from _msgNode
  late final ids = qs<List<int>>([]);

  /// The latest clicked message
  late final latestClicked = qs<Message?>(null);

  /// The index of the message being edited or regenerating
  late final editingOrRegeneratingIndex = qs<int?>(null);

  /// The node of the message list
  late final msgNode = qs<MsgNode>(MsgNode(0));

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

  late final loading = qs(false);
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
    msgNode.q = MsgNode(0);
  }

  Future<bool> _syncMsg(int id, Message msg) async {
    // 在内存中更新消息
    pool.q = {...pool.q, id: msg};
    final db = P.db._db;
    await db.upsertMsg(msg);
    return true;
  }

  /// Load messages from db. Then add them to the pool
  FV _loadMessages(Iterable<int> ids) async {
    loading.q = true;
    try {
      final db = P.db._db;
      final messages = await db.getMessagesByIds(ids);
      for (var message in messages) {
        pool.q = {...pool.q, message.id: message};
      }
    } catch (e) {
      qqr("Failed to load messages: $e");
    } finally {
      loading.q = false;
    }
  }

  void _logMsgNode() {
    qqr("msgNode.createAtInUS: ${msgNode.q.createAtInUS}");
  }
}

/// Public methods
extension $Msg on _Msg {
  int siblingCount(Message msg) {
    final parent = msgNode.q.findParentByMsgId(msg.id);
    if (parent == null) return 1;
    return parent.children.length;
  }

  List<int> siblingIds(Message msg) {
    final parent = msgNode.q.findParentByMsgId(msg.id);
    if (parent == null) return [];
    return parent.children.map((e) => e.id).toList();
  }

  void onTapSwitchAtIndex(
    int index, {
    required bool isBack,
    required Message msg,
  }) async {
    final parent = msgNode.q.findParentByMsgId(msg.id);
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
    ids.q = msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
  }
}
