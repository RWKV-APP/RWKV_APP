part of 'p.dart';

class _Msg {
  // ===========================================================================
  // StateProvider
  // ===========================================================================

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

  /// The key of it is the id of the message
  late final cotDisplayState = qsf<int, CoTDisplayState>(.showCotHeaderAndCotContent);

  late final loading = qs(false);

  late final batchSelection = qsf<Message, int?>(null);

  /// Message bottom 的详情展开状态
  ///
  /// key format: "{scope}::{messageId}"
  late final bottomDetailsExpanded = qs<Map<String, bool>>({});

  /// Message bottom 详情中展示的单条消息 token 数
  late final bottomMessageTokensCount = qs<Map<int, int>>({});

  /// Message bottom 详情中展示的当前会话 token 数
  late final bottomConversationTokensCount = qs<Map<int, int>>({});

  // ===========================================================================
  // Provider
  // ===========================================================================

  /// The list of messages rendering in the chat page message list
  late final list = qp<List<Message>>((ref) {
    final ids = ref.watch(this.ids);
    final pool = ref.watch(this.pool);
    return ids.m((id) => pool[id]).withoutNull;
  });

  late final length = qp<int>((ref) {
    final list = ref.watch(this.list);
    return list.length;
  });

  late final editingBotMessage = qp<bool>((ref) {
    final editingIndex = ref.watch(editingOrRegeneratingIndex);
    if (editingIndex == null) return false;
    final list = ref.watch(this.list);
    if (editingIndex < 0 || editingIndex >= list.length) return false;
    return list[editingIndex].isMine == false;
  });

  late final hasAtLeastOneImage = qp<bool>((ref) {
    final list = ref.watch(this.list);
    return list.any((msg) => msg.type == MessageType.userImage);
  });
}

/// Private methods
extension _$Msg on _Msg {
  Future<void> _init() async {
    switch (P.app.demoType.q) {
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
        return;
      case .chat:
      case .tts:
      case .see:
    }
    qq;
  }

  Message? findByIndex(int index) {
    final currentMessages = [...list.q];
    if (index < 0 || index >= currentMessages.length) return null;
    return currentMessages[index];
  }

  void _clear({bool syncNode = true}) {
    if (syncNode) P.conversation._syncNode();
    ids.q = [];
    msgNode.q = MsgNode(0);
    bottomDetailsExpanded.q = {};
    bottomMessageTokensCount.q = {};
    bottomConversationTokensCount.q = {};
  }

  /// 在内存和数据库中同时更新消息
  Future<bool> _syncMsg(int id, Message msg) async {
    // 在内存中更新消息
    pool.q = {...pool.q, id: msg};
    final db = P.app._db;
    await db.upsertMsg(msg);
    return true;
  }

  /// Load messages from db. Then add them to the pool
  Future<void> _loadMessages(Iterable<int> ids) async {
    loading.q = true;
    try {
      final db = P.app._db;
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
}

/// Public methods
extension $Msg on _Msg {
  String _bottomDetailsStateKey({
    required String scope,
    required int messageId,
  }) {
    return "$scope::$messageId";
  }

  bool isBottomDetailsExpanded({
    required String scope,
    required int messageId,
  }) {
    final String key = _bottomDetailsStateKey(scope: scope, messageId: messageId);
    final bool? expanded = bottomDetailsExpanded.q[key];
    if (expanded == null) return false;
    return expanded;
  }

  void setBottomDetailsExpanded({
    required String scope,
    required int messageId,
    required bool expanded,
  }) {
    final String key = _bottomDetailsStateKey(scope: scope, messageId: messageId);
    final Map<String, bool> current = bottomDetailsExpanded.q;

    if (!expanded) {
      if (!current.containsKey(key)) return;
      final Map<String, bool> next = {...current};
      next.remove(key);
      bottomDetailsExpanded.q = next;
      return;
    }

    if (current[key] == true) return;
    bottomDetailsExpanded.q = {...current, key: true};
  }

  void toggleBottomDetailsExpanded({
    required String scope,
    required int messageId,
  }) {
    final bool expanded = isBottomDetailsExpanded(scope: scope, messageId: messageId);
    setBottomDetailsExpanded(scope: scope, messageId: messageId, expanded: !expanded);
    P.app.hapticLight();
  }

  void clearBottomDetailsStateInScope({
    required String scope,
  }) {
    final Map<String, bool> current = bottomDetailsExpanded.q;
    if (current.isEmpty) return;

    final String prefix = "$scope::";
    final Map<String, bool> next = {};
    for (final MapEntry<String, bool> entry in current.entries) {
      if (entry.key.startsWith(prefix)) continue;
      next[entry.key] = entry.value;
    }
    if (next.length == current.length) return;
    bottomDetailsExpanded.q = next;
  }

  int? getBottomMessageTokensCount({
    required int messageId,
  }) {
    return bottomMessageTokensCount.q[messageId];
  }

  int? getBottomConversationTokensCount({
    required int messageId,
  }) {
    return bottomConversationTokensCount.q[messageId];
  }

  void setBottomTokensCount({
    required int messageId,
    int? messageTokensCount,
    int? conversationTokensCount,
  }) {
    if (messageTokensCount != null) {
      final int? current = bottomMessageTokensCount.q[messageId];
      if (current != messageTokensCount) {
        bottomMessageTokensCount.q = {
          ...bottomMessageTokensCount.q,
          messageId: messageTokensCount,
        };
      }
    }

    if (conversationTokensCount != null) {
      final int? current = bottomConversationTokensCount.q[messageId];
      if (current != conversationTokensCount) {
        bottomConversationTokensCount.q = {
          ...bottomConversationTokensCount.q,
          messageId: conversationTokensCount,
        };
      }
    }
  }

  void clearBottomTokensCount({
    int? messageId,
  }) {
    if (messageId == null) {
      if (bottomMessageTokensCount.q.isNotEmpty) {
        bottomMessageTokensCount.q = {};
      }
      if (bottomConversationTokensCount.q.isNotEmpty) {
        bottomConversationTokensCount.q = {};
      }
      return;
    }

    final Map<int, int> currentMessageCount = bottomMessageTokensCount.q;
    if (currentMessageCount.containsKey(messageId)) {
      final Map<int, int> nextMessageCount = {...currentMessageCount};
      nextMessageCount.remove(messageId);
      bottomMessageTokensCount.q = nextMessageCount;
    }

    final Map<int, int> currentConversationCount = bottomConversationTokensCount.q;
    if (currentConversationCount.containsKey(messageId)) {
      final Map<int, int> nextConversationCount = {...currentConversationCount};
      nextConversationCount.remove(messageId);
      bottomConversationTokensCount.q = nextConversationCount;
    }
  }

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
