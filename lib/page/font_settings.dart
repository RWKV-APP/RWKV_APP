import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:halo_state/halo_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/markdown.dart';

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
      body: AppGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;

    final scale = effectiveScale * 1.1;
    final userMessage = s.font_preview_user_message;
    final botMessage = s.font_preview_bot_message(
      _formatSize(scale),
      _formatSize(20 * scale),
      _formatSize(19 * scale),
      _formatSize(18 * scale),
      _formatSize(17 * scale),
      _formatSize(16 * scale),
      _formatSize(15 * scale),
      _formatSize(14 * scale),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User message preview
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(effectiveScale),
              ),
              child: Text(
                userMessage,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 14 * 1.1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Bot message preview
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(effectiveScale),
              ),
              child: MarkdownRenderer(raw: botMessage),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsControls extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scalePairs = P.preference.textScalePairs;
    final scaleValues = scalePairs.keys.where((k) => k > 0).toList()..sort();

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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use system font size toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.follow_system,
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
                ],
              ),
              const SizedBox(height: 8),
              // Slider
              AnimatedOpacity(
                opacity: useSystemSize ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: useSystemSize,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            _getScaleLabel(currentScale),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: primary,
                            ),
                          ),
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: 20,
                              color: onSurface.withOpacity(0.6),
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
            ],
          ),
        ),
      ),
    );
  }
}
