// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/func/format_debug_panel_text.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/debug_space_symbol.dart';
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
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final showEscapeCharacters = ref.watch(P.rwkv.showEscapeCharacters);
    final showSpaceSymbols = ref.watch(P.rwkv.showSpaceSymbols);
    final showPrefillLogOnly = ref.watch(P.rwkv.showPrefillLogOnly);
    final visibleSpaceSymbol = ref.watch(P.rwkv.visibleSpaceSymbol);
    final spaceSymbolTextColor = ref.watch(P.rwkv.spaceSymbolTextColor);
    final spaceSymbolBackgroundColor = ref.watch(P.rwkv.spaceSymbolBackgroundColor);
    final newlineSymbolTextColor = ref.watch(P.rwkv.newlineSymbolTextColor);
    final newlineSymbolBackgroundColor = ref.watch(P.rwkv.newlineSymbolBackgroundColor);

    final defaultSpaceTextColor = defaultDebugSpaceTextColor(appTheme: appTheme, qb: qb);
    final defaultSpaceBackgroundColor = defaultDebugSpaceBackgroundColor(appTheme: appTheme);
    final defaultNewlineTextColor = defaultDebugNewlineTextColor(appTheme: appTheme, qb: qb);
    final defaultNewlineBackgroundColor = defaultDebugNewlineBackgroundColor(appTheme: appTheme, qb: qb);
    final effectiveSpaceTextColor = spaceSymbolTextColor ?? defaultSpaceTextColor;
    final effectiveSpaceBackgroundColor = spaceSymbolBackgroundColor ?? defaultSpaceBackgroundColor;
    final effectiveNewlineTextColor = newlineSymbolTextColor ?? defaultNewlineTextColor;
    final effectiveNewlineBackgroundColor = newlineSymbolBackgroundColor ?? defaultNewlineBackgroundColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DebugSwitchRow(
          label: S.current.show_escape_characters,
          value: showEscapeCharacters,
          valueLabel: showEscapeCharacters ? S.current.line_break_rendered : S.current.escape_characters_rendered,
          onChanged: P.rwkv.toggleShowEscapeCharacters,
        ),
        const SizedBox(height: 2),
        _DebugSwitchRow(
          label: S.current.show_space_symbols,
          value: showSpaceSymbols,
          valueLabel: showSpaceSymbols ? "${S.current.space_symbols_rendered} ${visibleSpaceSymbol.symbol}" : S.current.space_rendered,
          onChanged: P.rwkv.toggleShowSpaceSymbols,
        ),
        if (includePrefillLogOnlySetting) const SizedBox(height: 2),
        if (includePrefillLogOnlySetting)
          _DebugSwitchRow(
            label: S.current.show_prefill_log_only,
            value: showPrefillLogOnly,
            valueLabel: showPrefillLogOnly ? S.current.enabled : S.current.disabled,
            onChanged: P.rwkv.toggleShowPrefillLogOnly,
          ),
        const SizedBox(height: 8),
        _DebugTokenSettingsCard(
          title: S.current.space_symbol_settings,
          subtitle: S.current.space_symbol_style,
          extra: SegmentedButton<DebugSpaceSymbol>(
            segments: DebugSpaceSymbol.values
                .map(
                  (symbol) => ButtonSegment<DebugSpaceSymbol>(
                    value: symbol,
                    label: Text(symbol.symbol),
                  ),
                )
                .toList(),
            selected: {visibleSpaceSymbol},
            showSelectedIcon: false,
            onSelectionChanged: (value) async {
              await P.rwkv.setVisibleSpaceSymbol(value.first);
            },
          ),
          children: [
            _DebugColorSettingRow(
              label: S.current.text_color,
              color: effectiveSpaceTextColor,
              overridden: spaceSymbolTextColor != null,
              onPick: () async {
                final result = await _DebugColorPickerDialog.show(
                  context: context,
                  title: "${S.current.space_symbol_settings}${S.current.colon}${S.current.text_color}",
                  initialColor: effectiveSpaceTextColor,
                );
                if (result == null) {
                  return;
                }

                final nextColor = result.toARGB32() == defaultSpaceTextColor.toARGB32() ? null : result;
                await P.rwkv.setSpaceSymbolTextColor(nextColor);
              },
              onReset: () async {
                await P.rwkv.setSpaceSymbolTextColor(null);
              },
              defaultColor: defaultSpaceTextColor,
            ),
            const SizedBox(height: 6),
            _DebugColorSettingRow(
              label: S.current.background_color,
              color: effectiveSpaceBackgroundColor,
              overridden: spaceSymbolBackgroundColor != null,
              onPick: () async {
                final result = await _DebugColorPickerDialog.show(
                  context: context,
                  title: "${S.current.space_symbol_settings}${S.current.colon}${S.current.background_color}",
                  initialColor: effectiveSpaceBackgroundColor,
                );
                if (result == null) {
                  return;
                }

                final nextColor = result.toARGB32() == defaultSpaceBackgroundColor.toARGB32() ? null : result;
                await P.rwkv.setSpaceSymbolBackgroundColor(nextColor);
              },
              onReset: () async {
                await P.rwkv.setSpaceSymbolBackgroundColor(null);
              },
              defaultColor: defaultSpaceBackgroundColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DebugTokenSettingsCard(
          title: S.current.line_break_symbol_settings,
          children: [
            _DebugColorSettingRow(
              label: S.current.text_color,
              color: effectiveNewlineTextColor,
              overridden: newlineSymbolTextColor != null,
              onPick: () async {
                final result = await _DebugColorPickerDialog.show(
                  context: context,
                  title: "${S.current.line_break_symbol_settings}${S.current.colon}${S.current.text_color}",
                  initialColor: effectiveNewlineTextColor,
                );
                if (result == null) {
                  return;
                }

                final nextColor = result.toARGB32() == defaultNewlineTextColor.toARGB32() ? null : result;
                await P.rwkv.setNewlineSymbolTextColor(nextColor);
              },
              onReset: () async {
                await P.rwkv.setNewlineSymbolTextColor(null);
              },
              defaultColor: defaultNewlineTextColor,
            ),
            const SizedBox(height: 6),
            _DebugColorSettingRow(
              label: S.current.background_color,
              color: effectiveNewlineBackgroundColor,
              overridden: newlineSymbolBackgroundColor != null,
              onPick: () async {
                final result = await _DebugColorPickerDialog.show(
                  context: context,
                  title: "${S.current.line_break_symbol_settings}${S.current.colon}${S.current.background_color}",
                  initialColor: effectiveNewlineBackgroundColor,
                );
                if (result == null) {
                  return;
                }

                final nextColor = result.toARGB32() == defaultNewlineBackgroundColor.toARGB32() ? null : result;
                await P.rwkv.setNewlineSymbolBackgroundColor(nextColor);
              },
              onReset: () async {
                await P.rwkv.setNewlineSymbolBackgroundColor(null);
              },
              defaultColor: defaultNewlineBackgroundColor,
            ),
          ],
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
  final String valueLabel;
  final Future<void> Function() onChanged;

  const _DebugSwitchRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
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
                    const SizedBox(height: 2),
                    Text(
                      valueLabel,
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

class _DebugTokenSettingsCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final Widget? extra;
  final List<Widget> children;

  const _DebugTokenSettingsCard({
    required this.title,
    this.subtitle,
    this.extra,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: qb.q(.15), width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) const SizedBox(height: 2),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(color: qb.q(.62)),
            ),
          if (extra case final extra?) ...[
            const SizedBox(height: 8),
            extra,
          ],
          if (children.isNotEmpty) const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DebugColorSettingRow extends ConsumerWidget {
  final String label;
  final Color color;
  final bool overridden;
  final Color defaultColor;
  final Future<void> Function() onPick;
  final Future<void> Function() onReset;

  const _DebugColorSettingRow({
    required this.label,
    required this.color,
    required this.overridden,
    required this.defaultColor,
    required this.onPick,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final showResetButton = overridden && color.toARGB32() != defaultColor.toARGB32();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await onPick();
        },
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: qb.q(.88),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _hex(color),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: qb.q(.62),
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Menlo', 'Monaco', 'Courier'],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  border: Border.all(color: qb.q(.2), width: .5),
                ),
              ),
              if (showResetButton) const SizedBox(width: 8),
              if (showResetButton)
                TextButton(
                  onPressed: () async {
                    await onReset();
                  },
                  child: Text(S.current.reset_to_default),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _hex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#$value';
  }
}

class _DebugColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initialColor;

  const _DebugColorPickerDialog({
    required this.title,
    required this.initialColor,
  });

  static Future<Color?> show({
    required BuildContext context,
    required String title,
    required Color initialColor,
  }) async {
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return _DebugColorPickerDialog(
          title: title,
          initialColor: initialColor,
        );
      },
    );
  }

  @override
  State<_DebugColorPickerDialog> createState() => _DebugColorPickerDialogState();
}

class _DebugColorPickerDialogState extends State<_DebugColorPickerDialog> {
  late Color currentColor = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              setState(() {
                currentColor = color;
              });
            },
            enableAlpha: true,
            portraitOnly: true,
            displayThumbColor: true,
            labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
            pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.current.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () {
            Navigator.of(context).pop(currentColor);
          },
          child: Text(S.current.apply),
        ),
      ],
    );
  }
}
