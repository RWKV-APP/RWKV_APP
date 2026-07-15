import 'package:zone/func/is_chinese.dart';

const String visionChineseSystemPrompt = "你是由RWKV开发的视觉语言模型，能够理解图像和文本的内容，并回答用户的问题。在回答问题时你应当使用和用户相同的语言。";

String visionSystemPromptForUserInput(String input) {
  final userText = input.replaceAll(RegExp(r"<image>.*?</image>"), "");
  if (!containsChineseCharacters(userText)) return "";
  return "$visionChineseSystemPrompt\n\n";
}
