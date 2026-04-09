// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:halo/halo.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/input_interactions.dart';

enum _PreviewInteractionState {
  unavailable,
  idleInteractive,
  available,
  enabled,
  defaultOnBatchModel,
}

InteractionVisualColors _previewInteractionVisualColors({
  required AppTheme appTheme,
  required _PreviewInteractionState state,
}) {
  switch (state) {
    case .unavailable:
      return interactionVisualColors(
        appTheme: appTheme,
        state: .unavailable,
      );
    case .available:
      return interactionVisualColors(
        appTheme: appTheme,
        state: .available,
      );
    case .enabled:
      return interactionVisualColors(
        appTheme: appTheme,
        state: .enabled,
      );
    case .idleInteractive:
      final unavailableColors = interactionVisualColors(
        appTheme: appTheme,
        state: .unavailable,
      );
      final availableColors = interactionVisualColors(
        appTheme: appTheme,
        state: .available,
      );
      return InteractionVisualColors(
        background:
            Color.lerp(
              unavailableColors.background,
              availableColors.background,
              .55,
            ) ??
            availableColors.background,
        foreground:
            Color.lerp(
              unavailableColors.foreground,
              availableColors.foreground,
              .45,
            ) ??
            availableColors.foreground,
        border:
            Color.lerp(
              unavailableColors.border,
              availableColors.border,
              .5,
            ) ??
            availableColors.border,
      );
    case .defaultOnBatchModel:
      return interactionVisualColors(
        appTheme: appTheme,
        state: .available,
      );
  }
}

class PageInteractionsPreview extends ConsumerWidget {
  const PageInteractionsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final preferredDarkTheme = ref.watch(P.preference.preferredDarkCustomTheme);
    final darkTheme = preferredDarkTheme == AppTheme.light ? AppTheme.lightsOut : preferredDarkTheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    const double paneGap = 12;
    final preferredPaneWidth = (viewportWidth - 32 - paneGap) / 2;
    final double paneWidth = preferredPaneWidth < 560 ? 560 : preferredPaneWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text("底部交互状态预览"),
      ),
      body: ListView(
        padding: const .all(16),
        children: [
          Text(
            "纯 UI 展示页（无业务逻辑）",
            style: TS(
              s: 16,
              w: .w600,
              c: qb,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "横向双栏对照：左侧浅色模式，右侧当前深色模式；五状态均仅用黑白灰表达。",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: qb.q(.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "联网模式映射：状态2=关闭，状态3=开启，状态4=深度。",
            style: theme.textTheme.bodySmall?.copyWith(
              color: qb.q(.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "按钮下方模式标签采用简写：S1~S4 代表对应状态层级。",
            style: theme.textTheme.bodySmall?.copyWith(
              color: qb.q(.55),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: .horizontal,
            child: Row(
              crossAxisAlignment: .start,
              children: [
                C(
                  decoration: BD(
                    color: AppTheme.light.scaffoldBg,
                    borderRadius: .circular(12),
                    border: .all(color: AppTheme.light.qb0.q(.14)),
                  ),
                  width: paneWidth,
                  child: const _ThemePreviewPane(
                    modeLabel: "浅色模式",
                    previewTheme: AppTheme.light,
                  ),
                ),
                const SizedBox(width: paneGap),
                C(
                  decoration: BD(
                    color: darkTheme.scaffoldBg,
                    borderRadius: .circular(12),
                    border: .all(color: darkTheme.qb0.q(.14)),
                  ),
                  width: paneWidth,
                  child: _ThemePreviewPane(
                    modeLabel: "深色模式",
                    previewTheme: darkTheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewPane extends StatelessWidget {
  final String modeLabel;
  final AppTheme previewTheme;

  const _ThemePreviewPane({
    required this.modeLabel,
    required this.previewTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = previewTheme.qb0;
    final secondaryText = previewTheme.qb0.q(.72);

    return Container(
      padding: const .all(4),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            modeLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "1不可用 / 2待机可交互 / 3可用 / 4已启用 / 5并行模型默认",
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          _StateSection(
            previewTheme: previewTheme,
            title: "1. 不可用（没有模型，不可点击）",
            state: _PreviewInteractionState.unavailable,
            description: "在未选择模型的情况下，这些项都不可点。",
            details: const [
              "联网：不可用",
              "思考：不可用",
              "风格：不可用",
              "并行：不可用",
              "表达模式：不可用",
            ],
          ),
          const SizedBox(height: 10),
          _StateSection(
            previewTheme: previewTheme,
            title: "2. 待机可交互（新增灰阶层级）",
            state: _PreviewInteractionState.idleInteractive,
            description: "可以交互，但还未进入默认工作态。视觉上介于不可用与可用之间，仅用灰阶表达。",
            details: const [
              "联网：关闭（状态2）",
              "思考：关（状态2）",
              "风格：默认（视觉按状态3）",
              "并行：关闭",
              "表达模式：今（状态2）",
            ],
          ),
          const SizedBox(height: 10),
          _StateSection(
            previewTheme: previewTheme,
            title: "3. 可用（可点击，默认状态）",
            state: _PreviewInteractionState.available,
            description: "默认状态下，按钮可点击但尚未启用非默认配置。",
            details: const [
              "联网：开启（状态3）",
              "思考：快（状态3）",
              "风格：默认（状态3）",
              "并行：关闭",
              "表达模式：今（状态3）",
            ],
          ),
          const SizedBox(height: 10),
          _StateSection(
            previewTheme: previewTheme,
            title: "4. 启用中（非默认值）",
            state: _PreviewInteractionState.enabled,
            description: "从默认切换到非默认配置时，进入启用中状态。",
            details: const [
              "联网：深度（状态4）",
              "思考：高 / 英短 / 英长（状态4）",
              "风格：非默认参数（如创意），但视觉仍按状态3",
              "并行：开启 ×2",
              "表达模式：今 / 古 / 猫（状态4）",
            ],
          ),
          const SizedBox(height: 10),
          _StateSection(
            previewTheme: previewTheme,
            title: "5. 默认状态（已选支持并行模型）",
            state: _PreviewInteractionState.defaultOnBatchModel,
            description: "用户已选择支持并行思考的模型后的默认展示状态。",
            details: const [
              "联网：关闭（按状态2）",
              "思考：快（按状态3）",
              "风格：默认（按状态3）",
              "并行：关闭（按状态3）",
              "表达模式：今（按状态2）",
            ],
          ),
        ],
      ),
    );
  }
}

class _StateSection extends StatelessWidget {
  final AppTheme previewTheme;
  final String title;
  final _PreviewInteractionState state;
  final String description;
  final List<String> details;

  const _StateSection({
    required this.previewTheme,
    required this.title,
    required this.state,
    required this.description,
    this.details = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = previewTheme.qb0;
    final secondaryText = previewTheme.qb0.q(.72);

    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: previewTheme.scaffoldBg,
        borderRadius: .circular(12),
        border: .all(color: previewTheme.qb0.q(.12)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 0.5,
            color: previewTheme.qb0.q(.16),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: secondaryText,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final String detail in details)
              Padding(
                padding: const .only(top: 2),
                child: Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          _InteractionsPreviewRow(
            previewTheme: previewTheme,
            state: state,
          ),
        ],
      ),
    );
  }
}

class _InteractionsPreviewRow extends StatelessWidget {
  final AppTheme previewTheme;
  final _PreviewInteractionState state;

  const _InteractionsPreviewRow({
    required this.previewTheme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(fontSize) + 20;
    final modeLabels = _modeLabelsForState(state);

    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          height: height,
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            child: Padding(
              padding: .symmetric(horizontal: previewTheme.inputBarHorizontalPadding),
              child: Row(
                children: [
                  _WebSearchPreviewButton(
                    previewTheme: previewTheme,
                    state: state,
                  ),
                  const SizedBox(width: 4),
                  _ThinkingPreviewButton(
                    previewTheme: previewTheme,
                    state: state,
                  ),
                  const SizedBox(width: 4),
                  _DecodePreviewButton(
                    previewTheme: previewTheme,
                    state: state,
                  ),
                  const SizedBox(width: 4),
                  _BatchPreviewButton(
                    previewTheme: previewTheme,
                    state: state,
                  ),
                  const SizedBox(width: 4),
                  _WenyanPreviewButton(
                    previewTheme: previewTheme,
                    state: state,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: .symmetric(horizontal: previewTheme.inputBarHorizontalPadding),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final String label in modeLabels)
                Container(
                  padding: const .symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: previewTheme.qb0.q(.08),
                    borderRadius: .circular(6),
                    border: .all(color: previewTheme.qb0.q(.18)),
                  ),
                  child: Text(
                    label,
                    style: TS(
                      s: 11,
                      c: previewTheme.qb0.q(.78),
                      height: 1.1,
                      w: .w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

List<String> _modeLabelsForState(_PreviewInteractionState state) {
  return switch (state) {
    _PreviewInteractionState.unavailable => [
      "联网 不可用(S1)",
      "思考 不可用(S1)",
      "风格 不可用(S1)",
      "并行 不可用(S1)",
      "表达模式 不可用(S1)",
    ],
    _PreviewInteractionState.idleInteractive => [
      "联网 关(S2)",
      "思考 关(S2)",
      "风格 默认(S3)",
      "并行 关(S3)",
      "表达模式 今(S2)",
    ],
    _PreviewInteractionState.available => [
      "联网 开(S3)",
      "思考 快(S3)",
      "风格 默认(S3)",
      "并行 关(S3)",
      "表达模式 今(S3)",
    ],
    _PreviewInteractionState.enabled => [
      "联网 深度(S4)",
      "思考 高/英短/英长(S4)",
      "风格 创意(S3)",
      "并行 ×2(S4)",
      "表达模式 今/古/猫(S4)",
    ],
    _PreviewInteractionState.defaultOnBatchModel => [
      "联网 关(S2)",
      "思考 快(S3)",
      "风格 默认(S3)",
      "并行 关(S3)",
      "表达模式 今(S2)",
    ],
  };
}

class _ButtonShell extends StatelessWidget {
  final AppTheme previewTheme;
  final _PreviewInteractionState state;
  final Widget child;

  const _ButtonShell({
    required this.previewTheme,
    required this.state,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _previewInteractionVisualColors(
      appTheme: previewTheme,
      state: state,
    );
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;

    return Container(
      height: InputInteractions.calculateButtonHeight(context),
      padding: const .symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: .circular(60),
        border: .all(color: colors.border),
      ),
      alignment: .center,
      child: IconTheme(
        data: IconThemeData(
          color: colors.foreground,
          size: previewTheme.inputBarInteractionsIconSize,
        ),
        child: DefaultTextStyle(
          style: TS(c: colors.foreground, s: fontSize, height: 1, w: .w500),
          child: child,
        ),
      ),
    );
  }
}

class _WebSearchPreviewButton extends StatelessWidget {
  final AppTheme previewTheme;
  final _PreviewInteractionState state;

  const _WebSearchPreviewButton({
    required this.previewTheme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDeepLabel = state == _PreviewInteractionState.enabled;
    final _PreviewInteractionState visualState = switch (state) {
      _PreviewInteractionState.defaultOnBatchModel => .idleInteractive,
      _ => state,
    };

    return _ButtonShell(
      previewTheme: previewTheme,
      state: visualState,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.travel_explore, size: previewTheme.inputBarInteractionsIconSize),
          if (showDeepLabel) ...[
            const SizedBox(width: 2),
            Text(
              "深度",
              style: TS(s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThinkingPreviewButton extends StatelessWidget {
  final AppTheme previewTheme;
  final _PreviewInteractionState state;

  const _ThinkingPreviewButton({
    required this.previewTheme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _previewInteractionVisualColors(
      appTheme: previewTheme,
      state: state,
    );
    final thinkingLabel = switch (state) {
      _PreviewInteractionState.unavailable => "关",
      _PreviewInteractionState.idleInteractive => "关",
      _PreviewInteractionState.available => "快",
      _PreviewInteractionState.enabled => "高",
      _PreviewInteractionState.defaultOnBatchModel => "快",
    };
    final _PreviewInteractionState visualState = switch (state) {
      _PreviewInteractionState.defaultOnBatchModel => .available,
      _ => state,
    };

    return _ButtonShell(
      previewTheme: previewTheme,
      state: visualState,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            Assets.img.chat.think,
            colorFilter: .mode(colors.foreground, BlendMode.srcIn),
            width: previewTheme.inputBarInteractionsIconSize,
            height: previewTheme.inputBarInteractionsIconSize,
          ),
          const SizedBox(width: 4),
          Text(
            thinkingLabel,
            style: TS(s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _DecodePreviewButton extends StatelessWidget {
  final AppTheme previewTheme;
  final _PreviewInteractionState state;

  const _DecodePreviewButton({
    required this.previewTheme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnavailable = state == _PreviewInteractionState.unavailable;
    final _PreviewInteractionState visualState = isUnavailable ? .unavailable : .available;
    final showingCreative = state == _PreviewInteractionState.enabled;

    return _ButtonShell(
      previewTheme: previewTheme,
      state: visualState,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.auto_awesome, size: previewTheme.inputBarInteractionsIconSize),
          const SizedBox(width: 4),
          Text(
            showingCreative ? "创意" : "默认",
            style: TS(s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
          ),
        ],
      ),
    );
  }
}

class _BatchPreviewButton extends StatelessWidget {
  final AppTheme previewTheme;
  final _PreviewInteractionState state;

  const _BatchPreviewButton({
    required this.previewTheme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = state == _PreviewInteractionState.enabled;
    final _PreviewInteractionState visualState = switch (state) {
      _PreviewInteractionState.unavailable => .unavailable,
      _PreviewInteractionState.enabled => .enabled,
      _ => .available,
    };

    return _ButtonShell(
      previewTheme: previewTheme,
      state: visualState,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.playlist_play, size: previewTheme.inputBarInteractionsIconSize),
          if (enabled) ...[
            const SizedBox(width: 4),
            Text(
              "2",
              style: TS(s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _WenyanPreviewButton extends StatelessWidget {
  final AppTheme previewTheme;
  final _PreviewInteractionState state;

  const _WenyanPreviewButton({
    required this.previewTheme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _PreviewInteractionState visualState = switch (state) {
      _PreviewInteractionState.unavailable => .unavailable,
      _PreviewInteractionState.idleInteractive => .idleInteractive,
      _PreviewInteractionState.available => .available,
      _PreviewInteractionState.enabled => .enabled,
      _PreviewInteractionState.defaultOnBatchModel => .idleInteractive,
    };

    return _ButtonShell(
      previewTheme: previewTheme,
      state: visualState,
      child: Text(
        "表达模式",
        style: TS(s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
      ),
    );
  }
}
