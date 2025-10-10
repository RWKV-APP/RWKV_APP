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
import 'package:sprintf/sprintf.dart';
import 'package:zone/func/gb_display.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';

class ModelItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final bool showTags;
  final bool loadButtonTextShowLoad;

  const ModelItem(this.fileInfo, this.showTags, {super.key, this.loadButtonTextShowLoad = false});

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

  Future<void> _onStartTapInSudoku() async {
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
    if (!loadButtonTextShowLoad) {
      Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    }
    pop();
  }

  Future<void> _onStartTapInChat() async {
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
    if (modelSize < 1.5 && pageKey == PageKey.chat && !fileInfo.tags.contains("DeepEmbedding")) {
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
      qqe;
      Alert.error(e.toString());
      return;
    }

    final batchAllowed = fileInfo.tags.contains("batch");
    if (!batchAllowed) P.chat.batchEnabled.q = false;

    final tags = fileInfo.tags;

    if (tags.contains("translate")) {
      if (P.translator.enToZh.q) {
        P.rwkv.send(SetUserRole("English"));
        P.rwkv.send(SetResponseRole("Chinese"));
      } else {
        P.rwkv.send(SetUserRole("Chinese"));
        P.rwkv.send(SetResponseRole("English"));
      }
      await P.rwkv.setModelConfig(thinkingMode: const thinking_mode.None(), prompt: "");
      P.backend.start();
    } else {
      P.rwkv.send(SetUserRole("User"));
      P.rwkv.send(SetResponseRole("Assistant"));
    }

    P.rwkv.currentModel.q = fileInfo;
    if (!loadButtonTextShowLoad) {
      Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    }

    final currentModelIsBefore20250922 = P.rwkv.currentModelIsBefore20250922.q;

    if (currentModelIsBefore20250922) {
      P.rwkv.setModelConfig(thinkingMode: const thinking_mode.Lighting());
    } else {
      P.rwkv.setModelConfig(thinkingMode: const thinking_mode.Fast());
    }

    pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.fileManager.locals(fileInfo));
    final hasFile = localFile.hasFile;
    final currentModel = ref.watch(P.rwkv.currentModel);
    final isCurrentModel = currentModel == fileInfo;
    final loading = ref.watch(P.rwkv.loading);
    final demoType = ref.watch(P.app.demoType);
    final customTheme = ref.watch(P.app.customTheme);

    String startTitle;

    final isTranslate = fileInfo.tags.contains("translate");

    switch (demoType) {
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
        startTitle = s.start_a_new_game;
      case DemoType.chat:
      case DemoType.tts:
      case DemoType.world:
        startTitle = isTranslate ? s.use_it_now : s.start_to_chat;
    }

    if (loadButtonTextShowLoad) {
      startTitle = S.current.load_;
    }

    final qw = ref.watch(P.app.qw);

    return ClipRRect(
      borderRadius: 8.r,
      child: Container(
        decoration: BoxDecoration(
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
                GestureDetector(
                  onTap: _onStartTap,
                  child: Container(
                    decoration: BoxDecoration(
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
                GestureDetector(
                  onTap: null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kG.q(.5),
                      borderRadius: 8.r,
                    ),
                    padding: const EI.a(8),
                    child: T(loadButtonTextShowLoad ? S.current.loaded : s.chatting, s: TS(c: qw)),
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
    await P.fileManager.getFile(fileInfo: file);
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
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: BoxDecoration(
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
    double networkSpeed = localFile.networkSpeed.clamp(0, 99999999).toDouble();
    Duration timeRemaining = localFile.timeRemaining;
    if (timeRemaining.isNegative) timeRemaining = Duration.zero;
    final primary = Theme.of(getContext()!).colorScheme.primary;
    final qb = ref.watch(P.app.qb);

    final remainText = timeRemaining.inMinutes == 0
        ? '${timeRemaining.inSeconds}s'
        : '${timeRemaining.inMinutes}m${timeRemaining.inSeconds % 60}s';

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
              s: const TS(w: FontWeight.w600),
            ),
            T(
              gbDisplay(fileSize),
              s: TS(c: qb.q(.7), w: FontWeight.w500),
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
              T(
                sprintf(s.str_downloading_info, [progress * 100, networkSpeed, remainText]),
                s: const TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['Roboto Mono', 'Roboto', 'CourierNew', 'Menlo', 'PingFang SC'],
                ),
              ),
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
  static const _highlightTags = ["NPU", "GPU", "npu", "gpu", "DeepEmbedding", "batch"];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantization = fileInfo.quantization?.toUpperCase();
    final tags = fileInfo.tags.where((e) => !_blockedTags.contains(e));
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);
    final date = fileInfo.dateDisplayString;

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: [
        ...tags.map((tag) {
          final showHighlight = _highlightTags.contains(tag);
          if (tag == "DeepEmbedding") tag = "DE";
          return Container(
            decoration: BoxDecoration(
              borderRadius: 4.r,
              color: showHighlight ? kCG : kG.q(.2),
            ),
            padding: const EI.s(h: 4),
            child: T(
              tag.toUpperCase(),
              s: TS(
                c: showHighlight ? qw : qb,
                w: showHighlight ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          );
        }),
        if (kDebugMode && fileInfo.isDebug)
          Container(
            decoration: BoxDecoration(color: kCR, borderRadius: 4.r),
            padding: const EI.s(h: 4),
            child: T("DEBUG", s: TS(c: qw)),
          ),
        if (quantization != null && quantization.isNotEmpty)
          Container(
            decoration: BoxDecoration(color: kG.q(.2), borderRadius: 4.r),
            padding: const EI.s(h: 4),
            child: T(quantization),
          ),
        if (date != null)
          Container(
            decoration: BoxDecoration(color: kG.q(.2), borderRadius: 4.r),
            padding: const EI.s(h: 4),
            child: T(date),
          ),
      ],
    );
  }
}
