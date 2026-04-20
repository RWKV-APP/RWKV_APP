import 'package:flutter_test/flutter_test.dart';
import 'package:zone/config.dart';
import 'package:zone/func/build_chat_history.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/message_type.dart';

String _storedUserContent(String content) {
  return content + Config.userMsgModifierSep;
}

void main() {
  group('buildChatHistory', () {
    test('excludes the current empty bot placeholder before inference', () {
      final history = buildChatHistory(
        messages: <Message>[
          Message(id: 1, content: _storedUserContent('hello'), isMine: true, paused: false),
          const Message(id: 2, content: '', isMine: false, paused: false),
        ],
        newChatTemplate: '',
        excludedMessageId: 2,
      );

      expect(history, const <String>['hello']);
      expect(history, everyElement(isNot(isEmpty)));
    });

    test('keeps the empty bot placeholder for callers that request raw history', () {
      final history = buildChatHistory(
        messages: <Message>[
          Message(id: 1, content: _storedUserContent('hello'), isMine: true, paused: false),
          const Message(id: 2, content: '', isMine: false, paused: false),
        ],
        newChatTemplate: '',
      );

      expect(history, const <String>['hello', '']);
    });

    test('keeps new-chat template behavior after excluding the placeholder', () {
      final history = buildChatHistory(
        messages: <Message>[
          Message(id: 1, content: _storedUserContent('hello'), isMine: true, paused: false),
          const Message(id: 2, content: '', isMine: false, paused: false),
        ],
        newChatTemplate: 'System prompt\n\nUser prompt',
        excludedMessageId: 2,
      );

      expect(history, const <String>['System prompt', 'User prompt']);
      expect(history, everyElement(isNot(isEmpty)));
    });

    test('ignores non-text messages', () {
      final history = buildChatHistory(
        messages: <Message>[
          const Message(id: 1, content: '', isMine: true, paused: false, type: MessageType.userImage),
          Message(id: 2, content: _storedUserContent('describe this'), isMine: true, paused: false),
        ],
        newChatTemplate: '',
      );

      expect(history, const <String>['describe this']);
    });
  });
}
