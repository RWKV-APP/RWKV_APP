// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/chat/chat_interaction_button.dart';

class BatchButton extends ConsumerWidget {
  const BatchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final loading = ref.watch(P.rwkvModel.loading);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final batchAllowed = ref.watch(P.chat.batchInferenceAvailable);
    final batchEnabled = ref.watch(P.chat.effectiveBatchEnabled);
    final batchCount = ref.watch(P.chat.effectiveBatchCount);
    final canEnable = !loading && !generating && batchAllowed;
    final InteractionVisualState state = switch ((batchEnabled, canEnable)) {
      (true, _) => .enabled,
      (false, true) => .available,
      (false, false) => .unavailable,
    };

    return ChatInteractionButton(
      label: batchEnabled ? batchCount.toString() : null,
      tooltip: S.of(context).batch_inference,
      state: state,
      iconBuilder: (color, size) => Icon(Icons.playlist_play, color: color, size: size),
      onTap: P.rwkvParams.onBatchInferenceTapped,
    );
  }
}
