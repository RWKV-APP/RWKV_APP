import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/web_search_provider.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/web_search_provider_icon.dart';

class WebSearchProviderSheet extends ConsumerWidget {
  final String selected;

  const WebSearchProviderSheet({super.key, required this.selected});

  static Future<String?> show(BuildContext context, {required String selected}) => showModalActionSheet<String>(
    context: context,
    // The package's string-only labels cannot include the bundled brand images.
    builder: (context, _) => WebSearchProviderSheet(selected: selected),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final isDesktop = ref.watch(P.app.isDesktop);
    final generating = ref.watch(P.rwkvGeneration.generating);
    final material = AdaptiveDialog.instance.defaultStyle.isMaterial(theme);
    final providers = <WebSearchProvider>[
      .anysearch,
      .deepseek,
      .zhihuGlobal,
      .zhihuSite,
      .tavily,
      .brave,
      .exa,
      .serper,
      .serpapi,
      .searchapi,
      .firecrawl,
      if (isDesktop) .browser,
    ];
    final actions = <Widget>[
      for (final provider in providers)
        _ProviderAction(provider: provider, selected: selected == provider.name, material: material, enabled: !generating),
      if (!material)
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop('settings'),
          child: Row(
            mainAxisSize: .min,
            children: [
              const Icon(Icons.settings_outlined, size: 24),
              const SizedBox(width: 10),
              Flexible(child: Text(s.web_search_settings)),
            ],
          ),
        )
      else
        TextButton.icon(
          onPressed: generating ? null : () => Navigator.of(context).pop('settings'),
          icon: const Icon(Icons.settings_outlined),
          label: Text(s.web_search_settings),
          style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
      _ProviderAction(provider: null, selected: selected == 'off', material: material, enabled: !generating),
    ];
    if (!material) {
      return CupertinoActionSheet(
        title: Text(s.web_search_provider),
        actions: actions,
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          children: [
            Padding(
              padding: const .all(16),
              child: Text(s.web_search_provider, style: theme.textTheme.titleMedium),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _ProviderAction extends StatelessWidget {
  final WebSearchProvider? provider;
  final bool selected;
  final bool material;
  final bool enabled;

  const _ProviderAction({required this.provider, required this.selected, required this.material, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = material ? theme.colorScheme.onSurface : CupertinoDynamicColor.resolve(CupertinoColors.label, context);
    final label = provider == null ? S.of(context).off : P.chat.searchProviderLabel(provider!);
    final description = provider == null ? '' : P.chat.searchProviderDescription(provider!);
    final content = Semantics(
      selected: selected,
      child: Column(
        mainAxisSize: .min,
        children: [
          Row(
            mainAxisSize: .min,
            mainAxisAlignment: .center,
            children: [
              if (provider == null)
                Icon(Icons.search_off, size: 24, color: iconColor)
              else
                WebSearchProviderIcon(provider: provider!, color: iconColor),
              const SizedBox(width: 10),
              Flexible(child: Text(label, textAlign: .center)),
              if (selected) ...[const SizedBox(width: 8), const Icon(Icons.check, size: 20)],
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const .only(top: 4),
              child: Text(
                description,
                textAlign: .center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
    if (!material) {
      return CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(provider?.name ?? 'off'),
        child: content,
      );
    }
    return TextButton(
      onPressed: enabled ? () => Navigator.of(context).pop(provider?.name ?? 'off') : null,
      style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48), padding: const .symmetric(horizontal: 16, vertical: 12)),
      child: content,
    );
  }
}
