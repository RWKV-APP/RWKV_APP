part of 'p.dart';

class _Chat {
  // ===========================================================================
  // Instance
  // ===========================================================================

  /// The scroll controller of the chat page message list
  late final scrollController = ScrollController();

  /// The text editing controller of the chat page input
  late final textEditingController = TextEditingController(text: "");

  /// The focus node of the chat page input
  late final focusNode = FocusNode();

  late final _sensitiveThrottler = Throttler(milliseconds: 333, trailing: true);

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final textInInput = qs("");

  /// Disable sender
  ///
  /// TODO: Should be moved to state/rwkv.dart
  @Deprecated("Use P.rwkv.receiving instead")
  late final receivingTokens = qs(false);

  late final prefillPercentage = qs(0.0);

  /// TODO: Should be moved to state/rwkv.dart
  late final receivedTokens = qs("");

  late final inputHeight = qs(77.0);

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
    final receiving = receivingTokens.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (mode != WebSearchMode.off) {
      wenYanWen.q = WenyanMode.off;
    }
    webSearchMode.q = mode;
  }

  void onSwitchWenYanWen(WenyanMode mode) async {
    final receiving = receivingTokens.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    if (mode != WenyanMode.off) {
      webSearchMode.q = WebSearchMode.off;
      if (mode == WenyanMode.mixed && P.rwkv.supportedBatchSizes.q.isNotEmpty) {
        onBatchInferenceSwitchChanged(true);
        batchCount.q = 2;
      }
    } else {
      if (wenYanWen.q == WenyanMode.mixed && batchCount.q == 2) {
        batchCount.q = 1;
        onBatchInferenceSwitchChanged(false);
      }
    }

    wenYanWen.q = mode;
  }

  Future<void> onSendButtonPressed({
    required DemoType preferredDemoType,
  }) async {
    qq;
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    final inSee = P.app.pageKey.q == PageKey.see;
    if (inSee) {
      final hasAtLeastOneImage = P.msg.hasAtLeastOneImage.q;
      final imagePath = P.see.imagePath.q;
      if (!hasAtLeastOneImage && imagePath == null) {
        Alert.info(S.current.please_select_an_image_first);
        await showImageSelector();
        return;
      }
    }

    if (!inputHasContent.q) {
      Alert.info("Please enter a message");
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
      if (imagePath == null) {
        await send(textToSend);
      } else {
        P.see.imagePath.q = null;
        if (P.msg.hasAtLeastOneImage.q) {
          P.msg._clear();
          await Future.delayed(10.ms);
          P.rwkv.clearStates();
          await Future.delayed(10.ms);
        }
        await send("", type: MessageType.userImage, imageUrl: imagePath);
        await Future.delayed(50.ms);
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

    final receivingTokens = P.chat.receivingTokens.q;

    if (receivingTokens) {
      Alert.info("Please wait for the previous message to be generated");
      return;
    }

    if (P.app.demoType.q == DemoType.tts) {
      await P.talk.gen();
      return;
    }

    final textToSend = textInInput.q.trim();
    if (textToSend.isEmpty) return;
    textInInput.q = "";
    focusNode.unfocus();
    await send(textToSend);
  }

  Future<void> onTapMessageList() async {
    qq;
    P.chat.focusNode.unfocus();
    P.talk.dismissAllShown();
    final _editingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (_editingIndex == null) return;
    P.msg.editingOrRegeneratingIndex.q = null;
    textEditingController.value = const TextEditingValue(text: "");
  }

  Future<void> onTapClearInput() async {
    qq;
    textEditingController.clear();
    textInInput.q = "";
    P.msg.editingOrRegeneratingIndex.q = null;
  }

  Future<void> onTapEditInUserMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: DemoType.chat)) return;
    final content = P.msg.list.q[index].contentAndTails[0];
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  Future<void> onTapEditInBotMessageBubble({required int index}) async {
    if (!checkModelSelection(preferredDemoType: DemoType.chat)) return;
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
    if (receivingTokens.q) await onStopButtonPressed();
    await Future.delayed(100.ms);
    // Alert.success(S.current.new_chat_started);
    P.msg._clear();
    P.rwkv.clearStates();
    P.conversation.currentCreatedAtUS.q = P.msg.msgNode.q.createAtInUS;
  }

  void toggleCompletionMode() {
    final receiving = P.chat.receivingTokens.q;
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

    if (!checkModelSelection(preferredDemoType: DemoType.chat)) return;

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

    Future.delayed(34.ms).then((_) {
      scrollToBottom();
    });

    if (type == MessageType.userImage) {
      // 在之前的操作中已经注入了 LLM 了
      return;
    }

    final receiveId = HF.milliseconds + 1;
    this.receiveId.q = receiveId;

    List<String> history = withHistory ? _history() : <String>[];

    P.msg.editingOrRegeneratingIndex.q = null;

    receivedTokens.q = "";
    receivingTokens.q = true;

    final receiveMsg = Message(
      id: receiveId,
      content: "",
      isMine: false,
      changing: true,
      paused: false,
      modelName: currentModel.name,
      runningMode: thinkingMode.toString(),
      rawDecodeParams: P.rwkv.backendBatchParams.q.rawDecodeParams,
    );

    P.msg.pool.q[receiveId] = receiveMsg;
    parentNode.add(MsgNode(receiveId));
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();

    history = withHistory ? await _historyWithWebSearch(receiveId, history) : [message];
    final inSee = P.app.pageKey.q == PageKey.see;
    final batchSize = inSee ? 1 : (batchEnabled.q ? batchCount.q : 1);

    P.rwkv.sendMessages(history, batchSize: batchSize);

    _checkSensitive(raw);
  }

  Future<void> onStopButtonPressed({bool wantHaptic = true}) async {
    qqq("receiveId: ${receiveId.q}");
    if (wantHaptic) P.app.hapticLight();
    await Future.delayed(1.ms);
    final id = receiveId.q;
    if (id == null) {
      qqw("message id is null");
      return;
    }
    if (!receivingTokens.q) {
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
  }

  Future<void> onBatchInferenceSwitchChanged(bool value) async {
    P.app.hapticLight();
    P.chat.batchEnabled.q = value;
    if (wenYanWen.q == WenyanMode.mixed && !value) {
      P.chat.wenYanWen.q = WenyanMode.off;
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
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        return;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.see:
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

    receivingTokens.l(_onReceivingTokensChanged);

    P.app.lifecycleState.lb(_onLifecycleStateChanged);

    P.preference.preferredLanguage.lv(P.suggestion.loadSuggestions);

    P.rwkv.supportedBatchSizes.l(_onSupportedBatchSizesChanged);

    batchCount.l(_onBatchCountChanged);
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

    await Future.delayed(1.ms);

    _pauseMessageById(id: id, isSensitive: true);
  }

  void _onLifecycleStateChanged(AppLifecycleState? previous, AppLifecycleState next) {
    if (P.app.isDesktop.q) return;
    final isToBackground = next == AppLifecycleState.paused || next == AppLifecycleState.hidden;
    if (isToBackground) {
      if (receiveId.q != null && _autoPauseId.q == null && receivingTokens.q == true) {
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

  void _onReceivingTokensChanged(bool next) async {}

  Future<void> _pauseMessageById({required int id, bool isSensitive = false}) async {
    qq;

    P.rwkv.stop();

    final msg = P.msg.pool.q[id];
    if (msg == null) {
      qqw("message not found");
      return;
    }

    if (msg.paused) {
      qqw("message already paused");
      return;
    }

    final newMsg = msg.copyWith(paused: true, isSensitive: isSensitive);
    P.msg._syncMsg(id, newMsg);
  }

  Future<void> _onFocusNodeChanged() async {
    hasFocus.q = focusNode.hasFocus;
  }

  Future<void> _onNewFileReceived((File, int) event) async {
    final demoType = P.app.demoType.q;

    if (demoType == DemoType.tts || demoType == DemoType.chat) {
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
      case PageKey.completion:
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) await P.rwkv._releaseAllModels();
        break;
      case PageKey.chat:
        P.rwkv.updateSystemPrompt();
        P.app.demoType.q = DemoType.chat;
        final isTranslate = model?.tags.contains("translate") ?? false;
        if (isTTS || isTranslate || isSee) {
          P.rwkv.currentWorldType.q = null;
          await P.rwkv._releaseAllModels();
        }
        break;
      case PageKey.talk:
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
    if (pageKey == PageKey.translator || pageKey == PageKey.ocr || pageKey == PageKey.benchmark || pageKey == PageKey.completion) return;
    qqq("callingFunction: $callingFunction");

    final id = receiveId.q;

    if (id == null) {
      qqe("receiveId is null");
      return;
    }

    final receivedTokens = this.receivedTokens.q;

    _updateMessageById(
      id: id,
      content: receivedTokens,
      changing: false,
      callingFunction: callingFunction,
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
    double? ttsOverallProgress,
    List<double>? ttsPerWavProgress,
    List<String>? ttsFilePaths,
    RefInfo? reference,
  }) {
    if (completionMode.q) {
      return;
    }
    final msg = P.msg.pool.q[id];
    if (msg == null) {
      qqe("message not found");
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
      ttsOverallProgress: ttsOverallProgress,
      ttsPerWavProgress: ttsPerWavProgress,
      ttsFilePaths: ttsFilePaths,
    );
    P.msg._syncMsg(id, newMsg);
  }

  @Deprecated("Use _onStreamEvent instead")
  void _onOldStreamEvent(LLMEvent event) {
    switch (event.type) {
      case _RWKVMessageType.isGenerating:
        final isGenerating = event.content == "true";
        receivingTokens.q = isGenerating;
        if (!isGenerating && !completionMode.q) _fullyReceived(callingFunction: "_onStreamEvent:isGenerating");
        break;

      case _RWKVMessageType.streamResponse:
        receivedTokens.q = event.content;
        receivingTokens.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == PageKey.translator) return;

    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        receivedTokens.q = res.responseBufferContent;
        if (completionMode.q) return;
        _sensitiveThrottler.call(() {
          _checkSensitive(res.responseBufferContent);
        });
        break;

      case from_rwkv.ResponseBatchBufferContent res:
        final responseBufferContent = res.responseBufferContent.join(Config.batchMarker) + Config.batchMarker + "-1";
        receivedTokens.q = responseBufferContent;
        if (completionMode.q) return;
        _sensitiveThrottler.call(() {
          _checkSensitive(responseBufferContent);
        });
        break;

      case from_rwkv.GenerateStop _:
        receivedTokens.q = "";
        receivingTokens.q = false;
        break;

      case from_rwkv.GenerateStart _:
        receivedTokens.q = "";
        receivingTokens.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamDone() async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == PageKey.translator) return;
    qq;
    final demoType = P.app.demoType.q;
    if (demoType != DemoType.chat && demoType != DemoType.see) return;
    receivingTokens.q = false;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == PageKey.translator) return;
    qqe("error: $error");
    if (!kDebugMode) Sentry.captureException(error, stackTrace: stackTrace);
    final demoType = P.app.demoType.q;
    if (demoType != DemoType.chat && demoType != DemoType.see) return;
    receivingTokens.q = false;
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
    Future.delayed(50.ms, () {
      _updateMessageById(id: receiveId, reference: ref);
    });

    return allMessage;
  }
}
