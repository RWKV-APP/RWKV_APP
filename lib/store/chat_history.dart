part of 'p.dart';

extension $ChatHistory on _Chat {
  List<String> _history({int? excludedMessageId}) {
    return buildChatHistory(
      messages: P.msg.list.q,
      newChatTemplate: P.preference.promptTemplate.newChatTemplate,
      excludedMessageId: excludedMessageId,
    );
  }

  List<String>? _historyBeforeBotMessage({required int messageId}) {
    final MsgNode? targetNode = P.msg.msgNode.q.findNodeByMsgId(messageId);
    final MsgNode? parentNode = targetNode?.parent;
    if (targetNode == null || parentNode == null) {
      return null;
    }

    final List<int> idsFromTargetToRoot = P.msg.msgNode.q.msgIdsFrom(parentNode);
    final List<int> orderedPathIds = idsFromTargetToRoot.reversed.where((int id) => id != 0).toList();
    if (orderedPathIds.isEmpty) {
      return null;
    }

    final List<Message> scopedMessages = <Message>[];
    for (final int id in orderedPathIds) {
      final Message? pathMessage = P.msg.pool.q[id];
      if (pathMessage == null) {
        continue;
      }
      if (pathMessage.type != MessageType.text) {
        continue;
      }
      scopedMessages.add(pathMessage);
    }
    if (scopedMessages.isEmpty) {
      return null;
    }

    final List<String> history = <String>[];
    final bool isSingleTurnPath = scopedMessages.length == 1 && scopedMessages.first.isMine;
    if (isSingleTurnPath) {
      final String template = P.preference.promptTemplate.newChatTemplate.trim();
      if (template.isNotEmpty) {
        history.addAll(template.split("\n\n").where((String entry) => entry.isNotEmpty));
      }
    }

    for (int i = 0; i < scopedMessages.length; i = i + 2) {
      final Message userMsg = scopedMessages[i];
      final Message? botMsg = i + 1 < scopedMessages.length ? scopedMessages[i + 1] : null;

      final String userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
      history.add(userContent);

      if (botMsg == null) {
        continue;
      }
      history.add(botMsg.getHistoryContent());
    }

    return history;
  }
}
