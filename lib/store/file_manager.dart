part of 'p.dart';

class _FileManager {
  late final locals = qsff<FileInfo, LocalFile>((ref, key) {
    return LocalFile(targetPath: ref.watch(_paths(key)));
  });

  late final _paths = qsff<FileInfo, String>((ref, key) {
    final dir = ref.watch(P.app.documentsDir);
    final fileName = key.fileName;
    final dirPath = dir!.path;
    return "$dirPath/$fileName";
  });

  late final _allInCurrentDemoType = qs<Set<FileInfo>>({});

  late final availableModelsInCurrentDemoType = qs<Set<FileInfo>>({});

  late final downloadSource = qs(P.preference.currentLangIsZh ? FileDownloadSource.hfmirror : FileDownloadSource.huggingface);

  late final modelSelectorShown = qs(false);

  late final ttsCores = qs<Set<FileInfo>>({});

  /// model-name to download-task map
  late final _downloadTasks = <String, DownloadTask>{};
}

/// Public methods
extension $FileManager on _FileManager {
  Future<void> syncAvailableModels() async {
    final demoType = P.app.demoType.q;
    if (demoType == DemoType.othello) {
      qqw("othello game does not need to sync available models");
      return;
    }

    qq;
    late final List<Map<String, dynamic>> modelConfigInCurrentDemoType;

    try {
      if (P.app._modelConfigInCurrentDemoType.q.isEmpty) {
        final demoType = P.app.demoType.q;
        final jsonPath = "remote/latest.json";
        qqq("jsonPath: $jsonPath");
        final jsonString = await rootBundle.loadString(jsonPath);
        final rawJSON = jsonDecode(jsonString);
        final data = rawJSON[demoType.name]["model_config"];
        modelConfigInCurrentDemoType = HF.listJSON(data);
      } else {
        modelConfigInCurrentDemoType = P.app._modelConfigInCurrentDemoType.q;
      }
      final weights = modelConfigInCurrentDemoType.map((e) => FileInfo.fromJSON(e)).toSet();
      _allInCurrentDemoType.q = weights;
      availableModelsInCurrentDemoType.q = weights.where((e) => e.available).toSet();
      ttsCores.q = availableModelsInCurrentDemoType.q.where((e) => e.tags.contains("core")).toSet();
    } catch (e) {
      qqe(e);
      Sentry.captureException(e, stackTrace: StackTrace.current);
    }
  }

  Future<void> checkLocal() async {
    qq;
    await Future.delayed(const Duration(milliseconds: 17));
    final all = _allInCurrentDemoType.q;
    final _fileInfos = all.where((e) => e.available).toList();

    for (final fileInfo in _fileInfos) {
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
    final nekos = _allInCurrentDemoType.q.where((e) => e.available && e.isNeko).toList();
    return nekos;
  }

  Future<void> getFile({required FileInfo fileInfo}) async {
    final url = downloadSource.q.prefix + fileInfo.raw + downloadSource.q.suffix;
    final path = _paths(fileInfo).q;

    qqq('start download file: \n>>url:$url\n>>path:$path');

    DownloadTask? task = _downloadTasks[fileInfo.fileName];
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
    final availableFiles = availableModelsInCurrentDemoType.q;
    final urlFmt = "${downloadSource.q.prefix}%s${downloadSource.q.suffix}";

    final stateFiles = availableFiles.map((e) => e.state).flattened;
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

  bool get isDebug {
    switch (this) {
      case huggingface:
        return false;
      case hfmirror:
        return false;
      case aifasthub:
        return false;
      case github:
        return true;
      case googleapis:
        return true;
    }
  }
}
