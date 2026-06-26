// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/input_interactions.dart';

class WebDemoButton extends ConsumerWidget {
  const WebDemoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final height = InputInteractions.calculateButtonHeight(context);
    final loading = ref.watch(P.rwkvModel.loading);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final usingCloud = ref.watch(P.webDemo.useOfficialCloud);
    final canUseLocal = ref.watch(P.rwkvModel.loaded) || ref.watch(P.albatrossRuntime.canUse);
    final canEnable = !loading && !generating && (usingCloud || canUseLocal);
    final state = canEnable ? InteractionVisualState.available : InteractionVisualState.unavailable;
    final colors = interactionVisualColors(appTheme: appTheme, state: state);
    final bgColor = usingCloud ? theme.colorScheme.primary : colors.background;
    final textColor = usingCloud ? theme.colorScheme.onPrimary : colors.foreground;
    final borderColor = usingCloud ? theme.colorScheme.primary.q(.4) : colors.border;
    final userBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigmaForBackdropFilterForInputOptions = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: P.webDemo.sendFromCurrentInput,
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
              decoration: BoxDecoration(
                color: bgColor.q(
                  userBackdropFilterForInputOptions
                      ? backdropFilterBgAlphaForInputOptions * backdropFilterBgAlphaForInputOptionsDarkModifier
                      : 1,
                ),
                borderRadius: .circular(60),
                border: .all(color: borderColor),
              ),
              padding: const .only(left: 8, right: 8),
              child: Row(
                mainAxisAlignment: .center,
                crossAxisAlignment: .center,
                children: [
                  Icon(Icons.web_asset_rounded, color: textColor, size: appTheme.inputBarInteractionsIconSize),
                  const SizedBox(width: 4),
                  Text(
                    "Web",
                    style: TS(c: textColor, height: 1, w: .w600),
                    strutStyle: const StrutStyle(
                      height: 1,
                      forceStrutHeight: true,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
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
