// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';

class SecondaryOptionsButton extends ConsumerWidget {
  const SecondaryOptionsButton({super.key});

  void _onTap() {
    P.rwkv.onSecondaryOptionsTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final fontSize = theme.textTheme.bodySmall?.fontSize ?? 10;
    final appTheme = ref.watch(P.app.theme);
    final loading = ref.watch(P.rwkv.loading);
    final generating = ref.watch(P.rwkv.generating);
    final loaded = ref.watch(P.rwkv.loaded);
    final thinkingMode = ref.watch(P.rwkv.thinkingMode);

    final canEnable = loaded && !loading && !generating;
    final interactionState = switch (thinkingMode) {
      .preferChinese => canEnable ? InteractionVisualState.enabled : InteractionVisualState.unavailable,
      .free => canEnable ? InteractionVisualState.available : InteractionVisualState.unavailable,
      _ => InteractionVisualState.unavailable,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final color = colors.background;
    final textColor = colors.foreground;

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    const EdgeInsets padding = .symmetric(horizontal: 12);

    return AnimatedSize(
      key: const Key("_SecondaryOptionsButton"),
      duration: 150.ms,
      curve: Curves.easeOutCubic,
      child: IntrinsicWidth(
        child: AnimatedOpacity(
          opacity: loading ? .33 : 1,
          duration: 250.ms,
          child: GestureDetector(
            onTap: _onTap,
            child: AnimatedContainer(
              height: height,
              duration: 150.ms,
              curve: Curves.easeOutCubic,
              padding: padding,
              decoration: BoxDecoration(
                color: color,
                borderRadius: .circular(60),
                border: .all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.translate, color: textColor, size: appTheme.inputBarInteractionsIconSize),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: .start,
                    mainAxisAlignment: .center,
                    children: [
                      Text(
                        s.prefer,
                        style: TS(c: textColor, s: fontSize, height: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.chinese,
                        style: TS(c: textColor, s: fontSize, height: 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
