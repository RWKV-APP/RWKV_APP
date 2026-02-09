// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/web_search_mode.dart';
import 'package:zone/model/wenyan_mode.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/batch_button.dart';
import 'package:zone/widgets/chat/decode_param_button.dart';
import 'package:zone/widgets/chat/secondary_options_button.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';
import 'package:zone/widgets/model_selector.dart';

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
      if (preferredDemoType == .chat) const ThinkingModeButton(),
      if (!isAlbatrossLoaded && preferredDemoType == .chat && currentLangIsZh && currentModelIsBefore20250922)
        const SecondaryOptionsButton(),
      if (!isAlbatrossLoaded && preferredDemoType == .chat) const DecodeParamButton(),
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

    // return Wrap(
    //   spacing: 4,
    //   runSpacing: 4,
    //   crossAxisAlignment: .center,
    //   alignment: .start,
    //   children: children,
    // );
  }
}

class _WebSearchModeButton extends ConsumerWidget {
  const _WebSearchModeButton();

  void _onTap() {
    P.chat.onSwitchWebSearchMode(P.chat.webSearchMode.q == WebSearchMode.off ? WebSearchMode.search : WebSearchMode.off);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final webSearchMode = ref.watch(P.chat.webSearchMode);

    final enabled = webSearchMode != WebSearchMode.off;
    final color = enabled ? primary : theme.colorScheme.surfaceContainer;
    final textColor = enabled ? theme.colorScheme.onPrimary : Colors.grey;

    final height = InputInteractions.calculateButtonHeight(context);
    const EdgeInsets padding = .only(left: 8);
    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: .circular(60),
          ),
          child: Row(
            children: [
              Icon(Icons.travel_explore, color: textColor, size: 16),
              const SizedBox(width: 2),
              Text(
                webSearchMode == WebSearchMode.deepSearch ? s.deep_web_search : s.web_search,
                style: TS(c: textColor, s: 14, height: 1, w: .w500),
              ),
              const SizedBox(width: 4),
              VerticalDivider(width: 2, indent: 8, endIndent: 8, color: textColor),
              PopupMenuButton(
                offset: const Offset(-30, -80),
                itemBuilder: (c) {
                  return [
                    PopupMenuItem(value: WebSearchMode.off, child: Text(s.off)),
                    PopupMenuItem(value: WebSearchMode.search, child: Text(s.web_search)),
                    PopupMenuItem(value: WebSearchMode.deepSearch, child: Text(s.deep_web_search)),
                  ];
                },
                onSelected: (mode) {
                  P.chat.onSwitchWebSearchMode(mode);
                },
                initialValue: webSearchMode,
                popUpAnimationStyle: AnimationStyle(
                  curve: Curves.linear,
                  duration: 250.ms,
                  reverseCurve: Curves.linear,
                  reverseDuration: 250.ms,
                ),
                child: Container(
                  height: height,
                  padding: const .symmetric(horizontal: 4),
                  alignment: .center,
                  child: Icon(Icons.expand_more_outlined, color: textColor, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WenYanWenButton extends ConsumerWidget {
  const _WenYanWenButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(P.chat.wenYanWen);
    final model = ref.watch(P.rwkv.latestModel);

    final height = InputInteractions.calculateButtonHeight(context);

    final bgColor = mode == WenyanMode.off ? theme.colorScheme.surfaceContainer : theme.colorScheme.primary;

    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final textColor = mode != WenyanMode.off ? qw.q(1) : qb.q(.667);

    String label = '';
    if (mode == WenyanMode.off) {
      label = '文言';
    } else if (mode == WenyanMode.classic) {
      label = '文言';
    } else if (mode == WenyanMode.mixed) {
      label = '古今';
    }

    return IntrinsicWidth(
      child: PopupMenuButton(
        offset: const Offset(-30, -80),
        itemBuilder: (c) {
          return [
            const PopupMenuItem(value: WenyanMode.off, child: Text('文言: 关')),
            const PopupMenuItem(value: WenyanMode.classic, child: Text('文言: 开')),
            const PopupMenuItem(value: WenyanMode.mixed, child: Text('古今')),
          ];
        },
        onSelected: (m) {
          if (model == null) {
            ModelSelector.show();
            return;
          }
          if (!model.tags.contains('batch') && m == WenyanMode.mixed) {
            Alert.warning(S.current.this_model_does_not_support_batch_inference);
            return;
          }
          P.chat.onSwitchWenYanWen(m);
        },
        initialValue: mode,
        popUpAnimationStyle: AnimationStyle(
          curve: Curves.linear,
          duration: 250.ms,
          reverseCurve: Curves.linear,
          reverseDuration: 250.ms,
        ),
        child: Container(
          height: height,
          padding: const .symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: .circular(60),
            border: .all(color: theme.colorScheme.primary.q(.1), width: 1),
          ),
          alignment: .center,
          child: Text(
            label,
            style: TS(c: textColor, s: 14, height: 1, w: .w500),
          ),
        ),
      ),
    );
  }
}
