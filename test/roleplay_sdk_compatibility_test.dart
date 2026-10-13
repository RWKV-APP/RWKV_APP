import 'package:flutter_roleplay/services/rwkv_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Import the real service so nullable captures across await are type-checked.
  test('roleplay service compiles with the project Dart SDK', () {
    final service = RWKVChatService();
    expect(service.isGenerating.value, isFalse);
  });
}
