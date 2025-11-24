// ignore: unused_import

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/branch_switcher.dart';

class BotMessageBottom extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final DemoType? preferredDemoType;
  final String? finalContent;

  const BotMessageBottom(this.msg, this.index, {super.key, this.preferredDemoType, this.finalContent});

  void _onSharePressed() {
    if (P.chat.receivingTokens.q) {
      P.chat.onStopButtonPressed();
    }

    final list = P.msg.list.q;
    final index = list.indexOf(msg);
    if (index > 0) {
      P.chat.sharingSelectedMsgIds.q = {list[index - 1].id, msg.id};
    }
    P.chat.isSharing.q = true;
  }

  void _onResumePressed() {
    P.chat.resumeMessageById(id: msg.id);
  }

  void _onBotEditPressed() async {
    await P.chat.onTapEditInBotMessageBubble(index: index);
  }

  void _onRegeneratePressed() async {
    await P.chat.onRegeneratePressed(index: index, preferredDemoType: preferredDemoType ?? DemoType.chat);
  }

  void _onCopyPressed() {
    Alert.success(S.current.chat_copied_to_clipboard);
    final isBatch = getIsBatch(msg.content);
    String message = msg.content;
    if (isBatch) {
      message = message.replaceAll(Config.batchMarker, "\n\n");
      message = message.substring(0, message.length - 3);
    }
    Clipboard.setData(ClipboardData(text: message));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    if (msg.isMine) return const SizedBox.shrink();
    final demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    if (demoType == DemoType.tts) return const SizedBox.shrink();

    final receiveId = ref.watch(P.chat.receiveId);
    final selectMessageMode = ref.watch(P.chat.isSharing);

    final paused = msg.paused;

    final changing = msg.changing;

    final primaryColor = Theme.of(context).colorScheme.primary;

    final worldType = ref.watch(P.rwkv.currentWorldType);

    bool showEditButton = true;
    bool showCopyButton = true;
    bool showBotRegenerateButton = true;
    bool showResumeButton = true;
    bool showShareButton = false;

    switch (worldType) {
      case null:
        break;
      default:
        showEditButton = false;
        showCopyButton = false;
    }

    switch (demoType) {
      case DemoType.tts:
        showEditButton = false;
        showCopyButton = false;
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
      showCopyButton = false;
      showEditButton = false;
      showShareButton = false;
    }
    if (selectMessageMode) {
      showBotRegenerateButton = false;
    }

    final thinkingMode = ThinkingMode.fromString(msg.runningMode);
    final inSee = ref.watch(P.app.pageKey) == PageKey.see;

    final modeWidget = switch (thinkingMode) {
      None() =>
        inSee
            ? const SizedBox.shrink()
            : Padding(
                padding: const .only(left: 4, top: 4, right: 4, bottom: 4),
                child: Icon(CupertinoIcons.zzz, color: primaryColor.q(.8), size: 14),
              ),
      _ => const SizedBox.shrink(),
    };

    final isBatch = getIsBatch(finalContent ?? msg.content);

    if (isBatch) {
      showEditButton = false;
    }

    return Row(
      mainAxisAlignment: .start,
      children: [
        if (isBatch) 12.w,
        if (changing)
          Padding(
            padding: const .only(top: 12, right: 4, bottom: 12),
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
        if (showCopyButton)
          GestureDetector(
            onTap: _onCopyPressed,
            child: Padding(
              padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
              child: Icon(
                Icons.copy,
                color: primaryColor.q(.8),
                size: 20,
              ),
            ),
          ),
        if (showBotRegenerateButton)
          GestureDetector(
            onTap: _onRegeneratePressed,
            child: Padding(
              padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
              child: Icon(
                Icons.refresh,
                color: primaryColor.q(.8),
                size: 20,
              ),
            ),
          ),
        if (showEditButton)
          GestureDetector(
            onTap: _onBotEditPressed,
            child: Padding(
              padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
              child: Icon(
                Icons.edit,
                color: primaryColor.q(.8),
                size: 20,
              ),
            ),
          ),
        if (showShareButton)
          GestureDetector(
            onTap: _onSharePressed,
            child: Padding(
              padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
              child: Container(
                decoration: const BoxDecoration(color: kC),
                child: Icon(
                  Icons.share_rounded,
                  color: primaryColor.q(.8),
                  size: 20,
                ),
              ),
            ),
          ),
        BranchSwitcher(msg, index),
        if (msg.modelName != null) 4.w,
        if (msg.modelName != null)
          Expanded(
            child: T(
              msg.modelName!,
              s: TS(c: primaryColor.q(.8), s: 10),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ),
        modeWidget,
        if (showResumeButton && paused && receiveId == msg.id && !isBatch)
          GestureDetector(
            onTap: _onResumePressed,
            child: Container(
              padding: const .only(left: 12, top: 9, bottom: 9),
              child: Container(
                padding: const .symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: kC,
                  border: Border.all(color: primaryColor.q(.67)),
                  borderRadius: 4.r,
                ),
                child: T(
                  s.chat_resume,
                  s: TS(c: primaryColor, w: .w600, s: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
