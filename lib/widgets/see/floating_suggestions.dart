// ignore: unused_import
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
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

    final primary = Theme.of(context).colorScheme.primary;
    final qb = P.app.qb.q;
    final qw = P.app.qw.q;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const .symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (var item in suggestions)
            Padding(
              padding: const .only(right: 4),
              child: OutlinedButton(
                onPressed: () => P.see.onSuggestionTap(item),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  backgroundColor: Platform.isIOS ? qw.q(.9) : qw,
                  padding: const .symmetric(horizontal: 10, vertical: 0),
                  visualDensity: .compact,
                  shape: RoundedRectangleBorder(borderRadius: .circular(6)),
                ),
                child: Text(
                  item,
                  style: TextStyle(fontSize: 14, color: qb, fontWeight: .w400),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
