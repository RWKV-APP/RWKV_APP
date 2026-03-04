// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_downloader/downloader.dart' show TaskState;
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:sprintf/sprintf.dart';

// Project imports:
import 'package:zone/func/extensions/num.dart';
import 'package:zone/func/format_bytes.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/albatross.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/loading_progress_button_content.dart';
import 'package:zone/widgets/model_tag.dart';

class ModelItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final String? dimInfo;

  final VoidCallback? onLoadModelTap;
  final bool isCurrentModel;
  final bool loadButtonTextShowLoad;
  final bool showDelete;
  final bool showLoadModel;
  final bool showTags;

  const ModelItem(
    this.fileInfo,
    this.showTags, {
    super.key,
    this.onLoadModelTap,
    this.showLoadModel = true,
    this.showDelete = true,
    this.isCurrentModel = false,
    this.loadButtonTextShowLoad = false,
    this.dimInfo,
  });

  void _onStartTap() async {
    qq;
    if (onLoadModelTap != null) {
      onLoadModelTap!();
      return;
    }

    switch (P.app.demoType.q) {
      case .sudoku:
        await _onStartTapInSudoku();
      case .chat:
      case .fifthteenPuzzle:
      case .othello:
      case .tts:
      case .see:
        await _onStartTapInChat();
    }
  }

  Future<void> _onStartTapInSudoku() async {
    qq;
    final localFile = P.remote.locals(fileInfo).q;
    final modelPath = localFile.targetPath;
    final backend = fileInfo.backend;

    try {
      P.rwkv.clearStates();
      await P.rwkv.loadSudoku(modelPath: modelPath, backend: backend!);
    } catch (e) {
      Alert.error(e.toString());
    }

    if (!loadButtonTextShowLoad) {
      Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    }
    pop();
  }

  Future<void> _onStartTapInChat() async {
    qq;
    if (P.rwkv.generating.q) {
      Alert.warning(S.current.please_wait_for_the_model_to_generate);
      return;
    }

    if (P.rwkv.loading.q) {
      Alert.info(S.current.please_wait_for_the_model_to_load);
      return;
    }

    final modelSize = fileInfo.modelSize ?? 0.1;
    final pageKey = P.app.pageKey.q;
    if (modelSize < 1.5 && pageKey == .chat && !fileInfo.tags.contains("DeepEmbedding")) {
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

    final backend = fileInfo.backend;

    if (backend == null) {
      if (fileInfo.isAlbatross) {
        try {
          await Albatross.instance.load(fileInfo);
          Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
          pop();
        } catch (e) {
          Alert.error(e.toString());
        }
        return;
      }
      Alert.error("Backend is null");
      return;
    }

    try {
      P.rwkv.clearStates();
      await P.rwkv.loadChat(fileInfo: fileInfo);
    } catch (e) {
      qqe;
      Alert.error(e.toString());
      return;
    }

    final batchAllowed = fileInfo.tags.contains("batch");
    if (!batchAllowed) P.chat.batchEnabled.q = false;

    final tags = fileInfo.tags;

    final isTranslate = tags.contains("translate");
    final modelID = P.rwkv.findModelIDByWeightType(weightType: .chat);
    if (modelID == null) {
      return;
    }
    if (isTranslate) {
      if (P.translator.enToZh.q) {
        P.rwkv.send(SetUserRole("English", modelID: modelID));
        P.rwkv.send(SetResponseRole(responseRole: "Chinese", modelID: modelID));
      } else {
        P.rwkv.send(SetUserRole("Chinese", modelID: modelID));
        P.rwkv.send(SetResponseRole(responseRole: "English", modelID: modelID));
      }
      await P.rwkv.setModelConfig(thinkingMode: .none, prompt: "<EOD>", setPrompt: true);
      P.backend.start();
    } else {
      P.rwkv.send(SetUserRole("User", modelID: modelID));
      P.rwkv.send(SetResponseRole(responseRole: "Assistant", modelID: modelID));
    }

    if (!loadButtonTextShowLoad) {
      Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
    }

    final currentModelIsBefore20250922 = P.rwkv.currentModelIsBefore20250922.q;

    if (!isTranslate) {
      if (currentModelIsBefore20250922) {
        P.rwkv.setModelConfig(thinkingMode: .lighting);
      } else {
        P.rwkv.setModelConfig(thinkingMode: .fast);
      }
    }

    pop();

    for (var i = 0; i < 3; i++) {
      (500 * i).msLater.then((_) {
        P.rwkv.send(GetSupportedBatchSizes(modelID: modelID));
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.remote.locals(fileInfo));
    final hasFile = localFile.hasFile;
    final currentModel = ref.watch(P.rwkv.latestModel);
    final isCurrentModel = this.isCurrentModel || currentModel == fileInfo;
    final loadingStatus = ref.watch(P.rwkv.loadingStatus);
    final loadingProgress = ref.watch(P.rwkv.loadingProgress);

    final loading =
        loadingStatus[fileInfo] == .loading ||
        loadingStatus[fileInfo] == .loadModelWithExtra ||
        loadingStatus[fileInfo] == .setQnnLibraryPath;
    final modelLoadingProgress = loadingProgress[fileInfo];

    final demoType = ref.watch(P.app.demoType);
    final appTheme = ref.watch(P.app.theme);
    final startButtonRadius = appTheme.startButtonRadius;

    String startTitle;

    final isTranslate = fileInfo.tags.contains("translate");

    final osVersionNumbers = ref.watch(P.app.osVersionNumbers);
    final isIOS17OrEarlier = osVersionNumbers.isNotEmpty && osVersionNumbers.first <= 17 && Platform.isIOS;
    final isCoreML = fileInfo.tags.contains("coreml");

    switch (demoType) {
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
        startTitle = s.start_a_new_game;
      case .chat:
      case .tts:
      case .see:
        startTitle = isTranslate ? s.use_it_now : s.start_to_chat;
    }

    if (loadButtonTextShowLoad) startTitle = S.current.load_;

    final unzipping = ref.watch(P.rwkv.unzippingStatus(fileInfo));
    if (unzipping) startTitle = s.unzipping;
    final showLoadingProgress = loading && !unzipping;

    final qw = ref.watch(P.app.qw);
    final primary = appTheme.primary;

    return ClipRRect(
      borderRadius: .circular(8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: appTheme.settingItem,
              borderRadius: .circular(8),
              border: .all(color: qw.q(.1), width: .5),
            ),
            margin: const .only(top: 8),
            padding: const .all(8),
            child: Row(
              children: [
                Expanded(
                  child: _FileKeyItem(fileInfo, showTags: showTags),
                ),
                const SizedBox(width: 8),
                DownloadActions(file: fileInfo, state: localFile.state),
                if (hasFile) ...[
                  if (!isCurrentModel && showLoadModel)
                    GestureDetector(
                      onTap: _onStartTap,
                      child: AnimatedContainer(
                        // opacity: loading || unzipping ? 0.6 : 1,
                        duration: 200.ms,
                        child: Container(
                          decoration: BoxDecoration(
                            color: loading || unzipping ? appTheme.qb8 : primary,
                            borderRadius: .circular(startButtonRadius),
                          ),
                          padding: const .all(8),
                          child: showLoadingProgress
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
                  if (isCurrentModel)
                    GestureDetector(
                      onTap: null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: appTheme.qb8,
                          borderRadius: .circular(startButtonRadius),
                        ),
                        padding: const .all(8),
                        child: Text(loadButtonTextShowLoad ? S.current.loaded : s.chatting, style: TS(c: qw)),
                      ),
                    ),
                  if (!isCurrentModel && showDelete) const SizedBox(width: 8),
                  if (!isCurrentModel && showDelete) _Delete(fileInfo),
                ],
              ],
            ),
          ),
          if (isIOS17OrEarlier && isCoreML)
            Positioned.fill(
              child: Container(
                margin: const .only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .58),
                  borderRadius: .circular(8),
                  border: .all(color: kCY.q(1), width: 1),
                ),
                alignment: .center,
                padding: const .symmetric(horizontal: 16),
                child: Text(
                  S.current.model_item_ios18_weight_hint,
                  textAlign: TextAlign.center,
                  style: const TS(c: kCY, s: 13, w: .w600, height: 1.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DownloadActions extends ConsumerWidget {
  final TaskState state;
  final FileInfo file;

  const DownloadActions({super.key, required this.file, required this.state});

  void onCancelTap() async {
    final result = await showOkCancelAlertDialog(
      context: getContext()!,
      title: S.current.cancel_download + "?",
      okLabel: S.current.cancel,
      isDestructiveAction: true,
      cancelLabel: S.current.continue_download,
    );
    if (result == OkCancelResult.ok) {
      await P.remote.cancelDownload(fileInfo: file);
    }
  }

  void onDownloadTap(BuildContext context) async {
    await P.preference.tryShowBatteryOptimizationDialog(context);
    await P.remote.getFile(fileInfo: file);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDownload = state == TaskState.idle;
    final showResume = state == TaskState.stopped;
    final showPause = state == TaskState.running;
    final showCancel = showPause || showResume;
    final localFile = ref.watch(P.remote.locals(file));
    final hasFile = localFile.hasFile;
    return Row(
      mainAxisSize: .min,
      children: [
        if (showDownload && !hasFile)
          IconButton(
            onPressed: () => onDownloadTap(context),
            icon: const Icon(Icons.download_rounded),
            visualDensity: .compact,
          ),
        if (showCancel)
          IconButton(
            visualDensity: .compact,
            onPressed: onCancelTap,
            icon: const Icon(Icons.stop_rounded),
          ),
        if (showPause)
          IconButton(
            onPressed: () {
              P.remote.pauseDownload(fileInfo: file);
            },
            visualDensity: .compact,
            icon: const Icon(Icons.pause),
          ),
        if (showResume)
          IconButton(
            onPressed: () => onDownloadTap(context),
            visualDensity: .compact,
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
      await P.remote.deleteFile(fileInfo: fileInfo);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: _onTap,
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
    );
  }
}

class _FileKeyItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final bool showTags;

  const _FileKeyItem(this.fileInfo, {this.showTags = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.remote.locals(fileInfo));
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

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    final appTheme = ref.watch(P.app.theme);

    return Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            Text(
              fileInfo.name,
              style: const TS(w: .w600),
            ),
            Text(
              formatBytes(fileSize),
              style: TS(c: qb.q(.7), w: .w500),
            ),
          ],
        ),
        if (showTags) const SizedBox(height: 4),
        if (showTags) _Tags(fileInfo: fileInfo),
        if (downloading) const SizedBox(height: 8),
        if (downloading)
          Padding(
            padding: const .only(right: 40),
            child: LinearProgressIndicator(
              value: (progress.isNaN || progress <= 0 || progress.isInfinite) ? null : progress,
              borderRadius: .circular(8),
              backgroundColor: appTheme.qb11,
              color: appTheme.qb5,
            ),
          ),
        if (downloading) const SizedBox(height: 4),
        if (downloading)
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
    );
  }
}

class _Tags extends ConsumerWidget {
  const _Tags({required this.fileInfo});

  final FileInfo fileInfo;

  static const _blockedTags = ["encoder", "reason"];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantization = fileInfo.quantization?.toUpperCase();
    final tags = fileInfo.tags.where((e) => !_blockedTags.contains(e.toLowerCase()));
    final date = fileInfo.dateDisplayString;
    List<String> hiddenTags = [];

    if (Platform.isIOS || Platform.isMacOS) hiddenTags = ["gpu"];

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: <ModelTag>[
        if (fileInfo.backend == .webRwkv) const ModelTag(tag: "GPU"),
        ...tags.where((tag) => !hiddenTags.contains(tag)).map((tag) => ModelTag(tag: tag)),
        if (kDebugMode && fileInfo.isDebug) const ModelTag(tag: "DEBUG", forceBgColor: Colors.red, forceTextColor: kW),
        if (quantization != null && quantization.isNotEmpty) ModelTag(tag: quantization, forceUppercase: true),
        if (date != null) ModelTag(tag: date),
      ],
    );
  }
}
