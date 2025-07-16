// ignore_for_file: constant_identifier_names

part of 'p.dart';

class _FileManager {
  late final locals = qsff<FileInfo, LocalFile>((ref, key) {
    return LocalFile(targetPath: ref.watch(paths(key)));
  });

  late final paths = qsff<FileInfo, String>((ref, key) {
    final dir = ref.watch(P.app.documentsDir);
    final fileName = key.fileName;
    final dirPath = dir!.path;
    return "$dirPath/$fileName";
  });

  late final _all = qs<Set<FileInfo>>({});

  late final availableModels = qs<Set<FileInfo>>({});

  late final unavailableModels = qs<Set<FileInfo>>({});

  late final downloadSource = qs(P.preference.currentLangIsZh ? FileDownloadSource.hfmirror : FileDownloadSource.huggingface);

  late final hasDownloadedModels = qs(false);

  late final modelSelectorShown = qs(false);

  late final ttsCores = qs<Set<FileInfo>>({});

  // model-name to download-task map
  late final downloadTasks = <String, DownloadTask>{};
}

/// Public methods
extension $FileManager on _FileManager {
  FV syncAvailableModels() async {
    switch (P.app.demoType.q) {
      case DemoType.othello:
        qqw("othello game does not need to sync available models");
        return;
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.sudoku:
      case DemoType.tts:
      case DemoType.world:
    }

    qq;
    late final List<JSON> json;

    try {
      if (P.app.modelConfig.q.isEmpty) {
        final demoType = P.app.demoType.q;
        final jsonPath = "remote/latest.json";
        qqq("jsonPath: $jsonPath");
        final jsonString = await rootBundle.loadString(jsonPath);
        final rawJSON = jsonDecode(jsonString);
        final data = rawJSON[demoType.name]["model_config"];
        json = HF.listJSON(data);
      } else {
        json = P.app.modelConfig.q;
      }
    } catch (e) {
      qqe(e);
      Sentry.captureException(e, stackTrace: StackTrace.current);
    }

    try {
      final weights = json.map((e) => FileInfo.fromJSON(e)).toSet();
      _all.q = weights;
      availableModels.q = weights.where((e) => e.available).toSet();
      unavailableModels.q = weights.where((e) => !e.available).toSet();
      if (P.app.demoType.q == DemoType.tts) {
        ttsCores.q = availableModels.q.where((e) => e.tags.contains("core")).toSet();
      }
    } catch (e) {
      qqe(e);
      Sentry.captureException(e, stackTrace: StackTrace.current);
    }
  }

  FV checkLocal() async {
    qq;
    await HF.wait(17);
    final all = _all.q;
    final _fileInfos = all.where((e) => e.available).toList();

    for (final fileInfo in _fileInfos) {
      final path = paths(fileInfo).q;
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
    final nekos = _all.q.where((e) => e.available && e.isNeko).toList();
    if (nekos.isEmpty) {
      Alert.error('Neko is not available');
      return [];
    }
    final downloaded = nekos.where((e) => locals(e).q.hasFile);
    return downloaded.toList();
  }

  FV _initModelDownloadTaskState() async {
    await HF.wait(17);
    final availableFiles = availableModels.q;
    final urlFmt = "${downloadSource.q.prefix}%s${downloadSource.q.suffix}";
    for (final fileInfo in availableFiles) {
      final taskId = fileInfo.fileName;

      if (downloadTasks.containsKey(taskId)) {
        continue;
      }
      final path = paths(fileInfo).q;
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
        downloadTasks[taskId] = task;
      } catch (e) {
        qqe(e);
        fileState.q = fileState.q.copyWith(state: TaskState.idle, hasFile: false);
      }
    }
  }

  FV getFile({required FileInfo fileInfo}) async {
    final url = downloadSource.q.prefix + fileInfo.raw + downloadSource.q.suffix;
    final path = paths(fileInfo).q;

    qqq('start download file: \n>>url:$url\n>>path:$path');

    DownloadTask? task = downloadTasks[fileInfo.fileName];
    if (task == null) {
      task = await DownloadTask.create(url: url, path: path);
      downloadTasks[fileInfo.fileName] = task;
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

  FV pauseDownload({required FileInfo fileInfo}) async {
    final task = downloadTasks[fileInfo.fileName];
    task?.stop();
    final state = locals(fileInfo);
    state.q = state.q.copyWith(state: TaskState.stopped);
  }

  FV cancelDownload({required FileInfo fileInfo}) async {
    final task = downloadTasks[fileInfo.fileName];
    await task?.cancel();
    final state = locals(fileInfo);
    state.q = state.q.copyWith(state: TaskState.idle);
  }

  FV deleteFile({required FileInfo fileInfo}) async {
    final state = locals(fileInfo);
    final value = state.q;

    try {
      await cancelDownload(fileInfo: fileInfo);
    } catch (e) {
      qe;
      qqe(e);
      if (!kDebugMode) Sentry.captureException(e, stackTrace: StackTrace.current);
    }
    final path = paths(fileInfo).q;
    await File(path).delete();
    state.q = value.copyWith(hasFile: false, state: TaskState.idle, progress: 0);
  }
}

/// Private methods
extension _$FileManager on _FileManager {
  FV _init() async {
    try {
      await syncAvailableModels();
    } catch (e) {
      Sentry.captureException(e, stackTrace: StackTrace.current);
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
