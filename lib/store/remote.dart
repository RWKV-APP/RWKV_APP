// ignore_for_file: unnecessary_brace_in_string_interps

part of 'p.dart';

const _modelsDirNotReadyMessage = "Models directory is not ready";

/// 1. 管理通过 latest.json 配置的文件
class _Remote {
  // ===========================================================================
  // Instance
  // ===========================================================================

  /// model-name to download-task map
  late final _downloadTasks = <String, DownloadTask>{};

  /// macOS: security-scoped resource for custom models directory
  FileSystemEntity? _macosCustomDirScopedResource;

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final downloadSource = qs<FileDownloadSource>(P.preference.currentLangIsZh.q ? .aifasthub : .huggingface);

  late final modelSelectorShown = qs(false);

  late final syncingLocalFiles = qs(false);

  /// 模型目录下所有文件的总大小
  late final totalSizeInModelsDir = qs(0);

  /// 本地文件状态
  late final locals = qsff<FileInfo, LocalFile>((ref, key) {
    return LocalFile(targetPath: ref.watch(_paths(key)));
  });

  /// 本地文件路径
  late final _paths = qsff<FileInfo, String>((ref, key) {
    final effectiveModelsDir = ref.watch(P.remote.effectiveModelsDir);
    final effectiveDocumentsDir = ref.watch(P.app.effectiveDocumentsDir);
    final isDesktop = ref.watch(P.app.isDesktop);

    if (isDesktop) {
      if (effectiveModelsDir.isEmpty) {
        return "";
      }
      return join(effectiveModelsDir, key.fileName);
    }

    final fileName = key.fileName;
    final dirPath = effectiveDocumentsDir!.path;
    return join(dirPath, Config.mobileModelsDirName, fileName);
  });

  /// 全部 chat 权重
  late final _allChatWeights = qs<Set<FileInfo>>({});

  /// 当前平台可用的 chat 权重
  late final chatWeights = qs<Set<FileInfo>>({});

  late final seeWeights = qs<Set<FileInfo>>({});
  late final sudokuWeights = qs<Set<FileInfo>>({});
  late final othelloWeights = qs<Set<FileInfo>>({});

  late final roleplayWeights = qs<Set<FileInfo>>({});

  /// 当前平台可用的 tts 权重, 包含 core 和 non-core 两种
  late final ttsWeights = qs<Set<FileInfo>>({});
  late final ttsCores = qs<Set<FileInfo>>({});

  /// Set of group IDs (core file names) that the user has explicitly requested to download
  late final activeDownloadGroupIds = qs<Set<String>>({});

  /// Unrecognized files found in the models directory
  late final unrecognizedFiles = qs<List<UnrecognizedFile>>([]);

  /// MLX/CoreML unzip cache directories found in the models directory
  late final mlxCacheDirectories = qs<List<MlxCacheDirectory>>([]);

  /// Check if using custom models directory
  late final usingCustomModelsDir = qp<bool>((ref) {
    final customDir = ref.watch(P.preference.customModelsDir);
    final defaultDir = defaultModelsDir.q;
    return customDir != null && customDir.isNotEmpty && customDir != defaultDir;
  });

  late final allWeights = qp<Set<FileInfo>>((ref) {
    final groups = <Set<FileInfo>>[
      ref.watch(chatWeights),
      ref.watch(roleplayWeights),
      ref.watch(ttsWeights),
      ref.watch(seeWeights),
      ref.watch(sudokuWeights),
      ref.watch(othelloWeights),
    ];
    final result = <FileInfo>{};
    for (final group in groups) {
      for (final fileInfo in group) {
        result.add(fileInfo);
        result.addAll(fileInfo.state);
      }
    }
    return result;
  });

  late final hasActiveDownload = qp<bool>((ref) {
    final allWeights = ref.watch(this.allWeights);
    for (final fileInfo in allWeights) {
      final localFile = ref.watch(locals(fileInfo));
      if (localFile.downloading) {
        return true;
      }
    }
    return false;
  });

  /// 量化好的权重被保存的文件夹位置
  late final effectiveModelsDir = qp<String>((ref) {
    final customDir = ref.watch(P.preference.customModelsDir);
    final defaultDir = ref.watch(defaultModelsDir);
    return customDir ?? defaultDir;
  });

  /// 默认的存放已量化权重的文件夹路径
  late final defaultModelsDir = qp<String>((ref) {
    if (Platform.isWindows) {
      if (Args.useWindowsSandboxModels) {
        final appSupportDir = ref.watch(P.app.effectiveDocumentsDir);
        if (appSupportDir == null) {
          qqw("Windows sandbox models dir is not ready yet");
          return "";
        }
        final res = join(appSupportDir.path, Config.desktopModelsDirName);
        return res;
      }
      final exePath = Platform.resolvedExecutable;
      final exeDir = dirname(exePath);
      final res = join(exeDir, Config.desktopModelsDirName);
      return res;
    }

    final documentsDir = ref.watch(P.app.documentsDir);

    if (documentsDir == null) {
      Sentry.captureException(Exception("documentsDir is null, WTF?"));
      return "";
    }

    if (Platform.isMacOS || Platform.isLinux) {
      final res = join(documentsDir.path, Config.desktopModelsDirName);
      return res;
    }

    final res = join(documentsDir.path, Config.mobileModelsDirName);
    return res;
  });

  /// 获取所有支持的NPU芯片列表（从所有模型的socLimitations中提取）
  List<String> get getSupportedNpuChips {
    final config = P.app._config.q;
    if (config == null) return [];

    final allModelConfigs = <Map<String, dynamic>>[];

    // 收集所有demo类型的模型配置
    for (final demoType in ['chat', 'tts', 'world', 'sudoku', 'othello', 'roleplay', 'albatross']) {
      final demoConfig = config[demoType];
      if (demoConfig is Map && demoConfig['model_config'] is List) {
        allModelConfigs.addAll(HF.listJSON(demoConfig['model_config']));
      }
    }

    // 提取所有NPU模型的socLimitations
    final supportedNpus = <String>{};
    for (final modelConfig in allModelConfigs) {
      final tags = HF.list(modelConfig['tags'] ?? []).map((e) => e.toString().toLowerCase()).toList();
      if (tags.contains('npu')) {
        final socLimitations = HF.list(modelConfig['socLimitations'] ?? []);
        for (final soc in socLimitations) {
          final socName = soc.toString();
          if (socName.isNotEmpty) {
            supportedNpus.add(socName);
          }
        }
      }
    }

    // 排序：先按品牌分组，然后按型号排序
    final qualcomm = <String>[];
    final mediatek = <String>[];
    final others = <String>[];

    for (final soc in supportedNpus) {
      if (soc.contains('8 Elite') || soc.contains('8 Gen') || soc.contains('7+ Gen')) {
        qualcomm.add(soc);
      } else if (soc.contains('Dimensity')) {
        mediatek.add(soc);
      } else {
        others.add(soc);
      }
    }

    // 排序：8 Elite Gen5 > 8 Elite > 8 Gen 3 > 8s Gen 3 > 7+ Gen 3 > 8 Gen 2
    qualcomm.sort((a, b) {
      final order = ['8 Elite Gen5', '8 Elite', '8 Gen 3', '8s Gen 3', '7+ Gen 3', '8 Gen 2'];
      final aIndex = order.indexWhere((e) => a.contains(e));
      final bIndex = order.indexWhere((e) => b.contains(e));
      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });

    return [...qualcomm, ...mediatek, ...others];
  }
}

/// Public methods
extension $Remote on _Remote {
  String? _getReadyModelsDirPath({bool showAlert = false}) {
    final modelsDir = effectiveModelsDir.q;
    if (modelsDir.isNotEmpty) {
      return modelsDir;
    }

    qqw(_modelsDirNotReadyMessage);
    if (showAlert) {
      Alert.error(_modelsDirNotReadyMessage);
    }
    return null;
  }

  Future<String?> _getModelsDirPathForScan() async {
    final isDesktop = P.app.isDesktop.q;
    if (isDesktop) {
      return _getReadyModelsDirPath();
    }

    final documentsDir = P.app.documentsDir.q?.path;
    if (documentsDir == null) {
      Sentry.captureException(Exception("documentsDir is null, WTF?"), stackTrace: StackTrace.current);
      return null;
    }

    final oldModelsDirPathInMobile = join(documentsDir, Config.desktopModelsDirName);
    final oldModelsDirPathInMobileExists = await Directory(oldModelsDirPathInMobile).exists();
    if (oldModelsDirPathInMobileExists) {
      qqw("Old models directory exists in mobile: $oldModelsDirPathInMobile");
      qqw("Transferring files from old models directory to new models directory...");
    }

    final targetDirPath = join(documentsDir, Config.mobileModelsDirName);
    await transferAllFilesInDir(oldModelsDirPathInMobile, targetDirPath);
    return targetDirPath;
  }

  Future<void> syncAvailableModels() async {
    qq;
    final config = P.app._config.q;
    if (config == null) {
      qqe("config is null");
      return;
    }

    final chatWeights = HF.listJSON(config["chat"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();
    final ttsWeights = HF.listJSON(config["tts"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();
    final worldWeights = HF.listJSON(config["world"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();
    final sudokuWeights = HF.listJSON(config["sudoku"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();
    final othelloWeights = HF.listJSON(config["othello"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();
    final albatrossWeights = HF.listJSON(config["albatross"]?["model_config"] ?? []).map((e) => FileInfo.fromJSON(e)).toSet();

    final roleplayConfig = (config["roleplay"] ?? <String, dynamic>{})["model_config"];
    final roleplayWeights = HF.listJSON(roleplayConfig ?? []).map((e) => FileInfo.fromJSON(e)).toSet();

    _allChatWeights.q = chatWeights;
    this.chatWeights.q = chatWeights.where((e) => e.available).toSet();
    this.roleplayWeights.q = roleplayWeights.where((e) => e.available).toSet();
    this.ttsWeights.q = ttsWeights.where((e) => e.available).toSet();
    this.sudokuWeights.q = sudokuWeights.where((e) => e.available).toSet();
    this.othelloWeights.q = othelloWeights.where((e) => e.available).toSet();
    seeWeights.q = worldWeights.where((e) => e.available).toSet();

    ttsCores.q = this.ttsWeights.q.where((e) => e.tags.contains("core")).toSet();

    if (P.rwkv.enableAlbatross.q) {
      this.chatWeights.q = this.chatWeights.q.union(albatrossWeights.where((e) => e.available).toSet());
    }
  }

  void cleanDownloadTasks() {
    _downloadTasks.clear();
  }

  /// 检查本地是否存在量化好的权重文件
  ///
  /// 更新本地文件状态
  ///
  /// 如果尺寸对不上, 自动删除
  Future<void> checkLocal() async {
    await 17.msLater;
    final readyModelsDir = _getReadyModelsDirPath();
    final fileInfos = [
      chatWeights.q,
      roleplayWeights.q,
      ttsWeights.q,
      seeWeights.q,
      sudokuWeights.q,
      othelloWeights.q,
    ].expand((e) => e).where((e) => e.available).toList();

    for (final fileInfo in fileInfos) {
      final local = locals(fileInfo);
      final path = _paths(fileInfo).q;
      if (path.isEmpty) {
        local.q = local.q.copyWith(
          hasFile: false,
          progress: 0,
          state: TaskState.idle,
        );
        continue;
      }

      final pathExists = await File(path).exists();
      bool fileSizeVerified = false;
      if (pathExists) {
        final expectFileSize = fileInfo.fileSize;
        final fileSize = await File(path).length();
        fileSizeVerified = expectFileSize == fileSize;
        if (kDebugMode) {
          if (!fileSizeVerified) {
            qqw("fileSizeVerified: $fileSizeVerified");
            qqw("expectFileSize: $expectFileSize");
            qqw("fileSize: $fileSize");
          }
        }

        final isNotDebug = !kDebugMode;
        final fileSizeNotCorrect = expectFileSize != fileSize;
        final shouldDelete = isNotDebug && fileSizeNotCorrect;

        if (shouldDelete) File(path).delete();
      }
      local.q = local.q.copyWith(hasFile: fileSizeVerified);
    }
    await _initModelDownloadTaskState();
    if (readyModelsDir == null) {
      totalSizeInModelsDir.q = 0;
      return;
    }

    final totalSize = await calculateTotalSizeOfDir(readyModelsDir);
    totalSizeInModelsDir.q = totalSize;
  }

  Future<void> removeFilesNotInConfig() async {
    qq;

    const maxSizeBytes = 20 * 1024 * 1024; // 20MB

    final fileInfos = [
      chatWeights.q,
      roleplayWeights.q,
      ttsWeights.q,
      seeWeights.q,
      sudokuWeights.q,
      othelloWeights.q,
    ].expand((e) => e).where((e) => e.available).toList();
    final documentsDir = P.app.effectiveDocumentsDir.q;
    if (documentsDir == null) return;

    // Scan both Documents root and models subfolder
    final directoriesToScan = <Directory>[documentsDir];
    final modelsDir = Directory("${documentsDir.path}/${Config.desktopModelsDirName}");
    if (await modelsDir.exists()) {
      directoriesToScan.add(modelsDir);
    }

    for (final dir in directoriesToScan) {
      final fileSystemEntities = dir.listSync();

      for (final entity in fileSystemEntities) {
        if (entity is! File) continue;

        final fileNameExistsInConfig = fileInfos.any((e) => entity.path.contains(e.fileName));

        if (fileNameExistsInConfig) continue;

        // 不移除以 .tmp 结尾的文件
        if (entity.path.endsWith('.tmp')) {
          continue;
        }

        // 检查文件大小，只删除大于 20MB 的文件
        final fileSize = await File(entity.path).length();
        final needToCheckBecauseTheFileIsBigEnough = fileSize > maxSizeBytes;
        if (!needToCheckBecauseTheFileIsBigEnough) continue;

        await entity.delete();

        qqw("delete file (size: ${fileSize} bytes): ${entity.path}");
        qqw("fileNameExistsInConfig: $fileNameExistsInConfig");
        if (!fileNameExistsInConfig) {
          qqw("fileName: ${basename(entity.path)}");
          qqw("All config file names: ${getAllConfigFileNames().join("\n")}");
        }
        qqw("needToCheckBecauseTheFileIsBigEnough: $needToCheckBecauseTheFileIsBigEnough");
      }
    }
  }

  List<FileInfo> getNekoModel() {
    final nekos = _allChatWeights.q.where((e) => e.available && e.isNeko).toList();
    return nekos;
  }

  Future<void> getFile({required FileInfo fileInfo}) async {
    final url = downloadSource.q.prefix + downloadSource.q.transformRaw(fileInfo.raw) + downloadSource.q.suffix;
    final path = _paths(fileInfo).q;
    if (path.isEmpty) {
      Alert.error(_modelsDirNotReadyMessage);
      return;
    }

    qqq('start download file: \n>>url:$url\n>>path:$path');

    DownloadTask? task = _downloadTasks[fileInfo.fileName];
    task?.url = url;
    if (task == null) {
      task = await DownloadTask.create(url: url, path: path);
      _downloadTasks[fileInfo.fileName] = task;
    }

    if (task.state == TaskState.running) return;

    final state = locals(fileInfo);

    task
        .events()
        .throttleTime(const Duration(milliseconds: 1000), trailing: true, leading: false)
        .listen(
          (e) {
            if (HF.randomBool(truePercentage: .2)) {
              qqq('download update: state:${e.state}, speed:${e.speedInMB.toStringAsFixed(2)}MB/s, ${e.totalSize}');
            }
            state.q = state.q.copyWith(
              timeRemaining: Duration(seconds: e.remainSeconds.round().clamp(0, 60 * 60 * 24)),
              progress: e.progress,
              state: e.state,
              networkSpeed: e.speedInMB,
              hasFile: e.state == TaskState.completed,
            );
          },
          onError: (e) {
            qqe(e);
            Alert.error(S.current.download_failed);
            Sentry.captureException(e, stackTrace: StackTrace.current);
          },
          onDone: () {
            qqq('event done');
          },
        );

    // 开始下载时，重置进度并确保 hasFile 为 false（避免进度计算错误）
    state.q = state.q.copyWith(progress: 0, state: TaskState.running, hasFile: false);

    try {
      await task.start();
    } on HttpException catch (e) {
      qqe(e.message);
      qqe(e);
      Alert.error(S.current.network_error + ": ${e.message}");
      state.q = state.q.copyWith(state: TaskState.stopped);
    } catch (e) {
      if (e.toString().contains("CERTIFICATE_VERIFY_FAILED")) {
        Alert.error('SSL Certificate Verify Failed');
      } else if (e.toString().toLowerCase().contains("timeout")) {
        Alert.error('Network timeout');
      } else if (e.toString().contains('HandshakeException')) {
        Alert.error(S.current.network_error);
      } else {
        qqe(e);
        Alert.error(S.current.download_failed);
        Sentry.captureException(e, stackTrace: StackTrace.current);
      }
      state.q = state.q.copyWith(state: TaskState.stopped);
    }
  }

  Future<void> pauseDownload({required FileInfo fileInfo}) async {
    final task = _downloadTasks[fileInfo.fileName];
    task?.stop();
    final state = locals(fileInfo);
    state.q = state.q.copyWith(state: TaskState.stopped);
  }

  Future<void> cancelDownload({required FileInfo fileInfo}) async {
    final task = _downloadTasks[fileInfo.fileName];
    await task?.cancel();
    final state = locals(fileInfo);
    state.q = state.q.copyWith(state: TaskState.idle);
  }

  Future<void> deleteFile({required FileInfo fileInfo}) async {
    final state = locals(fileInfo);
    final value = state.q;

    try {
      await cancelDownload(fileInfo: fileInfo);
    } catch (e) {
      qe;
      qqe(e);
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
    }
    final path = _paths(fileInfo).q;
    if (path.isEmpty) {
      state.q = value.copyWith(hasFile: false, state: TaskState.idle, progress: 0);
      return;
    }
    await File(path).delete();
    state.q = value.copyWith(hasFile: false, state: TaskState.idle, progress: 0);

    await sync();
  }

  Future<void> openModelDirectory() async {
    final isDesktop = P.app.isDesktop.q;

    if (!isDesktop) {
      Alert.info(S.current.open_folder_unsupported_on_platform(Platform.operatingSystem));
      return;
    }

    try {
      final effectiveDir = _getReadyModelsDirPath(showAlert: true);
      if (effectiveDir == null) {
        return;
      }
      await openFolder(effectiveDir);
    } catch (e) {
      qqe(e);
      Alert.error(e.toString());
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
    }

    await sync();
  }

  /// Pick and set a custom models directory
  /// Only updates preference path; does not migrate files. Use [Alert.info] to prompt manual migration.
  Future<bool> pickAndSetCustomModelsDir({required BuildContext context}) async {
    try {
      final selectedDir = await file_picker.FilePicker.getDirectoryPath();
      if (selectedDir == null) {
        return false; // User cancelled
      }

      final currentDir = P.remote.effectiveModelsDir.q;
      if (currentDir == selectedDir) {
        Alert.warning(S.current.already_using_this_directory);
        return false;
      }

      final dir = Directory(selectedDir);
      if (!await dir.exists()) {
        try {
          await dir.create(recursive: true);
        } catch (e) {
          qqe("Failed to create directory: $e");
          Alert.error(S.current.failed_to_create_directory);
          return false;
        }
      }

      String? bookmark;
      if (Platform.isMacOS) {
        try {
          await _stopAccessingCustomDirScopedResource();
          final sb = SecureBookmarks();
          bookmark = await sb.bookmark(dir);
          qqq("Created macOS bookmark for custom models dir: $selectedDir");
        } catch (e) {
          qqw("Failed to create macOS bookmark for $selectedDir: $e");
        }
      }

      P.preference.setCustomModelsDir(selectedDir, bookmark: bookmark);
      Alert.info(S.current.please_manually_migrate_files);
      cleanDownloadTasks();
      return true;
    } catch (e) {
      qqe(e);
      Alert.error(e.toString());
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
      return false;
    } finally {
      await sync();
    }
  }

  /// Reset to default models directory
  /// Only clears custom path in preference; does not migrate files. Use [Alert.info] to prompt manual migration.
  Future<void> resetToDefaultModelsDir({required BuildContext context}) async {
    if (Platform.isMacOS) {
      await _stopAccessingCustomDirScopedResource();
    }
    P.preference.setCustomModelsDir(null);
    Alert.info(S.current.please_manually_migrate_files);
    cleanDownloadTasks();
    await sync();
  }

  /// Stop accessing macOS security-scoped resource for custom models directory
  Future<void> _stopAccessingCustomDirScopedResource() async {
    if (_macosCustomDirScopedResource != null) {
      try {
        await SecureBookmarks().stopAccessingSecurityScopedResource(_macosCustomDirScopedResource!);
        qqq("Stopped accessing macOS scoped resource: ${_macosCustomDirScopedResource!.path}");
      } catch (e) {
        qqw("Failed to stop accessing macOS scoped resource: $e");
      }
      _macosCustomDirScopedResource = null;
    }
  }

  /// Restore macOS security-scoped bookmark access for custom models directory
  /// Called during app initialization
  Future<void> restoreCustomModelsDirAccess() async {
    if (!Platform.isMacOS) return;

    final bookmark = P.preference.customModelsDirBookmark.q;
    final customDir = P.preference.customModelsDir.q;
    if (bookmark == null || bookmark.isEmpty || customDir == null) return;

    try {
      final sb = SecureBookmarks();
      final entity = await sb.resolveBookmark(bookmark, isDirectory: true);
      final ok = await sb.startAccessingSecurityScopedResource(entity);
      if (ok) {
        _macosCustomDirScopedResource = entity;
        // Update the path in case it changed (e.g., volume name change)
        if (entity.path != customDir) {
          qqq("Custom models dir path updated from bookmark: $customDir -> ${entity.path}");
          P.preference.setCustomModelsDir(entity.path, bookmark: bookmark);
        }
        qqq("Restored macOS scoped resource access for: ${entity.path}");
      } else {
        qqw("Failed to start accessing macOS scoped resource for: $customDir");
      }
    } catch (e) {
      qqw("Failed to restore macOS bookmark for custom models dir: $e");
      // Clear invalid bookmark
      P.preference.setCustomModelsDir(null);
    }
  }

  /// Get all file names from configuration (including unavailable ones)
  /// This is used to determine which files are recognized vs "other files"
  Set<String> getAllConfigFileNames() {
    final config = P.app._config.q;
    if (config == null) {
      return {};
    }

    final allFileNames = <String>{};

    // Extract from all demo types
    for (final demoType in ['chat', 'tts', 'world', 'sudoku', 'othello', 'roleplay', 'albatross']) {
      final demoConfig = config[demoType];
      if (demoConfig is Map && demoConfig['model_config'] is List) {
        final modelConfigs = HF.listJSON(demoConfig['model_config']);
        for (final modelConfig in modelConfigs) {
          try {
            final fileInfo = FileInfo.fromJSON(modelConfig);
            allFileNames.add(fileInfo.fileName);
          } catch (e) {
            qqe("Failed to parse file info from config: $e");
          }
        }
      }
    }

    return allFileNames;
  }

  /// Check if a file would already exist at the target location
  /// Returns the FileInfo if file is in config, null otherwise
  /// Throws exception if file is not in configuration
  Future<FileInfo?> checkFileExistsInConfig(String fileName) async {
    final config = P.app._config.q;
    if (config == null) {
      throw Exception("Configuration not loaded");
    }

    final allFileInfos = <FileInfo>{};

    // Extract from all demo types
    for (final demoType in ['chat', 'tts', 'world', 'sudoku', 'othello', 'roleplay', 'albatross']) {
      final demoConfig = config[demoType];
      if (demoConfig is Map && demoConfig['model_config'] is List) {
        final modelConfigs = HF.listJSON(demoConfig['model_config']);
        for (final modelConfig in modelConfigs) {
          try {
            final fileInfo = FileInfo.fromJSON(modelConfig);
            allFileInfos.add(fileInfo);
          } catch (e) {
            qqe("Failed to parse file info from config: $e");
          }
        }
      }
    }

    // Find matching file info by fileName
    try {
      final matchingFileInfo = allFileInfos.firstWhere(
        (info) => info.fileName == fileName,
      );

      // Check if target file already exists
      final targetPath = _paths(matchingFileInfo).q;
      if (targetPath.isEmpty) {
        return null;
      }
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        return matchingFileInfo;
      }
      return null; // File is in config but doesn't exist yet
    } catch (e) {
      throw Exception("File not found in configuration");
    }
  }

  /// Import a weight file from external source
  /// Returns true if import was successful, false otherwise
  /// [overwrite] if true, will overwrite existing file; if false, will throw exception if file exists
  /// [sourceFile] the source file (used when path is available, e.g., Android, desktop)
  /// [fileBytes] the file bytes (used when path is null, e.g., iOS iCloud Drive)
  /// [fileName] the file name (required when using fileBytes)
  Future<bool> importWeightFile({
    File? sourceFile,
    Uint8List? fileBytes,
    String? fileName,
    bool overwrite = false,
  }) async {
    qq;

    // Get the file name
    final actualFileName = fileName ?? (sourceFile != null ? basename(sourceFile.path) : throw Exception("File name is required"));

    // Validate that we have either sourceFile or fileBytes
    if (sourceFile == null && fileBytes == null) {
      throw Exception("Either sourceFile or fileBytes must be provided");
    }

    // Check if the file exists in the configuration
    // Get all file infos from config (not just available ones)
    final config = P.app._config.q;
    if (config == null) {
      throw Exception("Configuration not loaded");
    }

    final allFileInfos = <FileInfo>{};

    // Extract from all demo types
    for (final demoType in ['chat', 'tts', 'world', 'sudoku', 'othello', 'roleplay', 'albatross']) {
      final demoConfig = config[demoType];
      if (demoConfig is Map && demoConfig['model_config'] is List) {
        final modelConfigs = HF.listJSON(demoConfig['model_config']);
        for (final modelConfig in modelConfigs) {
          try {
            final fileInfo = FileInfo.fromJSON(modelConfig);
            allFileInfos.add(fileInfo);
          } catch (e) {
            qqe("Failed to parse file info from config: $e");
          }
        }
      }
    }

    // Find matching file info by fileName
    FileInfo? matchingFileInfo;
    try {
      matchingFileInfo = allFileInfos.firstWhere(
        (info) => info.fileName == actualFileName,
      );
    } catch (e) {
      throw Exception("File not found in configuration");
    }

    // Get the target path
    final targetPath = _paths(matchingFileInfo).q;
    if (targetPath.isEmpty) {
      throw Exception(_modelsDirNotReadyMessage);
    }
    final targetFile = File(targetPath);

    // Check if target file already exists
    if (await targetFile.exists()) {
      if (!overwrite) {
        qqw("Target file already exists: $targetPath");
        throw Exception("File already exists");
      } else {
        // Delete existing file if overwrite is true
        try {
          await targetFile.delete();
          qqq("Deleted existing file for overwrite: $targetPath");
        } catch (e) {
          qqe("Failed to delete existing file: $e");
          throw Exception("Failed to delete existing file");
        }
      }
    }

    // Ensure target directory exists
    final targetDir = Directory(dirname(targetPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // Copy the file
    try {
      if (sourceFile != null) {
        // Use file copy (faster for large files when path is available)
        await sourceFile.copy(targetPath);
      } else if (fileBytes != null) {
        // Write bytes directly (for iOS when path is null)
        await File(targetPath).writeAsBytes(fileBytes);
      } else {
        throw Exception("No file data available");
      }
      qqq("Successfully imported file: $actualFileName to $targetPath");

      // Verify file size if available
      if (matchingFileInfo.fileSize > 0) {
        final copiedFileSize = await targetFile.length();
        if (copiedFileSize != matchingFileInfo.fileSize) {
          qqw("File size mismatch: expected ${matchingFileInfo.fileSize}, got $copiedFileSize");
          // In non-debug mode, delete the file if size doesn't match
          if (!kDebugMode) {
            await targetFile.delete();
            throw Exception("File size mismatch");
          }
        }
      }

      // Update local file status for this specific file only (much faster than checkLocal)
      final state = locals(matchingFileInfo);
      state.q = state.q.copyWith(
        hasFile: true,
        state: TaskState.completed,
        progress: 1.0,
      );

      return true;
    } catch (e) {
      qqe("Failed to import file: $e");
      // Clean up if file was partially copied
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (deleteError) {
          qqe("Failed to delete partially copied file: $deleteError");
        }
      }
      rethrow;
    }
  }

  /// Import all weight files from a ZIP file
  /// Returns the number of files successfully imported
  Future<int> importAllWeightFiles({
    required File zipFile,
    void Function(String currentFile, int completed, int total)? onProgress,
  }) async {
    qq;

    if (P.app.isDesktop.q && _getReadyModelsDirPath() == null) {
      throw Exception(_modelsDirNotReadyMessage);
    }

    // Read and decode ZIP file
    final zipBytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    if (archive.isEmpty) {
      throw Exception("ZIP file is empty");
    }

    // Get all file infos from config
    final config = P.app._config.q;
    if (config == null) {
      throw Exception("Configuration not loaded");
    }

    final allFileInfos = <FileInfo>{};
    for (final demoType in ['chat', 'tts', 'world', 'sudoku', 'othello', 'roleplay', 'albatross']) {
      final demoConfig = config[demoType];
      if (demoConfig is Map && demoConfig['model_config'] is List) {
        final modelConfigs = HF.listJSON(demoConfig['model_config']);
        for (final modelConfig in modelConfigs) {
          try {
            final fileInfo = FileInfo.fromJSON(modelConfig);
            allFileInfos.add(fileInfo);
          } catch (e) {
            qqe("Failed to parse file info from config: $e");
          }
        }
      }
    }

    // Find files in ZIP that match config
    final filesToImport = <ArchiveFile>[];
    for (final file in archive) {
      if (!file.isFile) continue;
      final fileName = basename(file.name);
      final matchingFileInfo = allFileInfos.where((info) => info.fileName == fileName).firstOrNull;
      if (matchingFileInfo != null) {
        filesToImport.add(file);
      }
    }

    if (filesToImport.isEmpty) {
      throw Exception("No valid weight files found in ZIP");
    }

    final total = filesToImport.length;
    int completed = 0;
    int successCount = 0;

    // Import each file
    for (final archiveFile in filesToImport) {
      final fileName = basename(archiveFile.name);
      if (onProgress != null) {
        onProgress(fileName, completed, total);
      }

      try {
        // Find matching file info
        final matchingFileInfo = allFileInfos.firstWhere((info) => info.fileName == fileName);

        // Get target path
        final targetPath = _paths(matchingFileInfo).q;
        if (targetPath.isEmpty) {
          completed++;
          continue;
        }
        final targetFile = File(targetPath);

        // Delete existing file if it exists (overwrite)
        if (await targetFile.exists()) {
          try {
            await targetFile.delete();
            qqq("Deleted existing file for overwrite: $targetPath");
          } catch (e) {
            qqe("Failed to delete existing file: $e");
            completed++;
            continue;
          }
        }

        // Ensure target directory exists
        final targetDir = Directory(dirname(targetPath));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        // Extract file from archive
        final fileBytes = archiveFile.content;
        await targetFile.writeAsBytes(fileBytes);
        qqq("Successfully imported file: $fileName to $targetPath");

        // Verify file size if available
        if (matchingFileInfo.fileSize > 0) {
          final copiedFileSize = await targetFile.length();
          if (copiedFileSize != matchingFileInfo.fileSize) {
            qqw("File size mismatch: expected ${matchingFileInfo.fileSize}, got $copiedFileSize");
            // In non-debug mode, delete the file if size doesn't match
            if (!kDebugMode) {
              await targetFile.delete();
              completed++;
              continue;
            }
          }
        }

        // Update local file status
        final state = locals(matchingFileInfo);
        state.q = state.q.copyWith(
          hasFile: true,
          state: TaskState.completed,
          progress: 1.0,
        );

        successCount++;
      } catch (e) {
        qqe("Failed to import $fileName: $e");
      }

      completed++;
    }

    if (onProgress != null) {
      onProgress("", completed, total);
    }

    qqq("Import completed: $successCount/$total files imported");
    return successCount;
  }

  /// Export a single weight file to a user-selected directory
  /// Returns true if export was successful, false otherwise
  Future<bool> exportWeightFile({
    required FileInfo fileInfo,
    required String targetDirectory,
  }) async {
    qq;

    final sourcePath = _paths(fileInfo).q;
    if (sourcePath.isEmpty) {
      throw Exception(_modelsDirNotReadyMessage);
    }
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      qqe("Source file does not exist: $sourcePath");
      throw Exception("Source file does not exist");
    }

    final targetFile = File("$targetDirectory/${fileInfo.fileName}");

    // Check if target file already exists
    if (await targetFile.exists()) {
      qqw("Target file already exists: ${targetFile.path}");
      throw Exception("Target file already exists");
    }

    // Ensure target directory exists
    final targetDir = Directory(targetDirectory);
    if (!await targetDir.exists()) {
      try {
        await targetDir.create(recursive: true);
      } catch (e) {
        qqe("Failed to create target directory: $e");
        throw Exception("Failed to create target directory");
      }
    }

    // On iOS, try to access security-scoped resource if needed
    bool? securityScopedAccessGranted;
    if (Platform.isIOS) {
      try {
        securityScopedAccessGranted = await P.adapter.call<bool>(
          ToNative.startAccessingSecurityScopedResource,
          targetDirectory,
        );
        if (securityScopedAccessGranted == true) {
          qqq("Successfully accessed security-scoped resource: $targetDirectory");
        }
      } catch (e) {
        qqw("Failed to access security-scoped resource: $e");
      }
    }

    try {
      // Try direct copy first (faster for large files)
      try {
        await sourceFile.copy(targetFile.path);
        qqq("Successfully exported file: ${fileInfo.fileName} to ${targetFile.path}");
        return true;
      } catch (copyError) {
        // If direct copy fails (e.g., iOS permission issue), read and write bytes
        qqw("Direct copy failed, trying read-write method: $copyError");
        try {
          final fileBytes = await sourceFile.readAsBytes();
          await targetFile.writeAsBytes(fileBytes);
          qqq("Successfully exported file (via bytes): ${fileInfo.fileName} to ${targetFile.path}");
          return true;
        } catch (writeError) {
          // If both methods fail, check if it's an iOS permission issue
          final errorStr = writeError.toString();
          if (Platform.isIOS && (errorStr.contains("Operation not permitted") || errorStr.contains("errno: 1"))) {
            qqe("iOS permission error: Cannot access selected directory. The selected directory may require special permissions.");
            throw Exception(
              "Permission denied: The selected directory cannot be accessed. Please try selecting a different location, such as Files app or iCloud Drive.",
            );
          }
          rethrow;
        }
      }
    } catch (e) {
      qqe("Failed to export file: $e");
      // Clean up if file was partially written
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (deleteError) {
          qqe("Failed to delete partially written file: $deleteError");
        }
      }
      rethrow;
    } finally {
      // On iOS, stop accessing security-scoped resource
      if (Platform.isIOS && securityScopedAccessGranted == true) {
        try {
          await P.adapter.call(ToNative.stopAccessingSecurityScopedResource, targetDirectory);
          qqq("Stopped accessing security-scoped resource: $targetDirectory");
        } catch (e) {
          qqw("Failed to stop accessing security-scoped resource: $e");
        }
      }
    }
  }

  /// Export all weight files to user-selected directory (individual files, not zipped)
  /// Only exports files that exist locally
  /// Returns the target directory path
  Future<String> exportAllWeightFiles({
    required String targetDirectory,
    void Function(String currentFile, int completed, int total)? onProgress,
  }) async {
    qq;

    if (P.app.isDesktop.q && _getReadyModelsDirPath() == null) {
      throw Exception(_modelsDirNotReadyMessage);
    }

    // Get all weight files that exist locally
    final allWeights = [
      ...chatWeights.q,
      ...roleplayWeights.q,
      ...ttsWeights.q,
      ...seeWeights.q,
      ...sudokuWeights.q,
      ...othelloWeights.q,
    ];

    final filesToExport = <FileInfo>[];
    for (final fileInfo in allWeights) {
      final local = locals(fileInfo).q;
      if (local.hasFile) {
        filesToExport.add(fileInfo);
      }
    }

    if (filesToExport.isEmpty) {
      throw Exception("No files to export");
    }

    final total = filesToExport.length;
    int completed = 0;
    int successCount = 0;

    // Ensure target directory exists
    final targetDir = Directory(targetDirectory);
    if (!await targetDir.exists()) {
      try {
        await targetDir.create(recursive: true);
      } catch (e) {
        qqe("Failed to create target directory: $e");
        throw Exception("Failed to create target directory");
      }
    }

    // On iOS, try to access security-scoped resource if needed
    bool? securityScopedAccessGranted;
    if (Platform.isIOS) {
      try {
        securityScopedAccessGranted = await P.adapter.call<bool>(
          ToNative.startAccessingSecurityScopedResource,
          targetDirectory,
        );
        if (securityScopedAccessGranted == true) {
          qqq("Successfully accessed security-scoped resource: $targetDirectory");
        }
      } catch (e) {
        qqw("Failed to access security-scoped resource: $e");
      }
    }

    try {
      for (final fileInfo in filesToExport) {
        if (onProgress != null) {
          onProgress(fileInfo.fileName, completed, total);
        }

        try {
          final sourcePath = _paths(fileInfo).q;
          if (sourcePath.isEmpty) {
            completed++;
            continue;
          }
          final sourceFile = File(sourcePath);

          if (!await sourceFile.exists()) {
            qqw("Source file does not exist, skipping: $sourcePath");
            completed++;
            continue;
          }

          final targetFile = File("$targetDirectory/${fileInfo.fileName}");

          // Check if target file already exists
          if (await targetFile.exists()) {
            qqw("Target file already exists, skipping: ${fileInfo.fileName}");
            completed++;
            continue;
          }

          // Try direct copy first (faster for large files)
          try {
            await sourceFile.copy(targetFile.path);
            qqq("Exported: ${fileInfo.fileName}");
            successCount++;
          } catch (copyError) {
            // If direct copy fails (e.g., iOS permission issue), read and write bytes
            qqw("Direct copy failed, trying read-write method: $copyError");
            try {
              final fileBytes = await sourceFile.readAsBytes();
              await targetFile.writeAsBytes(fileBytes);
              qqq("Exported (via bytes): ${fileInfo.fileName}");
              successCount++;
            } catch (writeError) {
              qqe("Failed to export ${fileInfo.fileName}: $writeError");
            }
          }

          completed++;
        } catch (e) {
          qqe("Failed to export ${fileInfo.fileName}: $e");
          completed++;
        }
      }

      if (onProgress != null) {
        onProgress("", completed, total);
      }

      qqq("Export completed: $successCount/$total files exported to $targetDirectory");
      return targetDirectory;
    } catch (e) {
      final errorStr = e.toString();
      if (Platform.isIOS && (errorStr.contains("Operation not permitted") || errorStr.contains("errno: 1"))) {
        qqe("iOS permission error: Cannot access selected directory. The selected directory may require special permissions.");
        throw Exception(
          "Permission denied: The selected directory cannot be accessed. Please try selecting a different location, such as Files app or iCloud Drive.",
        );
      }
      rethrow;
    } finally {
      // On iOS, stop accessing security-scoped resource
      if (Platform.isIOS && securityScopedAccessGranted == true) {
        try {
          await P.adapter.call(ToNative.stopAccessingSecurityScopedResource, targetDirectory);
          qqq("Stopped accessing security-scoped resource: $targetDirectory");
        } catch (e) {
          qqw("Failed to stop accessing security-scoped resource: $e");
        }
      }
    }
  }

  /// Pick and import multiple weight files from device storage
  /// Returns (successCount, failCount, failedFiles)
  /// This handles the full import flow including file picker, validation, and copying
  Future<(int, int, List<String>)> pickAndImportWeightFiles({
    required BuildContext context,
  }) async {
    qq;

    // Pick files
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['st', 'gguf', 'prefab', 'bin', 'rmpack', 'mnn', 'zip'],
    );

    if (result == null || result.files.isEmpty) {
      return (0, 0, <String>[]);
    }

    final pickedFiles = result.files;
    final totalFiles = pickedFiles.length;

    // First, validate all files and check for existing files
    final List<_FileImportInfo> fileInfos = [];
    bool hasExistingFiles = false;

    for (final pickedFile in pickedFiles) {
      final sourcePath = pickedFile.path;
      final fileName = pickedFile.name;

      File? sourceFile;
      Uint8List? fileBytes;

      if (sourcePath != null) {
        sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) {
          fileInfos.add(
            _FileImportInfo(
              pickedFile: pickedFile,
              sourceFile: null,
              fileBytes: null,
              existingFileInfo: null,
              error: S.current.file_not_found,
            ),
          );
          continue;
        }
      } else {
        if (pickedFile.bytes == null) {
          fileInfos.add(
            _FileImportInfo(
              pickedFile: pickedFile,
              sourceFile: null,
              fileBytes: null,
              existingFileInfo: null,
              error: S.current.file_path_not_found,
            ),
          );
          continue;
        }
        fileBytes = pickedFile.bytes;
      }

      FileInfo? existingFileInfo;
      try {
        final fileNameToCheck = fileName.isNotEmpty ? fileName : (sourceFile != null ? basename(sourceFile.path) : "unknown");
        existingFileInfo = await checkFileExistsInConfig(fileNameToCheck);
        if (existingFileInfo != null) {
          hasExistingFiles = true;
        }
      } catch (e) {
        final errorMessage = e.toString();
        if (errorMessage.contains("not found in configuration")) {
          fileInfos.add(
            _FileImportInfo(
              pickedFile: pickedFile,
              sourceFile: sourceFile,
              fileBytes: fileBytes,
              existingFileInfo: null,
              error: S.current.file_not_supported,
            ),
          );
          continue;
        } else {
          fileInfos.add(
            _FileImportInfo(
              pickedFile: pickedFile,
              sourceFile: sourceFile,
              fileBytes: fileBytes,
              existingFileInfo: null,
              error: e.toString(),
            ),
          );
          continue;
        }
      }

      fileInfos.add(
        _FileImportInfo(
          pickedFile: pickedFile,
          sourceFile: sourceFile,
          fileBytes: fileBytes,
          existingFileInfo: existingFileInfo,
          error: null,
        ),
      );
    }

    // If there are existing files, ask user for confirmation
    bool shouldOverwrite = false;
    if (hasExistingFiles) {
      if (!context.mounted) {
        return (0, 0, <String>[]);
      }
      final s = S.current;
      final existingCount = fileInfos.where((info) => info.existingFileInfo != null && info.error == null).length;
      final message = existingCount == 1
          ? s.overwrite_file_confirmation
          : "${s.overwrite_file_confirmation}\n\n($existingCount ${S.current.files})";

      final confirmResult = await showOkCancelAlertDialog(
        context: context,
        title: s.file_already_exists,
        message: message,
        okLabel: s.overwrite,
        cancelLabel: s.cancel,
        isDestructiveAction: true,
      );

      if (confirmResult != OkCancelResult.ok) {
        return (0, 0, <String>[]); // User cancelled
      }
      shouldOverwrite = true;
    }

    int successCount = 0;
    int failCount = 0;
    final List<String> failedFiles = [];

    // Process each file
    for (final fileInfo in fileInfos) {
      final pickedFile = fileInfo.pickedFile;
      final fileName = pickedFile.name;

      // Skip files with errors
      if (fileInfo.error != null) {
        failCount++;
        failedFiles.add("$fileName: ${fileInfo.error}");
        continue;
      }

      // Import the file
      try {
        final fileNameToUse = pickedFile.name.isNotEmpty
            ? pickedFile.name
            : (fileInfo.sourceFile != null ? basename(fileInfo.sourceFile!.path) : "unknown");

        final success = await importWeightFile(
          sourceFile: fileInfo.sourceFile,
          fileBytes: fileInfo.fileBytes,
          fileName: fileNameToUse,
          overwrite: shouldOverwrite && fileInfo.existingFileInfo != null,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
          failedFiles.add("$fileName: ${S.current.import_failed}");
        }
      } catch (e) {
        failCount++;
        failedFiles.add("$fileName: ${e.toString()}");
      }
    }

    // Show result summary
    if (successCount > 0 && failCount == 0) {
      Alert.success(totalFiles == 1 ? S.current.import_success : "$successCount ${S.current.import_success}");
    } else if (successCount > 0 && failCount > 0) {
      final message = "$successCount ${S.current.import_success}\n$failCount ${S.current.import_failed}\n\n${failedFiles.join('\n')}";
      Alert.warning(message);
    } else if (failCount > 0) {
      final message = "${S.current.import_failed}:\n${failedFiles.join('\n')}";
      Alert.error(message);
    }

    return (successCount, failCount, failedFiles);
  }

  /// Pick directory and export all weight files
  /// Returns true if export was successful
  Future<bool> pickAndExportAllWeightFiles({
    required BuildContext context,
    void Function(String currentFile, int completed, int total)? onProgress,
  }) async {
    qq;

    // Check if there are any files to export
    final allWeights = [
      ...chatWeights.q,
      ...roleplayWeights.q,
      ...ttsWeights.q,
      ...seeWeights.q,
      ...sudokuWeights.q,
      ...othelloWeights.q,
    ];

    final filesToExport = allWeights.where((fileInfo) {
      final local = locals(fileInfo).q;
      return local.hasFile;
    }).toList();

    if (filesToExport.isEmpty) {
      Alert.warning(S.current.no_weight_files_to_export);
      return false;
    }

    // Show confirmation dialog
    final s = S.current;
    final confirmResult = await showOkCancelAlertDialog(
      context: context,
      title: s.export_all_weight_files,
      message: s.export_all_weight_files_description,
      okLabel: s.export_all_weight_files,
      cancelLabel: s.cancel,
    );

    if (confirmResult != OkCancelResult.ok) {
      return false; // User cancelled
    }

    // Select target directory
    final targetDirectory = await file_picker.FilePicker.getDirectoryPath();
    if (targetDirectory == null) {
      return false; // User cancelled
    }

    // Export all files
    try {
      final exportDirectory = await exportAllWeightFiles(
        targetDirectory: targetDirectory,
        onProgress: onProgress,
      );

      Alert.success("${S.current.export_success}\n\nDirectory: $exportDirectory");
      return true;
    } catch (e) {
      Alert.error("${S.current.export_failed}: $e");
      return false;
    }
  }

  /// Pick directory and export a single weight file
  /// Returns true if export was successful
  Future<bool> pickAndExportWeightFile({
    required FileInfo fileInfo,
  }) async {
    qq;

    // Select target directory
    final targetDirectory = await file_picker.FilePicker.getDirectoryPath();
    if (targetDirectory == null) {
      return false; // User cancelled
    }

    // Export the file
    try {
      await exportWeightFile(
        fileInfo: fileInfo,
        targetDirectory: targetDirectory,
      );

      Alert.success(S.current.export_success);
      return true;
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains("already exists")) {
        Alert.error(S.current.file_already_exists);
      } else {
        Alert.error("${S.current.export_failed}: $e");
      }
      return false;
    }
  }

  /// Get all downloaded weight files for display
  List<FileInfo> getDownloadedWeights() {
    final allWeights = [
      ...chatWeights.q,
      ...roleplayWeights.q,
      ...ttsWeights.q,
      ...seeWeights.q,
      ...sudokuWeights.q,
      ...othelloWeights.q,
    ];

    return allWeights.where((fileInfo) {
      final local = locals(fileInfo).q;
      return local.hasFile;
    }).toList();
  }

  /// Check if there are any downloaded weight files
  bool hasDownloadedWeights() {
    return getDownloadedWeights().isNotEmpty;
  }

  /// 获取 /models 目录下未, 未记录至 latest.json 的文件
  Future<List<UnrecognizedFile>> getUnrecognizedFiles() async {
    final targetDirPath = await _getModelsDirPathForScan();
    if (targetDirPath == null) {
      return [];
    }

    final directory = Directory(targetDirPath);
    qqr("targetDir: $targetDirPath");
    if (!await directory.exists()) {
      Sentry.captureException(Exception("directory not found: $targetDirPath"), stackTrace: StackTrace.current);
      return [];
    }

    // Get all file names from config (not just available ones)
    final allWeightFileNames = getAllConfigFileNames();

    // Build a set of temporary file paths that belong to active download tasks
    final downloadingTmpPaths = <String>{};
    final downloadingCandidates = [
      chatWeights.q,
      roleplayWeights.q,
      ttsWeights.q,
      seeWeights.q,
      sudokuWeights.q,
      othelloWeights.q,
    ].expand((e) => e).where((e) => e.available).toList();

    for (final fileInfo in downloadingCandidates) {
      final local = locals(fileInfo).q;
      if (!local.downloading) continue;
      downloadingTmpPaths.add("${local.targetPath}.tmp");
    }

    final currentConfigInPlaceCacheDirNames = _getCurrentConfigInPlaceCacheDirNames();
    final shouldDetectInPlaceCacheDirs = Platform.isIOS || Platform.isMacOS;
    final unrecognizedFiles = <UnrecognizedFile>[];

    try {
      final entities = directory.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final filePath = entity.path;

          // Skip files that are temporary files of active download tasks
          if (downloadingTmpPaths.contains(filePath)) {
            continue;
          }

          final fileName = basename(filePath);
          if (allWeightFileNames.contains(fileName)) continue;

          final fileSize = await entity.length();

          unrecognizedFiles.add(
            UnrecognizedFile(
              fileName: fileName,
              filePath: filePath,
              fileSize: fileSize,
              isDirectory: false,
            ),
          );
          continue;
        }
        if (entity is! Directory) {
          continue;
        }
        if (!shouldDetectInPlaceCacheDirs) {
          continue;
        }
        final dirName = basename(entity.path);
        final dirNameLower = dirName.toLowerCase();
        final looksLikeInPlaceCache = dirNameLower.contains("-mlx-") || dirNameLower.contains("-coreml-");
        if (!looksLikeInPlaceCache) {
          continue;
        }
        if (currentConfigInPlaceCacheDirNames.contains(dirName)) {
          continue;
        }
        final directorySize = await calculateTotalSizeOfDir(entity.path);

        unrecognizedFiles.add(
          UnrecognizedFile(
            fileName: dirName,
            filePath: entity.path,
            fileSize: directorySize,
            isDirectory: true,
          ),
        );
      }
    } catch (e) {
      // Ignore errors when listing directory
    }

    return unrecognizedFiles;
  }

  /// 获取 /models 目录中由 MLX/CoreML zip 解压产生的缓存目录
  Future<List<MlxCacheDirectory>> getMlxCacheDirectories() async {
    final shouldDetectInPlaceCacheDirs = Platform.isIOS || Platform.isMacOS;
    if (!shouldDetectInPlaceCacheDirs) {
      return [];
    }

    final targetDirPath = await _getModelsDirPathForScan();
    if (targetDirPath == null) {
      return [];
    }

    final directory = Directory(targetDirPath);
    if (!await directory.exists()) {
      Sentry.captureException(Exception("directory not found: $targetDirPath"), stackTrace: StackTrace.current);
      return [];
    }

    final mlxCacheDirNames = _getCurrentConfigInPlaceCacheDirNames();
    if (mlxCacheDirNames.isEmpty) {
      return [];
    }

    final caches = <MlxCacheDirectory>[];
    try {
      final entities = directory.listSync();
      for (final entity in entities) {
        if (entity is! Directory) {
          continue;
        }
        final dirName = basename(entity.path);
        if (!mlxCacheDirNames.contains(dirName)) {
          continue;
        }

        final directorySize = await calculateTotalSizeOfDir(entity.path);
        caches.add(
          MlxCacheDirectory(
            directoryName: dirName,
            directoryPath: entity.path,
            directorySize: directorySize,
          ),
        );
      }
    } catch (_) {
      return [];
    }

    caches.sort((MlxCacheDirectory a, MlxCacheDirectory b) => b.directorySize.compareTo(a.directorySize));
    return caches;
  }

  /// Refresh unrecognized files and store into state
  Future<void> refreshUnrecognizedFiles() async {
    final files = await getUnrecognizedFiles();
    unrecognizedFiles.q = files;
  }

  /// Refresh MLX cache directories and store into state
  Future<void> refreshMlxCacheDirectories() async {
    final directories = await getMlxCacheDirectories();
    mlxCacheDirectories.q = directories;
  }

  /// Delete an unrecognized file
  Future<void> deleteUnrecognizedFile(UnrecognizedFile file) async {
    try {
      if (file.isDirectory) {
        await Directory(file.filePath).delete(recursive: true);
        return;
      }
      await File(file.filePath).delete();
    } catch (e) {
      qqe("Failed to delete file: $e");
      rethrow;
    }
  }

  /// Delete an MLX cache directory
  Future<void> deleteMlxCacheDirectory(MlxCacheDirectory directory) async {
    try {
      await Directory(directory.directoryPath).delete(recursive: true);
    } catch (e) {
      qqe("Failed to delete MLX cache directory: $e");
      rethrow;
    }
  }

  Future<FileInfo?> pickLocalPthFile() async {
    String? initialDirectory;
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        initialDirectory = downloadsDir.path;
      }
    } catch (_) {}
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['pth'],
      initialDirectory: initialDirectory,
    );
    if (result == null) {
      return null;
    }
    final file = File(result.files.single.path!);
    final fileName = basename(file.path);
    final fileInfo = FileInfo(
      name: fileName,
      fileName: file.path,
      fileType: FileType.weights,
      fileSize: file.lengthSync(),
      raw: file.path,
      isDebug: false,
      availableIn: const [],
      supportedPlatforms: const [],
      backend: Backend.webRwkv,
      sha256: null,
      modelSize: null,
      quantization: null,
      updatedAt: null,
      timestamp: null,
      date: null,
      fromPthFile: true,
    );

    await P.rwkv.loadChat(fileInfo: fileInfo);
    return fileInfo;
  }

  Future<void> sync() async {
    qr;

    syncingLocalFiles.q = true;
    await Future.wait([
      400.msLater,
      checkLocal(),
      refreshUnrecognizedFiles(),
      refreshMlxCacheDirectories(),
    ]);
    final readyModelsDir = _getReadyModelsDirPath();
    if (readyModelsDir == null) {
      totalSizeInModelsDir.q = 0;
      syncingLocalFiles.q = false;
      return;
    }
    await calculateTotalSizeOfDir(readyModelsDir);
    syncingLocalFiles.q = false;
  }
}

Set<String> _getCurrentConfigInPlaceCacheDirNames() {
  final allWeights = <FileInfo>[
    ...P.remote.chatWeights.q,
    ...P.remote.roleplayWeights.q,
    ...P.remote.ttsWeights.q,
    ...P.remote.seeWeights.q,
    ...P.remote.sudokuWeights.q,
    ...P.remote.othelloWeights.q,
  ];

  final dirNames = <String>{};
  for (final fileInfo in allWeights) {
    final backend = fileInfo.backend;
    if (backend != Backend.mlx && backend != Backend.coreml) {
      continue;
    }
    final dirName = basenameWithoutExtension(fileInfo.fileName);
    if (dirName.isEmpty) {
      continue;
    }
    dirNames.add(dirName);
  }
  return dirNames;
}

/// Private methods
extension _$Remote on _Remote {
  Future<void> _init() async {
    try {
      // Restore macOS security-scoped bookmark access for custom models directory
      await restoreCustomModelsDirAccess();

      await syncAvailableModels();
      // Check and perform migration if needed
      // Only migrate for users with build number < 637
      if (!P.preference.weightsMigrationCompleted.q) {
        // final currentBuildNumber = int.tryParse(P.app.buildNumber.q) ?? 0;
        // if (currentBuildNumber < 637) {
        await _migrateFilesToWeightsFolder();
        // } else {
        //   // Mark as completed for users with build >= 637
        //   P.preference.setWeightsMigrationCompleted(true);
        // }
      }
    } catch (e) {
      Sentry.captureException(e, stackTrace: StackTrace.current);
    }

    P.app.pageKey.lb(_onPageKeyChanged);
    hasActiveDownload.l(_onHasActiveDownloadChanged, fireImmediately: true);

    await _transferAllFilesFromOldModelsDirToNewModelsDirIfNeeded();
    sync();
  }

  void _onHasActiveDownloadChanged(bool hasActiveDownload) {
    P.app.setKeepScreenAwakeForReason(reason: .download, enabled: hasActiveDownload);
  }

  void _onPageKeyChanged(PageKey? previous, PageKey next) async {
    switch (next) {
      case .settings:
      case .weightManager:
        await sync();
        break;
      default:
        break;
    }
  }

  /// Migrate files from Documents root to Documents/models folder
  Future<void> _migrateFilesToWeightsFolder() async {
    qq;

    // Skip migration if custom directory is set
    if (P.preference.customModelsDir.q != null) {
      P.preference.setWeightsMigrationCompleted(true);
      return;
    }

    final documentsDir = P.app.effectiveDocumentsDir.q;
    if (documentsDir == null) {
      qqw("Documents directory is null, skipping migration");
      P.preference.setWeightsMigrationCompleted(true);
      return;
    }

    final documentsPath = documentsDir.path;
    final modelsDir = Directory("$documentsPath/${Config.desktopModelsDirName}");

    // Create models directory if it doesn't exist
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
      qqq("Created models directory: ${modelsDir.path}");
    }

    // Extract known file names from current config
    final knownFileNames = <String>{};
    final config = P.app._config.q;
    if (config != null) {
      for (final demoType in ['chat', 'tts', 'world', 'sudoku', 'othello', 'roleplay', 'albatross']) {
        final demoConfig = config[demoType];
        if (demoConfig is Map && demoConfig['model_config'] is List) {
          final modelConfigs = HF.listJSON(demoConfig['model_config']);
          for (final modelConfig in modelConfigs) {
            // Try to get fileName from fileName field
            if (modelConfig['fileName'] is String) {
              knownFileNames.add(modelConfig['fileName'] as String);
            }
            // Also extract from url if fileName is not available
            if (modelConfig['url'] is String) {
              final url = modelConfig['url'] as String;
              final fileName = basename(Uri.parse(url).path);
              if (fileName.isNotEmpty && !fileName.contains('/')) {
                knownFileNames.add(fileName);
              }
            }
          }
        }
      }
    }

    qqq("Known file names from config: ${knownFileNames.length} files");

    // Pattern-based file extensions
    const modelFileExtensions = ['.st', '.gguf', '.prefab', '.bin', '.rmpack', '.mnn', '.zip'];

    // Scan Documents directory for files to migrate
    final filesToMigrate = <File>[];
    try {
      final entities = documentsDir.listSync();
      for (final entity in entities) {
        if (entity is! File) continue;

        final fileName = basename(entity.path);

        // Skip database files (.sqlite, .sqlite3, .db) - they should be in AppData, not Documents
        if (fileName.toLowerCase().endsWith('.sqlite') ||
            fileName.toLowerCase().endsWith('.sqlite3') ||
            fileName.toLowerCase().endsWith('.db')) {
          qqw("Skipping database file (should be in AppData): $fileName");
          continue;
        }

        final shouldMigrate =
            knownFileNames.contains(fileName) ||
            fileName.toLowerCase().contains('rwkv') ||
            modelFileExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));

        if (shouldMigrate) {
          filesToMigrate.add(entity);
        }
      }
    } catch (e) {
      qqe("Error scanning Documents directory: $e");
      P.preference.setWeightsMigrationCompleted(true);
      return;
    }

    qqq("Found ${filesToMigrate.length} files to migrate");

    // Migrate files
    int migratedCount = 0;
    int skippedCount = 0;
    for (final file in filesToMigrate) {
      final fileName = basename(file.path);
      final targetFile = File("${modelsDir.path}/$fileName");

      // Skip if target file already exists
      if (await targetFile.exists()) {
        qqq("Target file already exists, skipping: $fileName");
        skippedCount++;
        continue;
      }

      try {
        // Try to rename first (faster)
        try {
          await file.rename(targetFile.path);
          qqq("Migrated file (renamed): $fileName");
        } catch (e) {
          // If rename fails (e.g., cross-device), copy and delete
          await file.copy(targetFile.path);
          await file.delete();
          qqq("Migrated file (copied): $fileName");
        }
        migratedCount++;
      } catch (e) {
        qqe("Failed to migrate file $fileName: $e");
      }
    }

    // Also migrate associated folders (for extracted files)
    try {
      final entities = documentsDir.listSync();
      for (final entity in entities) {
        if (entity is! Directory) continue;

        final dirName = basename(entity.path);
        // Skip the models directory itself
        if (dirName == Config.desktopModelsDirName) continue;

        // Check if this directory corresponds to a migrated file
        final correspondingFile = filesToMigrate.firstWhereOrNull(
          (f) => basenameWithoutExtension(f.path) == dirName,
        );

        if (correspondingFile != null) {
          final targetDir = Directory("${modelsDir.path}/$dirName");
          if (!await targetDir.exists()) {
            try {
              await entity.rename(targetDir.path);
              qqq("Migrated directory: $dirName");
            } catch (e) {
              qqe("Failed to migrate directory $dirName: $e");
            }
          }
        }
      }
    } catch (e) {
      qqe("Error migrating directories: $e");
    }

    qqq("Migration completed: $migratedCount files migrated, $skippedCount files skipped");
    P.preference.setWeightsMigrationCompleted(true);
  }

  Future<void> _initModelDownloadTaskState() async {
    await 17.msLater;
    final availableFiles = [...chatWeights.q, ...roleplayWeights.q];
    final urlFmt = "${downloadSource.q.prefix}%s${downloadSource.q.suffix}";

    final stateFiles = availableFiles.map((e) => e.state).flattened.toSet();
    availableFiles.addAll(stateFiles);

    for (final fileInfo in availableFiles) {
      final taskId = fileInfo.fileName;
      final fileState = locals(fileInfo);

      if (_downloadTasks.containsKey(taskId)) {
        continue;
      }
      final path = _paths(fileInfo).q;
      if (path.isEmpty) {
        fileState.q = fileState.q.copyWith(state: TaskState.idle, hasFile: false);
        continue;
      }
      final url = fileInfo.raw.startsWith("http://") || fileInfo.raw.startsWith("https://")
          ? fileInfo.raw
          : sprintf(urlFmt, [fileInfo.raw]);
      try {
        final task = await DownloadTask.create(
          url: url,
          path: path,
          acceptedSize: kDebugMode ? null : fileInfo.fileSize,
        );
        // qqq('init download task state: ${fileInfo.fileName}: ${task.state}');
        fileState.q = fileState.q.copyWith(
          hasFile: task.state == TaskState.completed,
          state: task.state,
        );
        _downloadTasks[taskId] = task;
      } catch (e) {
        qqe(e);
        fileState.q = fileState.q.copyWith(state: TaskState.idle, hasFile: false);
      }
    }
  }

  Future<void> _transferAllFilesFromOldModelsDirToNewModelsDirIfNeeded() async {
    if (P.app.isDesktop.q) return;
    final documentsDir = P.app.documentsDir.q?.path;
    if (documentsDir == null) {
      Sentry.captureException(Exception("documentsDir is null, WTF?"), stackTrace: StackTrace.current);
      return;
    }
    final oldModelsDirPathInMobile = join(documentsDir, Config.desktopModelsDirName);
    final targetDirPath = join(documentsDir, Config.mobileModelsDirName);
    await transferAllFilesInDir(oldModelsDirPathInMobile, targetDirPath);
  }
}

/// Represents an unrecognized file in the models directory
class MlxCacheDirectory {
  final String directoryName;
  final String directoryPath;
  final int directorySize;

  const MlxCacheDirectory({
    required this.directoryName,
    required this.directoryPath,
    required this.directorySize,
  });
}

/// Represents an unrecognized file in the models directory
class UnrecognizedFile {
  final String fileName;
  final String filePath;
  final int fileSize;
  final bool isDirectory;

  const UnrecognizedFile({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    this.isDirectory = false,
  });
}

/// Internal class for tracking file import information
class _FileImportInfo {
  final file_picker.PlatformFile pickedFile;
  final File? sourceFile;
  final Uint8List? fileBytes;
  final FileInfo? existingFileInfo;
  final String? error;

  const _FileImportInfo({
    required this.pickedFile,
    required this.sourceFile,
    required this.fileBytes,
    required this.existingFileInfo,
    required this.error,
  });
}
