part of 'p.dart';

extension $ChatGenerationCompletion on _Chat {
  void _fullyReceived({String? callingFunction}) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator || pageKey == .ocr || pageKey == .benchmark || pageKey == .completion) return;
    qqq("callingFunction: $callingFunction");
    _liveTokenCountThrottler.cancel();

    final id = receiveId.q;

    if (id == null) {
      qqw("receiveId is null");
      return;
    }

    if (id == Config.chatPrefillId) return;

    final currentMessage = P.msg.pool.q[id];
    if (currentMessage == null) {
      qqe("message not found when fully received: $id");
      return;
    }

    if (!currentMessage.changing) {
      qqq("skip fullyReceived for non-changing message: $id");
      return;
    }

    final receivedTokens = this.receivedTokens.q;
    final (double? snapshotPrefillSpeed, double? snapshotDecodeSpeed) = _currentSpeedSnapshotForStore();
    final finalPrefillSpeed = snapshotPrefillSpeed ?? currentMessage.prefillSpeed;
    final finalDecodeSpeed = snapshotDecodeSpeed ?? currentMessage.decodeSpeed;
    // 在 _prefillAfterReply 之前快照 peak，否则新推理会 resetPeakDecodeSpeed
    final double snapshotPeak = P.telemetry._peakDecodeSpeed.q;

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

    _prefillAfterReply();

    unawaited(
      P.telemetry.maybeReport(
        prefillSpeed: finalPrefillSpeed,
        decodeSpeed: finalDecodeSpeed,
        snapshotPeakDecodeSpeed: snapshotPeak,
      ),
    );
  }

  static final _thinkTagRegex = RegExp(r'<think>[\s\S]*?</think>');

  void _prefillAfterReply() {
    final pageKey = P.app.pageKey.q;
    if (pageKey != .chat) return;
    if (P.albatrossRuntime.enabled.q) return;
    if (P.rwkvContext.isLegacyAlbatrossLoaded.q) return;

    final messages = P.msg.list.q.where((msg) => msg.type == MessageType.text).toList();
    if (messages.isEmpty) return;
    if (messages.length % 2 != 0) return;

    final history = <String>[];
    for (int i = 0; i < messages.length; i += 2) {
      final userMsg = messages[i];
      final botMsg = i + 1 < messages.length ? messages[i + 1] : null;

      history.add(userMsg.getContentForHistoryWithRef(botMsg?.reference));

      if (botMsg != null) {
        final content = botMsg.content.replaceAll(_thinkTagRegex, '').trim();
        history.add(content);
      }
    }

    receiveId.q = Config.chatPrefillId;
    P.rwkvGeneration.sendMessages(history, maxLength: 0);
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

    if (id == Config.chatPrefillId) {
      qqw("chat prefill id: $id");
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
    final currentPrefillSpeed = P.rwkvGeneration.prefillSpeed.q;
    final currentDecodeSpeed = P.rwkvGeneration.decodeSpeed.q;
    final snapshotPrefillSpeed = currentPrefillSpeed > 0 ? currentPrefillSpeed : null;
    final snapshotDecodeSpeed = currentDecodeSpeed > 0 ? currentDecodeSpeed : null;
    return (snapshotPrefillSpeed, snapshotDecodeSpeed);
  }
}
