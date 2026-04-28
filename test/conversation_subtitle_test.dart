import 'package:flutter_test/flutter_test.dart';
import 'package:zone/config.dart';
import 'package:zone/func/conversation_subtitle.dart';

void main() {
  group('buildConversationSubtitleFromResponseContent', () {
    test('normalizes a single response', () {
      final subtitle = buildConversationSubtitleFromResponseContent('<think>\nreason</think>\n\nanswer\nline');

      expect(subtitle, 'reason answer line');
    });

    test('uses the first batch response before selection', () {
      final content = ['first answer', 'second answer'].join(Config.batchMarker) + Config.batchMarker + "-1";

      final subtitle = buildConversationSubtitleFromResponseContent(content);

      expect(subtitle, 'first answer');
    });

    test('uses the stored selected batch response', () {
      final content = ['first answer', 'second answer'].join(Config.batchMarker) + Config.batchMarker + "1";

      final subtitle = buildConversationSubtitleFromResponseContent(content);

      expect(subtitle, 'second answer');
    });

    test('uses the explicitly selected batch response', () {
      final content = ['first answer', 'second answer'].join(Config.batchMarker) + Config.batchMarker + "-1";

      final subtitle = buildConversationSubtitleFromResponseContent(content, selectedBatch: 1);

      expect(subtitle, 'second answer');
    });
  });
}
