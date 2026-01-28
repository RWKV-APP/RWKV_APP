import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
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
  }) : assert(infoText == null || infoWidget == null, "infoText and infoWidget cannot be provided at the same time");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Minimalist colors
    final itemBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final separatorColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final titleTextColor = titleColor ?? (isDark ? Colors.white : Colors.black);
    final subtitleColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final infoTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final arrowColor = isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: itemBgColor,
          borderRadius: .only(
            topLeft: isSectionStart ? 10.rr : .zero,
            topRight: isSectionStart ? 10.rr : .zero,
            bottomLeft: isSectionEnd ? 10.rr : .zero,
            bottomRight: isSectionEnd ? 10.rr : .zero,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (icon != null) icon!,
                  if (icon != null) 12.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        T(
                          title,
                          textAlign: titleTextAlign,
                          s: TS(w: .w500, s: 15, c: titleTextColor, height: 1.2),
                        ),
                        if (subtitle != null) 2.h,
                        if (subtitle != null)
                          T(
                            subtitle!,
                            s: TS(w: .w400, s: 12, c: subtitleColor, height: 1.2),
                          ),
                      ],
                    ),
                  ),
                  if (infoText != null)
                    T(
                      infoText,
                      s: TS(w: .w400, s: 14, c: infoTextColor),
                    ),
                  if (infoWidget != null) infoWidget!,
                  ?trailing,
                  if (showArrow) 6.w,
                  if (showArrow)
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: arrowColor,
                    ),
                ],
              ),
            ),
            // Separator line (inset style like iOS)
            if (autoShowBottomBorder && !isSectionEnd)
              Padding(
                padding: EdgeInsets.only(left: icon != null ? 44 : 16),
                child: Container(
                  height: 0.5,
                  color: separatorColor,
                ),
              ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
