part of 'p.dart';

class _MultiQuestion {
  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final questions = qs<List<String>>([]);

  late final canSend = qp((ref) {
    final generating = ref.watch(P.rwkv.generating);
    if (generating) return false;
    final questionList = ref.watch(questions);
    return questionList.any((q) => q.trim().isNotEmpty);
  });

  late final questionCount = qp((ref) {
    return ref.watch(P.chat.batchCount);
  });
}

/// Public methods
extension $MultiQuestion on _MultiQuestion {
  List<String> _pickRandomSuggestions(int count, {List<String> exclude = const []}) {
    List<Suggestion> pool;

    if (P.suggestion.useHighScoreApi.q && P.suggestion.highScoreTopSuggestions.q.isNotEmpty) {
      pool = P.suggestion.highScoreTopSuggestions.q;
    } else {
      pool = P.suggestion.config.q.chat.expand((c) => c.items).toList();
    }

    pool = pool.where((s) => !exclude.contains(s.prompt)).toList().shuffled;
    final int take = count < pool.length ? count : pool.length;
    return pool.sublist(0, take).map((s) => s.prompt).toList();
  }

  void initQuestions(int count) {
    final List<String> suggestions = _pickRandomSuggestions(count);
    final int remaining = count - suggestions.length;
    questions.q = [...suggestions, ...List<String>.filled(remaining < 0 ? 0 : remaining, "")];
  }

  void addQuestion() {
    final List<String> current = questions.q;
    final List<String> picked = _pickRandomSuggestions(1, exclude: current);
    final String newQuestion = picked.isNotEmpty ? picked.first : "";
    questions.q = [...current, newQuestion];
  }

  void removeQuestion(int index) {
    final List<String> current = questions.q;
    if (index < 0 || index >= current.length) return;
    if (current.length <= 2) return;
    questions.q = [...current]..removeAt(index);
  }

  void refreshQuestion(int index) {
    final List<String> current = questions.q;
    if (index < 0 || index >= current.length) return;
    final List<String> exclude = [
      for (int i = 0; i < current.length; i++)
        if (i != index && current[i].trim().isNotEmpty) current[i],
    ];
    final List<String> picked = _pickRandomSuggestions(1, exclude: exclude);
    if (picked.isEmpty) return;
    final List<String> next = [...current];
    next[index] = picked.first;
    questions.q = next;
  }

  void updateQuestion(int index, String text) {
    if (index < 0 || index >= questions.q.length) return;
    final next = <String>[...questions.q];
    next[index] = text;
    questions.q = next;
  }

  void reset() {
    questions.q = [];
  }

  Future<void> sendFromAskQuestion(List<String> allQuestions) async {
    final List<String> nonEmpty = [
      for (final q in allQuestions)
        if (q.trim().isNotEmpty) q.trim(),
    ];
    if (nonEmpty.isEmpty) return;

    // 检查模型是否支持 batch
    final List<int> supported = P.rwkv.supportedBatchSizes.q;
    if (supported.isEmpty) {
      Alert.warning(S.current.this_model_does_not_support_batch_inference, position: AlertPosition.bottom);
      return;
    }

    final int maxBatchSize = supported.reduce((a, b) => a > b ? a : b);
    if (maxBatchSize < 2) {
      Alert.warning(S.current.this_model_does_not_support_batch_inference, position: AlertPosition.bottom);
      return;
    }

    // 截取至最大支持数量，且至少 2
    final int clampedCount = nonEmpty.length.clamp(2, maxBatchSize);
    final List<String> effectiveList = nonEmpty.length > clampedCount ? nonEmpty.sublist(0, clampedCount) : nonEmpty;

    // 对齐 batchCount
    P.chat.batchCount.q = effectiveList.length;
    if (!P.chat.batchEnabled.q) P.chat.batchEnabled.q = true;

    // 设置 questions 并发送
    questions.q = effectiveList;
    await sendAll();
  }

  Future<void> sendAll() async {
    final questionList = questions.q;
    final List<String> effectiveQuestions = [
      for (final q in questionList)
        if (q.trim().isNotEmpty) q.trim(),
    ];
    if (effectiveQuestions.isEmpty) return;
    if (effectiveQuestions.length < 2) {
      Alert.info("Please provide at least 2 questions for batch sending", position: AlertPosition.bottom);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    if (P.rwkv.generating.q) {
      Alert.warning(S.current.please_wait_for_the_model_to_finish_generating, position: AlertPosition.bottom);
      return;
    }

    final thinkingMode = P.rwkv.thinkingMode.q;
    final currentModel = P.rwkv.latestModel.q;

    // 1. 构建 batch 格式的用户消息 content
    final String userBatchContent = effectiveQuestions.join(Config.batchMarker) + Config.batchMarker + "-1";
    final String storedContent = userBatchContent + Config.userMsgModifierSep + thinkingMode.userMsgFooter;

    // 2. 处理父节点的 batch finalization (同 _Chat.send 727-737)
    MsgNode parentNode = P.msg.msgNode.q.wholeLatestNode;
    final parentMsg = P.msg.pool.q[parentNode.id];
    if (parentMsg != null && parentMsg.type == MessageType.text && !parentMsg.isMine && getIsBatch(parentMsg.content)) {
      final selection = P.msg.batchSelection(parentMsg).q;
      if (selection != null) {
        final finalizedContent = parentMsg.content.split(Config.batchMarker)[selection];
        P.msg._syncMsg(parentMsg.id, parentMsg.copyWith(content: finalizedContent));
        unawaited(
          P.chat._refreshTokenCountsForMessage(
            messageId: parentMsg.id,
            overrideBotContent: finalizedContent,
            persistToMessage: true,
          ),
        );

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

    // 3. 创建用户消息
    final int userMsgId = HF.milliseconds;
    final userMsg = Message(
      id: userMsgId,
      content: storedContent,
      isMine: true,
      type: MessageType.text,
      paused: false,
    );
    P.msg._syncMsg(userMsgId, userMsg);
    parentNode = parentNode.add(MsgNode(userMsgId));

    // 4. 创建空 bot 消息
    final int botMsgId = HF.milliseconds + 1;
    final botMsg = Message(
      id: botMsgId,
      content: "",
      isMine: false,
      changing: true,
      paused: false,
      modelName: currentModel?.name,
      runningMode: thinkingMode.toString(),
      rawDecodeParams: P.chat._resolveDecodeParamsSnapshotRaw(),
    );
    P.msg._syncMsg(botMsgId, botMsg);
    parentNode.add(MsgNode(botMsgId));

    // 5. 更新 ids, 同步
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();

    // 6. 设置 receiveId，让 _Chat._onStreamEvent 处理
    P.chat.receiveId.q = botMsgId;
    P.chat.receivedTokens.q = "";
    P.rwkv.generating.q = true;

    // 7. 关闭面板
    reset();

    // 8. 构建 batchMessages
    // _history() 会读取当前消息列表，此时 userMsg 已加入
    // history 最后一个元素是 batch 格式的用户消息，需要移除它并手动构建各 slot
    final List<String> history = P.chat._history();
    // history 末尾是 [batchUserContent, emptyBotContent]，需要去掉这两个
    final List<String> historyPrefix = history.length > 2 ? history.sublist(0, history.length - 2) : [];

    final List<List<String>> batchMessages = [];
    for (final question in effectiveQuestions) {
      String userContent = question;
      if (thinkingMode.userMsgFooter.isNotEmpty) {
        userContent = userContent + thinkingMode.userMsgFooter;
      }
      batchMessages.add([...historyPrefix, userContent]);
    }

    // 9. 发送
    final int batchSize = batchMessages.length;
    P.rwkv.sendMessages(
      batchMessages.first,
      batchSize: batchSize,
      overrideBatchMessages: batchMessages,
    );

    // 10. 滚动到底部
    34.msLater.then((_) {
      P.chat.scrollToBottom();
    });
  }
}
