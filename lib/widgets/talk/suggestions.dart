// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/func/is_chinese.dart';
import 'package:zone/func/widget_debugger.dart';
import 'package:zone/model/tts_instruction.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/interactions.dart';
import 'package:zone/widgets/suggestion_chips.dart';

class Suggestions extends ConsumerWidget {
  static const defaultHeight = 46.0;

  const Suggestions({super.key});

  void _onSuggestionTap(String suggestion) {
    P.suggestion.ttsTicker.q += 1;

    final String? intonation = _decodeIntonationSuggestion(suggestion);
    if (intonation != null) {
      _onIntonationTap(intonation);
      return;
    }

    final current = P.chat.textEditingController.text;
    if (current.isEmpty) {
      P.chat.textEditingController.text = suggestion;
      return;
    }

    final last = current.characters.last;
    final lastIsChinese = containsChineseCharacters(last);
    final lastIsEnglish = isEnglish(last);
    if (lastIsChinese) {
      P.chat.textEditingController.text = "$current。$suggestion";
    } else if (lastIsEnglish) {
      P.chat.textEditingController.text = "$current. $suggestion";
    } else {
      P.chat.textEditingController.text = "$current$suggestion";
    }
  }

  void _onIntonationTap(String intonation) {
    final controller = P.chat.textEditingController;
    final selection = controller.selection;
    final text = controller.text;
    if (!selection.isValid) {
      controller.text += intonation;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      P.app.hapticLight();
      return;
    }

    final String newText = text.replaceRange(selection.start, selection.end, intonation);
    final int newOffset = selection.start + intonation.length;
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: newOffset);
    P.app.hapticLight();
  }

  String? _decodeIntonationSuggestion(String suggestion) {
    final List<String> options = TTSInstruction.intonation.options;
    final List<String> emojis = TTSInstruction.intonation.emojiOptions;
    for (int index = 0; index < options.length; index += 1) {
      final String display = "${emojis[index]}${options[index]}";
      if (display != suggestion) continue;
      return options[index];
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(P.suggestion.talkSuggestion);
    final appTheme = ref.watch(P.app.theme);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SuggestionChips(
      suggestions: suggestions,
      onTap: _onSuggestionTap,
      height: InputInteractions.calculateButtonHeight(context),
      listPadding: const .only(left: 12, right: 12, bottom: 0),
      chipPadding: const .symmetric(horizontal: 12, vertical: 0),
      backgroundColor: appTheme.qb144,
      borderColor: appTheme.qb11,
      textColor: appTheme.qb4,
    );
  }
}
