// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class DebugTextDisplaySettingsSection extends ConsumerWidget {
  final bool includePrefillLogOnlySetting;

  const DebugTextDisplaySettingsSection({
    super.key,
    this.includePrefillLogOnlySetting = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final renderNewlineDirectly = ref.watch(P.rwkv.renderNewlineDirectly);
    final renderSpaceSymbol = ref.watch(P.rwkv.renderSpaceSymbol);
    final showPrefillLogOnly = ref.watch(P.rwkv.showPrefillLogOnly);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DebugSwitchRow(
          label: S.current.render_newline_directly,
          value: renderNewlineDirectly,
          onChanged: P.rwkv.toggleRenderNewlineDirectly,
        ),
        const SizedBox(height: 2),
        _DebugSwitchRow(
          label: S.current.render_space_symbol,
          value: renderSpaceSymbol,
          onChanged: P.rwkv.toggleRenderSpaceSymbol,
        ),
        if (includePrefillLogOnlySetting) const SizedBox(height: 2),
        if (includePrefillLogOnlySetting)
          _DebugSwitchRow(
            label: S.current.show_prefill_log_only,
            value: showPrefillLogOnly,
            valueLabel: showPrefillLogOnly ? S.current.enabled : S.current.disabled,
            onChanged: P.rwkv.toggleShowPrefillLogOnly,
          ),
        const SizedBox(height: 2),
        Container(height: .5, color: theme.colorScheme.outlineVariant),
      ],
    );
  }
}

class _DebugSwitchRow extends ConsumerWidget {
  final String label;
  final bool value;
  final String? valueLabel;
  final Future<void> Function() onChanged;

  const _DebugSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await onChanged();
        },
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TS(c: qb.q(.9), s: 14, w: .w500),
                    ),
                    if (valueLabel != null) const SizedBox(height: 2),
                    if (valueLabel != null)
                      Text(
                        valueLabel!,
                        style: theme.textTheme.bodySmall?.copyWith(color: qb.q(.6)),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: (_) async {
                  await onChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
