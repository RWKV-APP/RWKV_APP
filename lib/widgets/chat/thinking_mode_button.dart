// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

// Project imports:
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';

class ThinkingModeButton extends ConsumerWidget {
  final DemoType preferredDemoType;

  const ThinkingModeButton({super.key, this.preferredDemoType = .chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final loading = ref.watch(P.rwkvModel.loading);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final loaded = ref.watch(P.rwkvModel.loaded);
    final albatrossCanUse = ref.watch(P.albatrossRuntime.canUse);
    final thinkingMode = ref.watch(P.rwkvParams.thinkingMode);

    final canUseChatBackend = loaded || albatrossCanUse;
    final canEnable = canUseChatBackend && !loading && !generating;
    final InteractionVisualState interactionState = switch (thinkingMode) {
      .none => canEnable ? .idleInteractive : .unavailable,
      .fast => canEnable ? .available : .unavailable,
      .fastWithSpacePrefix => canEnable ? .available : .unavailable,
      .lighting => canEnable ? .available : .unavailable,
      .free => canEnable ? .enabled : .unavailable,
      .en => canEnable ? .enabled : .unavailable,
      .enShort => canEnable ? .enabled : .unavailable,
      .enLong => canEnable ? .enabled : .unavailable,
      .preferChinese => canEnable ? .enabled : .unavailable,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final color = colors.background;
    final textColor = colors.foreground;
    final border = Border.all(color: colors.border);

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(fontSize) + 20;
    const padding = EdgeInsets.symmetric(horizontal: 8);

    final text = switch (thinkingMode) {
      .lighting => s.thinking_mode_button_auto,
      .none => s.thinking_mode_button_off,
      .free => s.thinking_mode_button_high,
      .preferChinese => s.thinking_mode_button_high,
      .fast => s.thinking_mode_button_fast,
      .fastWithSpacePrefix => s.thinking_mode_button_fast,
      .en => s.thinking_mode_button_en,
      .enShort => s.thinking_mode_button_en_short,
      .enLong => s.thinking_mode_button_en_long,
    };
    final useBackdropFilter = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigma = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);

    return AnimatedSize(
      key: const Key("_ThinkingModeButton"),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: IntrinsicWidth(
        child: AnimatedOpacity(
          opacity: loading ? .33 : 1,
          duration: const Duration(milliseconds: 250),
          child: GestureDetector(
            onTap: () => P.rwkvParams.onThinkModeTapped(preferredDemoType: preferredDemoType),
            child: ClipRRect(
              borderRadius: .circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: sigma.toDouble(),
                  sigmaY: sigma.toDouble(),
                ),
                enabled: useBackdropFilter,
                child: SizedBox(
                  height: height,
                  child: Container(
                    padding: padding,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: useBackdropFilter
                            ? backdropFilterBgAlphaForInputOptions * backdropFilterBgAlphaForInputOptionsDarkModifier
                            : 1,
                      ),
                      borderRadius: .circular(60),
                      border: border,
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          Assets.img.chat.think,
                          colorFilter: .mode(textColor, BlendMode.srcIn),
                          width: appTheme.inputBarInteractionsIconSize,
                          height: appTheme.inputBarInteractionsIconSize,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          text,
                          style: TextStyle(color: textColor, fontSize: fontSize, height: 1, fontWeight: .w500),
                          strutStyle: StrutStyle(
                            fontSize: fontSize,
                            height: 1,
                            forceStrutHeight: true,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
