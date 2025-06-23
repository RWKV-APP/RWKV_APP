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

  /// 将 conversation 导出为 .txt 文件
  ///
  /// 文件格式如下
  ///
  /// Title
  ///
  /// 创建时间: 2025-01-01 12:00:00
  ///
  /// 更新时间: 2025-01-01 12:00:00
  ///
  /// 消息内容
  ///
  /// 直接使用 ConversationData 转成的 [MsgNode] 的 [MsgNode.allMsgIdsFromRoot] 作为要获取的消息
  ///
  /// 然后根据这些 ID 查询消息
  ///
  /// 渲染消息的格式为:
  ///
  /// User:
  ///
  /// context
  ///
  /// Assistant:
  ///
  /// context
  FV onExportClicked(BuildContext context, ConversationData conversation) async {
    final s = S.of(context);
    try {
      // 1. 从ConversationData转成MsgNode获取所有消息ID
      final msgNode = MsgNode.fromJson(
        conversation.data,
        createAtInUS: conversation.createdAtUS,
      );
      final allMsgIds = msgNode.allMsgIdsFromRoot;

      if (allMsgIds.isEmpty) {
        Alert.warning(s.no_message_to_export);
        return;
      }

      // 2. 从数据库查询所有消息
      final db = P.app._db;
      final messages = await db.getMessagesByIds(allMsgIds);

      // 3. 按照消息树的顺序排序消息
      final orderedMessages = <Message>[];
      final messageMap = {for (var msg in messages) msg.id: msg};

      // 使用深度优先遍历获取正确的消息顺序
      void traverseNode(MsgNode node) {
        if (node.id != 0 && messageMap.containsKey(node.id)) {
          orderedMessages.add(messageMap[node.id]!);
        }
        for (var child in node.children) {
          traverseNode(child);
        }
      }

      traverseNode(msgNode);

      // 4. 格式化时间
      String formatTime(int? timeUS) {
        if (timeUS == null) return s.unknown;
        final dateTime = DateTime.fromMicrosecondsSinceEpoch(timeUS);
        return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
      }

      // 5. 构建文件内容
      final buffer = StringBuffer();
      buffer.writeln(s.export_title);
      buffer.writeln();
      buffer.writeln(conversation.title);
      buffer.writeln();
      buffer.writeln("${s.created_at}: ${formatTime(conversation.createdAtUS)}");
      buffer.writeln();
      buffer.writeln("${s.updated_at}: ${formatTime(conversation.updatedAtUS)}");
      buffer.writeln();
      buffer.writeln("${s.message_content}:");
      buffer.writeln();

      for (final message in orderedMessages) {
        if (message.isMine) {
          buffer.writeln(s.user);
          buffer.writeln();
          buffer.writeln(message.content);
        } else {
          buffer.writeln(s.assistant);
          buffer.writeln();
          buffer.writeln(message.content);
        }
        buffer.writeln();
      }

      // 6. 创建文件
      final Directory tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "${conversation.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_$timestamp.txt";
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(buffer.toString(), encoding: utf8);

      // 7. 分享文件
      final xFile = XFile(file.path, mimeType: 'text/plain');
      await Share.shareXFiles(
        [xFile],
        subject: conversation.title,
      );
    } catch (e) {
      qqe("Export conversation failed: $e");
      Alert.error(s.export_conversation_failed);
    }
  }
}
