part of 'p.dart';

class _Conversation {
  final conversations = qs<List<ConversationData>>([]);

  final currentCreatedAtUS = qs<int?>(null);

  final interactingCreatedAtUS = qs<int?>(null);
}

/// Private methods
extension _$Conversation on _Conversation {
  FV _init() async {
    await load();
  }

  FV _syncNode() async {
    qq;

    final msgNode = P.msg.msgNode.q;
    final db = P.app._db;

    if (msgNode.isEmpty) {
      qqq("msgNode is empty, skip upsert");
      return;
    }

    await db.upsertConv(msgNode);
    await load();
  }

  Future<Set<int>> _getAllMsgIdsFromConv(int createAtInUS) async {
    final db = P.app._db;
    final msgDataList = await db.findConvByCreateAtInUS(createAtInUS);
    if (msgDataList == null) return {};
    final msgNode = MsgNode.fromJson(msgDataList.data, createAtInUS: createAtInUS);
    final ids = msgNode.allMsgIdsFromRoot;
    return ids;
  }
}

/// Public methods
extension $Conversation on _Conversation {
  FV load() async {
    final db = P.app._db;
    final list = await db.convPage();
    qqq("${list.length}");
    conversations.q = list;
  }

  FV delete(int createAtInUS) async {
    final db = P.app._db;
    await db.deleteConv(createAtInUS);
    await load();

    _getAllMsgIdsFromConv(createAtInUS).then((ids) async {
      await db.deleteMsgsByCreateAtInUS(ids);
    });

    if (currentCreatedAtUS.q == createAtInUS) {
      currentCreatedAtUS.q = null;
      Pager.toggle();
      if (checkModelSelection(showModelSelector: false, showAlert: false)) {
        P.chat.startNewChat();
      }
    }
  }

  FV onTapInList(ConversationData conversation) async {
    qq;
    currentCreatedAtUS.q = conversation.createdAtUS;
    Pager.toggle();
    final msgNode = MsgNode.fromJson(
      conversation.data,
      createAtInUS: conversation.createdAtUS,
    );
    final ids = msgNode.latestMsgIdsWithoutRoot;
    await P.msg._loadMessages(ids);
    P.msg.msgNode.q = msgNode;
    P.msg.ids.q = ids;
    P.msg._loadMessages(msgNode.allMsgIdsFromRoot);
  }
}
