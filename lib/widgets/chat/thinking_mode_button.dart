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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final loading = ref.watch(P.rwkv.loading);
    ref.watch(P.app.qw);
    final thinkingMode = ref.watch(P.rwkv.thinkingMode);

    final color = switch (thinkingMode) {
      .lighting => theme.colorScheme.surfaceContainer,
      .fast => theme.colorScheme.surfaceContainer,
      .none => theme.colorScheme.surfaceContainer,
      .free => primary,
      .preferChinese => primary,
      .en => primary,
      .enShort => theme.colorScheme.surfaceContainer,
      .enLong => primary,
    };

    final textColor = switch (thinkingMode) {
      .lighting => primary,
      .fast => primary,
      .none => Colors.grey,
      .preferChinese => theme.colorScheme.onPrimary,
      .free => theme.colorScheme.onPrimary,
      .en => theme.colorScheme.onPrimary,
      .enShort => primary,
      .enLong => theme.colorScheme.onPrimary,
    };

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    const EdgeInsets padding = .symmetric(horizontal: 8);

    final text = switch (thinkingMode) {
      .lighting => s.thinking_mode_auto(""),
      .none => s.thinking_mode_off(""),
      .free => s.thinking_mode_high(""),
      .preferChinese => s.thinking_mode_high(""),
      .fast => s.think_button_mode_fast(""),
      .en => s.think_button_mode_en(""),
      .enShort => s.think_button_mode_en_short(""),
      .enLong => s.think_button_mode_en_long(""),
    };

    final Border? border = switch (thinkingMode) {
      .lighting => .all(color: textColor),
      .none => null,
      .free => .all(color: textColor),
      .preferChinese => .all(color: textColor),
      .fast => .all(color: textColor),
      .en => .all(color: textColor),
      .enShort => .all(color: textColor),
      .enLong => .all(color: textColor),
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
            onTap: P.rwkv.onThinkModeTapped,
            child: SizedBox(
              height: height,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: .circular(60),
                  border: border,
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: textColor, size: 18),
                    const SizedBox(width: 2),
                    Text(
                      text,
                      style: TS(c: textColor, s: 14, height: 1, w: .w500),
                    ),
                    const SizedBox(width: 4),
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
