// Dart imports:

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/wenyan_mode.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/input_interactions.dart';

class WenYanWenButton extends ConsumerWidget {
  const WenYanWenButton({super.key});

  void _onTap() {
    P.chat.onWenYanWenTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final mode = ref.watch(P.chat.wenYanWen);
    final model = ref.watch(P.rwkv.latestModel);
    final loading = ref.watch(P.rwkv.loading);
    final generating = ref.watch(P.rwkv.generating);

    final height = InputInteractions.calculateButtonHeight(context);
    final canEnable = model != null && !loading && !generating;
    final interactionState = switch ((canEnable, mode)) {
      (false, _) => InteractionVisualState.unavailable,
      (true, WenyanMode.off) => InteractionVisualState.idleInteractive,
      (true, WenyanMode.classic) => InteractionVisualState.available,
      (true, WenyanMode.mixed) => InteractionVisualState.enabled,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final bgColor = colors.background;
    final textColor = colors.foreground;
    final borderColor = colors.border;
    final userBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigmaForBackdropFilterForInputOptions = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);
    final label = switch (mode) {
      WenyanMode.off => "文言",
      WenyanMode.classic => "文言",
      WenyanMode.mixed => "古今",
    };

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
        child: ClipRRect(
          borderRadius: .circular(60),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sigmaForBackdropFilterForInputOptions.toDouble(),
              sigmaY: sigmaForBackdropFilterForInputOptions.toDouble(),
            ),
            enabled: userBackdropFilterForInputOptions,
            child: Container(
              height: height,
              padding: const .symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: bgColor.q(
                  userBackdropFilterForInputOptions
                      ? backdropFilterBgAlphaForInputOptions * backdropFilterBgAlphaForInputOptionsDarkModifier
                      : 1,
                ),
                borderRadius: .circular(60),
                border: .all(color: borderColor, width: 1),
              ),
              alignment: .center,
              child: Text(
                label,
                style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
