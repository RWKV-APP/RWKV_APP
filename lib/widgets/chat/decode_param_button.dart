// ignore: unused_import

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/bottom_interactions.dart';

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
      (label: s.decode_param_comprehensive, key: .comprehensive),
      (label: s.decode_param_creative, key: .creative),
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
    final qb = ref.watch(P.app.qb);
    final height = BottomInteractions.calculateButtonHeight(context);
    final decodeParamType = ref.watch(P.rwkv.decodeParamType);
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final primary = Theme.of(context).colorScheme.primary;
    final bgColor = surfaceContainer;
    final textColor = qb.q(.667);
    final borderColor = primary.q(.1);
    final s = S.of(context);
    return Tooltip(
      message: s.decode_param,
      child: IntrinsicWidth(
        child: GestureDetector(
          onTap: _onTap,
          child: Container(
            height: height,
            padding: const .symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: 60.r,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              children: [
                Text(
                  s.style + s.hyphen + decodeParamType.displayNameShort,
                  style: TS(c: textColor, s: 14, height: 1, w: .w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
