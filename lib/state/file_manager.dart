// ignore_for_file: constant_identifier_names

part of 'p.dart';

class _FileManager {
  late final locals = qsff<FileInfo, LocalFile>((ref, key) {
    return LocalFile(fileInfo: key, targetPath: ref.watch(paths(key)));
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

  late final downloadSource = qs(FileDownloadSource.hfmirror);

  late final hasDownloadedModels = qs(false);

  late final modelSelectorShown = qs(false);

  late final ttsCores = qs<Set<FileInfo>>({});

  late final downloader = bd.FileDownloader();
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

    if (P.app.modelConfig.q.isEmpty) {
      final demoType = P.app.demoType.q;
      final jsonPath = "demo-config.json";
      qqq("jsonPath: $jsonPath");
      final jsonString = await rootBundle.loadString(jsonPath);
      final rawJSON = jsonDecode(jsonString);
      final data = rawJSON[demoType.name]["model_config"];
      json = HF.listJSON(data);
    } else {
      json = P.app.modelConfig.q;
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
  }

  FV getFile({required FileInfo fileInfo}) async {
    /// resume download if needed
    try {
      bd.Task? task;
      final records = await downloader.database.allRecords();
      final r = records.firstWhereOrNull((e) => e.task.filename == fileInfo.fileName);
      task = r?.task;
      qqq("try resume task: $task");

      if (task != null) {
        final canResume = await downloader.taskCanResume(task);
        if (canResume) {
          await downloader.resume(task as bd.DownloadTask);
          qqq("#### resume download ####: ${fileInfo.fileName}");
          return;
        }
        await downloader.database.deleteRecordWithId(task.taskId);
        qqq('task cannot resume');
      }
    } catch (e) {
      qqe(e);
    }

    final fileName = fileInfo.fileName;
    final url = downloadSource.q.prefix + fileInfo.raw + downloadSource.q.suffix;
    final state = locals(fileInfo);
    qqq("fileKey: $fileInfo\nfileName: $fileName\nurl: $url");

    try {
      state.q = state.q.copyWith(state: DownloadLoadState.none);

      final task = bd.DownloadTask(
        taskId: url,
        url: url,
        baseDirectory: bd.BaseDirectory.applicationDocuments,
        filename: fileName,
        updates: bd.Updates.statusAndProgress,
        // request status and progress updates
        requiresWiFi: false,
        retries: 5,
        allowPause: true,
        metaData: fileInfo.fileName,
        httpRequestMethod: "GET",
      );

      state.q = state.q.copyWith(downloadTaskId: task.taskId);

      final success = await downloader.enqueue(task);

      if (!success) {
        throw Exception("Enqueue failed");
      }
    } catch (e) {
      qqe("getFile error: $e");
      state.q = state.q.copyWith(state: DownloadLoadState.none);
    }
  }

  FV pauseDownload({required FileInfo fileInfo}) async {
    final taskId = locals(fileInfo).q.downloadTaskId;
    if (taskId == null) throw Exception("😡 TaskId is null");
    final task = await downloader.taskForId(taskId);
    if (task == null) throw Exception("😡 Task not found");
    await downloader.pause(task as bd.DownloadTask);
  }

  FV cancelDownload({required FileInfo fileInfo}) async {
    final state = locals(fileInfo);
    final value = state.q;

    if (value.state != DownloadLoadState.downloading) throw Exception("😡 Download not in progress");

    final taskId = value.downloadTaskId;

    if (taskId == null) throw Exception("😡 Task ID not found");

    await downloader.cancelTaskWithId(taskId);
    state.q = value.copyWith(state: DownloadLoadState.none, downloadTaskId: null);
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
    state.q = value.copyWith(hasFile: false);
  }
}

/// Private methods
extension _$FileManager on _FileManager {
  FV _init() async {
    // 1. check file
    // 2. check zip file
    await syncAvailableModels();
    await downloader.ready;
    downloader.updates.listen(_onTaskUpdate);
    await _updateTaskRecord();
    await downloader.trackTasks();
    await checkLocal();
    downloader.pauseAll();
  }

  FV _updateTaskRecord() async {
    try {
      final allRecords = await downloader.database.allRecords();
      for (final record in allRecords) {
        qqq("check record: ${record.status}, ${record.progress.toStringAsFixed(2)}, ${record.task.filename}");
        switch (record.status) {
          case bd.TaskStatus.waitingToRetry:
          case bd.TaskStatus.failed:
          case bd.TaskStatus.running:
            await downloader.database.updateRecord(
              record.copyWith(status: bd.TaskStatus.paused),
            );
            break;
          case bd.TaskStatus.enqueued:
          case bd.TaskStatus.complete:
          case bd.TaskStatus.notFound:
          case bd.TaskStatus.canceled:
            await downloader.database.deleteRecordWithId(record.taskId);
            break;
          case bd.TaskStatus.paused:
          // do nothing
        }
      }
    } catch (e) {
      qqe(e);
    }
  }

  void _onTaskUpdate(bd.TaskUpdate taskUpdate) async {
    final task = taskUpdate.task;
    final taskId = task.taskId;

    final pair = _all.q.firstWhereOrNull((e) {
      final lf = locals(e).q;
      return lf.fileName == task.metaData || lf.downloadTaskId == taskId;
    });

    if (pair == null) {
      final task = await downloader.taskForId(taskId);
      qqe("_onTaskUpdate: taskId: $taskId not found, ${task?.toJson()}");
      downloader.cancelTaskWithId(taskId);
      return;
    }
    final state = locals(pair);

    switch (taskUpdate) {
      case bd.TaskProgressUpdate update:
        qqq("task_update_progress: ${update.progress.toStringAsFixed(2)} => ${task.filename}");
        final progress = update.progress;
        final networkSpeed = update.networkSpeed;
        final timeRemaining = update.timeRemaining;
        final done = progress >= 1.0;
        state.q = state.q.copyWith(
          progress: progress,
          downloadTaskId: taskId,
          state: DownloadLoadState.downloading,
          networkSpeed: done ? state.q.networkSpeed : networkSpeed,
          timeRemaining: done ? state.q.timeRemaining : timeRemaining,
        );
        return;
      case bd.TaskStatusUpdate update:
        qqq("task_update_status:  ${update.status}, ${task.filename}, ${update.exception}");
        state.q = state.q.copyWith(state: DownloadLoadState.from(update));
        checkLocal();
        return;
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
