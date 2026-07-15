import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/vision_system_prompt.dart';

void main() {
  test('sets the algorithm system prompt only for Chinese VL user input', () {
    expect(visionSystemPromptForUserInput("请描述这张图片"), "$visionChineseSystemPrompt\n\n");
    expect(visionSystemPromptForUserInput("Please describe this image"), isEmpty);
  });

  test('detects the user text without treating a Chinese image path as input', () {
    expect(visionSystemPromptForUserInput("<image>/tmp/中文图片.jpg</image>Please describe this image"), isEmpty);
    expect(
      visionSystemPromptForUserInput("<image>/tmp/image.jpg</image>请描述这张图片"),
      "$visionChineseSystemPrompt\n\n",
    );
  });
}
