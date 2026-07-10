// Dart imports:
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/web_demo_grayscale_theme.dart';
import 'package:zone/widgets/web_demo_preview.dart';

class PageWebDemo extends ConsumerWidget {
  const PageWebDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = (theme, ref.watch(P.msg.ids));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      P.webDemo.hydrateFromCurrentConversation();
    });

    return Theme(
      data: webDemoGrayscaleTheme(theme),
      child: const Scaffold(
        body: SafeArea(
          bottom: false,
          child: _WebDemoShell(),
        ),
      ),
    );
  }
}

class _WebDemoShell extends ConsumerWidget {
  const _WebDemoShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    if (compact) {
      return const Column(
        children: [
          _WebDemoTopBar(),
          SizedBox(
            height: 456,
            child: _WebDemoControlPanel(),
          ),
          Expanded(child: _WebDemoGrid()),
        ],
      );
    }

    return const Column(
      children: [
        _WebDemoTopBar(),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 312,
                child: _WebDemoControlPanel(),
              ),
              _VerticalRule(),
              Expanded(child: _WebDemoGrid()),
            ],
          ),
        ),
      ],
    );
  }
}

class _WebDemoTopBar extends ConsumerWidget {
  const _WebDemoTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final active = ref.watch(P.webDemo.active);
    final backendMode = ref.watch(P.webDemo.backendMode);
    final run = ref.watch(P.webDemo.currentRun);
    final backendText = webDemoBackendLabel(backendMode);
    final statusText = active
        ? S.current.generating
        : run == null
        ? backendText
        : S.current.web_demo_pages_status(run.batchSize, backendText);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: appTheme.appBarBgC,
        border: Border(bottom: BorderSide(color: qb.withValues(alpha: .14), width: .5)),
      ),
      padding: const .symmetric(horizontal: 16),
      child: Row(
        children: [
          Tooltip(
            message: MaterialLocalizations.of(context).backButtonTooltip,
            child: IconButton(
              onPressed: () => _onBackPressed(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Center(
              child: Text(
                "RWKV Web Demo",
                maxLines: 1,
                overflow: .ellipsis,
                style: TextStyle(fontSize: 22, fontWeight: .w700),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const .symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? theme.colorScheme.primary.withValues(alpha: .12) : appTheme.settingBg,
              borderRadius: .circular(999),
              border: Border.all(color: active ? theme.colorScheme.primary.withValues(alpha: .34) : qb.withValues(alpha: .12), width: .5),
            ),
            child: Text(
              statusText,
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(
                color: active ? theme.colorScheme.primary : qb.withValues(alpha: .72),
                fontSize: 12,
                fontWeight: .w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBackPressed(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    go(.home);
  }
}

class _WebDemoControlPanel extends ConsumerWidget {
  const _WebDemoControlPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final appTheme = ref.watch(P.app.theme);
    final active = ref.watch(P.webDemo.active);
    final prompt = ref.watch(P.webDemo.promptInput);
    final pendingHtmlContext = ref.watch(P.webDemo.pendingHtmlContext);
    final backendMode = ref.watch(P.webDemo.backendMode);
    final configured = P.webDemo.officialCloudConfigured;

    return Container(
      color: appTheme.settingBg,
      child: SingleChildScrollView(
        padding: const .fromLTRB(12, 12, 12, 18),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            _PromptPicker(enabled: !active),
            const SizedBox(height: 10),
            _PromptInput(enabled: !active),
            if (pendingHtmlContext != null) const SizedBox(height: 8),
            if (pendingHtmlContext != null) const _AttachedHtmlNotice(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: active || prompt.trim().isEmpty ? null : P.webDemo.sendFromCurrentInput,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: .circular(6)),
                    ),
                    child: Text(
                      S.current.web_demo_generate_html_grid,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: .w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: active ? P.webDemo.stopActive : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: .circular(6)),
                    ),
                    child: Text(
                      S.current.stop,
                      style: const TextStyle(fontWeight: .w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _BackendSelector(
              backendMode: backendMode,
              configured: configured,
              enabled: !active,
            ),
            if (webDemoBackendIsCloud(backendMode)) const SizedBox(height: 8),
            if (webDemoBackendIsCloud(backendMode))
              _CloudModelSelector(
                backendMode: backendMode,
                enabled: !active && configured,
              ),
            const SizedBox(height: 14),
            _WebDemoIntegerControl(
              label: S.current.web_demo_max_tokens,
              min: 50,
              max: 16000,
              resetValue: 16000,
              argument: Argument.maxLength,
            ),
            const _WebDemoBatchControl(),
            _PreviewControl(
              label: S.current.web_demo_preview_scale_percent,
              min: 20,
              max: 100,
              resetValue: 35,
              kind: _PreviewControlKind.scale,
            ),
            _PreviewControl(
              label: S.current.web_demo_preview_scroll_seconds,
              min: 0,
              max: 10,
              resetValue: 5,
              kind: _PreviewControlKind.scrollSeconds,
            ),
            _WebDemoDecimalControl(
              label: S.current.web_demo_temperature,
              argument: Argument.temperature,
              resetValue: 1,
            ),
            _WebDemoDecimalControl(
              label: S.current.web_demo_top_p,
              argument: Argument.topP,
              resetValue: .5,
            ),
            _WebDemoDecimalControl(
              label: S.current.web_demo_presence_penalty,
              argument: Argument.presencePenalty,
              resetValue: 1,
            ),
            _WebDemoDecimalControl(
              label: S.current.web_demo_count_penalty,
              argument: Argument.frequencyPenalty,
              resetValue: .1,
            ),
            _WebDemoDecimalControl(
              label: S.current.web_demo_penalty_decay,
              argument: Argument.penaltyDecay,
              resetValue: .99,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptPicker extends ConsumerWidget {
  final bool enabled;

  const _PromptPicker({required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      height: 34,
      padding: const .symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(6),
        border: Border.all(color: appTheme.qb12, width: .5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: "custom",
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          style: theme.textTheme.bodySmall?.copyWith(color: appTheme.qb0),
          onChanged: enabled ? _onPresetChanged : null,
          items: [
            DropdownMenuItem(value: "custom", child: Text(S.current.web_demo_custom_prompt)),
            DropdownMenuItem(value: "animation", child: Text(S.current.web_demo_preset_animation)),
            DropdownMenuItem(value: "dashboard", child: Text(S.current.web_demo_preset_dashboard)),
            DropdownMenuItem(value: "product", child: Text(S.current.web_demo_preset_product)),
          ],
        ),
      ),
    );
  }

  void _onPresetChanged(String? value) {
    final prompt = switch (value) {
      "animation" =>
        "Create a single-file HTML page showing a 3D animation of cars in a forest with animals. Use CSS or JavaScript, polished composition, and responsive layout. Return only one complete HTML document.",
      "dashboard" =>
        "Create a single-file HTML SaaS analytics dashboard with charts, KPI cards, filters, table, light and dark friendly colors, and responsive layout. Return only one complete HTML document.",
      "product" =>
        "Create a single-file HTML product landing page for an AI coding assistant with hero, feature grid, pricing, testimonials, and refined responsive design. Return only one complete HTML document.",
      _ => null,
    };
    if (prompt == null) return;
    P.webDemo.promptInput.q = prompt;
    P.webDemo.promptController.text = prompt;
    P.webDemo.promptController.selection = TextSelection.collapsed(offset: prompt.length);
  }
}

class _PromptInput extends ConsumerWidget {
  final bool enabled;

  const _PromptInput({required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          S.current.prompt,
          style: TextStyle(color: appTheme.qb5, fontSize: 13, fontWeight: .w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: P.webDemo.promptController,
          focusNode: P.webDemo.promptFocusNode,
          enabled: enabled,
          onChanged: P.webDemo.setPromptInput,
          minLines: 9,
          maxLines: 14,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.24),
          decoration: InputDecoration(
            filled: true,
            fillColor: appTheme.settingItem,
            hintText: S.current.web_demo_prompt_hint,
            hintStyle: TextStyle(color: appTheme.qb7),
            contentPadding: const .all(10),
            border: OutlineInputBorder(
              borderRadius: .circular(6),
              borderSide: BorderSide(color: appTheme.qb12, width: .5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: .circular(6),
              borderSide: BorderSide(color: appTheme.qb12, width: .5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: .circular(6),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachedHtmlNotice extends ConsumerWidget {
  const _AttachedHtmlNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .1),
        borderRadius: .circular(6),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: .2), width: .5),
      ),
      child: Text(
        S.current.web_demo_html_attached,
        style: TextStyle(color: appTheme.qb2, fontSize: 12, fontWeight: .w600),
      ),
    );
  }
}

enum _WebDemoBackendFamily {
  cloud,
  albatross,
  rwkvMobile,
}

_WebDemoBackendFamily _webDemoBackendFamilyFor(WebDemoBackendMode mode) {
  return switch (mode) {
    WebDemoBackendMode.cloud7b => _WebDemoBackendFamily.cloud,
    WebDemoBackendMode.cloud13b => _WebDemoBackendFamily.cloud,
    WebDemoBackendMode.localAlbatross => _WebDemoBackendFamily.albatross,
    WebDemoBackendMode.localRwkvMobile => _WebDemoBackendFamily.rwkvMobile,
  };
}

WebDemoBackendMode _webDemoBackendModeForFamily(_WebDemoBackendFamily family, WebDemoBackendMode currentMode) {
  return switch (family) {
    _WebDemoBackendFamily.cloud => webDemoBackendIsCloud(currentMode) ? currentMode : WebDemoBackendMode.cloud7b,
    _WebDemoBackendFamily.albatross => WebDemoBackendMode.localAlbatross,
    _WebDemoBackendFamily.rwkvMobile => WebDemoBackendMode.localRwkvMobile,
  };
}

class _BackendSelector extends ConsumerWidget {
  final WebDemoBackendMode backendMode;
  final bool configured;
  final bool enabled;

  const _BackendSelector({
    required this.backendMode,
    required this.configured,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return SegmentedButton<_WebDemoBackendFamily>(
      segments: [
        ButtonSegment(
          value: _WebDemoBackendFamily.cloud,
          enabled: enabled && configured,
          icon: const Icon(Icons.cloud_done_outlined, size: 17),
          label: Text(configured ? S.current.web_demo_cloud : S.current.web_demo_no_key),
        ),
        const ButtonSegment(
          value: _WebDemoBackendFamily.albatross,
          icon: Icon(Icons.bolt_rounded, size: 17),
          label: Text("Albatross"),
        ),
        const ButtonSegment(
          value: _WebDemoBackendFamily.rwkvMobile,
          icon: Icon(Icons.memory_rounded, size: 17),
          label: Text("RWKV Mobile"),
        ),
      ],
      selected: {_webDemoBackendFamilyFor(backendMode)},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium),
        side: WidgetStatePropertyAll(BorderSide(color: appTheme.qb12, width: .5)),
      ),
      onSelectionChanged: enabled
          ? (selection) {
              final next = selection.isEmpty ? null : selection.first;
              if (next == null) return;
              P.webDemo.setBackendMode(_webDemoBackendModeForFamily(next, backendMode));
            }
          : null,
    );
  }
}

class _CloudModelSelector extends ConsumerWidget {
  final WebDemoBackendMode backendMode;
  final bool enabled;

  const _CloudModelSelector({
    required this.backendMode,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return SegmentedButton<WebDemoBackendMode>(
      segments: const [
        ButtonSegment(
          value: WebDemoBackendMode.cloud7b,
          icon: Icon(Icons.cloud_done_outlined, size: 16),
          label: Text("7.2B"),
        ),
        ButtonSegment(
          value: WebDemoBackendMode.cloud13b,
          icon: Icon(Icons.cloud_queue_rounded, size: 16),
          label: Text("13.3B"),
        ),
      ],
      selected: {backendMode == WebDemoBackendMode.cloud13b ? WebDemoBackendMode.cloud13b : WebDemoBackendMode.cloud7b},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
        side: WidgetStatePropertyAll(BorderSide(color: appTheme.qb12, width: .5)),
      ),
      onSelectionChanged: enabled
          ? (selection) {
              final next = selection.isEmpty ? null : selection.first;
              if (next == null) return;
              P.webDemo.setBackendMode(next);
            }
          : null,
    );
  }
}

class _WebDemoIntegerControl extends ConsumerWidget {
  final String label;
  final double min;
  final double max;
  final int resetValue;
  final Argument argument;

  const _WebDemoIntegerControl({
    required this.label,
    required this.min,
    required this.max,
    required this.resetValue,
    required this.argument,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final value = ref.watch(P.webDemo.arguments(argument)).clamp(min, max);

    return _ControlFrame(
      label: label,
      valueText: value.round().toString(),
      onReset: () => P.webDemo.syncArgument(argument, resetValue.toDouble()),
      child: Slider(
        value: value.toDouble(),
        min: min,
        max: max,
        divisions: ((max - min) / 50).round(),
        onChanged: (next) => P.webDemo.syncArgument(argument, next.roundToDouble()),
        activeColor: theme.colorScheme.primary,
      ),
    );
  }
}

class _WebDemoBatchControl extends ConsumerWidget {
  const _WebDemoBatchControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final max = ref.watch(P.webDemo.batchSizeMax);
    final value = ref.watch(P.webDemo.batchSize).clamp(1, max).toInt();

    return _ControlFrame(
      label: S.current.web_demo_concurrency,
      valueText: value.toString(),
      onReset: () => P.webDemo.setBatchSize(30),
      child: Slider(
        value: value.toDouble(),
        min: 1,
        max: max.toDouble(),
        divisions: max > 1 ? max - 1 : null,
        onChanged: (next) => P.webDemo.setBatchSize(next),
        activeColor: theme.colorScheme.primary,
      ),
    );
  }
}

enum _PreviewControlKind {
  scale,
  scrollSeconds,
}

class _PreviewControl extends ConsumerWidget {
  final String label;
  final double min;
  final double max;
  final double resetValue;
  final _PreviewControlKind kind;

  const _PreviewControl({
    required this.label,
    required this.min,
    required this.max,
    required this.resetValue,
    required this.kind,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final value = switch (kind) {
      _PreviewControlKind.scale => ref.watch(P.webDemo.previewScalePercent),
      _PreviewControlKind.scrollSeconds => ref.watch(P.webDemo.previewAutoScrollSeconds),
    };

    return _ControlFrame(
      label: label,
      valueText: kind == _PreviewControlKind.scale ? value.round().toString() : value.toStringAsFixed(1),
      onReset: () => _setValue(resetValue),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: ((max - min) * (kind == _PreviewControlKind.scale ? 1 : 2)).round(),
        onChanged: _setValue,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  void _setValue(double value) {
    switch (kind) {
      case _PreviewControlKind.scale:
        P.webDemo.setPreviewScalePercent(value);
      case _PreviewControlKind.scrollSeconds:
        P.webDemo.setPreviewAutoScrollSeconds(value);
    }
  }
}

class _WebDemoDecimalControl extends ConsumerWidget {
  final String label;
  final Argument argument;
  final double resetValue;

  const _WebDemoDecimalControl({
    required this.label,
    required this.argument,
    required this.resetValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final value = ref.watch(P.webDemo.arguments(argument)).clamp(argument.min, argument.max);

    return _ControlFrame(
      label: label,
      valueText: value.toDouble().toStringAsFixed(argument.fixedDecimals),
      onReset: () => P.webDemo.syncArgument(argument, resetValue),
      child: Slider(
        value: value.toDouble(),
        min: argument.min,
        max: argument.max,
        divisions: _divisionsFor(argument),
        onChanged: (next) => P.webDemo.syncArgument(argument, next),
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  int _divisionsFor(Argument argument) {
    final step = argument.step;
    if (step == null || step <= 0) return 100;
    return ((argument.max - argument.min) / step).round();
  }
}

class _ControlFrame extends ConsumerWidget {
  final String label;
  final String valueText;
  final VoidCallback onReset;
  final Widget child;

  const _ControlFrame({
    required this.label,
    required this.valueText,
    required this.onReset,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return Padding(
      padding: const .only(bottom: 10),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: appTheme.qb5, fontSize: 13, fontWeight: .w600),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 58),
                padding: const .symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appTheme.settingItem,
                  borderRadius: .circular(5),
                  border: Border.all(color: appTheme.qb12, width: .5),
                ),
                child: Text(
                  valueText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: .w600),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: S.current.reset,
                child: IconButton(
                  onPressed: onReset,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.restart_alt_rounded, size: 17, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 28, child: child),
        ],
      ),
    );
  }
}

class _WebDemoGrid extends ConsumerStatefulWidget {
  const _WebDemoGrid();

  @override
  ConsumerState<_WebDemoGrid> createState() => _WebDemoGridState();
}

class _WebDemoGridState extends ConsumerState<_WebDemoGrid> {
  late final ScrollController _gridScrollController = ScrollController();

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final resultCount = ref.watch(P.webDemo.results.select((results) => results.length));

    if (resultCount == 0) {
      return Container(
        color: appTheme.scaffoldBg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const .all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity).toDouble()),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        Icon(Icons.grid_view_rounded, size: 36, color: theme.colorScheme.primary.withValues(alpha: .82)),
                        const SizedBox(height: 14),
                        Text(
                          S.current.web_demo_empty_title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: .w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.current.web_demo_empty_description,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: appTheme.qb5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1140
            ? 3
            : width >= 760
            ? 2
            : 1;
        final itemHeight = width >= 760 ? 390.0 : 520.0;

        final itemWidth = ((width - 20 - (10 * (crossAxisCount - 1))) / crossAxisCount).clamp(0, double.infinity).toDouble();
        final children = List<Widget>.generate(
          resultCount,
          (index) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _WebDemoResultTile(
                index: index,
                parentScrollController: _gridScrollController,
              ),
            );
          },
        );

        return SingleChildScrollView(
          controller: _gridScrollController,
          padding: const .all(10),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children,
          ),
        );
      },
    );
  }
}

class _WebDemoResultTile extends ConsumerWidget {
  final int index;
  final ScrollController parentScrollController;

  const _WebDemoResultTile({
    required this.index,
    required this.parentScrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final scalePercent = ref.watch(P.webDemo.previewScalePercent);
    final autoScrollSeconds = ref.watch(P.webDemo.previewAutoScrollSeconds);
    final result = ref.watch(P.webDemo.resultByIndex(index));
    if (result == null) return const SizedBox.shrink();
    final html = result.html;

    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        border: Border.all(color: appTheme.qb12, width: .5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _ResultHeader(result: result),
          if (html != null)
            Expanded(
              flex: 3,
              child: _ScaledHtmlPreview(
                html: html,
                complete: result.document?.complete ?? false,
                scalePercent: scalePercent,
                autoScrollSeconds: autoScrollSeconds,
                parentScrollController: parentScrollController,
              ),
            ),
          if (html != null) Container(height: .5, color: appTheme.qb12),
          Expanded(
            flex: html == null ? 1 : 2,
            child: _SourceStream(
              raw: html ?? result.raw,
              parentScrollController: parentScrollController,
            ),
          ),
          if (result.error != null)
            Container(
              color: theme.colorScheme.error.withValues(alpha: .1),
              padding: const .symmetric(horizontal: 8, vertical: 5),
              child: Text(
                result.error!,
                maxLines: 1,
                overflow: .ellipsis,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12, fontWeight: .w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultHeader extends ConsumerWidget {
  final WebDemoResult result;

  const _ResultHeader({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final html = result.html;
    final textColor = Colors.white.withValues(alpha: .92);
    final mutedColor = Colors.white.withValues(alpha: .68);

    return Container(
      height: 28,
      color: Colors.black,
      padding: const .only(left: 8, right: 4),
      child: Row(
        children: [
          Text(
            "#${result.index + 1}",
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: .w800, fontFamily: "monospace"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.current.web_demo_tokens_and_bytes(result.tokens, result.bytes),
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(color: mutedColor, fontSize: 11, fontWeight: .w700, fontFamily: "monospace"),
            ),
          ),
          if (result.streaming)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.6, color: theme.colorScheme.primary),
            ),
          const SizedBox(width: 4),
          _HeaderAction(
            tooltip: S.current.web_demo_copy_result,
            icon: Icons.content_copy_rounded,
            onPressed: () => P.webDemo.copyResultSource(result),
          ),
          if (html != null)
            _HeaderAction(
              tooltip: S.current.web_demo_view_source,
              icon: Icons.code_rounded,
              onPressed: () => showWebDemoSourceSheet(
                context: context,
                source: html,
                label: S.current.web_demo_result_label(result.index + 1),
              ),
            ),
          if (html != null)
            _HeaderAction(
              tooltip: S.current.web_demo_continue_editing,
              icon: Icons.edit_outlined,
              onPressed: () => P.webDemo.prepareContinuationFromResult(result),
            ),
          if (html != null)
            _HeaderAction(
              tooltip: S.current.web_demo_save_html,
              icon: Icons.save_alt_rounded,
              onPressed: () => P.webDemo.saveResultHtml(result),
            ),
          if (html != null)
            _HeaderAction(
              tooltip: S.current.web_demo_open_in_browser,
              icon: Icons.open_in_browser_rounded,
              onPressed: () => P.webDemo.openResultInSystemBrowser(result),
            ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: .zero,
        constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        icon: Icon(icon, size: 15, color: Colors.white.withValues(alpha: .82)),
        hoverColor: theme.colorScheme.primary.withValues(alpha: .22),
      ),
    );
  }
}

class _ScaledHtmlPreview extends StatelessWidget {
  final String html;
  final bool complete;
  final double scalePercent;
  final double autoScrollSeconds;
  final ScrollController parentScrollController;

  const _ScaledHtmlPreview({
    required this.html,
    required this.complete,
    required this.scalePercent,
    required this.autoScrollSeconds,
    required this.parentScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;
    final scale = (scalePercent / 100).clamp(.2, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledWidth = constraints.maxWidth / scale;
        final scaledHeight = constraints.maxHeight / scale;

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: scaledWidth,
            maxWidth: scaledWidth,
            minHeight: scaledHeight,
            maxHeight: scaledHeight,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: scaledWidth,
                height: scaledHeight,
                child: _WebDemoGridWebView(
                  html: html,
                  complete: complete,
                  autoScrollSeconds: autoScrollSeconds,
                  parentScrollController: parentScrollController,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WebDemoGridWebView extends StatelessWidget {
  final String html;
  final bool complete;
  final double autoScrollSeconds;
  final ScrollController parentScrollController;

  const _WebDemoGridWebView({
    required this.html,
    required this.complete,
    required this.autoScrollSeconds,
    required this.parentScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;
    final baseUri = WebUri("https://rwkv-web-demo.local/");

    return InAppWebView(
      key: ValueKey<int>(_previewKey(html: html, complete: complete, autoScrollSeconds: autoScrollSeconds)),
      initialData: InAppWebViewInitialData(
        data: html,
        mimeType: "text/html",
        encoding: "utf-8",
        baseUrl: baseUri,
        historyUrl: baseUri,
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: false,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptRequest: true,
        allowFileAccessFromFileURLs: false,
        allowUniversalAccessFromFileURLs: false,
        transparentBackground: false,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: "webDemoPreviewBoundaryScroll",
          callback: (arguments) {
            final rawDelta = arguments.isEmpty ? null : arguments.first;
            if (rawDelta is num) {
              _forwardScrollControllerBy(parentScrollController, rawDelta.toDouble());
            }
            if (rawDelta is String) {
              final parsed = double.tryParse(rawDelta);
              if (parsed == null) return null;
              _forwardScrollControllerBy(parentScrollController, parsed);
            }
            return null;
          },
        );
      },
      onLoadStop: (controller, url) async {
        await controller.evaluateJavascript(source: _previewBoundaryScrollScript());
        if (autoScrollSeconds <= 0) return;
        final durationMs = (autoScrollSeconds * 1000).round();
        await controller.evaluateJavascript(source: _autoScrollScript(durationMs));
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        if (url == null) return NavigationActionPolicy.CANCEL;
        if (url.host == baseUri.host) return NavigationActionPolicy.ALLOW;
        return NavigationActionPolicy.CANCEL;
      },
      shouldInterceptRequest: (controller, request) async {
        final url = request.url;
        if (url.host == baseUri.host) return null;
        if (url.scheme == "data" || url.scheme == "blob" || url.scheme == "about") return null;
        return WebResourceResponse(
          contentType: "text/plain",
          data: Uint8List(0),
          headers: const <String, String>{},
          statusCode: 403,
          reasonPhrase: "Blocked",
        );
      },
    );
  }
}

class _SourceStream extends ConsumerWidget {
  final String raw;
  final ScrollController parentScrollController;

  const _SourceStream({
    required this.raw,
    required this.parentScrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final display = raw.isEmpty ? S.current.web_demo_waiting_for_first_tokens : raw;

    return Container(
      color: appTheme.isLight ? const Color(0xFFF7F7F7) : const Color(0xFF101010),
      child: _BoundaryForwardingScrollView(
        parentScrollController: parentScrollController,
        padding: const .all(8),
        reverse: true,
        child: SelectableText(
          display,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: "monospace",
            fontSize: 10.5,
            height: 1.22,
            color: raw.isEmpty ? appTheme.qb7 : appTheme.qb1,
          ),
        ),
      ),
    );
  }
}

class _BoundaryForwardingScrollView extends StatefulWidget {
  final ScrollController parentScrollController;
  final EdgeInsetsGeometry padding;
  final bool reverse;
  final Widget child;

  const _BoundaryForwardingScrollView({
    required this.parentScrollController,
    required this.padding,
    required this.reverse,
    required this.child,
  });

  @override
  State<_BoundaryForwardingScrollView> createState() => _BoundaryForwardingScrollViewState();
}

class _BoundaryForwardingScrollViewState extends State<_BoundaryForwardingScrollView> {
  late final ScrollController _childScrollController = ScrollController();

  @override
  void dispose() {
    _childScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return NotificationListener<OverscrollNotification>(
      onNotification: _onOverscroll,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: SingleChildScrollView(
          controller: _childScrollController,
          padding: widget.padding,
          reverse: widget.reverse,
          child: widget.child,
        ),
      ),
    );
  }

  bool _onOverscroll(OverscrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final dragDelta = notification.dragDetails?.delta.dy;
    final delta = dragDelta == null ? _parentDeltaFromOverscroll(notification.overscroll) : -dragDelta;
    _forwardScrollControllerBy(widget.parentScrollController, delta);
    return false;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = event.scrollDelta.dy;
    if (delta == 0) return;
    if (_childCanScrollToward(delta)) return;
    _forwardScrollControllerBy(widget.parentScrollController, delta);
  }

  bool _childCanScrollToward(double delta) {
    if (!_childScrollController.hasClients) return false;
    final position = _childScrollController.position;
    if (!position.hasContentDimensions) return false;
    if (position.maxScrollExtent <= position.minScrollExtent) return false;

    const tolerance = .5;
    if (widget.reverse) {
      if (delta > 0) return position.pixels > position.minScrollExtent + tolerance;
      if (delta < 0) return position.pixels < position.maxScrollExtent - tolerance;
      return false;
    }

    if (delta > 0) return position.pixels < position.maxScrollExtent - tolerance;
    if (delta < 0) return position.pixels > position.minScrollExtent + tolerance;
    return false;
  }

  double _parentDeltaFromOverscroll(double overscroll) {
    if (!widget.reverse) return overscroll;
    return -overscroll;
  }
}

class _VerticalRule extends ConsumerWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final qb = ref.watch(P.app.qb);
    return Container(width: .5, color: qb.withValues(alpha: .15));
  }
}

String _autoScrollScript(int durationMs) {
  return """
(function() {
  var duration = Math.max(0, $durationMs);
  var start = window.scrollY || document.documentElement.scrollTop || 0;
  var end = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight) - window.innerHeight;
  if (end <= start || duration <= 0) {
    window.scrollTo(0, end);
    return;
  }
  var startTime = performance.now();
  function tick(now) {
    var progress = Math.min(1, (now - startTime) / duration);
    var eased = 1 - Math.pow(1 - progress, 3);
    window.scrollTo(0, start + (end - start) * eased);
    if (progress < 1) requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
})();
""";
}

String _previewBoundaryScrollScript() {
  return """
(function() {
  if (window.__rwkvWebDemoBoundaryForwardingInstalled) return;
  window.__rwkvWebDemoBoundaryForwardingInstalled = true;

  function scrollingElement() {
    return document.scrollingElement || document.documentElement || document.body;
  }

  function maxScrollTop(element) {
    return Math.max(0, element.scrollHeight - window.innerHeight);
  }

  function currentScrollTop(element) {
    return element.scrollTop || window.scrollY || document.documentElement.scrollTop || 0;
  }

  function atBoundary(deltaY) {
    var element = scrollingElement();
    var max = maxScrollTop(element);
    var top = currentScrollTop(element);
    if (max <= 1) return true;
    if (deltaY < 0 && top <= 1) return true;
    return deltaY > 0 && top >= max - 1;
  }

  function send(deltaY) {
    if (!atBoundary(deltaY)) return;
    if (!window.flutter_inappwebview || !window.flutter_inappwebview.callHandler) return;
    window.flutter_inappwebview.callHandler("webDemoPreviewBoundaryScroll", deltaY);
  }

  window.addEventListener("wheel", function(event) {
    send(event.deltaY || 0);
  }, { passive: true });

  var lastTouchY = null;
  window.addEventListener("touchstart", function(event) {
    if (!event.touches || event.touches.length === 0) return;
    lastTouchY = event.touches[0].clientY;
  }, { passive: true });

  window.addEventListener("touchmove", function(event) {
    if (lastTouchY === null) return;
    if (!event.touches || event.touches.length === 0) return;
    var nextY = event.touches[0].clientY;
    var deltaY = lastTouchY - nextY;
    lastTouchY = nextY;
    send(deltaY);
  }, { passive: true });

  window.addEventListener("touchend", function() {
    lastTouchY = null;
  }, { passive: true });
})();
""";
}

void _forwardScrollControllerBy(ScrollController controller, double delta) {
  if (delta == 0) return;
  if (!controller.hasClients) return;
  final position = controller.position;
  if (!position.hasContentDimensions) return;
  final next = (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
  if ((next - position.pixels).abs() < .1) return;
  position.jumpTo(next);
}

int _previewKey({
  required String html,
  required bool complete,
  required double autoScrollSeconds,
}) {
  final scrollKey = (autoScrollSeconds * 10).round();
  if (complete) return Object.hash(html.hashCode, scrollKey);
  return Object.hash(html.length ~/ 1800, scrollKey);
}
