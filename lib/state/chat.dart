part of 'p.dart';

class _Chat {
  /// The key of it is the id of the message
  late final cotDisplayState = qsf<int, CoTDisplayState>(CoTDisplayState.showCotHeaderAndCotContent);

  /// The scroll controller of the chat page message list
  late final scrollController = ScrollController();

  /// The text editing controller of the chat page input
  late final textEditingController = TextEditingController(text: "");

  /// The focus node of the chat page input
  late final focusNode = FocusNode();

  late final textInInput = qs("");

  late final inputHasContent = qp((ref) {
    final textInInput = ref.watch(this.textInInput);
    return textInInput.trim().isNotEmpty;
  });

  /// Disable sender
  ///
  /// TODO: Should be moved to state/rwkv.dart
  @Deprecated("Use P.rwkv.receiving instead")
  late final receivingTokens = qs(false);

  /// TODO: Should be moved to state/rwkv.dart
  late final receivedTokens = qs("");

  late final inputHeight = qs(77.0);

  late final receiveId = qs<int?>(null);

  late final hasFocus = qs(false);

  late final autoPauseId = qs<int?>(null);

  late final selectedMessages = qs<Set<int>>({});

  late final selectMessageMode = qs(false);

  late final _sensitiveThrottler = Throttler(milliseconds: 333, trailing: true);
}

/// Public methods
extension $Chat on _Chat {
  void clearMessages() {
    P.msg._clear();
  }

  FV onSendButtonPressed() async {
    qq;
    if (!checkModelSelection()) return;

    if (!inputHasContent.q) {
      Alert.info("Please enter a message");
      return;
    }

    focusNode.unfocus();
    final textToSend = textInInput.q.trim();
    textInInput.uc();

    final _editingBotMessage = P.msg.editingBotMessage.q;

    if (_editingBotMessage) {
      final id = HF.debugShorterMS;
      final currentMessages = [...P.msg.list.q];
      final _editingIndex = P.msg.editingOrRegeneratingIndex.q!;
      final currentMessage = currentMessages[_editingIndex];

      final newMsg = Message(
        id: id,
        content: textToSend,
        isMine: false,
        changing: false,
        isReasoning: currentMessage.isReasoning,
        paused: currentMessage.paused,
        modelName: currentMessage.modelName,
        runningMode: currentMessage.runningMode,
      );

      P.msg.pool.q = {...P.msg.pool.q, id: newMsg};
      final userMsgNode = P.msg._msgNode.findParentByMsgId(currentMessage.id);
      if (userMsgNode == null) {
        qqe("We should found a user message node before a bot message node");
        return;
      }
      userMsgNode.add(MsgNode(id));
      P.msg.ids.q = P.msg._msgNode.latestMsgIdsWithoutRoot;
      P.msg.editingOrRegeneratingIndex.q = null;
      Alert.success(S.current.bot_message_edited);
      return;
    }

    await send(textToSend);
  }

  FV onEditingComplete() async {
    qq;
  }

  FV onKeyboardSubmitted(String aString) async {
    qqq(aString);

    final receivingTokens = P.chat.receivingTokens.q;

    if (receivingTokens) {
      Alert.info("Please wait for the previous message to be generated");
      return;
    }

    if (P.app.demoType.q == DemoType.tts) {
      await P.tts.gen();
      return;
    }

    final textToSend = textInInput.q.trim();
    if (textToSend.isEmpty) return;
    textInInput.uc();
    focusNode.unfocus();
    await send(textToSend);
  }

  FV onTapMessageList() async {
    qq;
    P.chat.focusNode.unfocus();
    P.tts.dismissAllShown();
    final _editingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (_editingIndex == null) return;
    P.msg.editingOrRegeneratingIndex.q = null;
    textEditingController.value = const TextEditingValue(text: "");
  }

  FV onTapClearInput() async {
    qq;
    textEditingController.clear();
    textInInput.uc();
    P.msg.editingOrRegeneratingIndex.q = null;
  }

  FV onTapEditInUserMessageBubble({required int index}) async {
    if (!checkModelSelection()) return;
    final content = P.msg.list.q[index].content;
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  FV onTapEditInBotMessageBubble({required int index}) async {
    if (!checkModelSelection()) return;
    final content = P.msg.list.q[index].content;
    textEditingController.value = TextEditingValue(text: content);
    focusNode.requestFocus();
    P.msg.editingOrRegeneratingIndex.q = index;
  }

  FV onRegeneratePressed({required int index}) async {
    qqq("index: $index");
    if (!checkModelSelection()) return;

    final userMessage = P.msg.list.q[index - 1];
    P.msg.editingOrRegeneratingIndex.q = index;
    textInInput.uc();
    focusNode.unfocus();
    if (userMessage.type == MessageType.userAudio) {
      await send(
        "",
        type: MessageType.userAudio,
        audioUrl: userMessage.audioUrl,
        withHistory: false,
        audioLength: userMessage.audioLength,
      );
      return;
    }
    await send(userMessage.content, isRegenerate: true);
  }

  FV scrollToBottom({Duration? duration, bool? animate = true}) async {
    await scrollTo(offset: 0, duration: duration, animate: animate);
  }

  FV scrollTo({required double offset, Duration? duration, bool? animate = true}) async {
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

  FV startNewChat() async {
    if (receivingTokens.q) await onStopButtonPressed();
    await Future.delayed(100.ms);
    Alert.success(S.current.new_chat_started);
    P.msg._clear();
    P.rwkv.clearStates();
  }

  FV send(
    String message, {
    MessageType type = MessageType.text,
    String? imageUrl,
    String? audioUrl,
    int? audioLength,
    bool withHistory = true,
    bool isRegenerate = false,
  }) async {
    MsgNode? parentNode = P.msg._msgNode.wholeLatestNode;

    final editingOrRegeneratingIndex = P.msg.editingOrRegeneratingIndex.q;
    if (editingOrRegeneratingIndex != null) {
      final currentMessage = P.msg.findByIndex(editingOrRegeneratingIndex);
      if (currentMessage == null) {
        qqe("currentMessage is null");
        return;
      }

      if (isRegenerate) {
        parentNode = P.msg._msgNode.findParentByMsgId(currentMessage.id);
      } else {
        // 以该消息的父节点作为新消息的父结点
        parentNode = P.msg._msgNode.findParentByMsgId(currentMessage.id);
      }

      if (parentNode == null) {
        qqe("parentNode is null");
        return;
      }
    }

    late final Message? msg;

    final id = HF.debugShorterMS;

    if (isRegenerate) {
      // 重新生成 Bot 消息, 所以, 不添加新的用户消息
      msg = null;
      // 但是, 需要移除旧的 bot 消息
      parentNode.latest = null;
    } else {
      // 新增或编辑了用户消息
      msg = Message(
        id: id,
        content: message,
        isMine: true,
        type: type,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        audioLength: audioLength,
        isReasoning: false,
        paused: false,
      );
      P.msg.pool.q = {...P.msg.pool.q, id: msg};
      parentNode = parentNode.add(MsgNode(id));
    }

    // 更新消息 id 列表
    P.msg.ids.q = P.msg._msgNode.latestMsgIdsWithoutRoot;

    Future.delayed(34.ms).then((_) {
      scrollToBottom();
    });

    if (type == MessageType.userImage) {
      // 在之前的操作中已经注入了 LLM 了
      return;
    }

    // TODO: @WangCe: Use _history() instead
    final historyMessage = P.msg.list.q
        .where((e) {
          return e.type != MessageType.userImage;
        })
        .m((e) {
          if (!e.isReasoning) return e.content;
          if (!e.isCotFormat) return e.content;
          if (!e.containsCotEndMark) return e.content;
          final (cotContent, cotResult) = e.cotContentAndResult;
          return cotResult;
        });

    final history = withHistory ? historyMessage : [message];

    P.rwkv.sendMessages(history);
    P.msg.editingOrRegeneratingIndex.q = null;

    receivedTokens.q = "";
    receivingTokens.q = true;

    final receiveId = HF.debugShorterMS + 1;

    this.receiveId.q = receiveId;
    final receiveMsg = Message(
      id: receiveId,
      content: "",
      isMine: false,
      changing: true,
      isReasoning: P.rwkv.reasoning.q,
      paused: false,
      modelName: P.rwkv.currentModel.q?.name,
      runningMode: P.rwkv.thinkingMode.q.toString(),
    );

    P.msg.pool.q[receiveId] = receiveMsg;
    parentNode.add(MsgNode(receiveId));
    P.msg.ids.q = P.msg._msgNode.latestMsgIdsWithoutRoot;

    _checkSensitive(message);
  }

  FV onStopButtonPressed() async {
    qqq("receiveId: ${receiveId.q}");
    P.app.hapticLight();
    await Future.delayed(1.ms);
    final id = receiveId.q;
    if (id == null) {
      qqw("message id is null");
      return;
    }
    _pauseMessageById(id: id);
  }

  FV resumeMessageById({required int id, bool withHaptic = true}) async {
    qq;
    if (withHaptic) P.app.hapticLight();
    P.rwkv.sendMessages(_history());
    _updateMessageById(
      id: id,
      changing: true,
      paused: false,
      callingFunction: "resumeMessageById",
    );
  }
}

/// Private methods
extension _$Chat on _Chat {
  FV _init() async {
    switch (P.app.demoType.q) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        return;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
    }
    qq;

    textEditingController.addListener(_onTextEditingControllerValueChanged);
    textInInput.l(_onTextChanged);

    P.app.pageKey.l(_onPageKeyChanged);

    P.rwkv.oldBroadcastStream.listen(_onOldStreamEvent, onDone: _onStreamDone, onError: _onStreamError);
    P.rwkv.broadcastStream.listen(_onStreamEvent, onDone: _onStreamDone, onError: _onStreamError);

    P.world.audioFileStreamController.stream.listen(_onNewFileReceived);
    focusNode.addListener(_onFocusNodeChanged);
    hasFocus.q = focusNode.hasFocus;
    P.suggestion.loadSuggestions();

    receivingTokens.l(_onReceivingTokensChanged);

    P.app.lifecycleState.lb(_onLifecycleStateChanged);

    P.preference.preferredLanguage.lv(P.suggestion.loadSuggestions);
  }

  FV _checkSensitive(String content) async {
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
      if (receiveId.q != null && autoPauseId.q == null && receivingTokens.q == true) {
        autoPauseId.q = receiveId.q!;
        _pauseMessageById(id: receiveId.q!);
      }
    } else {
      if (autoPauseId.q != null) {
        resumeMessageById(id: autoPauseId.q!, withHaptic: false);
        autoPauseId.uc();
      }
    }
    qqq("autoPauseId: ${autoPauseId.q}, receiveId: ${receiveId.q}, state: $next");
  }

  List<String> _history() {
    final history = P.msg.list.q.where((msg) => msg.type == MessageType.text).m((e) {
      if (!e.isReasoning) return e.content;
      if (!e.isCotFormat) return e.content;
      if (!e.containsCotEndMark) return e.content;
      if (e.paused) return e.content;
      final (cotContent, cotResult) = e.cotContentAndResult;
      return cotResult;
    });
    return history;
  }

  void _onReceivingTokensChanged(bool next) async {}

  FV _pauseMessageById({required int id, bool isSensitive = false}) async {
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
    P.msg.pool.q = {...P.msg.pool.q, id: newMsg};
  }

  FV _onFocusNodeChanged() async {
    hasFocus.q = focusNode.hasFocus;
  }

  FV _onNewFileReceived((File, int) event) async {
    final demoType = P.app.demoType.q;
    if (demoType == DemoType.world) {
      final (file, length) = event;
      final path = file.path;

      qqq("new file received: $path, length: $length");

      final t0 = HF.debugShorterMS;
      P.rwkv.setAudioPrompt(path: path);
      final t1 = HF.debugShorterMS;
      qqq("setAudioPrompt done in ${t1 - t0}ms");
      send("", type: MessageType.userAudio, audioUrl: path, withHistory: false, audioLength: length);
      final t2 = HF.debugShorterMS;
      qqq("send done in ${t2 - t1}ms");
    }

    if (demoType == DemoType.tts) {
      final (file, length) = event;
      final path = file.path;
      qqq("new file received: $path, length: $length");
      P.tts.selectSourceAudioPath.q = path;
      P.tts.selectedSpkName.uc();
    }
  }

  void _onPageKeyChanged(PageKey pageKey) {
    qqq("_onPageKeyChanged: $pageKey");
    Future.delayed(200.ms).then((_) {
      P.msg._clear();
    });

    if (!checkModelSelection()) return;
  }

  void _onTextEditingControllerValueChanged() {
    // qqq("_onTextEditingControllerValueChanged");
    final textInController = textEditingController.text;
    if (textInInput.q != textInController) textInInput.q = textInController;
  }

  void _onTextChanged(String next) {
    // qqq("_onTextChanged");
    final textInController = textEditingController.text;
    if (next != textInController) textEditingController.text = next;
  }

  void _fullyReceived({String? callingFunction}) {
    qqq("callingFunction: $callingFunction");

    final id = receiveId.q;

    if (id == null) {
      qqe("receiveId is null");
      return;
    }

    _updateMessageById(
      id: id,
      content: receivedTokens.q,
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
  }) {
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
    P.msg.pool.q = {...P.msg.pool.q, id: newMsg};
  }

  @Deprecated("Use _onStreamEvent instead")
  void _onOldStreamEvent(LLMEvent event) {
    switch (event.type) {
      case _RWKVMessageType.isGenerating:
        final isGenerating = event.content == "true";
        receivingTokens.q = isGenerating;
        if (!isGenerating) _fullyReceived(callingFunction: "_onStreamEvent:isGenerating");
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
    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        receivedTokens.q = res.responseBufferContent;
        _sensitiveThrottler.call(() {
          _checkSensitive(res.responseBufferContent);
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
    qq;
    final demoType = P.app.demoType.q;
    if (demoType != DemoType.chat && demoType != DemoType.world) return;
    receivingTokens.q = false;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    qqe("error: $error");
    if (!kDebugMode) Sentry.captureException(error, stackTrace: stackTrace);
    final demoType = P.app.demoType.q;
    if (demoType != DemoType.chat && demoType != DemoType.world) return;
    receivingTokens.q = false;
  }
}
