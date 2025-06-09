import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:zone/model/file_info.dart';

enum DownloadLoadState {
  none,
  downloading,
  paused;

  static DownloadLoadState from(bd.TaskStatusUpdate statusUpdate) {
    switch (statusUpdate.status) {
      case bd.TaskStatus.paused:
        return DownloadLoadState.paused;
      case bd.TaskStatus.enqueued:
      case bd.TaskStatus.running:
      case bd.TaskStatus.waitingToRetry:
        return DownloadLoadState.downloading;
      case bd.TaskStatus.complete:
      case bd.TaskStatus.notFound:
      case bd.TaskStatus.failed:
      case bd.TaskStatus.canceled:
        return DownloadLoadState.none;
    }
  }
}

@immutable
class LocalFile extends Equatable {
  final double progress;
  final double networkSpeed;
  final Duration timeRemaining;
  final DownloadLoadState state;
  final String targetPath;
  final bool hasFile;
  final String? downloadTaskId;

  final FileInfo _fileInfo;

  String get fileName => _fileInfo.fileName;
  bool get downloading => state == DownloadLoadState.downloading;

  const LocalFile({
    required FileInfo fileInfo,
    required this.targetPath,
    this.progress = 0,
    this.networkSpeed = 0,
    this.timeRemaining = Duration.zero,
    this.state = DownloadLoadState.none,
    this.hasFile = false,
    this.downloadTaskId,
  }) : _fileInfo = fileInfo;

  LocalFile copyWith({
    FileInfo? fileInfo,
    double? progress,
    double? networkSpeed,
    Duration? timeRemaining,
    DownloadLoadState? state,
    String? targetPath,
    bool? hasFile,
    String? downloadTaskId,
  }) => LocalFile(
    fileInfo: fileInfo ?? _fileInfo,
    progress: progress ?? this.progress,
    networkSpeed: networkSpeed ?? this.networkSpeed,
    timeRemaining: timeRemaining ?? this.timeRemaining,
    state: state ?? this.state,
    targetPath: targetPath ?? this.targetPath,
    hasFile: hasFile ?? this.hasFile,
    downloadTaskId: downloadTaskId ?? this.downloadTaskId,
  );

  @override
  List<Object?> get props => [
    progress,
    networkSpeed,
    timeRemaining,
    state,
    targetPath,
    hasFile,
    downloadTaskId,
    _fileInfo,
  ];
}
