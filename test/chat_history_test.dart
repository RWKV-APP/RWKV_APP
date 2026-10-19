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

    test('keeps the first answer character after a closed thinking tag', () {
      final answer = '# ' + List<String>.filled(201, 'a').join();
      for (final separator in <String>['', '\n']) {
        final message = Message(
          id: 2,
          content: '<think>reasoning</think>$separator$answer',
          isMine: false,
          paused: false,
        );

        expect(message.getHistoryContent(), answer);
      }
    });

    test('preserves the existing short-answer thinking threshold', () {
      for (final length in <int>[0, 1, 200, 201]) {
        final answer = List<String>.filled(length, 'a').join();
        final content = '<think>reasoning</think>$answer';
        final message = Message(id: 2, content: content, isMine: false, paused: false);

        expect(message.getHistoryContent(), length <= 200 ? content : answer);
      }
    });

    test('preserves paused, incomplete and empty-thinking history policy', () {
      final answer = List<String>.filled(201, 'a').join();
      final paused = Message(
        id: 2,
        content: '<think>reasoning</think>$answer',
        isMine: false,
        paused: true,
      );
      final incomplete = Message(id: 4, content: '<think>$answer', isMine: false, paused: false);
      final emptyThinking = Message(
        id: 6,
        content: '<think>\n</think>$answer',
        isMine: false,
        paused: false,
      );

      for (final message in <Message>[paused, incomplete, emptyThinking]) {
        expect(message.getHistoryContent(), message.content);
      }
    });

    test('uses the same complete assistant history before the next user turn', () {
      final answer = '# ' + List<String>.filled(201, 'a').join() + ' \n';
      final messages = <Message>[
        Message(id: 1, content: _storedUserContent('first question'), isMine: true, paused: false),
        Message(id: 2, content: '<think></think>$answer', isMine: false, paused: false),
      ];

      final completedHistory = buildChatHistory(messages: messages, newChatTemplate: '');
      final nextHistory = buildChatHistory(
        messages: <Message>[
          ...messages,
          Message(id: 3, content: _storedUserContent('follow-up'), isMine: true, paused: false),
          const Message(id: 4, content: '', isMine: false, paused: false),
        ],
        newChatTemplate: '',
        excludedMessageId: 4,
      );

      expect(completedHistory, <String>['first question', answer]);
      expect(nextHistory, <String>['first question', answer, 'follow-up']);
      expect(nextHistory.take(completedHistory.length), completedHistory);
    });
  });
}
