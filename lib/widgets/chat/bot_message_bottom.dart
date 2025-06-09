// ignore: unused_import

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/chat/branch_switcher.dart';

class BotMessageBottom extends ConsumerWidget {
  final model.Message msg;
  final int index;

  const BotMessageBottom(this.msg, this.index, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    if (msg.isMine) return const SizedBox.shrink();
    final demoType = ref.watch(P.app.demoType);
    if (demoType == DemoType.tts) return const SizedBox.shrink();

    final receiveId = ref.watch(P.chat.receiveId);
    final selectMessageMode = ref.watch(P.chat.selectMessageMode);

    final paused = msg.paused;

    final changing = msg.changing;

    final primaryColor = Theme.of(context).colorScheme.primary;

    final worldType = ref.watch(P.rwkv.currentWorldType);

    bool showBotEditButton = true;
    bool showBotCopyButton = true;
    bool showBotRegenerateButton = true;
    bool showResumeButton = true;
    bool showShareButton = false;

    switch (worldType) {
      case null:
        break;
      default:
        showBotEditButton = false;
        showBotCopyButton = false;
    }

    switch (demoType) {
      case DemoType.tts:
        showBotEditButton = false;
        showBotCopyButton = false;
        showBotRegenerateButton = false;
        showResumeButton = false;
        break;
      case DemoType.chat:
        showShareButton = true;
        break;
      default:
        break;
    }

    if (msg.isSensitive || selectMessageMode) {
      showResumeButton = false;
      showBotCopyButton = false;
      showBotEditButton = false;
      showShareButton = false;
    }
    if (selectMessageMode) {
      showBotRegenerateButton = false;
    }

    final thinkingMode = ThinkingMode.fromString(msg.runningMode);

    final modeWidget = switch (thinkingMode) {
      None() => Padding(
        padding: const EI.o(v: 4, r: 4, l: 4),
        child: Icon(CupertinoIcons.zzz, color: primaryColor.q(.8), size: 14),
      ),
      _ => const SizedBox.shrink(),
    };

    return Row(
      mainAxisAlignment: MAA.start,
      children: [
        if (changing)
          Padding(
            padding: const EI.o(v: 12, r: 4),
            child: TweenAnimationBuilder(
              tween: Tween(begin: .0, end: 1.0),
              duration: const Duration(milliseconds: 1000000000),
              builder: (context, value, child) => Transform.rotate(
                angle: value * 2 * math.pi * 1000000,
                child: child,
              ),
              child: Icon(
                Icons.hourglass_top,
                color: primaryColor,
                size: 20,
              ),
            ),
          ),
        if (showBotCopyButton)
          GD(
            onTap: _onCopyPressed,
            child: Padding(
              padding: const EI.o(v: 12, r: 4, l: 4),
              child: Icon(
                Icons.copy,
                color: primaryColor.q(.8),
                size: 20,
              ),
            ),
          ),
        if (showBotRegenerateButton)
          GD(
            onTap: _onRegeneratePressed,
            child: Padding(
              padding: const EI.o(v: 12, r: 4, l: 4),
              child: Icon(
                Icons.refresh,
                color: primaryColor.q(.8),
                size: 20,
              ),
            ),
          ),
        if (showBotEditButton)
          GD(
            onTap: _onBotEditPressed,
            child: Padding(
              padding: const EI.o(v: 12, r: 4, l: 4),
              child: Icon(
                Icons.edit,
                color: primaryColor.q(.8),
                size: 20,
              ),
            ),
          ),
        if (showShareButton)
          GD(
            onTap: _onSharePressed,
            child: Padding(
              padding: const EI.o(v: 12, l: 4, r: 4),
              child: Icon(
                Icons.share_rounded,
                color: primaryColor.q(.8),
                size: 20,
              ),
            ),
          ),
        BranchSwitcher(msg, index),
        if (msg.modelName != null) 4.w,
        if (msg.modelName != null)
          Container(
            alignment: Alignment.centerRight,
            constraints: BoxConstraints(minHeight: 36),
            child: Expanded(
              child: T(
                msg.modelName!,
                s: TS(c: primaryColor.q(.8), s: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        modeWidget,
        if (showResumeButton && paused && receiveId == msg.id)
          GD(
            onTap: _onResumePressed,
            child: C(
              padding: const EI.o(v: 9, l: 12),
              child: C(
                padding: const EI.s(v: 1, h: 8),
                decoration: BD(
                  color: kC,
                  border: Border.all(color: primaryColor.q(.67)),
                  borderRadius: 4.r,
                ),
                child: T(
                  s.chat_resume,
                  s: TS(c: primaryColor, w: FW.w600, s: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onSharePressed() {
    final list = P.msg.list.q;
    final index = list.indexOf(msg);
    if (index > 0) {
      P.chat.selectedMessages.q = {list[index - 1].id, msg.id};
    }
    P.chat.selectMessageMode.q = true;
  }

  void _onResumePressed() {
    P.chat.resumeMessageById(id: msg.id);
  }

  void _onBotEditPressed() async {
    await P.chat.onTapEditInBotMessageBubble(index: index);
  }

  void _onRegeneratePressed() async {
    await P.chat.onRegeneratePressed(index: index);
  }

  void _onCopyPressed() {
    Alert.success(S.current.chat_copied_to_clipboard);
    Clipboard.setData(ClipboardData(text: msg.content));
  }
}
