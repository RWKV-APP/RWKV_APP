import 'dart:convert';
import 'dart:developer';

import 'package:halo_state/halo_state.dart';
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/store/p.dart';

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
      thinkingWithChinese: '',
      thinkingLighting: '<think>\n</think>',
      thinkingFree: '<think',
      newChatTemplate: '',
      webSearchTemplate: '%s\nPlease answer according to the above information:\n%s',
      webSearchChineseTemplate: '%s\n请根据以上信息回答:\n%s',
      systemPrompt: '',
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
        return thinkingLighting.isNotEmpty ? thinkingLighting : Lighting().header;
      case Free():
        return thinkingFree.isNotEmpty ? thinkingFree : Free().header;
      case PreferChinese():
        final fileInfo = P.rwkv.currentModel.q;
        final date = fileInfo?.date;
        if (date != null && date.isAfter(DateTime(2025, 9, 21))) {
          final result = thinkingWithChinese.isNotEmpty ? thinkingWithChinese : "<think>好的";
          return result;
        }
        return thinkingWithChinese.isNotEmpty ? thinkingWithChinese : PreferChinese().header;
      case None():
        return None().header;
      case En():
        return En().header;
      case EnShort():
        return EnShort().header;
      case EnLong():
        return EnLong().header;
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
