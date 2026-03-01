// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/message_type.dart' as model;
import 'package:zone/model/world_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/branch_switcher.dart';

class UserMessageBottom extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final bool showInlineEditAndCopyButtons;

  /// On desktop, when non-null: edit/copy buttons use this for opacity (hover = 1, else 0) but keep same layout size.
  final bool? desktopActionsHovered;

  const UserMessageBottom(
    this.msg,
    this.index, {
    super.key,
    this.showInlineEditAndCopyButtons = true,
    this.desktopActionsHovered,
  });

  static ({bool showUserEditButton, bool showUserCopyButton, bool showUserTTSPlayButton}) resolveActionVisibility({
    required model.Message msg,
    required WorldType? worldType,
  }) {
    var showUserEditButton = false;
    var showUserCopyButton = false;
    var showUserTTSPlayButton = false;

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

    return (
      showUserEditButton: showUserEditButton,
      showUserCopyButton: showUserCopyButton,
      showUserTTSPlayButton: showUserTTSPlayButton,
    );
  }

  static ({bool canEdit, bool canCopy}) resolveContextMenuActions({
    required model.Message msg,
    required WorldType? worldType,
    required bool selectMessageMode,
  }) {
    if (!msg.isMine || selectMessageMode) {
      return (canEdit: false, canCopy: false);
    }

    switch (msg.type) {
      case model.MessageType.userImage:
      case model.MessageType.userTTS:
        return (canEdit: false, canCopy: false);
      case model.MessageType.text:
      case model.MessageType.ttsGeneration:
    }

    final actions = resolveActionVisibility(msg: msg, worldType: worldType);
    return (
      canEdit: actions.showUserEditButton,
      canCopy: actions.showUserCopyButton,
    );
  }

  static Future<void> onUserEditPressed({required int index}) async {
    await P.chat.onTapEditInUserMessageBubble(index: index);
  }

  static void onCopyPressed(model.Message msg) {
    P.chat.onCopyUserMessage(msg);
  }

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

    final actions = resolveActionVisibility(msg: msg, worldType: worldType);
    var showUserEditButton = actions.showUserEditButton;
    var showUserCopyButton = actions.showUserCopyButton;
    final showUserTTSPlayButton = actions.showUserTTSPlayButton;

    if (!showInlineEditAndCopyButtons) {
      showUserEditButton = false;
      showUserCopyButton = false;
    }

    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final playing = ref.watch(P.see.playing);
    final isCurrentMessage = latestClickedMessage?.id == msg.id;

    final s = S.of(context);

    final desktopOpacity = desktopActionsHovered != null ? (desktopActionsHovered! ? 1.0 : 0.0) : null;

    Widget wrapDesktopOpacity(Widget child, {required bool isEditOrCopy}) {
      if (desktopOpacity == null || !isEditOrCopy) return child;
      return AnimatedOpacity(
        opacity: desktopOpacity,
        duration: 200.ms,
        child: child,
      );
    }

    final EdgeInsets padding = const .only(left: 4, top: 4, right: 4, bottom: 4);

    return Row(
      mainAxisAlignment: .end,
      mainAxisSize: .min,
      children: [
        BranchSwitcher(msg, index),
        if (showUserEditButton)
          wrapDesktopOpacity(
            Tooltip(
              message: s.edit,
              child: GestureDetector(
                onTap: () => onUserEditPressed(index: index),
                child: Padding(
                  padding: padding,
                  child: Icon(
                    Icons.edit,
                    color: primary.q(.8),
                    size: 20,
                  ),
                ),
              ),
            ),
            isEditOrCopy: true,
          ),
        if (showUserTTSPlayButton && (!playing || !isCurrentMessage))
          Tooltip(
            message: s.resume,
            child: GestureDetector(
              onTap: _onTTSPlayPressed,
              child: Padding(
                padding: padding,
                child: Icon(Icons.play_arrow, color: primary.q(.8), size: 20),
              ),
            ),
          ),
        if (showUserTTSPlayButton && (playing && isCurrentMessage))
          Tooltip(
            message: s.pause,
            child: GestureDetector(
              onTap: _onTTSPausePressed,
              child: Padding(
                padding: padding,
                child: Icon(Icons.pause, color: primary.q(.8), size: 20),
              ),
            ),
          ),
        if (showUserCopyButton)
          wrapDesktopOpacity(
            Tooltip(
              message: s.copy_text,
              child: GestureDetector(
                onTap: () => onCopyPressed(msg),
                child: Padding(
                  padding: padding,
                  child: Icon(
                    Symbols.content_copy,
                    color: primary.q(.8),
                    size: 20,
                  ),
                ),
              ),
            ),
            isEditOrCopy: true,
          ),
        if (!showUserEditButton && !showUserCopyButton) const SizedBox(height: 8),
      ],
    );
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
