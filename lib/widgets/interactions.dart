// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/wenyan_mode.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/batch_button.dart';
import 'package:zone/widgets/chat/decode_param_button.dart';
import 'package:zone/widgets/chat/interaction_visual_state.dart';
import 'package:zone/widgets/chat/secondary_options_button.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';

class InputInteractions extends ConsumerWidget {
  final DemoType preferredDemoType;

  static double calculateButtonHeight(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context);
    return textScaleFactor.scale(14) + 20;
  }

  const InputInteractions({
    super.key,
    required this.preferredDemoType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(color: kC),
      child: _Interactions(preferredDemoType: preferredDemoType),
    );
  }
}

class _Interactions extends ConsumerWidget {
  final DemoType preferredDemoType;

  const _Interactions({this.preferredDemoType = .chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(P.app.featureRollout);
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    final currentModelIsBefore20250922 = ref.watch(P.rwkv.currentModelIsBefore20250922);
    final isAlbatrossLoaded = ref.watch(P.rwkv.isAlbatrossLoaded);

    final children = [
      if (features.webSearch && preferredDemoType == .chat) const _WebSearchModeButton(),
      if (!isAlbatrossLoaded && preferredDemoType == .chat) const DecodeParamButton(),
      if (!isAlbatrossLoaded && preferredDemoType == .chat && currentLangIsZh && currentModelIsBefore20250922)
        const SecondaryOptionsButton(),
      if (preferredDemoType == .chat) const ThinkingModeButton(),
      if (!isAlbatrossLoaded && preferredDemoType == .chat) const BatchButton(),
      if (preferredDemoType == .chat && currentLangIsZh) const _WenYanWenButton(),
    ];

    final appTheme = ref.watch(P.app.theme);
    final inputBarHorizontalPadding = appTheme.inputBarHorizontalPadding;

    if (children.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: InputInteractions.calculateButtonHeight(context),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: .symmetric(horizontal: inputBarHorizontalPadding),
        scrollDirection: .horizontal,
        itemBuilder: (context, index) {
          return children[index];
        },
        itemCount: children.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 4);
        },
      ),
    );
  }
}

class _WebSearchModeButton extends ConsumerWidget {
  const _WebSearchModeButton();

  void _onTap() {
    P.chat.onWebSearchModeTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    final loading = ref.watch(P.rwkv.loading);
    final loaded = ref.watch(P.rwkv.loaded);
    final generating = ref.watch(P.rwkv.generating);
    final webSearchMode = ref.watch(P.chat.webSearchMode);

    final canEnable = loaded && !loading && !generating;
    final interactionState = switch ((canEnable, webSearchMode)) {
      (false, _) => InteractionVisualState.unavailable,
      (true, .off) => InteractionVisualState.idleInteractive,
      (true, .search) => InteractionVisualState.available,
      (true, .deepSearch) => InteractionVisualState.enabled,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final color = colors.background;
    final textColor = colors.foreground;
    final borderColor = colors.border;
    final actionColor = textColor;
    final backgroundColor = color;
    final actionBorderColor = borderColor;
    final showDeepLabel = webSearchMode == .deepSearch;
    final deepLabel = currentLangIsZh ? "深度" : "Deep";

    final height = InputInteractions.calculateButtonHeight(context);
    const EdgeInsets padding = .symmetric(horizontal: 8);
    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: .circular(60),
            border: .all(color: actionBorderColor),
          ),
          child: Row(
            children: [
              Icon(Symbols.travel_explore, color: actionColor, size: 18),
              if (showDeepLabel) ...[
                const SizedBox(width: 2),
                Text(
                  deepLabel,
                  style: TS(c: actionColor, s: fontSize, height: 1, w: .w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WenYanWenButton extends ConsumerWidget {
  const _WenYanWenButton();

  void _onTap() {
    P.chat.onWenYanWenTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final appTheme = ref.watch(P.app.theme);
    final mode = ref.watch(P.chat.wenYanWen);
    final model = ref.watch(P.rwkv.latestModel);
    final loading = ref.watch(P.rwkv.loading);
    final generating = ref.watch(P.rwkv.generating);

    final height = InputInteractions.calculateButtonHeight(context);
    final canEnable = model != null && !loading && !generating;
    final interactionState = switch ((canEnable, mode)) {
      (false, _) => InteractionVisualState.unavailable,
      (true, WenyanMode.off) => InteractionVisualState.idleInteractive,
      (true, WenyanMode.classic) => InteractionVisualState.available,
      (true, WenyanMode.mixed) => InteractionVisualState.enabled,
    };
    final colors = interactionVisualColors(appTheme: appTheme, state: interactionState);
    final bgColor = colors.background;
    final textColor = colors.foreground;
    final borderColor = colors.border;
    final String label = switch (mode) {
      WenyanMode.off => "文言",
      WenyanMode.classic => "文言",
      WenyanMode.mixed => "古今",
    };

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          height: height,
          padding: const .symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: .circular(60),
            border: .all(color: borderColor, width: 1),
          ),
          alignment: .center,
          child: Text(
            label,
            style: TS(c: textColor, s: fontSize, height: 1, w: .w500),
          ),
        ),
      ),
    );
  }
}
