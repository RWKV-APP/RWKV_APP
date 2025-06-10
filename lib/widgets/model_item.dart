// ignore: unused_import
import 'dart:developer';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:zone/config.dart';
import 'package:zone/func/gb_display.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/route/method.dart';
import 'package:zone/route/router.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/state/p.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

class ModelItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final bool isUnavailable;

  const ModelItem(this.fileInfo, {super.key, this.isUnavailable = false});

  void _onStartTap() async {
    qq;

    switch (P.app.demoType.q) {
      case DemoType.sudoku:
        await _onStartTapInSudoku();
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.tts:
      case DemoType.world:
        await _onStartTapInChat();
    }
  }

  FV _onStartTapInSudoku() async {
    qq;
    final localFile = P.fileManager.locals(fileInfo).q;
    final modelPath = localFile.targetPath;
    final backend = fileInfo.backend;

    try {
      P.rwkv.clearStates();
      await P.rwkv.loadSudoku(modelPath: modelPath, backend: backend!);
    } catch (e) {
      Alert.error(e.toString());
    }

    P.rwkv.currentModel.q = fileInfo;
    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    pop();
  }

  FV _onStartTapInChat() async {
    qq;

    final modelSize = fileInfo.modelSize ?? 0.1;
    if (modelSize < 1.5 && !kDebugMode) {
      final result = await showOkCancelAlertDialog(
        context: getContext()!,
        title: S.current.size_recommendation,
        okLabel: S.current.continue_using_smaller_model,
        cancelLabel: S.current.reselect_model,
      );
      if (result != OkCancelResult.ok) {
        return;
      }
    }

    final localFile = P.fileManager.locals(fileInfo).q;
    final modelPath = localFile.targetPath;
    final backend = fileInfo.backend;
    final modelPathForCoreML = modelPath.replaceAll(".zip", "");

    if (backend == Backend.coreml) {
      P.fileManager.unzipping.q = true;
      final from = modelPath;
      final to = path.dirname(modelPath);
      final startMS = HF.debugShorterMS;
      await compute((List<String> args) async {
        final zipPath = args[0];
        final targetFolder = args[1];
        final unzipPath = args[2];
        final exists = await Directory(unzipPath).exists();
        if (!exists) {
          qqw("Unzipped directory not found: $unzipPath");
          qqw("unzipping...");
          await extractFileToDisk(zipPath, targetFolder);
        } else {
          qqw("Unzipped directory found: $unzipPath");
          qqw("Skipping unzip");
        }
      }, [from, to, modelPathForCoreML]);
      final endMS = HF.debugShorterMS;
      qqq("extract time: ${endMS - startMS}");
      P.fileManager.unzipping.q = false;
    }

    if (backend == Backend.coreml) {
      qqr("Using coreml");
    }

    try {
      if (!Config.enableConversation) P.chat.clearMessages();
      await P.rwkv.loadChat(
        modelPath: backend == Backend.coreml ? modelPathForCoreML : modelPath,
        backend: backend!,
        enableReasoning: fileInfo.isReasoning,
        fileInfo: fileInfo,
      );
    } catch (e) {
      Alert.error(e.toString());
      return;
    }

    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    pop();
  }

  void _onDownloadTap() async {
    P.fileManager.getFile(fileInfo: fileInfo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.fileManager.locals(fileInfo));
    final hasFile = localFile.hasFile;
    final downloading = localFile.downloading;
    final currentModel = ref.watch(P.rwkv.currentModel);
    final isCurrentModel = currentModel == fileInfo;
    final loading = ref.watch(P.rwkv.loading);
    final demoType = ref.watch(P.app.demoType);
    final customTheme = ref.watch(P.app.customTheme);
    final unzipping = ref.watch(P.fileManager.unzipping);

    late final String startTitle;

    switch (demoType) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        startTitle = s.start_a_new_game;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
        startTitle = s.start_to_chat;
    }

    late final String loadingTitle;
    if (unzipping) {
      loadingTitle = s.unzipping;
    } else {
      loadingTitle = s.loading;
    }

    final qw = ref.watch(P.app.qw);

    return ClipRRect(
      borderRadius: 8.r,
      child: C(
        decoration: BD(
          color: customTheme.settingItem,
          borderRadius: 8.r,
          border: Border.all(color: qw.q(.1), width: .5),
        ),
        margin: const EI.o(t: 8),
        padding: const EI.a(8),
        child: Row(
          children: [
            Expanded(
              child: FileKeyItem(fileInfo, isUnavailable: isUnavailable),
            ),
            8.w,
            if (!hasFile && !downloading && !isUnavailable)
              IconButton(
                onPressed: _onDownloadTap,
                icon: const Icon(Icons.download),
              ),
            if (downloading) _DownloadIndicator(fileInfo),
            if (hasFile) ...[
              if (!isCurrentModel)
                GD(
                  onTap: _onStartTap,
                  child: C(
                    decoration: BD(
                      color: (loading || unzipping) ? kCG.q(.5) : kCG,
                      borderRadius: 8.r,
                    ),
                    padding: const EI.a(8),
                    child: T(
                      loading || unzipping ? loadingTitle : startTitle,
                      s: TS(c: qw),
                    ),
                  ),
                ),
              if (isCurrentModel)
                GD(
                  onTap: null,
                  child: C(
                    decoration: BD(
                      color: kG.q(.5),
                      borderRadius: 8.r,
                    ),
                    padding: const EI.a(8),
                    child: T(s.chatting, s: TS(c: qw)),
                  ),
                ),
              if (!isCurrentModel) 8.w,
              if (!isCurrentModel) _Delete(fileInfo),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadIndicator extends ConsumerWidget {
  final FileInfo fileInfo;

  const _DownloadIndicator(this.fileInfo);

  void _onTap() async {
    qq;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    return GD(
      onTap: _onTap,
      child: C(
        margin: const EI.o(r: 8),
        child: Stack(
          children: [
            const SB(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              left: 0,
              child: Icon(
                Icons.stop,
                size: 16,
                color: qb.q(.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Delete extends ConsumerWidget {
  final FileInfo fileInfo;

  const _Delete(this.fileInfo);

  void _onTap() async {
    qq;
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    return GD(
      onTap: _onTap,
      child: C(
        decoration: BD(
          color: kC,
          borderRadius: 8.r,
          border: Border.all(
            color: kC,
          ),
        ),
        padding: const EI.a(5),
        child: Icon(
          Icons.delete_forever_outlined,
          color: primary,
        ),
      ),
    );
  }
}

class FileKeyItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final bool showDownloaded;
  final bool isUnavailable;

  const FileKeyItem(this.fileInfo, {super.key, this.showDownloaded = false, this.isUnavailable = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.fileManager.locals(fileInfo));
    final fileSize = fileInfo.fileSize;
    final progress = localFile.progress;
    final downloading = localFile.downloading;
    final modelSize = fileInfo.modelSize ?? 0;
    final quantization = fileInfo.quantization;
    double networkSpeed = localFile.networkSpeed;
    if (networkSpeed < 0) networkSpeed = 0;
    Duration timeRemaining = localFile.timeRemaining;
    if (timeRemaining.isNegative) timeRemaining = Duration.zero;
    final tags = fileInfo.tags;
    final primary = Theme.of(getContext()!).colorScheme.primary;
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    return Column(
      crossAxisAlignment: CAA.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            T(
              fileInfo.name,
              s: const TS(w: FW.w600),
            ),
            T(
              gbDisplay(fileSize),
              s: TS(c: qb.q(.7), w: FW.w500),
            ),
            if (showDownloaded && localFile.hasFile)
              Icon(
                Icons.download_done,
                color: primary,
                size: 20,
              ),
          ],
        ),
        4.h,
        _Tags(fileInfo: fileInfo, isUnavailable: isUnavailable),
        if (downloading) 8.h,
        if (downloading)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SB(
                width: width - 100,
                child: Row(
                  children: [
                    Expanded(
                      flex: (100 * progress).toInt(),
                      child: C(
                        decoration: BD(
                          borderRadius: BorderRadius.only(topLeft: 8.rr, bottomLeft: 8.rr),
                          color: kCG,
                        ),
                        height: 4,
                      ),
                    ),
                    Expanded(
                      flex: 100 - (100 * progress).toInt(),
                      child: C(
                        decoration: BD(
                          borderRadius: BorderRadius.only(topRight: 8.rr, bottomRight: 8.rr),
                          color: kG.q(.5),
                        ),
                        height: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (downloading) 4.h,
        if (downloading)
          Wrap(
            children: [
              T(s.speed),
              T("${networkSpeed.toStringAsFixed(1)}MB/s"),
              12.w,
              T(s.remaining),
              if (timeRemaining.inMinutes > 0) T("${timeRemaining.inMinutes}m"),
              if (timeRemaining.inMinutes == 0) T("${timeRemaining.inSeconds}s"),
            ],
          ),
      ],
    );
  }
}

class _Tags extends ConsumerWidget {
  const _Tags({required this.fileInfo, this.isUnavailable = false});

  final FileInfo fileInfo;
  final bool isUnavailable;

  static const _blockedTags = ["encoder", "reason", "ENCODER", "REASON"];
  static const _highlightTags = ["NPU", "GPU", "npu", "gpu"];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantization = fileInfo.quantization?.toUpperCase();
    final tags = fileInfo.tags.where((e) => !_blockedTags.contains(e));
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: [
        ...tags.map((tag) {
          final showHighlight = _highlightTags.contains(tag);
          return C(
            decoration: BD(
              borderRadius: 4.r,
              color: showHighlight ? kCG : kG.q(.2),
            ),
            padding: const EI.s(h: 4),
            child: T(
              tag.toUpperCase(),
              s: TS(
                c: showHighlight ? qw : qb,
                w: showHighlight ? FW.w500 : FW.w400,
              ),
            ),
          );
        }),
        if (kDebugMode && fileInfo.isDebug)
          Container(
            decoration: BD(color: kCR, borderRadius: 4.r),
            padding: const EI.s(h: 4),
            child: T("DEBUG", s: TS(c: qw)),
          ),
        if (kDebugMode && isUnavailable)
          Container(
            decoration: BD(color: kCR, borderRadius: 4.r),
            padding: const EI.s(h: 4),
            child: T("DEBUG: UNAVAILABLE", s: TS(c: qw)),
          ),
        if (quantization != null && quantization.isNotEmpty)
          C(
            decoration: BD(color: kG.q(.2), borderRadius: 4.r),
            padding: const EI.s(h: 4),
            child: T(quantization),
          ),
      ],
    );
  }
}
