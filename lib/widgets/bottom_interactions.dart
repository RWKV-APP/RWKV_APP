// ignore: unused_import

import 'dart:io';

import 'package:flutter/cupertino.dart';
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
import 'package:zone/widgets/see/select_image_button.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/performance_info.dart';

class BottomInteractions extends ConsumerWidget {
  final DemoType preferredDemoType;

  static double calculateButtonHeight(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context);
    return textScaleFactor.scale(14) + 20;
  }

  const BottomInteractions({
    super.key,
    required this.preferredDemoType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const .only(top: 8),
      child: Row(
        children: [
          Expanded(child: _Interactions(preferredDemoType: preferredDemoType)),
          _SendingInteraction(preferredDemoType: preferredDemoType),
        ],
      ),
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
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: .center,
      children: [
        if (preferredDemoType == .see) const IntrinsicWidth(child: SelectImageButton()),
        if (features.webSearch && preferredDemoType == .chat) const _WebSearchModeButton(),
        if (preferredDemoType == .chat) const ThinkingModeButton(),
        if (!isAlbatrossLoaded && preferredDemoType == .chat && currentLangIsZh && currentModelIsBefore20250922)
          const SecondaryOptionsButton(),
        if (!isAlbatrossLoaded && preferredDemoType == .chat) const DecodeParamButton(),
        if (!isAlbatrossLoaded && preferredDemoType == .chat) const BatchButton(),
        if (preferredDemoType == .chat && currentLangIsZh) const _WenYanWenButton(),
      ],
    );
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

    final height = BottomInteractions.calculateButtonHeight(context);
    const EdgeInsets padding = .only(left: 8);
    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: 60.r,
          ),
          child: Row(
            children: [
              Icon(Icons.travel_explore, color: textColor, size: 16),
              2.w,
              T(
                webSearchMode == WebSearchMode.deepSearch ? s.deep_web_search : s.web_search,
                s: TS(c: textColor, s: 14, height: 1, w: .w500),
              ),
              4.w,
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

    final height = BottomInteractions.calculateButtonHeight(context);

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
            borderRadius: 60.r,
            border: Border.all(color: theme.colorScheme.primary.q(.1), width: 1),
          ),
          alignment: .center,
          child: T(
            label,
            s: TS(c: textColor, s: 14, height: 1, w: .w500),
          ),
        ),
      ),
    );
  }
}

class _SendingInteraction extends ConsumerWidget {
  final DemoType preferredDemoType;

  const _SendingInteraction({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generating = ref.watch(P.rwkv.generating);
    final hiddenPrefilling = ref.watch(P.rwkv.hiddenPrefilling);
    // final waitingImagePath = ref.watch(P.see.waitingImagePath);
    final waitingText = ref.watch(P.see.waitingText);

    if (!generating || (hiddenPrefilling && waitingText == null)) return _Send(preferredDemoType: preferredDemoType);

    return const _Stop();
  }
}

class _Send extends ConsumerWidget {
  final DemoType preferredDemoType;
  const _Send({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;

    final editingBotMessage = ref.watch(P.msg.editingBotMessage);
    final inSee = ref.watch(P.app.pageKey) == .see;
    final imagePath = ref.watch(P.see.imagePath);
    final hasAtLeastOneImage = ref.watch(P.msg.hasAtLeastOneImage);
    final inputHasContent = ref.watch(P.chat.inputHasContent);

    double opacity = 1.0;

    if (inSee) opacity = ((imagePath != null || hasAtLeastOneImage) && inputHasContent) ? 1 : .333;

    return AnimatedOpacity(
      opacity: opacity,
      duration: 250.ms,
      child: GestureDetector(
        onTap: () => P.chat.onSendButtonPressed(preferredDemoType: preferredDemoType),
        child: Container(
          padding: const .symmetric(horizontal: 10, vertical: 5),
          child: Icon(
            (Platform.isIOS || Platform.isMacOS)
                ? editingBotMessage
                      ? CupertinoIcons.pencil_circle_fill
                      : CupertinoIcons.arrow_up_circle_fill
                : editingBotMessage
                ? Icons.edit
                : Icons.send_rounded,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: P.chat.onStopButtonPressed,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Stack(
          children: [
            SizedBox(
              width: 46,
              height: 34,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: 2.r),
                  width: 12,
                  height: 12,
                ),
              ),
            ),
            SizedBox(
              width: 46,
              height: 34,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: color.q(.5),
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
