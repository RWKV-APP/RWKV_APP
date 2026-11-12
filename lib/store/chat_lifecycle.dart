part of 'p.dart';

extension $ChatLifecycle on _Chat {
  Future<void> _init() async {
    switch (P.app.demoType.q) {
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
        return;
      case .chat:
      case .tts:
      case .see:
    }
    qq;

    textEditingController.addListener(_onTextEditingControllerValueChanged);
    textInInput.l(_onTextChanged);

    P.app.pageKey.l(_onPageKeyChanged);

    P.rwkvBridge.oldBroadcastStream.listen(_onOldStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
    final event = P.rwkvBridge.broadcastStream;
    event.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);

    /// update the conversation subtitle
    event
        .whereType<from_rwkv.ResponseBufferContent>()
        .where((e) => P.msg.list.q.length <= 2)
        .throttleTime(const Duration(milliseconds: 500), trailing: true, leading: true)
        .listen((e) {
          unawaited(P.conversation.updateCurrentConvSubtitleFromResponseContent(e.responseBufferContent));
        });
    event
        .whereType<from_rwkv.ResponseBatchBufferContent>()
        .where((e) => P.msg.list.q.length <= 2)
        .throttleTime(const Duration(milliseconds: 500), trailing: true, leading: true)
        .listen((e) {
          final content = _buildBatchResponseBufferContent(e);
          unawaited(P.conversation.updateCurrentConvSubtitleFromResponseContent(content));
        });

    P.see.audioFileStreamController.stream.listen(_onNewFileReceived);
    focusNode.addListener(_onFocusNodeChanged);
    hasFocus.q = focusNode.hasFocus;
    P.app.lifecycleState.lb(_onLifecycleStateChanged);

    P.rwkvParams.supportedBatchSizes.l(_onSupportedBatchSizesChanged);

    batchCount.l(_onBatchCountChanged);

    scrollController.addListener(_onScroll);
    P.msg.ids.l(_onMessageIdsChangedForTokenCount);
    _onMessageIdsChangedForTokenCount(P.msg.ids.q);
  }

  void _onScroll() async {
    if (scrollController.hasClients == false) return;
    final position = scrollController.position;
    final extentAfter = position.extentAfter;
    if (extentAfter > 0) {
      listAtTop.q = false;
    } else {
      listAtTop.q = true;
    }
  }

  void _onConversationTokenCountObserved({
    required int? conversationTokensCount,
  }) {
    if (conversationTokensCount == null) return;
    final int currentEffectiveBatchCount = effectiveBatchEnabled.q ? effectiveBatchCount.q : 1;
    final int threshold = Config.newConversationTokenReminderThreshold * currentEffectiveBatchCount;
    if (conversationTokensCount < threshold) return;

    final conversationId = P.msg.msgNode.q.createAtInUS;
    final shownConversationIds = tokenReminderShownConversationIds.q;
    if (shownConversationIds.contains(conversationId)) return;

    tokenReminderShownConversationIds.q = {
      ...shownConversationIds,
      conversationId,
    };
    newConversationGuideConversationId.q = conversationId;
    Alert.info(S.current.conversation_token_limit_recommend_new_chat);
  }

  void _onLifecycleStateChanged(AppLifecycleState? previous, AppLifecycleState next) {
    if (P.app.isDesktop.q) return;
    final isToBackground = next == AppLifecycleState.paused || next == AppLifecycleState.hidden;
    if (isToBackground) {
      if (receiveId.q != null && _autoPauseId.q == null && P.rwkvGeneration.generating.q == true) {
        _autoPauseId.q = receiveId.q!;
        _pauseMessageById(id: receiveId.q!);
      }
    } else {
      if (_autoPauseId.q != null) {
        resumeMessageById(id: _autoPauseId.q!, withHaptic: false);
        _autoPauseId.q = null;
      }
    }
    qqq("autoPauseId: ${_autoPauseId.q}, receiveId: ${receiveId.q}, state: $next");
  }

  Future<void> _onFocusNodeChanged() async {
    hasFocus.q = focusNode.hasFocus;
  }

  Future<void> _onNewFileReceived((File, int) event) async {
    final demoType = P.app.demoType.q;

    if (demoType == .tts || demoType == .chat) {
      final (file, length) = event;
      final path = file.path;
      qqq("new file received: $path, length: $length");
      P.talk.selectSourceAudioPath.q = path;
      P.talk.selectedSpkName.q = null;
    }
  }

  void _onPageKeyChanged(PageKey pageKey) async {
    final model = P.rwkvModel.latest.q;
    final isTTS = model?.isTTS ?? false;
    final isSee = model?.worldType != null;
    if (pageKey == .chat) {
      unawaited(_showFixedDecodeParamWarningAfterEnteringChat());
    }
    switch (pageKey) {
      case .completion:
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) await P.rwkvModel._releaseAllModels();
        break;
      case .chat:
      case .neko:
        P.rwkvParams.updateSystemPrompt();
        P.app.demoType.q = .chat;
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) {
          P.rwkvContext.currentWorldType.q = null;
          await P.rwkvModel._releaseAllModels();
        }
        break;
      case .talk:
        if (!isTTS) {
          P.rwkvContext.currentGroupInfo.q = null;
          await P.rwkvModel._releaseAllModels();
        }
        break;
      default:
        break;
    }
    textInInput.q = "";
    textEditingController.text = "";
    focusNode.unfocus();
    hasFocus.q = false;
  }

  Future<void> _showFixedDecodeParamWarningAfterEnteringChat() async {
    await 500.msLater;
    if (P.app.pageKey.q != .chat) return;
    if (!P.rwkvParams.isCurrentDecodeParamFixed()) return;
    P.rwkvParams.showFixedDecodeParamWarning();
  }

  void _onTextEditingControllerValueChanged() {
    final textInController = textEditingController.text.replaceAll(Config.userMsgModifierSep, "");
    if (textInInput.q != textInController) textInInput.q = textInController;
  }

  void _onTextChanged(String next) {
    // qqq("_onTextChanged");
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
  }
}
