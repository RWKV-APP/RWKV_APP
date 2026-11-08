// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/alert.dart';
import 'package:zone/widgets/chat/ask_question_panel.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/chat/chat_interaction_button.dart';

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
    final _ = theme;
    final loading = ref.watch(P.rwkvModel.loading);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final loaded = ref.watch(P.rwkvModel.loaded);
    final albatrossCanUse = ref.watch(P.albatrossRuntime.canUse);
    final canUseChatBackend = loaded || albatrossCanUse;
    final canEnable = canUseChatBackend && !loading && !generating;
    final InteractionVisualState state = generating || !canUseChatBackend
        ? .unavailable
        : canEnable
        ? .available
        : .idleInteractive;

    return ChatInteractionButton(
      label: S.of(context).ask,
      state: state,
      iconBuilder: (color, size) => Icon(Symbols.lightbulb, color: color, size: size),
      onTap: _onTap,
    );
  }
}
