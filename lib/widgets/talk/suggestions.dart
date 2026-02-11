// ignore: unused_import
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/func/is_chinese.dart';
import 'package:zone/store/p.dart';

class Suggestions extends ConsumerWidget {
  static const defaultHeight = 46.0;

  const Suggestions({super.key});

  void _onSuggestionTap(String suggestion) {
    P.suggestion.ttsTicker.q += 1;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(P.suggestion.talkSuggestion);
    final appTheme = ref.watch(P.app.theme);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final qb = P.app.qb.q;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const .symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (var item in suggestions)
            Padding(
              padding: const .only(right: 4),
              child: GD(
                onTap: () => _onSuggestionTap(item),
                child: Container(
                  decoration: BoxDecoration(
                    color: appTheme.scaffoldBg,
                    borderRadius: .circular(8),
                    border: .all(color: qb.q(.3), width: .5),
                  ),
                  padding: const .symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    item,
                    style: TextStyle(color: qb.q(.9)),
                  ),
                ),
              ),
            ),
        ].widgetJoin((index) => const SizedBox(width: 2)),
      ),
    );
  }
}
