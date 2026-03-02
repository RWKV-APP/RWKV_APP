part of 'p.dart';

enum _UserMessageMenuAction {
  edit,
  copy,
}

class _Chat {
  // ===========================================================================
  // Instance
  // ===========================================================================

  /// The scroll controller of the chat page message list
  late final scrollController = ScrollController();

  late final listAtTop = qs(true);

  /// The text editing controller of the chat page input
  late final textEditingController = TextEditingController(text: "");

  /// The focus node of the chat page input
  late final focusNode = FocusNode();

  late final _sensitiveThrottler = Throttler(milliseconds: 333, trailing: true);
  late final _liveTokenCountDebouncer = Debouncer(milliseconds: 240);
  int _refreshTokenCountEpoch = 0;

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final textInInput = qs("");

  late final prefillPercentage = qs(0.0);

  /// TODO: Should be moved to state/rwkv.dart
  late final receivedTokens = qs("");

  late final inputHeight = qs(77.0);

  late final ttsBottomHeight = qs(0.0);

  late final receiveId = qs<int?>(null);

  late final hasFocus = qs(false);

  late final _autoPauseId = qs<int?>(null);

  // TODO: Should be moved to state/msg.dart in the future
  late final sharingSelectedMsgIds = qs<Set<int>>({});

  // TODO: Should be moved to state/msg.dart in the future
  late final isSharing = qs(false);

  late final completionMode = qs(false);

  late final webSearchMode = qs(WebSearchMode.off);

  // 使用文言文
  late final wenYanWen = qs(WenyanMode.off);

  late final batchEnabled = qs(Args.enableBatchInference);
  late final batchCount = qs<int>(Argument.batchCount.defaults.toInt());
  late final batchVW = qs<int>(Argument.batchVW.defaults.toInt());

  // ===========================================================================
  // Provider
  // ===========================================================================

  late final inputHasContent = qp((ref) {
    final textInInput = ref.watch(this.textInInput);
    return textInInput.trim().isNotEmpty;
  });
}

/// Public methods
extension $Chat on _Chat {
  void clearMessages() {
    P.msg._clear();
  }

  void onSwitchWebSearchMode(WebSearchMode mode) async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (mode != WebSearchMode.off) {
      wenYanWen.q = WenyanMode.off;
    }
    webSearchMode.q = mode;
  }

  Future<void> onWebSearchModeTapped() async {
    final bool receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final BuildContext? context = getContext();
    if (context == null) return;

    P.app.hapticLight();

    final S s = S.current;
    final WebSearchMode current = webSearchMode.q;
    final List<({String label, WebSearchMode key})> actionPairs = [
      (label: s.off, key: .off),
      (label: s.web_search, key: .search),
      (label: s.deep_web_search, key: .deepSearch),
    ];

    final List<SheetAction<WebSearchMode>> actions = actionPairs.map((entry) {
      final bool isCurrent = entry.key == current;
      final String label = isCurrent ? "☑ ${entry.label}" : entry.label;
      final WebSearchMode key = entry.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final WebSearchMode? selectedMode = await showModalActionSheet<WebSearchMode>(
      context: context,
      title: s.web_search,
      message: "${s.web_search} / ${s.deep_web_search}",
      cancelLabel: s.cancel,
      actions: actions,
    );

    if (selectedMode == null) return;

    onSwitchWebSearchMode(selectedMode);
  }

  void onSwitchWenYanWen(WenyanMode mode) async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    switch (mode) {
      case .off:
      case .classic:
        break;
      case .mixed:
        if (batchEnabled.q == false) batchEnabled.q = true;
    }

    if (mode != WenyanMode.off) {
      webSearchMode.q = WebSearchMode.off;
      if (mode == WenyanMode.mixed && P.rwkv.supportedBatchSizes.q.isNotEmpty) {
        onBatchInferenceSwitchChanged(true);
        batchCount.q = 2;
      }
    } else {
      if (wenYanWen.q == WenyanMode.mixed && batchCount.q == 2) {
        onBatchInferenceSwitchChanged(false);
      }
    }

    wenYanWen.q = mode;
  }

  Future<void> onWenYanWenTapped() async {
    final bool receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    final FileInfo? model = P.rwkv.latestModel.q;
    if (model == null) {
      ModelSelector.show();
      return;
    }

    final BuildContext? context = getContext();
    if (context == null) return;

    P.app.hapticLight();

    final WenyanMode currentMode = wenYanWen.q;
    final List<({String label, WenyanMode key})> actionPairs = [
      (label: "文言: 关", key: .off),
      (label: "文言: 开", key: .classic),
      (label: "古今", key: .mixed),
    ];
    final List<SheetAction<WenyanMode>> actions = actionPairs.map((entry) {
      final bool isCurrent = entry.key == currentMode;
      final String label = isCurrent ? "☑ ${entry.label}" : entry.label;
      final WenyanMode key = entry.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final WenyanMode? selectedMode = await showModalActionSheet<WenyanMode>(
      context: context,
      title: "文言",
      message: "请选择文言模式",
      cancelLabel: S.current.cancel,
      actions: actions,
    );

    if (selectedMode == null) return;

    if (!model.tags.contains('batch') && selectedMode == WenyanMode.mixed) {
      Alert.warning(S.current.this_model_does_not_support_batch_inference);
      return;
    }

    onSwitchWenYanWen(selectedMode);
  }

  // TODO: 适时去掉 preferredDemoType
  Future<void> onSendButtonPressed({
    required DemoType preferredDemoType,
  }) async {
    if (P.app.demoType.q == .tts) {
      await P.talk.gen();
      return;
    }

    qq;
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    final inSee = P.app.pageKey.q == .see;
    if (inSee) {
      final hasAtLeastOneImage = P.msg.hasAtLeastOneImage.q;
      final imagePath = P.see.imagePath.q;
      if (!hasAtLeastOneImage && imagePath == null) {
        Alert.info(S.current.please_select_an_image_first);

        if (focusNode.hasFocus) {
          focusNode.unfocus();
        }

        final imagePath = await showImageSelector();
        if (imagePath == null) return;
        P.see.imagePath.q = imagePath;
        return;
      }
    }

    if (!inputHasContent.q) {
      Alert.info(S.current.chat_empty_message);
      return;
    }

    MsgNode? parentNode = P.msg.msgNode.q.wholeLatestNode;
    final parentMsg = P.msg.pool.q[parentNode.id];
    if (parentMsg != null && parentMsg.type == MessageType.text && !parentMsg.isMine && getIsBatch(parentMsg.content)) {
      final selection = P.msg.batchSelection(parentMsg).q;
      if (selection == null) {
        Alert.info(S.current.please_select_a_branch_to_continue_the_conversation, position: AlertPosition.top);
        return;
      }
    }

    focusNode.unfocus();
    final textToSend = textInInput.q.trim();
    textInInput.q = "";

    final _editingBotMessage = P.msg.editingBotMessage.q;

    if (_editingBotMessage) {
      final id = HF.milliseconds;
      final currentMessages = [...P.msg.list.q];
      final _editingIndex = P.msg.editingOrRegeneratingIndex.q!;
      final currentMessage = currentMessages[_editingIndex];
      receiveId.q = id;

      final newMsg = Message(
        id: id,
        content: textToSend,
        isMine: false,
        changing: false,
        paused: currentMessage.paused,
        modelName: currentMessage.modelName,
        runningMode: currentMessage.runningMode,
      );

      P.msg._syncMsg(id, newMsg);
      final userMsgNode = P.msg.msgNode.q.findParentByMsgId(currentMessage.id);
      if (userMsgNode == null) {
        qqe("We should found a user message node before a bot message node");
        return;
      }
      userMsgNode.add(MsgNode(id));
      P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
      P.conversation._syncNode();
      P.msg.editingOrRegeneratingIndex.q = null;
      Alert.success(S.current.bot_message_edited);
      return;
    }

    if (inSee) {
      final imagePath = P.see.imagePath.q;
      final isPureText = imagePath == null;

      if (P.rwkv.generating.q) {
        // qqw("TODO:");
        // 1. 添加 message 至 queue
        // 2. 在 ui 上渲染 queue
        // 3. 等待 prefill 完成后, 马上发送消息
        P.see.waitingText.q = textToSend;
        P.see.waitingImagePath.q = imagePath;
        P.see.imagePath.q = null;
        return;
      }

      if (isPureText) {
        await send(textToSend);
      } else {
        P.see.imagePath.q = null;
        if (P.msg.hasAtLeastOneImage.q) {
          P.msg._clear();
          await 10.msLater;
          P.rwkv.clearStates();
          await 10.msLater;
        }
        await send("", type: MessageType.userImage, imageUrl: imagePath);
        await 50.msLater;
        final finalTextToSend = "<image>$imagePath</image>" + textToSend.trim();
        await send(finalTextToSend);
      }
    } else {
      await send(textToSend);
    }
  }

  Future<void> onEditingComplete() async {
    qq;
  }

  Future<void> onKeyboardSubmitted(String aString) async {
    qqq(aString);

    final generating = P.rwkv.generating.q;

    if (generating) {
      Alert.info("Please wait for the previous message to be generated");
      return;
    }

    if (P.app.demoType.q == .tts) {
      await P.talk.gen();
      return;
    }

    final textToSend = textInInput.q.trim();
    if (textToSend.isEmpty) return;
    textInInput.q = "";
    focusNode.unfocus();
    await send(textToSend);
  }

  void cancelEditing({bool clearInput = false}) {
    final int? editingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (editingIndex == null && !clearInput) return;
    P.msg.editingOrRegeneratingIndex.q = null;
    if (!clearInput) return;
    textEditingController.clear();
    textInInput.q = "";
  }

  Future<void> onTapMessageList() async {
    qq;
    focusNode.unfocus();
    P.talk.dismissAllShown();
    cancelEditing(clearInput: true);
  }

  Future<void> onTapClearInput() async {
    qq;
    cancelEditing(clearInput: true);
  }

  Future<void> onTapEditInUserMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final content = P.msg.list.q[index].contentAndTails[0];
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  void onMessageTapped(Message msg) {
    if (P.rwkv.currentWorldType.q != null) {
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
    if (!canEdit && !canCopy) return;
    if (!P.app.isMobile.q) return;

    final _UserMessageMenuAction? selectedAction = await _showMobileUserMessageMenu(
      context: context,
      canEdit: canEdit,
      canCopy: canCopy,
    );
    if (selectedAction == null) return;
    if (selectedAction == .edit) {
      await onTapEditInUserMessageBubble(index: index);
      return;
    }
    if (selectedAction == .copy) {
      onCopyUserMessage(msg);
    }
  }

  Future<_UserMessageMenuAction?> _showMobileUserMessageMenu({
    required BuildContext context,
    required bool canEdit,
    required bool canCopy,
  }) async {
    final S s = S.of(context);
    final List<SheetAction<_UserMessageMenuAction>> actions = [
      if (canEdit) SheetAction(label: s.edit, key: .edit),
      if (canCopy) SheetAction(label: s.copy_text, key: .copy),
    ];

    return showModalActionSheet<_UserMessageMenuAction>(
      context: context,
      cancelLabel: s.cancel,
      actions: actions,
    );
  }

  Future<void> onTapEditInBotMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final content = P.msg.list.q[index].content;
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  Future<void> onRegeneratePressed({required int index, required DemoType preferredDemoType}) async {
    qqq("index: $index");
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    final userMessage = P.msg.list.q[index - 1];
    P.msg.editingOrRegeneratingIndex.q = index;
    textInInput.q = "";
    focusNode.unfocus();
    final content = userMessage.contentAndTails.first;
    await send(content, isRegenerate: true);
  }

  Future<void> scrollToBottom({Duration? duration, bool? animate = true}) async {
    await scrollTo(offset: 0, duration: duration, animate: animate);
  }

  Future<void> scrollTo({required double offset, Duration? duration, bool? animate = true}) async {
    if (scrollController.hasClients == false) return;
    if (scrollController.offset == offset) return;
    if (animate == true) {
      await scrollController.animateTo(
        offset,
        duration: duration ?? 300.ms,
        curve: Curves.easeInOut,
      );
    } else {
      scrollController.jumpTo(offset);
    }
  }

  Future<void> startNewChat() async {
    if (P.rwkv.generating.q) await onStopButtonPressed();
    await 100.msLater;
    // Alert.success(S.current.new_chat_started);
    P.msg._clear();
    P.rwkv.clearStates();
    P.conversation.currentCreatedAtUS.q = P.msg.msgNode.q.createAtInUS;
  }

  void toggleCompletionMode() {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    final r = !completionMode.q;
    completionMode.q = r;
    P.rwkv.setGenerateMode(r);
  }

  Future<void> stopCompletion() async {
    P.rwkv.stop();
  }

  /// 拼装消息, 调用 rwkv 的 sendMessages 方法
  Future<void> send(
    String raw, {
    MessageType type = MessageType.text,
    String? imageUrl,
    String? audioUrl,
    int? audioLength,
    bool withHistory = true,
    bool isRegenerate = false,
  }) async {
    assert(!raw.contains(Config.userMsgModifierSep));

    raw = raw.trim();
    String message = raw;

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final currentModel = P.rwkv.latestModel.q!;

    final thinkingMode = P.rwkv.thinkingMode.q;

    MsgNode? parentNode = P.msg.msgNode.q.wholeLatestNode;
    final editingOrRegeneratingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (editingOrRegeneratingIndex != null) {
      final currentMessage = P.msg.findByIndex(editingOrRegeneratingIndex);
      if (currentMessage == null) {
        qqe("currentMessage is null");
        return;
      }

      if (isRegenerate) {
        parentNode = P.msg.msgNode.q.findParentByMsgId(currentMessage.id);
      } else {
        // 以该消息的父节点作为新消息的父结点
        parentNode = P.msg.msgNode.q.findParentByMsgId(currentMessage.id);
      }

      if (parentNode == null) {
        qqe("parentNode is null");
        return;
      }
    }

    late final Message? userMsg;

    final id = HF.milliseconds;

    if (thinkingMode.userMsgFooter.isNotEmpty) {
      message = message + thinkingMode.userMsgFooter;
    }

    final parentMsg = P.msg.pool.q[parentNode.id];
    if (isRegenerate) {
      // 重新生成 Bot 消息, 所以, 不添加新的用户消息
      userMsg = parentMsg;
      // 但是, 需要移除旧的 bot 消息
      parentNode.latest = null;
      if (parentMsg != null) {
        final newContent = parentMsg.content + Config.userMsgModifierSep + thinkingMode.userMsgFooter;
        final newUserMsg = parentMsg.copyWith(content: newContent);
        P.msg._syncMsg(parentMsg.id, newUserMsg);
      }
    } else {
      // 新增或编辑了用户消息

      if (parentMsg != null && parentMsg.type == MessageType.text && !parentMsg.isMine && getIsBatch(parentMsg.content)) {
        final selection = P.msg.batchSelection(parentMsg).q;
        if (selection != null) {
          final finalizedContent = parentMsg.content.split(Config.batchMarker)[selection];
          final finalizedMsg = parentMsg.copyWith(content: finalizedContent);
          P.msg._syncMsg(parentMsg.id, finalizedMsg);
        } else {
          Alert.info(S.current.please_select_a_branch_to_continue_the_conversation, position: AlertPosition.bottom);
          return;
        }
      }

      final storedContent = raw + Config.userMsgModifierSep + thinkingMode.userMsgFooter;
      userMsg = Message(
        id: id,
        content: storedContent,
        isMine: true,
        type: type,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        audioLength: audioLength,
        paused: false,
      );
      P.msg._syncMsg(id, userMsg);
      parentNode = parentNode.add(MsgNode(id));
    }

    // 更新消息 id 列表
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();

    34.msLater.then((_) {
      scrollToBottom();
    });

    if (type == MessageType.userImage) {
      // 在之前的操作中已经注入了 LLM 了
      return;
    }

    P.msg.clearBottomDetailsStateInScope(scope: "chat_bot_message_bottom");

    final receiveId = HF.milliseconds + 1;
    this.receiveId.q = receiveId;

    List<String> history = withHistory ? _history() : <String>[];

    P.msg.editingOrRegeneratingIndex.q = null;

    receivedTokens.q = "";
    P.rwkv.generating.q = true;

    final receiveMsg = Message(
      id: receiveId,
      content: "",
      isMine: false,
      changing: true,
      paused: false,
      modelName: currentModel.name,
      runningMode: thinkingMode.toString(),
      rawDecodeParams: _resolveDecodeParamsSnapshotRaw(),
    );

    P.msg.pool.q[receiveId] = receiveMsg;
    parentNode.add(MsgNode(receiveId));
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
    _scheduleRefreshLiveTokenCounts(messageId: receiveId, liveBotContent: "");

    history = withHistory ? await _historyWithWebSearch(receiveId, history) : [message];
    final inSee = P.app.pageKey.q == .see;
    final batchSize = inSee ? 1 : (batchEnabled.q ? batchCount.q : 1);

    final forceChinese = inSee && message.containsChinese;

    P.rwkv.sendMessages(history, batchSize: batchSize, forceChinese: forceChinese);

    _checkSensitive(raw);
  }

  Future<void> onStopButtonPressed({bool wantHaptic = true}) async {
    qqq("receiveId: ${receiveId.q}");
    if (wantHaptic) P.app.hapticLight();
    await 1.msLater;
    final id = receiveId.q;
    if (id == null) {
      qqw("message id is null");
      return;
    }
    if (!P.rwkv.generating.q) {
      return;
    }
    _pauseMessageById(id: id);
  }

  Future<void> resumeMessageById({required int id, bool withHaptic = true}) async {
    qq;
    if (withHaptic) P.app.hapticLight();
    P.rwkv.sendMessages(_history(), batchSize: batchEnabled.q ? batchCount.q : 1);
    _updateMessageById(
      id: id,
      changing: true,
      paused: false,
      callingFunction: "resumeMessageById",
    );
    _scheduleRefreshLiveTokenCounts(messageId: id, liveBotContent: receivedTokens.q);
  }

  Future<void> onBatchInferenceSwitchChanged(bool value) async {
    P.app.hapticLight();
    batchEnabled.q = value;
    if (wenYanWen.q == WenyanMode.mixed && !value) {
      wenYanWen.q = WenyanMode.off;
    }

    if (!value) return;

    final temperature = P.rwkv.arguments(Argument.temperature).q;
    final topP = P.rwkv.arguments(Argument.topP).q;
    final presencePenalty = P.rwkv.arguments(Argument.presencePenalty).q;
    final frequencyPenalty = P.rwkv.arguments(Argument.frequencyPenalty).q;
    final penaltyDecay = P.rwkv.arguments(Argument.penaltyDecay).q;

    final List<SamplerAndPenaltyParam> newValue = List.generate(
      100,
      (index) => SamplerAndPenaltyParam(
        temperature: temperature,
        topP: topP,
        presencePenalty: presencePenalty,
        frequencyPenalty: frequencyPenalty,
        penaltyDecay: penaltyDecay,
      ),
    );

    P.rwkv.frontendBatchParams.q = newValue;
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    P.rwkv.send(
      to_rwkv.SetSamplerAndPenaltyParams(
        temperatures: newValue.map((e) => e.temperature).toList(),
        topKs: newValue.map((_) => 500.0).toList(),
        topPs: newValue.map((e) => e.topP).toList(),
        presencePenalties: newValue.map((e) => e.presencePenalty).toList(),
        frequencyPenalties: newValue.map((e) => e.frequencyPenalty).toList(),
        penaltyDecays: newValue.map((e) => e.penaltyDecay).toList(),
        modelID: modelID,
      ),
    );
    final batchCount = this.batchCount.q;
    P.rwkv.send(to_rwkv.GetSamplerAndPenaltyParams(batchSize: batchCount, modelID: modelID));
  }
}

/// Private methods
extension _$Chat on _Chat {
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

    P.rwkv.oldBroadcastStream.listen(_onOldStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
    final event = P.rwkv.broadcastStream;
    event.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);

    /// update the conversation subtitle
    event
        .whereType<from_rwkv.ResponseBufferContent>()
        .where((e) => P.msg.list.q.length <= 2)
        .throttleTime(const Duration(milliseconds: 500), trailing: true, leading: true)
        .listen((e) {
          final r = e.responseBufferContent.replaceAll('\n', '').replaceAll('</think>', '').replaceAll('<think>', '');
          P.conversation.updateCurrentConvSubtitle(r);
        });

    P.see.audioFileStreamController.stream.listen(_onNewFileReceived);
    focusNode.addListener(_onFocusNodeChanged);
    hasFocus.q = focusNode.hasFocus;
    P.suggestion.loadSuggestions();

    P.app.lifecycleState.lb(_onLifecycleStateChanged);

    P.preference.preferredLanguage.lv(P.suggestion.loadSuggestions);

    P.rwkv.supportedBatchSizes.l(_onSupportedBatchSizesChanged);

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

  void _onBatchCountChanged(int value) async {
    late final List<SamplerAndPenaltyParam> newFrontendBatchParams;
    newFrontendBatchParams = [
      ...P.rwkv.frontendBatchParams.q,
      P.rwkv.frontendBatchParams.q.last,
    ];

    P.rwkv.frontendBatchParams.q = newFrontendBatchParams;
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    P.rwkv.send(
      to_rwkv.SetSamplerAndPenaltyParams(
        temperatures: newFrontendBatchParams.map((e) => e.temperature).toList(),
        topKs: newFrontendBatchParams.map((_) => 500.0).toList(),
        topPs: newFrontendBatchParams.map((e) => e.topP).toList(),
        presencePenalties: newFrontendBatchParams.map((e) => e.presencePenalty).toList(),
        frequencyPenalties: newFrontendBatchParams.map((e) => e.frequencyPenalty).toList(),
        penaltyDecays: newFrontendBatchParams.map((e) => e.penaltyDecay).toList(),
        modelID: modelID,
      ),
    );
    P.rwkv.send(to_rwkv.GetSamplerAndPenaltyParams(batchSize: value, modelID: modelID));
  }

  void _onSupportedBatchSizesChanged(List<int> supportedBatchSizes) {
    if (supportedBatchSizes.isEmpty) {
      batchEnabled.q = false;
      batchCount.q = Argument.batchCount.defaults.toInt();
      if (wenYanWen.q == WenyanMode.mixed) {
        wenYanWen.q = WenyanMode.off;
      }
      return;
    }
    final max = supportedBatchSizes.max;
    if (max < batchCount.q) batchCount.q = max;
  }

  Future<void> _checkSensitive(String content) async {
    final isSensitive = await P.guard.isSensitive(content);
    if (!isSensitive) return;

    final id = receiveId.q;
    if (id == null) {
      qqe("receiveId is null");
      return;
    }

    await 1.msLater;

    _pauseMessageById(id: id, isSensitive: true);
  }

  void _onLifecycleStateChanged(AppLifecycleState? previous, AppLifecycleState next) {
    if (P.app.isDesktop.q) return;
    final isToBackground = next == AppLifecycleState.paused || next == AppLifecycleState.hidden;
    if (isToBackground) {
      if (receiveId.q != null && _autoPauseId.q == null && P.rwkv.generating.q == true) {
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

  /// 获取历史记录
  List<String> _history() {
    final messages = P.msg.list.q.where((msg) => msg.type == MessageType.text).toList();

    if (messages.isEmpty) return [];

    // 如果只有一条消息，使用模板
    if (messages.length == 1) {
      final template = P.preference.promptTemplate.newChatTemplate.trim();
      if (template.isNotEmpty) {
        return template.split("\n\n").where((e) => e.isNotEmpty).toList();
      }
    }

    final result = <String>[];

    // 按用户消息和机器人消息配对处理
    for (int i = 0; i < messages.length; i += 2) {
      final userMsg = messages[i];
      final botMsg = i + 1 < messages.length ? messages[i + 1] : null;

      // 处理用户消息
      String userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
      if (wenYanWen.q == WenyanMode.classic) {
        userContent = '$userContent 请用文言文回答。';
      }
      result.add(userContent);

      // 处理机器人消息（如果存在）
      if (botMsg != null) {
        final botContent = botMsg.getHistoryContent();
        result.add(botContent);
      }
    }

    return result;
  }

  Future<void> _pauseMessageById({required int id, bool isSensitive = false}) async {
    qq;

    final msg = P.msg.pool.q[id];
    if (msg == null) {
      qqw("message not found");
      return;
    }

    if (msg.paused) {
      qqw("message already paused");
      return;
    }

    final (double? snapshotPrefillSpeed, double? snapshotDecodeSpeed) = _currentSpeedSnapshotForStore();
    final double? finalPrefillSpeed = snapshotPrefillSpeed ?? msg.prefillSpeed;
    final double? finalDecodeSpeed = snapshotDecodeSpeed ?? msg.decodeSpeed;

    P.rwkv.stop();

    final newMsg = msg.copyWith(
      paused: true,
      changing: false,
      isSensitive: isSensitive,
      prefillSpeed: finalPrefillSpeed,
      decodeSpeed: finalDecodeSpeed,
    );
    P.msg._syncMsg(id, newMsg);
    final String currentGeneratedContent = id == receiveId.q ? receivedTokens.q : newMsg.content;
    unawaited(
      _refreshTokenCountsForMessage(
        messageId: id,
        overrideBotContent: currentGeneratedContent,
        persistToMessage: true,
      ),
    );
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
    final model = P.rwkv.latestModel.q;
    final isTTS = model?.isTTS ?? false;
    final isSee = model?.worldType != null;
    switch (pageKey) {
      case .completion:
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) await P.rwkv._releaseAllModels();
        break;
      case .chat:
        P.rwkv.updateSystemPrompt();
        P.app.demoType.q = .chat;
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) {
          P.rwkv.currentWorldType.q = null;
          await P.rwkv._releaseAllModels();
        }
        break;
      case .talk:
        if (!isTTS) {
          P.rwkv.currentGroupInfo.q = null;
          await P.rwkv._releaseAllModels();
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

  void _onTextEditingControllerValueChanged() {
    final textInController = textEditingController.text.replaceAll(Config.userMsgModifierSep, "");
    if (textInInput.q != textInController) textInInput.q = textInController;
  }

  void _onTextChanged(String next) {
    // qqq("_onTextChanged");
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
  }

  void _fullyReceived({String? callingFunction}) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator || pageKey == .ocr || pageKey == .benchmark || pageKey == .completion) return;
    qqq("callingFunction: $callingFunction");

    final id = receiveId.q;

    if (id == null) {
      qqe("receiveId is null");
      return;
    }

    final receivedTokens = this.receivedTokens.q;
    final Message? currentMessage = P.msg.pool.q[id];
    final (double? snapshotPrefillSpeed, double? snapshotDecodeSpeed) = _currentSpeedSnapshotForStore();
    final double? finalPrefillSpeed = snapshotPrefillSpeed ?? currentMessage?.prefillSpeed;
    final double? finalDecodeSpeed = snapshotDecodeSpeed ?? currentMessage?.decodeSpeed;

    _updateMessageById(
      id: id,
      content: receivedTokens,
      changing: false,
      prefillSpeed: finalPrefillSpeed,
      decodeSpeed: finalDecodeSpeed,
      callingFunction: callingFunction,
    );
    unawaited(
      _refreshTokenCountsForMessage(
        messageId: id,
        overrideBotContent: receivedTokens,
        persistToMessage: true,
      ),
    );
  }

  /// Update a message by id
  ///
  /// Should follow [Message] class
  void _updateMessageById({
    required int id,
    String? content,
    bool? isMine,
    bool? changing,
    MessageType? type,
    String? imageUrl,
    String? audioUrl,
    int? audioLength,
    bool? isReasoning,
    bool? paused,
    String? callingFunction,
    bool? isSensitive,
    RefInfo? reference,
    double? prefillSpeed,
    double? decodeSpeed,
    int? messageTokensCount,
    int? conversationTokensCount,
  }) {
    if (completionMode.q) {
      return;
    }

    if (id == Config.seePrefillId) {
      qqw("see prefill id: $id");
      return;
    }

    final msg = P.msg.pool.q[id];
    if (msg == null) {
      qqe("message not found: id: $id");
      Sentry.captureException(Exception("message not found, callingFunction: $callingFunction"), stackTrace: StackTrace.current);
      return;
    }
    final newMsg = msg.copyWith(
      content: content,
      isMine: isMine,
      changing: changing,
      type: type,
      reference: reference,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      audioLength: audioLength,
      isReasoning: isReasoning,
      paused: paused,
      isSensitive: isSensitive,
      prefillSpeed: prefillSpeed,
      decodeSpeed: decodeSpeed,
      messageTokensCount: messageTokensCount,
      conversationTokensCount: conversationTokensCount,
    );
    P.msg._syncMsg(id, newMsg);
  }

  (double? prefillSpeed, double? decodeSpeed) _currentSpeedSnapshotForStore() {
    final double currentPrefillSpeed = P.rwkv.prefillSpeed.q;
    final double currentDecodeSpeed = P.rwkv.decodeSpeed.q;
    final double? snapshotPrefillSpeed = currentPrefillSpeed > 0 ? currentPrefillSpeed : null;
    final double? snapshotDecodeSpeed = currentDecodeSpeed > 0 ? currentDecodeSpeed : null;
    return (snapshotPrefillSpeed, snapshotDecodeSpeed);
  }

  void _onMessageIdsChangedForTokenCount(List<int> messageIds) {
    _refreshTokenCountEpoch = _refreshTokenCountEpoch + 1;
    final int epoch = _refreshTokenCountEpoch;
    unawaited(_refreshMissingTokenCountsForMessages(messageIds: messageIds, epoch: epoch));
  }

  Future<void> _refreshMissingTokenCountsForMessages({
    required List<int> messageIds,
    required int epoch,
  }) async {
    for (final int messageId in messageIds) {
      if (epoch != _refreshTokenCountEpoch) return;
      final Message? message = P.msg.pool.q[messageId];
      if (message == null || message.isMine || message.type != MessageType.text) continue;
      final int? existingMessageCount = P.msg.getBottomMessageTokensCount(messageId: messageId);
      final int? existingConversationCount = P.msg.getBottomConversationTokensCount(messageId: messageId);
      final int? persistedMessageCount = message.messageTokensCount;
      final int? persistedConversationCount = message.conversationTokensCount;
      final bool hasCachedCount = existingMessageCount != null && existingConversationCount != null;
      final bool hasPersistedCount = persistedMessageCount != null && persistedConversationCount != null;
      if (hasCachedCount || hasPersistedCount) {
        if (!message.changing && hasPersistedCount && !hasCachedCount) {
          P.msg.setBottomTokensCount(
            messageId: messageId,
            messageTokensCount: persistedMessageCount,
            conversationTokensCount: persistedConversationCount,
          );
        }
        continue;
      }
      final String? overrideBotContent = message.changing && receiveId.q == messageId ? receivedTokens.q : null;
      await _refreshTokenCountsForMessage(
        messageId: messageId,
        overrideBotContent: overrideBotContent,
        persistToMessage: !message.changing,
      );
    }
  }

  void _scheduleRefreshLiveTokenCounts({
    required int messageId,
    required String liveBotContent,
  }) {
    _liveTokenCountDebouncer.call(() {
      unawaited(_refreshTokenCountsForMessage(messageId: messageId, overrideBotContent: liveBotContent));
    });
  }

  Future<void> _refreshTokenCountsForMessage({
    required int messageId,
    String? overrideBotContent,
    bool persistToMessage = false,
  }) async {
    final Message? message = P.msg.pool.q[messageId];
    if (message == null || message.isMine || message.type != MessageType.text) return;

    String botContent = overrideBotContent ?? message.content;
    if (botContent.isEmpty && messageId == receiveId.q) {
      botContent = receivedTokens.q;
    }

    final List<String>? history = _historyForTokenCountUntilMessage(
      messageId: messageId,
      overrideBotContent: botContent,
    );
    if (history == null || history.isEmpty) return;

    final List<int?> counts = await Future.wait([
      P.rwkv.calculateTokensCountRaw(text: botContent),
      P.rwkv.calculateTokensCountFromMessages(messages: history),
    ]);
    final int? messageTokensCount = counts[0];
    final int? conversationTokensCount = counts[1];
    if (messageTokensCount == null && conversationTokensCount == null) return;
    final Message? latestMessage = P.msg.pool.q[messageId];
    if (latestMessage == null) return;

    P.msg.setBottomTokensCount(
      messageId: messageId,
      messageTokensCount: messageTokensCount,
      conversationTokensCount: conversationTokensCount,
    );

    if (!persistToMessage) return;

    final int? resolvedMessageTokensCount = messageTokensCount ?? latestMessage.messageTokensCount;
    final int? resolvedConversationTokensCount = conversationTokensCount ?? latestMessage.conversationTokensCount;
    if (resolvedMessageTokensCount == null && resolvedConversationTokensCount == null) return;

    final bool noMessageCountChanges = resolvedMessageTokensCount == latestMessage.messageTokensCount;
    final bool noConversationCountChanges = resolvedConversationTokensCount == latestMessage.conversationTokensCount;
    if (noMessageCountChanges && noConversationCountChanges) return;

    final Message updatedMessage = latestMessage.copyWith(
      messageTokensCount: resolvedMessageTokensCount,
      conversationTokensCount: resolvedConversationTokensCount,
    );
    await P.msg._syncMsg(messageId, updatedMessage);
  }

  List<String>? _historyForTokenCountUntilMessage({
    required int messageId,
    String? overrideBotContent,
  }) {
    final MsgNode? targetNode = P.msg.msgNode.q.findNodeByMsgId(messageId);
    if (targetNode == null) return null;
    final List<int> idsFromTargetToRoot = P.msg.msgNode.q.msgIdsFrom(targetNode);
    final List<int> orderedPathIds = idsFromTargetToRoot.reversed.where((int id) => id != 0).toList();
    if (orderedPathIds.isEmpty) return null;

    final List<Message> scopedMessages = [];
    for (final int id in orderedPathIds) {
      final Message? pathMessage = P.msg.pool.q[id];
      if (pathMessage == null) continue;
      if (pathMessage.type != MessageType.text) continue;
      scopedMessages.add(pathMessage);
    }
    if (scopedMessages.isEmpty) return null;

    final List<String> history = [];
    final bool isSingleTurnPath = scopedMessages.length == 2 && scopedMessages.first.isMine;
    if (isSingleTurnPath) {
      final String template = P.preference.promptTemplate.newChatTemplate.trim();
      if (template.isNotEmpty) {
        final List<String> templateMessages = template.split("\n\n").where((String entry) => entry.isNotEmpty).toList();
        history.addAll(templateMessages);
      }
    }
    for (int i = 0; i < scopedMessages.length; i = i + 2) {
      final Message userMsg = scopedMessages[i];
      final Message? botMsg = i + 1 < scopedMessages.length ? scopedMessages[i + 1] : null;

      String userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
      if (wenYanWen.q == WenyanMode.classic) {
        userContent = "$userContent 请用文言文回答。";
      }
      history.add(userContent);

      if (botMsg == null) continue;

      String botContent = botMsg.getHistoryContent();
      if (botMsg.id == messageId && overrideBotContent != null) {
        botContent = overrideBotContent;
      }
      history.add(botContent);
    }
    return history;
  }

  String? _resolveDecodeParamsSnapshotRaw() {
    final List<SamplerAndPenaltyParam> backendParams = P.rwkv.backendBatchParams.q;
    if (backendParams.isNotEmpty) return backendParams.rawDecodeParams;

    final List<SamplerAndPenaltyParam> frontendParams = P.rwkv.frontendBatchParams.q;
    if (frontendParams.isNotEmpty) return frontendParams.rawDecodeParams;

    final SamplerAndPenaltyParam currentParam = SamplerAndPenaltyParam(
      temperature: P.rwkv.arguments(Argument.temperature).q,
      topP: P.rwkv.arguments(Argument.topP).q,
      presencePenalty: P.rwkv.arguments(Argument.presencePenalty).q,
      frequencyPenalty: P.rwkv.arguments(Argument.frequencyPenalty).q,
      penaltyDecay: P.rwkv.arguments(Argument.penaltyDecay).q,
    );
    return <SamplerAndPenaltyParam>[currentParam].rawDecodeParams;
  }

  @Deprecated("Use _onStreamEvent instead")
  void _onOldStreamEvent(LLMEvent event) {
    switch (event.type) {
      case _RWKVMessageType.isGenerating:
        final isGenerating = event.content == "true";
        P.rwkv.generating.q = isGenerating;
        if (!isGenerating && !completionMode.q) _fullyReceived(callingFunction: "_onStreamEvent:isGenerating");
        break;

      case _RWKVMessageType.streamResponse:
        receivedTokens.q = event.content;
        P.rwkv.generating.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;

    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        receivedTokens.q = res.responseBufferContent;
        if (completionMode.q) return;
        final int? currentReceiveId = receiveId.q;
        if (currentReceiveId != null) {
          _scheduleRefreshLiveTokenCounts(
            messageId: currentReceiveId,
            liveBotContent: res.responseBufferContent,
          );
        }
        _sensitiveThrottler.call(() {
          _checkSensitive(res.responseBufferContent);
        });
        break;

      case from_rwkv.ResponseBatchBufferContent res:
        final responseBufferContent = res.responseBufferContent.join(Config.batchMarker) + Config.batchMarker + "-1";
        receivedTokens.q = responseBufferContent;
        if (completionMode.q) return;
        final int? currentReceiveId = receiveId.q;
        if (currentReceiveId != null) {
          _scheduleRefreshLiveTokenCounts(
            messageId: currentReceiveId,
            liveBotContent: responseBufferContent,
          );
        }
        _sensitiveThrottler.call(() {
          _checkSensitive(responseBufferContent);
        });
        break;

      case from_rwkv.GenerateStop _:
        receivedTokens.q = "";
        P.rwkv.generating.q = false;
        break;

      case from_rwkv.GenerateStart _:
        receivedTokens.q = "";
        P.rwkv.generating.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamDone() async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    qq;
    final demoType = P.app.demoType.q;
    if (demoType != .chat && demoType != .see) return;
    P.rwkv.generating.q = false;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    qqe("error: $error");
    if (!kDebugMode) Sentry.captureException(error, stackTrace: stackTrace);
    final demoType = P.app.demoType.q;
    if (demoType != .chat && demoType != .see) return;
    P.rwkv.generating.q = false;
  }

  Future<List<String>> _historyWithWebSearch(int receiveId, List<String> allMessage) async {
    RefInfo ref = RefInfo.empty();
    final isZh = P.preference.currentLangIsZh.q;

    if (webSearchMode.q != WebSearchMode.off) {
      ref = ref.copyWith(enable: true);
      try {
        final prompt = allMessage.last;
        final deepSearch = webSearchMode.q == WebSearchMode.deepSearch;
        _updateMessageById(id: receiveId, reference: ref);
        final resp =
            await _post(
                  'https://auth.rwkvos.com/api/internet_search',
                  token: 'x8rYbL3KfGp2Nq1zT9wVvJ0iQ5sUoAeX7HcM4',
                  body: {
                    "query": prompt,
                    "top_n": 3,
                    'is_deepsearch': deepSearch,
                  },
                ).timeout(const Duration(seconds: 10))
                as dynamic;
        qqq('web search mode: ${webSearchMode.q}');
        final refs = (resp['data'] as Iterable).map((e) => Reference.fromJson(e)).toList();
        ref = ref.copyWith(list: refs);
        final searchResult = refs.map((e) => e.summary).join("\n");
        allMessage.removeLast();
        final template = P.preference.promptTemplate;
        final msg = sprintf(isZh ? template.webSearchChineseTemplate : template.webSearchTemplate, [searchResult, prompt]);
        allMessage.add(msg);
      } catch (e) {
        ref = ref.copyWith(error: e.toString());
        qqe(e);
      }
    }
    50.msLater.then((_) {
      _updateMessageById(id: receiveId, reference: ref);
    });

    return allMessage;
  }
}
