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

  static void _onCopyPressed(model.Message msg) {
    P.chat.onCopyUserMessage(msg);
  }

  static Future<void> onDeleteBranchPressed({
    required model.Message msg,
  }) async {
    await P.chat.onDeleteBranchPressed(msg: msg);
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

    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final WorldType? worldType = ref.watch(P.rwkv.currentWorldType);
    final bool selectMessageMode = ref.watch(P.chat.isSharing);
    ref.watch(P.msg.msgNode);

    if (selectMessageMode) {
      return const SizedBox(height: 12);
    }

    final ({bool showUserEditButton, bool showUserCopyButton, bool showUserTTSPlayButton}) actions = resolveActionVisibility(
      msg: msg,
      worldType: worldType,
    );
    bool showUserEditButton = actions.showUserEditButton;
    bool showUserCopyButton = actions.showUserCopyButton;
    final bool showUserTTSPlayButton = actions.showUserTTSPlayButton;
    final bool branchSwitcherAvailable = P.msg.siblingCount(msg) > 1;
    final bool showUserDeleteButton = branchSwitcherAvailable && showInlineEditAndCopyButtons;

    if (!showInlineEditAndCopyButtons) {
      showUserEditButton = false;
      showUserCopyButton = false;
    }

    final model.Message? latestClickedMessage = ref.watch(P.msg.latestClicked);
    final bool playing = ref.watch(P.see.playing);
    final bool isCurrentMessage = latestClickedMessage?.id == msg.id;

    final S s = S.of(context);

    final double? desktopOpacity = desktopActionsHovered != null ? (desktopActionsHovered! ? 1.0 : 0.0) : null;

    Widget wrapDesktopOpacity(
      Widget child, {
      required bool applyDesktopHoverAnimation,
    }) {
      if (desktopOpacity == null || !applyDesktopHoverAnimation) return child;
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
        if (branchSwitcherAvailable)
          wrapDesktopOpacity(
            BranchSwitcher(msg, index),
            applyDesktopHoverAnimation: true,
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
                onTap: () => _onCopyPressed(msg),
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
            applyDesktopHoverAnimation: true,
          ),
        if (showUserEditButton)
          wrapDesktopOpacity(
            Tooltip(
              message: s.edit,
              child: GestureDetector(
                onTap: () => onUserEditPressed(index: index),
                child: Padding(
                  padding: padding,
                  child: Icon(
                    Symbols.edit,
                    color: primary.q(.8),
                    size: 20,
                  ),
                ),
              ),
            ),
            applyDesktopHoverAnimation: true,
          ),
        if (showUserDeleteButton)
          wrapDesktopOpacity(
            Tooltip(
              message: s.delete,
              child: GestureDetector(
                onTap: _onDeleteBranchPressed,
                child: Padding(
                  padding: padding,
                  child: Icon(
                    Icons.delete_outline,
                    color: primary.q(.8),
                    size: 20,
                  ),
                ),
              ),
            ),
            applyDesktopHoverAnimation: true,
          ),
        if (!branchSwitcherAvailable && !showUserEditButton && !showUserCopyButton && !showUserDeleteButton && showInlineEditAndCopyButtons)
          const SizedBox(height: 8),
      ],
    );
  }

  void _onDeleteBranchPressed() async {
    await onDeleteBranchPressed(msg: msg);
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
