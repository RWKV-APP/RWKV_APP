part of 'p.dart';

class _FileManager {
  late final downloadSource = qs(P.preference.currentLangIsZh.q ? FileDownloadSource.hfmirror : FileDownloadSource.huggingface);
  late final modelSelectorShown = qs(false);

  /// model-name to download-task map
  late final _downloadTasks = <String, DownloadTask>{};

  late final locals = qsff<FileInfo, LocalFile>((ref, key) {
    return LocalFile(targetPath: ref.watch(_paths(key)));
  });

  late final _paths = qsff<FileInfo, String>((ref, key) {
    final dir = ref.watch(P.app.documentsDir);
    final fileName = key.fileName;
    final dirPath = dir!.path;
    return "$dirPath/$fileName";
  });

  /// 全部 chat 权重
  late final _allChatWeights = qs<Set<FileInfo>>({});

  /// 当前平台可用的 chat 权重
  late final chatWeights = qs<Set<FileInfo>>({});

  late final worldWeights = qs<Set<FileInfo>>({});
  late final sudokuWeights = qs<Set<FileInfo>>({});
  late final othelloWeights = qs<Set<FileInfo>>({});

  /// 当前平台可用的 tts 权重, 包含 core 和 non-core 两种
  late final ttsWeights = qs<Set<FileInfo>>({});
  late final ttsCores = qs<Set<FileInfo>>({});
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

    // FIXME: 需要根据 demoType 来获取对应的权重
    final worldWeights = HF.listJSON(config["world"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();
    final sudokuWeights = HF.listJSON(config["sudoku"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();
    final othelloWeights = HF.listJSON(config["othello"]["model_config"]).map((e) => FileInfo.fromJSON(e)).toSet();

    _allChatWeights.q = chatWeights;
    this.chatWeights.q = chatWeights.where((e) => e.available).toSet();
    this.ttsWeights.q = ttsWeights.where((e) => e.available).toSet();
    ttsCores.q = this.ttsWeights.q.where((e) => e.tags.contains("core")).toSet();
  }

  Future<void> checkLocal() async {
    qq;
    await Future.delayed(const Duration(milliseconds: 17));
    final fileInfos = [
      chatWeights.q,
      ttsWeights.q,
      worldWeights.q,
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
        if (!kDebugMode) {
          if (!fileSizeVerified) File(path).delete();
        }
      }
      final state = locals(fileInfo);
      state.q = state.q.copyWith(hasFile: fileSizeVerified);
    }
    await _initModelDownloadTaskState();
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
            qqq('download update: state:${e.state}, speed:${e.speedInMB.toStringAsFixed(2)}MB/s');
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
      qqe(e);
      state.q = state.q.copyWith(state: TaskState.stopped);
      rethrow;
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
    final availableFiles = chatWeights.q;
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
          acceptedSize: fileInfo.fileSize,
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

enum FileDownloadSource {
  aifasthub,
  hfmirror,
  huggingface,
  github,
  googleapis;

  String get prefix => switch (this) {
    aifasthub => 'https://aifasthub.com/',
    hfmirror => 'https://hf-mirror.com/',
    huggingface => 'https://huggingface.co/',
    github => 'https://github.com/',
    googleapis => 'https://googleapis.com/',
  };

  String get suffix => switch (this) {
    aifasthub => '?download=true',
    hfmirror => '?download=true',
    huggingface => '',
    github => '',
    googleapis => '',
  };

  bool get isDebug => switch (this) {
    huggingface => false,
    hfmirror => false,
    aifasthub => false,
    github => true,
    googleapis => true,
  };

  bool get hidden => switch (this) {
    _ => false,
  };
}
