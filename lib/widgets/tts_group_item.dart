// ignore: unused_import
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter_roleplay/flutter_roleplay.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/group_info.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:zone/func/gb_display.dart';

ModelInfo? rolePlayTTSModel;

class TTSGroupItem extends ConsumerWidget {
  final FileInfo fileInfo;

  TTSGroupItem(
    this.fileInfo, {
    super.key,
  }) : assert(fileInfo.tags.contains("core"), "fileInfo must be a core model");

  Future<void> _onDownloadAllTap() async {
    final helperModels = P.fileManager.ttsWeights.q.where((e) => !e.tags.contains("core")).toList();
    final core = fileInfo;
    final missingFileInfos = [...helperModels, core].where((e) => P.fileManager.locals(e).q.hasFile == false).toList();
    for (var e in missingFileInfos) {
      P.fileManager.getFile(fileInfo: e);
    }
  }

  Future<void> _onDeleteAllTap() async {
    final helperModels = P.fileManager.ttsWeights.q.where((e) => !e.tags.contains("core")).toList();
    final core = fileInfo;
    for (var e in [...helperModels, core]) {
      P.fileManager.deleteFile(fileInfo: e);
    }
  }

  Future<void> _onSparkTap() async {
    if (P.rwkv.loading.q) {
      Alert.warning(S.current.please_wait_for_the_model_to_load);
      return;
    }
    final availableModels = P.fileManager.ttsWeights.q;
    final fileInfos = availableModels.toList();
    final sparkFileKeys = fileInfos.where((e) => e.tags.contains("spark")).toList();
    if (sparkFileKeys.isEmpty) {
      Alert.error("Spark file not found");
      qqe;
      return;
    }

    final wav2vec2FileKey = sparkFileKeys.firstWhereOrNull((e) => e.tags.contains("wav2vec2"));
    final detokenizeFileKey = sparkFileKeys.firstWhereOrNull((e) => e.tags.contains("detokenize"));
    final bicodecTokenizeFileKey = sparkFileKeys.firstWhereOrNull((e) => e.tags.contains("tokenize"));

    if (wav2vec2FileKey == null) {
      Alert.error("Wav2vec2 file not found");
      qqe;
      return;
    }

    if (detokenizeFileKey == null) {
      Alert.error("Detokenize file not found");
      qqe;
      return;
    }

    if (bicodecTokenizeFileKey == null) {
      Alert.error("Tokenize file not found");
      qqe;
      return;
    }

    final modelLocalFile = P.fileManager.locals(fileInfo).q;
    final localWav2vec2File = P.fileManager.locals(wav2vec2FileKey).q;
    final localDetokenizeFile = P.fileManager.locals(detokenizeFileKey).q;
    final localTokenizeFile = P.fileManager.locals(bicodecTokenizeFileKey).q;

    if (P.app.pageKey.q == PageKey.rolePlaying) {
      final info = ModelInfo(
        id: fileInfo.fileName,
        modelPath: modelLocalFile.targetPath,
        statePath: '',
        backend: fileInfo.backend!,
        modelType: RoleplayManageModelType.tts,
      );
      final sp = await P.rwkv.loadTTS(
        modelPath: modelLocalFile.targetPath,
        backend: fileInfo.backend!,
        wav2vec2Path: localWav2vec2File.targetPath,
        detokenizePath: localDetokenizeFile.targetPath,
        bicodecTokenzerPath: localTokenizeFile.targetPath,
        fileInfo: fileInfo,
      );
      RoleplayManage.onModelDownloadComplete(info, [sp.$1, sp.$2], P.rwkv.receivePort);
      Navigator.pop(getContext()!);
      return;
    }

    P.rwkv.clearStates();
    P.chat.clearMessages();

    try {
      await P.rwkv.loadTTS(
        modelPath: modelLocalFile.targetPath,
        backend: fileInfo.backend!,
        wav2vec2Path: localWav2vec2File.targetPath,
        detokenizePath: localDetokenizeFile.targetPath,
        bicodecTokenzerPath: localTokenizeFile.targetPath,
        fileInfo: fileInfo,
      );
      P.talk.getTTSSpkNames();
      Navigator.pop(getContext()!);
    } catch (e) {
      qqe("$e");
      Alert.error(e.toString());
      P.rwkv.currentGroupInfo.q = null;
      return;
    }

    P.rwkv.currentGroupInfo.q = GroupInfo(displayName: fileInfo.name);
    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
  }

  Future<void> _onContinueTap() async {
    qq;
    pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final availableModels = ref.watch(P.fileManager.ttsWeights);
    final isSpark = fileInfo.tags.contains("spark");
    final fileInfos = availableModels.toList().where((e) {
      return !e.tags.contains("core") && (isSpark ? e.tags.contains("spark") : !e.tags.contains("spark"));
    }).toList();
    fileInfos.insert(0, fileInfo);
    if (fileInfos.isEmpty) return const SizedBox.shrink();

    final customTheme = ref.watch(P.app.customTheme);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = !customTheme.light;

    // 适配深色和浅色模式的颜色
    final cardColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final fileItemBgColor = isDark ? const Color(0xFF252525) : const Color(0xFFF8F9FA);
    final fileItemBorderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8);
    final primaryColor = colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    final files = fileInfos.m((e) {
      return ref.watch(P.fileManager.locals(e));
    });

    final allDownloaded = files.every((e) => e.hasFile);
    final allMissing = files.every((e) => !e.hasFile);
    final downloading = files.any((e) => e.downloading);

    final currentModel = ref.watch(P.rwkv.latestModel);
    bool alreadyStarted = currentModel == fileInfo;
    final loading = ref.watch(P.rwkv.loading);
    final isDesktop = ref.watch(P.app.isDesktop);

    if (P.app.pageKey.q == PageKey.rolePlaying) {
      alreadyStarted = fileInfo.fileName == rolePlayTTSModel?.id;
    }

    return Container(
      margin: const .only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: .circular(16),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.q(.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.q(.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: .all(isDesktop ? 12 : 8),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            // 标题栏
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      T(
                        fileInfo.name,
                        s: TS(
                          s: 18,
                          w: .w600,
                          c: textColor,
                        ),
                      ),
                      4.h,
                      Row(
                        children: [
                          Container(
                            padding: const .symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.q(.1),
                              borderRadius: .circular(12),
                            ),
                            child: T(
                              "TTS",
                              s: TS(
                                s: 12,
                                w: .w500,
                                c: primaryColor,
                              ),
                            ),
                          ),
                          8.w,
                          // 国旗图标
                          Row(
                            children: [
                              const T("🇨🇳", s: TS(s: 14)),
                              4.w,
                              const T("🇺🇸", s: TS(s: 14)),
                              4.w,
                              const T("🇯🇵", s: TS(s: 14)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 操作按钮
            Row(
              children: [
                if (downloading) 8.h,
                if (allMissing && !downloading)
                  _ActionButton(
                    text: s.download_all,
                    onPressed: _onDownloadAllTap,
                    color: primaryColor,
                    isDark: isDark,
                  ),
                if (!allMissing && !allDownloaded && !downloading)
                  _ActionButton(
                    text: s.download_missing,
                    onPressed: _onDownloadAllTap,
                    color: primaryColor,
                    isDark: isDark,
                  ),
                if (allDownloaded && !alreadyStarted)
                  _ActionButton(
                    text: s.delete_all,
                    onPressed: _onDeleteAllTap,
                    color: Colors.red,
                    isDark: isDark,
                  ),
                if (alreadyStarted)
                  _ActionButton(
                    text: s.exploring,
                    onPressed: null,
                    color: Colors.grey,
                    isDark: isDark,
                  ),
                const Spacer(),
                if (allDownloaded && !alreadyStarted)
                  _ActionButton(
                    text: loading ? s.loading : s.start_to_chat,
                    onPressed: loading ? null : _onSparkTap,
                    color: primaryColor,
                    isDark: isDark,
                    isPrimary: true,
                  ),
                if (alreadyStarted)
                  _ActionButton(
                    text: loading ? s.loading : s.back_to_chat,
                    onPressed: loading ? null : _onContinueTap,
                    color: primaryColor,
                    isDark: isDark,
                    isPrimary: true,
                  ),
              ],
            ),

            // 文件列表
            ...fileInfos.m(
              (e) => Container(
                decoration: BoxDecoration(
                  color: fileItemBgColor,
                  border: Border.all(color: fileItemBorderColor, width: 1),
                  borderRadius: .circular(12),
                ),
                padding: .all(isDesktop ? 12 : 8),
                margin: const .only(top: 8),
                child: _FileItem(
                  fileInfo: e,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final bool isDark;
  final bool isPrimary;

  const _ActionButton({
    required this.text,
    required this.onPressed,
    required this.color,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: .circular(8),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const .symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: .circular(8),
            ),
          ),
          child: T(
            text,
            s: const TS(
              w: .w600,
              s: 14,
            ),
          ),
        ),
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const .symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: .circular(8),
        ),
      ),
      child: T(
        text,
        s: TS(
          w: .w600,
          s: 14,
          c: color,
        ),
      ),
    );
  }
}

class _FileItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final bool isDark;
  final Color primaryColor;
  final Color textColor;
  final Color secondaryTextColor;

  const _FileItem({
    required this.fileInfo,
    required this.isDark,
    required this.primaryColor,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localFile = ref.watch(P.fileManager.locals(fileInfo));
    final hasFile = localFile.hasFile;
    final downloading = localFile.downloading;
    final progress = localFile.progress / 100;
    final fileSize = fileInfo.fileSize;
    double networkSpeed = localFile.networkSpeed;
    if (networkSpeed < 0) networkSpeed = 0;
    Duration timeRemaining = localFile.timeRemaining;
    if (timeRemaining.isNegative) timeRemaining = Duration.zero;

    return Column(
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
                    s: TS(
                      w: .w600,
                      c: textColor,
                      s: 14,
                    ),
                  ),
                  4.h,
                  T(
                    gbDisplay(fileSize),
                    s: TS(
                      c: secondaryTextColor,
                      w: .w500,
                      s: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              Container(
                padding: const .symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.q(.1),
                  borderRadius: .circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 16,
                ),
              ),
          ],
        ),

        8.h,

        // 标签
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...fileInfo.tags.map((tag) {
              final isHighlight = ["GPU", "CPU", "NPU", "gpu", "cpu", "npu"].contains(tag);
              if (fileInfo.backend == Backend.webRwkv) {
                tag = "WebRWKV";
              }
              return Container(
                padding: const .symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? (tag.toLowerCase() == "gpu" ? Colors.green.q(.2) : Colors.blue.q(.2))
                      : (isDark ? Colors.grey.q(.2) : Colors.grey.q(.1)),
                  borderRadius: .circular(8),
                ),
                child: T(
                  tag.toUpperCase(),
                  s: TS(
                    c: isHighlight ? (tag.toLowerCase() == "gpu" ? Colors.green : Colors.blue) : secondaryTextColor,
                    w: .w500,
                    s: 10,
                  ),
                ),
              );
            }),
          ],
        ),

        if (downloading) ...[
          12.h,
          LinearProgressIndicator(
            value: (progress.isNaN || progress <= 0 || progress.isInfinite) ? null : progress,
            backgroundColor: isDark ? Colors.grey.q(.3) : Colors.grey.q(.2),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            borderRadius: .circular(4),
          ),
          8.h,
          Wrap(
            spacing: 8,
            children: [
              T(
                s.speed,
                s: TS(
                  c: secondaryTextColor,
                  w: .w500,
                  s: 11,
                ),
              ),
              T(
                "${networkSpeed.toStringAsFixed(1)}MB/s",
                s: TS(
                  c: textColor,
                  w: .w600,
                  s: 11,
                ),
              ),
              16.w,
              T(
                s.remaining,
                s: TS(
                  c: secondaryTextColor,
                  w: .w500,
                  s: 11,
                ),
              ),
              T(
                timeRemaining.inMinutes > 0 ? "${timeRemaining.inMinutes}m" : "${timeRemaining.inSeconds}s",
                s: TS(
                  c: textColor,
                  w: .w600,
                  s: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
