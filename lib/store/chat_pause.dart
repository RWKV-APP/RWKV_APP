part of 'p.dart';

const Duration _pauseStopSignalTimeout = Duration(seconds: 3);
const Duration _pauseFinalBufferTimeout = Duration(seconds: 2);

class _PausedGenerationSnapshot {
  final int messageId;
  final int? modelID;
  final bool isSensitive;
  final String lastContent;
  final double? prefillSpeed;
  final double? decodeSpeed;
  final double peakDecodeSpeed;
  final bool isBatchInference;
  final bool isResponseStyleSequential;
  final List<String> responseStyleCompletedOutputs;
  final int responseStyleTotalCount;

  const _PausedGenerationSnapshot({
    required this.messageId,
    required this.modelID,
    required this.isSensitive,
    required this.lastContent,
    required this.prefillSpeed,
    required this.decodeSpeed,
    required this.peakDecodeSpeed,
    required this.isBatchInference,
    required this.isResponseStyleSequential,
    required this.responseStyleCompletedOutputs,
    required this.responseStyleTotalCount,
  });
}

extension $ChatPause on _Chat {
  Future<void> onStopButtonPressed({bool wantHaptic = true}) async {
    qqq("receiveId: ${receiveId.q}");
    if (wantHaptic) P.app.hapticLight();
    await 1.msLater;
    final id = receiveId.q;
    if (id == null) {
      qqw("message id is null");
      return;
    }
    if (!P.rwkvGeneration.generating.q) {
      return;
    }
    if (P.webDemo.active.q) {
      await P.webDemo.stopActive();
    }
    _pauseMessageById(id: id);
  }

  Future<void> resumeMessageById({required int id, bool withHaptic = true}) async {
    qq;
    if (withHaptic) P.app.hapticLight();
    _clearResponseStyleSequentialState();
    receiveId.q = id;
    final currentMessage = P.msg.pool.q[id];
    if (currentMessage != null && currentMessage.content.isNotEmpty) {
      _setReceivedTokens(currentMessage.content, immediateUi: true);
    }
    _updateMessageById(
      id: id,
      changing: true,
      paused: false,
      callingFunction: "resumeMessageById",
    );
    _liveTokenCountThrottler.cancel();
    final bool resumedSequentially = await _resumeResponseStyleSequentialMessage(messageId: id);
    if (resumedSequentially) {
      return;
    }
    final responseStyleResumeRequest = _buildResponseStyleResumeRequest(messageId: id);
    if (responseStyleResumeRequest != null) {
      if (responseStyleResumeRequest.slotConfigs != null) {
        await _setFastThinkingModeForResponseStyleBatch();
      }
      P.rwkvGeneration.sendMessages(
        responseStyleResumeRequest.messages,
        batchSize: responseStyleResumeRequest.slotConfigs == null && effectiveBatchEnabled.q ? effectiveBatchCount.q : 1,
        overrideBatchSlotConfigs: responseStyleResumeRequest.slotConfigs,
        forceLang: responseStyleResumeRequest.forceLang,
      );
      _scheduleRefreshLiveTokenCounts(messageId: id, liveBotContent: receivedTokens.q);
      return;
    }
    final batchResumeRequest = _buildBatchResumeRequest(messageId: id);
    if (batchResumeRequest != null) {
      P.rwkvGeneration.sendMessages(
        batchResumeRequest.messages,
        batchSize: batchResumeRequest.batchMessages.length,
        overrideBatchMessages: batchResumeRequest.batchMessages,
      );
      _scheduleRefreshLiveTokenCounts(messageId: id, liveBotContent: receivedTokens.q);
      return;
    }
    P.rwkvGeneration.sendMessages(_history(), batchSize: effectiveBatchEnabled.q ? effectiveBatchCount.q : 1);
    _scheduleRefreshLiveTokenCounts(messageId: id, liveBotContent: receivedTokens.q);
  }

  Future<void> _pauseMessageById({required int id, bool isSensitive = false}) async {
    qq;

    if (_pauseFinalizingMessageId == id) {
      qqw("message is finalizing pause");
      return;
    }

    final msg = P.msg.pool.q[id];
    if (msg == null) {
      qqw("message not found");
      return;
    }

    if (msg.paused) {
      qqw("message already paused");
      return;
    }

    final pausedMarkdownRepro = await _pauseMarkdownFlickerReproMessage(
      id: id,
      msg: msg,
      isSensitive: isSensitive,
    );
    if (pausedMarkdownRepro) {
      return;
    }

    final pausedFakeBenchmark = await _pauseFakeBatchInferenceBenchmarkMessage(
      id: id,
      msg: msg,
      isSensitive: isSensitive,
    );
    if (pausedFakeBenchmark) {
      return;
    }

    final (double? snapshotPrefillSpeed, double? snapshotDecodeSpeed) = _currentSpeedSnapshotForStore();
    final finalPrefillSpeed = snapshotPrefillSpeed ?? msg.prefillSpeed;
    final finalDecodeSpeed = snapshotDecodeSpeed ?? msg.decodeSpeed;
    final double snapshotPeak = P.telemetry._peakDecodeSpeed.q;
    final currentGeneratedContent = id == receiveId.q ? receivedTokens.q : msg.content;
    final lastContent = currentGeneratedContent.isNotEmpty ? currentGeneratedContent : msg.content;
    final isResponseStyleSequential = _responseStyleSequentialActive && _responseStyleSequentialMessageId == id;
    final modelID = _resolvePauseModelID();
    final snapshot = _PausedGenerationSnapshot(
      messageId: id,
      modelID: modelID,
      isSensitive: isSensitive,
      lastContent: lastContent,
      prefillSpeed: finalPrefillSpeed,
      decodeSpeed: finalDecodeSpeed,
      peakDecodeSpeed: snapshotPeak,
      isBatchInference: !isResponseStyleSequential && _shouldReadBatchPauseBuffer(message: msg, content: lastContent),
      isResponseStyleSequential: isResponseStyleSequential,
      responseStyleCompletedOutputs: isResponseStyleSequential ? <String>[..._responseStyleSequentialCompletedOutputs] : const <String>[],
      responseStyleTotalCount: isResponseStyleSequential ? _responseStyleSequentialRoutes.length : 0,
    );

    _pauseFinalizingMessageId = id;
    _liveTokenCountThrottler.cancel();
    if (isResponseStyleSequential) {
      _responseStyleSequentialStopRequested = true;
    }
    unawaited(_stopAndFinalizePausedMessage(snapshot));
  }

  bool _shouldReadBatchPauseBuffer({
    required Message message,
    required String content,
  }) {
    final labelCount = message.batchSlotLabels?.length ?? 0;
    if (labelCount > 1) return true;
    if (message.parsedDecodeParams.length > 1) return true;
    if (effectiveBatchEnabled.q && effectiveBatchCount.q > 1) return true;
    return getIsBatch(content);
  }

  Future<void> _stopAndFinalizePausedMessage(_PausedGenerationSnapshot snapshot) async {
    try {
      final stopSignal = _waitForPauseStopSignal(snapshot);
      await P.rwkvGeneration.stop();
      await stopSignal;

      P.rwkvGeneration._cancelTokensTimer();
      P.rwkvGeneration.generating.q = false;

      final finalContent = await _readPausedFinalContent(snapshot);
      await _finalizePausedMessage(snapshot, finalContent);
    } catch (e, stackTrace) {
      qqe("pause finalize failed: $e");
      P.rwkvGeneration.generating.q = false;
      if (!kDebugMode) {
        Sentry.captureException(e, stackTrace: stackTrace);
      }
    } finally {
      if (_pauseFinalizingMessageId == snapshot.messageId) {
        _pauseFinalizingMessageId = null;
      }
    }
  }

  Future<void> _waitForPauseStopSignal(_PausedGenerationSnapshot snapshot) async {
    try {
      await _waitForPauseStopSignalStrict(snapshot);
    } catch (_) {
      qqw("pause stop signal timed out");
    }
  }

  Future<void> _waitForPauseStopSignalStrict(_PausedGenerationSnapshot snapshot) async {
    if (!P.rwkvGeneration.generating.q) return;
    await P.rwkvBridge.broadcastStream
        .where((from_rwkv.FromRWKV event) {
          if (event is from_rwkv.GenerateStop) return _pauseStopMatchesSnapshot(event, snapshot);
          if (event is from_rwkv.IsGenerating) return !event.isGenerating && _pauseIsGeneratingMatchesSnapshot(event, snapshot);
          return false;
        })
        .first
        .timeout(_pauseStopSignalTimeout);
  }

  bool _pauseStopMatchesSnapshot(from_rwkv.GenerateStop event, _PausedGenerationSnapshot snapshot) {
    final modelID = snapshot.modelID;
    if (modelID == null) return true;
    final req = event.req;
    if (req is! to_rwkv.Stop) return true;
    return req.modelID == modelID;
  }

  bool _pauseIsGeneratingMatchesSnapshot(from_rwkv.IsGenerating event, _PausedGenerationSnapshot snapshot) {
    final modelID = snapshot.modelID;
    if (modelID == null) return true;
    return event.modelID == modelID;
  }

  Future<String> _readPausedFinalContent(_PausedGenerationSnapshot snapshot) async {
    try {
      final finalContent =
          snapshot
              .isBatchInference //
          ? await _requestPausedFinalBatchContent(snapshot)
          : await _requestPausedFinalSingleContent(snapshot);
      if (finalContent.isNotEmpty) return finalContent;
    } catch (_) {
      qqw("pause final buffer read failed");
    }
    return _latestPausedContent(snapshot);
  }

  Future<String> _requestPausedFinalSingleContent(_PausedGenerationSnapshot snapshot) async {
    final modelID = snapshot.modelID;
    if (modelID == null) return "";

    final request = to_rwkv.GetResponseBufferContent(messages: const <String>[], modelID: modelID);
    final responseFuture = P.rwkvBridge.broadcastStream
        .whereType<from_rwkv.ResponseBufferContent>()
        .where((from_rwkv.ResponseBufferContent event) => event.req?.requestId == request.requestId)
        .first
        .timeout(_pauseFinalBufferTimeout);
    P.rwkvBridge.send(request);
    final response = await responseFuture;
    final content = response.responseBufferContent;

    if (!snapshot.isResponseStyleSequential) return content;
    if (snapshot.responseStyleTotalCount <= 0) return content;
    return _buildResponseStyleSequentialBatchContent(
      completedOutputs: snapshot.responseStyleCompletedOutputs,
      currentOutput: content,
      totalCount: snapshot.responseStyleTotalCount,
    );
  }

  Future<String> _requestPausedFinalBatchContent(_PausedGenerationSnapshot snapshot) async {
    final modelID = snapshot.modelID;
    if (modelID == null) return "";

    final request = to_rwkv.GetBatchResponseBufferContent(messages: const <String>[], modelID: modelID);
    final responseFuture = P.rwkvBridge.broadcastStream
        .whereType<from_rwkv.ResponseBatchBufferContent>()
        .where((from_rwkv.ResponseBatchBufferContent event) => event.req?.requestId == request.requestId)
        .first
        .timeout(_pauseFinalBufferTimeout);
    P.rwkvBridge.send(request);
    final response = await responseFuture;
    return _buildBatchResponseBufferContentForMessage(response: response, messageId: snapshot.messageId);
  }

  int? _resolvePauseModelID() {
    final WeightType weightType = switch (P.app.demoType.q) {
      .see => .see,
      .tts => .tts,
      .sudoku => .sudoku,
      .othello => .othello,
      .chat => .chat,
      .fifthteenPuzzle => .chat,
    };
    return P.rwkvModel.findModelIDByWeightType(weightType: weightType);
  }

  String _latestPausedContent(_PausedGenerationSnapshot snapshot) {
    if (receiveId.q != snapshot.messageId) return snapshot.lastContent;
    final currentReceivedTokens = receivedTokens.q;
    if (currentReceivedTokens.isNotEmpty) return currentReceivedTokens;
    final currentVisibleReceivedTokens = visibleReceivedTokens.q;
    if (currentVisibleReceivedTokens.isNotEmpty) return currentVisibleReceivedTokens;
    return snapshot.lastContent;
  }

  Future<void> _finalizePausedMessage(_PausedGenerationSnapshot snapshot, String content) async {
    final msg = P.msg.pool.q[snapshot.messageId];
    if (msg == null) {
      qqw("message not found");
      return;
    }

    final finalizedContent = content.isNotEmpty ? content : msg.content;
    final newMsg = msg.copyWith(
      content: finalizedContent,
      paused: true,
      changing: false,
      isSensitive: snapshot.isSensitive,
      prefillSpeed: snapshot.prefillSpeed,
      decodeSpeed: snapshot.decodeSpeed,
    );
    await P.msg._syncMsg(snapshot.messageId, newMsg);
    if (snapshot.isResponseStyleSequential) {
      _clearResponseStyleSequentialState();
    }
    _setReceivedTokens("", immediateUi: true);
    unawaited(
      _refreshTokenCountsForMessage(
        messageId: snapshot.messageId,
        overrideBotContent: finalizedContent,
        persistToMessage: true,
      ),
    );

    unawaited(
      P.telemetry.maybeReport(
        prefillSpeed: snapshot.prefillSpeed,
        decodeSpeed: snapshot.decodeSpeed,
        snapshotPeakDecodeSpeed: snapshot.peakDecodeSpeed,
      ),
    );
  }
}
