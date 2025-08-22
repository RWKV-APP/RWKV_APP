// ignore: unused_import
import 'dart:convert';
import 'dart:io';

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

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final primary = Theme.of(context).colorScheme.primary;
    final qb = P.app.qb.q;
    final qw = P.app.qw.q;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (var item in suggestions)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: OutlinedButton(
                onPressed: () => _onSuggestionTap(item),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  backgroundColor: Platform.isIOS ? qw.q(.9) : qw,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(
                  item,
                  style: TextStyle(fontSize: 14, color: qb, fontWeight: FontWeight.w400),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
