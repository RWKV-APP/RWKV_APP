// Dart imports:
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/font_picker_bottom_sheet.dart';
import 'package:zone/widgets/message.dart' as message_widget;

class PageFontSettings extends ConsumerStatefulWidget {
  const PageFontSettings({super.key});

  @override
  ConsumerState<PageFontSettings> createState() => _PageFontSettingsState();
}

class _PageFontSettingsState extends ConsumerState<PageFontSettings> {
  late double _currentScale;
  bool _useSystemSize = true;
  String _previewTemplate = "";
  late final ScrollController _previewScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final stored = P.preference.preferredTextScaleFactor.q;
    _useSystemSize = stored == P.preference.textScaleFactorSystem;
    _currentScale = _useSystemSize ? 1.0 : stored;
    _loadPreviewTemplate();
  }

  @override
  void dispose() {
    _previewScrollController.dispose();
    super.dispose();
  }

  Future<void> _saveScale(double scale) async {
    P.preference.preferredTextScaleFactor.q = scale;
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble("halo_state.textScaleFactor", scale);
  }

  Future<void> _loadPreviewTemplate() async {
    final assetPath = S.current.font_preview_markdown_asset;
    String template = "";
    try {
      template = await rootBundle.loadString(assetPath);
    } catch (_) {
      template = "";
    }
    if (!mounted) return;
    setState(() {
      _previewTemplate = template;
    });
  }

  String _formatSize(double size) {
    return size.toStringAsFixed(1);
  }

  Future<void> _saveMessageLineHeight(double lineHeight) async {
    await P.preference.setPreferredMessageLineHeight(lineHeight);
  }

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
    final theme = Theme.of(context);

    // Watch the provider for UI updates
    ref.watch(P.preference.preferredTextScaleFactor);
    final currentMessageLineHeight = ref.watch(P.preference.preferredMessageLineHeight);

    final effectiveScale = _useSystemSize ? 1.0 : _currentScale;
    const fontScale = Config.msgFontScale;
    const sizes = Config.markdownHeaderFontSizes;
    const bodySize = Config.markdownBodyFontSize;
    final markdownScale = effectiveScale * fontScale;
    String botPreview = "";
    if (_previewTemplate.trim().isNotEmpty) {
      botPreview = _applyFontPreviewPlaceholders(_previewTemplate, markdownScale, sizes, bodySize);
    }
    if (botPreview.trim().isEmpty) {
      botPreview = "```text\n...\n```";
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.font_setting),
      ),
      body: Column(
        children: [
          Expanded(
            child: _PreviewMessageList(
              scrollController: _previewScrollController,
              userMessage: s.font_preview_user_message,
              botMessage: botPreview,
            ),
          ),
          // Settings controls
          _SettingsControls(
            useSystemSize: _useSystemSize,
            currentScale: _currentScale,
            currentMessageLineHeight: currentMessageLineHeight,
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
            onMessageLineHeightChanged: (value) async {
              await _saveMessageLineHeight(value);
            },
          ),
        ],
      ),
    );
  }
}

class _PreviewMessageList extends ConsumerWidget {
  final ScrollController scrollController;
  final String userMessage;
  final String botMessage;

  const _PreviewMessageList({
    required this.scrollController,
    required this.userMessage,
    required this.botMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final paddingRight = ref.watch(P.app.paddingRight);

    final messages = <model.Message>[
      model.Message(
        id: -900000001,
        content: userMessage,
        isMine: true,
        paused: false,
      ),
      model.Message(
        id: -900000002,
        content: botMessage,
        isMine: false,
        paused: false,
      ),
    ];

    final listView = ListView.separated(
      controller: scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: .only(left: paddingLeft, top: 4, right: paddingRight, bottom: 4),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final finalIndex = messages.length - 1 - index;
        final message = messages[finalIndex];
        return IgnorePointer(
          child: message_widget.Message(
            message,
            finalIndex,
            preferredDemoType: .chat,
          ),
        );
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 15);
      },
    );

    final content = GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: (Platform.isWindows || Platform.isLinux)
          ? RawScrollbar(
              controller: scrollController,
              radius: 100.rr,
              thickness: 4,
              thumbColor: qb.q(.4),
              padding: const .only(top: 4, right: 4, bottom: 4),
              child: listView,
            )
          : listView,
    );

    return content;
  }
}

class _SettingsControls extends ConsumerWidget {
  static const List<double> _messageLineHeightValues = <double>[
    1.0,
    1.1,
    1.2,
    1.3,
    1.4,
    1.5,
    1.6,
    1.7,
    1.8,
    1.9,
    2.0,
  ];

  final bool useSystemSize;
  final double currentScale;
  final double currentMessageLineHeight;
  final ValueChanged<bool> onUseSystemSizeChanged;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onMessageLineHeightChanged;

  const _SettingsControls({
    required this.useSystemSize,
    required this.currentScale,
    required this.currentMessageLineHeight,
    required this.onUseSystemSizeChanged,
    required this.onScaleChanged,
    required this.onMessageLineHeightChanged,
  });

  String _getScaleLabel(double scale) {
    final pairs = P.preference.textScalePairs;
    final entry = pairs.entries.firstWhere(
      (e) => (e.key - scale).abs() < 0.01,
      orElse: () => MapEntry(scale, '${(scale * 100).round()}%'),
    );
    return entry.value;
  }

  double _findClosestValue(List<double> values, double value) {
    double closest = values.first;
    double minDiff = (value - closest).abs();
    for (final current in values) {
      final diff = (value - current).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = current;
      }
    }
    return closest;
  }

  String _getLineHeightLabel(String defaultLabel, double lineHeight) {
    if (lineHeight <= 0) {
      return defaultLabel;
    }
    return "${lineHeight.toStringAsFixed(1)}x";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final scalePairs = P.preference.textScalePairs;
    final scaleValues = scalePairs.keys.where((k) => k > 0).toList()..sort();
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final useDefaultMessageLineHeight = currentMessageLineHeight <= 0;
    final customMessageLineHeight = useDefaultMessageLineHeight ? _messageLineHeightValues.first : currentMessageLineHeight;
    double paddingBottom = ref.watch(P.app.paddingBottom);
    final qb = ref.watch(P.app.qb);
    paddingBottom = max(paddingBottom, 8);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.q(.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          // Use system font size toggle
          Container(
            decoration: BoxDecoration(color: qb.q(.1)),
            height: 1,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 12),
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
              const SizedBox(width: 12),
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
                          children: [
                            18.w,
                            Text(
                              'A',
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.q(.6),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _getScaleLabel(currentScale),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: .w500,
                                color: primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'A',
                              style: TextStyle(
                                fontSize: 20,
                                color: onSurface.q(.6),
                              ),
                            ),
                            18.w,
                          ],
                        ),
                        Slider(
                          value: currentScale,
                          min: scaleValues.first,
                          max: scaleValues.last,
                          divisions: scaleValues.length - 1,
                          onChanged: (value) {
                            final closest = _findClosestValue(scaleValues, value);
                            onScaleChanged(closest);
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.use_default_line_height,
                  style: TextStyle(
                    fontSize: 16,
                    color: onSurface,
                  ),
                ),
              ),
              Switch(
                value: useDefaultMessageLineHeight,
                onChanged: (value) {
                  if (value) {
                    onMessageLineHeightChanged(P.preference.messageLineHeightDefault);
                    return;
                  }
                  onMessageLineHeightChanged(_messageLineHeightValues.first);
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: useDefaultMessageLineHeight
                ? const SizedBox.shrink()
                : Padding(
                    padding: const .only(top: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                s.message_line_height,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: onSurface,
                                ),
                              ),
                            ),
                            Text(
                              _getLineHeightLabel(s.default_font, customMessageLineHeight),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: .w500,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                        Padding(
                          padding: const .only(left: 16, top: 4, right: 16, bottom: 4),
                          child: Text(
                            s.message_line_height_default_hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.q(.65),
                            ),
                          ),
                        ),
                        Slider(
                          value: customMessageLineHeight,
                          min: _messageLineHeightValues.first,
                          max: _messageLineHeightValues.last,
                          divisions: _messageLineHeightValues.length - 1,
                          onChanged: (value) {
                            final closest = _findClosestValue(_messageLineHeightValues, value);
                            onMessageLineHeightChanged(closest);
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            decoration: BoxDecoration(color: qb.q(.1)),
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
    final qb = ref.watch(P.app.qb);
    final preferredUIFont = ref.watch(P.preference.preferredUIFont);
    final preferredMonospaceFont = ref.watch(P.preference.preferredMonospaceFont);

    return Column(
      children: [
        _FontSelectionRow(
          title: s.ui_font_setting,
          subtitle: preferredUIFont ?? s.default_font,
          subtitleFontFamily: preferredUIFont,
          subtitleColor: onSurface.q(.7),
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
        Container(
          margin: const .only(left: 16, right: 16),
          height: 0.5,
          color: qb.q(.12),
        ),
        _FontSelectionRow(
          title: s.monospace_font_setting,
          subtitle: preferredMonospaceFont ?? s.default_font,
          subtitleFontFamily: preferredMonospaceFont,
          subtitleColor: onSurface.q(.7),
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

class _FontSelectionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? subtitleFontFamily;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _FontSelectionRow({
    required this.title,
    required this.subtitle,
    required this.subtitleFontFamily,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const .only(left: 16, top: 12, right: 12, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                      color: subtitleColor,
                      fontFamily: subtitleFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.q(.45),
            ),
          ],
        ),
      ),
    );
  }
}
