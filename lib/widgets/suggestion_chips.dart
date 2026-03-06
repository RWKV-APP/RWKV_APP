// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/store/p.dart';

class SuggestionChips extends ConsumerWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  final double height;
  final EdgeInsetsGeometry listPadding;
  final EdgeInsetsGeometry chipPadding;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double borderRadius;
  final double separatorWidth;

  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onTap,
    required this.height,
    required this.listPadding,
    required this.chipPadding,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.borderRadius = 1000,
    this.separatorWidth = 6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final bool userBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final double backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final double backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(
      P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier,
    );
    final double sigmaForBackdropFilterForInputOptions = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);
    final Color chipBackgroundColor = userBackdropFilterForInputOptions
        ? backgroundColor.q(
            backdropFilterBgAlphaForInputOptions * backdropFilterBgAlphaForInputOptionsDarkModifier,
          )
        : backgroundColor;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: .horizontal,
        padding: listPadding,
        itemBuilder: (BuildContext context, int index) {
          final item = suggestions[index];
          return GD(
            onTap: () {
              onTap(item);
            },
            child: ClipRRect(
              borderRadius: .circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: sigmaForBackdropFilterForInputOptions,
                  sigmaY: sigmaForBackdropFilterForInputOptions,
                ),
                enabled: userBackdropFilterForInputOptions,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: chipBackgroundColor,
                    borderRadius: .circular(borderRadius),
                    border: .all(color: borderColor),
                  ),
                  padding: chipPadding,
                  child: Center(
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(width: separatorWidth);
        },
        itemCount: suggestions.length,
      ),
    );
  }
}
