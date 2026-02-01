// ignore_for_file: unnecessary_brace_in_string_interps

part of 'p.dart';

class _FileManager {
  // ===========================================================================
  // Instance
  // ===========================================================================

  /// model-name to download-task map
  late final _downloadTasks = <String, DownloadTask>{};

  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final downloadSource = qs<FileDownloadSource>(P.preference.currentLangIsZh.q ? .aifasthub : .huggingface);

  /// 是否使用本地文件
  late final modelSelectorShown = qs(false);
  late final localPthFileOption = qs<LocalPthFileOption>(LocalPthFileOption.filesInConfig);

  late final locals = qsff<FileInfo, LocalFile>((ref, key) {
    return LocalFile(targetPath: ref.watch(_paths(key)));
  });

  late final _paths = qsff<FileInfo, String>((ref, key) {
    final customDir = ref.watch(P.preference.customModelsDir);
    if (customDir != null && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return "$customDir/${key.fileName}";
    }
    final dir = ref.watch(P.app.effectiveDocumentsDir);
    final fileName = key.fileName;
    final dirPath = dir!.path;
    return "$dirPath/${Config.modelsDirName}/$fileName";
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

  /// 获取所有支持的NPU芯片列表（从所有模型的socLimitations中提取）
  List<String> getSupportedNpuChips() {
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
extension $FileManager on _FileManager {
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

  Future<void> checkLocal() async {
    qq;
    await 17.msLater;
    final fileInfos = [
      chatWeights.q,
      roleplayWeights.q,
      ttsWeights.q,
      seeWeights.q,
      sudokuWeights.q,
      othelloWeights.q,
    ].expand((e) => e).where((e) => e.available).toList();

    for (final fileInfo in fileInfos) {
      final path = _paths(fileInfo).q;
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
      final state = locals(fileInfo);
      state.q = state.q.copyWith(hasFile: fileSizeVerified);
    }
    await _initModelDownloadTaskState();
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
    final modelsDir = Directory("${documentsDir.path}/${Config.modelsDirName}");
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
          qqw("fileName: ${path.basename(entity.path)}");
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
    final url = downloadSource.q.prefix + fileInfo.raw + downloadSource.q.suffix;
    final path = _paths(fileInfo).q;

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
            qqq('download update: state:${e.state}, speed:${e.speedInMB.toStringAsFixed(2)}MB/s, ${e.totalSize}');
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
    await File(path).delete();
    state.q = value.copyWith(hasFile: false, state: TaskState.idle, progress: 0);
  }

  Future<void> openModelDirectory() async {
    try {
      final customDir = P.preference.customModelsDir.q;
      final documentsDir = P.app.effectiveDocumentsDir.q?.path;
      final defaultDir = documentsDir != null ? path.join(documentsDir, Config.modelsDirName) : null;
      final dirPath = customDir ?? defaultDir;
      if (dirPath == null) return;
      qqr(dirPath);
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await launchUrl(Uri.directory(dirPath));
      }
    } catch (e) {
      qqe(e);
      Alert.error(e.toString());
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
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
    final actualFileName = fileName ?? (sourceFile != null ? path.basename(sourceFile.path) : throw Exception("File name is required"));

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
    final targetDir = Directory(path.dirname(targetPath));
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
      final fileName = path.basename(file.name);
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
      final fileName = path.basename(archiveFile.name);
      if (onProgress != null) {
        onProgress(fileName, completed, total);
      }

      try {
        // Find matching file info
        final matchingFileInfo = allFileInfos.firstWhere((info) => info.fileName == fileName);

        // Get target path
        final targetPath = _paths(matchingFileInfo).q;
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
        final targetDir = Directory(path.dirname(targetPath));
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

  Future<FileInfo?> pickLocalPthFile() async {
    String? initialDirectory;
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        initialDirectory = downloadsDir.path;
      }
    } catch (_) {}
    final result = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['pth'],
      initialDirectory: initialDirectory,
    );
    if (result == null) {
      return null;
    }
    final file = File(result.files.single.path!);
    final fileName = path.basename(file.path);
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
}

/// Private methods
extension _$FileManager on _FileManager {
  Future<void> _init() async {
    try {
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
    final modelsDir = Directory("$documentsPath/${Config.modelsDirName}");

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
              final fileName = path.basename(Uri.parse(url).path);
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

        final fileName = path.basename(entity.path);

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
      final fileName = path.basename(file.path);
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

        final dirName = path.basename(entity.path);
        // Skip the models directory itself
        if (dirName == Config.modelsDirName) continue;

        // Check if this directory corresponds to a migrated file
        final correspondingFile = filesToMigrate.firstWhereOrNull(
          (f) => path.basenameWithoutExtension(f.path) == dirName,
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

      if (_downloadTasks.containsKey(taskId)) {
        continue;
      }
      final path = _paths(fileInfo).q;
      final url = fileInfo.raw.startsWith("http://") || fileInfo.raw.startsWith("https://")
          ? fileInfo.raw
          : sprintf(urlFmt, [fileInfo.raw]);
      final fileState = locals(fileInfo);
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
}
