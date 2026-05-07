part of 'p.dart';

const String _lastModelByScenePreferenceKey = "halo_state.lastModelByScene.v1";

enum _AutoLoadScene {
  chat,
  neko,
  translator,
  talk,
  roleplayChat,
  roleplayTts,
}

class _RWKVAutoLoad {
  final Map<String, Future<bool>> _inFlight = {};

  late final lastModelByScene = qs<Map<String, Map<String, dynamic>>>({});
}

extension $RWKVAutoLoad on _RWKVAutoLoad {
  Future<void> _init() async {
    await _loadFromPreference();
    await _migrateLegacyPreference();
    P.app.pageKey.lb(_onPageKeyChanged);
  }

  Future<int?> loadSelectedChatModel({
    required FileInfo fileInfo,
    bool showSuccess = true,
  }) async {
    final scene = _chatSceneForCurrentPage(fileInfo);
    return await _loadChatModelForScene(
      scene: scene,
      fileInfo: fileInfo,
      showSuccess: showSuccess,
      saveScene: true,
      expectedPageKey: P.app.pageKey.q,
    );
  }

  Future<(SendPort?, int?)> loadRoleplayChatModel({
    required FileInfo fileInfo,
    required ModelStateFile? state,
  }) async {
    return await _loadRoleplayChatModel(
      fileInfo: fileInfo,
      state: state,
      saveScene: true,
      expectedPageKey: P.app.pageKey.q,
    );
  }

  Future<bool> loadSeeWorldModel({
    required WorldType worldType,
    required String modelFileName,
    bool showSuccess = true,
  }) async {
    return await _loadSeeWorldModel(
      worldType: worldType,
      modelFileName: modelFileName,
      showSuccess: showSuccess,
      saveScene: true,
      expectedPageKey: P.app.pageKey.q,
    );
  }

  Future<(SendPort?, int?)> loadTtsCoreForCurrentScene({
    required FileInfo fileInfo,
    bool showSuccess = true,
  }) async {
    final scene = P.app.pageKey.q == .rolePlaying ? _AutoLoadScene.roleplayTts : _AutoLoadScene.talk;
    return await _loadTtsCoreForScene(
      scene: scene,
      fileInfo: fileInfo,
      showSuccess: showSuccess,
      saveScene: true,
      expectedPageKey: P.app.pageKey.q,
    );
  }

  Future<bool> restoreForPage(PageKey pageKey) async {
    return switch (pageKey) {
      .chat => await _restoreChatScene(scene: .chat, pageKey: pageKey, showSelectorOnFailure: true),
      .neko => await _restoreNeko(pageKey: pageKey),
      .translator || .ocr => await _restoreChatScene(scene: .translator, pageKey: pageKey, showSelectorOnFailure: true),
      .see => await _restoreSee(pageKey: pageKey),
      .talk => await _restoreTalk(pageKey: pageKey),
      .rolePlaying => await _restoreRoleplay(pageKey: pageKey),
      _ => false,
    };
  }

  FileInfo? visibleActiveLoadingFileForPage({
    required FileInfo? fileInfo,
    required PageKey pageKey,
    required DemoType preferredDemoType,
  }) {
    if (fileInfo == null) return null;
    if (!_isFileForPage(fileInfo: fileInfo, pageKey: pageKey, preferredDemoType: preferredDemoType)) return null;
    return fileInfo;
  }

  FileInfo? visibleCurrentModelForPage({
    required FileInfo? fileInfo,
    required PageKey pageKey,
    required DemoType preferredDemoType,
  }) {
    if (fileInfo == null) return null;
    if (!_isFileForPage(fileInfo: fileInfo, pageKey: pageKey, preferredDemoType: preferredDemoType)) return null;
    return fileInfo;
  }

  GroupInfo? visibleGroupInfoForPage({
    required GroupInfo? groupInfo,
    required PageKey pageKey,
    required DemoType preferredDemoType,
  }) {
    if (pageKey != .talk) return null;
    if (preferredDemoType != .tts) return null;
    return groupInfo;
  }
}

extension _$RWKVAutoLoad on _RWKVAutoLoad {
  void _onPageKeyChanged(PageKey? previous, PageKey next) {
    switch (next) {
      case .chat:
      case .neko:
      case .translator:
      case .ocr:
      case .see:
      case .talk:
      case .rolePlaying:
        unawaited(_restorePageLater(next));
        break;
      default:
        break;
    }
  }

  Future<void> _restorePageLater(PageKey pageKey) async {
    await 500.msLater;
    if (P.app.pageKey.q != pageKey) return;
    await restoreForPage(pageKey);
  }

  Future<bool> _runOnce(String key, Future<bool> Function() createFn) async {
    final existing = _inFlight[key];
    if (existing != null) {
      return await existing;
    }

    final future = createFn();
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      if (_inFlight[key] == future) {
        _inFlight.remove(key);
      }
    }
  }

  Future<void> _loadFromPreference() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_lastModelByScenePreferenceKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final result = <String, Map<String, dynamic>>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! Map) continue;
        result[key] = Map<String, dynamic>.from(value);
      }
      lastModelByScene.q = result;
    } catch (e) {
      qqw("failed to load auto model preference: $e");
    }
  }

  Future<void> _migrateLegacyPreference() async {
    final next = {...lastModelByScene.q};
    bool changed = false;

    if (P.preference.lastChatModel.q case final Map<String, dynamic> lastChat) {
      final scene = _legacyChatScene(lastChat);
      final key = _sceneKey(scene);
      if (!next.containsKey(key)) {
        next[key] = {
          "fileName": lastChat["fileName"],
          "fileSize": lastChat["fileSize"],
          "updatedAt": DateTime.now().millisecondsSinceEpoch,
        };
        changed = true;
      }
    }

    if (P.preference.lastWorldModel.q case final Map<String, dynamic> lastWorld) {
      final worldTypeName = lastWorld["worldType"];
      final modelFileName = lastWorld["modelFileName"];
      if (worldTypeName is String && modelFileName is String) {
        final key = _seeSceneKeyByName(worldTypeName);
        if (!next.containsKey(key)) {
          next[key] = {
            "worldType": worldTypeName,
            "fileName": modelFileName,
            "updatedAt": DateTime.now().millisecondsSinceEpoch,
          };
          changed = true;
        }
      }
    }

    if (!changed) return;
    lastModelByScene.q = next;
    await _persist();
  }

  _AutoLoadScene _legacyChatScene(Map<String, dynamic> lastChat) {
    final savedFileName = lastChat["fileName"];
    final savedFileSize = lastChat["fileSize"];
    if (savedFileName is! String || savedFileSize is! int) {
      return .chat;
    }

    final fileInfo = P.remote.chatWeights.q.firstWhereOrNull((e) {
      return e.fileName == savedFileName && e.fileSize == savedFileSize;
    });
    if (fileInfo == null) return .chat;
    if (fileInfo.isNeko) return .neko;
    if (fileInfo.hasEffectiveTag("translate")) return .translator;
    return .chat;
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_lastModelByScenePreferenceKey, jsonEncode(lastModelByScene.q));
  }

  void _saveScene(String sceneKey, Map<String, dynamic> payload) {
    final next = {...lastModelByScene.q};
    next[sceneKey] = {
      ...payload,
      "updatedAt": DateTime.now().millisecondsSinceEpoch,
    };
    lastModelByScene.q = next;
    unawaited(_persist());
  }

  void _saveChatScene(_AutoLoadScene scene, FileInfo fileInfo) {
    _saveScene(_sceneKey(scene), {
      "fileName": fileInfo.fileName,
      "fileSize": fileInfo.fileSize,
    });

    if (scene == .chat || scene == .neko || scene == .translator) {
      P.preference.saveLastChatModel({
        "fileName": fileInfo.fileName,
        "fileSize": fileInfo.fileSize,
      });
    }
  }

  void _saveSeeScene({
    required WorldType worldType,
    required FileInfo fileInfo,
  }) {
    _saveScene(_seeSceneKey(worldType), {
      "worldType": worldType.name,
      "fileName": fileInfo.fileName,
      "fileSize": fileInfo.fileSize,
    });
    P.preference.saveLastWorldModel({
      "worldType": worldType.name,
      "modelFileName": fileInfo.fileName,
    });
  }

  void _saveRoleplayChatScene({
    required FileInfo fileInfo,
    required ModelStateFile? state,
  }) {
    _saveScene(_sceneKey(.roleplayChat), {
      "fileName": fileInfo.fileName,
      "fileSize": fileInfo.fileSize,
      if (state != null) "stateFileName": state.fileName,
      if (state != null) "stateFileSize": state.fileSize,
    });
  }

  String _sceneKey(_AutoLoadScene scene) {
    return scene.name;
  }

  String _seeSceneKey(WorldType worldType) {
    return _seeSceneKeyByName(worldType.name);
  }

  String _seeSceneKeyByName(String worldTypeName) {
    return "see.$worldTypeName";
  }

  _AutoLoadScene _chatSceneForCurrentPage(FileInfo fileInfo) {
    final pageKey = P.app.pageKey.q;
    if (pageKey == .rolePlaying) return .roleplayChat;
    if (pageKey == .neko || fileInfo.isNeko) return .neko;
    if (pageKey == .translator || pageKey == .ocr || fileInfo.hasEffectiveTag("translate")) return .translator;
    return .chat;
  }

  bool _isOtherModelLoading(FileInfo fileInfo) {
    final activeLoadingFile = P.rwkvModel.activeLoadingFile.q;
    if (activeLoadingFile == null || activeLoadingFile == fileInfo) return false;
    return P.rwkvModel.loading.q;
  }

  bool _isFileForPage({
    required FileInfo fileInfo,
    required PageKey pageKey,
    required DemoType preferredDemoType,
  }) {
    return switch (pageKey) {
      .chat => _isRegularChatFile(fileInfo),
      .neko => fileInfo.isNeko,
      .translator || .ocr => fileInfo.weightType == .chat && fileInfo.hasEffectiveTag("translate"),
      .see => fileInfo.weightType == .see || fileInfo.worldType != null,
      .talk => fileInfo.weightType == .tts || fileInfo.isTTS,
      .rolePlaying => _isRoleplayPageFile(fileInfo),
      _ => _isFileForDemoType(fileInfo: fileInfo, preferredDemoType: preferredDemoType),
    };
  }

  bool _isFileForDemoType({
    required FileInfo fileInfo,
    required DemoType preferredDemoType,
  }) {
    return switch (preferredDemoType) {
      .chat => _isRegularChatFile(fileInfo),
      .see => fileInfo.weightType == .see || fileInfo.worldType != null,
      .tts => fileInfo.weightType == .tts || fileInfo.isTTS,
      .fifthteenPuzzle || .othello || .sudoku => fileInfo.weightType?.name == preferredDemoType.name,
    };
  }

  bool _isRegularChatFile(FileInfo fileInfo) {
    if (fileInfo.weightType != .chat) return false;
    if (fileInfo.isNeko) return false;
    if (fileInfo.hasEffectiveTag("translate")) return false;
    return true;
  }

  bool _isRoleplayPageFile(FileInfo fileInfo) {
    if (fileInfo.weightType == .roleplay) return true;
    if (fileInfo.weightType == .tts || fileInfo.isTTS) return true;
    return fileInfo.state.isNotEmpty;
  }

  bool _isExpectedPageActive(PageKey? expectedPageKey) {
    if (expectedPageKey == null) return true;

    final currentPageKey = P.app.pageKey.q;
    if (currentPageKey == expectedPageKey) return true;
    if ((expectedPageKey == .translator || expectedPageKey == .ocr) && (currentPageKey == .translator || currentPageKey == .ocr)) {
      return true;
    }
    return false;
  }

  Future<bool> _waitForOtherModelLoading({
    required FileInfo fileInfo,
    required PageKey? expectedPageKey,
  }) async {
    while (true) {
      if (!_isExpectedPageActive(expectedPageKey)) return false;
      if (!_isOtherModelLoading(fileInfo)) return true;
      await 200.msLater;
    }
  }

  Future<bool> _prepareLoadedModelsForPage({
    required PageKey? expectedPageKey,
    required DemoType preferredDemoType,
  }) async {
    if (!_isExpectedPageActive(expectedPageKey)) return false;

    final pageKey = expectedPageKey ?? P.app.pageKey.q;
    final loadedFiles = P.rwkvModel.allLoaded.q.keys.toList();
    for (final fileInfo in loadedFiles) {
      if (_isFileForPage(fileInfo: fileInfo, pageKey: pageKey, preferredDemoType: preferredDemoType)) continue;
      await P.rwkvModel._releaseLoadedModelByFileInfoIfNeeded(fileInfo);
      if (!_isExpectedPageActive(expectedPageKey)) return false;
    }

    return true;
  }

  bool _isChatSceneLoaded(_AutoLoadScene scene) {
    final currentModel = P.rwkvModel.latest.q;
    if (currentModel == null) return false;

    return switch (scene) {
      .chat => !currentModel.isNeko && !currentModel.hasEffectiveTag("translate") && currentModel.weightType == .chat,
      .neko => currentModel.isNeko,
      .translator => currentModel.hasEffectiveTag("translate"),
      .talk || .roleplayChat || .roleplayTts => false,
    };
  }

  bool _isTtsLoaded() {
    return P.rwkvModel.allLoaded.q.keys.any((e) => e.isTTS);
  }

  bool _isSeeLoaded(WorldType? worldType) {
    return P.rwkvModel.allLoaded.q.keys.any((e) {
      if (e.worldType == null) return false;
      if (worldType == null) return true;
      return e.worldType == worldType;
    });
  }

  Future<int?> _loadChatModelForScene({
    required _AutoLoadScene scene,
    required FileInfo fileInfo,
    required bool showSuccess,
    required bool saveScene,
    required PageKey? expectedPageKey,
  }) async {
    if (fileInfo.backend == null) {
      Alert.error("Backend is null");
      return null;
    }

    final canContinueAfterLoading = await _waitForOtherModelLoading(
      fileInfo: fileInfo,
      expectedPageKey: expectedPageKey,
    );
    if (!canContinueAfterLoading) {
      return null;
    }

    final prepared = await _prepareLoadedModelsForPage(
      expectedPageKey: expectedPageKey,
      preferredDemoType: .chat,
    );
    if (!prepared) {
      return null;
    }
    if (!_isExpectedPageActive(expectedPageKey)) {
      return null;
    }

    await P.rwkvGeneration.clearStates();
    final (_, modelID) = await P.rwkvModel.loadChat(
      fileInfo: fileInfo,
      shouldKeepLoadedModel: () => _isExpectedPageActive(expectedPageKey),
    );
    if (modelID == null) return null;

    await _configureChatModel(fileInfo: fileInfo, modelID: modelID);
    if (saveScene) _saveChatScene(scene, fileInfo);
    if (showSuccess) Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    return modelID;
  }

  Future<void> _configureChatModel({
    required FileInfo fileInfo,
    required int modelID,
  }) async {
    final batchAllowed = fileInfo.supportsBatchInference;
    if (!batchAllowed) {
      if (P.chat.responseStyle.q.activeCount > 1) {
        P.chat.resetResponseStyle();
      } else {
        P.chat.batchEnabled.q = false;
        P.chat.batchCount.q = Argument.batchCount.defaults.toInt();
      }
    } else if (P.chat.responseStyle.q.activeCount > 1) {
      await P.chat._syncBatchStateForResponseStyle(activeCount: P.chat.responseStyle.q.activeCount);
    }

    final isTranslate = fileInfo.hasEffectiveTag("translate");
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
      await P.rwkvParams.setModelConfig(thinkingMode: P.rwkvParams.thinkingModeForCurrentChatConfig());
    }

    for (int i = 0; i < 3; i++) {
      unawaited(
        P.rwkvModel._requestSupportedBatchSizesLater(
          delay: Duration(milliseconds: 500 * i),
          modelID: modelID,
        ),
      );
    }
  }

  Future<bool> _restoreChatScene({
    required _AutoLoadScene scene,
    required PageKey pageKey,
    required bool showSelectorOnFailure,
  }) async {
    final sceneKey = _sceneKey(scene);
    return await _runOnce(sceneKey, () async {
      if (P.app.pageKey.q != pageKey) return false;
      if (_isChatSceneLoaded(scene)) return true;

      final data = lastModelByScene.q[sceneKey] ?? _legacyChatPayloadForScene(scene);
      final fileInfo = _findChatFile(scene: scene, data: data);
      if (fileInfo == null || !_isLocalModelReady(fileInfo)) {
        if (showSelectorOnFailure) _showModelSelectorForScene(scene, pageKey: pageKey);
        return false;
      }

      final modelID = await _loadChatModelForScene(
        scene: scene,
        fileInfo: fileInfo,
        showSuccess: false,
        saveScene: false,
        expectedPageKey: pageKey,
      );
      return modelID != null;
    });
  }

  Future<bool> _restoreNeko({required PageKey pageKey}) async {
    final scene = _AutoLoadScene.neko;
    return await _runOnce(_sceneKey(scene), () async {
      if (P.app.pageKey.q != pageKey) return false;
      if (_isChatSceneLoaded(scene)) return true;

      final data = lastModelByScene.q[_sceneKey(scene)] ?? _legacyChatPayloadForScene(scene);
      FileInfo? fileInfo = _findChatFile(scene: scene, data: data);
      fileInfo ??= _firstDownloadedNekoModel();

      if (fileInfo == null || !_isLocalModelReady(fileInfo)) {
        final nekoModels = P.remote.getNekoModel();
        if (nekoModels.isNotEmpty) {
          Alert.warning(S.current.chat_you_need_download_model_if_you_want_to_use_it);
          _showModelSelectorForScene(scene, pageKey: pageKey);
        } else {
          Alert.error("Neko is not available");
        }
        return false;
      }

      final modelID = await _loadChatModelForScene(
        scene: scene,
        fileInfo: fileInfo,
        showSuccess: false,
        saveScene: true,
        expectedPageKey: pageKey,
      );
      return modelID != null;
    });
  }

  FileInfo? _findChatFile({
    required _AutoLoadScene scene,
    required Map<String, dynamic>? data,
  }) {
    final fileInfo = _findFileFromPayload(P.remote.chatWeights.q, data);
    if (fileInfo == null) return null;

    return switch (scene) {
      .chat when !fileInfo.isNeko && !fileInfo.hasEffectiveTag("translate") => fileInfo,
      .neko when fileInfo.isNeko => fileInfo,
      .translator when fileInfo.hasEffectiveTag("translate") => fileInfo,
      _ => null,
    };
  }

  Map<String, dynamic>? _legacyChatPayloadForScene(_AutoLoadScene scene) {
    final lastChat = P.preference.lastChatModel.q;
    if (lastChat == null) return null;
    final fileInfo = _findChatFile(scene: scene, data: lastChat);
    if (fileInfo == null) return null;
    return lastChat;
  }

  FileInfo? _firstDownloadedNekoModel() {
    final nekoModels = P.remote.getNekoModel();
    return nekoModels.firstWhereOrNull((e) => P.remote.locals(e).q.hasFile);
  }

  void _showModelSelectorForScene(_AutoLoadScene scene, {required PageKey pageKey}) {
    if (P.app.pageKey.q != pageKey) return;
    switch (scene) {
      case .chat:
        ModelSelector.show();
        break;
      case .neko:
        ModelSelector.show(showNeko: true);
        break;
      case .translator:
        ModelSelector.show();
        break;
      case .talk:
        ModelSelector.show(preferredDemoType: .tts);
        break;
      case .roleplayChat:
        ModelSelector.show(rolePlayOnly: true);
        break;
      case .roleplayTts:
        ModelSelector.show(preferredDemoType: .tts);
        break;
    }
  }

  FileInfo? _findFileFromPayload(Iterable<FileInfo> source, Map<String, dynamic>? data) {
    if (data == null) return null;
    final fileName = data["fileName"];
    final fileSize = data["fileSize"];
    if (fileName is! String) return null;

    return source.firstWhereOrNull((e) {
      if (e.fileName != fileName) return false;
      if (fileSize is int && e.fileSize != fileSize) return false;
      return true;
    });
  }

  bool _isLocalModelReady(FileInfo fileInfo) {
    if (fileInfo.backend == null) return false;
    return P.remote.locals(fileInfo).q.hasFile;
  }

  Future<bool> _restoreSee({required PageKey pageKey}) async {
    final worldType = P.rwkvContext.currentWorldType.q;
    final sceneKey = _seeSceneKeyForRestore(worldType);
    if (sceneKey == null) {
      if (P.app.pageKey.q == pageKey) {
        ModelSelector.show(preferredDemoType: .see);
      }
      return false;
    }

    return await _runOnce(sceneKey, () async {
      if (P.app.pageKey.q != pageKey) return false;
      final targetWorldType = _worldTypeFromSeeSceneKey(sceneKey);
      if (_isSeeLoaded(targetWorldType)) return true;

      final data = lastModelByScene.q[sceneKey];
      if (data == null) {
        ModelSelector.show(preferredDemoType: .see);
        return false;
      }

      final modelFileName = data["fileName"];
      if (targetWorldType == null || modelFileName is! String) {
        ModelSelector.show(preferredDemoType: .see);
        return false;
      }

      final loaded = await _loadSeeWorldModel(
        worldType: targetWorldType,
        modelFileName: modelFileName,
        showSuccess: false,
        saveScene: false,
        expectedPageKey: pageKey,
      );
      if (!loaded && P.app.pageKey.q == pageKey) {
        ModelSelector.show(preferredDemoType: .see);
      }
      return loaded;
    });
  }

  String? _seeSceneKeyForRestore(WorldType? worldType) {
    if (worldType != null) {
      final key = _seeSceneKey(worldType);
      if (lastModelByScene.q.containsKey(key)) return key;
    }

    String? latestKey;
    int latestUpdatedAt = -1;
    for (final entry in lastModelByScene.q.entries) {
      if (!entry.key.startsWith("see.")) continue;
      final updatedAt = entry.value["updatedAt"];
      final normalizedUpdatedAt = updatedAt is int ? updatedAt : 0;
      if (normalizedUpdatedAt <= latestUpdatedAt) continue;
      latestKey = entry.key;
      latestUpdatedAt = normalizedUpdatedAt;
    }
    return latestKey;
  }

  WorldType? _worldTypeFromSeeSceneKey(String sceneKey) {
    final name = sceneKey.replaceFirst("see.", "");
    return WorldType.values.firstWhereOrNull((e) => e.name == name);
  }

  Future<bool> _loadSeeWorldModel({
    required WorldType worldType,
    required String modelFileName,
    required bool showSuccess,
    required bool saveScene,
    required PageKey? expectedPageKey,
  }) async {
    final files = _resolveSeeFiles(worldType: worldType, modelFileName: modelFileName);
    if (files == null) {
      Alert.error("Required model files not found");
      return false;
    }

    final canContinueAfterLoading = await _waitForOtherModelLoading(
      fileInfo: files.model,
      expectedPageKey: expectedPageKey,
    );
    if (!canContinueAfterLoading) {
      return false;
    }

    final prepared = await _prepareLoadedModelsForPage(
      expectedPageKey: expectedPageKey,
      preferredDemoType: .see,
    );
    if (!prepared) {
      return false;
    }
    if (!_isExpectedPageActive(expectedPageKey)) {
      return false;
    }

    final encoderLocalFile = P.remote.locals(files.encoder).q;
    final modelLocalFile = P.remote.locals(files.model).q;
    final adapterLocalFile = files.adapter != null ? P.remote.locals(files.adapter!).q : null;

    if (!encoderLocalFile.hasFile || !modelLocalFile.hasFile || (adapterLocalFile != null && !adapterLocalFile.hasFile)) {
      return false;
    }

    P.rwkvContext.currentWorldType.q = worldType;
    await P.rwkvGeneration.clearStates();
    P.chat.clearMessages();

    final adapterPath = switch (worldType) {
      WorldType.reasoningQA || WorldType.ocr => null,
      WorldType.modrwkvV2 || WorldType.modrwkvV3 => adapterLocalFile?.targetPath,
    };
    final modelID = await P.rwkvModel.loadSee(
      modelPath: modelLocalFile.targetPath,
      encoderPath: encoderLocalFile.targetPath,
      backend: files.model.backend!,
      enableReasoning: worldType.isReasoning,
      adapterPath: adapterPath,
      fileInfo: files.model,
      shouldKeepLoadedModel: () => _isExpectedPageActive(expectedPageKey),
    );

    if (modelID == null) return false;
    switch (worldType) {
      case WorldType.reasoningQA:
      case WorldType.ocr:
        break;
      case WorldType.modrwkvV2:
      case WorldType.modrwkvV3:
        P.rwkvBridge.send(SetImageUniqueIdentifier("image"));
        P.rwkvBridge.send(SetSpaceAfterRoles(false, modelID: modelID));
    }

    if (saveScene) {
      _saveSeeScene(worldType: worldType, fileInfo: files.model);
    }
    if (showSuccess) Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    return true;
  }

  ({FileInfo encoder, FileInfo model, FileInfo? adapter})? _resolveSeeFiles({
    required WorldType worldType,
    required String modelFileName,
  }) {
    final fileInfos = P.remote.seeWeights.q.where((e) => e.worldType == worldType).toList();
    final encoderFileKey = fileInfos.firstWhereOrNull((e) => e.isEncoder);
    final modelFileKey = fileInfos.firstWhereOrNull((e) => !e.isEncoder && e.fileName == modelFileName);
    final adapterFileKey = fileInfos.firstWhereOrNull((e) => e.isAdapter);
    if (encoderFileKey == null || modelFileKey == null) return null;
    if (modelFileKey.backend == null) return null;
    return (encoder: encoderFileKey, model: modelFileKey, adapter: adapterFileKey);
  }

  Future<bool> _restoreTalk({required PageKey pageKey}) async {
    final scene = _AutoLoadScene.talk;
    return await _runOnce(_sceneKey(scene), () async {
      if (P.app.pageKey.q != pageKey) return false;
      if (_isTtsLoaded()) return true;

      final data = lastModelByScene.q[_sceneKey(scene)];
      final fileInfo = _findFileFromPayload(P.remote.ttsCores.q, data);
      if (fileInfo == null || !_isLocalModelReady(fileInfo)) {
        _showModelSelectorForScene(scene, pageKey: pageKey);
        return false;
      }

      final result = await _loadTtsCoreForScene(
        scene: scene,
        fileInfo: fileInfo,
        showSuccess: false,
        saveScene: false,
        expectedPageKey: pageKey,
      );
      return result.$2 != null;
    });
  }

  Future<(SendPort?, int?)> _loadTtsCoreForScene({
    required _AutoLoadScene scene,
    required FileInfo fileInfo,
    required bool showSuccess,
    required bool saveScene,
    required PageKey? expectedPageKey,
  }) async {
    final dependencies = _resolveTtsDependencies();
    if (dependencies == null) {
      Alert.error("TTS dependency file not found");
      return (P.rwkvBridge.sendPort, null);
    }

    if (!_isLocalModelReady(fileInfo) || !_isTtsDependenciesReady(dependencies)) {
      return (P.rwkvBridge.sendPort, null);
    }

    final canContinueAfterLoading = await _waitForOtherModelLoading(
      fileInfo: fileInfo,
      expectedPageKey: expectedPageKey,
    );
    if (!canContinueAfterLoading) {
      return (P.rwkvBridge.sendPort, null);
    }

    final DemoType preferredDemoType = scene == .roleplayTts ? .chat : .tts;
    final prepared = await _prepareLoadedModelsForPage(
      expectedPageKey: expectedPageKey,
      preferredDemoType: preferredDemoType,
    );
    if (!prepared) {
      return (P.rwkvBridge.sendPort, null);
    }
    if (!_isExpectedPageActive(expectedPageKey)) {
      return (P.rwkvBridge.sendPort, null);
    }

    if (scene != .roleplayTts) {
      await P.rwkvGeneration.clearStates();
      P.chat.clearMessages();
    }

    final modelLocalFile = P.remote.locals(fileInfo).q;
    final localWav2vec2File = P.remote.locals(dependencies.wav2vec2).q;
    final localDetokenizeFile = P.remote.locals(dependencies.detokenize).q;
    final localTokenizeFile = P.remote.locals(dependencies.tokenize).q;
    final result = await P.rwkvModel.loadTTS(
      modelPath: modelLocalFile.targetPath,
      backend: fileInfo.backend!,
      wav2vec2Path: localWav2vec2File.targetPath,
      detokenizePath: localDetokenizeFile.targetPath,
      bicodecTokenzerPath: localTokenizeFile.targetPath,
      fileInfo: fileInfo,
      shouldKeepLoadedModel: () => _isExpectedPageActive(expectedPageKey),
    );

    final modelID = result.$2;
    if (modelID == null) return result;

    if (saveScene) {
      _saveScene(_sceneKey(scene), {
        "fileName": fileInfo.fileName,
        "fileSize": fileInfo.fileSize,
      });
    }

    if (scene == .roleplayTts) {
      final info = ModelInfo(
        id: fileInfo.fileName,
        modelPath: modelLocalFile.targetPath,
        statePath: '',
        backend: fileInfo.backend!,
        modelType: RoleplayManageModelType.tts,
      );
      rolePlayTTSModel = info;
      RoleplayManage.onModelDownloadComplete(info, [result.$1, modelID], P.rwkvBridge.receivePort);
      return result;
    }

    P.talk.getTTSSpkNames();
    P.rwkvContext.currentGroupInfo.q = GroupInfo(displayName: fileInfo.name);
    if (showSuccess) Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    return result;
  }

  ({FileInfo wav2vec2, FileInfo detokenize, FileInfo tokenize})? _resolveTtsDependencies() {
    final sparkFileKeys = P.remote.ttsWeights.q.where((e) => e.tags.contains("spark")).toList();
    final wav2vec2FileKey = sparkFileKeys.firstWhereOrNull((e) => e.tags.contains("wav2vec2"));
    final detokenizeFileKey = sparkFileKeys.firstWhereOrNull((e) => e.tags.contains("detokenize"));
    final bicodecTokenizeFileKey = sparkFileKeys.firstWhereOrNull((e) => e.tags.contains("tokenize"));
    if (wav2vec2FileKey == null || detokenizeFileKey == null || bicodecTokenizeFileKey == null) return null;
    return (wav2vec2: wav2vec2FileKey, detokenize: detokenizeFileKey, tokenize: bicodecTokenizeFileKey);
  }

  bool _isTtsDependenciesReady(({FileInfo wav2vec2, FileInfo detokenize, FileInfo tokenize}) dependencies) {
    return P.remote.locals(dependencies.wav2vec2).q.hasFile &&
        P.remote.locals(dependencies.detokenize).q.hasFile &&
        P.remote.locals(dependencies.tokenize).q.hasFile;
  }

  Future<bool> _restoreRoleplay({required PageKey pageKey}) async {
    final chatRestored = await _restoreRoleplayChat(pageKey: pageKey);
    final ttsRestored = await _restoreRoleplayTts(pageKey: pageKey);
    return chatRestored || ttsRestored;
  }

  Future<bool> _restoreRoleplayChat({required PageKey pageKey}) async {
    final sceneKey = _sceneKey(.roleplayChat);
    return await _runOnce(sceneKey, () async {
      if (P.app.pageKey.q != pageKey) return false;
      if (_isRoleplayChatLoaded()) return true;

      final data = lastModelByScene.q[sceneKey];
      final candidates = <FileInfo>{
        ...P.remote.roleplayWeights.q,
        ...P.remote.chatWeights.q.where((e) => e.state.isNotEmpty),
      };
      final fileInfo = _findFileFromPayload(candidates, data);
      if (fileInfo == null || !_isLocalModelReady(fileInfo)) return false;

      final state = _findRoleplayState(fileInfo: fileInfo, data: data);
      if (state != null && !P.remote.locals(state).q.hasFile) return false;

      final result = await _loadRoleplayChatModel(
        fileInfo: fileInfo,
        state: state,
        saveScene: false,
        expectedPageKey: pageKey,
      );
      return result.$2 != null;
    });
  }

  Future<(SendPort?, int?)> _loadRoleplayChatModel({
    required FileInfo fileInfo,
    required ModelStateFile? state,
    required bool saveScene,
    required PageKey? expectedPageKey,
  }) async {
    if (fileInfo.backend == null) {
      Alert.error("Backend is null");
      return (P.rwkvBridge.sendPort, null);
    }

    final canContinueAfterLoading = await _waitForOtherModelLoading(
      fileInfo: fileInfo,
      expectedPageKey: expectedPageKey,
    );
    if (!canContinueAfterLoading) {
      return (P.rwkvBridge.sendPort, null);
    }

    final prepared = await _prepareLoadedModelsForPage(
      expectedPageKey: expectedPageKey,
      preferredDemoType: .chat,
    );
    if (!prepared) {
      return (P.rwkvBridge.sendPort, null);
    }
    if (!_isExpectedPageActive(expectedPageKey)) {
      return (P.rwkvBridge.sendPort, null);
    }

    final modelLocalFile = P.remote.locals(fileInfo).q;
    final statePath = state == null ? '' : P.remote.locals(state).q.targetPath;
    final info = _buildRoleplayChatModelInfo(
      fileInfo: fileInfo,
      modelPath: modelLocalFile.targetPath,
      statePath: statePath,
      state: state,
    );
    final result = await P.rwkvModel.loadChat(
      fileInfo: fileInfo,
      shouldKeepLoadedModel: () => _isExpectedPageActive(expectedPageKey),
    );
    final modelID = result.$2;
    if (modelID == null) return result;

    rolePlayCurrentModel = info;
    if (saveScene) {
      _saveRoleplayChatScene(fileInfo: fileInfo, state: state);
    }
    RoleplayManage.onModelDownloadComplete(info, [result.$1, modelID], P.rwkvBridge.receivePort);
    return result;
  }

  ModelInfo _buildRoleplayChatModelInfo({
    required FileInfo fileInfo,
    required String modelPath,
    required String statePath,
    required ModelStateFile? state,
  }) {
    final decodeParam = state?.decodeParam;
    return ModelInfo(
      id: fileInfo.fileName,
      modelPath: modelPath,
      statePath: statePath,
      backend: fileInfo.backend!,
      topP: _numberFromDecodeParam(decodeParam, "topP"),
      temperature: _numberFromDecodeParam(decodeParam, "temperature"),
      penaltyDecay: _numberFromDecodeParam(decodeParam, "penaltyDecay"),
      presencePenalty: _numberFromDecodeParam(decodeParam, "presencePenalty"),
      frequencyPenalty: _numberFromDecodeParam(decodeParam, "frequencyPenalty"),
      modelType: RoleplayManageModelType.chat,
    );
  }

  double? _numberFromDecodeParam(dynamic decodeParam, String key) {
    if (decodeParam is! Map) return null;
    final value = decodeParam[key];
    if (value is num) return value.toDouble();
    return null;
  }

  ModelStateFile? _findRoleplayState({
    required FileInfo fileInfo,
    required Map<String, dynamic>? data,
  }) {
    if (fileInfo.state.isEmpty) return null;
    if (data == null) return fileInfo.state.first;

    final stateFileName = data["stateFileName"];
    final stateFileSize = data["stateFileSize"];
    if (stateFileName is! String) return fileInfo.state.first;

    return fileInfo.state.firstWhereOrNull((e) {
      if (e.fileName != stateFileName) return false;
      if (stateFileSize is int && e.fileSize != stateFileSize) return false;
      return true;
    });
  }

  Future<bool> _restoreRoleplayTts({required PageKey pageKey}) async {
    final scene = _AutoLoadScene.roleplayTts;
    return await _runOnce(_sceneKey(scene), () async {
      if (P.app.pageKey.q != pageKey) return false;
      if (_isRoleplayTtsLoaded()) return true;

      final data = lastModelByScene.q[_sceneKey(scene)];
      final fileInfo = _findFileFromPayload(P.remote.ttsCores.q, data);
      if (fileInfo == null || !_isLocalModelReady(fileInfo)) return false;

      final result = await _loadTtsCoreForScene(
        scene: scene,
        fileInfo: fileInfo,
        showSuccess: false,
        saveScene: false,
        expectedPageKey: pageKey,
      );
      return result.$2 != null;
    });
  }

  bool _isRoleplayChatLoaded() {
    final currentModel = rolePlayCurrentModel;
    if (currentModel == null) return false;
    return P.rwkvModel.allLoaded.q.keys.any((e) => e.fileName == currentModel.id);
  }

  bool _isRoleplayTtsLoaded() {
    final currentModel = rolePlayTTSModel;
    if (currentModel == null) return false;
    return P.rwkvModel.allLoaded.q.keys.any((e) => e.fileName == currentModel.id);
  }
}
