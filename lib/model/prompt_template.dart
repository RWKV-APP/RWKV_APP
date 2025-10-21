import 'dart:convert';

import 'package:halo_state/halo_state.dart';
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/store/p.dart';

class PromptTemplate {
  final String thinkingWithChinese;
  final String thinkingLighting;
  final String thinkingFast;
  final String thinkingFree;
  final String newChatTemplate;
  final String webSearchTemplate;
  final String webSearchChineseTemplate;
  final String systemPrompt;

  PromptTemplate({
    required this.thinkingWithChinese,
    required this.thinkingLighting,
    required this.thinkingFast,
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
      thinkingFast: '<think>\n</think',
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
      thinkingFast: map['thinkingFast'] ?? '',
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
        return thinkingLighting.isNotEmpty ? thinkingLighting : const Lighting().header;
      case Fast():
        return thinkingFast.isNotEmpty ? thinkingFast : const Fast().header;
      case Free():
        return thinkingFree.isNotEmpty ? thinkingFree : const Free().header;
      case PreferChinese():
        final fileInfo = P.rwkv.currentModel.q;
        final date = fileInfo?.date;
        if (date != null && date.isAfter(DateTime(2025, 9, 21))) {
          final result = thinkingWithChinese.isNotEmpty ? thinkingWithChinese : "<think>好的";
          return result;
        }
        return thinkingWithChinese.isNotEmpty ? thinkingWithChinese : const PreferChinese().header;
      case None():
        return const None().header;
      case En():
        return const En().header;
      case EnShort():
        return const EnShort().header;
      case EnLong():
        return const EnLong().header;
    }
  }

  String serialize() {
    return jsonEncode({
      "thinkingWithChinese": thinkingWithChinese,
      "thinkingLighting": thinkingLighting,
      "thinkingFast": thinkingFast,
      "thinkingFree": thinkingFree,
      "newChatTemplate": newChatTemplate,
      "webSearchTemplate": webSearchTemplate,
      "webSearchChineseTemplate": webSearchChineseTemplate,
      "systemPrompt": systemPrompt,
    });
  }
}
