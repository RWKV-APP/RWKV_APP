// ignore: unused_import

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/func/show_image_selector.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/state/p.dart';
import 'package:zone/widgets/performance_info.dart';

class BottomInteractions extends ConsumerWidget {
  const BottomInteractions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EI.o(t: 8),
      child: Row(
        children: [
          Expanded(child: _Interactions()),
          _MessageButton(),
        ],
      ),
    );
  }
}

class _Interactions extends ConsumerWidget {
  const _Interactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final demoType = ref.watch(P.app.demoType);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (currentWorldType?.isVisualDemo == true) const IntrinsicWidth(child: _SelectImageButton()),
        if (demoType == DemoType.chat) const _ThinkingModeButton(),
        if (demoType == DemoType.chat) const _SecondaryOptionsButton(),
        const IntrinsicWidth(child: PerformanceInfo()),
      ],
    );
  }
}

class _ThinkingModeButton extends ConsumerWidget {
  const _ThinkingModeButton();

  void _onTap() {
    P.rwkv.onThinkModeTyped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final loading = ref.watch(P.rwkv.loading);
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);
    final thinkingMode = ref.watch(P.rwkv.thinkingMode);

    final color = switch (thinkingMode) {
      thinking_mode.Lighting() => kC,
      thinking_mode.None() => kC,
      thinking_mode.Free() => primary,
      thinking_mode.PreferChinese() => primary,
    };

    final borderColor = switch (thinkingMode) {
      thinking_mode.Lighting() => primary.q(.33),
      thinking_mode.None() => primary.q(.33),
      thinking_mode.Free() => primary.q(.5),
      thinking_mode.PreferChinese() => primary.q(.5),
    };

    final textColor = switch (thinkingMode) {
      thinking_mode.Lighting() => primary.q(.5),
      thinking_mode.None() => primary.q(.5),
      thinking_mode.Free() => qw,
      thinking_mode.PreferChinese() => qw,
    };

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    final padding = const EI.s(h: 8);

    return IntrinsicWidth(
      child: AnimatedOpacity(
        opacity: loading ? .33 : 1,
        duration: 250.ms,
        child: GD(
          onTap: _onTap,
          child: SB(
            height: height,
            child: C(
              padding: padding,
              decoration: BD(
                color: color,
                border: Border.all(color: borderColor),
                borderRadius: 10.r,
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: textColor, size: 18),
                  2.w,
                  T(
                    s.reason,
                    s: TS(c: textColor, s: 14, height: 1, w: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryOptionsButton extends ConsumerWidget {
  const _SecondaryOptionsButton();

  void _onTap() {
    P.rwkv.onSecondaryOptionsTyped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final loading = ref.watch(P.rwkv.loading);

    final thinkingMode = ref.watch(P.rwkv.thinkingMode);
    final qw = ref.watch(P.app.qw);

    final color = switch (thinkingMode) {
      thinking_mode.Lighting() => kC,
      thinking_mode.Free() => kC,
      thinking_mode.None() => primary,
      thinking_mode.PreferChinese() => primary,
    };

    final borderColor = switch (thinkingMode) {
      thinking_mode.Lighting() => primary.q(.33),
      thinking_mode.Free() => primary.q(.33),
      thinking_mode.PreferChinese() => primary.q(.33),
      thinking_mode.None() => primary.q(.33),
    };

    final textColor = switch (thinkingMode) {
      thinking_mode.Lighting() => primary.q(.5),
      thinking_mode.None() => qw,
      thinking_mode.Free() => primary.q(.5),
      thinking_mode.PreferChinese() => qw,
    };

    final iconWidget = switch (thinkingMode) {
      thinking_mode.Free() => Icon(Icons.translate, color: textColor, size: 18),
      thinking_mode.PreferChinese() => Icon(Icons.translate, color: textColor, size: 18),
      _ => Icon(CupertinoIcons.zzz, color: textColor, size: 18),
    };

    final textWidget = switch (thinkingMode) {
      thinking_mode.Lighting() => null,
      thinking_mode.None() => T(s.lazy, s: TS(c: textColor, s: 14, height: 1)),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MAA.center,
        children: [
          T(s.prefer, s: TS(c: textColor, s: 10, height: 1)),
          2.h,
          T(s.chinese, s: TS(c: textColor, s: 10, height: 1)),
        ],
      ),
    };

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;
    final padding = const EI.s(h: 8);

    return AnimatedSize(
      key: const Key("_SecondaryOptionsButton"),
      duration: 150.ms,
      curve: Curves.easeOutCubic,
      child: IntrinsicWidth(
        child: AnimatedOpacity(
          opacity: loading ? .33 : 1,
          duration: 250.ms,
          child: GD(
            onTap: _onTap,
            child: AnimatedContainer(
              height: height,
              duration: 150.ms,
              curve: Curves.easeOutCubic,
              padding: padding,
              decoration: BD(
                color: color,
                border: Border.all(color: borderColor),
                borderRadius: 10.r,
              ),
              child: Row(
                children: [
                  iconWidget,
                  if (textWidget != null) 4.w,
                  ?textWidget,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectImageButton extends ConsumerWidget {
  const _SelectImageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final s = S.of(context);
    return GD(
      onTap: () async {
        await showImageSelector();
      },
      child: AnimatedContainer(
        duration: 150.ms,
        curve: Curves.easeOutCubic,
        decoration: BD(
          color: primaryContainer,
          border: Border.all(
            color: color.q(.5),
          ),
          borderRadius: 12.r,
        ),
        padding: const EI.o(l: 8, r: 8, t: 8, b: 8),
        child: T(
          s.select_new_image,
          s: TS(c: color),
        ),
      ),
    );
  }
}

class _MessageButton extends ConsumerWidget {
  const _MessageButton();

  void _onPressed() async {
    qq;

    final currentWorldType = P.rwkv.currentWorldType.q;
    final imagePath = P.world.imagePath.q;

    if (currentWorldType != null && imagePath == null) {
      await showImageSelector();
      Alert.info(S.current.please_load_model_first);
      return;
    }

    await P.chat.onSendButtonPressed();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiving = ref.watch(P.chat.receivingTokens);
    final canSend = ref.watch(P.chat.inputHasContent);
    final editingBotMessage = ref.watch(P.msg.editingBotMessage);
    final color = Theme.of(context).colorScheme.primary;

    if (!receiving) {
      return AnimatedOpacity(
        opacity: canSend ? 1 : .333,
        duration: 250.ms,
        child: GD(
          onTap: _onPressed,
          child: C(
            padding: const EI.s(h: 10, v: 5),
            child: Icon(
              (Platform.isIOS || Platform.isMacOS)
                  ? editingBotMessage
                        ? CupertinoIcons.pencil_circle_fill
                        : CupertinoIcons.arrow_up_circle_fill
                  : editingBotMessage
                  ? Icons.edit
                  : Icons.send,
              color: color,
            ),
          ),
        ),
      );
    }

    return GD(
      onTap: P.chat.onStopButtonPressed,
      child: C(
        decoration: const BD(color: kC),
        child: Stack(
          children: [
            SizedBox(
              width: 46,
              height: 34,
              child: Center(
                child: C(
                  decoration: BD(color: color, borderRadius: 2.r),
                  width: 12,
                  height: 12,
                ),
              ),
            ),
            SB(
              width: 46,
              height: 34,
              child: Center(
                child: SB(
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
