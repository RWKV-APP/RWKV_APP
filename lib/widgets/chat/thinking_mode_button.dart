// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';

class ThinkingModeButton extends ConsumerWidget {
  const ThinkingModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final loading = ref.watch(P.rwkv.loading);
    final generating = ref.watch(P.rwkv.generating);
    final loaded = ref.watch(P.rwkv.loaded);
    final thinkingMode = ref.watch(P.rwkv.thinkingMode);

    final canEnable = loaded && !loading && !generating;
    final interactionState = switch (thinkingMode) {
      .free => canEnable ? InteractionVisualState.enabled : InteractionVisualState.unavailable,
      .en => canEnable ? InteractionVisualState.enabled : InteractionVisualState.unavailable,
      .enShort => canEnable ? InteractionVisualState.enabled : InteractionVisualState.unavailable,
      .enLong => canEnable ? InteractionVisualState.enabled : InteractionVisualState.unavailable,
      .none => canEnable ? InteractionVisualState.available : InteractionVisualState.unavailable,
      .fast => canEnable ? InteractionVisualState.available : InteractionVisualState.unavailable,
      .lighting => canEnable ? InteractionVisualState.available : InteractionVisualState.unavailable,
      .preferChinese => canEnable ? InteractionVisualState.available : InteractionVisualState.unavailable,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final color = colors.background;
    final textColor = colors.foreground;
    final border = Border.all(color: colors.border);

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(fontSize) + 20;
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
                      style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
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
