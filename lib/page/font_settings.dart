import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/gradient_background.dart';
import 'package:zone/widgets/markdown_render.dart';
import 'package:zone/widgets/font_picker_bottom_sheet.dart';
import 'package:zone/config.dart';

class PageFontSettings extends ConsumerStatefulWidget {
  const PageFontSettings({super.key});

  @override
  ConsumerState<PageFontSettings> createState() => _PageFontSettingsState();
}

class _PageFontSettingsState extends ConsumerState<PageFontSettings> {
  late double _currentScale;
  bool _useSystemSize = true;

  @override
  void initState() {
    super.initState();
    final stored = P.preference.preferredTextScaleFactor.q;
    _useSystemSize = stored == P.preference.textScaleFactorSystem;
    _currentScale = _useSystemSize ? 1.0 : stored;
  }

  Future<void> _saveScale(double scale) async {
    P.preference.preferredTextScaleFactor.q = scale;
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble("halo_state.textScaleFactor", scale);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    // Watch the provider for UI updates
    ref.watch(P.preference.preferredTextScaleFactor);

    final effectiveScale = _useSystemSize ? 1.0 : _currentScale;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.font_setting),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const .all(8),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    // Preview section
                    _PreviewCard(
                      effectiveScale: effectiveScale,
                      primaryContainer: primaryContainer,
                      surface: surface,
                      onSurface: onSurface,
                    ),
                  ],
                ),
              ),
            ),
            // Settings controls
            _SettingsControls(
              useSystemSize: _useSystemSize,
              currentScale: _currentScale,
              primary: primary,
              surface: surface,
              onSurface: onSurface,
              onUseSystemSizeChanged: (value) async {
                setState(() {
                  _useSystemSize = value;
                  if (!value) {
                    // Reset to default 100% when switching from system to manual
                    _currentScale = 1.0;
                  }
                });
                if (value) {
                  await _saveScale(P.preference.textScaleFactorSystem);
                } else {
                  await _saveScale(_currentScale);
                }
              },
              onScaleChanged: (value) async {
                setState(() {
                  _currentScale = value;
                });
                if (!_useSystemSize) {
                  await _saveScale(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final double effectiveScale;
  final Color primaryContainer;
  final Color surface;
  final Color onSurface;

  const _PreviewCard({
    required this.effectiveScale,
    required this.primaryContainer,
    required this.surface,
    required this.onSurface,
  });

  String _formatSize(double size) => size.toStringAsFixed(1);

  String _applyFontPreviewPlaceholders(
    String template,
    double scale,
    List<double> sizes,
    double bodySize,
  ) {
    final h1Base = sizes[0];
    final h2Base = sizes[1];
    final h3Base = sizes[2];
    final h4Base = sizes[3];
    final h5Base = sizes[4];
    final h6Base = sizes[5];

    final h1 = h1Base * scale;
    final h2 = h2Base * scale;
    final h3 = h3Base * scale;
    final h4 = h4Base * scale;
    final h5 = h5Base * scale;
    final h6 = h6Base * scale;
    final body = bodySize * scale;

    return template
        .replaceAll('{scale}', _formatSize(scale))
        .replaceAll('{h1BaseSize}', _formatSize(h1Base))
        .replaceAll('{h2BaseSize}', _formatSize(h2Base))
        .replaceAll('{h3BaseSize}', _formatSize(h3Base))
        .replaceAll('{h4BaseSize}', _formatSize(h4Base))
        .replaceAll('{h5BaseSize}', _formatSize(h5Base))
        .replaceAll('{h6BaseSize}', _formatSize(h6Base))
        .replaceAll('{bodyBaseSize}', _formatSize(bodySize))
        .replaceAll('{h1Size}', _formatSize(h1))
        .replaceAll('{h2Size}', _formatSize(h2))
        .replaceAll('{h3Size}', _formatSize(h3))
        .replaceAll('{h4Size}', _formatSize(h4))
        .replaceAll('{h5Size}', _formatSize(h5))
        .replaceAll('{h6Size}', _formatSize(h6))
        .replaceAll('{bodySize}', _formatSize(body));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    const fontScale = Config.msgFontScale;
    const sizes = Config.markdownHeaderFontSizes;
    const bodySize = Config.markdownBodyFontSize;
    final scale = effectiveScale * fontScale;
    final userMessage = s.font_preview_user_message;
    final assetPath = s.font_preview_markdown_asset;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        // User message preview
        Align(
          alignment: .centerRight,
          child: Container(
            padding: const .symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryContainer,
              borderRadius: const .only(
                topLeft: .circular(20),
                topRight: .circular(20),
                bottomLeft: .circular(20),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: .linear(effectiveScale),
              ),
              child: Text(
                userMessage,
                style: TextStyle(
                  color: onSurface,
                  fontSize: bodySize * fontScale,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Bot message preview
        Align(
          alignment: .centerLeft,
          child: Container(
            padding: const .all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const .only(
                topLeft: .circular(0),
                topRight: .circular(20),
                bottomLeft: .circular(20),
                bottomRight: .circular(20),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: .linear(effectiveScale),
              ),
              child: FutureBuilder<String>(
                future: rootBundle.loadString(assetPath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final template = snapshot.data!;
                  final botMessage = _applyFontPreviewPlaceholders(template, scale, sizes, bodySize);
                  return MarkdownRender(raw: botMessage);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsControls extends ConsumerWidget {
  final bool useSystemSize;
  final double currentScale;
  final Color primary;
  final Color surface;
  final Color onSurface;
  final ValueChanged<bool> onUseSystemSizeChanged;
  final ValueChanged<double> onScaleChanged;

  const _SettingsControls({
    required this.useSystemSize,
    required this.currentScale,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.onUseSystemSizeChanged,
    required this.onScaleChanged,
  });

  String _getScaleLabel(double scale) {
    final pairs = P.preference.textScalePairs;
    final entry = pairs.entries.firstWhere(
      (e) => (e.key - scale).abs() < 0.01,
      orElse: () => MapEntry(scale, '${(scale * 100).round()}%'),
    );
    return entry.value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final scalePairs = P.preference.textScalePairs;
    final scaleValues = scalePairs.keys.where((k) => k > 0).toList()..sort();
    double paddingBottom = ref.watch(P.app.paddingBottom);
    final qb = ref.watch(P.app.qb);
    paddingBottom = max(paddingBottom, 8);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          // Use system font size toggle
          C(
            decoration: BD(color: qb.q(.1)),
            height: 1,
          ),
          8.h,
          Row(
            children: [
              12.w,
              Expanded(
                child: Text(
                  s.font_size_follow_system,
                  style: TextStyle(
                    fontSize: 16,
                    color: onSurface,
                  ),
                ),
              ),
              Switch(
                value: useSystemSize,
                onChanged: onUseSystemSizeChanged,
              ),
              12.w,
            ],
          ),
          // Slider - only show when not using system size
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: useSystemSize
                ? const SizedBox.shrink()
                : Padding(
                    padding: const .only(top: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Text(
                              'A',
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.q(.6),
                              ),
                            ),
                            Text(
                              _getScaleLabel(currentScale),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: .w500,
                                color: primary,
                              ),
                            ),
                            Text(
                              'A',
                              style: TextStyle(
                                fontSize: 20,
                                color: onSurface.q(.6),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: currentScale,
                          min: scaleValues.first,
                          max: scaleValues.last,
                          divisions: scaleValues.length - 1,
                          onChanged: (value) {
                            // Snap to nearest defined value
                            double closest = scaleValues.first;
                            double minDiff = (value - closest).abs();
                            for (final sv in scaleValues) {
                              final diff = (value - sv).abs();
                              if (diff < minDiff) {
                                minDiff = diff;
                                closest = sv;
                              }
                            }
                            onScaleChanged(closest);
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          C(
            decoration: BD(color: qb.q(.1)),
            margin: const .only(top: 8),
            height: 1,
          ),
          const _FontSelectionButtons(),
          paddingBottom.h,
        ],
      ),
    );
  }
}

class _FontSelectionButtons extends ConsumerWidget {
  const _FontSelectionButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final preferredUIFont = ref.watch(P.preference.preferredUIFont);
    final preferredMonospaceFont = ref.watch(P.preference.preferredMonospaceFont);

    return Column(
      children: [
        // UI Font Setting
        ListTile(
          title: Text(s.ui_font_setting),
          subtitle: preferredUIFont != null
              ? Text(
                  preferredUIFont,
                  style: TextStyle(
                    fontFamily: preferredUIFont,
                    color: onSurface.q(.7),
                  ),
                )
              : Text(
                  s.default_font,
                  style: TextStyle(
                    color: onSurface.q(.7),
                  ),
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await FontPickerBottomSheet.show(
              context: context,
              currentFont: preferredUIFont,
              isMonospace: false,
              onFontSelected: (font) async {
                await P.preference.setPreferredUIFont(font);
              },
            );
          },
        ),
        // Monospace Font Setting
        ListTile(
          title: Text(s.monospace_font_setting),
          subtitle: preferredMonospaceFont != null
              ? Text(
                  preferredMonospaceFont,
                  style: TextStyle(
                    fontFamily: preferredMonospaceFont,
                    color: onSurface.q(.7),
                  ),
                )
              : Text(
                  s.default_font,
                  style: TextStyle(
                    color: onSurface.q(.7),
                  ),
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await FontPickerBottomSheet.show(
              context: context,
              currentFont: preferredMonospaceFont,
              isMonospace: true,
              onFontSelected: (font) async {
                await P.preference.setPreferredMonospaceFont(font);
              },
            );
          },
        ),
      ],
    );
  }
}
