part of 'p.dart';

class _Conversation {
  final conversations = qs<List<ConversationData>>([]);

  final current = qs<ConversationData?>(null);
}

/// Private methods
extension _$Conversation on _Conversation {
  FV _init() async {
    await load();
  }

  FV _syncNode() async {
    qq;
    await P.db._db.syncConv(P.msg._msgNode);
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
    current.q = conversation;
    Pager.toggle();
  }
}
