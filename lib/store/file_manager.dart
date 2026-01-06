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

  late final downloadSource = qs(P.preference.currentLangIsZh.q ? FileDownloadSource.hfmirror : FileDownloadSource.huggingface);
  late final modelSelectorShown = qs(false);

  late final locals = qsff<FileInfo, LocalFile>((ref, key) {
    return LocalFile(targetPath: ref.watch(_paths(key)));
  });

  late final _paths = qsff<FileInfo, String>((ref, key) {
    final customDir = ref.watch(P.preference.customModelsDir);
    if (customDir != null && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return "$customDir/${key.fileName}";
    }
    final dir = ref.watch(P.app.documentsDir);
    final fileName = key.fileName;
    final dirPath = dir!.path;
    return "$dirPath/$fileName";
  });

  /// 全部 chat 权重
  late final _allChatWeights = qs<Set<FileInfo>>({});

  /// 当前平台可用的 chat 权重
  late final chatWeights = qs<Set<FileInfo>>({});

  late final seeWeights = qs<Set<FileInfo>>({});
  late final sudokuWeights = qs<Set<FileInfo>>({});
  late final othelloWeights = qs<Set<FileInfo>>({});

  ///
  late final roleplayWeights = qs<Set<FileInfo>>({});

  /// 当前平台可用的 tts 权重, 包含 core 和 non-core 两种
  late final ttsWeights = qs<Set<FileInfo>>({});
  late final ttsCores = qs<Set<FileInfo>>({});

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
    await Future.delayed(const Duration(milliseconds: 17));
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
    final documentsDir = P.app.documentsDir.q;
    if (documentsDir == null) return;
    final fileSystemEntities = documentsDir.listSync();

    for (final entity in fileSystemEntities) {
      if (entity is! File) continue;
      if (fileInfos.any((e) => entity.path.contains(e.fileName))) continue;

      // 不移除以 .tmp 结尾的文件
      if (entity.path.endsWith('.tmp')) {
        continue;
      }

      // 检查文件大小，只删除大于 20MB 的文件
      final fileSize = await File(entity.path).length();
      if (fileSize <= maxSizeBytes) {
        continue;
      }

      await entity.delete();
      qqw("delete file (size: ${fileSize} bytes): ${entity.path}");
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
          },
          onDone: () {
            qqq('event done');
          },
        );

    state.q = state.q.copyWith(progress: 0, state: TaskState.running);

    try {
      await task.start();
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
    final customDir = P.preference.customModelsDir.q;
    final defaultDir = P.app.documentsDir.q?.path;
    final path = customDir ?? defaultDir;
    if (path == null) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await launchUrl(Uri.directory(path));
    }
  }

  Future<void> updateCustomDirectory(String? newPath, {void Function(String currentFile, int completed, int total)? onProgress}) async {
    final customDir = P.preference.customModelsDir.q;
    final defaultDir = P.app.documentsDir.q?.path;
    final oldPath = customDir ?? defaultDir;

    if (newPath == oldPath) return;

    if (oldPath != null) {
      final targetPath = newPath ?? defaultDir;
      if (targetPath == null) return;

      final allWeights = <dynamic>{
        ...chatWeights.q,
        ...ttsWeights.q,
        ...roleplayWeights.q,
        ...seeWeights.q,
        ...sudokuWeights.q,
        ...othelloWeights.q,
      }.toList();

      final existingFiles = <FileInfo>[];
      for (final weight in allWeights) {
        final oldFile = File("$oldPath/${weight.fileName}");
        if (await oldFile.exists()) {
          existingFiles.add(weight);
        }
      }

      final total = existingFiles.length;
      int completed = 0;

      for (final weight in existingFiles) {
        if (onProgress != null) {
          onProgress(weight.fileName, completed, total);
        }

        final oldFile = File("$oldPath/${weight.fileName}");
        final newFile = File("$targetPath/${weight.fileName}");
        if (!await newFile.exists()) {
          try {
            await oldFile.rename(newFile.path);
          } catch (e) {
            await oldFile.copy(newFile.path);
            await oldFile.delete();
          }
        }

        final nameWithoutExtension = path.basenameWithoutExtension(weight.fileName);
        final oldFolder = Directory("$oldPath/$nameWithoutExtension");
        if (await oldFolder.exists()) {
          try {
            await oldFolder.delete(recursive: true);
            qqq("Deleted old folder: ${oldFolder.path}");
          } catch (e) {
            qqe("Failed to delete old folder: $e");
          }
        }
        
        completed++;
      }
      
      if (onProgress != null) {
          onProgress("", completed, total);
      }
    }

    P.preference.setCustomModelsDir(newPath);
  }
}

/// Private methods
extension _$FileManager on _FileManager {
  Future<void> _init() async {
    try {
      await syncAvailableModels();
    } catch (e) {
      Sentry.captureException(e, stackTrace: StackTrace.current);
    }
  }

  Future<void> _initModelDownloadTaskState() async {
    await Future.delayed(const Duration(milliseconds: 17));
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
