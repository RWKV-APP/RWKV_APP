// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/store/p.dart';

class ThinkingModeButton extends ConsumerWidget {
  const ThinkingModeButton({super.key});

  void _onTap() {
    P.rwkv.onThinkModeTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final loading = ref.watch(P.rwkv.loading);
    final qw = ref.watch(P.app.qw);
    final thinkingMode = ref.watch(P.rwkv.thinkingMode);

    final color = switch (thinkingMode) {
      thinking_mode.Lighting() => theme.colorScheme.surfaceContainer,
      thinking_mode.Fast() => theme.colorScheme.surfaceContainer,
      thinking_mode.None() => theme.colorScheme.surfaceContainer,
      thinking_mode.Free() => primary,
      thinking_mode.PreferChinese() => primary,
      thinking_mode.En() => primary,
      thinking_mode.EnShort() => theme.colorScheme.surfaceContainer,
      thinking_mode.EnLong() => primary,
    };

    final textColor = switch (thinkingMode) {
      thinking_mode.Lighting() => primary,
      thinking_mode.Fast() => primary,
      thinking_mode.None() => Colors.grey,
      thinking_mode.PreferChinese() => theme.colorScheme.onPrimary,
      thinking_mode.Free() => theme.colorScheme.onPrimary,
      thinking_mode.En() => theme.colorScheme.onPrimary,
      thinking_mode.EnShort() => primary,
      thinking_mode.EnLong() => theme.colorScheme.onPrimary,
    };

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    final padding = const EI.s(h: 8);

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

    final border = switch (thinkingMode) {
      thinking_mode.Lighting() => Border.all(color: textColor),
      thinking_mode.None() => null,
      thinking_mode.Free() => Border.all(color: textColor),
      thinking_mode.PreferChinese() => Border.all(color: textColor),
      thinking_mode.Fast() => Border.all(color: textColor),
      thinking_mode.En() => Border.all(color: textColor),
      thinking_mode.EnShort() => Border.all(color: textColor),
      thinking_mode.EnLong() => Border.all(color: textColor),
    };

    return AnimatedSize(
      key: const Key("_ThinkingModeButton"),
      duration: 150.ms,
      curve: Curves.easeOutCubic,
      child: IntrinsicWidth(
        child: AnimatedOpacity(
          opacity: loading ? .33 : 1,
          duration: 250.ms,
          child: GestureDetector(
            onTap: _onTap,
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
                    Icon(Icons.lightbulb_outline, color: textColor, size: 18),
                    2.w,
                    T(
                      text,
                      s: TS(c: textColor, s: 14, height: 1, w: FontWeight.w500),
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
