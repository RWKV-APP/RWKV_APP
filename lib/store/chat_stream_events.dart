part of 'p.dart';

extension $ChatStreamEvents on _Chat {
  void _onOldStreamEvent(LLMEvent event) {
    if (P.askQuestion.interceptingEvents.q) return;

    switch (event.type) {
      case _RWKVMessageType.isGenerating:
        final isGenerating = event.content == "true";
        P.rwkvGeneration.generating.q = isGenerating;
        if (!isGenerating && _pauseFinalizingMessageId != null) break;
        if (!isGenerating && !completionMode.q) _fullyReceived(callingFunction: "_onStreamEvent:isGenerating");
        break;

      case _RWKVMessageType.streamResponse:
        _setReceivedTokens(event.content);
        P.rwkvGeneration.generating.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamEvent(from_rwkv.FromRWKV event) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    if (P.askQuestion.interceptingEvents.q) return;
    if (_handleResponseStyleSequentialEvent(event)) return;

    switch (event) {
      case from_rwkv.ResponseBufferContent res:
        _setReceivedTokens(res.responseBufferContent);
        if (completionMode.q) return;
        final currentReceiveId = receiveId.q;
        if (currentReceiveId != null && _shouldCheckSensitiveForReceiveId(currentReceiveId)) {
          _scheduleRefreshLiveTokenCounts(
            messageId: currentReceiveId,
            liveBotContent: res.responseBufferContent,
          );
          _sensitiveThrottler.call(() {
            _checkSensitive(res.responseBufferContent);
          });
        }
        break;

      case from_rwkv.ResponseBatchBufferContent res:
        final responseBufferContent = _buildBatchResponseBufferContent(res);
        _setReceivedTokens(responseBufferContent);
        if (completionMode.q) return;
        final currentReceiveId = receiveId.q;
        if (currentReceiveId != null && _shouldCheckSensitiveForReceiveId(currentReceiveId)) {
          _scheduleRefreshLiveTokenCounts(
            messageId: currentReceiveId,
            liveBotContent: responseBufferContent,
          );
          _sensitiveThrottler.call(() {
            _checkSensitive(responseBufferContent);
          });
        }
        break;

      case from_rwkv.GenerateStop _:
        if (_pauseFinalizingMessageId == null) {
          _setReceivedTokens("", immediateUi: true);
        }
        P.rwkvGeneration.generating.q = false;
        break;

      case from_rwkv.GenerateStart _:
        _setReceivedTokens("", immediateUi: true);
        P.rwkvGeneration.generating.q = true;
        break;

      default:
        break;
    }
  }

  void _onStreamDone() async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    qq;
    _liveTokenCountThrottler.cancel();
    _clearResponseStyleSequentialState();
    final demoType = P.app.demoType.q;
    if (demoType != .chat && demoType != .see) return;
    P.rwkvGeneration.generating.q = false;
  }

  void _onStreamError(Object error, StackTrace stackTrace) async {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .translator) return;
    qqe("error: $error");
    _liveTokenCountThrottler.cancel();
    _clearResponseStyleSequentialState();
    if (!kDebugMode) Sentry.captureException(error, stackTrace: stackTrace);
    final demoType = P.app.demoType.q;
    if (demoType != .chat && demoType != .see) return;
    P.rwkvGeneration.generating.q = false;
  }
}
