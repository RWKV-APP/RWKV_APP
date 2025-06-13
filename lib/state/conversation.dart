part of 'p.dart';

class _Conversation {
  final conversations = qs<List<ConversationData>>([]);

  final current = qs<ConversationData?>(null);
}

/// Private methods
extension _$Conversation on _Conversation {
  FV _init() async {
    if (!Config.enableConversation) return;
    qq;
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
    conversations.q = await P.db._db.convPage();
  }

  FV delete(int createAtInUS) async {
    await P.db._db.deleteConv(createAtInUS);
  }

  FV onTapInList(ConversationData conversation) async {
    if (!Config.enableConversation) return;
    current.q = conversation;
    Pager.toggle();
  }
}
