part of 'p.dart';

class _RWKVGeneration {
  /// 正在预填充或者正在生成
  late final generating = qs(false);

  /// 当前正在预填充或者生成的请求 ID
  late final generatingId = qs<int?>(null);

  /// 是否隐藏预填充, 用于在 see 模式下, 隐藏预填充的进度条, 如果 max length 为 0, 则隐藏预填充的进度条
  ///
  /// 如果隐藏预填充状态, 则, 我们会渲染可交互的发送按钮
  late final hiddenPrefilling = qs(false);

  late final prefillSpeed = qs<double>(.0);
  late final decodeSpeed = qs<double>(.0);
  late final prefillProgress = qs<double>(.0);

  Timer? _getTokensTimer;
}

extension $RWKVGeneration on _RWKVGeneration {
  Future<void> setAudioPrompt({required String path}) async {
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .tts);
    if (modelID == null) {
      return;
    }
    P.rwkvBridge.send(to_rwkv.SetAudioPrompt(path, modelID: modelID));
  }

  Future<void> sendMessages(
    List<String> messages, {
    double getIsGeneratingRate = .5,
    double getResponseBufferContentRate = .5,
    int batchSize = 1,
    int? maxLength,
    bool forceChinese = false,
    int? forceLang,
    List<List<String>>? overrideBatchMessages,
    List<to_rwkv.ChatBatchSlotConfig>? overrideBatchSlotConfigs,
  }) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    P.telemetry.resetPeakDecodeSpeed();

    if (P.rwkvContext.isAlbatrossLoaded.q) {
      final stream = Albatross.instance.chat(messages, batchSize: 1);
      try {
        await for (final event in stream) {
          P.rwkvBridge.emitFromRWKV(event);
        }

        /// NOTE: downstream requires this delay
        unawaited(_emitGenerateStopLater());
      } catch (e) {
        unawaited(_emitGenerateStopLater(error: e.toString()));
      } finally {
        P.rwkvBridge.emitOldEvent(const LLMEvent(type: _RWKVMessageType.isGenerating, content: 'false'));
      }
      return;
    }

    final WeightType weightType = switch (P.app.demoType.q) {
      .chat => .chat,
      .see => .see,
      .tts => .tts,
      .sudoku => .sudoku,
      .othello => .othello,
      // TODO: Handle this case.
      .fifthteenPuzzle => throw UnimplementedError(),
    };

    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: weightType);
    if (modelID == null) {
      qqe("modelID is null");
      return;
    }

    final thinkingMode = P.rwkvParams.thinkingMode.q;

    final reasoning = thinkingMode.hasThinkTag;
    final forceReasoning = thinkingMode.forceReasoning;
    final hasOverrideBatchSlotConfigs = overrideBatchSlotConfigs != null && overrideBatchSlotConfigs.isNotEmpty;
    final int effectiveBatchSize = hasOverrideBatchSlotConfigs ? overrideBatchSlotConfigs.length : batchSize;
    final isBatchInference = effectiveBatchSize > 1;
    final addGenerationPrompt = messages.length.isOdd;
    final resolvedForceLang = forceLang ?? (forceChinese ? FORCE_LANG_CHN : null);

    final to_rwkv.ToRWKV request;
    if (hasOverrideBatchSlotConfigs) {
      request = to_rwkv.ChatBatchAsync.withSlotConfigs(
        overrideBatchSlotConfigs,
        modelID: modelID,
        maxLength: maxLength,
        forceLang: resolvedForceLang,
      );
    } else if (isBatchInference) {
      final List<List<String>> batchMessages;
      if (overrideBatchMessages != null) {
        batchMessages = overrideBatchMessages;
      } else {
        batchMessages = <List<String>>[];
        for (int i = 0; i < effectiveBatchSize; i++) {
          batchMessages.add(messages);
        }
      }
      request = to_rwkv.ChatBatchAsync(
        batchMessages,
        enableReasoning: reasoning,
        forceReasoning: forceReasoning,
        addGenerationPrompt: addGenerationPrompt,
        batchSize: effectiveBatchSize,
        modelID: modelID,
        maxLength: maxLength,
        forceLang: resolvedForceLang,
      );
    } else {
      request = to_rwkv.ChatAsync(
        messages,
        enableReasoning: reasoning,
        forceReasoning: forceReasoning,
        addGenerationPrompt: addGenerationPrompt,
        modelID: modelID,
        maxLength: maxLength,
        forceLang: resolvedForceLang,
      );
    }
    P.rwkvBridge.send(request);

    generatingId.q = request.requestId;
    hiddenPrefilling.q = maxLength == 0;

    _cancelTokensTimer();

    final ms = 47 * sqrt(effectiveBatchSize.toDouble());

    _getTokensTimer = Timer.periodic(Duration(milliseconds: ms.toInt()), (_) {
      final getResponseCalling = isBatchInference
          ? to_rwkv.GetBatchResponseBufferContent(messages: messages, modelID: modelID) //
          : to_rwkv.GetResponseBufferContent(messages: messages, modelID: modelID);
      P.rwkvBridge.send(getResponseCalling);
      if (HF.randomBool(truePercentage: getIsGeneratingRate)) P.rwkvBridge.send(to_rwkv.GetIsGenerating(modelID: modelID));
      if (HF.randomBool(truePercentage: getResponseBufferContentRate)) {
        P.rwkvBridge.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
      }
    });
  }

  Stream<from_rwkv.ResponseBatchBufferContent> completion(
    String prompt, {
    int batchSize = 1,
    int? maxLength,
    int? stopToken,
    bool? disableCache,
  }) {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    prefillProgress.q = 0;
    P.telemetry.resetPeakDecodeSpeed();

    if (P.rwkvContext.isAlbatrossLoaded.q) {
      return Albatross.instance.completion(prompt, batchSize: batchSize);
    }

    final sendPort = P.rwkvBridge.sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return const Stream.empty();
    }

    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return const Stream.empty();
    }

    final request = to_rwkv.GenerateAsync(
      prompt,
      batch: batchSize,
      modelID: modelID,
      maxLength: maxLength,
      stopToken: stopToken,
      disableCache: disableCache,
    );
    P.rwkvBridge.send(request);
    _cancelTokensTimer();

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final getResponseCalling = batchSize > 1
          ? to_rwkv.GetBatchResponseBufferContent(messages: [], modelID: modelID) //
          : to_rwkv.GetResponseBufferContent(messages: [], modelID: modelID);
      P.rwkvBridge.send(getResponseCalling);
      if (HF.randomBool(truePercentage: .5)) P.rwkvBridge.send(to_rwkv.GetIsGenerating(modelID: modelID));
      if (HF.randomBool(truePercentage: .5)) P.rwkvBridge.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    });
    return P.rwkvBridge.broadcastStream.mapNotNull((e) {
      if (e is from_rwkv.ResponseBatchBufferContent) {
        return e;
      } else if (e is from_rwkv.ResponseBufferContent) {
        return from_rwkv.ResponseBatchBufferContent(
          responseBufferContent: [e.responseBufferContent],
          eosFound: [e.eosFound],
          batchSize: batchSize,
        );
      }
      return null;
    });
  }

  /// 直接在 ffi+cpp 线程中进行推理工作, 也就是说, 会让 ffi 线程不接受任何新的 event
  Future<void> generate(String prompt) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    final sendPort = P.rwkvBridge.sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }

    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: .othello);
    if (modelID == null) {
      return;
    }

    P.rwkvBridge.send(to_rwkv.SudokuOthelloGenerate(prompt, modelID: modelID));

    _cancelTokensTimer();

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      P.rwkvBridge.send(to_rwkv.GetResponseBufferIds(modelID: modelID));
      P.rwkvBridge.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
      P.rwkvBridge.send(to_rwkv.GetResponseBufferContent(messages: [], modelID: modelID));
      await 1000.msLater;
      P.rwkvBridge.send(to_rwkv.GetIsGenerating(modelID: modelID));
    });
  }

  Future<void> clearStates() async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    prefillProgress.q = 0;
    final sendPort = P.rwkvBridge.sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }
    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      P.rwkvBridge.send(to_rwkv.ClearStates(modelID: modelID));
    }
  }

  Future<int?> calculateTokensCountRaw({
    required String text,
    WeightType? preferredWeightType,
  }) async {
    if (text.isEmpty) return 0;
    if (P.rwkvBridge.sendPort == null) return null;
    final weightType = _resolveWeightTypeForTokenCount(preferredWeightType: preferredWeightType);
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: weightType);
    if (modelID == null) return null;

    final request = to_rwkv.CalculateTokensCountRaw(text, modelID: modelID);
    P.rwkvBridge.send(request);

    try {
      final response = await P.rwkvBridge.broadcastStream
          .whereType<from_rwkv.TokensCount>()
          .where((from_rwkv.TokensCount event) => event.req?.requestId == request.requestId)
          .first
          .timeout(const Duration(seconds: 3));
      return response.tokensCount;
    } catch (_) {
      return null;
    }
  }

  Future<int?> calculateTokensCountFromMessages({
    required List<String> messages,
    WeightType? preferredWeightType,
  }) async {
    if (messages.isEmpty) return 0;
    if (P.rwkvBridge.sendPort == null) return null;
    final weightType = _resolveWeightTypeForTokenCount(preferredWeightType: preferredWeightType);
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: weightType);
    if (modelID == null) return null;

    final request = to_rwkv.CalculateTokensCountFromMessages(messages, modelID: modelID);
    P.rwkvBridge.send(request);

    try {
      final response = await P.rwkvBridge.broadcastStream
          .whereType<from_rwkv.TokensCount>()
          .where((from_rwkv.TokensCount event) => event.req?.requestId == request.requestId)
          .first
          .timeout(const Duration(seconds: 3));
      return response.tokensCount;
    } catch (_) {
      return null;
    }
  }

  void requestGenerationMetrics({WeightType weightType = .chat}) {
    final modelID = P.rwkvModel.findModelIDByWeightType(weightType: weightType);
    if (modelID == null) return;
    P.rwkvBridge.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    P.rwkvBridge.send(to_rwkv.GetIsGenerating(modelID: modelID));
  }

  Future<void> stop() async {
    if (P.rwkvContext.isAlbatrossLoaded.q) return Albatross.instance.stop();
    for (final entry in P.rwkvModel.allLoaded.q.entries) {
      final modelID = entry.value;
      P.rwkvBridge.send(to_rwkv.Stop(modelID: modelID));
    }
  }

  void _cancelTokensTimer() {
    _getTokensTimer?.cancel();
    _getTokensTimer = null;
  }

  void _onGeneratingChanged(bool generating) async {
    P.app.setKeepScreenAwakeForReason(reason: .generation, enabled: generating);
    if (generatingId.q == null) return;
    if (!generating) generatingId.q = null;
  }

  Future<void> _emitGenerateStopLater({String? error}) async {
    await 500.msLater;
    P.rwkvBridge.emitFromRWKV(from_rwkv.GenerateStop(error: error));
  }

  WeightType _resolveWeightTypeForTokenCount({
    WeightType? preferredWeightType,
  }) {
    if (preferredWeightType != null) {
      return preferredWeightType;
    }
    final demoType = P.app.demoType.q;
    return switch (demoType) {
      .see => .see,
      .tts => .tts,
      .sudoku => .sudoku,
      .othello => .othello,
      .chat => .chat,
      .fifthteenPuzzle => .chat,
    };
  }
}
