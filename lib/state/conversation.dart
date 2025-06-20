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
    P.msg.msgNode.lv(_onMsgNodeChanged, fireImmediately: true);
  }

  FV _onMsgNodeChanged() async {
    qq;
    final createAtUS = P.msg.msgNode.q.createAtInUS;
    if (currentCreatedAtUS.q == createAtUS) {
      return;
    }
    currentCreatedAtUS.q = createAtUS;
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
    qqq(HF.microseconds);
    final db = P.app._db;
    final list = await db.convPage();
    qqq("${list.length}");
    conversations.q = list;
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

  FV onDeleteClicked(BuildContext context, ConversationData conversation) async {
    final s = S.of(context);
    final res = await showOkCancelAlertDialog(
      context: context,
      title: s.delete_conversation,
      message: s.delete_conversation_message,
      okLabel: s.delete,
      cancelLabel: s.cancel,
      isDestructiveAction: true,
    );

    if (res != OkCancelResult.ok) return;

    final db = P.app._db;
    final createAtInUS = conversation.createdAtUS;

    final allRelatedMsgIds = await _getAllMsgIdsFromConv(createAtInUS);
    final success = await db.deleteConv(createAtInUS);
    if (!success) {
      qqe("delete conversation failed");
      return;
    }
    await load();
    await db.deleteMsgsByCreateAtInUS(allRelatedMsgIds);
    P.msg.ids.q = [];
    P.msg.msgNode.q = MsgNode(0);
    P.msg._clear();

    if (currentCreatedAtUS.q == createAtInUS) {
      currentCreatedAtUS.q = null;
    }
  }

  FV onRenameClicked(BuildContext context, ConversationData conversation) async {
    final s = S.of(context);
    final currentTitle = conversation.title;
    final initialText = currentTitle.length > Config.maxTitleLength ? currentTitle.substring(0, Config.maxTitleLength) : currentTitle;
    final res = await showTextInputDialog(
      context: context,
      title: s.rename,
      textFields: [
        DialogTextField(
          initialText: initialText,
          hintText: s.please_enter_conversation_name,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return s.conversation_name_cannot_be_empty;
            }
            if (value.length > Config.maxTitleLength) {
              return s.conversation_name_cannot_be_longer_than_30_characters(Config.maxTitleLength);
            }
            return null;
          },
          maxLength: Config.maxTitleLength,
        ),
      ],
    );

    if (res == null || res.isEmpty) {
      return;
    }

    final db = P.app._db;
    final newTitle = res[0];
    final success = await db.renameConv(conversation.createdAtUS, newTitle);
    if (!success) return;
    await P.conversation.load();
  }

  FV onExportClicked(BuildContext context, ConversationData conversation) async {}
}
