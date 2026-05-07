// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/ask_question_panel.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/input_interactions.dart';

class AskQuestionButton extends ConsumerWidget {
  const AskQuestionButton({super.key});

  Future<void> _onTap() async {
    final generating = P.rwkvGeneration.generating.q;
    if (generating) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    P.app.hapticLight();
    await AskQuestionPanel.show();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final height = InputInteractions.calculateButtonHeight(context);
    final loading = ref.watch(P.rwkvModel.loading);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final loaded = ref.watch(P.rwkvModel.loaded);
    final canEnable = loaded && !loading && !generating;

    InteractionVisualState interactionState = canEnable ? .available : .idleInteractive;
    if (generating || !loaded) interactionState = .unavailable;

    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final color = colors.background;
    final textColor = colors.foreground;
    final border = Border.all(color: colors.border);
    final useBackdropFilter = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final sigma = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);

    final userBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
        child: ClipRRect(
          borderRadius: .circular(60),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sigma.toDouble(),
              sigmaY: sigma.toDouble(),
            ),
            enabled: useBackdropFilter,
            child: Container(
              height: height,
              padding: const .symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: color.q(
                  userBackdropFilterForInputOptions
                      ? backdropFilterBgAlphaForInputOptions * backdropFilterBgAlphaForInputOptionsDarkModifier
                      : 1,
                ),
                borderRadius: .circular(60),
                border: border,
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.lightbulb,
                    color: textColor,
                    size: appTheme.inputBarInteractionsIconSize,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.ask,
                    style: TS(
                      c: textColor,
                      s: fontSize,
                      height: 1,
                      w: .w500,
                    ),
                    strutStyle: StrutStyle(
                      fontSize: fontSize,
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
