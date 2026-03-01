// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:rwkv_downloader/downloader.dart';

// Project imports:
import 'package:zone/model/file_info.dart';

@immutable
class LocalFile extends Equatable {
  /// from 0 to 100
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
  }) {
    progress = _shouldBeCorrect(progress);
    if (progress != null) progress = progress.clamp(0.0, 100.0);

    networkSpeed = _shouldBeCorrect(networkSpeed);

    return LocalFile(
      progress: progress ?? this.progress,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      state: state ?? this.state,
      targetPath: targetPath ?? this.targetPath,
      hasFile: hasFile ?? this.hasFile,
    );
  }

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

double? _shouldBeCorrect(double? value) {
  if (value == null) {
    return null;
  }
  if (value.isNaN) {
    return 0.0;
  }
  //
  else if (value.isInfinite) {
    return 0.0;
  }
  //
  else if (value.isNegative) {
    return 0.0;
  }
  //
  else {
    return value;
  }
}
