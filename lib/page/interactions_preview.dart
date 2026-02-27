import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:halo/halo.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/interactions.dart';

class PageInteractionsPreview extends ConsumerWidget {
  const PageInteractionsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
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
            "每组展示 5 个按钮在三种状态下的视觉效果：不可用 / 可用 / 已启用",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: qb.q(.7),
            ),
          ),
          const SizedBox(height: 16),
          const _StateSection(
            title: "不可用, 没有模型",
            state: InteractionVisualState.unavailable,
            description: "在未选择模型的情况下，这些项都不可点。",
          ),
          const SizedBox(height: 12),
          const _StateSection(
            title: "可用 / 可点击 / 默认 / 已经是降级处理的(比如思考关闭)",
            state: InteractionVisualState.available,
            description: "",
          ),
          const SizedBox(height: 12),
          const _StateSection(
            title: "启用中 / 非默认值",
            state: InteractionVisualState.enabled,
            description: "",
            details: [
              "(a) 从推理快切换到了推理高或推理英长",
              "(b) 开启了并行推理",
              "(c) 开启了文言文开关 / 古今",
              "(d) 开启了互联网搜索 / 深度",
            ],
          ),
        ],
      ),
    );
  }
}

class _StateSection extends ConsumerWidget {
  final String title;
  final InteractionVisualState state;
  final String description;
  final List<String> details;

  const _StateSection({
    required this.title,
    required this.state,
    required this.description,
    this.details = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(12),
        border: .all(color: qb.q(.12)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: qb.q(.92),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 0.5,
            color: qb.q(.16),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: qb.q(.75),
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
                    color: qb.q(.72),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          _InteractionsPreviewRow(state: state),
        ],
      ),
    );
  }
}

class _InteractionsPreviewRow extends ConsumerWidget {
  final InteractionVisualState state;

  const _InteractionsPreviewRow({
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(fontSize) + 20;
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        child: Padding(
          padding: .symmetric(horizontal: appTheme.inputBarHorizontalPadding),
          child: Row(
            children: [
              _WebSearchPreviewButton(state: state),
              const SizedBox(width: 4),
              _ThinkingPreviewButton(state: state),
              const SizedBox(width: 4),
              _DecodePreviewButton(state: state),
              const SizedBox(width: 4),
              _BatchPreviewButton(state: state),
              const SizedBox(width: 4),
              _BatchPreviewButton(
                state: state,
                alt: true,
              ),
              const SizedBox(width: 4),
              _WenyanPreviewButton(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonShell extends ConsumerWidget {
  final InteractionVisualState state;
  final Widget child;

  const _ButtonShell({
    required this.state,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final InteractionVisualColors colors = interactionVisualColors(
      appTheme: appTheme,
      state: state,
    );
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final textColor = colors.foreground;

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
          color: textColor,
          size: appTheme.inputBarInteractionsIconSize,
        ),
        child: DefaultTextStyle(
          style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
          child: child,
        ),
      ),
    );
  }
}

class _WebSearchPreviewButton extends ConsumerWidget {
  final InteractionVisualState state;

  const _WebSearchPreviewButton({
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showDeepLabel = state == InteractionVisualState.enabled;
    return _ButtonShell(
      state: state,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.travel_explore),
          if (showDeepLabel) ...[
            const SizedBox(width: 2),
            const Text("深度"),
          ],
        ],
      ),
    );
  }
}

class _ThinkingPreviewButton extends ConsumerWidget {
  final InteractionVisualState state;

  const _ThinkingPreviewButton({
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final bool enabled = state == InteractionVisualState.enabled;
    final InteractionVisualColors colors = interactionVisualColors(
      appTheme: appTheme,
      state: state,
    );
    return _ButtonShell(
      state: state,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            Assets.img.chat.think,
            colorFilter: .mode(colors.foreground, BlendMode.srcIn),
            width: appTheme.inputBarInteractionsIconSize,
            height: appTheme.inputBarInteractionsIconSize,
          ),
          const SizedBox(width: 4),
          Text(
            enabled ? "高" : "快",
            style: TS(c: colors.foreground, s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _DecodePreviewButton extends ConsumerWidget {
  final InteractionVisualState state;

  const _DecodePreviewButton({
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final bool enabled = state == InteractionVisualState.enabled;
    final InteractionVisualColors colors = interactionVisualColors(
      appTheme: appTheme,
      state: state,
    );
    return _ButtonShell(
      state: state,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.auto_awesome, color: colors.foreground, size: appTheme.inputBarInteractionsIconSize),
          const SizedBox(width: 4),
          Text(
            enabled ? "创意" : "默认",
            style: TS(c: colors.foreground, s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
          ),
        ],
      ),
    );
  }
}

class _BatchPreviewButton extends ConsumerWidget {
  final InteractionVisualState state;
  final bool alt;

  const _BatchPreviewButton({
    required this.state,
    this.alt = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final bool enabled = state == InteractionVisualState.enabled;
    final InteractionVisualColors colors = interactionVisualColors(
      appTheme: appTheme,
      state: state,
    );
    return _ButtonShell(
      state: state,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(alt ? Symbols.playlist_play : Symbols.airware, color: colors.foreground, size: appTheme.inputBarInteractionsIconSize),
          if (enabled) ...[
            const SizedBox(width: 4),
            Text(
              "× 2",
              style: TS(c: colors.foreground, s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _WenyanPreviewButton extends ConsumerWidget {
  final InteractionVisualState state;

  const _WenyanPreviewButton({
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool enabled = state == InteractionVisualState.enabled;
    final InteractionVisualColors colors = interactionVisualColors(
      appTheme: ref.watch(P.app.theme),
      state: state,
    );
    return _ButtonShell(
      state: state,
      child: Text(
        enabled ? "古今" : "文言",
        style: TS(c: colors.foreground, s: theme.textTheme.bodyMedium?.fontSize ?? 14, height: 1, w: .w500),
      ),
    );
  }
}
