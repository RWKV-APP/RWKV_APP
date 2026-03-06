// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/input_interactions.dart';

class WebSearchModeButton extends ConsumerWidget {
  const WebSearchModeButton({super.key});

  void _onTap() {
    P.chat.onWebSearchModeTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    final loading = ref.watch(P.rwkv.loading);
    final loaded = ref.watch(P.rwkv.loaded);
    final generating = ref.watch(P.rwkv.generating);
    final webSearchMode = ref.watch(P.chat.webSearchMode);

    final canEnable = loaded && !loading && !generating;
    final interactionState = switch ((canEnable, webSearchMode)) {
      (false, _) => InteractionVisualState.unavailable,
      (true, .off) => InteractionVisualState.idleInteractive,
      (true, .search) => InteractionVisualState.available,
      (true, .deepSearch) => InteractionVisualState.enabled,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final color = colors.background;
    final textColor = colors.foreground;
    final borderColor = colors.border;
    final actionColor = textColor;
    final backgroundColor = color;
    final actionBorderColor = borderColor;
    final showDeepLabel = webSearchMode == .deepSearch;
    final deepLabel = currentLangIsZh ? "深度" : "Deep";
    final userBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigmaForBackdropFilterForInputOptions = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);

    final height = InputInteractions.calculateButtonHeight(context);
    const padding = EdgeInsets.symmetric(horizontal: 8);
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
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor.q(
                  userBackdropFilterForInputOptions
                      ? backdropFilterBgAlphaForInputOptions * backdropFilterBgAlphaForInputOptionsDarkModifier
                      : 1,
                ),
                borderRadius: .circular(60),
                border: .all(color: actionBorderColor),
              ),
              child: Row(
                children: [
                  Icon(Symbols.travel_explore, color: actionColor, size: 18),
                  if (showDeepLabel) ...[
                    const SizedBox(width: 2),
                    Text(
                      deepLabel,
                      style: TS(c: actionColor, s: fontSize, height: 1, w: .w500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
