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

class BatchButton extends ConsumerWidget {
  const BatchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final height = InputInteractions.calculateButtonHeight(context);
    final loading = ref.watch(P.rwkv.loading);
    final generating = ref.watch(P.rwkv.generating);
    final loaded = ref.watch(P.rwkv.loaded);
    final latestModel = ref.watch(P.rwkv.latestModel);
    final batchAllowed = latestModel?.tags.contains("batch") ?? false;
    final batchEnabled = ref.watch(P.chat.effectiveBatchEnabled);
    final batchCount = ref.watch(P.chat.effectiveBatchCount);
    final canEnable = loaded && !loading && !generating && batchAllowed;

    final InteractionVisualState interactionState = switch ((batchEnabled, canEnable)) {
      (true, _) => .enabled,
      (false, true) => .available,
      (false, false) => .unavailable,
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
        onTap: P.rwkv.onBatchInferenceTapped,
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
                  Icon(Icons.playlist_play, color: textColor, size: appTheme.inputBarInteractionsIconSize),
                  if (batchEnabled) const SizedBox(width: 4),
                  if (batchEnabled)
                    Text(
                      batchCount.toString(),
                      style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
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
