// ignore: unused_import

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/store/web_search_mode.dart';
import 'package:zone/widgets/chat/batch_button.dart';
import 'package:zone/widgets/chat/secondary_options_button.dart';
import 'package:zone/widgets/chat/select_image_button.dart';
import 'package:zone/widgets/chat/thinking_mode_button.dart';
import 'package:zone/widgets/performance_info.dart';

class BottomInteractions extends ConsumerWidget {
  final DemoType preferredDemoType;

  const BottomInteractions({
    super.key,
    this.preferredDemoType = DemoType.chat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EI.o(t: 8),
      child: Row(
        children: [
          Expanded(child: _Interactions(preferredDemoType: preferredDemoType)),
          _MessageButton(),
        ],
      ),
    );
  }
}

class _Interactions extends ConsumerWidget {
  final DemoType preferredDemoType;
  const _Interactions({this.preferredDemoType = DemoType.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(P.app.featureRollout);
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    final currentModelIsBefore20250922 = ref.watch(P.rwkv.currentModelIsBefore20250922);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (preferredDemoType == DemoType.world) const IntrinsicWidth(child: SelectImageButton()),
        if (features.webSearch && preferredDemoType == DemoType.chat) const _WebSearchModeButton(),
        if (preferredDemoType == DemoType.chat) const ThinkingModeButton(),
        if (preferredDemoType == DemoType.chat && currentLangIsZh && currentModelIsBefore20250922) const SecondaryOptionsButton(),
        if (preferredDemoType == DemoType.chat) const BatchButton(),
        if (preferredDemoType == DemoType.chat && currentLangIsZh) const _WenYanWenButton(),
        const IntrinsicWidth(child: PerformanceInfo()),
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

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    final padding = const EI.o(l: 8);
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
                s: TS(c: textColor, s: 14, height: 1, w: FontWeight.w500),
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
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

  void _onTap() {
    P.chat.onSwitchWenYanWen(!P.chat.wenYanWen.q);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wenYanWen = ref.watch(P.chat.wenYanWen);

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          duration: 150.ms,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(color: wenYanWen ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer, borderRadius: 60.r),
          child: Center(
            child: Text(
              "文言",
              style: TextStyle(
                fontSize: 14,
                height: 1,
                color: wenYanWen ? theme.colorScheme.onPrimary : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageButton extends ConsumerWidget {
  const _MessageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiving = ref.watch(P.chat.receivingTokens);
    final editingBotMessage = ref.watch(P.msg.editingBotMessage);
    final color = Theme.of(context).colorScheme.primary;
    final inSee = ref.watch(P.app.pageKey) == PageKey.see;
    final imagePath = ref.watch(P.world.imagePath);
    final hasAtLeastOneImage = ref.watch(P.msg.hasAtLeastOneImage);
    final inputHasContent = ref.watch(P.chat.inputHasContent);
    double opacity = 1;
    if (inSee) opacity = ((imagePath != null || hasAtLeastOneImage) && inputHasContent) ? 1 : .333;

    if (!receiving) {
      return AnimatedOpacity(
        opacity: opacity,
        duration: 250.ms,
        child: GestureDetector(
          onTap: P.chat.onSendButtonPressed,
          child: Container(
            padding: const EI.s(h: 10, v: 5),
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

    return GestureDetector(
      onTap: P.chat.onStopButtonPressed,
      child: Container(
        decoration: const BoxDecoration(color: kC),
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
