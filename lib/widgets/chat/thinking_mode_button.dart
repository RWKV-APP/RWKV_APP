// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/store/p.dart';

class ThinkingModeButton extends ConsumerWidget {
  const ThinkingModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final loading = ref.watch(P.rwkv.loading);
    final thinkingMode = ref.watch(P.rwkv.thinkingMode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Design colors: light gray fill unselected, light yellow fill selected
    final lightGrayFill = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7);
    const darkGrayText = Color(0xFF636366);
    const yellowColor = Color(0xFFFFCC00); // Yellow for selected state
    // Light yellow for selected background (solid color, not transparency)
    final lightYellowFill = isDark ? const Color(0xFF3D3A2E) : const Color(0xFFFFF8E1);

    // Active modes use yellow, others use gray
    final isActive = switch (thinkingMode) {
      thinking_mode.Free() => true,
      thinking_mode.PreferChinese() => true,
      thinking_mode.En() => true,
      thinking_mode.EnLong() => true,
      thinking_mode.Lighting() => true,
      thinking_mode.Fast() => true,
      thinking_mode.EnShort() => true,
      _ => false,
    };

    final color = isActive ? lightYellowFill : lightGrayFill;
    final textColor = isActive ? (isDark ? yellowColor : const Color(0xFFB8860B)) : darkGrayText;

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(12) + 16;
    const EdgeInsets padding = .symmetric(horizontal: 6);

    final text = switch (thinkingMode) {
      thinking_mode.Lighting() => s.thinking_mode_auto(""),
      thinking_mode.None() => s.thinking_mode_off(""),
      thinking_mode.Free() => s.thinking_mode_high(""),
      thinking_mode.PreferChinese() => s.thinking_mode_high(""),
      thinking_mode.Fast() => s.think_button_mode_fast(""),
      thinking_mode.En() => s.think_button_mode_en(""),
      thinking_mode.EnShort() => s.think_button_mode_en_short(""),
      thinking_mode.EnLong() => s.think_button_mode_en_long(""),
    };

    final border = isActive ? Border.all(color: yellowColor.withOpacity(0.5)) : null;

    return AnimatedSize(
      key: const Key("_ThinkingModeButton"),
      duration: 150.ms,
      curve: Curves.easeOutCubic,
      child: IntrinsicWidth(
        child: AnimatedOpacity(
          opacity: loading ? .33 : 1,
          duration: 250.ms,
          child: GestureDetector(
            onTap: P.rwkv.onThinkModeTapped,
            child: SizedBox(
              height: height,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: 60.r,
                  border: border,
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: textColor, size: 14),
                    2.w,
                    T(
                      text,
                      s: TS(c: textColor, s: 12, height: 1, w: .w500),
                    ),
                    4.w,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
