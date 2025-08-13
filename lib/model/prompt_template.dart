import 'dart:convert';

import 'package:zone/model/thinking_mode.dart';

class PromptTemplate {
  final String thinkingWithChinese;
  final String thinkingLighting;
  final String thinkingFree;
  final String newChatTemplate;
  final String webSearchTemplate;
  final String webSearchChineseTemplate;
  final String systemPrompt;

  PromptTemplate({
    required this.thinkingWithChinese,
    required this.thinkingLighting,
    required this.thinkingFree,
    required this.newChatTemplate,
    required this.webSearchTemplate,
    required this.webSearchChineseTemplate,
    required this.systemPrompt,
  });

  factory PromptTemplate.empty() {
    return PromptTemplate(
      thinkingWithChinese: '<think>嗯',
      thinkingLighting: '<think>\n</think>',
      thinkingFree: '<think',
      newChatTemplate: ' ',
      webSearchTemplate: '%s\nPlease answer according to the above information:\n%s',
      webSearchChineseTemplate: '%s\n请根据以上信息回答:\n%s',
      systemPrompt: ' ',
    );
  }

  static PromptTemplate deserialize(String json) {
    var map = jsonDecode(json);
    return PromptTemplate(
      thinkingWithChinese: map['thinkingWithChinese'] ?? '',
      thinkingLighting: map['thinkingLighting'] ?? '',
      thinkingFree: map['thinkingFree'] ?? '',
      newChatTemplate: map['newChatTemplate'] ?? '',
      webSearchTemplate: map['webSearchTemplate'] ?? '',
      webSearchChineseTemplate: map['webSearchChineseTemplate'] ?? '',
      systemPrompt: map['systemPrompt'] ?? '',
    );
  }

  String apply(ThinkingMode mode) {
    switch (mode) {
      case Lighting():
        return thinkingLighting.isNotEmpty ? thinkingLighting : mode.header;
      case Free():
        return thinkingFree.isNotEmpty ? thinkingFree : mode.header;
      case PreferChinese():
        return thinkingWithChinese.isNotEmpty ? thinkingWithChinese : mode.header;
      case None():
        return mode.header;
    }
  }

  String serialize() {
    return jsonEncode({
      "thinkingWithChinese": thinkingWithChinese,
      "thinkingLighting": thinkingLighting,
      "thinkingFree": thinkingFree,
      "newChatTemplate": newChatTemplate,
      "webSearchTemplate": webSearchTemplate,
      "webSearchChineseTemplate": webSearchChineseTemplate,
      "systemPrompt": systemPrompt,
    });
  }
}
