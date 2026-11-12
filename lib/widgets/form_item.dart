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
    final style = ref.watch(P.preference.appStyle);
    final qb = ref.watch(P.app.qb);
    final radius = Radius.circular(style.radius);
    final corners = BorderRadius.vertical(
      top: isSectionStart ? radius : .zero,
      bottom: isSectionEnd ? radius : .zero,
    );
    final surface = style.box(appTheme, corners);
    final titleStyle = style.isClassic
        ? TextStyle(fontWeight: .w500, fontSize: 16, color: titleColor ?? theme.colorScheme.onSurface)
        : theme.textTheme.titleMedium?.copyWith(color: titleColor ?? theme.colorScheme.onSurface);
    final info = infoText;
    final stackedInfo =
        !style.isClassic &&
            subtitle == null &&
            trailing == null &&
            MediaQuery.sizeOf(context).width < 520 &&
            MediaQuery.textScalerOf(context).scale(12) > 14.4
        ? info
        : null;
    final detailStyle = TextStyle(fontWeight: .w500, fontSize: 12, color: appTheme.qb6);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: isSectionStart && isSectionEnd ? surface : surface.copyWith(boxShadow: const [], border: const Border()),
            padding: .symmetric(horizontal: style.rowInset, vertical: style.rowPadding),
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
                            style: titleStyle,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: detailStyle,
                            ),
                          if (stackedInfo != null) ...[
                            const SizedBox(height: 2),
                            Text(stackedInfo, style: detailStyle),
                          ],
                        ],
                      ),
                    ),
                    if (info != null && stackedInfo == null)
                      Expanded(
                        flex: 2,
                        child: Text(
                          info,
                          style: detailStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ?infoWidget,
                    if (!showArrow && info != null && stackedInfo == null) const SizedBox(width: 4),
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
