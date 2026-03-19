part of 'p.dart';

class _RWKV {
  // ===========================================================================
  // Static
  // ===========================================================================

  @Deprecated("Use _broadcastStream instead")
  static Stream<LLMEvent>? _oldBroadcastStream;

  static Stream<from_rwkv.FromRWKV>? _broadcastStream;

  // ===========================================================================
  // Instance
  // ===========================================================================

  /// We use it to send message to rwkv_mobile_flutter isolate
  ///
  /// This sendPort is created rwkv_mobile_flutter isolate
  SendPort? _sendPort;

  /// Receive message from RWKV isolate
  late final _receivePort = ReceivePort();

  ReceivePort get receivePort => _receivePort;

  @Deprecated("Use _streamController instead")
  late final _oldMessagesController = StreamController<LLMEvent>();

  late final _messagesController = StreamController<from_rwkv.FromRWKV>();

  /// 我们等着这个的主要目的是等着 rwkv_mobile_flutter isolate 把 sendPort 发过来, 我们好用 sendport 来让 rwkv_mobile_flutter isolate 加载模型, 并执行后继操作
  Completer<void>? _createRWKVIsolateCompleter;

  Timer? _getTokensTimer;

  Timer? _ttsPerformanceTimer;

  late final argumentUpdatingDebouncer = Debouncer(milliseconds: 300);

  // ===========================================================================
  // Getters
  // ===========================================================================

  @Deprecated("Use broadcastStream instead")
  Stream<LLMEvent> get oldBroadcastStream {
    _oldBroadcastStream ??= _oldMessagesController.stream.asBroadcastStream();
    return _oldBroadcastStream!;
  }

  Stream<from_rwkv.FromRWKV> get broadcastStream {
    _broadcastStream ??= _messagesController.stream.asBroadcastStream();
    return _broadcastStream!;
  }

  // ===========================================================================
  // StateProvider
  // ===========================================================================

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

  late final argumentsPanelShown = qs(false);
  late final logPanelShown = qs(false);
  late final statePanelShown = qs(false);
  late final renderNewlineDirectly = qs(false);
  late final renderSpaceSymbol = qs(false);
  late final showPrefillLogOnly = qs(true);

  late final _thinkingMode = qs<thinking_mode.ThinkingMode>(.fast);

  /// 已经加载到内存中的模型，key 为 FuncType，value 为模型 ID
  late final loadedModels = qs<Map<FileInfo, int>>({});

  late final usingPth = qp<bool?>((ref) {
    final loadedModels = ref.watch(P.rwkv.loadedModels);

    if (loadedModels.isEmpty) return null;

    if (loadedModels.keys.any((e) => e.fromPthFile)) {
      return true;
    }

    return false;
  });

  /// 模型加载状态, 曾经被加载过的模型, 也会显示在这里
  late final loadingStatus = qs<Map<FileInfo, LoadingStatus>>({});

  // TODO: @wangce 改成 qsff 以便减少不必要的页面刷新
  /// 注意, 后端给的是 0-1 的 double, 且, 在模型加载完成时, progress 不一定为 1.0, 可能是, 0.1, 0.5, 0.999, 但是这不影响我们判断模型是否加载完成
  late final loadingProgress = qs<Map<FileInfo, double>>({});

  /// 模型加载完成器, 用于等待模型加载完成
  late final modelLoadingCompleters = qs<Map<FileInfo, Completer<int?>>>({});

  /// 模型释放完成器, 用于等待模型释放完成
  late final modelReleasingCompleters = qs<Map<int, Completer<bool>>>({});

  /// 模型解压状态, 用于等待模型解压完成
  late final unzippingStatus = qsf<FileInfo, bool>(false);

  late final currentWorldType = qs<WorldType?>(null);

  late final currentGroupInfo = qs<GroupInfo?>(null);

  late final socName = qs("");
  late final socBrand = qs(SocBrand.unknown);

  late final frontendSocName = qs<String?>(null);
  late final frontendSocBrand = qs<SocBrand?>(null);

  late final _qnnLibsCopied = qs(false);

  late final supportedBatchSizes = qs<List<int>>([]);
  late final batchParams = qs<List<DecodeParamType>>([]);
  late final runtimeLog = qs<List<LogItem>>([]);
  late final stateLogList = qs<List<StateLog>>([]);

  late final arguments = qsff<Argument, double>((ref, argument) {
    return argument.defaults;
  });

  late final frontendBatchParams = qs<List<SamplerAndPenaltyParam>>([]);
  late final backendBatchParams = qs<List<SamplerAndPenaltyParam>>([]);
  late final editingBatchParamsIndex = qs<int?>(null);

  late final backendStatus = qs<BackendStatus>(.none);

  late final unzipping = qs(false);

  // ===========================================================================
  // Provider
  // ===========================================================================

  late final loading = qp((ref) {
    final loadingStatus = ref.watch(P.rwkv.loadingStatus);
    return loadingStatus.values.any((e) {
      return e == LoadingStatus.loading || e == LoadingStatus.loadModelWithExtra || e == LoadingStatus.setQnnLibraryPath;
    });
  });

  late final loadedModelsCount = qp((ref) {
    final loadedModels = ref.watch(P.rwkv.loadedModels);
    return loadedModels.length;
  });

  late final latestModel = qp<FileInfo?>((ref) {
    final loadedModels = ref.watch(P.rwkv.loadedModels);
    final m = loadedModels.keys.lastOrNull;
    if (m?.weightType == .roleplay) {
      return null;
    }
    return m;
  });

  late final latestModelId = qp<int?>((ref) {
    final _latestModel = ref.watch(P.rwkv.latestModel);
    final _loadedModels = ref.watch(P.rwkv.loadedModels);
    if (_latestModel == null || _loadedModels.isEmpty) return null;
    return _loadedModels[_latestModel];
  });

  late final frontendBatchParamsAreAllSame = qp((ref) {
    final frontendBatchParams = ref.watch(this.frontendBatchParams);
    if (frontendBatchParams.isEmpty) return false;
    return frontendBatchParams.every((param) => param == frontendBatchParams.first);
  });

  late final syncingBatchParams = qp(_syncingBatchParams);

  bool _syncingBatchParams(Ref<dynamic> ref) {
    final frontendBatchParams = ref.watch(this.frontendBatchParams);
    final backendBatchParams = ref.watch(this.backendBatchParams);
    if (frontendBatchParams.isEmpty || backendBatchParams.isEmpty) return false;
    bool areAllSame = true;
    for (int i = 0; i < backendBatchParams.length; i++) {
      final frontendParam = frontendBatchParams[i];
      final backendParam = backendBatchParams[i];
      final isEqual = frontendParam.tolerantEquals(backendParam);
      if (!isEqual) {
        areAllSame = false;
        break;
      }
    }
    return !areAllSame;
  }

  late final decodeParamType = qp<DecodeParamType>((ref) {
    final temp = ref.watch(arguments(Argument.temperature));
    final topP = ref.watch(arguments(Argument.topP));
    final presencePenalty = ref.watch(arguments(Argument.presencePenalty));
    final frequencyPenalty = ref.watch(arguments(Argument.frequencyPenalty));
    final penaltyDecay = ref.watch(arguments(Argument.penaltyDecay));
    return DecodeParamType.fromValue(
      temperature: temp,
      topP: topP,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      penaltyDecay: penaltyDecay,
    );
  });

  late final reasoning = qp((ref) => ref.watch(_thinkingMode).hasThinkTag);
  late final thinkingMode = qp((ref) => ref.watch(_thinkingMode));

  /// 模型是否已加载
  late final loaded = qp((ref) {
    final currentModel = ref.watch(latestModel);
    return currentModel != null;
  });

  late final isAlbatrossLoaded = qp((ref) {
    final currentModel = ref.watch(latestModel);
    return currentModel?.tags.contains('albatross') ?? false;
  });

  late final enableAlbatross = qs(false);

  /// 当前模型是否是2025年9月22日之前发布的
  ///
  /// 新的权重要使用新的 thinking mode 组
  late final currentModelIsBefore20250922 = qp((ref) {
    final currentModel = ref.watch(latestModel);
    if (currentModel == null) return false;
    final date = currentModel.date;
    return date != null && date.isBefore(DateTime(2025, 9, 22));
  });

  late final inTTSTranslateOrSee = qp((ref) {
    final model = ref.watch(P.rwkv.latestModel);
    if (model == null) return false;
    final isTTS = model.isTTS;
    final isTranslate = model.tags.contains("translate");
    final isWorld = model.fileName.contains("modrwkv") || model.fileName.contains("rwkv-vl");
    return isTTS || isTranslate || isWorld;
  });
}

extension $RWKVLoad on _RWKV {
  Future<(SendPort?, int?)> loadChat({
    required FileInfo fileInfo,
  }) async {
    qq;
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/rwkv_vocab_v20230424.txt");

    String modelPath;

    if (fileInfo.fromPthFile) {
      modelPath = fileInfo.raw;
    } else {
      final localFile = P.remote.locals(fileInfo).q;
      modelPath = localFile.targetPath;
    }

    final backend = fileInfo.backend;

    if (backend == null) {
      throw Exception("Backend is null");
    }

    final enableReasoning = fileInfo.isReasoning;

    if (backend == Backend.mlx || backend == Backend.coreml) {
      unzippingStatus(fileInfo).q = true;
      modelPath = await unzipInPlace(modelPath);
      unzippingStatus(fileInfo).q = false;
    }

    await _ensureQNNCopied();
    await _createRWKVIsolateIfNeeded();
    await _releaseModelByWeightTypeIfNeeded(weightType: .chat);
    await _releaseModelByWeightTypeIfNeeded(weightType: .roleplay);

    final modelID = await _loadModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      fileInfo: fileInfo,
    );
    if (modelID == null) {
      final msg = "Failed to load model, modelID is null";
      qqw(msg);
      return (_sendPort, null);
    }
    P.app.demoType.q = .chat;
    loadedModels.q = {
      ...loadedModels.q,
      fileInfo: modelID,
    };

    await setModelConfig(enableReasoning: enableReasoning);
    await resetSamplerParams(enableReasoning: enableReasoning);
    await resetMaxLength(enableReasoning: enableReasoning);
    // send(to_rwkv.GetSamplerParams()); NOTE: already get in resetSamplerParams, so no need here
    _syncMaxBatchCount();

    return (_sendPort, modelID);
  }

  Future<int?> loadSee({
    required String modelPath,
    required String encoderPath,
    required Backend backend,
    required bool enableReasoning,
    required String? adapterPath,
    required FileInfo fileInfo,
  }) async {
    qq;
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    _thinkingMode.q = enableReasoning ? .free : .none;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/rwkv_vocab_v20230424.txt");

    await _ensureQNNCopied();
    await _createRWKVIsolateIfNeeded();
    await _releaseModelByWeightTypeIfNeeded(weightType: .see);

    final modelID = await _loadModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      fileInfo: fileInfo,
    );
    if (modelID == null) {
      final msg = "Failed to load model, modelID is null";
      qqw(msg);
      return null;
    }
    P.app.demoType.q = .see;
    loadedModels.q = {
      ...loadedModels.q,
      fileInfo: modelID,
    };

    if (adapterPath != null) {
      send(to_rwkv.LoadVisionEncoderAndAdapter(encoderPath, adapterPath, modelID: modelID));
    } else {
      send(to_rwkv.LoadVisionEncoder(encoderPath, modelID: modelID));
    }

    await setModelConfig(
      enableReasoning: enableReasoning,
      preferChinese: false,
      setPrompt: false,
      thinkingMode: _thinkingMode.q,
    );
    await resetSamplerParams(enableReasoning: enableReasoning);
    await resetMaxLength(enableReasoning: enableReasoning);
    send(to_rwkv.SetEosToken("\x17", modelID: modelID));
    send(to_rwkv.SetBosToken("\x16", modelID: modelID));
    send(to_rwkv.SetTokenBanned([0], modelID: modelID));

    return modelID;
  }

  Future<(SendPort?, int?)> loadTTS({
    required String modelPath,
    required String wav2vec2Path,
    required String detokenizePath,
    required String bicodecTokenzerPath,
    required Backend backend,
    required FileInfo fileInfo,
  }) async {
    qq;
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/vocab_talk.txt");

    await _ensureQNNCopied();
    await _createRWKVIsolateIfNeeded();
    await _releaseModelByWeightTypeIfNeeded(weightType: .tts);
    final modelID = await _loadModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      fileInfo: fileInfo,
    );

    if (modelID == null) {
      final msg = "Failed to load model, modelID is null";
      qqw(msg);
      return (_sendPort, null);
    }
    P.app.demoType.q = .tts;
    loadedModels.q = {
      ...loadedModels.q,
      fileInfo: modelID,
    };

    if (_ttsPerformanceTimer != null) {
      _ttsPerformanceTimer!.cancel();
      _ttsPerformanceTimer = null;
    }

    _ttsPerformanceTimer = Timer.periodic(225.ms, (timer) async {
      send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    });

    send(
      to_rwkv.LoadSparkTTSModels(
        wav2vec2Path: wav2vec2Path,
        bicodecTokenizerPath: bicodecTokenzerPath,
        bicodecDetokenizerPath: detokenizePath,
      ),
    );

    final ttsTextNormalizerDatePath = await fromAssetsToTemp("assets/config/chat/date-zh.fst");
    final ttsTextNormalizerNumberPath = await fromAssetsToTemp("assets/config/chat/number-zh.fst");
    final ttsTextNormalizerPhonePath = await fromAssetsToTemp("assets/config/chat/phone-zh.fst");
    // note: order matters here
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerDatePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerPhonePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerNumberPath));
    return (_sendPort, modelID);
  }

  Future<void> loadOthello() async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    late final String modelPath;
    late final Backend backend;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/b_othello_vocab.txt");

    if (Platform.isIOS || Platform.isMacOS) {
      modelPath = await fromAssetsToTemp("assets/model/chat/rwkv7_othello_26m_L10_D448_extended.st");
      backend = Backend.webRwkv;
    } else {
      modelPath = await fromAssetsToTemp("assets/model/chat/rwkv7_othello_26m_L10_D448_extended-ncnn.bin");
      await fromAssetsToTemp("assets/model/chat/rwkv7_othello_26m_L10_D448_extended-ncnn.param");
      backend = Backend.ncnn;
    }

    await _createRWKVIsolateIfNeeded();
    await _releaseModelByWeightTypeIfNeeded(weightType: .othello);

    final modelID = await _loadModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      // TODO: fileInfo is null for othello
      fileInfo: FileInfo.fromJSON(const {}),
    );
    if (modelID == null) {
      final msg = "Failed to load model, modelID is null";
      qqw(msg);
      return;
    }

    P.app.demoType.q = .othello;
    loadedModels.q = {
      ...loadedModels.q,
      // TODO: fileInfo is null for othello
      // fileInfo: modelID,
    };

    send(to_rwkv.SetMaxLength(64000, modelID: modelID));
    send(
      to_rwkv.SetSamplerParams(
        temperature: 1.0,
        topK: 1,
        topP: 1.0,
        presencePenalty: .0,
        frequencyPenalty: .0,
        penaltyDecay: .0,
        modelID: modelID,
      ),
    );
    send(to_rwkv.SetGenerationStopToken(0, modelID: modelID));
    send(to_rwkv.ClearStates(modelID: modelID));
  }

  Future<void> loadSudoku({
    required String modelPath,
    required Backend backend,
  }) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/b_sudoku_vocab.txt");
    final data = await rootBundle.load("assets/config/chat/sudoku_rwkv_20241120_ncnn.param");
    final paramFile = File(join(P.app.effectiveDocumentsDir.q!.path, "sudoku_rwkv_20241120_ncnn.param"));
    await paramFile.writeAsBytes(data.buffer.asUint8List());

    await _ensureQNNCopied();
    await _createRWKVIsolateIfNeeded();
    await _releaseModelByWeightTypeIfNeeded(weightType: .sudoku);

    final modelID = await _loadModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      // TODO: fileInfo is null for othello
      fileInfo: FileInfo.fromJSON(const {}),
    );
    if (modelID == null) {
      final msg = "Failed to load model, modelID is null";
      qqw(msg);
      return;
    }

    P.app.demoType.q = .sudoku;
    loadedModels.q = {
      ...loadedModels.q,
      // TODO: fileInfo is null for sudoku
      // fileInfo: modelID,
    };

    send(to_rwkv.SetMaxLength(6000_000, modelID: modelID));
    send(
      to_rwkv.SetSamplerParams(
        temperature: 1.0,
        topK: 1,
        topP: 1.0,
        presencePenalty: .0,
        frequencyPenalty: .0,
        penaltyDecay: .0,
        modelID: modelID,
      ),
    );
    send(to_rwkv.SetGenerationStopToken(_Sudoku.tokenStop, modelID: modelID));
    send(to_rwkv.ClearStates(modelID: modelID));
  }
}

/// Public methods
extension $RWKV on _RWKV {
  Future<void> setAudioPrompt({required String path}) async {
    final modelID = findModelIDByWeightType(weightType: .tts);
    if (modelID == null) {
      return;
    }
    send(to_rwkv.SetAudioPrompt(path, modelID: modelID));
  }

  Future<void> sendMessages(
    List<String> messages, {
    double getIsGeneratingRate = .5,
    double getResponseBufferContentRate = .5,
    int batchSize = 1,
    int? maxLength,
    bool forceChinese = false,
  }) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    if (isAlbatrossLoaded.q) {
      final stream = Albatross.instance.chat(messages, batchSize: 1);
      try {
        await for (final event in stream) {
          _messagesController.add(event);
        }

        /// NOTE: downstream requires this delay
        500.msLater.then((_) {
          _messagesController.add(from_rwkv.GenerateStop());
        });
      } catch (e) {
        500.msLater.then((_) {
          _messagesController.add(from_rwkv.GenerateStop(error: e.toString()));
        });
      } finally {
        _oldMessagesController.add(const LLMEvent(type: _RWKVMessageType.isGenerating, content: 'false'));
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

    final modelID = findModelIDByWeightType(weightType: weightType);
    if (modelID == null) {
      qqe("modelID is null");
      return;
    }

    final isBatchInference = batchSize > 1;

    final thinkingMode = _thinkingMode.q;

    final reasoning = thinkingMode.hasThinkTag;
    List<List<String>> batchMessages = [];
    for (var i = 0; i < batchSize; i++) {
      batchMessages.add(messages);
    }

    /// ‘古今’ 模式
    List<String> his = batchMessages[0];
    if (his.length % 2 == 1 && batchSize == 2) {
      if (P.chat.wenYanWen.q == WenyanMode.mixed) {
        his = [...his];
        his[his.length - 1] = his[his.length - 1] + " 请用文言文回答。";
        batchMessages[0] = his;
      }
    }

    final forceReasoning = thinkingMode.forceReasoning;
    final addGenerationPrompt = messages.length.isOdd;
    final request = isBatchInference
        ? to_rwkv.ChatBatchAsync(
            batchMessages,
            enableReasoning: reasoning,
            forceReasoning: forceReasoning,
            addGenerationPrompt: addGenerationPrompt,
            batchSize: batchSize,
            modelID: modelID,
            maxLength: maxLength,
            forceLang: forceChinese ? 1 : null,
          ) //
        : to_rwkv.ChatAsync(
            messages,
            enableReasoning: reasoning,
            forceReasoning: forceReasoning,
            addGenerationPrompt: addGenerationPrompt,
            modelID: modelID,
            maxLength: maxLength,
            forceLang: forceChinese ? 1 : null,
          );
    send(request);

    generatingId.q = request.requestId;
    hiddenPrefilling.q = maxLength == 0;

    if (_getTokensTimer != null) _getTokensTimer!.cancel();

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      final getResponseCalling = isBatchInference
          ? to_rwkv.GetBatchResponseBufferContent(messages: messages, modelID: modelID) //
          : to_rwkv.GetResponseBufferContent(messages: messages, modelID: modelID);
      send(getResponseCalling);
      if (HF.randomBool(truePercentage: getIsGeneratingRate)) send(to_rwkv.GetIsGenerating(modelID: modelID));
      if (HF.randomBool(truePercentage: getResponseBufferContentRate)) send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
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

    if (isAlbatrossLoaded.q) {
      return Albatross.instance.completion(prompt, batchSize: batchSize);
    }

    final sendPort = _sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return const Stream.empty();
    }

    final modelID = findModelIDByWeightType(weightType: .chat);
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
    send(request);
    if (_getTokensTimer != null) _getTokensTimer!.cancel();

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      final getResponseCalling = batchSize > 1
          ? to_rwkv.GetBatchResponseBufferContent(messages: [], modelID: modelID) //
          : to_rwkv.GetResponseBufferContent(messages: [], modelID: modelID);
      send(getResponseCalling);
      if (HF.randomBool(truePercentage: .5)) send(to_rwkv.GetIsGenerating(modelID: modelID));
      if (HF.randomBool(truePercentage: .5)) send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    });
    return broadcastStream.mapNotNull((e) {
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
    final sendPort = _sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }

    final modelID = findModelIDByWeightType(weightType: .othello);
    if (modelID == null) {
      return;
    }

    send(to_rwkv.SudokuOthelloGenerate(prompt, modelID: modelID));

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
    }

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      send(to_rwkv.GetResponseBufferIds(modelID: modelID));
      send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
      send(to_rwkv.GetResponseBufferContent(messages: [], modelID: modelID));
      await 1000.msLater;
      send(to_rwkv.GetIsGenerating(modelID: modelID));
    });
  }

  Future<void> clearStates() async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    final sendPort = _sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }
    for (final entry in loadedModels.q.entries) {
      final modelID = entry.value;
      send(to_rwkv.ClearStates(modelID: modelID));
    }
  }

  Future<int?> calculateTokensCountRaw({
    required String text,
    WeightType? preferredWeightType,
  }) async {
    if (text.isEmpty) return 0;
    if (_sendPort == null) return null;
    final weightType = _resolveWeightTypeForTokenCount(preferredWeightType: preferredWeightType);
    final modelID = findModelIDByWeightType(weightType: weightType);
    if (modelID == null) return null;

    final request = to_rwkv.CalculateTokensCountRaw(text, modelID: modelID);
    send(request);

    try {
      final response = await broadcastStream
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
    if (_sendPort == null) return null;
    final weightType = _resolveWeightTypeForTokenCount(preferredWeightType: preferredWeightType);
    final modelID = findModelIDByWeightType(weightType: weightType);
    if (modelID == null) return null;

    final request = to_rwkv.CalculateTokensCountFromMessages(messages, modelID: modelID);
    send(request);

    try {
      final response = await broadcastStream
          .whereType<from_rwkv.TokensCount>()
          .where((from_rwkv.TokensCount event) => event.req?.requestId == request.requestId)
          .first
          .timeout(const Duration(seconds: 3));
      return response.tokensCount;
    } catch (_) {
      return null;
    }
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

  void send(to_rwkv.ToRWKV toRwkv) {
    final sendPort = _sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }
    sendPort.send(toRwkv);
    return;
  }

  Future<void> stop() async {
    if (isAlbatrossLoaded.q) return Albatross.instance.stop();
    for (final entry in loadedModels.q.entries) {
      final modelID = entry.value;
      send(to_rwkv.Stop(modelID: modelID));
    }
  }

  void setGenerateMode(bool isGenerateMode) {
    if (isGenerateMode) {
      for (final entry in loadedModels.q.entries) {
        final modelID = entry.value;
        send(to_rwkv.SetPrompt("", modelID: modelID));
      }
    } else {
      setModelConfig(thinkingMode: _thinkingMode.q);
    }
  }

  void updateSystemPrompt({String? prompt}) {
    final systemPrompt = P.preference.promptTemplate.formatedSystemPrompt().trim();
    for (final entry in loadedModels.q.entries) {
      final modelID = entry.value;
      if (prompt != null) {
        send(to_rwkv.SetPrompt(prompt, modelID: modelID));
      } else {
        String p = prompt ?? "<EOD>";
        if (systemPrompt.isNotEmpty) {
          p = "$systemPrompt\n\n";
        }
        send(to_rwkv.SetPrompt(p, modelID: modelID));
      }
      qqw("setPrompt: $prompt");
    }
  }

  Future<void> setModelConfig({
    thinking_mode.ThinkingMode? thinkingMode,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? enableReasoning,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? preferChinese,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? preferPseudo,
    bool setPrompt = true,
    String? prompt,
  }) async {
    qqr(thinkingMode);
    _thinkingMode.q = thinkingMode ?? .fast;

    if (setPrompt) {
      updateSystemPrompt(prompt: prompt);
    }

    final custom = P.preference.promptTemplate;
    final thinkingToken = custom.apply(_thinkingMode.q);
    qqq("setThinkingToken: $thinkingToken");
    for (final entry in loadedModels.q.entries) {
      final modelID = entry.value;
      send(to_rwkv.SetThinkingToken(thinkingToken, modelID: modelID));
    }
  }

  Future<void> resetSamplerParams({required bool enableReasoning}) async {
    for (final entry in loadedModels.q.entries) {
      final modelID = entry.value;
      send(
        to_rwkv.SetSamplerParams(
          temperature: enableReasoning ? Argument.temperature.reasonDefaults : Argument.temperature.defaults,
          topK: enableReasoning ? Argument.topK.reasonDefaults : Argument.topK.defaults,
          topP: enableReasoning ? Argument.topP.reasonDefaults : Argument.topP.defaults,
          presencePenalty: enableReasoning ? Argument.presencePenalty.reasonDefaults : Argument.presencePenalty.defaults,
          frequencyPenalty: enableReasoning ? Argument.frequencyPenalty.reasonDefaults : Argument.frequencyPenalty.defaults,
          penaltyDecay: enableReasoning ? Argument.penaltyDecay.reasonDefaults : Argument.penaltyDecay.defaults,
          modelID: modelID,
        ),
      );
    }
  }

  Future syncSamplerParamsFromDefault(DecodeParamType param) async {
    await syncSamplerParams(
      temperature: param.temperature,
      topP: param.topP,
      penaltyDecay: param.penaltyDecay,
      presencePenalty: param.presencePenalty,
      frequencyPenalty: param.frequencyPenalty,
    );
  }

  Future<void> syncSamplerParams({
    double? temperature,
    double? topK,
    double? topP,
    double? presencePenalty,
    double? frequencyPenalty,
    double? penaltyDecay,
  }) async {
    if (temperature != null) arguments(Argument.temperature).q = temperature;
    if (topK != null) arguments(Argument.topK).q = topK;
    if (topP != null) arguments(Argument.topP).q = topP;
    if (presencePenalty != null) arguments(Argument.presencePenalty).q = presencePenalty;
    if (frequencyPenalty != null) arguments(Argument.frequencyPenalty).q = frequencyPenalty;
    if (penaltyDecay != null) arguments(Argument.penaltyDecay).q = penaltyDecay;

    for (final entry in loadedModels.q.entries) {
      final modelID = entry.value;
      send(
        to_rwkv.SetSamplerParams(
          temperature: _intIfFixedDecimalsIsZero(Argument.temperature),
          topK: _intIfFixedDecimalsIsZero(Argument.topK),
          topP: _intIfFixedDecimalsIsZero(Argument.topP),
          presencePenalty: _intIfFixedDecimalsIsZero(Argument.presencePenalty),
          frequencyPenalty: _intIfFixedDecimalsIsZero(Argument.frequencyPenalty),
          penaltyDecay: _intIfFixedDecimalsIsZero(Argument.penaltyDecay),
          modelID: modelID,
        ),
      );
    }

    if (kDebugMode) {
      for (final entry in loadedModels.q.entries) {
        final modelID = entry.value;
        send(to_rwkv.GetSamplerParams(modelID: modelID));
      }
    }
  }

  Future<void> resetMaxLength({required bool enableReasoning}) async {
    await syncMaxLength(maxLength: enableReasoning ? Argument.maxLength.reasonDefaults : Argument.maxLength.defaults);
  }

  Future<void> syncMaxLength({num? maxLength}) async {
    if (maxLength != null) arguments(Argument.maxLength).q = maxLength.toDouble();
    for (final entry in loadedModels.q.entries) {
      final modelID = entry.value;
      send(to_rwkv.SetMaxLength(_intIfFixedDecimalsIsZero(Argument.maxLength).toInt(), modelID: modelID));
    }
  }

  Future<void> onThinkModeTapped() async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    P.app.hapticLight();

    final s = S.current;

    if (isAlbatrossLoaded.q) {
      final current = thinkingMode.q;
      if (current != .none) {
        setModelConfig(thinkingMode: .none);
      } else {
        setModelConfig(thinkingMode: .free);
      }
      return;
    }

    final currentModelIsBefore20250922 = P.rwkv.currentModelIsBefore20250922.q;
    qqr("currentModelIsBefore20250922: $currentModelIsBefore20250922");
    if (currentModelIsBefore20250922) {
      final current = thinkingMode.q;
      switch (current) {
        case .lighting:
          setModelConfig(thinkingMode: .free);
          Alert.success(s.thinking_mode_high(s.thinking_mode_alert_footer));
        case .free:
          setModelConfig(thinkingMode: .none);
          Alert.success(s.thinking_mode_off(s.thinking_mode_alert_footer));
        case .preferChinese:
          setModelConfig(thinkingMode: .none);
          Alert.success(s.thinking_mode_off(s.thinking_mode_alert_footer));
        case .none:
          setModelConfig(thinkingMode: .lighting);
          Alert.success(s.thinking_mode_auto(s.thinking_mode_alert_footer));
        default:
          break;
      }
      return;
    }

    final current = thinkingMode.q;

    final actionPairs = <({thinking_mode.ThinkingMode key, String label})>[
      (label: s.thinking_mode_off(""), key: .none),
      (label: s.think_button_mode_fast(""), key: .fast),
      (label: s.thinking_mode_high(""), key: .free),
      (label: s.think_button_mode_en(""), key: .en),
      (label: s.think_button_mode_en_short(""), key: .enShort),
      (label: s.think_button_mode_en_long(""), key: .enLong),
    ];

    qqr("actionPairs: $actionPairs");

    final actions = actionPairs.map((e) {
      final isCurrent = e.key == current;
      final label = isCurrent ? "☑ ${e.label}" : e.label;
      final key = e.key;
      return SheetAction(label: label, key: key);
    }).toList();

    final res = await showModalActionSheet<thinking_mode.ThinkingMode>(
      context: getContext()!,
      title: s.think_mode_selector_title,
      message: s.think_mode_selector_message + "\n" + s.think_mode_selector_recommendation,
      actions: actions,
    );

    if (res == null) return;

    setModelConfig(thinkingMode: res);
    switch (res) {
      case .none:
        Alert.success(s.thinking_mode_off(s.thinking_mode_alert_footer));
      case .fast:
        Alert.success(s.think_button_mode_fast(s.thinking_mode_alert_footer));
      case .free:
        Alert.success(s.thinking_mode_high(s.thinking_mode_alert_footer));
      case .en:
        Alert.success(s.think_button_mode_en(s.thinking_mode_alert_footer));
      case .enShort:
        Alert.success(s.think_button_mode_en_short(s.thinking_mode_alert_footer));
      case .enLong:
        Alert.success(s.think_button_mode_en_long(s.thinking_mode_alert_footer));
      default:
        break;
    }
  }

  void onBatchInferenceTapped() async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final currentModel = P.rwkv.latestModel.q;

    final batchAllowed = currentModel!.tags.contains("batch");

    if (!batchAllowed) {
      Alert.info(S.current.this_model_does_not_support_batch_inference);
      await 500.msLater;
      ModelSelector.show();
      return;
    }

    await BatchSettingsPanel.show();
  }

  void onSecondaryOptionsTapped() async {
    final receiving = P.rwkv.generating.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection(preferredDemoType: .chat)) return;

    final current = thinkingMode.q;
    P.app.hapticLight();
    switch (current) {
      case .lighting:
      case .none:
        break;
      case .free:
        setModelConfig(thinkingMode: .preferChinese);
        Alert.success(S.current.prefer_chinese);
      case .preferChinese:
        setModelConfig(thinkingMode: .free);
        Alert.success(S.current.thinking_mode_high(S.current.thinking_mode_alert_footer));
      default:
        break;
    }
  }

  Future<void> refreshRuntimeLog() async {
    send(to_rwkv.DumpLog());
  }

  Future<void> refreshStatePanel() async {
    final modelID = findModelIDByWeightType(weightType: .chat);
    if (modelID != null) send(to_rwkv.DumpStateInfo(modelID: modelID));
  }

  Future<void> setRenderNewlineDirectly(bool value) async {
    if (renderNewlineDirectly.q == value) {
      return;
    }

    renderNewlineDirectly.q = value;
    await P.preference.saveDebugRenderNewlineDirectly(value);
  }

  Future<void> toggleRenderNewlineDirectly() async {
    await setRenderNewlineDirectly(!renderNewlineDirectly.q);
  }

  Future<void> setRenderSpaceSymbol(bool value) async {
    if (renderSpaceSymbol.q == value) {
      return;
    }

    renderSpaceSymbol.q = value;
    await P.preference.saveDebugRenderSpaceSymbol(value);
  }

  Future<void> toggleRenderSpaceSymbol() async {
    await setRenderSpaceSymbol(!renderSpaceSymbol.q);
  }

  Future<void> setShowPrefillLogOnly(bool value) async {
    if (showPrefillLogOnly.q == value) {
      return;
    }

    showPrefillLogOnly.q = value;
    await P.preference.saveDebugShowPrefillLogOnly(value);
  }

  Future<void> toggleShowPrefillLogOnly() async {
    await setShowPrefillLogOnly(!showPrefillLogOnly.q);
  }

  /// 加载指定 pth 权重并完成聊天用配置（角色、batch、thinkingMode、GetSupportedBatchSizes）。
  /// 供 UI 在「Start to Chat」时调用；成功/失败在内部用 Alert.success / Alert.error 与 pop 处理。
  Future<void> startPthForChat(FileInfo fileInfo) async {
    qq;
    if (fileInfo.backend == null) {
      Alert.error("Backend is null");
      return;
    }
    try {
      clearStates();
      await loadChat(fileInfo: fileInfo);
    } catch (e) {
      Alert.error(e.toString());
      return;
    }
    final batchAllowed = fileInfo.tags.contains("batch");
    if (!batchAllowed) P.chat.batchEnabled.q = false;

    final modelID = findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      Alert.error("findModelIDByWeightType(chat) returned null");
      return;
    }

    final isTranslate = fileInfo.tags.contains("translate");
    if (isTranslate) {
      if (P.translator.enToZh.q) {
        send(to_rwkv.SetUserRole("English", modelID: modelID));
        send(to_rwkv.SetResponseRole(responseRole: "Chinese", modelID: modelID));
      } else {
        send(to_rwkv.SetUserRole("Chinese", modelID: modelID));
        send(to_rwkv.SetResponseRole(responseRole: "English", modelID: modelID));
      }
      await setModelConfig(thinkingMode: .none, prompt: "<EOD>", setPrompt: true);
      P.backend.start();
    } else {
      send(to_rwkv.SetUserRole("User", modelID: modelID));
      send(to_rwkv.SetResponseRole(responseRole: "Assistant", modelID: modelID));
    }

    if (!isTranslate) {
      if (currentModelIsBefore20250922.q) {
        setModelConfig(thinkingMode: .lighting);
      } else {
        setModelConfig(thinkingMode: .fast);
      }
    }

    for (var i = 0; i < 3; i++) {
      (500 * i).msLater.then((_) {
        send(to_rwkv.GetSupportedBatchSizes(modelID: modelID));
      });
    }
    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    pop();
  }

  int? findModelIDByWeightType({required WeightType weightType}) {
    final loaded = loadedModels.q.entries.firstWhereOrNull((e) => e.key.weightType == weightType);

    final value = loaded?.value;

    if (value == null) {
      final msg = "model id for weight type $weightType, maybe model is not loaded";
      qqq(msg);
    }

    return value;
  }
}

/// Private methods
extension _$RWKV on _RWKV {
  Future<void> _init() async {
    P.app.pageKey.lv(_onPageKeyChanged);
    _receivePort.listen(_onMessage);
    final r = await compute((_) {
      final socName = RWKVMobile.getSocName();
      final platformName = RWKVMobile.getPlatformName();
      final socBrand = SocBrand.fromString(platformName);
      return (socName, socBrand);
    }, []);
    socName.q = r.$1;
    socBrand.q = r.$2;

    if (Platform.isAndroid) {
      final detected = await P.adapter.detectSocInfo();
      if (detected != null) {
        final detectedName = detected.$1;
        final detectedBrand = detected.$2;
        if (detectedName.isNotEmpty) {
          frontendSocName.q = detectedName;
        }
        if (detectedBrand != SocBrand.unknown) {
          frontendSocBrand.q = detectedBrand;
        }
      }
    }

    latestModel.lb(_onCurrentModelChanged);
    Albatross.instance.init();
    P.rwkv.generating.l(_onGeneratingChanged);
  }

  void _onGeneratingChanged(bool generating) async {
    P.app.setKeepScreenAwakeForReason(reason: .generation, enabled: generating);
    if (P.rwkv.generatingId.q == null) return;
    if (!generating) P.rwkv.generatingId.q = null;
  }

  Future<void> _createRWKVIsolateIfNeeded() async {
    if (backendStatus.q != .none) {
      final msg = "Backend is not in none status, so isolate should be created before, current status: ${backendStatus.q}";
      qqw(msg);
      return;
    }

    backendStatus.q = .creatingIsolate;
    _createRWKVIsolateCompleter = Completer<void>();
    final options = StartOptions(
      sendPort: _receivePort.sendPort,
      rootIsolateToken: RootIsolateToken.instance!,
    );
    await RWKVMobile().runIsolate(options);
    await _createRWKVIsolateCompleter!.future;
    backendStatus.q = .ready;
  }

  Future<int?> _loadModel({
    required String modelPath,
    required String tokenizerPath,
    required Backend backend,
    required FileInfo fileInfo,
  }) async {
    final completer = Completer<int?>();
    modelLoadingCompleters.q = {...modelLoadingCompleters.q, fileInfo: completer};
    final req = to_rwkv.LoadRWKVModel(
      modelPath: modelPath,
      backend: backend,
      tokenizerPath: tokenizerPath,
      extra: fileInfo,
    );
    send(req);
    loadingStatus.q = {...loadingStatus.q, fileInfo: .loading};
    loadingProgress.q = {...loadingProgress.q, fileInfo: 0.0};
    final modelID = await completer.future;
    modelLoadingCompleters.q = {...modelLoadingCompleters.q..remove(fileInfo)};
    // 如果我们得到的 modelID 为 null, 则表示加载失败
    return modelID;
  }

  Future<void> _releaseModelById({required int modelID}) async {
    if (modelReleasingCompleters.q.containsKey(modelID)) {
      qqw("modelReleasingCompleters already contains completer for modelID: $modelID");
      return;
    }
    qqq("releasing model by id: $modelID");
    final completer = Completer<bool>();
    modelReleasingCompleters.q = {...modelReleasingCompleters.q, modelID: completer};
    final fileInfo = loadedModels.q.entries.firstWhereOrNull((e) => e.value == modelID)?.key;
    final req = to_rwkv.ReleaseRWKVModel(modelID: modelID, extra: fileInfo);
    send(req);
    final success = await completer.future;
    modelReleasingCompleters.q = {...modelReleasingCompleters.q..remove(modelID)};
    if (success) loadedModels.q = {...loadedModels.q..remove(fileInfo)};
  }

  Future<void> _releaseModelByWeightTypeIfNeeded({required WeightType weightType}) async {
    final loaded = loadedModels.q.entries.firstWhereOrNull((e) => e.key.weightType == weightType);
    final modelID = loaded?.value;
    final fileInfo = loaded?.key;

    if (modelID == null) {
      final msg = "ModelID is null, maybe no model is loaded for weight type $weightType, so no need to release";
      qqq(msg);
      return;
    }

    if (fileInfo == null) {
      final msg = "FileInfo is null, maybe no model is loaded for weight type $weightType, so no need to release";
      qqq(msg);
      return;
    }

    switch (weightType) {
      case .chat:
        break;
      case .see:
        break;
      case .tts:
        send(to_rwkv.ReleaseTTSModels());
        break;
      case .sudoku:
        break;
      case .othello:
        break;
      case .roleplay:
        break;
    }

    await _releaseModelById(modelID: modelID);
    loadedModels.q = {...loadedModels.q..remove(fileInfo)};
    final msg = "Released model $modelID for $weightType";
    qqr(msg);
  }

  Future<void> _releaseAllModels() async {
    currentGroupInfo.q = null;
    currentWorldType.q = null;
    await Future.wait(loadedModels.q.entries.map((e) => _releaseModelById(modelID: e.value)));
  }

  void _syncMaxBatchCount() {
    for (final delay in [500.ms, 1000.ms, 2000.ms]) {
      delay.inMilliseconds.msLater.then((_) {
        final modelID = findModelIDByWeightType(weightType: .chat);
        if (modelID != null) send(to_rwkv.GetSupportedBatchSizes(modelID: modelID));
      });
    }
  }

  void _onCurrentModelChanged(FileInfo? oldModel, FileInfo? newModel) async {
    if (oldModel == null || newModel == null) return;
    final oldModelSize = oldModel.modelSize;
    final newModelSize = newModel.modelSize;
    if (oldModelSize == null || newModelSize == null) return;
    if (oldModelSize >= newModelSize) return;
    if (P.app.pageKey.q != .chat) return;
    if (P.msg.list.q.isEmpty) return;
    await 2000.msLater;
    Alert.info(S.current.model_size_increased_please_open_a_new_conversation);
  }

  num _intIfFixedDecimalsIsZero(Argument argument) {
    if (argument.fixedDecimals == 0) {
      return arguments(argument).q.toInt();
    } else {
      return double.parse(arguments(argument).q.toStringAsFixed(argument.fixedDecimals));
    }
  }

  Future<void> _onPageKeyChanged() async {
    final pageKey = P.app.pageKey.q;
    switch (pageKey) {
      case .othello:
        await loadOthello();
        break;
      case .chat:
        qq;
        final modelID = findModelIDByWeightType(weightType: .chat);
        if (modelID != null) send(to_rwkv.GetSupportedBatchSizes(modelID: modelID));
        break;
      default:
        break;
    }
  }

  // ignore: unused_element
  Future<void> _loadFifthteenPuzzle() async {
    throw "Not support, please contact the developer";
  }

  // ignore: unused_element
  Future<void> _loadSudoku() async {
    throw "Not support, please contact the developer";
  }

  void _onMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      _createRWKVIsolateCompleter?.complete();
      _createRWKVIsolateCompleter = null;
      return;
    }

    if (RoleplayManage.isRolePlayMessage) {
      RoleplayManage.operationMessage(message);
    }

    if (message is from_rwkv.FromRWKV) {
      _handleFromRWKV(message);
      return;
    }

    if (message["responseBufferIds"] != null) {
      final responseBufferIdsList = message["responseBufferIds"];
      _oldMessagesController.add(
        LLMEvent(
          responseBufferIds: (responseBufferIdsList as List).map((e) => e as int).toList(),
          type: _RWKVMessageType.responseBufferIds,
        ),
      );
      return;
    }

    if (message["isGenerating"] != null) {
      final isGenerating = message["isGenerating"];
      _oldMessagesController.add(
        LLMEvent(
          content: isGenerating.toString(),
          type: _RWKVMessageType.isGenerating,
        ),
      );
      if (!isGenerating) {
        _getTokensTimer?.cancel();
        _getTokensTimer = null;
      }
      return;
    }

    if (message["sudokuOthelloResponse"] != null) {
      final responseText = message["sudokuOthelloResponse"].toString();
      _oldMessagesController.add(
        LLMEvent(
          content: responseText,
          type: _RWKVMessageType.sudokuOthelloResponse,
        ),
      );
      return;
    }

    if (message["streamResponse"] != null) {
      final responseText = message["streamResponse"].toString();
      _oldMessagesController.add(
        LLMEvent(
          content: responseText,
          token: message["streamResponseToken"],
          type: _RWKVMessageType.streamResponse,
        ),
      );
      if (message["prefillSpeed"] != null && message["prefillSpeed"] != -1.0) {
        prefillSpeed.q = message["prefillSpeed"];
      }
      if (message["decodeSpeed"] != null && message["decodeSpeed"] != -1.0) {
        decodeSpeed.q = message["decodeSpeed"];
      }
      return;
    }

    qqe("unknown message: $message");
    if (!kDebugMode) Sentry.captureException(Exception("unknown message: $message"), stackTrace: StackTrace.current);
  }

  void _handleLoadModelSteps(from_rwkv.LoadModelSteps response) {
    final req = response.req;

    late final FileInfo extra;

    if (req is to_rwkv.LoadRWKVModel) {
      extra = req.extra as FileInfo;
    } else if (req is to_rwkv.ReleaseRWKVModel) {
      extra = req.extra as FileInfo;
    } else {
      qqe("unknown request: $req");
      return;
    }

    final modelID = response.modelID;
    final status = response.status;
    final info = response.info;
    final name = extra.name;

    qqq("$name, modelID: $modelID, status: $status");

    final modelLoadingCompleter = modelLoadingCompleters.q[extra];
    final modelReleasingCompleter = modelReleasingCompleters.q[modelID];

    switch (status) {
      case .loaded:
        if (modelID == null) {
          qqe("modelID is null,  but status is loaded, this should not happen");
          return;
        }
        loadedModels.q = {...loadedModels.q, extra: modelID};

        if (modelLoadingCompleter != null) {
          modelLoadingCompleter.complete(modelID);
        } else {
          qqe("modelLoadingCompleter is null,  but status is loaded, this is impossible");
        }

      case .failedInLoading:
        if (modelLoadingCompleter != null) {
          modelLoadingCompleter.complete(null);
        } else {
          qqe("modelLoadingCompleter is null,  but status is loaded, this should not happen");
        }
        qqe("failed in loading model $name, status: $status");
        qqe("error: $info");
        Alert.error("Failed to load model $name, error: $info");

      case .released:
        if (modelReleasingCompleter != null) {
          modelReleasingCompleter.complete(true);
        } else {
          qqe("modelReleasingCompleter is null, but status is .released, this should not happen");
          qqe("modelReleasingCompleters: ${modelReleasingCompleters.q}");
          qqe("trying to find completer by id: $modelID");
        }

      case .failedInReleasing:
        if (modelReleasingCompleter != null) {
          modelReleasingCompleter.complete(false);
        } else {
          qqe("modelReleasingCompleter is null, but status is .failedInReleasing, this should not happen");
          qqe("modelReleasingCompleters: ${modelReleasingCompleters.q}");
          qqe("trying to find completer by id: $modelID");
        }

      case .loading:
        final progress = response.progress;
        if (progress != null) loadingProgress.q = {...loadingProgress.q, extra: progress};
      case .none:
      case .releasing:
      case .setQnnLibraryPath:
      case .loadModelWithExtra:
        break;
    }
    loadingStatus.q = {...loadingStatus.q, extra: status};
  }

  void _handleFromRWKV(from_rwkv.FromRWKV message) {
    _messagesController.add(message);
    switch (message) {
      case from_rwkv.LoadModelSteps res:
        _handleLoadModelSteps(res);

      case from_rwkv.SamplerAndPenaltyParams res:
        final temperatures = res.temperatures;
        final topPs = res.topPs;
        final presencePenalties = res.presencePenalties;
        final frequencyPenalties = res.frequencyPenalties;
        final penaltyDecays = res.penaltyDecays;
        List<SamplerAndPenaltyParam> backendValues = [];
        for (int i = 0; i < temperatures.length; i++) {
          backendValues.add(
            SamplerAndPenaltyParam(
              temperature: temperatures[i].toDouble(),
              topP: topPs[i].toDouble(),
              presencePenalty: presencePenalties[i].toDouble(),
              frequencyPenalty: frequencyPenalties[i].toDouble(),
              penaltyDecay: penaltyDecays[i].toDouble(),
            ),
          );
        }
        backendBatchParams.q = backendValues;

      case from_rwkv.EvaluationResults res:
        P.lambada._onResultsReceived(res);

      case from_rwkv.IsGenerating res:
        generating.q = res.isGenerating;

      case from_rwkv.StateInfo response:
        final stateInfo = response.stateInfo.trim();
        if (stateInfo.isEmpty) return;
        final stateLogList = stateInfo.split("text =").where((e) => e.isNotEmpty).map((e) {
          final raw = e.split(", remaining lifespan = ");
          final text = raw[0];
          final lifeSpan = int.tryParse(raw[1]) ?? 0;
          return StateLog(text: text, lifeSpan: lifeSpan);
        }).toList();
        this.stateLogList.q = stateLogList;

      case from_rwkv.Error response:
        if (kDebugMode) {
          String errorLog = "error: ${response.message}";
          if (message.to != null) errorLog += " in ${message.to.runtimeType}";
          if (message.to?.requestId != null) errorLog += " requestId: ${message.to?.requestId}";
          qqe(errorLog);
        }
        qqe;
        Alert.error(response.message);

      case from_rwkv.Speed response:
        prefillSpeed.q = response.prefillSpeed;
        decodeSpeed.q = response.decodeSpeed;
        prefillProgress.q = response.prefillProgress.clamp(0, 1).toDouble();

      case from_rwkv.StreamResponse response:
        final decodeSpeed = response.decodeSpeed;
        final prefillSpeed = response.prefillSpeed;
        if (decodeSpeed != -1.0) this.decodeSpeed.q = decodeSpeed;
        if (prefillSpeed != -1.0) this.prefillSpeed.q = prefillSpeed;

      case from_rwkv.SupportedBatchSizes response:
        supportedBatchSizes.q = response.supportedBatchSizes;

      case from_rwkv.RuntimeLog response:
        runtimeLog.q = _parseRuntimeLog(response.runtimeLog);

      default:
        break;
    }
  }

  Future<void> _ensureQNNCopied() async {
    if (_qnnLibsCopied.q) {
      return;
    }

    if (Platform.isAndroid) {
      final qnnLibList = <String>{
        "libQnnHtp.so",
        "libQnnHtpNetRunExtensions.so",
        "libQnnHtpV68Stub.so",
        "libQnnHtpV69Stub.so",
        "libQnnHtpV73Stub.so",
        "libQnnHtpV75Stub.so",
        "libQnnHtpV79Stub.so",
        "libQnnHtpV81Stub.so",
        "libQnnHtpV68Skel.so",
        "libQnnHtpV69Skel.so",
        "libQnnHtpV73Skel.so",
        "libQnnHtpV75Skel.so",
        "libQnnHtpV79Skel.so",
        "libQnnHtpV81Skel.so",
        "libQnnHtpPrepare.so",
        "libQnnSystem.so",
        "libQnnRwkvWkvOpPackageV68.so",
        "libQnnRwkvWkvOpPackageV69.so",
        "libQnnRwkvWkvOpPackageV73.so",
        "libQnnRwkvWkvOpPackageV75.so",
        "libQnnRwkvWkvOpPackageV79.so",
        "libQnnRwkvWkvOpPackageV81.so",
      };
      for (final lib in qnnLibList) {
        await fromAssetsToTemp("assets/lib/qnn/$lib", targetPath: "assets/lib/$lib");
      }
      _qnnLibsCopied.q = true;
      return;
    }

    if (!Platform.isWindows || ffi.Abi.current() != ffi.Abi.windowsArm64) {
      return;
    }

    final qnnLibList = <String>{
      "QnnHtp.dll",
      "QnnHtpNetRunExtensions.dll",
      "QnnHtpPrepare.dll",
      "QnnSystem.dll",
      "QnnHtpV68Stub.dll",
      "QnnHtpV73Stub.dll",
      "QnnHtpV81Stub.dll",
      "libQnnHtpV73Skel.so",
      "libQnnHtpV81Skel.so",
      "libqnnhtpv73.cat",
      "libqnnhtpv81.cat",
    };
    for (final lib in qnnLibList) {
      await fromAssetsToTemp("assets/lib/qnn-windows/$lib", targetPath: "assets/lib/$lib");
    }
    _qnnLibsCopied.q = true;
  }

  /// 解析运行时日志，按 [INFO]、[DEBUG]、[WARN] 等标签分割
  List<LogItem> _parseRuntimeLog(String runtimeLog) {
    if (runtimeLog.isEmpty) return [];

    final logItems = <LogItem>[];
    final regex = RegExp(r'\[(INFO|DEBUG|WARN|ERROR|TRACE|FATAL)\]');
    final matches = regex.allMatches(runtimeLog);
    final timeRegex = RegExp(r'\[\d{4}-\d{2}-\d{2} (\d{2}:\d{2}:\d{2}\.\d+)\]');
    final dateRegex = RegExp(r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+\]');

    for (int i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);
      final tag = match.group(1) ?? 'UNKNOWN';

      // 获取当前标签到下一个标签之间的内容
      final start = match.end;
      final end = i + 1 < matches.length ? matches.elementAt(i + 1).start : runtimeLog.length;

      String content = runtimeLog.substring(start, end).trim();
      final timeDisplayString = timeRegex.firstMatch(content)?.group(1) ?? "";
      final dateDisplayString = dateRegex.firstMatch(content)?.group(0) ?? "";
      content = content.replaceAll(dateDisplayString, "");
      final isPrefill = content.startsWith("new text to prefill");

      if (content.isNotEmpty) {
        logItems.add(
          LogItem(
            tag: tag,
            content: content.trim(),
            isPrefill: isPrefill,
            dateTimeString: timeDisplayString.trim(),
          ),
        );
      }
    }

    return logItems;
  }
}

@Deprecated("Use FromRWKV instead")
enum _RWKVMessageType {
  /// 模型吐完 token 了会被调用, 调用内容该次 generate 吐出的总文本
  @Deprecated("Use FromRWKV instead")
  sudokuOthelloResponse,

  /// 模型每吐一个token，调用一次, 调用内容为该次 generate 已经吐出的文本
  @Deprecated("Use FromRWKV instead")
  streamResponse,

  /// 模型是否正在生成
  @Deprecated("Use FromRWKV instead")
  isGenerating,
  @Deprecated("Use FromRWKV instead")
  responseBufferIds,
}

@Deprecated("Use FromRWKV instead")
@immutable
final class LLMEvent {
  final _RWKVMessageType type;
  final String content;
  final List<int>? responseBufferIds;
  final int? token;

  const LLMEvent({
    required this.type,
    this.content = "",
    this.responseBufferIds,
    this.token,
  });

  @override
  String toString() {
    return "LLMEvent.type: $type";
  }
}
