// ignore: unused_import
import 'dart:developer';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:rwkv_downloader/downloader.dart' show TaskState;
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:zone/func/gb_display.dart';
import 'package:sprintf/sprintf.dart';
import 'package:zone/widgets/model_tag.dart';

class WorldGroupItem extends ConsumerStatefulWidget {
  final WorldType worldType;
  final (String, String) socPair;

  const WorldGroupItem(this.worldType, {super.key, required this.socPair});

  @override
  ConsumerState<WorldGroupItem> createState() => _WorldGroupItemState();
}

class _WorldGroupItemState extends ConsumerState<WorldGroupItem> {
  bool _expanded = false;

  List<FileInfo> get _fileInfos {
    final worldWeights = P.fileManager.seeWeights.q.where((e) => e.worldType == widget.worldType).where((file) {
      return file.isEncoder || file.isAdapter || (!file.isEncoder && file.fileName == widget.socPair.$2);
    }).toList();
    return worldWeights;
  }

  void _onDownloadAllTap() async {
    P.fileManager.activeDownloadGroupIds.q = {...P.fileManager.activeDownloadGroupIds.q, widget.socPair.$2};
    final missingFileInfos = _fileInfos.where((e) => P.fileManager.locals(e).q.hasFile == false).toList();
    for (var e in missingFileInfos) {
      P.fileManager.getFile(fileInfo: e);
    }
  }

  void _onDeleteAllTap() async {
    P.fileManager.activeDownloadGroupIds.q = P.fileManager.activeDownloadGroupIds.q.difference({widget.socPair.$2});
    for (var e in _fileInfos) {
      P.fileManager.deleteFile(fileInfo: e);
    }
  }

  String _getModelName() {
    final modelFile = _fileInfos.firstWhereOrNull((e) => e.fileName == widget.socPair.$2);
    if (modelFile == null) return '';
    return modelFile.name;
  }

  int _getTotalSize() {
    return _fileInfos.fold(0, (sum, file) => sum + file.fileSize);
  }

  int _getDownloadedSize() {
    int downloaded = 0;
    for (var fileInfo in _fileInfos) {
      final localFile = P.fileManager.locals(fileInfo).q;
      if (localFile.downloading) {
        final progress = localFile.progress.clamp(0.0, 100.0) / 100.0;
        downloaded += (fileInfo.fileSize * progress).round();
      } else if (localFile.hasFile) {
        final fileSize = fileInfo.fileSize;
        downloaded += fileSize;
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
    final myModelFile = _fileInfos.firstWhereOrNull((e) => e.fileName == widget.socPair.$2);
    if (myModelFile == null) return false;
    final myModelLocal = P.fileManager.locals(myModelFile).q;
    final isExplicitlyActive = P.fileManager.activeDownloadGroupIds.q.contains(widget.socPair.$2);
    final isCoreActive = myModelLocal.downloading;

    if (!isExplicitlyActive && !isCoreActive) return false;

    for (var fileInfo in _fileInfos) {
      final localFile = P.fileManager.locals(fileInfo).q;
      if (localFile.downloading) {
        return true;
      }
    }
    return false;
  }

  double _getTotalSpeed() {
    double totalSpeed = 0.0;
    for (var fileInfo in _fileInfos) {
      final localFile = P.fileManager.locals(fileInfo).q;
      if (localFile.downloading && localFile.networkSpeed > 0) {
        totalSpeed += localFile.networkSpeed;
      }
    }
    return totalSpeed;
  }

  Duration _getAverageRemaining() {
    Duration totalRemaining = Duration.zero;
    int downloadingCount = 0;
    for (var fileInfo in _fileInfos) {
      final localFile = P.fileManager.locals(fileInfo).q;
      if (localFile.downloading && !localFile.timeRemaining.isNegative) {
        totalRemaining += localFile.timeRemaining;
        downloadingCount++;
      }
    }
    if (downloadingCount == 0) return Duration.zero;
    return totalRemaining ~/ downloadingCount; // divide and round down
  }

  TaskState _getOverallState() {
    final files = _fileInfos.map((e) => P.fileManager.locals(e).q).toList();
    final allDownloaded = files.every((e) => e.hasFile);
    if (allDownloaded) return TaskState.completed;

    final myModelFile = _fileInfos.firstWhereOrNull((e) => e.fileName == widget.socPair.$2);
    if (myModelFile == null) return TaskState.idle;
    final myModelLocal = P.fileManager.locals(myModelFile).q;
    final isExplicitlyActive = P.fileManager.activeDownloadGroupIds.q.contains(widget.socPair.$2);
    final isCoreActive = myModelLocal.downloading || myModelLocal.state == TaskState.running;

    if (!isExplicitlyActive && !isCoreActive) return TaskState.idle;

    final anyRunning = files.any((e) => e.state == TaskState.running);
    if (anyRunning) return TaskState.running;

    final anyStopped = files.any((e) => e.state == TaskState.stopped);
    if (anyStopped) return TaskState.stopped;

    return TaskState.idle;
  }

  void _onStartToChatTap() async {
    if (P.rwkv.loading.q) {
      Alert.warning("Please wait for the model to load...");
      return;
    }
    final availableModels = P.fileManager.seeWeights.q;
    final fileInfos = availableModels.where((e) => e.worldType == widget.worldType).toList();
    final encoderFileKey = fileInfos.firstWhereOrNull((e) => e.isEncoder);
    final modelFileKey = fileInfos.firstWhereOrNull((e) => !e.isEncoder && e.fileName == widget.socPair.$2);
    final adapterFileKey = fileInfos.firstWhereOrNull((e) => e.isAdapter);

    if (encoderFileKey == null || modelFileKey == null) {
      Alert.error("Required model files not found");
      return;
    }
    final encoderLocalFile = P.fileManager.locals(encoderFileKey).q;
    final modelLocalFile = P.fileManager.locals(modelFileKey).q;
    final adapterLocalFile = adapterFileKey != null ? P.fileManager.locals(adapterFileKey).q : null;

    P.rwkv.currentWorldType.q = widget.worldType;

    qqq("worldType: ${widget.worldType}");

    P.rwkv.clearStates();
    P.chat.clearMessages();

    try {
      switch (widget.worldType) {
        case WorldType.reasoningQA:
        case WorldType.ocr:
          await P.rwkv.loadSee(
            modelPath: modelLocalFile.targetPath,
            encoderPath: encoderLocalFile.targetPath,
            backend: modelFileKey.backend!,
            enableReasoning: widget.worldType.isReasoning,
            adapterPath: null,
            fileInfo: modelFileKey,
          );
        case WorldType.modrwkvV2:
        case WorldType.modrwkvV3:
          final modelID = await P.rwkv.loadSee(
            modelPath: modelLocalFile.targetPath,
            encoderPath: encoderLocalFile.targetPath,
            backend: modelFileKey.backend!,
            enableReasoning: widget.worldType.isReasoning,
            adapterPath: adapterLocalFile?.targetPath,
            fileInfo: modelFileKey,
          );
          if (modelID != null) P.rwkv.send(SetImageUniqueIdentifier("image"));
          if (modelID != null) P.rwkv.send(SetSpaceAfterRoles(false, modelID: modelID));
      }
      Navigator.pop(getContext()!);
    } catch (e) {
      qqe("$e");
      Alert.error(e.toString());
      P.rwkv.currentWorldType.q = null;
      return;
    }

    P.preference.saveLastWorldModel({
      "worldType": widget.worldType.name,
      "modelFileName": modelFileKey.fileName,
    });
    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
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
      P.fileManager.activeDownloadGroupIds.q = P.fileManager.activeDownloadGroupIds.q.difference({widget.socPair.$2});

      // 1. Cancel the core file
      final modelFileKey = _fileInfos.firstWhereOrNull((e) => !e.isEncoder && e.fileName == widget.socPair.$2);
      if (modelFileKey != null) {
        await P.fileManager.cancelDownload(fileInfo: modelFileKey);
      }

      // 2. Check if we should cancel dependencies
      bool shouldCancelDependencies = true;
      final activeGroups = P.fileManager.activeDownloadGroupIds.q;
      final myId = widget.socPair.$2;

      for (final groupId in activeGroups) {
        if (groupId == myId) continue;
        final otherModel = P.fileManager.seeWeights.q.firstWhereOrNull((e) => e.fileName == groupId);
        if (otherModel != null && otherModel.worldType == widget.worldType) {
          shouldCancelDependencies = false;
          break;
        }
      }

      if (shouldCancelDependencies) {
        for (var fileInfo in _fileInfos) {
          if (fileInfo.fileName != widget.socPair.$2) {
            await P.fileManager.cancelDownload(fileInfo: fileInfo);
          }
        }
      }
    }
  }

  void _onPauseTap() {
    // 1. Pause the core file
    final modelFileKey = _fileInfos.firstWhereOrNull((e) => !e.isEncoder && e.fileName == widget.socPair.$2);
    if (modelFileKey == null) return;
    P.fileManager.pauseDownload(fileInfo: modelFileKey);

    // 2. Check if we should pause dependencies
    bool shouldPauseDependencies = true;
    final activeGroups = P.fileManager.activeDownloadGroupIds.q;
    final myId = widget.socPair.$2;

    for (final groupId in activeGroups) {
      if (groupId == myId) continue;
      final otherModel = P.fileManager.seeWeights.q.firstWhereOrNull((e) => e.fileName == groupId);
      if (otherModel != null && otherModel.worldType == widget.worldType) {
        shouldPauseDependencies = false;
        break;
      }
    }

    if (shouldPauseDependencies) {
      for (var fileInfo in _fileInfos) {
        if (fileInfo.fileName != widget.socPair.$2) {
          P.fileManager.pauseDownload(fileInfo: fileInfo);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_fileInfos.isEmpty) {
      qqw("fileInfos is empty, worldType: ${widget.worldType}");
      return const SizedBox.shrink();
    }

    final customTheme = ref.watch(P.app.customTheme);
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    final files = _fileInfos.m((e) {
      return ref.watch(P.fileManager.locals(e));
    });

    final allDownloaded = files.every((e) => e.hasFile);

    if (allDownloaded && P.fileManager.activeDownloadGroupIds.q.contains(widget.socPair.$2)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        P.fileManager.activeDownloadGroupIds.q = P.fileManager.activeDownloadGroupIds.q.difference({widget.socPair.$2});
      });
    }

    final downloading = _isDownloading();
    final overallState = _getOverallState();
    final overallProgress = _getOverallProgress();
    final totalSize = _getTotalSize();
    final networkSpeed = _getTotalSpeed();
    final timeRemaining = _getAverageRemaining();

    final isCurrentModel = P.rwkv.latestModel.q?.fileName == widget.socPair.$2;
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final alreadyStarted = currentWorldType == widget.worldType && isCurrentModel;
    final loading = ref.watch(P.rwkv.loading);
    final loadingStatus = ref.watch(P.rwkv.loadingStatus);

    final modelFileKey = _fileInfos.firstWhereOrNull((e) => !e.isEncoder && e.fileName == widget.socPair.$2);
    if (modelFileKey == null) {
      return const SizedBox.shrink();
    }
    final modelLoading =
        loadingStatus[modelFileKey] == .loading ||
        loadingStatus[modelFileKey] == .loadModelWithExtra ||
        loadingStatus[modelFileKey] == .setQnnLibraryPath;

    String startTitle = s.start_to_chat;
    if (loading || modelLoading) {
      startTitle = s.loading;
    }

    final remainText = timeRemaining.inMinutes == 0
        ? '${timeRemaining.inSeconds}s'
        : '${timeRemaining.inMinutes}m${timeRemaining.inSeconds % 60}s';

    return ClipRRect(
      borderRadius: 8.r,
      child: Container(
        decoration: BoxDecoration(
          color: customTheme.settingItem,
          borderRadius: 8.r,
          border: Border.all(color: qw.q(.1), width: .5),
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
                decoration: const BD(color: kC),
                child: Row(
                  children: [
                    Expanded(
                      child: _CollapsedContent(
                        modelName: _getModelName(),
                        totalSize: totalSize,
                        overallProgress: overallProgress,
                        downloading: downloading,
                        networkSpeed: networkSpeed,
                        remainText: remainText,
                        socPair: widget.socPair,
                        quantization: modelFileKey.quantization,
                      ),
                    ),
                    8.w,
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
                          onTap: (loading || modelLoading) ? null : _onStartToChatTap,
                          child: Container(
                            decoration: BoxDecoration(
                              color: (loading || modelLoading) ? kCG.q(.5) : kCG,
                              borderRadius: 8.r,
                            ),
                            padding: const .all(8),
                            child: T(
                              startTitle,
                              s: TS(c: qw),
                            ),
                          ),
                        ),
                      if (alreadyStarted)
                        GestureDetector(
                          onTap: null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: kG.q(.5),
                              borderRadius: 8.r,
                            ),
                            padding: const .all(8),
                            child: T(s.chatting, s: TS(c: qw)),
                          ),
                        ),
                      if (!alreadyStarted) 8.w,
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
                              borderRadius: 8.r,
                              border: Border.all(
                                color: Colors.transparent,
                              ),
                            ),
                            padding: const .all(5),
                            child: Icon(
                              Icons.delete_forever_outlined,
                              color: Theme.of(context).colorScheme.primary,
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
              8.h,
              ..._fileInfos.map(
                (e) => Container(
                  margin: const .only(top: 8),
                  padding: const .all(8),
                  decoration: BoxDecoration(
                    color: qb.q(.05),
                    borderRadius: 8.r,
                    border: Border.all(color: qb.q(.1), width: 1),
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
  final (String, String) socPair;
  final String? quantization;
  final Backend? backend;

  const _CollapsedContent({
    required this.modelName,
    required this.totalSize,
    required this.overallProgress,
    required this.downloading,
    required this.networkSpeed,
    required this.remainText,
    required this.socPair,
    this.quantization,
    // ignore: unused_element_parameter
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
            T(
              modelName,
              s: const TS(w: .w600),
            ),
            T(
              gbDisplay(totalSize),
              s: TS(c: qb.q(.7), w: .w500),
            ),
          ],
        ),
        4.h,
        _WorldTags(socPair: socPair, quantization: quantization, backend: backend),
        if (downloading) ...[
          8.h,
          Padding(
            padding: const EdgeInsetsGeometry.only(right: 40),
            child: LinearProgressIndicator(
              value: (overallProgress.isNaN || overallProgress <= 0 || overallProgress.isInfinite) ? null : overallProgress,
              borderRadius: 8.r,
            ),
          ),
          4.h,
          Wrap(
            children: [
              T(
                sprintf(S.current.str_downloading_info, [
                  (overallProgress.isNaN || overallProgress <= 0 || overallProgress.isInfinite) ? 0.0 : overallProgress * 100.0,
                  networkSpeed,
                  remainText,
                ]),
                s: TextStyle(
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

class _WorldTags extends ConsumerWidget {
  final (String, String) socPair;
  final String? quantization;
  final Backend? backend;

  const _WorldTags({required this.socPair, this.quantization, this.backend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNPU = socPair.$1.isNotEmpty;

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: [
        const ModelTag(tag: "Vision"),
        ModelTag(tag: isNPU ? "NPU" : "CPU"),
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
    await P.fileManager.getFile(fileInfo: fileInfo);
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
      await P.fileManager.cancelDownload(fileInfo: fileInfo);
    }
  }

  void _onPauseTap() {
    P.fileManager.pauseDownload(fileInfo: fileInfo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.fileManager.locals(fileInfo));
    final hasFile = localFile.hasFile;
    final downloading = localFile.downloading;
    final progress = localFile.progress / 100;
    final fileSize = fileInfo.fileSize;
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
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
                        T(
                          fileInfo.name,
                          s: const TS(
                            w: .w600,
                            s: 14,
                          ),
                        ),
                        4.h,
                        T(
                          gbDisplay(fileSize),
                          s: TS(
                            c: qb.q(.7),
                            w: .w500,
                            s: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasFile)
                    Icon(
                      Icons.download_done,
                      color: primary,
                      size: 20,
                    ),
                ],
              ),
              if (downloading) ...[
                8.h,
                LinearProgressIndicator(
                  value: (progress.isNaN || progress <= 0 || progress.isInfinite) ? null : progress,
                  borderRadius: 8.r,
                ),
                4.h,
                Wrap(
                  children: [
                    T(
                      sprintf(s.str_downloading_info, [
                        (progress.isNaN || progress <= 0 || progress.isInfinite) ? 0.0 : progress * 100.0,
                        networkSpeed,
                        remainText,
                      ]),
                      s: TextStyle(
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
        8.w,
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
                    await P.fileManager.deleteFile(fileInfo: fileInfo);
                  }
                },
                visualDensity: .compact,
                icon: const Icon(Icons.delete_forever_outlined),
              ),
          ],
        ),
      ],
    );
  }
}
