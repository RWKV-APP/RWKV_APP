// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/debug_trace.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/alert.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/chat/chat_interaction_button.dart';

class DecodeParamButton extends ConsumerWidget {
  const DecodeParamButton({super.key});

  void _onTap() async {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    P.app.hapticLight();

    final s = S.current;

    final current = P.rwkvParams.decodeParamType.q;
    final selectedMark = P.preference.appStyle.q.isClassic ? '☑' : '✓';

    qqr(current);

    final actionPairs = <({String label, DecodeParamType key})>[
      (label: s.decode_param_custom, key: .custom),
      (label: s.decode_param_default_, key: .defaults),
      (label: s.decode_param_creative, key: .creative),
      (label: s.decode_param_comprehensive, key: .comprehensive),
      (label: s.decode_param_conservative, key: .conservative),
      (label: s.decode_param_fixed, key: .fixed),
    ];

    final actions = actionPairs.map((e) {
      final isCurrent = e.key == current;
      final label = isCurrent ? '$selectedMark ${e.label}' : e.label;
      final key = e.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final res = await showModalActionSheet<DecodeParamType>(
      context: getContext()!,
      title: s.decode_param_select_title,
      message: s.decode_param_select_message,
      actions: actions,
    );

    if (res == null) {
      if (current == DecodeParamType.fixed) P.rwkvParams.showFixedDecodeParamWarning();
      return;
    }

    if (res == .custom) {
      await ArgumentsPanel.show(getContext()!);
      P.preference.saveCustomDecodeParams();
    } else {
      await P.rwkvParams.syncSamplerParamsFromDefault(res);
      P.preference.saveDecodeParamType(res);
    }

    if (P.rwkvParams.isCurrentDecodeParamFixed()) P.rwkvParams.showFixedDecodeParamWarning();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final loading = ref.watch(P.rwkvModel.loading);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final loaded = ref.watch(P.rwkvModel.loaded);
    final albatrossCanUse = ref.watch(P.albatrossRuntime.canUse);
    final decodeParamType = ref.watch(P.rwkvParams.decodeParamType);
    final canEnable = (loaded || albatrossCanUse) && !loading && !generating;

    return ChatInteractionButton(
      label: decodeParamType.displayNameShort,
      tooltip: S.of(context).decode_param,
      state: canEnable ? .available : .unavailable,
      iconBuilder: (color, size) => Icon(Symbols.auto_awesome, color: color, size: size),
      onTap: _onTap,
    );
  }
}
