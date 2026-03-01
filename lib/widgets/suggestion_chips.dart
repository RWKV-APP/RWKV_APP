// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo/halo.dart';

class SuggestionChips extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: listPadding,
        itemBuilder: (BuildContext context, int index) {
          final String item = suggestions[index];
          return GD(
            onTap: () {
              onTap(item);
            },
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: backgroundColor,
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
