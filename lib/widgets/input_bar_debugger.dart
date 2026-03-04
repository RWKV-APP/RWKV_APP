// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/theme_selector.dart';

extension _InputBarDebuggerVisiblePage on PageKey {
  bool get isInputBarDebuggerVisible => switch (this) {
    .chat => true,
    .see => true,
    .talk => true,
    .test2 => true,
    _ => false,
  };
}

class InputBarDebugger extends ConsumerWidget {
  const InputBarDebugger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final pageKey = ref.watch(P.app.pageKey);
    final shown = ref.watch(P.chat.inputBarDebuggerShown);
    final visible = pageKey.isInputBarDebuggerVisible && shown;
    final useBackdropFilterForInputOptions = ref.watch(P.ui.useBackdropFilterForInputOptions);
    final backdropFilterBgAlphaForInputOptions = ref.watch(P.ui.backdropFilterBgAlphaForInputOptions);
    final sigmaForBackdropFilterForInputOptions = ref.watch(P.ui.sigmaForBackdropFilterForInputOptions);
    final gradientStartForInputBar = ref.watch(P.ui.gradientStartForInputBar);
    final gradientForInputBar = ref.watch(P.ui.gradientForInputBar);

    final screenWidth = ref.watch(P.app.screenWidth);
    final paddingTop = MediaQuery.paddingOf(context).top;
    final panelWidth = screenWidth - 100;
    final maxPanelHeight = MediaQuery.sizeOf(context).height * .6;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCirc,
      right: 12,
      left: 12,
      top: visible ? paddingTop + 90 : -(maxPanelHeight + 40),
      child: AnimatedOpacity(
        opacity: visible ? .96 : 0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCirc,
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: panelWidth,
              constraints: BoxConstraints(
                minHeight: 120,
                maxHeight: maxPanelHeight,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: theme.colorScheme.outlineVariant, width: .5),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, right: 4, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '输入栏调试面板',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _onClosePressed,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                  Container(height: .5, color: theme.colorScheme.outlineVariant),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '已通过调试口令校验，当前页面已启用输入栏调试层。'
                            '\n说明：仅当「Alpha < 1 且 Sigma > 0」时，输入选项区域 BackdropFilter 才会自动启用。',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          _BackdropAlphaSliderSetting(
                            title: '输入选项区域 Alpha（背景不透明度）',
                            subtitle:
                                '控制输入栏上方功能按钮区域的背景透明度。'
                                '数值越小越透明，越能看见底层内容；当数值为 1 时表示完全不透明，会自动关闭该区域的模糊。',
                            value: backdropFilterBgAlphaForInputOptions,
                            backdropFilterEnabled: useBackdropFilterForInputOptions,
                            onChanged: _onInputOptionsAlphaChanged,
                          ),
                          const SizedBox(height: 8),
                          _BackdropSigmaSliderSetting(
                            title: '输入选项区域 Sigma（模糊强度）',
                            subtitle:
                                '控制输入栏上方功能按钮区域的模糊半径。'
                                '0 表示不模糊并会自动关闭该区域的模糊；值越大模糊越强。',
                            value: sigmaForBackdropFilterForInputOptions.toDouble(),
                            backdropFilterEnabled: useBackdropFilterForInputOptions,
                            onChanged: _onInputOptionsSigmaChanged,
                          ),
                          const SizedBox(height: 8),
                          _InputBarGradientSetting(
                            title: '输入栏背景渐变起点（Y）',
                            subtitle:
                                '控制输入栏背景渐变从哪里开始变化，对应 Alignment(0, y) 的 y。'
                                '该值越靠近 -1，渐变越偏向顶部开始；越靠近 1，开始位置越靠底部。'
                                '当起点被拖到高于终点时，终点会自动跟随起点。',
                            value: gradientStartForInputBar,
                            onChanged: _onInputBarGradientStartChanged,
                          ),
                          const SizedBox(height: 8),
                          _InputBarGradientSetting(
                            title: '输入栏背景渐变终点（Y）',
                            subtitle:
                                '控制输入栏背景渐变的终点纵坐标，对应 Alignment(0, y) 的 y。'
                                '取值范围 -1.0 到 1.0：-1 靠顶部，1 靠底部。'
                                '当终点被拖到低于起点时，起点会自动跟随终点。',
                            value: gradientForInputBar,
                            onChanged: _onInputBarGradientChanged,
                          ),
                          const SizedBox(height: 8),
                          const ThemeColorSettingSection(showDarkThemeTitle: false),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onClosePressed() {
    P.chat.inputBarDebuggerShown.q = false;
  }

  void _onInputOptionsAlphaChanged(double value) {
    final nextValue = ((value * 100).roundToDouble() / 100).clamp(0, 1).toDouble();
    P.ui.backdropFilterBgAlphaForInputOptions.q = nextValue;
  }

  void _onInputOptionsSigmaChanged(double value) {
    final nextValue = ((value * 10).roundToDouble() / 10).clamp(0, 32).toDouble();
    P.ui.sigmaForBackdropFilterForInputOptions.q = nextValue;
  }

  void _onInputBarGradientChanged(double value) {
    final nextValue = ((value * 100).roundToDouble() / 100).clamp(-1, 1).toDouble();
    P.ui.gradientForInputBar.q = nextValue;
  }

  void _onInputBarGradientStartChanged(double value) {
    final nextValue = ((value * 100).roundToDouble() / 100).clamp(-1, 1).toDouble();
    P.ui.gradientStartForInputBar.q = nextValue;
  }
}

class _BackdropAlphaSliderSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final bool backdropFilterEnabled;
  final ValueChanged<double> onChanged;

  const _BackdropAlphaSliderSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.backdropFilterEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final status = backdropFilterEnabled ? '当前状态：模糊已启用（Alpha < 1 且 Sigma > 0）' : '当前状态：模糊已关闭';
    final sliderValue = value.clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: borderColor, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sliderValue.toStringAsFixed(2),
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CupertinoSlider(
            value: sliderValue,
            min: 0,
            max: 1,
            divisions: 100,
            onChanged: onChanged,
          ),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BackdropSigmaSliderSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final bool backdropFilterEnabled;
  final ValueChanged<double> onChanged;

  const _BackdropSigmaSliderSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.backdropFilterEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final status = backdropFilterEnabled ? '当前状态：模糊已启用（Alpha < 1 且 Sigma > 0）' : '当前状态：模糊已关闭';
    final sliderValue = value.toDouble().clamp(0, 32).toDouble();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: borderColor, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sliderValue.toStringAsFixed(1),
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CupertinoSlider(
            value: sliderValue,
            min: 0,
            max: 32,
            divisions: 320,
            onChanged: onChanged,
          ),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _InputBarGradientSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final ValueChanged<double> onChanged;

  const _InputBarGradientSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final sliderValue = value.clamp(-1, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: borderColor, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sliderValue.toStringAsFixed(2),
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CupertinoSlider(
            value: sliderValue,
            min: -1,
            max: 1,
            divisions: 200,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
