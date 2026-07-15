// Project imports:
import 'package:zone/model/message.dart';
import 'package:zone/model/msg_node.dart';

int? resolvePausedReplyGuidanceMessageId({
  required List<Message> messages,
  required int? dismissedMessageId,
}) {
  if (messages.isEmpty) return null;

  final message = messages.last;
  if (message.isMine || message.changing || !message.paused) return null;
  if (dismissedMessageId == message.id) return null;
  return message.id;
}

int? originalQuestionIndexForPausedReply({
  required List<Message> messages,
  required MsgNode rootNode,
  required int pausedReplyId,
}) {
  final pausedReplyNode = rootNode.findNodeByMsgId(pausedReplyId);
  final originalQuestionId = pausedReplyNode?.parent?.id;
  if (originalQuestionId == null) return null;

  final index = messages.indexWhere((Message message) => message.id == originalQuestionId && message.isMine);
  if (index < 0) return null;
  return index;
}
