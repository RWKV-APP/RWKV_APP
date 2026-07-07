part of 'p.dart';

extension $ChatInputSend on _Chat {
  Future<void> onSendButtonPressed({
    required DemoType preferredDemoType,
  }) async {
    final inSee = P.app.pageKey.q == .see;

    if (!inSee && _showGeneratingSendBlockedAlert()) return;

    final textToSend = textInInput.q.trim();

    if (P.app.demoType.q == .tts) {
      await P.talk.gen();
      return;
    }

    qq;
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    if (inSee) {
      final hasAtLeastOneImage = P.msg.hasAtLeastOneImage.q;
      final imagePath = P.see.imagePath.q;
      if (!hasAtLeastOneImage && imagePath == null) {
        Alert.info(S.current.please_select_an_image_first);

        if (focusNode.hasFocus) {
          focusNode.unfocus();
        }

        final imagePath = await showImageSelector(
          onProcessingChanged: (value) => P.see.processingImage.q = value,
        );
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
    textInInput.q = "";

    final _editingBotMessage = P.msg.editingBotMessage.q;

    if (_editingBotMessage) {
      final id = DateTime.now().millisecondsSinceEpoch;
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

      if (P.rwkvGeneration.generating.q) {
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
          P.rwkvGeneration.clearStates();
          await 10.msLater;
        }
        await send("", type: MessageType.userImage, imageUrl: imagePath);
        await 50.msLater;
        final finalTextToSend = "<image>$imagePath</image>" + textToSend.trim();
        await send(finalTextToSend);
      }

      return;
    }

    await send(textToSend);
  }

  Future<void> onEditingComplete() async {
    qq;
  }

  Future<void> onKeyboardSubmitted(String aString) async {
    qqq(aString);
    if (P.app.pageKey.q == .see) {
      await onSendButtonPressed(preferredDemoType: .see);
      return;
    }

    if (_showGeneratingSendBlockedAlert()) return;

    final textToSend = textInInput.q.trim();

    if (P.app.demoType.q == .tts) {
      await P.talk.gen();
      return;
    }

    if (textToSend.isEmpty) return;
    textInInput.q = "";
    focusNode.unfocus();
    await send(textToSend);
  }

  void cancelEditing({bool clearInput = false}) {
    final editingIndex = P.msg.editingOrRegeneratingIndex.q;
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
        duration: duration ?? const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      scrollController.jumpTo(offset);
    }
  }

  void toggleCompletionMode() {
    final receiving = P.rwkvGeneration.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }
    final r = !completionMode.q;
    completionMode.q = r;
    P.rwkvParams.setGenerateMode(r);
  }

  Future<void> stopCompletion() async {
    P.rwkvGeneration.stop();
  }

  bool _showGeneratingSendBlockedAlert() {
    if (!P.rwkvGeneration.generating.q) return false;
    Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
    return true;
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

    if (_showGeneratingSendBlockedAlert()) return;

    raw = raw.trim();
    String message = raw;
    final isMarkdownFlickerRepro = _shouldStartMarkdownFlickerRepro(raw);

    if (!isMarkdownFlickerRepro && !checkModelSelection(preferredDemoType: .chat)) return;
    _clearResponseStyleSequentialState();

    final currentModel = P.rwkvModel.latest.q;
    final modelName = isMarkdownFlickerRepro
        ? _markdownFlickerReproModelName
        : P.albatrossRuntime.enabled.q
        ? "Albatross"
        : currentModel?.name;
    if (modelName == null) {
      Alert.info(S.current.please_load_model_first);
      return;
    }

    final thinkingMode = P.rwkvParams.thinkingMode.q;
    final markdownFlickerReproBatchSize = isMarkdownFlickerRepro && P.app.pageKey.q == .chat && effectiveBatchEnabled.q
        ? effectiveBatchCount.q
        : 1;
    final markdownFlickerReproBatchSlotLabels = isMarkdownFlickerRepro && markdownFlickerReproBatchSize > 1
        ? List<String>.generate(markdownFlickerReproBatchSize, (int index) => "Repro ${index + 1}")
        : null;

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

    final id = DateTime.now().millisecondsSinceEpoch;

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
          final finalizedMsg = parentMsg.copyWith(
            content: finalizedContent,
            clearBatchSlotLabels: true,
          );
          P.msg._syncMsg(parentMsg.id, finalizedMsg);

          // 重新计算 token count（从 batch 全量变为单 slot）
          unawaited(
            _refreshTokenCountsForMessage(
              messageId: parentMsg.id,
              overrideBotContent: finalizedContent,
              persistToMessage: true,
            ),
          );

          // Also finalize the paired user batch message if it exists
          final userParentNode = P.msg.msgNode.q.findParentByMsgId(parentMsg.id);
          if (userParentNode != null) {
            final userParentMsg = P.msg.pool.q[userParentNode.id];
            if (userParentMsg != null && userParentMsg.isMine) {
              final userParts = userParentMsg.content.split(Config.userMsgModifierSep);
              final userRawContent = userParts[0];
              final userTail = userParts.length > 1 ? userParts.sublist(1).join(Config.userMsgModifierSep) : "";
              if (getIsBatch(userRawContent)) {
                final userBatch = userRawContent.split(Config.batchMarker);
                if (selection < userBatch.length) {
                  final selectedQuestion = userBatch[selection];
                  final finalizedUserContent = userTail.isNotEmpty
                      ? selectedQuestion + Config.userMsgModifierSep + userTail
                      : selectedQuestion;
                  P.msg._syncMsg(userParentMsg.id, userParentMsg.copyWith(content: finalizedUserContent));
                }
              }
            }
          }
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

    _scheduleScrollToBottom();

    if (type == MessageType.userImage) {
      // 在之前的操作中已经注入了 LLM 了
      return;
    }

    P.msg.clearBottomDetailsStateInScope(scope: "chat_bot_message_bottom");

    final receiveId = DateTime.now().millisecondsSinceEpoch + 1;
    this.receiveId.q = receiveId;

    P.msg.editingOrRegeneratingIndex.q = null;

    _setReceivedTokens("", immediateUi: true);
    P.rwkvGeneration.generating.q = true;
    _liveTokenCountThrottler.cancel();

    final int plainBatchSlotCount = P.app.pageKey.q == .chat && responseStyle.q.activeCount <= 1 && effectiveBatchEnabled.q
        ? effectiveBatchCount.q
        : 1;

    final receiveMsg = Message(
      id: receiveId,
      content: "",
      isMine: false,
      changing: true,
      paused: false,
      modelName: modelName,
      runningMode: thinkingMode.toString(),
      rawDecodeParams: _resolveDecodeParamsSnapshotRaw(),
      batchSlotLabels:
          markdownFlickerReproBatchSlotLabels ??
          (P.app.pageKey.q == .chat && responseStyle.q.activeCount > 1
              ? responseStyle.q.enabledLabelsInOrder
              : _batchSlotLabelsForCount(plainBatchSlotCount)),
    );

    P.msg.pool.q[receiveId] = receiveMsg;
    parentNode.add(MsgNode(receiveId));
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
    if (isMarkdownFlickerRepro) {
      _startMarkdownFlickerRepro(
        messageId: receiveId,
        batchSize: markdownFlickerReproBatchSize,
      );
      return;
    }
    if (P.app.pageKey.q == .chat && fakeBatchInferenceBenchmarkEnabled.q) {
      final benchmarkBatchSize = effectiveBatchEnabled.q ? effectiveBatchCount.q : 1;
      _startFakeBatchInferenceBenchmark(
        messageId: receiveId,
        batchSize: benchmarkBatchSize,
      );
      return;
    }
    _scheduleRefreshLiveTokenCounts(messageId: receiveId, liveBotContent: "");

    List<String> history = withHistory ? _history(excludedMessageId: receiveId) : <String>[];
    history = withHistory ? await _historyWithWebSearch(receiveId, history) : [message];
    final inSee = P.app.pageKey.q == .see;
    // final forceChinese = inSee && message.containsChinese;
    final forceChinese = false;

    if (!inSee) {
      final List<ResponseStyleRoute> routes = responseStyle.q.enabledRoutesInOrder;
      if (routes.length > 1) {
        await _setFastThinkingModeForResponseStyleBatch();
        if (_shouldUseResponseStyleBatchExecution(routes.length)) {
          final List<to_rwkv.ChatBatchSlotConfig> slotConfigs = _buildResponseStyleSlotConfigs(
            history: history,
            routes: routes,
          );
          P.rwkvGeneration.sendMessages(
            history,
            forceChinese: forceChinese,
            overrideBatchSlotConfigs: slotConfigs,
          );
          _checkSensitive(raw);
          return;
        }
        final int currentReceiveId = this.receiveId.q!;
        unawaited(
          _startResponseStyleSequentialGeneration(
            messageId: currentReceiveId,
            history: history,
            routes: routes,
            forceChinese: forceChinese,
          ),
        );
        _checkSensitive(raw);
        return;
      }

      final ResponseStyleRoute route = routes.first;
      final List<String> singleRouteHistory = _buildRequestHistoryForResponseStyleRoute(
        history: history,
        route: route,
      );
      P.rwkvGeneration.sendMessages(
        singleRouteHistory,
        batchSize: effectiveBatchEnabled.q ? effectiveBatchCount.q : 1,
        forceChinese: forceChinese,
        forceLang: route.forceLang,
      );
      _checkSensitive(raw);
      return;
    }

    final batchSize = inSee ? 1 : (effectiveBatchEnabled.q ? effectiveBatchCount.q : 1);
    P.rwkvGeneration.sendMessages(history, batchSize: batchSize, forceChinese: forceChinese);

    _checkSensitive(raw);
  }

  Future<void> tryLoadLastChatModel() async {
    isAutoLoadingModel.q = true;
    try {
      await P.rwkvAutoLoad.restoreForPage(P.app.pageKey.q);
    } catch (e) {
      qqe("Failed to auto load chat model: $e");
    } finally {
      isAutoLoadingModel.q = false;
    }
  }

  void _scheduleScrollToBottom() {
    unawaited(_scrollToBottomAfterDelay());
  }

  Future<void> _scrollToBottomAfterDelay() async {
    await 34.msLater;
    await scrollToBottom();
  }
}
