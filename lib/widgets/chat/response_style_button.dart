// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/response_style.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/input_interactions.dart';

class ResponseStyleButton extends ConsumerWidget {
  const ResponseStyleButton({super.key});

  void _onTap() {
    P.chat.onResponseStyleTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final responseStyle = ref.watch(P.chat.responseStyle);
    final model = ref.watch(P.rwkv.latestModel);
    final loading = ref.watch(P.rwkv.loading);
    final generating = ref.watch(P.rwkv.generating);

    final height = InputInteractions.calculateButtonHeight(context);
    final canEnable = model != null && !loading && !generating;
    final buttonLabel = responseStyle.buttonLabel(
      baseLabel: s.response_style_button,
      manyLabel: s.response_style_many,
    );
    final interactionState = switch ((canEnable, responseStyle.isDefault)) {
      (false, _) => InteractionVisualState.unavailable,
      (true, true) => InteractionVisualState.idleInteractive,
      (true, false) => InteractionVisualState.enabled,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final bgColor = colors.background;
    final textColor = colors.foreground;
    final borderColor = colors.border;
    final userBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigmaForBackdropFilterForInputOptions = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);

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
                buttonLabel,
                style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
                strutStyle: StrutStyle(
                  fontSize: fontSize,
                  height: 1,
                  forceStrutHeight: true,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
