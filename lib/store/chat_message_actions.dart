part of 'p.dart';

enum _UserMessageMenuAction {
  edit,
  copy,
  deleteCurrentBranch,
}

extension $ChatMessageActions on _Chat {
  void clearMessages() {
    _cancelMarkdownFlickerRepro(updateGenerating: true);
    _cancelFakeBatchInferenceBenchmark(updateGenerating: true);
    P.msg._clear();
  }

  Future<void> onDeleteBranchPressed({
    required Message msg,
  }) async {
    if (P.rwkvGeneration.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final targetNode = P.msg.msgNode.q.findNodeByMsgId(msg.id);
    final parentNode = targetNode?.parent;
    if (targetNode == null || parentNode == null) {
      Alert.warning(S.current.please_select_a_branch_to_continue_the_conversation);
      return;
    }

    final siblings = parentNode.children;
    if (siblings.length <= 1) {
      return;
    }

    final targetIndex = siblings.indexWhere((MsgNode node) => node.id == msg.id);
    if (targetIndex < 0) {
      Alert.warning(S.current.please_select_a_branch_to_continue_the_conversation);
      return;
    }

    final context = getContext();
    if (context == null) return;
    final s = S.of(context);
    final confirmResult = await showOkCancelAlertDialog(
      context: context,
      title: s.delete_branch_title,
      message: s.delete_branch_confirmation_message,
      okLabel: s.delete,
      cancelLabel: s.cancel,
      isDestructiveAction: true,
    );
    if (confirmResult != OkCancelResult.ok) return;

    final deletedIds = _collectSubtreeIds(targetNode);
    final deletedIdSet = deletedIds.toSet();

    parentNode.children.removeAt(targetIndex);
    if (parentNode.latest?.id == msg.id) {
      if (parentNode.children.isEmpty) {
        parentNode.latest = null;
      } else {
        final settledIndex = targetIndex >= parentNode.children.length ? parentNode.children.length - 1 : targetIndex;
        parentNode.latest = parentNode.children[settledIndex];
      }
    }

    final nextPool = <int, Message>{...P.msg.pool.q};
    for (final deletedId in deletedIds) {
      nextPool.remove(deletedId);
    }
    P.msg.pool.q = nextPool;

    P.msg.clearBottomDetailsStateByMessageIds(messageIds: deletedIds);
    P.msg.clearBottomTokensCountByMessageIds(messageIds: deletedIds);

    final latestClickedMessage = P.msg.latestClicked.q;
    if (latestClickedMessage != null && deletedIdSet.contains(latestClickedMessage.id)) {
      P.msg.latestClicked.q = null;
    }

    final selectedSharingIds = sharingSelectedMsgIds.q;
    final filteredSharingIds = selectedSharingIds.where((int id) => !deletedIdSet.contains(id)).toSet();
    if (filteredSharingIds.length != selectedSharingIds.length) {
      sharingSelectedMsgIds.q = filteredSharingIds;
    }
    if (filteredSharingIds.length < 2) {
      isSharing.q = false;
    }

    final editingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (editingIndex != null) {
      final editingMessage = P.msg.findByIndex(editingIndex);
      if (editingMessage != null && deletedIdSet.contains(editingMessage.id)) {
        P.msg.editingOrRegeneratingIndex.q = null;
      }
    }

    final currentReceiveId = receiveId.q;
    if (currentReceiveId != null && deletedIdSet.contains(currentReceiveId)) {
      receiveId.q = null;
      _setReceivedTokens("", immediateUi: true);
    }

    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    await P.conversation._syncNode();

    try {
      await P.app._db.deleteMsgsByCreateAtInUS(deletedIds);
      Alert.success(S.current.delete_finished);
    } catch (e) {
      qqe("delete branch failed: $e");
      Alert.error("Delete failed");
    }
  }

  List<int> _collectSubtreeIds(MsgNode rootNode) {
    final ids = <int>[];
    final stack = <MsgNode>[rootNode];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      ids.add(node.id);
      for (final child in node.children) {
        stack.add(child);
      }
    }
    return ids;
  }

  Future<void> onTapEditInUserMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final content = P.msg.list.q[index].contentAndTails[0];
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  Future<void> onEditOriginalQuestionForPausedReplyPressed({required int pausedReplyId}) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final messages = P.msg.list.q;
    final originalQuestionIndex = originalQuestionIndexForPausedReply(
      messages: messages,
      rootNode: P.msg.msgNode.q,
      pausedReplyId: pausedReplyId,
    );
    if (originalQuestionIndex == null) return;

    final currentDraft = textEditingController.text.trim();
    if (currentDraft.isEmpty) {
      final content = messages[originalQuestionIndex].contentAndTails.first;
      textEditingController.value = TextEditingValue(
        text: content,
        selection: TextSelection.collapsed(offset: content.length),
      );
    }

    P.app.hapticLight();
    P.msg.editingOrRegeneratingIndex.q = originalQuestionIndex;
    focusNode.requestFocus();
  }

  void dismissPausedReplyGuidance({required int pausedReplyId}) {
    if (_dismissedPausedReplyGuidanceMessageId.q == pausedReplyId) return;
    _dismissedPausedReplyGuidanceMessageId.q = pausedReplyId;
    P.app.hapticLight();
  }

  void onMessageTapped(Message msg) {
    if (P.rwkvContext.currentWorldType.q != null) {
      Focus.of(getContext()!).unfocus();
    }
    focusNode.unfocus();
    P.talk.dismissAllShown();
    P.msg.latestClicked.q = msg;
    if (msg.type == MessageType.ttsGeneration) {
      if (P.see.playing.q) {
        P.see.stopPlaying();
      } else {
        if (msg.changing) Alert.info(S.current.playing_partial_generated_audio);
        P.see.play(path: msg.audioUrl!);
      }
    }
  }

  void onCopyUserMessage(Message msg) {
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

  Future<void> showUserMessageContextMenu({
    required BuildContext context,
    required bool canEdit,
    required bool canCopy,
    required int index,
    required Message msg,
  }) async {
    final canDeleteCurrentBranch = P.msg.siblingCount(msg) > 1;
    if (!canEdit && !canCopy && !canDeleteCurrentBranch) return;
    if (!P.app.isMobile.q) return;

    final selectedAction = await _showMobileUserMessageMenu(
      context: context,
      canEdit: canEdit,
      canCopy: canCopy,
      canDeleteCurrentBranch: canDeleteCurrentBranch,
    );
    if (selectedAction == null) return;

    if (selectedAction == .edit) {
      await onTapEditInUserMessageBubble(index: index);
      return;
    }

    if (selectedAction == .copy) {
      onCopyUserMessage(msg);
      return;
    }

    if (selectedAction == .deleteCurrentBranch) {
      await onDeleteBranchPressed(msg: msg);
    }
  }

  Future<_UserMessageMenuAction?> _showMobileUserMessageMenu({
    required BuildContext context,
    required bool canEdit,
    required bool canCopy,
    required bool canDeleteCurrentBranch,
  }) async {
    final s = S.of(context);
    final actions = <SheetAction<_UserMessageMenuAction>>[
      if (canEdit) SheetAction(label: s.edit, key: .edit),
      if (canCopy) SheetAction(label: s.copy_text, key: .copy),
      if (canDeleteCurrentBranch) SheetAction(label: s.delete_current_branch, key: .deleteCurrentBranch),
    ];

    return showModalActionSheet<_UserMessageMenuAction>(
      context: context,
      cancelLabel: s.cancel,
      actions: actions,
    );
  }

  Future<void> onTapEditInBotMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final content = P.msg.list.q[index].getContentForEditing();
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  Future<void> startNewChat() async {
    if (P.rwkvGeneration.generating.q) await onStopButtonPressed();
    await 100.msLater;
    // Alert.success(S.current.new_chat_started);
    dismissNewConversationGuide();
    P.msg._clear();
    P.rwkvGeneration.clearStates();
    P.conversation.currentCreatedAtUS.q = P.msg.msgNode.q.createAtInUS;
  }

  void dismissNewConversationGuide() {
    if (newConversationGuideConversationId.q == null) return;
    newConversationGuideConversationId.q = null;
  }
}
