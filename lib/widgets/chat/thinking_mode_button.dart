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
import 'package:zone/widgets/chat/chat_interaction_button.dart';

class ThinkingModeButton extends ConsumerWidget {
  final DemoType preferredDemoType;

  const ThinkingModeButton({super.key, this.preferredDemoType = .chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final s = S.of(context);
    final loading = ref.watch(P.rwkvModel.loading);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final loaded = ref.watch(P.rwkvModel.loaded);
    final albatrossCanUse = ref.watch(P.albatrossRuntime.canUse);
    final thinkingMode = ref.watch(P.rwkvParams.thinkingMode);
    final canEnable = (loaded || albatrossCanUse) && !loading && !generating;
    final InteractionVisualState state = switch (thinkingMode) {
      .none => canEnable ? .idleInteractive : .unavailable,
      .fast || .fastWithSpacePrefix || .lighting => canEnable ? .available : .unavailable,
      _ => canEnable ? .enabled : .unavailable,
    };
    final text = switch (thinkingMode) {
      .lighting => s.thinking_mode_button_auto,
      .none => s.thinking_mode_button_off,
      .free || .preferChinese => s.thinking_mode_button_high,
      .fast || .fastWithSpacePrefix => s.thinking_mode_button_fast,
      .en => s.thinking_mode_button_en,
      .enShort => s.thinking_mode_button_en_short,
      .enLong => s.thinking_mode_button_en_long,
    };

    return AnimatedSize(
      key: const Key('_ThinkingModeButton'),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: loading ? .33 : 1,
        duration: const Duration(milliseconds: 250),
        child: ChatInteractionButton(
          label: text,
          state: state,
          iconBuilder: (color, size) =>
              SvgPicture.asset(Assets.img.chat.think, colorFilter: .mode(color, BlendMode.srcIn), width: size, height: size),
          onTap: () => P.rwkvParams.onThinkModeTapped(preferredDemoType: preferredDemoType),
        ),
      ),
    );
  }
}
