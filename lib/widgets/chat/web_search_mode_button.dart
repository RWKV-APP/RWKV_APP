import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/chat_interaction_button.dart';
import 'package:zone/widgets/chat/web_search_provider_icon.dart';

class WebSearchModeButton extends ConsumerWidget {
  const WebSearchModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final mode = ref.watch(P.chat.webSearchMode);
    final provider = ref.watch(P.chat.webSearchProvider);
    final appTheme = ref.watch(P.app.theme);

    return ChatInteractionButton(
      label: mode == .off ? (currentLangIsZh ? '联网' : 'Search') : P.chat.searchProviderLabel(provider),
      tooltip: S.of(context).web_search_provider,
      state: generating
          ? .unavailable
          : mode == .off
          ? .idleInteractive
          : .enabled,
      iconBuilder: (color, size) => mode == .off
          ? Icon(Symbols.travel_explore, color: color, size: size)
          : WebSearchProviderIcon(
              provider: provider,
              color: provider == .deepseek && generating && !appTheme.isLight ? appTheme.qb4 : color,
              size: size,
              useButtonForeground: true,
            ),
      onTap: generating ? null : () => P.chat.onWebSearchModeTapped(context),
    );
  }
}
