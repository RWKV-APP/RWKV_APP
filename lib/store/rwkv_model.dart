part of 'p.dart';

class _RWKVModel {
  Timer? _ttsPerformanceTimer;

  /// 已经加载到内存中的模型，key 为 FuncType，value 为模型 ID
  late final allLoaded = qs<Map<FileInfo, int>>({});

  late final usingPth = qp<bool?>((ref) {
    final loadedModels = ref.watch(P.rwkvModel.allLoaded);

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
  late final activeLoadingFile = qs<FileInfo?>(null);

  /// 模型加载完成器, 用于等待模型加载完成
  late final modelLoadingCompleters = qs<Map<FileInfo, Completer<int?>>>({});

  /// 模型释放完成器, 用于等待模型释放完成
  late final modelReleasingCompleters = qs<Map<int, Completer<bool>>>({});

  /// 模型解压状态, 用于等待模型解压完成
  late final unzippingStatus = qsf<FileInfo, bool>(false);

  late final unzipping = qs(false);

  late final loading = qp<bool>((ref) {
    final loadingStatus = ref.watch(P.rwkvModel.loadingStatus);
    return loadingStatus.values.any((e) {
      return e == LoadingStatus.loading || e == LoadingStatus.loadModelWithExtra || e == LoadingStatus.setQnnLibraryPath;
    });
  });

  late final activeLoadingProgress = qp<double?>((ref) {
    final activeLoadingFile = ref.watch(P.rwkvModel.activeLoadingFile);
    if (activeLoadingFile == null) return null;
    final loadingProgress = ref.watch(P.rwkvModel.loadingProgress);
    return loadingProgress[activeLoadingFile];
  });

  late final loadedModelsCount = qp<int>((ref) {
    final loadedModels = ref.watch(P.rwkvModel.allLoaded);
    return loadedModels.length;
  });

  late final latest = qp<FileInfo?>((ref) {
    final loadedModels = ref.watch(P.rwkvModel.allLoaded);
    final m = loadedModels.keys.lastOrNull;
    if (m?.weightType == .roleplay) {
      return null;
    }
    return m;
  });

  late final latestId = qp<int?>((ref) {
    final latestModel = ref.watch(P.rwkvModel.latest);
    final loadedModels = ref.watch(P.rwkvModel.allLoaded);
    if (latestModel == null || loadedModels.isEmpty) return null;
    return loadedModels[latestModel];
  });

  /// 模型是否已加载
  late final loaded = qp<bool>((ref) {
    final currentModel = ref.watch(P.rwkvModel.latest);
    return currentModel != null;
  });
}

extension $RWKVModel on _RWKVModel {
  Future<(SendPort?, int?)> loadChat({
    required FileInfo fileInfo,
    bool Function()? shouldKeepLoadedModel,
  }) async {
    qq;
    P.rwkvGeneration.prefillSpeed.q = 0;
    P.rwkvGeneration.decodeSpeed.q = 0;
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

    await P.rwkvBackend._ensureQNNCopied();
    await P.rwkvBridge._createRWKVIsolateIfNeeded();
    if (!_isLoadedOrLoading(fileInfo)) {
      await _releaseModelByWeightTypeIfNeeded(weightType: .chat);
      await _releaseModelByWeightTypeIfNeeded(weightType: .roleplay);
    }

    final modelID = await _loadModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      fileInfo: fileInfo,
    );
    if (modelID == null) {
      final msg = "Failed to load model, modelID is null";
      qqw(msg);
      return (P.rwkvBridge.sendPort, null);
    }
    if (shouldKeepLoadedModel != null && !shouldKeepLoadedModel()) {
      await _releaseLoadedModelByFileInfoIfNeeded(fileInfo);
      return (P.rwkvBridge.sendPort, null);
    }
    P.app.demoType.q = .chat;
    allLoaded.q = {
      ...allLoaded.q,
      fileInfo: modelID,
    };

    await P.rwkvParams.setModelConfig(thinkingMode: P.rwkvParams.thinkingModeForCurrentChatConfig());
    await P.rwkvParams.resetSamplerParams(enableReasoning: enableReasoning);
    await P.rwkvParams.resetMaxLength(enableReasoning: enableReasoning);
    // send(to_rwkv.GetSamplerParams()); NOTE: already get in resetSamplerParams, so no need here
    P.rwkvParams._syncMaxBatchCount();

    return (P.rwkvBridge.sendPort, modelID);
  }

  Future<int?> loadSee({
    required String modelPath,
    required String encoderPath,
    required Backend backend,
    required bool enableReasoning,
    required String? adapterPath,
    required FileInfo fileInfo,
    bool Function()? shouldKeepLoadedModel,
  }) async {
    qq;
    P.rwkvGeneration.prefillSpeed.q = 0;
    P.rwkvGeneration.decodeSpeed.q = 0;
    P.rwkvParams._thinkingMode.q = enableReasoning ? .free : .none;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/rwkv_vocab_v20230424.txt");

    await P.rwkvBackend._ensureQNNCopied();
    await P.rwkvBridge._createRWKVIsolateIfNeeded();
    if (!_isLoadedOrLoading(fileInfo)) {
      await _releaseModelByWeightTypeIfNeeded(weightType: .see);
    }

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
    if (shouldKeepLoadedModel != null && !shouldKeepLoadedModel()) {
      await _releaseLoadedModelByFileInfoIfNeeded(fileInfo);
      return null;
    }
    P.app.demoType.q = .see;
    allLoaded.q = {
      ...allLoaded.q,
      fileInfo: modelID,
    };

    if (adapterPath != null) {
      P.rwkvBridge.send(to_rwkv.LoadVisionEncoderAndAdapter(encoderPath, adapterPath, modelID: modelID));
    } else {
      P.rwkvBridge.send(to_rwkv.LoadVisionEncoder(encoderPath, modelID: modelID));
    }

    await P.rwkvParams.setModelConfig(
      enableReasoning: enableReasoning,
      preferChinese: false,
      setPrompt: false,
      thinkingMode: P.rwkvParams._thinkingMode.q,
    );
    await P.rwkvParams.resetSamplerParams(enableReasoning: enableReasoning);
    await P.rwkvParams.resetMaxLength(enableReasoning: enableReasoning);
    P.rwkvBridge.send(to_rwkv.SetEosToken("\x17", modelID: modelID));
    P.rwkvBridge.send(to_rwkv.SetBosToken("\x16", modelID: modelID));
    P.rwkvBridge.send(to_rwkv.SetTokenBanned([0], modelID: modelID));

    return modelID;
  }

  Future<(SendPort?, int?)> loadTTS({
    required String modelPath,
    required String wav2vec2Path,
    required String detokenizePath,
    required String bicodecTokenzerPath,
    required Backend backend,
    required FileInfo fileInfo,
    bool Function()? shouldKeepLoadedModel,
  }) async {
    qq;
    P.rwkvGeneration.prefillSpeed.q = 0;
    P.rwkvGeneration.decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/vocab_talk.txt");

    await P.rwkvBackend._ensureQNNCopied();
    await P.rwkvBridge._createRWKVIsolateIfNeeded();
    if (!_isLoadedOrLoading(fileInfo)) {
      await _releaseModelByWeightTypeIfNeeded(weightType: .tts);
    }
    final modelID = await _loadModel(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      backend: backend,
      fileInfo: fileInfo,
    );

    if (modelID == null) {
      final msg = "Failed to load model, modelID is null";
      qqw(msg);
      return (P.rwkvBridge.sendPort, null);
    }
    if (shouldKeepLoadedModel != null && !shouldKeepLoadedModel()) {
      await _releaseLoadedModelByFileInfoIfNeeded(fileInfo);
      return (P.rwkvBridge.sendPort, null);
    }
    P.app.demoType.q = .tts;
    allLoaded.q = {
      ...allLoaded.q,
      fileInfo: modelID,
    };

    if (_ttsPerformanceTimer != null) {
      _ttsPerformanceTimer!.cancel();
      _ttsPerformanceTimer = null;
    }

    _ttsPerformanceTimer = Timer.periodic(225.ms, (timer) async {
      P.rwkvBridge.send(to_rwkv.GetPrefillAndDecodeSpeed(modelID: modelID));
    });

    P.rwkvBridge.send(
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
    P.rwkvBridge.send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerDatePath));
    P.rwkvBridge.send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerPhonePath));
    P.rwkvBridge.send(to_rwkv.LoadTTSTextNormalizer(ttsTextNormalizerNumberPath));
    return (P.rwkvBridge.sendPort, modelID);
  }

  Future<void> loadOthello() async {
    P.rwkvGeneration.prefillSpeed.q = 0;
    P.rwkvGeneration.decodeSpeed.q = 0;

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

    await P.rwkvBridge._createRWKVIsolateIfNeeded();
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
    allLoaded.q = {
      ...allLoaded.q,
      // TODO: fileInfo is null for othello
      // fileInfo: modelID,
    };

    P.rwkvBridge.send(to_rwkv.SetMaxLength(64000, modelID: modelID));
    P.rwkvBridge.send(
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
    P.rwkvBridge.send(to_rwkv.SetGenerationStopToken(0, modelID: modelID));
    P.rwkvBridge.send(to_rwkv.ClearStates(modelID: modelID));
  }

  Future<void> loadSudoku({
    required String modelPath,
    required Backend backend,
  }) async {
    P.rwkvGeneration.prefillSpeed.q = 0;
    P.rwkvGeneration.decodeSpeed.q = 0;

    final tokenizerPath = await fromAssetsToTemp("assets/config/chat/b_sudoku_vocab.txt");
    final data = await rootBundle.load("assets/config/chat/sudoku_rwkv_20241120_ncnn.param");
    final paramFile = File(join(P.app.effectiveDocumentsDir.q!.path, "sudoku_rwkv_20241120_ncnn.param"));
    await paramFile.writeAsBytes(data.buffer.asUint8List());

    await P.rwkvBackend._ensureQNNCopied();
    await P.rwkvBridge._createRWKVIsolateIfNeeded();
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
    allLoaded.q = {
      ...allLoaded.q,
      // TODO: fileInfo is null for sudoku
      // fileInfo: modelID,
    };

    P.rwkvBridge.send(to_rwkv.SetMaxLength(6000_000, modelID: modelID));
    P.rwkvBridge.send(
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
    P.rwkvBridge.send(to_rwkv.SetGenerationStopToken(_Sudoku.tokenStop, modelID: modelID));
    P.rwkvBridge.send(to_rwkv.ClearStates(modelID: modelID));
  }

  /// 加载指定 pth 权重并完成聊天用配置（角色、batch、thinkingMode、GetSupportedBatchSizes）。
  /// 供 UI 在「Start to Chat」时调用；成功/失败在内部用 Alert.success / Alert.error 处理。
  Future<void> startPthForChat(FileInfo fileInfo) async {
    qq;
    if (fileInfo.backend == null) {
      Alert.error("Backend is null");
      return;
    }
    try {
      await P.rwkvGeneration.clearStates();
      await loadChat(fileInfo: fileInfo);
    } catch (e) {
      Alert.error(e.toString());
      return;
    }
    final batchAllowed = fileInfo.supportsBatchInference;
    if (!batchAllowed) {
      if (P.chat.responseStyle.q.activeCount > 1) {
        P.chat.resetResponseStyle();
      } else {
        P.chat.batchEnabled.q = false;
        P.chat.batchCount.q = Argument.batchCount.defaults.toInt();
      }
    }

    final modelID = findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      Alert.error("findModelIDByWeightType(chat) returned null");
      return;
    }

    final isTranslate = fileInfo.tags.contains("translate");
    if (isTranslate) {
      if (P.translator.enToZh.q) {
        P.rwkvBridge.send(to_rwkv.SetUserRole("English", modelID: modelID));
        P.rwkvBridge.send(to_rwkv.SetResponseRole(responseRole: "Chinese", modelID: modelID));
      } else {
        P.rwkvBridge.send(to_rwkv.SetUserRole("Chinese", modelID: modelID));
        P.rwkvBridge.send(to_rwkv.SetResponseRole(responseRole: "English", modelID: modelID));
      }
      await P.rwkvParams.setModelConfig(thinkingMode: .none, prompt: "<EOD>", setPrompt: true);
      P.apiServer.start();
    } else {
      P.rwkvBridge.send(to_rwkv.SetUserRole("User", modelID: modelID));
      P.rwkvBridge.send(to_rwkv.SetResponseRole(responseRole: "Assistant", modelID: modelID));
    }

    if (!isTranslate) {
      P.rwkvParams.setModelConfig(thinkingMode: P.rwkvParams.thinkingModeForCurrentChatConfig());
    }

    for (int i = 0; i < 3; i++) {
      unawaited(
        _requestSupportedBatchSizesLater(
          delay: Duration(milliseconds: 500 * i),
          modelID: modelID,
        ),
      );
    }
    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
  }

  int? findModelIDByWeightType({required WeightType weightType}) {
    final loaded = allLoaded.q.entries.firstWhereOrNull((e) => e.key.weightType == weightType);

    final value = loaded?.value;

    if (value == null) {
      final msg = "model id for weight type $weightType, maybe model is not loaded";
      qqq(msg);
    }

    return value;
  }

  Future<int?> _loadModel({
    required String modelPath,
    required String tokenizerPath,
    required Backend backend,
    required FileInfo fileInfo,
  }) async {
    final loadedModelID = allLoaded.q[fileInfo];
    if (loadedModelID != null) {
      qqq("model already loaded: ${fileInfo.name}, modelID: $loadedModelID");
      return loadedModelID;
    }

    final existingCompleter = modelLoadingCompleters.q[fileInfo];
    if (existingCompleter != null) {
      qqq("model already loading: ${fileInfo.name}");
      return await existingCompleter.future;
    }

    final currentStatus = loadingStatus.q[fileInfo];
    if (_isLoadingStatus(currentStatus)) {
      qqw("model loading status exists without completer: ${fileInfo.name}, status: $currentStatus");
    }

    final completer = Completer<int?>();
    activeLoadingFile.q = fileInfo;
    modelLoadingCompleters.q = {...modelLoadingCompleters.q, fileInfo: completer};
    final shouldForceLlamaCppNGpuLayersToZero = _shouldForceLlamaCppNGpuLayersToZero(
      backend: backend,
    );
    final req = shouldForceLlamaCppNGpuLayersToZero
        ? to_rwkv.LoadRWKVModel(
            modelPath: modelPath,
            backend: backend,
            tokenizerPath: tokenizerPath,
            llamaCppNGpuLayers: 0,
            extra: fileInfo,
          )
        : to_rwkv.LoadRWKVModel(
            modelPath: modelPath,
            backend: backend,
            tokenizerPath: tokenizerPath,
            extra: fileInfo,
          );
    P.rwkvBridge.send(req);
    loadingStatus.q = {...loadingStatus.q, fileInfo: .loading};
    loadingProgress.q = {...loadingProgress.q, fileInfo: 0.0};
    try {
      final modelID = await completer.future;
      // 如果我们得到的 modelID 为 null, 则表示加载失败
      return modelID;
    } finally {
      final nextCompleters = {...modelLoadingCompleters.q};
      if (nextCompleters[fileInfo] == completer) {
        nextCompleters.remove(fileInfo);
        modelLoadingCompleters.q = nextCompleters;
      }
    }
  }

  bool _isLoadedOrLoading(FileInfo fileInfo) {
    if (allLoaded.q.containsKey(fileInfo)) {
      return true;
    }
    if (modelLoadingCompleters.q.containsKey(fileInfo)) {
      return true;
    }
    return _isLoadingStatus(loadingStatus.q[fileInfo]);
  }

  bool _isLoadingStatus(LoadingStatus? status) {
    return status == .loading || status == .loadModelWithExtra || status == .setQnnLibraryPath;
  }

  bool _shouldForceLlamaCppNGpuLayersToZero({required Backend backend}) {
    if (backend != Backend.llamacpp) {
      return false;
    }
    if (!Platform.isWindows) {
      return false;
    }
    if (P.rwkvBackend.socBrand.q == SocBrand.snapdragon) {
      return true;
    }

    final lowerCpuName = P.telemetry._cpuName.q.toLowerCase();
    if (lowerCpuName.contains('snapdragon')) {
      return true;
    }
    if (lowerCpuName.contains('qualcomm')) {
      return true;
    }
    return false;
  }

  Future<void> _releaseModelById({required int modelID}) async {
    final existingCompleter = modelReleasingCompleters.q[modelID];
    if (existingCompleter != null) {
      qqw("modelReleasingCompleters already contains completer for modelID: $modelID");
      await existingCompleter.future;
      return;
    }
    qqq("releasing model by id: $modelID");
    final completer = Completer<bool>();
    modelReleasingCompleters.q = {...modelReleasingCompleters.q, modelID: completer};
    final fileInfo = allLoaded.q.entries.firstWhereOrNull((e) => e.value == modelID)?.key;
    final req = to_rwkv.ReleaseRWKVModel(modelID: modelID, extra: fileInfo);
    P.rwkvBridge.send(req);
    final success = await completer.future;
    final nextCompleters = {...modelReleasingCompleters.q};
    nextCompleters.remove(modelID);
    modelReleasingCompleters.q = nextCompleters;
    if (success) {
      final nextLoaded = {...allLoaded.q};
      nextLoaded.remove(fileInfo);
      allLoaded.q = nextLoaded;
    }
  }

  Future<void> _releaseLoadedModelByFileInfoIfNeeded(FileInfo fileInfo) async {
    final modelID = allLoaded.q[fileInfo];
    if (modelID == null) {
      final msg = "ModelID is null, maybe model is not loaded: ${fileInfo.name}";
      qqq(msg);
      return;
    }

    if (rolePlayCurrentModel?.id == fileInfo.fileName) {
      rolePlayCurrentModel = null;
    }
    if (rolePlayTTSModel?.id == fileInfo.fileName) {
      rolePlayTTSModel = null;
    }

    if (fileInfo.weightType == .tts) {
      P.rwkvBridge.send(to_rwkv.ReleaseTTSModels());
    }

    await _releaseModelById(modelID: modelID);
  }

  Future<void> _releaseModelByWeightTypeIfNeeded({required WeightType weightType}) async {
    final loaded = allLoaded.q.entries.firstWhereOrNull((e) => e.key.weightType == weightType);
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

    await _releaseLoadedModelByFileInfoIfNeeded(fileInfo);
    final msg = "Released model $modelID for $weightType";
    qqr(msg);
  }

  Future<void> _releaseAllModels() async {
    P.rwkvContext.currentGroupInfo.q = null;
    P.rwkvContext.currentWorldType.q = null;
    rolePlayCurrentModel = null;
    rolePlayTTSModel = null;
    final loadedFiles = allLoaded.q.keys.toList();
    for (final fileInfo in loadedFiles) {
      await _releaseLoadedModelByFileInfoIfNeeded(fileInfo);
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

  void _handleLoadModelSteps(from_rwkv.LoadModelSteps response) {
    final req = response.req;

    late final FileInfo extra;
    final isLoadRequest = req is to_rwkv.LoadRWKVModel;

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

    if (status != .loading) {
      qqq("$name, modelID: $modelID, status: $status");
    }

    final modelLoadingCompleter = modelLoadingCompleters.q[extra];
    final modelReleasingCompleter = modelReleasingCompleters.q[modelID];

    switch (status) {
      case .loaded:
        if (modelID == null) {
          qqe("modelID is null,  but status is loaded, this should not happen");
          return;
        }
        allLoaded.q = {...allLoaded.q, extra: modelID};

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
    if (isLoadRequest) {
      final stillLoading = switch (status) {
        LoadingStatus.loading => true,
        LoadingStatus.loadModelWithExtra => true,
        LoadingStatus.setQnnLibraryPath => true,
        _ => false,
      };
      if (stillLoading) {
        activeLoadingFile.q = extra;
      } else if (activeLoadingFile.q == extra) {
        activeLoadingFile.q = null;
      }
    }
    loadingStatus.q = {...loadingStatus.q, extra: status};
  }

  Future<void> _requestSupportedBatchSizesLater({
    required Duration delay,
    required int modelID,
  }) async {
    await Future<void>.delayed(delay);
    P.rwkvBridge.send(to_rwkv.GetSupportedBatchSizes(modelID: modelID));
  }

  // ignore: unused_element
  Future<void> _loadFifthteenPuzzle() async {
    throw "Not support, please contact the developer";
  }

  // ignore: unused_element
  Future<void> _loadSudoku() async {
    throw "Not support, please contact the developer";
  }
}
