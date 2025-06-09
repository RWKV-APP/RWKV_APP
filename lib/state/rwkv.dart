part of 'p.dart';

class _RWKV {
  /// Send message to RWKV isolate
  SendPort? _sendPort;

  /// Receive message from RWKV isolate
  late final _receivePort = ReceivePort();

  @Deprecated("Use _streamController instead")
  late final _oldMessagesController = StreamController<LLMEvent>();

  @Deprecated("Use _broadcastStream instead")
  static Stream<LLMEvent>? _oldBroadcastStream;

  @Deprecated("Use broadcastStream instead")
  Stream<LLMEvent> get oldBroadcastStream {
    _oldBroadcastStream ??= _oldMessagesController.stream.asBroadcastStream();
    return _oldBroadcastStream!;
  }

  late final _messagesController = StreamController<from_rwkv.FromRWKV>();

  static Stream<from_rwkv.FromRWKV>? _broadcastStream;

  Stream<from_rwkv.FromRWKV> get broadcastStream {
    _broadcastStream ??= _messagesController.stream.asBroadcastStream();
    return _broadcastStream!;
  }

  late Completer<void> _initRuntimeCompleter = Completer<void>();

  late final prefillSpeed = qs<double>(.0);
  late final decodeSpeed = qs<double>(.0);
  late final argumentsPanelShown = qs(false);

  late final arguments = qsff<Argument, double>((ref, argument) {
    return argument.defaults;
  });

  late final reasoning = qp((ref) => ref.watch(_thinkingMode).hasThinkTag);
  late final thinkingMode = qp((ref) => ref.watch(_thinkingMode));
  late final _thinkingMode = qs<ThinkingMode>(const thinking_mode.Lighting());

  ThinkingMode reasoningOnOrder = const thinking_mode.Free();
  ThinkingMode reasoningOffOrder = const thinking_mode.Lighting();

  /// 模型是否已加载
  late final loaded = qp((ref) {
    final currentModel = ref.watch(this.currentModel);
    return currentModel != null;
  });

  late final currentModel = qs<FileInfo?>(null);

  late final currentWorldType = qs<WorldType?>(null);

  late final currentGroupInfo = qs<GroupInfo?>(null);

  late final loading = qp((ref) {
    return ref.watch(_loading);
  });

  late final _loading = qs(false);

  late final argumentUpdatingDebouncer = Debouncer(milliseconds: 300);

  Timer? _getTokensTimer;

  late final socName = qs("");
  late final socBrand = qs<SocBrand>(SocBrand.unknown);

  late final _qnnLibsCopied = qs(false);

  Timer? _ttsPerformanceTimer;

  // TODO: Use it @WangCe
  late final receiving = qs(false);
}

extension $RWKVLoad on _RWKV {
  FV loadWorldVision({
    required String modelPath,
    required String encoderPath,
    required Backend backend,
    required bool enableReasoning,
  }) async {
    qq;
    _loading.q = true;
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/b_rwkv_vocab_v20230424.txt");

    await _ensureQNNCopied();

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      try {
        send(to_rwkv.ReleaseWhisperEncoder());
        send(to_rwkv.ReleaseModel());
        final startMS = HF.debugShorterMS;
        await reInitRuntime(backend: backend, modelPath: modelPath, tokenizerPath: tokenizerPath);
        final endMS = HF.debugShorterMS;
        qqr("initRuntime done in ${endMS - startMS}ms");
      } catch (e) {
        qqe("initRuntime failed: $e");
        if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
        Alert.error("Failed to load model: $e");
        return;
      }
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
        latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      qqq("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    send(to_rwkv.GetLatestRuntimeAddress());

    send(to_rwkv.LoadVisionEncoder(encoderPath));
    await setModelConfig(
      enableReasoning: enableReasoning,
      preferChinese: false,
      setPrompt: false,
    );
    await resetSamplerParams(enableReasoning: enableReasoning);
    await resetMaxLength(enableReasoning: enableReasoning);
    send(to_rwkv.SetEosToken("\x17"));
    send(to_rwkv.SetBosToken("\x16"));
    send(to_rwkv.SetTokenBanned([0]));
    _loading.q = false;
  }

  FV loadWorldEngAudioQA({
    required String modelPath,
    required String encoderPath,
    required Backend backend,
  }) async {
    qq;
    _loading.q = true;
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/b_rwkv_vocab_v20230424.txt");

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      send(to_rwkv.ReleaseVisionEncoder());
      send(to_rwkv.ReleaseModel());
      final startMS = HF.debugShorterMS;
      await reInitRuntime(backend: backend, modelPath: modelPath, tokenizerPath: tokenizerPath);
      final endMS = HF.debugShorterMS;
      qqr("initRuntime done in ${endMS - startMS}ms");
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
        latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      qqq("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    send(to_rwkv.GetLatestRuntimeAddress());

    send(to_rwkv.LoadWhisperEncoder(encoderPath));
    await setModelConfig(
      enableReasoning: false,
      preferChinese: false,
      setPrompt: false,
    );
    await resetSamplerParams(enableReasoning: false);
    await resetMaxLength(enableReasoning: false);
    send(to_rwkv.SetEosToken("\x17"));
    send(to_rwkv.SetBosToken("\x16"));
    send(to_rwkv.SetTokenBanned([0]));
    send(to_rwkv.SetUserRole(""));
    _loading.q = false;
  }

  FV loadTTSModels({
    required String modelPath,
    required Backend backend,
    required bool enableReasoning,
    required String campPlusPath,
    required String flowEncoderPath,
    required String flowDecoderEstimatorPath,
    required String hiftGeneratorPath,
    required String speechTokenizerPath,
  }) async {
    qq;
    _loading.q = true;
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/b_rwkv_vocab_v20230424.txt");

    await _ensureQNNCopied();

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      try {
        send(to_rwkv.ReleaseTTSModels());
        final startMS = HF.debugShorterMS;
        await reInitRuntime(backend: backend, modelPath: modelPath, tokenizerPath: tokenizerPath);
        final endMS = HF.debugShorterMS;
        qqr("initRuntime done in ${endMS - startMS}ms");
      } catch (e) {
        qqe("initRuntime failed: $e");
        if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
        Alert.error("Failed to load model: $e");
        return;
      }
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
        latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      qqq("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    send(to_rwkv.GetLatestRuntimeAddress());

    if (_ttsPerformanceTimer != null) {
      _ttsPerformanceTimer!.cancel();
      _ttsPerformanceTimer = null;
    }

    _ttsPerformanceTimer = Timer.periodic(225.ms, (timer) async {
      send(to_rwkv.GetPrefillAndDecodeSpeed());
    });

    final ttsTokenizerPath = await fromAssetsToTemp("assets/config/chat/b_rwkv_vocab_v20230424_tts.txt");

    send(
      to_rwkv.LoadTTSModels(
        campPlusPath: campPlusPath,
        flowDecoderEstimatorPath: flowDecoderEstimatorPath,
        flowEncoderPath: flowEncoderPath,
        hiftGeneratorPath: hiftGeneratorPath,
        speechTokenizerPath: speechTokenizerPath,
        ttsTokenizerPath: ttsTokenizerPath,
      ),
    );

    final ttsTextNormalizerDatePath = await fromAssetsToTemp("assets/config/chat/date-zh.fst");
    final ttsTextNormalizerNumberPath = await fromAssetsToTemp("assets/config/chat/number-zh.fst");
    final ttsTextNormalizerPhonePath = await fromAssetsToTemp("assets/config/chat/phone-zh.fst");
    // note: order matters here
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerDatePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerPhonePath));
    send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerNumberPath));

    _loading.q = false;
  }

  FV loadChat({
    required String modelPath,
    required Backend backend,
    required bool enableReasoning,
  }) async {
    qq;
    _loading.q = true;
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    final tokenizerPath = await fromAssetsToTemp(Assets.config.chat.bRwkvVocabV20230424);

    await _ensureQNNCopied();

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      try {
        final startMS = HF.debugShorterMS;
        await reInitRuntime(backend: backend, modelPath: modelPath, tokenizerPath: tokenizerPath);
        final endMS = HF.debugShorterMS;
        qqr("initRuntime done in ${endMS - startMS}ms");
      } catch (e) {
        qqe("initRuntime failed: $e");
        if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
        Alert.error("Failed to load model: $e");
        return;
      }
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
        latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      qqq("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    send(to_rwkv.GetLatestRuntimeAddress());

    P.app.demoType.q = DemoType.chat;
    await setModelConfig(enableReasoning: enableReasoning);
    await resetSamplerParams(enableReasoning: enableReasoning);
    await resetMaxLength(enableReasoning: enableReasoning);
    send(to_rwkv.GetSamplerParams());
    _loading.q = false;
  }

  FV loadOthello() async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    late final String modelPath;
    late final Backend backend;

    final tokenizerPath = await fromAssetsToTemp(Assets.config.othello.bOthelloVocab);

    if (Platform.isIOS || Platform.isMacOS) {
      modelPath = await fromAssetsToTemp(Assets.model.othello.rwkv7Othello26mL10D448Extended);
      backend = Backend.webRwkv;
    } else {
      modelPath = await fromAssetsToTemp(Assets.model.othello.rwkv7Othello26mL10D448ExtendedNcnnBin);
      await fromAssetsToTemp(Assets.model.othello.rwkv7Othello26mL10D448ExtendedNcnnParam);
      backend = Backend.ncnn;
    }

    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      send(
        to_rwkv.ReInitRuntime(
          modelPath: modelPath,
          backend: backend,
          tokenizerPath: tokenizerPath,
          latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
        ),
      );
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
        latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      qqq("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    send(to_rwkv.GetLatestRuntimeAddress());

    P.app.demoType.q = DemoType.othello;

    send(to_rwkv.SetMaxLength(64000));
    send(
      to_rwkv.SetSamplerParams(
        temperature: 1.0,
        topK: 1,
        topP: 1.0,
        presencePenalty: .0,
        frequencyPenalty: .0,
        penaltyDecay: .0,
      ),
    );
    send(to_rwkv.SetGenerationStopToken(0));
    send(to_rwkv.ClearStates());
  }

  FV loadSudoku({
    required String modelPath,
    required Backend backend,
  }) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/b_sudoku_vocab.txt");
    final data = await rootBundle.load("assets/config/chat/sudoku_rwkv_20241120_ncnn.param");
    final paramFile = File(P.app.documentsDir.q!.path + "/sudoku_rwkv_20241120_ncnn.param");
    await paramFile.writeAsBytes(data.buffer.asUint8List());

    await _ensureQNNCopied();
    final rootIsolateToken = RootIsolateToken.instance;

    if (_sendPort != null) {
      send(
        to_rwkv.ReInitRuntime(
          modelPath: modelPath,
          backend: backend,
          tokenizerPath: tokenizerPath,
          latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
        ),
      );
    } else {
      final options = StartOptions(
        modelPath: modelPath,
        tokenizerPath: tokenizerPath,
        backend: backend,
        sendPort: _receivePort.sendPort,
        rootIsolateToken: rootIsolateToken!,
        latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
      );
      await RWKVMobile().runIsolate(options);
    }

    while (_sendPort == null) {
      qqq("waiting for sendPort...");
      await Future.delayed(const Duration(milliseconds: 50));
    }

    send(to_rwkv.GetLatestRuntimeAddress());

    P.app.demoType.q = DemoType.sudoku;

    send(to_rwkv.SetMaxLength(6000_000));
    send(
      to_rwkv.SetSamplerParams(
        temperature: 1.0,
        topK: 1,
        topP: 1.0,
        presencePenalty: .0,
        frequencyPenalty: .0,
        penaltyDecay: .0,
      ),
    );
    send(to_rwkv.SetGenerationStopToken(_Sudoku.tokenStop));
    send(to_rwkv.ClearStates());
    _loading.q = false;
  }
}

/// Public methods
extension $RWKV on _RWKV {
  FV setAudioPrompt({required String path}) async {
    send(to_rwkv.SetAudioPrompt(path));
  }

  FV sendMessages(List<String> messages) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;

    qqq("message lengths: ${messages.m((e) => e.length)}");

    final sendPort = _sendPort;

    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }

    send(to_rwkv.ChatAsync(messages, reasoning: thinkingMode.q.hasThinkTag));

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
    }

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      send(to_rwkv.GetResponseBufferContent());
      if (HF.randomBool(truePercentage: .5)) send(to_rwkv.GetIsGenerating());
      if (HF.randomBool(truePercentage: .5)) send(to_rwkv.GetPrefillAndDecodeSpeed());
    });
  }

  /// 直接在 ffi+cpp 线程中进行推理工作
  FV generate(String prompt) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    final sendPort = _sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }
    send(to_rwkv.SudokuOthelloGenerate(prompt));

    if (_getTokensTimer != null) {
      _getTokensTimer!.cancel();
    }

    _getTokensTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      send(to_rwkv.GetResponseBufferIds());
      send(to_rwkv.GetPrefillAndDecodeSpeed());
      send(to_rwkv.GetResponseBufferContent());
      await Future.delayed(const Duration(milliseconds: 1000));
      send(to_rwkv.GetIsGenerating());
    });
  }

  FV setImagePath({required String path}) async {
    send(to_rwkv.SetVisionPrompt(path));
  }

  FV clearStates() async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    final sendPort = _sendPort;
    if (sendPort == null) {
      qqw("sendPort is null");
      return;
    }
    send(to_rwkv.ClearStates());
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

  FV stop() async => send(to_rwkv.Stop());

  FV reInitRuntime({
    required String modelPath,
    required Backend backend,
    required String tokenizerPath,
  }) async {
    prefillSpeed.q = 0;
    decodeSpeed.q = 0;
    _initRuntimeCompleter = Completer<void>();
    send(
      to_rwkv.ReInitRuntime(
        modelPath: modelPath,
        backend: backend,
        tokenizerPath: tokenizerPath,
        latestRuntimeAddress: P.preference.latestRuntimeAddress.q,
      ),
    );
    return _initRuntimeCompleter.future;
  }

  FV setModelConfig({
    ThinkingMode? thinkingMode,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? enableReasoning,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? preferChinese,
    @Deprecated("Use thinkingMode instead, 不能排除之后突然来个不支持 <think> 的模型, 所以先不删除") bool? preferPseudo,
    bool setPrompt = true,
  }) async {
    qqr(thinkingMode);
    _thinkingMode.q = thinkingMode ?? const thinking_mode.Lighting();

    final finalPrompt = switch (_thinkingMode) {
      thinking_mode.PreferChinese() => Config.promptCN,
      _ => Config.prompt,
    };

    if (setPrompt) {
      qqq("setPrompt: $finalPrompt");
      send(to_rwkv.SetPrompt(_thinkingMode.q.hasThinkTag ? "<EOD>" : finalPrompt));
    }

    switch (_thinkingMode.q) {
      case thinking_mode.Lighting():
      case thinking_mode.Free():
      case thinking_mode.PreferChinese():
        final thinkingToken = _thinkingMode.q.header;
        qqq("setThinkingToken: $thinkingToken");
        send(to_rwkv.SetThinkingToken(thinkingToken));
      case thinking_mode.None():
        break;
    }
  }

  FV resetSamplerParams({required bool enableReasoning}) async {
    await syncSamplerParams(
      temperature: enableReasoning ? Argument.temperature.reasonDefaults : Argument.temperature.defaults,
      topK: enableReasoning ? Argument.topK.reasonDefaults : Argument.topK.defaults,
      topP: enableReasoning ? Argument.topP.reasonDefaults : Argument.topP.defaults,
      presencePenalty: enableReasoning ? Argument.presencePenalty.reasonDefaults : Argument.presencePenalty.defaults,
      frequencyPenalty: enableReasoning ? Argument.frequencyPenalty.reasonDefaults : Argument.frequencyPenalty.defaults,
      penaltyDecay: enableReasoning ? Argument.penaltyDecay.reasonDefaults : Argument.penaltyDecay.defaults,
    );
  }

  FV syncSamplerParams({
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

    send(
      to_rwkv.SetSamplerParams(
        temperature: _intIfFixedDecimalsIsZero(Argument.temperature),
        topK: _intIfFixedDecimalsIsZero(Argument.topK),
        topP: _intIfFixedDecimalsIsZero(Argument.topP),
        presencePenalty: _intIfFixedDecimalsIsZero(Argument.presencePenalty),
        frequencyPenalty: _intIfFixedDecimalsIsZero(Argument.frequencyPenalty),
        penaltyDecay: _intIfFixedDecimalsIsZero(Argument.penaltyDecay),
      ),
    );

    if (kDebugMode) send(to_rwkv.GetSamplerParams());
  }

  FV resetMaxLength({required bool enableReasoning}) async {
    await syncMaxLength(
      maxLength: enableReasoning ? Argument.maxLength.reasonDefaults : Argument.maxLength.defaults,
    );
  }

  FV syncMaxLength({num? maxLength}) async {
    if (maxLength != null) arguments(Argument.maxLength).q = maxLength.toDouble();
    send(to_rwkv.SetMaxLength(_intIfFixedDecimalsIsZero(Argument.maxLength).toInt()));
  }

  void onThinkModeTyped() async {
    final receiving = P.chat.receivingTokens.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection()) return;

    P.app.hapticLight();
    final current = thinkingMode.q;
    switch (current) {
      case thinking_mode.Lighting():
        setModelConfig(thinkingMode: reasoningOnOrder);
        if (reasoningOnOrder is thinking_mode.Free) Alert.success(S.current.reasoning_enabled);
        if (reasoningOnOrder is thinking_mode.PreferChinese) Alert.success(S.current.prefer_chinese);
        reasoningOffOrder = const thinking_mode.Lighting();
      case thinking_mode.Free():
        setModelConfig(thinkingMode: reasoningOffOrder);
        reasoningOnOrder = const thinking_mode.Free();
      case thinking_mode.PreferChinese():
        setModelConfig(thinkingMode: reasoningOffOrder);
        reasoningOnOrder = const thinking_mode.PreferChinese();
      case thinking_mode.None():
        setModelConfig(thinkingMode: reasoningOnOrder);
        reasoningOffOrder = const thinking_mode.None();
    }
  }

  void onSecondaryOptionsTyped() async {
    final receiving = P.chat.receivingTokens.q;
    if (receiving) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    if (!checkModelSelection()) return;

    final current = thinkingMode.q;
    P.app.hapticLight();
    switch (current) {
      case thinking_mode.Lighting():
        setModelConfig(thinkingMode: const thinking_mode.None());
        reasoningOffOrder = const thinking_mode.None();
      case thinking_mode.Free():
        setModelConfig(thinkingMode: const thinking_mode.PreferChinese());
        Alert.success(S.current.prefer_chinese);
        reasoningOnOrder = const thinking_mode.PreferChinese();
      case thinking_mode.PreferChinese():
        setModelConfig(thinkingMode: const thinking_mode.Free());
        reasoningOnOrder = const thinking_mode.Free();
      case thinking_mode.None():
        setModelConfig(thinkingMode: const thinking_mode.Lighting());
        reasoningOffOrder = const thinking_mode.Lighting();
    }
  }
}

/// Private methods
extension _$RWKV on _RWKV {
  FV _init() async {
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
  }

  num _intIfFixedDecimalsIsZero(Argument argument) {
    if (argument.fixedDecimals == 0) {
      return arguments(argument).q.toInt();
    } else {
      return double.parse(arguments(argument).q.toStringAsFixed(argument.fixedDecimals));
    }
  }

  FV _onPageKeyChanged() async {
    final pageKey = P.app.pageKey.q;
    switch (pageKey) {
      case PageKey.othello:
        await loadOthello();
        break;
      case PageKey.chat:
      case PageKey.sudoku:
        break;
    }
  }

  // ignore: unused_element
  FV _loadFifthteenPuzzle() async {
    throw "Not support, please contact the developer";
  }

  // ignore: unused_element
  FV _loadSudoku() async {
    throw "Not support, please contact the developer";
  }

  void _onMessage(message) {
    if (message is SendPort) {
      _sendPort = message;
      return;
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

  void _handleFromRWKV(from_rwkv.FromRWKV message) {
    _messagesController.add(message);
    switch (message) {
      case from_rwkv.ReInitSteps res:
        final done = res.done;
        final success = res.success;
        final error = res.error;
        final step = res.step;

        if (done) {
          if (success == true) {
            if (_initRuntimeCompleter.isCompleted) return;
            _initRuntimeCompleter.complete();
          } else if (success == false) {
            qqe("initRuntime failed: $error");
            final exception = Exception("initRuntime failed: $error");
            if (!kDebugMode) Sentry.captureException(exception, stackTrace: StackTrace.current);
            if (_initRuntimeCompleter.isCompleted) return;
            _initRuntimeCompleter.completeError(exception);
          } else {}
        }

      case from_rwkv.LatestRuntimeAddress response:
        P.preference._saveLatestRuntimeAddress(response.latestRuntimeAddress);

      case from_rwkv.Error response:
        if (kDebugMode) {
          String errorLog = "error: ${response.message}";
          if (message.to != null) errorLog += " in ${message.to.runtimeType}";
          if (message.to?.requestId != null) errorLog += " requestId: ${message.to?.requestId}";
          qqe(errorLog);
        }
        Alert.error(response.message);

      case from_rwkv.Speed response:
        prefillSpeed.q = response.prefillSpeed;
        decodeSpeed.q = response.decodeSpeed;

      case from_rwkv.StreamResponse response:
        final decodeSpeed = response.decodeSpeed;
        final prefillSpeed = response.prefillSpeed;
        if (decodeSpeed != -1.0) this.decodeSpeed.q = decodeSpeed;
        if (prefillSpeed != -1.0) this.prefillSpeed.q = prefillSpeed;

      default:
    }
  }

  FV _ensureQNNCopied() async {
    if (Platform.isAndroid && !_qnnLibsCopied.q) {
      // TODO: @Molly better solution here
      // TODO: @wangce Ask Molly why there are "better" solution here
      final qnnLibList = {
        "libQnnHtp.so",
        "libQnnHtpNetRunExtensions.so",
        "libQnnHtpV68Stub.so",
        "libQnnHtpV69Stub.so",
        "libQnnHtpV73Stub.so",
        "libQnnHtpV75Stub.so",
        "libQnnHtpV79Stub.so",
        "libQnnHtpV68Skel.so",
        "libQnnHtpV69Skel.so",
        "libQnnHtpV73Skel.so",
        "libQnnHtpV75Skel.so",
        "libQnnHtpV79Skel.so",
        "libQnnHtpPrepare.so",
        "libQnnSystem.so",
        "libQnnRwkvWkvOpPackageV68.so",
        "libQnnRwkvWkvOpPackageV69.so",
        "libQnnRwkvWkvOpPackageV73.so",
        "libQnnRwkvWkvOpPackageV75.so",
        "libQnnRwkvWkvOpPackageV79.so",
      };
      for (final lib in qnnLibList) {
        await fromAssetsToTemp("assets/lib/qnn/$lib", targetPath: "assets/lib/$lib");
      }
      _qnnLibsCopied.q = true;
    }
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
