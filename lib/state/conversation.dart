part of 'p.dart';

class _Conversation {
  final conversations = qs<List<ConversationData>>([]);

  final currentCreatedAtUS = qs<int?>(null);
}

/// Private methods
extension _$Conversation on _Conversation {
  FV _init() async {
    await load();
  }

  FV _syncNode() async {
    qq;

    final msgNode = P.msg.msgNode.q;

    if (msgNode.isEmpty) {
      qqq("msgNode is empty, skip upsert");
      return;
    }

    await P.db._db.upsertConv(msgNode);
    await load();
  }
}

/// Public methods
extension $Conversation on _Conversation {
  FV load() async {
    final list = await P.db._db.convPage();
    qqq("${list.length}");
    conversations.q = list;
  }

  FV delete(int createAtInUS) async {
    await P.db._db.deleteConv(createAtInUS);
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
