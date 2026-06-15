import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/message.dart';

void main() {
  group('Message.getContentForEditing', () {
    test('returns visible answer for quick thinking content', () {
      const message = Message(
        id: 1,
        content: '<think>\n</think>\nanswer',
        isMine: false,
        paused: false,
        runningMode: '.Fast',
      );

      expect(message.getContentForEditing(), 'answer');
    });

    test('strips legacy fast thinking tail from assistant content', () {
      const message = Message(
        id: 2,
        content: '>\nanswer',
        isMine: false,
        paused: false,
        runningMode: '.Fast',
      );

      expect(message.getContentForEditing(), 'answer');
    });

    test('keeps non-fast leading greater-than content unchanged', () {
      const message = Message(
        id: 3,
        content: '> quoted answer',
        isMine: false,
        paused: false,
        runningMode: '.None',
      );

      expect(message.getContentForEditing(), '> quoted answer');
    });
  });
}
