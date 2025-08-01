// ignore: unused_import
import 'dart:developer';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_downloader/downloader.dart' show TaskState;
import 'package:rwkv_mobile_flutter/to_rwkv.dart';
import 'package:zone/func/gb_display.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/rag_init_dialog.dart';

class ModelItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final bool showTags;

  const ModelItem(this.fileInfo, this.showTags, {super.key});

  void _onStartTap(BuildContext context) async {
    qq;

    if (fileInfo.isEmbedding) {
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 100));
      RagInitDialog.show(getContext()!);
      return;
    }

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
    if (P.chat.receivingTokens.q) {
      Alert.warning(S.current.please_wait_for_the_model_to_generate);
      return;
    }

    if (P.rwkv.loading.q) {
      Alert.info(S.current.please_wait_for_the_model_to_load);
      return;
    }

    final modelSize = fileInfo.modelSize ?? 0.1;
    final pageKey = P.app.pageKey.q;
    if (modelSize < 1.5 && pageKey == PageKey.chat) {
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

    try {
      P.rwkv.clearStates();
      await P.rwkv.loadChat(
        modelPath: modelPath,
        backend: backend!,
        enableReasoning: fileInfo.isReasoning,
      );
    } catch (e) {
      Alert.error(e.toString());
      return;
    }

    final tags = fileInfo.tags;

    if (tags.contains("translate")) {
      P.rwkv.send(SetUserRole("English"));
      P.rwkv.send(SetResponseRole("Chinese"));
      await P.rwkv.setModelConfig(thinkingMode: const thinking_mode.None(), prompt: "");
      P.backend.start();
    } else {
      P.rwkv.send(SetUserRole("User"));
      P.rwkv.send(SetResponseRole("Assistant"));
    }

    P.rwkv.currentModel.q = fileInfo;
    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    pop();
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

    String startTitle;

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
    if (fileInfo.isEmbedding) {
      startTitle = s.load_model;
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
              child: FileKeyItem(fileInfo, showTags: showTags),
            ),
            8.w,
            _DownloadActions(file: fileInfo, state: localFile.state),
            if (hasFile) ...[
              if (!isCurrentModel)
                GD(
                  onTap: () => _onStartTap(context),
                  child: C(
                    decoration: BD(
                      color: loading ? kCG.q(.5) : kCG,
                      borderRadius: 8.r,
                    ),
                    padding: const EI.a(8),
                    child: T(
                      loading ? s.loading : startTitle,
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

class _DownloadActions extends StatelessWidget {
  final TaskState state;
  final FileInfo file;

  const _DownloadActions({required this.file, required this.state});

  void onCancelTap() async {
    final result = await showOkCancelAlertDialog(
      context: getContext()!,
      title: S.current.cancel_download + "?",
      okLabel: S.current.cancel,
      isDestructiveAction: true,
      cancelLabel: S.current.continue_download,
    );
    if (result == OkCancelResult.ok) {
      await P.fileManager.cancelDownload(fileInfo: file);
    }
  }

  void onDownloadTap(BuildContext context) async {
    await P.preference.tryShowBatteryOptimizationDialog(context);

    try {
      await P.fileManager.getFile(fileInfo: file);
    } catch (e) {
      qqe(e);
      Alert.error(S.current.download_failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDownload = state == TaskState.idle;
    final showResume = state == TaskState.stopped;
    final showPause = state == TaskState.running;
    final showCancel = showPause || showResume;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDownload)
          IconButton(
            onPressed: () => onDownloadTap(context),
            icon: const Icon(Icons.download_rounded),
            visualDensity: VisualDensity.compact,
          ),
        if (showCancel)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onCancelTap,
            icon: const Icon(Icons.stop_rounded),
          ),
        if (showPause)
          IconButton(
            onPressed: () {
              P.fileManager.pauseDownload(fileInfo: file);
            },
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.pause),
          ),
        if (showResume)
          IconButton(
            onPressed: () => onDownloadTap(context),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
      ],
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
  final bool showTags;

  const FileKeyItem(this.fileInfo, {super.key, this.showDownloaded = false, this.showTags = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.fileManager.locals(fileInfo));
    final fileSize = fileInfo.fileSize;
    final progress = localFile.progress / 100;
    final downloading = localFile.downloading;
    double networkSpeed = localFile.networkSpeed;
    if (networkSpeed < 0) networkSpeed = 0;
    Duration timeRemaining = localFile.timeRemaining;
    if (timeRemaining.isNegative) timeRemaining = Duration.zero;
    final primary = Theme.of(getContext()!).colorScheme.primary;
    final qb = ref.watch(P.app.qb);

    return Column(
      crossAxisAlignment: CAA.start,
      mainAxisAlignment: MainAxisAlignment.center,
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
        if (showTags) 4.h,
        if (showTags) _Tags(fileInfo: fileInfo),
        if (downloading) 8.h,
        if (downloading)
          Padding(
            padding: const EdgeInsetsGeometry.only(right: 40),
            child: LinearProgressIndicator(
              value: (progress.isNaN || progress <= 0 || progress.isInfinite) ? null : progress,
              borderRadius: 8.r,
            ),
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
  const _Tags({required this.fileInfo});

  final FileInfo fileInfo;

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
