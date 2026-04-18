// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';

String _extractInteractionSuffix({
  required String source,
  required String separator,
}) {
  final separatorIndex = source.lastIndexOf(separator);
  if (separatorIndex < 0) return source;
  return source.substring(separatorIndex + separator.length);
}

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
    final InteractionVisualState interactionState = switch (thinkingMode) {
      .none => canEnable ? .idleInteractive : .unavailable,
      .fast => canEnable ? .available : .unavailable,
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
      .lighting => s.thinking_mode_auto(""),
      .none => s.thinking_mode_off(""),
      .free => s.thinking_mode_high(""),
      .preferChinese => s.thinking_mode_high(""),
      .fast => s.think_button_mode_fast(""),
      .en => s.think_button_mode_en(""),
      .enShort => s.think_button_mode_en_short(""),
      .enLong => s.think_button_mode_en_long(""),
    };
    final compactText = _extractInteractionSuffix(source: text, separator: s.hyphen);

    final useBackdropFilter = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final backdropFilterBgAlphaForInputOptionsDarkModifier = ref.watch(P.ui.backdropFilterBgAlphaForInputOptionsDarkModifier);
    final sigma = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);

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
                      color: color.q(
                        useBackdropFilter ? backdropFilterBgAlphaForInputOptions * backdropFilterBgAlphaForInputOptionsDarkModifier : 1,
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
                          compactText,
                          style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
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
