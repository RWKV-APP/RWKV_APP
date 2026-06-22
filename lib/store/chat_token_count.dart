part of 'p.dart';

extension $ChatTokenCount on _Chat {
  void _onMessageIdsChangedForTokenCount(List<int> messageIds) {
    _refreshTokenCountEpoch = _refreshTokenCountEpoch + 1;
    final epoch = _refreshTokenCountEpoch;
    unawaited(_refreshMissingTokenCountsForMessages(messageIds: messageIds, epoch: epoch));
  }

  Future<void> _refreshMissingTokenCountsForMessages({
    required List<int> messageIds,
    required int epoch,
  }) async {
    for (final messageId in messageIds) {
      if (epoch != _refreshTokenCountEpoch) return;
      final message = P.msg.pool.q[messageId];
      if (message == null || message.isMine || message.type != MessageType.text) continue;
      final existingMessageCount = P.msg.getBottomMessageTokensCount(messageId: messageId);
      final existingConversationCount = P.msg.getBottomConversationTokensCount(messageId: messageId);
      final persistedMessageCount = message.messageTokensCount;
      final persistedConversationCount = message.conversationTokensCount;
      final hasCachedCount = existingMessageCount != null && existingConversationCount != null;
      final hasPersistedCount = persistedMessageCount != null && persistedConversationCount != null;
      if (hasCachedCount || hasPersistedCount) {
        final observedConversationCount = persistedConversationCount ?? existingConversationCount;
        _onConversationTokenCountObserved(conversationTokensCount: observedConversationCount);
        if (!message.changing && hasPersistedCount && !hasCachedCount) {
          P.msg.setBottomTokensCount(
            messageId: messageId,
            messageTokensCount: persistedMessageCount,
            conversationTokensCount: persistedConversationCount,
          );
        }
        continue;
      }
      final overrideBotContent = message.changing && receiveId.q == messageId ? receivedTokens.q : null;
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
    _liveTokenCountThrottler.call(() {
      final latestMessage = P.msg.pool.q[messageId];
      if (latestMessage == null || !latestMessage.changing) return;
      unawaited(_refreshTokenCountsForMessage(messageId: messageId, overrideBotContent: liveBotContent));
    });
  }

  Future<void> _refreshTokenCountsForMessage({
    required int messageId,
    String? overrideBotContent,
    bool persistToMessage = false,
  }) async {
    final message = P.msg.pool.q[messageId];
    if (message == null || message.isMine || message.type != MessageType.text) return;

    String botContent = overrideBotContent ?? message.content;
    if (botContent.isEmpty && messageId == receiveId.q) {
      botContent = receivedTokens.q;
    }

    final history = _historyForTokenCountUntilMessage(
      messageId: messageId,
      overrideBotContent: botContent,
    );
    if (history == null || history.isEmpty) return;

    final counts = await Future.wait([
      P.rwkvGeneration.calculateTokensCountRaw(text: botContent),
      P.rwkvGeneration.calculateTokensCountFromMessages(messages: history),
    ]);
    final messageTokensCount = counts[0];
    final conversationTokensCount = counts[1];
    if (messageTokensCount == null && conversationTokensCount == null) return;
    final latestMessage = P.msg.pool.q[messageId];
    if (latestMessage == null) return;
    final observedConversationTokensCount = conversationTokensCount ?? latestMessage.conversationTokensCount;
    _onConversationTokenCountObserved(conversationTokensCount: observedConversationTokensCount);

    P.msg.setBottomTokensCount(
      messageId: messageId,
      messageTokensCount: messageTokensCount,
      conversationTokensCount: conversationTokensCount,
    );

    if (!persistToMessage) return;

    final resolvedMessageTokensCount = messageTokensCount ?? latestMessage.messageTokensCount;
    final resolvedConversationTokensCount = conversationTokensCount ?? latestMessage.conversationTokensCount;
    if (resolvedMessageTokensCount == null && resolvedConversationTokensCount == null) return;

    final noMessageCountChanges = resolvedMessageTokensCount == latestMessage.messageTokensCount;
    final noConversationCountChanges = resolvedConversationTokensCount == latestMessage.conversationTokensCount;
    if (noMessageCountChanges && noConversationCountChanges) return;

    final updatedMessage = latestMessage.copyWith(
      messageTokensCount: resolvedMessageTokensCount,
      conversationTokensCount: resolvedConversationTokensCount,
    );
    await P.msg._syncMsg(messageId, updatedMessage);
  }

  List<String>? _historyForTokenCountUntilMessage({
    required int messageId,
    String? overrideBotContent,
  }) {
    final targetNode = P.msg.msgNode.q.findNodeByMsgId(messageId);
    if (targetNode == null) return null;
    final idsFromTargetToRoot = P.msg.msgNode.q.msgIdsFrom(targetNode);
    final orderedPathIds = idsFromTargetToRoot.reversed.where((int id) => id != 0).toList();
    if (orderedPathIds.isEmpty) return null;

    final scopedMessages = <Message>[];
    for (final id in orderedPathIds) {
      final pathMessage = P.msg.pool.q[id];
      if (pathMessage == null) continue;
      if (pathMessage.type != MessageType.text) continue;
      scopedMessages.add(pathMessage);
    }
    if (scopedMessages.isEmpty) return null;

    final history = <String>[];
    final isSingleTurnPath = scopedMessages.length == 2 && scopedMessages.first.isMine;
    if (isSingleTurnPath) {
      final template = P.preference.promptTemplate.newChatTemplate.trim();
      if (template.isNotEmpty) {
        final templateMessages = template.split("\n\n").where((String entry) => entry.isNotEmpty).toList();
        history.addAll(templateMessages);
      }
    }
    for (int i = 0; i < scopedMessages.length; i = i + 2) {
      final Message userMsg = scopedMessages[i];
      final Message? botMsg = i + 1 < scopedMessages.length ? scopedMessages[i + 1] : null;

      final String userContent = userMsg.getContentForHistoryWithRef(botMsg?.reference);
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
    final backendParams = P.rwkvParams.backendBatchParams.q;
    if (backendParams.isNotEmpty) return backendParams.rawDecodeParams;

    final frontendParams = P.rwkvParams.frontendBatchParams.q;
    if (frontendParams.isNotEmpty) return frontendParams.rawDecodeParams;

    final currentParam = SamplerAndPenaltyParam(
      temperature: P.rwkvParams.arguments(Argument.temperature).q,
      topP: P.rwkvParams.arguments(Argument.topP).q,
      presencePenalty: P.rwkvParams.arguments(Argument.presencePenalty).q,
      frequencyPenalty: P.rwkvParams.arguments(Argument.frequencyPenalty).q,
      penaltyDecay: P.rwkvParams.arguments(Argument.penaltyDecay).q,
    );
    return <SamplerAndPenaltyParam>[currentParam].rawDecodeParams;
  }
}
