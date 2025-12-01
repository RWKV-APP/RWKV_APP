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
      systemPrompt:
          'System: You are RWKV, a next-gen RNN chatbot developed by RWKV foundation. '
          'You are a helpful assistant. Today is {{date}}, {{day_of_week}}.',
    );
  }

  static PromptTemplate deserialize(String json) {
    var map = jsonDecode(json);
    String system = map['systemPrompt'] ?? '';
    if (system == '') {
      // system = PromptTemplate.empty().systemPrompt;
    }
    return PromptTemplate(
      thinkingWithChinese: map['thinkingWithChinese'] ?? '',
      thinkingLighting: map['thinkingLighting'] ?? '',
      thinkingFast: map['thinkingFast'] ?? '',
      thinkingFree: map['thinkingFree'] ?? '',
      newChatTemplate: map['newChatTemplate'] ?? '',
      webSearchTemplate: map['webSearchTemplate'] ?? '',
      webSearchChineseTemplate: map['webSearchChineseTemplate'] ?? '',
      systemPrompt: system,
    );
  }

  String formatedSystemPrompt({
    bool chinese = false,
  }) {
    if (systemPrompt.isEmpty) return '';

    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    final time = '${now.hour}:${now.minute}';
    final dayOfWeek = now.weekday;

    final chinese = P.preference.currentLangIsZh.q;
    final cn =
        {
          1: "星期一",
          2: "星期二",
          3: "星期三",
          4: "星期四",
          5: "星期五",
          6: "星期六",
          7: "星期日",
        }[dayOfWeek] ??
        '';
    final en =
        {
          1: 'Monday',
          2: 'Tuesday',
          3: 'Wednesday',
          4: 'Thursday',
          5: 'Friday',
          6: 'Saturday',
          7: 'Sunday',
        }[dayOfWeek] ??
        '';

    String p = systemPrompt;
    p = p.replaceAll('{{date}}', date);
    p = p.replaceAll('{{time}}', time);
    p = p.replaceAll('{{day_of_week}}', chinese ? cn : en);
    return p;
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
