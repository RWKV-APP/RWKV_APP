// ignore: unused_import
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/interactions.dart';
import 'package:zone/widgets/suggestion_chips.dart';

class FloatingSuggestions extends ConsumerWidget {
  static const defaultHeight = 40.0;

  const FloatingSuggestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(P.suggestion.worldSuggestion);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final appTheme = ref.watch(P.app.theme);
    final bgColor = appTheme.qb144;

    return SuggestionChips(
      suggestions: suggestions,
      onTap: (String item) => P.see.onSuggestionTap(item),
      height: InputInteractions.calculateButtonHeight(context),
      listPadding: const .only(left: 12, right: 12, bottom: 0),
      chipPadding: const .symmetric(horizontal: 12, vertical: 0),
      backgroundColor: bgColor,
      borderColor: appTheme.qb11,
      textColor: appTheme.qb4,
    );
  }
}
