// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/message_type.dart' as model;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/branch_switcher.dart';

class UserMessageBottom extends ConsumerWidget {
  final model.Message msg;
  final int index;

  const UserMessageBottom(this.msg, this.index, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!msg.isMine) return const SizedBox.shrink();

    switch (msg.type) {
      case model.MessageType.userImage:
      case model.MessageType.userTTS:
        return const SizedBox.shrink();
      case model.MessageType.text:
      case model.MessageType.ttsGeneration:
    }

    final primary = Theme.of(context).colorScheme.primary;
    final worldType = ref.watch(P.rwkv.currentWorldType);
    final selectMessageMode = ref.watch(P.chat.isSharing);

    if (selectMessageMode) {
      return const SizedBox(height: 12);
    }

    bool showUserEditButton = false;
    bool showUserCopyButton = false;
    bool showUserTTSPlayButton = false;

    switch (worldType) {
      case null:
        switch (msg.type) {
          case model.MessageType.text:
          case model.MessageType.userImage:
            showUserEditButton = true;
            showUserCopyButton = true;
          case model.MessageType.userTTS:
            showUserEditButton = false;
            showUserCopyButton = true;
            if (msg.audioUrl != null) {
              showUserTTSPlayButton = true;
            }
          case model.MessageType.ttsGeneration:
            showUserEditButton = false;
            showUserCopyButton = false;
        }

      default:
        showUserEditButton = false;
        showUserCopyButton = false;
    }

    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final playing = ref.watch(P.see.playing);
    final isCurrentMessage = latestClickedMessage?.id == msg.id;

    return Row(
      mainAxisAlignment: .end,
      mainAxisSize: .min,
      children: [
        BranchSwitcher(msg, index),
        if (showUserEditButton)
          Tooltip(
            message: S.current.change,
            child: GestureDetector(
              onTap: _onUserEditPressed,
              child: Padding(
                padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
                child: Icon(
                  Icons.edit,
                  color: primary.q(.8),
                  size: 20,
                ),
              ),
            ),
          ),
        if (showUserTTSPlayButton && (!playing || !isCurrentMessage))
          Tooltip(
            message: S.current.resume,
            child: GestureDetector(
              onTap: _onTTSPlayPressed,
              child: Padding(
                padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
                child: Icon(Icons.play_arrow, color: primary.q(.8), size: 20),
              ),
            ),
          ),
        if (showUserTTSPlayButton && (playing && isCurrentMessage))
          Tooltip(
            message: S.current.pause,
            child: GestureDetector(
              onTap: _onTTSPausePressed,
              child: Padding(
                padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
                child: Icon(Icons.pause, color: primary.q(.8), size: 20),
              ),
            ),
          ),
        if (showUserCopyButton)
          Tooltip(
            message: S.current.copy_text,
            child: GestureDetector(
              onTap: _onCopyPressed,
              child: Padding(
                padding: const .only(left: 4, top: 12, right: 4, bottom: 12),
                child: Icon(
                  Icons.copy,
                  color: primary.q(.8),
                  size: 20,
                ),
              ),
            ),
          ),
        if (!showUserEditButton && !showUserCopyButton) const SizedBox(height: 8),
      ],
    );
  }

  void _onUserEditPressed() async {
    await P.chat.onTapEditInUserMessageBubble(index: index);
  }

  void _onCopyPressed() {
    Alert.success(S.current.chat_copied_to_clipboard);
    if (msg.ttsTarget != null) {
      Clipboard.setData(ClipboardData(text: msg.ttsTarget!.replaceAll(Config.userMsgModifierSep, "").trim()));
      return;
    }
    final content = msg.content.replaceAll(Config.userMsgModifierSep, "").trim();
    if (content.isEmpty) {
      Alert.warning("No content to copy");
      return;
    }
    Clipboard.setData(ClipboardData(text: content));
  }

  void _onTTSPlayPressed() {
    qq;
    P.msg.latestClicked.q = msg;
    P.see.play(path: msg.audioUrl!);
  }

  void _onTTSPausePressed() {
    P.see.stopPlaying();
  }
}
