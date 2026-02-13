// ignore: unused_import
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/interactions.dart';

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

    return SizedBox(
      height: InputInteractions.calculateButtonHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const .only(left: 12, right: 12, bottom: 0),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return GD(
            onTap: () => P.see.onSuggestionTap(item),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: .circular(1000),
                border: .all(color: appTheme.qb11),
              ),
              padding: const .symmetric(horizontal: 12, vertical: 0),
              child: Center(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: appTheme.qb4,
                    fontWeight: .w400,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemCount: suggestions.length,
      ),
    );
  }
}
