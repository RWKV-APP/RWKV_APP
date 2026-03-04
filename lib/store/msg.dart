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
    final key = _bottomDetailsStateKey(scope: scope, messageId: messageId);
    final expanded = bottomDetailsExpanded.q[key];
    if (expanded == null) return false;
    return expanded;
  }

  void setBottomDetailsExpanded({
    required String scope,
    required int messageId,
    required bool expanded,
  }) {
    final key = _bottomDetailsStateKey(scope: scope, messageId: messageId);
    final current = bottomDetailsExpanded.q;

    if (!expanded) {
      if (!current.containsKey(key)) return;
      final next = <String, bool>{...current};
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
    final expanded = isBottomDetailsExpanded(scope: scope, messageId: messageId);
    setBottomDetailsExpanded(scope: scope, messageId: messageId, expanded: !expanded);
    P.app.hapticLight();
  }

  void clearBottomDetailsStateInScope({
    required String scope,
  }) {
    final current = bottomDetailsExpanded.q;
    if (current.isEmpty) return;

    final prefix = "$scope::";
    final next = <String, bool>{};
    for (final entry in current.entries) {
      if (entry.key.startsWith(prefix)) continue;
      next[entry.key] = entry.value;
    }
    if (next.length == current.length) return;
    bottomDetailsExpanded.q = next;
  }

  void clearBottomDetailsStateByMessageIds({
    required Iterable<int> messageIds,
  }) {
    final targets = messageIds.toSet();
    if (targets.isEmpty) return;

    final current = bottomDetailsExpanded.q;
    if (current.isEmpty) return;

    final next = <String, bool>{};
    for (final entry in current.entries) {
      final splitIndex = entry.key.lastIndexOf("::");
      if (splitIndex <= 0) {
        next[entry.key] = entry.value;
        continue;
      }
      final idText = entry.key.substring(splitIndex + 2);
      final id = int.tryParse(idText);
      if (id != null && targets.contains(id)) continue;
      next[entry.key] = entry.value;
    }
    if (next.length == current.length) return;
    bottomDetailsExpanded.q = next;
  }

  void syncBottomDetailsExpandedBetweenMessages({
    required int sourceMessageId,
    required int targetMessageId,
  }) {
    if (sourceMessageId == targetMessageId) return;

    final current = bottomDetailsExpanded.q;
    if (current.isEmpty) return;

    final sourceSuffix = "::$sourceMessageId";
    final targetSuffix = "::$targetMessageId";
    final scopesToSync = <String>{};

    for (final key in current.keys) {
      if (!key.endsWith(sourceSuffix) && !key.endsWith(targetSuffix)) continue;
      final splitIndex = key.lastIndexOf("::");
      if (splitIndex <= 0) continue;
      final scope = key.substring(0, splitIndex);
      scopesToSync.add(scope);
    }

    if (scopesToSync.isEmpty) return;

    final Map<String, bool> next = {...current};
    bool changed = false;

    for (final scope in scopesToSync) {
      final sourceKey = _bottomDetailsStateKey(scope: scope, messageId: sourceMessageId);
      final targetKey = _bottomDetailsStateKey(scope: scope, messageId: targetMessageId);
      final sourceExpanded = current[sourceKey] ?? false;
      final targetExpanded = current[targetKey] ?? false;

      if (sourceExpanded == targetExpanded) continue;
      changed = true;

      if (!sourceExpanded) {
        next.remove(targetKey);
        continue;
      }

      next[targetKey] = true;
    }

    if (!changed) return;
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
      final current = bottomMessageTokensCount.q[messageId];
      if (current != messageTokensCount) {
        bottomMessageTokensCount.q = {
          ...bottomMessageTokensCount.q,
          messageId: messageTokensCount,
        };
      }
    }

    if (conversationTokensCount != null) {
      final current = bottomConversationTokensCount.q[messageId];
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

    final currentMessageCount = bottomMessageTokensCount.q;
    if (currentMessageCount.containsKey(messageId)) {
      final nextMessageCount = <int, int>{...currentMessageCount};
      nextMessageCount.remove(messageId);
      bottomMessageTokensCount.q = nextMessageCount;
    }

    final currentConversationCount = bottomConversationTokensCount.q;
    if (currentConversationCount.containsKey(messageId)) {
      final nextConversationCount = <int, int>{...currentConversationCount};
      nextConversationCount.remove(messageId);
      bottomConversationTokensCount.q = nextConversationCount;
    }
  }

  void clearBottomTokensCountByMessageIds({
    required Iterable<int> messageIds,
  }) {
    final targets = messageIds.toSet();
    if (targets.isEmpty) return;

    final Map<int, int> currentMessageCount = bottomMessageTokensCount.q;
    final Map<int, int> nextMessageCount = {};
    bool messageCountChanged = false;
    for (final MapEntry<int, int> entry in currentMessageCount.entries) {
      if (targets.contains(entry.key)) {
        messageCountChanged = true;
        continue;
      }
      nextMessageCount[entry.key] = entry.value;
    }
    if (messageCountChanged) {
      bottomMessageTokensCount.q = nextMessageCount;
    }

    final Map<int, int> currentConversationCount = bottomConversationTokensCount.q;
    final Map<int, int> nextConversationCount = {};
    bool conversationCountChanged = false;
    for (final MapEntry<int, int> entry in currentConversationCount.entries) {
      if (targets.contains(entry.key)) {
        conversationCountChanged = true;
        continue;
      }
      nextConversationCount[entry.key] = entry.value;
    }
    if (conversationCountChanged) {
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
    final targetMessageId = siblingIds[newIndex];
    syncBottomDetailsExpandedBetweenMessages(
      sourceMessageId: msg.id,
      targetMessageId: targetMessageId,
    );
    parent.latest = parent.children[newIndex];
    ids.q = msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
  }
}
