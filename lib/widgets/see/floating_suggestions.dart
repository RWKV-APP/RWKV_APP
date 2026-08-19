// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/func/thinking_prefix.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';
import 'package:zone/widgets/input_interactions.dart';
import 'package:zone/widgets/suggestion_chips.dart';

class FloatingSuggestions extends ConsumerWidget {
  static const defaultHeight = 40.0;

  const FloatingSuggestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final suggestions = ref.watch(P.suggestion.worldSuggestion);
    final currentModel = ref.watch(P.rwkvModel.latest);
    final showVisionThinking = supportsConfigurableVisionThinking(currentModel);

    if (suggestions.isEmpty && !showVisionThinking) return const SizedBox.shrink();

    final appTheme = ref.watch(P.app.theme);
    final colors = interactionVisualColors(
      appTheme: appTheme,
      state: .available,
    );

    return SuggestionChips(
      suggestions: suggestions,
      onTap: (String item) => P.see.onSuggestionTap(item),
      height: InputInteractions.calculateButtonHeight(context),
      listPadding: .symmetric(horizontal: appTheme.inputBarHorizontalPadding),
      chipPadding: const .symmetric(horizontal: 12, vertical: 0),
      backgroundColor: colors.background,
      borderColor: colors.border,
      textColor: colors.foreground,
      fontWeight: .w500,
      matchInteractionTextMetrics: true,
      separatorWidth: 4,
      leadingWidgets: [
        if (showVisionThinking) const ThinkingModeButton(preferredDemoType: .see),
      ],
    );
  }
}
