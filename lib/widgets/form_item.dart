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
    final customTheme = ref.watch(P.app.customTheme);
    final qb = ref.watch(P.app.qb);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: customTheme.settingItem,
          borderRadius: .only(
            topLeft: isSectionStart ? 12.rr : .zero,
            topRight: isSectionStart ? 12.rr : .zero,
            bottomLeft: isSectionEnd ? 12.rr : .zero,
            bottomRight: isSectionEnd ? 12.rr : .zero,
          ),
          border: Border(
            bottom: (autoShowBottomBorder && !isSectionEnd)
                ? BorderSide(
                    color: qb.q(.1),
                    width: .5,
                  )
                : BorderSide.none,
          ),
        ),
        padding: const .only(left: 8, top: 12, right: 8, bottom: 12),
        child: Column(
          children: [
            Row(
              children: [
                ?icon,
                if (icon != null) 8.w,
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        title,
                        textAlign: titleTextAlign,
                        style: TS(w: .w500, s: 16, c: titleColor),
                      ),
                      if (subtitle != null)
                        Opacity(
                          opacity: 0.5,
                          child: Text(
                            subtitle!,
                            style: const TS(w: .w500, s: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                if (infoText != null)
                  Expanded(
                    flex: 2,
                    child: Text(
                      infoText ?? "null",
                      style: const TS(w: .w500, s: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ?infoWidget,
                if (!showArrow && infoText != null) 4.w,
                ?trailing,
                if (showArrow) 8.w,
                if (showArrow)
                  const Icon(
                    Icons.chevron_right,
                  ),
              ],
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
