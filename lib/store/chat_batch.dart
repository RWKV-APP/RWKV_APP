part of 'p.dart';

extension $ChatBatch on _Chat {
  void updateBatchViewportSlotIndexes({
    required int messageId,
    required Set<int> indexes,
  }) {
    final current = batchViewportSlotIndexes.q;
    if (current != null && current.messageId == messageId && _sameIntSet(current.indexes, indexes)) return;
    batchViewportSlotIndexes.q = (
      messageId: messageId,
      indexes: Set<int>.unmodifiable(indexes),
    );
  }

  void clearBatchViewportSlotIndexes({required int messageId}) {
    final current = batchViewportSlotIndexes.q;
    if (current == null) return;
    if (current.messageId != messageId) return;
    batchViewportSlotIndexes.q = null;
  }

  bool _sameIntSet(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  void onBatchSlotSelected({
    required Message msg,
    required int slotIndex,
    String? slotContent,
  }) {
    P.msg.batchSelection(msg).q = slotIndex;
    unawaited(
      P.conversation.updateCurrentConvSubtitleFromMessage(
        msg,
        selectedBatch: slotIndex,
        contentOverride: slotContent,
      ),
    );
  }

  Future<void> onBatchInferenceSwitchChanged(
    bool value, {
    bool triggeredByResponseStyle = false,
  }) async {
    if (!triggeredByResponseStyle) {
      P.app.hapticLight();
      if (responseStyle.q.activeCount > 1) {
        resetResponseStyle();
        return;
      }
    }

    if (value && !_canUseBatchInferenceNow()) {
      batchEnabled.q = false;
      batchCount.q = Argument.batchCount.defaults.toInt();
      if (triggeredByResponseStyle && responseStyle.q.activeCount > 1) {
        responseStyle.q = const ResponseStyleState();
      }
      if (!triggeredByResponseStyle) {
        Alert.info(S.current.this_model_does_not_support_batch_inference);
      }
      return;
    }

    batchEnabled.q = value;
    if (!value) {
      batchCount.q = Argument.batchCount.defaults.toInt();
      return;
    }

    final currentParam = P.rwkvParams.currentSamplerAndPenaltyParam();
    final batchParam = currentParam.decodeParamType == DecodeParamType.fixed
        ? SamplerAndPenaltyParam.fromDecodeParamType(DecodeParamType.conservative)
        : currentParam;

    final newValue = List<SamplerAndPenaltyParam>.generate(
      100,
      (index) => SamplerAndPenaltyParam(
        temperature: batchParam.temperature,
        topP: batchParam.topP,
        presencePenalty: batchParam.presencePenalty,
        frequencyPenalty: batchParam.frequencyPenalty,
        penaltyDecay: batchParam.penaltyDecay,
      ),
    );

    P.rwkvParams.frontendBatchParams.q = newValue;
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    P.rwkvBridge.send(
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
    final currentBatchCount = batchCount.q;
    P.rwkvBridge.send(to_rwkv.GetSamplerAndPenaltyParams(batchSize: currentBatchCount, modelID: modelID));
  }

  void onManualBatchCountChanged(int value) {
    if (batchCount.q == value) {
      return;
    }
    batchCount.q = value;
    if (responseStyle.q.activeCount > 1 && value != responseStyle.q.activeCount) {
      resetResponseStyle();
    }
  }

  int _runtimeMaxSupportedBatchCount() {
    final supportedBatchSizes = P.rwkvParams.supportedBatchSizes.q;
    if (supportedBatchSizes.isEmpty) return 0;
    return math.max(1, supportedBatchSizes.max);
  }

  int _normalizeExpectedBatchCount(int value, {required int runtimeMaxBatchCount}) {
    if (value <= 1) return 1;
    if (runtimeMaxBatchCount > 1 && value > runtimeMaxBatchCount) return 0;
    return value;
  }

  int _resolveExpectedBatchResponseCount({
    required Message? message,
    required from_rwkv.ResponseBatchBufferContent response,
    required int runtimeMaxBatchCount,
  }) {
    final labels = message?.batchSlotLabels;
    final labelCount = _normalizeExpectedBatchCount(labels?.length ?? 0, runtimeMaxBatchCount: runtimeMaxBatchCount);
    if (labelCount > 1) return labelCount;

    final decodeParamCount = _normalizeExpectedBatchCount(
      message?.parsedDecodeParams.length ?? 0,
      runtimeMaxBatchCount: runtimeMaxBatchCount,
    );
    if (decodeParamCount > 1) return decodeParamCount;

    final effectiveCount = _normalizeExpectedBatchCount(
      effectiveBatchEnabled.q ? effectiveBatchCount.q : 1,
      runtimeMaxBatchCount: runtimeMaxBatchCount,
    );
    if (effectiveCount > 1) return effectiveCount;

    final responseBatchCount = _normalizeExpectedBatchCount(response.batchSize, runtimeMaxBatchCount: runtimeMaxBatchCount);
    if (responseBatchCount > 1) return responseBatchCount;

    return _normalizeExpectedBatchCount(response.responseBufferContent.length, runtimeMaxBatchCount: runtimeMaxBatchCount);
  }

  String _buildBatchResponseBufferContent(from_rwkv.ResponseBatchBufferContent response) {
    return _buildBatchResponseBufferContentForMessage(response: response, messageId: receiveId.q);
  }

  String _buildBatchResponseBufferContentForMessage({
    required from_rwkv.ResponseBatchBufferContent response,
    required int? messageId,
  }) {
    final message = messageId == null ? null : P.msg.pool.q[messageId];
    final runtimeMaxBatchCount = _runtimeMaxSupportedBatchCount();
    final expectedBatchCount = _resolveExpectedBatchResponseCount(
      message: message,
      response: response,
      runtimeMaxBatchCount: runtimeMaxBatchCount,
    );
    final normalized = normalizeBatchResponseBufferContent(
      responseBufferContent: response.responseBufferContent,
      expectedBatchCount: expectedBatchCount,
      maxBatchSlotCount: runtimeMaxBatchCount,
    );
    return buildBatchContent(normalized);
  }

  void _onBatchCountChanged(int value) async {
    if (responseStyle.q.activeCount > 1 && value != responseStyle.q.activeCount) {
      resetResponseStyle();
    }

    late final List<SamplerAndPenaltyParam> newFrontendBatchParams;
    newFrontendBatchParams = [
      ...P.rwkvParams.frontendBatchParams.q,
      P.rwkvParams.frontendBatchParams.q.last,
    ];

    P.rwkvParams.frontendBatchParams.q = newFrontendBatchParams;
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    P.rwkvBridge.send(
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
    P.rwkvBridge.send(to_rwkv.GetSamplerAndPenaltyParams(batchSize: value, modelID: modelID));
  }

  void _onSupportedBatchSizesChanged(List<int> supportedBatchSizes) {
    if (P.albatrossRuntime.canUse.q || P.rwkvContext.isLegacyAlbatrossLoaded.q) {
      if (supportedBatchSizes.isEmpty) {
        batchEnabled.q = false;
        batchCount.q = Argument.batchCount.defaults.toInt();
        if (responseStyle.q.activeCount > 1) {
          responseStyle.q = const ResponseStyleState();
        }
        return;
      }
      final max = supportedBatchSizes.max;
      if (responseStyle.q.activeCount > 1 && max < responseStyle.q.activeCount) {
        resetResponseStyle();
        return;
      }
      if (max < batchCount.q) batchCount.q = max;
      return;
    }

    final currentModel = P.rwkvModel.latest.q;
    if (currentModel != null && !currentModel.supportsBatchInference) {
      batchEnabled.q = false;
      batchCount.q = Argument.batchCount.defaults.toInt();
      if (responseStyle.q.activeCount > 1) {
        responseStyle.q = const ResponseStyleState();
      }
      return;
    }

    if (supportedBatchSizes.isEmpty) {
      batchEnabled.q = false;
      batchCount.q = Argument.batchCount.defaults.toInt();
      if (responseStyle.q.activeCount > 1) {
        responseStyle.q = const ResponseStyleState();
      }
      return;
    }
    final max = supportedBatchSizes.max;
    if (responseStyle.q.activeCount > 1 && max < responseStyle.q.activeCount) {
      resetResponseStyle();
      return;
    }
    if (max < batchCount.q) batchCount.q = max;
  }
}
