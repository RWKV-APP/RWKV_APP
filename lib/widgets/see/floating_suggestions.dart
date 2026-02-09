// ignore: unused_import
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/store/p.dart';

class FloatingSuggestions extends ConsumerWidget {
  static const defaultHeight = 46.0;

  const FloatingSuggestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(P.suggestion.worldSuggestion);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final chipBg = Platform.isIOS ? colorScheme.surface.q(.95) : colorScheme.surface;
    final chipBorder = colorScheme.outline.q(.22);
    final chipText = colorScheme.onSurface.q(.88);

    return SizedBox(
      height: defaultHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const .only(left: 12, right: 12, top: 8, bottom: 0),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return OutlinedButton(
            onPressed: () => P.see.onSuggestionTap(item),
            style: TextButton.styleFrom(
              foregroundColor: chipText,
              backgroundColor: chipBg,
              padding: const .symmetric(horizontal: 12, vertical: 0),
              visualDensity: .compact,
              side: BorderSide(color: chipBorder),
              shape: RoundedRectangleBorder(borderRadius: .circular(10)),
            ),
            child: Text(
              item,
              style: TextStyle(fontSize: 14, color: chipText, fontWeight: .w400),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemCount: suggestions.length,
      ),
    );
  }
}
