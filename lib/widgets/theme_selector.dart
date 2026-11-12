// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_presentation.dart';
import 'package:zone/model/app_style.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/form_item.dart';

class ThemeSelector extends ConsumerWidget {
  static final _shown = qs(false);

  static Future<void> show({bool styles = false}) async {
    if (_shown.q) return;
    final context = getContext();
    if (context == null || !context.mounted) return;

    _shown.q = true;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: styles ? .88 : .75,
            maxChildSize: .9,
            minChildSize: .5,
            expand: false,
            builder: (context, scrollController) => ThemeSelector(scrollController, styles: styles),
          );
        },
      );
    } finally {
      _shown.q = false;
    }
  }

  final ScrollController? scrollController;
  final bool styles;

  const ThemeSelector(this.scrollController, {super.key, this.styles = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final appStyle = ref.watch(P.preference.appStyle);

    return ClipRRect(
      borderRadius: .vertical(top: .circular(appStyle.isClassic ? 16 : appStyle.radius)),
      child: Scaffold(
        backgroundColor: appTheme.settingBg,
        appBar: AppBar(
          primary: false,
          title: Text(styles ? s.theme_styles : s.display, style: theme.textTheme.titleLarge),
          automaticallyImplyLeading: false,
          backgroundColor: appTheme.settingBg,
          actions: [
            Padding(
              padding: const .only(right: 8),
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const .fromLTRB(16, 0, 16, 24),
            children: [if (styles) const _StyleGallery() else const ThemeColorSettingSection()],
          ),
        ),
      ),
    );
  }
}

class ThemeColorSettingSection extends ConsumerWidget {
  final bool showDisplayOptions;

  const ThemeColorSettingSection({super.key, this.showDisplayOptions = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final mode = ref.watch(P.app.preferredThemeMode);
    final followsSystem = mode == ThemeMode.system;
    final appStyle = ref.watch(P.preference.appStyle);
    final renderThinkingTagAsPreview = ref.watch(P.preference.renderThinkingTagAsPreviewEnabled);
    final respondToMobileOrientationChanges = ref.watch(P.preference.respondToMobileOrientationChanges);
    final isMobile = ref.watch(P.app.isMobile);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (showDisplayOptions) _DisplayHeading(s.appearance_mode),
        _ThemeOption(
          selected: followsSystem,
          onPressed: () => P.preference.setAppearance(null),
          child: Row(
            children: [
              const Icon(Icons.brightness_auto_outlined, size: 20),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: Text(s.system_mode)),
              if (followsSystem) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(appTheme.displayName(s), textAlign: .end, style: theme.textTheme.bodySmall),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check, color: appTheme.themePrimary, size: 18),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (appStyle.isClassic) ...[
          _ThemePaletteGroup(title: s.light_mode, light: true, selected: followsSystem ? null : appTheme),
          const SizedBox(height: 16),
          _ThemePaletteGroup(title: s.dark_mode, light: false, selected: followsSystem ? null : appTheme),
        ] else
          _ThemeGrid(
            children: [
              for (final (option, preset) in [(ThemeMode.light, appStyle.light), (ThemeMode.dark, appStyle.dark)])
                _ThemeOption(
                  selected: mode == option,
                  onPressed: () => P.preference.setAppearanceMode(option),
                  child: _PreviewLabel(
                    label: option == ThemeMode.light ? s.light_mode : s.dark_mode,
                    selected: mode == option,
                    preview: _StylePreview(appStyle, preset),
                  ),
                ),
            ],
          ),
        if (showDisplayOptions && isMobile) ...[
          const SizedBox(height: 20),
          _DisplayHeading(s.screen_orientation),
          FormItem(
            icon: Icon(Icons.screen_rotation, color: theme.colorScheme.onSurfaceVariant, size: 16),
            title: s.screen_rotation,
            subtitle: s.screen_rotation_subtitle,
            showArrow: false,
            isSectionStart: true,
            isSectionEnd: true,
            trailing: Switch.adaptive(
              value: respondToMobileOrientationChanges,
              onChanged: P.preference.setRespondToMobileOrientationChanges,
              activeThumbColor: appTheme.themePrimary,
            ),
          ),
        ],
        if (showDisplayOptions) ...[
          const SizedBox(height: 20),
          _DisplayHeading(s.thinking_tag_rendering),
          FormItem(
            icon: Icon(Icons.psychology_alt_outlined, color: theme.colorScheme.onSurfaceVariant, size: 16),
            title: s.thinking_tag_preview,
            subtitle: s.thinking_tag_preview_subtitle,
            showArrow: false,
            isSectionStart: true,
            isSectionEnd: true,
            trailing: Switch.adaptive(
              value: renderThinkingTagAsPreview,
              onChanged: P.preference.setRenderThinkingTagAsPreviewEnabled,
              activeThumbColor: appTheme.themePrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _StyleGallery extends ConsumerWidget {
  const _StyleGallery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final selected = ref.watch(P.preference.appStyle);
    final light = ref.watch(P.app.theme).isLight;
    final classicPalette = ref.watch(light ? P.preference.preferredLightCustomTheme : P.preference.preferredDarkCustomTheme);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const .fromLTRB(2, 4, 2, 16),
          child: Text(s.theme_styles_hint, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        _ThemeGrid(
          children: [
            for (final style in AppStyle.values)
              _ThemeOption(
                selected: style == selected,
                onPressed: () => P.preference.setAppStyle(style),
                child: _PreviewLabel(
                  label: style.displayName(s),
                  selected: style == selected,
                  preview: _StylePreview(style, style.isClassic ? classicPalette : (light ? style.light : style.dark)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final minimum = 138 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 2);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final columns = ((constraints.maxWidth + gap) / (minimum + gap)).floor().clamp(1, children.length.clamp(1, 4));
            final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final child in children) SizedBox(width: width, child: child)],
            );
          },
        ),
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel({required this.label, required this.selected, required this.preview});

  final String label;
  final bool selected;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(height: 1.25, letterSpacing: .1);
    final labelHeight = MediaQuery.textScalerOf(context).scale(labelStyle?.fontSize ?? 14) * 2.5;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Stack(
          children: [
            preview,
            if (selected)
              PositionedDirectional(
                top: 5,
                end: 5,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: theme.colorScheme.surface, shape: .circle),
                    child: Padding(
                      padding: const .all(3),
                      child: Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: labelHeight),
          child: Text(label, style: labelStyle),
        ),
      ],
    );
  }
}

class _StylePreview extends StatelessWidget {
  const _StylePreview(this.style, this.palette);

  final AppStyle style;
  final AppTheme palette;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(style.radius / 2);
    final presentation = AppPresentation.forStyle(style);
    if (presentation != null) {
      final placement = presentation.navigation;
      final side = placement == .editorial || placement == .rail;
      final top = placement == .topTabs || placement == .commandBar;
      final columns =
          presentation.launcher == .dashboard ||
          presentation.launcher == .studio ||
          presentation.launcher == .workshop ||
          presentation.launcher == .device;
      Widget block(Color color, {double? height, double? width}) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(color: color, borderRadius: corners),
      );
      Widget nav() => block(palette.primary, height: 5);
      final content = Column(
        crossAxisAlignment: .stretch,
        children: [
          if (top) ...[nav(), const SizedBox(height: 5)],
          Align(alignment: presentation.launcher == .focus ? .center : .centerLeft, child: block(palette.qb6, width: 26, height: 3)),
          const SizedBox(height: 5),
          Expanded(
            child: Row(
              crossAxisAlignment: .stretch,
              children: [
                Expanded(
                  flex: columns ? 2 : 1,
                  child: block(palette.userMsgBg),
                ),
                if (columns) ...[const SizedBox(width: 4), Expanded(child: block(palette.qb14))],
              ],
            ),
          ),
          if (!side && !top) ...[const SizedBox(height: 5), nav()],
        ],
      );
      return ExcludeSemantics(
        child: Container(
          height: 78,
          padding: const .all(8),
          decoration: BoxDecoration(
            color: palette.settingBg,
            border: Border.all(color: palette.qb13),
            borderRadius: corners,
          ),
          child: side
              ? Row(
                  children: [
                    block(palette.primary, width: 9, height: double.infinity),
                    const SizedBox(width: 5),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      );
    }
    Widget module() => Expanded(
      child: Container(height: 10, decoration: style.box(palette, corners)),
    );

    return ExcludeSemantics(
      child: Container(
        height: 78,
        padding: const .all(8),
        decoration: BoxDecoration(
          color: palette.settingBg,
          border: Border.all(color: palette.qb13),
          borderRadius: corners,
        ),
        child: Column(
          crossAxisAlignment: style.centered ? .center : .start,
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(
              'RWKV',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: palette.qb1,
                fontFamily: style.headingFont(Theme.of(context).platform),
                fontSize: style.headingSize * .47,
                fontWeight: style.headingWeight,
                letterSpacing: style.headingTracking * .5,
                height: 1,
              ),
            ),
            Row(
              children: [
                if (style.layout != .ledger) ...[module(), const SizedBox(width: 4)],
                module(),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: style.box(palette, .circular(style.composerRadius / 3), fill: palette.textInputBgC),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.arrow_upward, size: 12, color: palette.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplayHeading extends StatelessWidget {
  const _DisplayHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const .only(left: 2, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _ThemePaletteGroup extends StatelessWidget {
  const _ThemePaletteGroup({required this.title, required this.light, required this.selected});

  final String title;
  final bool light;
  final AppTheme? selected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final presets = [
      for (final preset in AppTheme.values)
        if (preset.isLight == light) preset,
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _DisplayHeading(title),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final availableColumns = ((constraints.maxWidth + spacing) / (108 + spacing)).floor().clamp(1, presets.length);
            final rows = (presets.length / availableColumns).ceil();
            final columns = (presets.length / rows).ceil();
            final width = (constraints.maxWidth - (columns - 1) * spacing) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final preset in presets)
                  SizedBox(
                    width: width,
                    child: _ThemeOption(
                      selected: preset == selected,
                      onPressed: () => P.preference.setAppearance(preset),
                      child: Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          _ThemePreview(preset),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(child: Text(preset.displayName(s))),
                              if (preset == selected) const Icon(Icons.check, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  const _ThemeOption({required this.selected, required this.onPressed, required this.child});

  final bool selected;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final borderColor = selected ? appTheme.themePrimary : appTheme.qb12;

    return Semantics(
      selected: selected,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: appTheme.settingItem,
          foregroundColor: theme.colorScheme.onSurface,
          textStyle: theme.textTheme.labelLarge,
          minimumSize: const Size(0, 52),
          padding: const .all(9),
          shape: const RoundedRectangleBorder(borderRadius: .all(.circular(12))),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview(this.preset);

  final AppTheme preset;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 56,
        padding: const .all(7),
        decoration: BoxDecoration(
          color: preset.scaffoldBg,
          border: Border.all(color: preset.qb13),
          borderRadius: const .all(.circular(7)),
        ),
        child: Column(
          mainAxisAlignment: .spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: preset.themePrimary, size: 6),
                const SizedBox(width: 4),
                Container(width: 16, height: 2, color: preset.qb6),
              ],
            ),
            Align(
              alignment: .centerRight,
              child: Container(
                width: 28,
                height: 10,
                alignment: .center,
                decoration: BoxDecoration(color: preset.userMsgBg, borderRadius: const .all(.circular(4))),
                child: Container(width: 12, height: 2, color: preset.qb6),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: preset.textInputBgC,
                      border: Border.all(color: preset.qb12),
                      borderRadius: const .all(.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_circle_up, size: 11, color: preset.sendingButtonC),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
