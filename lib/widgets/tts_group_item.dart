// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_downloader/downloader.dart';
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:sprintf/sprintf.dart';

// Project imports:
import 'package:zone/func/format_bytes.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/loading_progress_button_content.dart';
import 'package:zone/widgets/model_tag.dart';

ModelInfo? rolePlayTTSModel;

class TTSGroupItem extends ConsumerStatefulWidget {
  final FileInfo fileInfo;

  TTSGroupItem(
    this.fileInfo, {
    super.key,
  }) : assert(fileInfo.tags.contains("core"), "fileInfo must be a core model");

  @override
  ConsumerState<TTSGroupItem> createState() => _TTSGroupItemState();
}

class _TTSGroupItemState extends ConsumerState<TTSGroupItem> {
  bool _expanded = false;

  List<FileInfo> get _fileInfos {
    final availableModels = P.remote.ttsWeights.q;
    final isSpark = widget.fileInfo.tags.contains("spark");
    final fileInfos = availableModels.toList().where((e) {
      return !e.tags.contains("core") && (isSpark ? e.tags.contains("spark") : !e.tags.contains("spark"));
    }).toList();
    fileInfos.insert(0, widget.fileInfo);
    return fileInfos;
  }

  void _onDownloadAllTap() async {
    P.remote.activeDownloadGroupIds.q = {...P.remote.activeDownloadGroupIds.q, widget.fileInfo.fileName};
    final missingFileInfos = _fileInfos.where((e) => P.remote.locals(e).q.hasFile == false).toList();
    for (final e in missingFileInfos) {
      P.remote.getFile(fileInfo: e);
    }
  }

  void _onDeleteAllTap() async {
    P.remote.activeDownloadGroupIds.q = P.remote.activeDownloadGroupIds.q.difference({widget.fileInfo.fileName});
    for (final e in _fileInfos) {
      P.remote.deleteFile(fileInfo: e);
    }
  }

  int _getTotalSize() {
    return _fileInfos.fold(0, (sum, file) => sum + file.fileSize);
  }

  int _getDownloadedSize() {
    int downloaded = 0;
    for (final fileInfo in _fileInfos) {
      final localFile = P.remote.locals(fileInfo).q;
      if (localFile.downloading) {
        final progress = localFile.progress.clamp(0.0, 100.0) / 100.0;
        downloaded += (fileInfo.fileSize * progress).round();
      } else if (localFile.hasFile) {
        downloaded += fileInfo.fileSize;
      }
    }
    return downloaded;
  }

  double _getOverallProgress() {
    final totalSize = _getTotalSize();
    if (totalSize == 0) return 0.0;
    final downloadedSize = _getDownloadedSize();
    return downloadedSize / totalSize;
  }

  bool _isDownloading() {
    final coreLocal = P.remote.locals(widget.fileInfo).q;
    final isExplicitlyActive = P.remote.activeDownloadGroupIds.q.contains(widget.fileInfo.fileName);
    final isCoreActive = coreLocal.downloading;

    if (!isExplicitlyActive && !isCoreActive) return false;

    for (final fileInfo in _fileInfos) {
      final localFile = P.remote.locals(fileInfo).q;
      if (localFile.downloading) {
        return true;
      }
    }
    return false;
  }

  double _getTotalSpeed() {
    double totalSpeed = 0.0;
    for (final fileInfo in _fileInfos) {
      final localFile = P.remote.locals(fileInfo).q;
      if (localFile.downloading && localFile.networkSpeed > 0) {
        totalSpeed += localFile.networkSpeed;
      }
    }
    return totalSpeed;
  }

  Duration _getAverageRemaining() {
    Duration totalRemaining = Duration.zero;
    int downloadingCount = 0;
    for (final fileInfo in _fileInfos) {
      final localFile = P.remote.locals(fileInfo).q;
      if (localFile.downloading && !localFile.timeRemaining.isNegative) {
        totalRemaining += localFile.timeRemaining;
        downloadingCount++;
      }
    }
    if (downloadingCount == 0) return Duration.zero;
    return totalRemaining ~/ downloadingCount;
  }

  TaskState _getOverallState() {
    final files = _fileInfos.map((e) => P.remote.locals(e).q).toList();
    final allDownloaded = files.every((e) => e.hasFile);
    if (allDownloaded) return TaskState.completed;

    final coreLocal = P.remote.locals(widget.fileInfo).q;
    final isExplicitlyActive = P.remote.activeDownloadGroupIds.q.contains(widget.fileInfo.fileName);
    final isCoreActive = coreLocal.downloading || coreLocal.state == TaskState.running;

    if (!isExplicitlyActive && !isCoreActive) {
      return TaskState.idle;
    }

    final anyRunning = files.any((e) => e.state == TaskState.running);
    if (anyRunning) return TaskState.running;

    final anyStopped = files.any((e) => e.state == TaskState.stopped);
    if (anyStopped) return TaskState.stopped;

    return TaskState.idle;
  }

  void _onDownloadTap(BuildContext context) async {
    await P.preference.tryShowBatteryOptimizationDialog(context);
    _onDownloadAllTap();
  }

  void _onCancelTap() async {
    final result = await showOkCancelAlertDialog(
      context: getContext()!,
      title: S.current.cancel_download + "?",
      okLabel: S.current.cancel,
      isDestructiveAction: true,
      cancelLabel: S.current.continue_download,
    );
    if (result == OkCancelResult.ok) {
      P.remote.activeDownloadGroupIds.q = P.remote.activeDownloadGroupIds.q.difference({widget.fileInfo.fileName});

      // 1. Cancel the core file (always unique to this group)
      await P.remote.cancelDownload(fileInfo: widget.fileInfo);

      // 2. Check if we should cancel dependencies
      bool shouldCancelDependencies = true;

      final activeGroups = P.remote.activeDownloadGroupIds.q;
      final myId = widget.fileInfo.fileName;
      final isMySpark = widget.fileInfo.tags.contains("spark");

      // Look for other active groups
      for (final groupId in activeGroups) {
        if (groupId == myId) continue;

        // Find the FileInfo for this groupId
        final otherCore = P.remote.ttsCores.q.firstWhereOrNull((e) => e.fileName == groupId);
        if (otherCore != null) {
          final isOtherSpark = otherCore.tags.contains("spark");
          if (isMySpark == isOtherSpark) {
            // Found another active group of the same type (sharing dependencies)
            shouldCancelDependencies = false;
            break;
          }
        }
      }

      if (shouldCancelDependencies) {
        for (final fileInfo in _fileInfos) {
          if (fileInfo.fileName != widget.fileInfo.fileName) {
            await P.remote.cancelDownload(fileInfo: fileInfo);
          }
        }
      }
    }
  }

  void _onPauseTap() {
    // 1. Pause the core file (always unique to this group)
    P.remote.pauseDownload(fileInfo: widget.fileInfo);

    // 2. Check if we should pause dependencies
    bool shouldPauseDependencies = true;

    final activeGroups = P.remote.activeDownloadGroupIds.q;
    final myId = widget.fileInfo.fileName;
    final isMySpark = widget.fileInfo.tags.contains("spark");

    // Look for other active groups
    for (final groupId in activeGroups) {
      if (groupId == myId) continue;

      // Find the FileInfo for this groupId
      final otherCore = P.remote.ttsCores.q.firstWhereOrNull((e) => e.fileName == groupId);
      if (otherCore != null) {
        final isOtherSpark = otherCore.tags.contains("spark");
        if (isMySpark == isOtherSpark) {
          // Found another active group of the same type (sharing dependencies)
          shouldPauseDependencies = false;
          break;
        }
      }
    }

    if (shouldPauseDependencies) {
      for (final fileInfo in _fileInfos) {
        if (fileInfo.fileName != widget.fileInfo.fileName) {
          P.remote.pauseDownload(fileInfo: fileInfo);
        }
      }
    }
  }

  Future<void> _onSparkTap() async {
    if (P.rwkvModel.loading.q) {
      Alert.warning(S.current.please_wait_for_the_model_to_load);
      return;
    }

    if (P.remote.modelSelectorShown.q) {
      Navigator.pop(context);
    }

    final result = await P.rwkvAutoLoad.loadTtsCoreForCurrentScene(fileInfo: widget.fileInfo);
    if (result.$2 != null) return;
    P.rwkvContext.currentGroupInfo.q = null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_fileInfos.isEmpty) {
      return const SizedBox.shrink();
    }

    final appTheme = ref.watch(P.app.theme);

    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);
    final primary = appTheme.primary;

    final startButtonRadius = appTheme.startButtonRadius;

    final files = _fileInfos.m((e) {
      return ref.watch(P.remote.locals(e));
    });

    final allDownloaded = files.every((e) => e.hasFile);

    if (allDownloaded && P.remote.activeDownloadGroupIds.q.contains(widget.fileInfo.fileName)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        P.remote.activeDownloadGroupIds.q = P.remote.activeDownloadGroupIds.q.difference({widget.fileInfo.fileName});
      });
    }

    final downloading = _isDownloading();
    final overallState = _getOverallState();
    final overallProgress = _getOverallProgress();
    final totalSize = _getTotalSize();
    final networkSpeed = _getTotalSpeed();
    final timeRemaining = _getAverageRemaining();

    final currentModel = ref.watch(P.rwkvModel.latest);
    bool alreadyStarted = currentModel == widget.fileInfo;
    final loading = ref.watch(P.rwkvModel.loading);
    final loadingStatus = ref.watch(P.rwkvModel.loadingStatus);
    final loadingProgress = ref.watch(P.rwkvModel.loadingProgress);
    final modelLoading =
        loadingStatus[widget.fileInfo] == .loading ||
        loadingStatus[widget.fileInfo] == .loadModelWithExtra ||
        loadingStatus[widget.fileInfo] == .setQnnLibraryPath;
    final modelLoadingProgress = loadingProgress[widget.fileInfo];

    if (P.app.pageKey.q == .rolePlaying) {
      alreadyStarted = widget.fileInfo.fileName == rolePlayTTSModel?.id;
    }

    String startTitle = s.start_to_chat;
    if (loading) {
      startTitle = s.loading;
    }

    final remainText = timeRemaining.inMinutes == 0
        ? '${timeRemaining.inSeconds}s'
        : '${timeRemaining.inMinutes}m${timeRemaining.inSeconds % 60}s';

    return ClipRRect(
      borderRadius: .circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.settingItem,
          borderRadius: .circular(8),
          border: .all(color: qw.q(.1), width: .5),
        ),
        margin: const .only(top: 8),
        padding: const .all(8),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            // 折叠状态的主行
            GestureDetector(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Container(
                decoration: const BoxDecoration(color: kC),
                child: Row(
                  children: [
                    Expanded(
                      child: _CollapsedContent(
                        modelName: widget.fileInfo.name,
                        totalSize: totalSize,
                        overallProgress: overallProgress,
                        downloading: downloading,
                        networkSpeed: networkSpeed,
                        remainText: remainText,
                        isSpark: widget.fileInfo.tags.contains("spark"),
                        isNpu: widget.fileInfo.tags.contains("npu"),
                        quantization: widget.fileInfo.quantization,
                        backend: widget.fileInfo.backend,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DownloadActionsWidget(
                      state: overallState,
                      hasFile: allDownloaded,
                      onDownload: () => _onDownloadTap(context),
                      onCancel: _onCancelTap,
                      onPause: _onPauseTap,
                      onResume: () => _onDownloadTap(context),
                    ),
                    if (allDownloaded) ...[
                      if (!alreadyStarted)
                        GestureDetector(
                          onTap: loading ? null : _onSparkTap,
                          child: AnimatedOpacity(
                            opacity: loading ? 0.6 : 1,
                            duration: 200.ms,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: .circular(startButtonRadius),
                              ),
                              padding: const .all(8),
                              child: modelLoading
                                  ? LoadingProgressButtonContent(
                                      progress: modelLoadingProgress,
                                      textStyle: TS(c: qw),
                                      indicatorColor: qw,
                                    )
                                  : Text(
                                      startTitle,
                                      style: TS(c: qw),
                                    ),
                            ),
                          ),
                        ),
                      if (alreadyStarted)
                        GestureDetector(
                          onTap: null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kG.q(.5),
                              borderRadius: .circular(startButtonRadius),
                            ),
                            padding: const .all(8),
                            child: Text(s.chatting, style: TS(c: qw)),
                          ),
                        ),
                      if (!alreadyStarted) const SizedBox(width: 8),
                      if (!alreadyStarted)
                        GestureDetector(
                          onTap: () async {
                            final result = await showOkCancelAlertDialog(
                              context: getContext()!,
                              title: S.current.are_you_sure_you_want_to_delete_this_model,
                              okLabel: S.current.delete,
                              isDestructiveAction: true,
                              cancelLabel: S.current.cancel,
                            );
                            if (result == OkCancelResult.ok) {
                              _onDeleteAllTap();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: .circular(8),
                              border: .all(
                                color: Colors.transparent,
                              ),
                            ),
                            padding: const .all(5),
                            child: Icon(
                              Icons.delete_forever_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            // 展开状态的文件列表
            if (_expanded) ...[
              const SizedBox(height: 8),
              ..._fileInfos.map(
                (e) => Container(
                  margin: const .only(top: 8),
                  padding: const .all(8),
                  decoration: BoxDecoration(
                    color: qb.q(.05),
                    borderRadius: .circular(8),
                    border: .all(color: qb.q(.1), width: 1),
                  ),
                  child: _ExpandedFileItem(fileInfo: e),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollapsedContent extends ConsumerWidget {
  final String modelName;
  final int totalSize;
  final double overallProgress;
  final bool downloading;
  final double networkSpeed;
  final String remainText;
  final bool isSpark;
  final bool isNpu;
  final String? quantization;
  final Backend? backend;

  const _CollapsedContent({
    required this.modelName,
    required this.totalSize,
    required this.overallProgress,
    required this.downloading,
    required this.networkSpeed,
    required this.remainText,
    required this.isSpark,
    required this.isNpu,
    this.quantization,
    this.backend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            Text(
              modelName,
              style: const TS(w: .w600),
            ),
            Text(
              formatBytes(totalSize),
              style: TS(c: qb.q(.7), w: .w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _TTSTags(isSpark: isSpark, isNpu: isNpu, quantization: quantization, backend: backend),
        if (downloading) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const .only(right: 40),
            child: LinearProgressIndicator(
              value: (overallProgress.isNaN || overallProgress <= 0 || overallProgress.isInfinite) ? null : overallProgress,
              borderRadius: .circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            children: [
              Text(
                sprintf(S.current.str_downloading_info, [
                  (overallProgress.isNaN || overallProgress <= 0 || overallProgress.isInfinite) ? 0.0 : overallProgress * 100.0,
                  networkSpeed,
                  remainText,
                ]),
                style: TextStyle(
                  fontFamily: monospaceFF,
                  fontFamilyFallback: const ['Roboto Mono', 'Roboto', 'CourierNew', 'Menlo', 'PingFang SC'],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TTSTags extends StatelessWidget {
  final bool isSpark;
  final bool isNpu;
  final String? quantization;
  final Backend? backend;

  const _TTSTags({required this.isSpark, required this.isNpu, this.quantization, this.backend});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: <ModelTag>[
        const ModelTag(tag: "TTS"),
        if (isNpu) const ModelTag(tag: "NPU"),
        if (backend == Backend.webRwkv) const ModelTag(tag: "WebRWKV"),
        if (quantization != null && quantization!.isNotEmpty) ModelTag(tag: quantization!, forceUppercase: true),
      ],
    );
  }
}

class _DownloadActionsWidget extends StatelessWidget {
  final TaskState state;
  final bool hasFile;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _DownloadActionsWidget({
    required this.state,
    required this.hasFile,
    required this.onDownload,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final showDownload = state == TaskState.idle && !hasFile;
    final showResume = state == TaskState.stopped;
    final showPause = state == TaskState.running;
    final showCancel = showPause || showResume;

    return Row(
      mainAxisSize: .min,
      children: [
        if (showDownload)
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded),
            visualDensity: .compact,
          ),
        if (showCancel)
          IconButton(
            visualDensity: .compact,
            onPressed: onCancel,
            icon: const Icon(Icons.stop_rounded),
          ),
        if (showPause)
          IconButton(
            onPressed: onPause,
            visualDensity: .compact,
            icon: const Icon(Icons.pause),
          ),
        if (showResume)
          IconButton(
            onPressed: onResume,
            visualDensity: .compact,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
      ],
    );
  }
}

class _ExpandedFileItem extends ConsumerWidget {
  final FileInfo fileInfo;

  const _ExpandedFileItem({required this.fileInfo});

  void _onDownloadTap(BuildContext context) async {
    await P.preference.tryShowBatteryOptimizationDialog(context);
    await P.remote.getFile(fileInfo: fileInfo);
  }

  void _onCancelTap() async {
    final result = await showOkCancelAlertDialog(
      context: getContext()!,
      title: S.current.cancel_download + "?",
      okLabel: S.current.cancel,
      isDestructiveAction: true,
      cancelLabel: S.current.continue_download,
    );
    if (result == OkCancelResult.ok) {
      await P.remote.cancelDownload(fileInfo: fileInfo);
    }
  }

  void _onPauseTap() {
    P.remote.pauseDownload(fileInfo: fileInfo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.remote.locals(fileInfo));
    final hasFile = localFile.hasFile;
    final downloading = localFile.downloading;
    final progress = localFile.progress / 100;
    final fileSize = fileInfo.fileSize;
    final qb = ref.watch(P.app.qb);
    final state = localFile.state;
    double networkSpeed = localFile.networkSpeed.clamp(0, 99999999).toDouble();
    Duration timeRemaining = localFile.timeRemaining;
    if (timeRemaining.isNegative) timeRemaining = Duration.zero;

    final remainText = timeRemaining.inMinutes == 0
        ? '${timeRemaining.inSeconds}s'
        : '${timeRemaining.inMinutes}m${timeRemaining.inSeconds % 60}s';

    final showDownload = state == TaskState.idle && !hasFile;
    final showResume = state == TaskState.stopped;
    final showPause = state == TaskState.running;
    final showCancel = showPause || showResume;

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          fileInfo.name,
                          style: const TS(
                            w: .w600,
                            s: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatBytes(fileSize),
                          style: TS(
                            c: qb.q(.7),
                            w: .w500,
                            s: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (downloading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (progress.isNaN || progress <= 0 || progress.isInfinite) ? null : progress,
                  borderRadius: .circular(8),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    Text(
                      sprintf(s.str_downloading_info, [
                        (progress.isNaN || progress <= 0 || progress.isInfinite) ? 0.0 : progress * 100.0,
                        networkSpeed,
                        remainText,
                      ]),
                      style: TextStyle(
                        fontFamily: monospaceFF,
                        fontFamilyFallback: const ['Roboto Mono', 'Roboto', 'CourierNew', 'Menlo', 'PingFang SC'],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: .min,
          children: [
            if (showDownload)
              IconButton(
                onPressed: () => _onDownloadTap(context),
                icon: const Icon(Icons.download_rounded),
                visualDensity: .compact,
              ),
            if (showCancel)
              IconButton(
                visualDensity: .compact,
                onPressed: _onCancelTap,
                icon: const Icon(Icons.stop_rounded),
              ),
            if (showPause)
              IconButton(
                onPressed: _onPauseTap,
                visualDensity: .compact,
                icon: const Icon(Icons.pause),
              ),
            if (showResume)
              IconButton(
                onPressed: () => _onDownloadTap(context),
                visualDensity: .compact,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            if (hasFile)
              IconButton(
                onPressed: () async {
                  final result = await showOkCancelAlertDialog(
                    context: getContext()!,
                    title: S.current.are_you_sure_you_want_to_delete_this_model,
                    okLabel: S.current.delete,
                    isDestructiveAction: true,
                    cancelLabel: S.current.cancel,
                  );
                  if (result == OkCancelResult.ok) {
                    await P.remote.deleteFile(fileInfo: fileInfo);
                  }
                },
                visualDensity: .compact,
                icon: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
