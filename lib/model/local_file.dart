import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rwkv_downloader/downloader.dart';
import 'package:zone/model/file_info.dart';

@immutable
class LocalFile extends Equatable {
  final double progress;
  final double networkSpeed;
  final Duration timeRemaining;
  final TaskState state;
  final String targetPath;
  final bool hasFile;

  bool get downloading => state == TaskState.running;

  const LocalFile({
    required this.targetPath,
    this.progress = 0,
    this.networkSpeed = 0,
    this.timeRemaining = Duration.zero,
    this.state = TaskState.idle,
    this.hasFile = false,
  });

  LocalFile copyWith({
    FileInfo? fileInfo,
    double? progress,
    double? networkSpeed,
    Duration? timeRemaining,
    TaskState? state,
    String? targetPath,
    bool? hasFile,
  }) => LocalFile(
    progress: progress ?? this.progress,
    networkSpeed: networkSpeed ?? this.networkSpeed,
    timeRemaining: timeRemaining ?? this.timeRemaining,
    state: state ?? this.state,
    targetPath: targetPath ?? this.targetPath,
    hasFile: hasFile ?? this.hasFile,
  );

  @override
  List<Object?> get props => [
    progress,
    networkSpeed,
    timeRemaining,
    state,
    targetPath,
    hasFile,
  ];
}
