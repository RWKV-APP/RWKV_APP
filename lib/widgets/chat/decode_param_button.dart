// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/interactions.dart';

class DecodeParamButton extends ConsumerWidget {
  const DecodeParamButton({super.key});

  void _onTap() async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    P.app.hapticLight();

    final s = S.current;

    final current = P.rwkv.decodeParamType.q;

    qqr(current);

    final List<({String label, DecodeParamType key})> actionPairs = [
      (label: s.decode_param_custom, key: .custom),
      (label: s.decode_param_default_, key: .defaults),
      (label: s.decode_param_creative, key: .creative),
      (label: s.decode_param_comprehensive, key: .comprehensive),
      (label: s.decode_param_conservative, key: .conservative),
      (label: s.decode_param_fixed, key: .fixed),
    ];

    final actions = actionPairs.map((e) {
      final isCurrent = e.key == current;
      final label = isCurrent ? "☑ ${e.label}" : e.label;
      final key = e.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final res = await showModalActionSheet<DecodeParamType>(
      context: getContext()!,
      title: s.decode_param_select_title,
      message: s.decode_param_select_message,
      actions: actions,
    );

    if (res == null) return;

    if (res == .custom) {
      await ArgumentsPanel.show(getContext()!);
      P.preference.saveCustomDecodeParams();
    } else {
      await P.rwkv.syncSamplerParamsFromDefault(res);
      P.preference.saveDecodeParamType(res);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final height = InputInteractions.calculateButtonHeight(context);
    final loading = ref.watch(P.rwkv.loading);
    final generating = ref.watch(P.rwkv.generating);
    final loaded = ref.watch(P.rwkv.loaded);
    final decodeParamType = ref.watch(P.rwkv.decodeParamType);
    final canEnable = loaded && !loading && !generating;
    final interactionState = canEnable ? InteractionVisualState.available : InteractionVisualState.unavailable;
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final bgColor = colors.background;
    final textColor = colors.foreground;
    final borderColor = colors.border;
    final userBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final sigmaForBackdropFilterForInputOptions = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);
    final s = S.of(context);

    return Tooltip(
      message: s.decode_param,
      child: IntrinsicWidth(
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
                  color: bgColor.q(userBackdropFilterForInputOptions ? backdropFilterBgAlphaForInputOptions : 1),
                  borderRadius: .circular(60),
                  border: .all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .center,
                  children: [
                    Icon(Symbols.auto_awesome, color: textColor, size: appTheme.inputBarInteractionsIconSize),
                    const SizedBox(width: 4),
                    Text(
                      decodeParamType.displayNameShort,
                      style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
                    ),
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
