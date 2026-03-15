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
    final spaceSummary =
        "${visibleSpaceSymbol.symbol}  ${_hexColor(effectiveSpaceTextColor)} / ${_hexColor(effectiveSpaceBackgroundColor)}";
    final newlineSummary = "${r'\n'}  ${_hexColor(effectiveNewlineTextColor)} / ${_hexColor(effectiveNewlineBackgroundColor)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DebugToggleSettingRow(
          label: S.current.show_escape_characters,
          value: showEscapeCharacters,
          valueLabel: showEscapeCharacters ? S.current.line_break_rendered : newlineSummary,
          settingsEnabled: !showEscapeCharacters,
          previewText: r'\n',
          previewTextColor: effectiveNewlineTextColor,
          previewBackgroundColor: effectiveNewlineBackgroundColor,
          onChanged: P.rwkv.toggleShowEscapeCharacters,
          onTap: _LineBreakSymbolSettingsPanel.show,
        ),
        const SizedBox(height: 2),
        _DebugToggleSettingRow(
          label: S.current.show_space_symbols,
          value: showSpaceSymbols,
          valueLabel: showSpaceSymbols ? spaceSummary : S.current.space_rendered,
          settingsEnabled: showSpaceSymbols,
          previewText: visibleSpaceSymbol.symbol,
          previewTextColor: effectiveSpaceTextColor,
          previewBackgroundColor: effectiveSpaceBackgroundColor,
          onChanged: P.rwkv.toggleShowSpaceSymbols,
          onTap: _SpaceSymbolSettingsPanel.show,
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

class _DebugToggleSettingRow extends ConsumerWidget {
  final String label;
  final bool value;
  final String valueLabel;
  final bool settingsEnabled;
  final String previewText;
  final Color previewTextColor;
  final Color previewBackgroundColor;
  final Future<void> Function() onChanged;
  final Future<void> Function() onTap;

  const _DebugToggleSettingRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.settingsEnabled,
    required this.previewText,
    required this.previewTextColor,
    required this.previewBackgroundColor,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: settingsEnabled
            ? () async {
                await onTap();
              }
            : null,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: qb.q(settingsEnabled ? .66 : .5),
                        fontFamily: 'monospace',
                        fontFamilyFallback: kDebugPanelSymbolFontFallback,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Opacity(
                opacity: settingsEnabled ? 1 : .38,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DebugTokenPreviewChip(
                      text: previewText,
                      textColor: previewTextColor,
                      backgroundColor: previewBackgroundColor,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: qb.q(.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

class _DebugTokenPreviewChip extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;

  const _DebugTokenPreviewChip({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontSize: 12,
          fontFamily: 'monospace',
          fontFamilyFallback: kDebugPanelSymbolFontFallback,
          fontWeight: FontWeight.w700,
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

class _SpaceSymbolSettingsPanel extends ConsumerWidget {
  static const String panelKey = 'SpaceSymbolSettingsPanel';

  static Future<void> show() async {
    await P.ui.showPanel(
      key: panelKey,
      initialChildSize: .46,
      maxChildSize: .62,
      builder: (scrollController) => _SpaceSymbolSettingsPanel(
        scrollController: scrollController,
      ),
    );
  }

  final ScrollController scrollController;

  const _SpaceSymbolSettingsPanel({
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final visibleSpaceSymbol = ref.watch(P.rwkv.visibleSpaceSymbol);
    final spaceSymbolTextColor = ref.watch(P.rwkv.spaceSymbolTextColor);
    final spaceSymbolBackgroundColor = ref.watch(P.rwkv.spaceSymbolBackgroundColor);
    final defaultSpaceTextColor = defaultDebugSpaceTextColor(appTheme: appTheme, qb: qb);
    final defaultSpaceBackgroundColor = defaultDebugSpaceBackgroundColor(appTheme: appTheme);
    final effectiveSpaceTextColor = spaceSymbolTextColor ?? defaultSpaceTextColor;
    final effectiveSpaceBackgroundColor = spaceSymbolBackgroundColor ?? defaultSpaceBackgroundColor;

    return _DebugSecondaryPanelShell(
      scrollController: scrollController,
      title: S.current.space_symbol_settings,
      child: _DebugTokenSettingsCard(
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
            defaultColor: defaultSpaceTextColor,
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
          ),
          const SizedBox(height: 6),
          _DebugColorSettingRow(
            label: S.current.background_color,
            color: effectiveSpaceBackgroundColor,
            overridden: spaceSymbolBackgroundColor != null,
            defaultColor: defaultSpaceBackgroundColor,
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
          ),
        ],
      ),
    );
  }
}

class _LineBreakSymbolSettingsPanel extends ConsumerWidget {
  static const String panelKey = 'LineBreakSymbolSettingsPanel';

  static Future<void> show() async {
    await P.ui.showPanel(
      key: panelKey,
      initialChildSize: .4,
      maxChildSize: .56,
      builder: (scrollController) => _LineBreakSymbolSettingsPanel(
        scrollController: scrollController,
      ),
    );
  }

  final ScrollController scrollController;

  const _LineBreakSymbolSettingsPanel({
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final newlineSymbolTextColor = ref.watch(P.rwkv.newlineSymbolTextColor);
    final newlineSymbolBackgroundColor = ref.watch(P.rwkv.newlineSymbolBackgroundColor);
    final defaultNewlineTextColor = defaultDebugNewlineTextColor(appTheme: appTheme, qb: qb);
    final defaultNewlineBackgroundColor = defaultDebugNewlineBackgroundColor(appTheme: appTheme, qb: qb);
    final effectiveNewlineTextColor = newlineSymbolTextColor ?? defaultNewlineTextColor;
    final effectiveNewlineBackgroundColor = newlineSymbolBackgroundColor ?? defaultNewlineBackgroundColor;

    return _DebugSecondaryPanelShell(
      scrollController: scrollController,
      title: S.current.line_break_symbol_settings,
      child: _DebugTokenSettingsCard(
        title: S.current.line_break_symbol_settings,
        children: [
          _DebugColorSettingRow(
            label: S.current.text_color,
            color: effectiveNewlineTextColor,
            overridden: newlineSymbolTextColor != null,
            defaultColor: defaultNewlineTextColor,
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
          ),
          const SizedBox(height: 6),
          _DebugColorSettingRow(
            label: S.current.background_color,
            color: effectiveNewlineBackgroundColor,
            overridden: newlineSymbolBackgroundColor != null,
            defaultColor: defaultNewlineBackgroundColor,
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
          ),
        ],
      ),
    );
  }
}

class _DebugSecondaryPanelShell extends ConsumerWidget {
  final ScrollController scrollController;
  final String title;
  final Widget child;

  const _DebugSecondaryPanelShell({
    required this.scrollController,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Scaffold(
        backgroundColor: appTheme.settingBg,
        appBar: AppBar(
          backgroundColor: appTheme.settingBg,
          automaticallyImplyLeading: false,
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          children: [child],
        ),
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

String _hexColor(Color color) {
  final value = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#$value';
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
