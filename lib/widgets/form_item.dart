// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/store/p.dart';

class FormItem extends ConsumerWidget {
  final bool isSectionStart;
  final bool isSectionEnd;
  final bool autoShowBottomBorder;
  final String title;
  final String? infoText;
  final Widget? infoWidget;
  final VoidCallback? onTap;
  final bool showArrow;
  final TextAlign? titleTextAlign;
  final Widget? icon;
  final Color? titleColor;
  final String? subtitle;

  final Widget? trailing;

  final Widget? bottom;

  final double? bottomLineLeft;
  final double? bottomLineRight;
  final double? bottomLineHeight;
  final Color? bottomLineColor;

  const FormItem({
    super.key,
    required this.title,
    this.onTap,
    this.isSectionStart = false,
    this.isSectionEnd = false,
    this.infoText,
    this.infoWidget,
    this.icon,
    this.showArrow = true,
    this.autoShowBottomBorder = true,
    this.titleTextAlign,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.bottom,
    this.bottomLineLeft = 44,
    this.bottomLineRight = 0,
    this.bottomLineHeight = 0.5,
    this.bottomLineColor,
  }) : assert(infoText == null || infoWidget == null, "infoText and infoWidget cannot be provided at the same time");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: appTheme.settingItem,
              borderRadius: .only(
                topLeft: isSectionStart ? const Radius.circular(12) : .zero,
                topRight: isSectionStart ? const Radius.circular(12) : .zero,
                bottomLeft: isSectionEnd ? const Radius.circular(12) : .zero,
                bottomRight: isSectionEnd ? const Radius.circular(12) : .zero,
              ),
            ),
            padding: const .only(left: 8, top: 12, right: 8, bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    ?icon,
                    if (icon != null) const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            title,
                            textAlign: titleTextAlign,
                            style: TextStyle(fontWeight: .w500, fontSize: 16, color: titleColor ?? theme.colorScheme.onSurface),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(fontWeight: .w500, fontSize: 12, color: appTheme.qb6),
                            ),
                        ],
                      ),
                    ),
                    if (infoText != null)
                      Expanded(
                        flex: 2,
                        child: Text(
                          infoText ?? "null",
                          style: TextStyle(fontWeight: .w500, fontSize: 12, color: appTheme.qb6),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ?infoWidget,
                    if (!showArrow && infoText != null) const SizedBox(width: 4),
                    ?trailing,
                    if (showArrow) const SizedBox(width: 8),
                    if (showArrow)
                      Icon(
                        Icons.chevron_right,
                        color: appTheme.qb6,
                      ),
                  ],
                ),
                ?bottom,
              ],
            ),
          ),

          if (autoShowBottomBorder && !isSectionEnd)
            Positioned(
              bottom: 0,
              left: bottomLineLeft,
              right: bottomLineRight,
              height: bottomLineHeight,
              child: Container(
                height: bottomLineHeight,
                color: bottomLineColor ?? qb.withValues(alpha: .1),
              ),
            ),
        ],
      ),
    );
  }
}
