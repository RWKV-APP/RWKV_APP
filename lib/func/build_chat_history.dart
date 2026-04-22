// Project imports:
import 'package:zone/model/message.dart';
import 'package:zone/model/message_type.dart';

List<String> buildChatHistory({
  required Iterable<Message> messages,
  required String newChatTemplate,
  int? excludedMessageId,
}) {
  final textMessages = <Message>[];
  for (final Message msg in messages) {
    if (msg.type != MessageType.text) continue;
    if (excludedMessageId != null && msg.id == excludedMessageId) continue;
    textMessages.add(msg);
  }

  if (textMessages.isEmpty) return <String>[];

  if (textMessages.length == 1) {
    final template = newChatTemplate.trim();
    if (template.isNotEmpty) {
      return template.split("\n\n").where((String entry) => entry.isNotEmpty).toList();
    }
  }

  final result = <String>[];
  for (int i = 0; i < textMessages.length; i = i + 2) {
    final userMsg = textMessages[i];
    final botMsg = i + 1 < textMessages.length ? textMessages[i + 1] : null;

    final userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
    result.add(userContent);

    if (botMsg == null) continue;

    result.add(botMsg.getHistoryContent());
  }

  return result;
}
