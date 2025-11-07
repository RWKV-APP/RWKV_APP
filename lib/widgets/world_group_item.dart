// ignore: unused_import
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:zone/func/gb_display.dart';

class WorldGroupItem extends ConsumerWidget {
  final WorldType worldType;
  final (String, String) socPair;

  const WorldGroupItem(this.worldType, {super.key, required this.socPair});

  List<FileInfo> get _fileInfos {
    final worldWeights = P.fileManager.worldWeights.q.where((e) => e.worldType == worldType).where((file) {
      return file.isEncoder || file.isAdapter || (!file.isEncoder && file.fileName == socPair.$2);
    }).toList();
    return worldWeights;
  }

  void _onDownloadAllTap() async {
    final missingFileInfos = _fileInfos.where((e) => P.fileManager.locals(e).q.hasFile == false).toList();
    for (var e in missingFileInfos) {
      P.fileManager.getFile(fileInfo: e);
    }
  }

  void _onDeleteAllTap() async {
    for (var e in _fileInfos) {
      P.fileManager.deleteFile(fileInfo: e);
    }
  }

  void _onStartToChatTap() async {
    if (P.rwkv.loading.q) {
      Alert.warning("Please wait for the model to load...");
      return;
    }
    final availableModels = P.fileManager.worldWeights.q;
    final fileInfos = availableModels.where((e) => e.worldType == worldType).toList();
    final encoderFileKey = fileInfos.firstWhere((e) => e.isEncoder);
    final modelFileKey = fileInfos.firstWhere((e) => !e.isEncoder && e.fileName == socPair.$2);
    final adapterFileKey = fileInfos.firstWhereOrNull((e) => e.isAdapter);
    final encoderLocalFile = P.fileManager.locals(encoderFileKey).q;
    final modelLocalFile = P.fileManager.locals(modelFileKey).q;
    final adapterLocalFile = adapterFileKey != null ? P.fileManager.locals(adapterFileKey).q : null;

    P.rwkv.currentWorldType.q = worldType;

    qqq("worldType: $worldType");

    P.rwkv.clearStates();
    P.chat.clearMessages();

    try {
      switch (worldType) {
        case WorldType.reasoningQA:
        case WorldType.ocr:
          await P.rwkv.loadWorldVision(
            modelPath: modelLocalFile.targetPath,
            encoderPath: encoderLocalFile.targetPath,
            backend: modelFileKey.backend!,
            enableReasoning: worldType.isReasoning,
            adapterPath: null,
          );
        case WorldType.modrwkvV2:
        case WorldType.modrwkvV3:
          await P.rwkv.loadWorldVision(
            modelPath: modelLocalFile.targetPath,
            encoderPath: encoderLocalFile.targetPath,
            backend: modelFileKey.backend!,
            enableReasoning: worldType.isReasoning,
            adapterPath: adapterLocalFile?.targetPath,
          );
      }
      Navigator.pop(getContext()!);
    } catch (e) {
      qqe("$e");
      Alert.error(e.toString());
      P.rwkv.currentWorldType.q = null;
      return;
    }

    P.rwkv.currentModel.q = modelFileKey;
    Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
  }

  void _onContinueTap() async {
    qq;
    pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    if (_fileInfos.isEmpty) {
      qqw("fileInfos is empty, worldType: $worldType");
      return const SizedBox.shrink();
    }

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

    final files = _fileInfos.m((e) {
      return ref.watch(P.fileManager.locals(e));
    });

    final allDownloaded = files.every((e) => e.hasFile);
    final allMissing = files.every((e) => !e.hasFile);
    final downloading = files.any((e) => e.downloading);

    final isCurrentModel = P.rwkv.currentModel.q?.fileName == socPair.$2;

    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final alreadyStarted = currentWorldType == worldType && isCurrentModel;
    final loading = ref.watch(P.rwkv.loading);
    final isDesktop = ref.watch(P.app.isDesktop);

    return Container(
      margin: const EI.o(t: 0, l: 0, r: 0, b: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
        padding: EI.a(isDesktop ? 12 : 8),
        child: Column(
          crossAxisAlignment: CAA.stretch,
          children: [
            // 标题栏
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CAA.start,
                    children: [
                      T(
                        worldType.displayName,
                        s: TS(
                          s: 18,
                          w: FontWeight.w600,
                          c: textColor,
                        ),
                      ),
                      4.h,
                      T(
                        worldType.taskDescription,
                        s: TS(
                          s: 12,
                          w: FontWeight.w400,
                          c: secondaryTextColor,
                        ),
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
                    onPressed: loading ? null : _onStartToChatTap,
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
            ..._fileInfos.m(
              (e) => Container(
                decoration: BoxDecoration(
                  color: fileItemBgColor,
                  border: Border.all(color: fileItemBorderColor, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EI.a(isDesktop ? 12 : 8),
                margin: const EI.o(t: 8),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EI.s(h: 16, v: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: T(
            text,
            s: const TS(
              w: FontWeight.w600,
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
        padding: const EI.s(h: 16, v: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: T(
        text,
        s: TS(
          w: FontWeight.w600,
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
      crossAxisAlignment: CAA.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CAA.start,
                children: [
                  T(
                    fileInfo.name,
                    s: TS(
                      w: FontWeight.w600,
                      c: textColor,
                      s: 14,
                    ),
                  ),
                  4.h,
                  T(
                    gbDisplay(fileSize),
                    s: TS(
                      c: secondaryTextColor,
                      w: FontWeight.w500,
                      s: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              Container(
                padding: const EI.s(h: 8, v: 4),
                decoration: BoxDecoration(
                  color: primaryColor.q(.1),
                  borderRadius: BorderRadius.circular(12),
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
              return Container(
                padding: const EI.s(h: 8, v: 4),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? (tag.toLowerCase() == "gpu" ? Colors.green.q(.2) : Colors.blue.q(.2))
                      : (isDark ? Colors.grey.q(.2) : Colors.grey.q(.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: T(
                  tag.toUpperCase(),
                  s: TS(
                    c: isHighlight ? (tag.toLowerCase() == "gpu" ? Colors.green : Colors.blue) : secondaryTextColor,
                    w: FontWeight.w500,
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
            borderRadius: BorderRadius.circular(4),
          ),
          8.h,
          Wrap(
            spacing: 8,
            children: [
              T(
                s.speed,
                s: TS(
                  c: secondaryTextColor,
                  w: FontWeight.w500,
                  s: 11,
                ),
              ),
              T(
                "${networkSpeed.toStringAsFixed(1)}MB/s",
                s: TS(
                  c: textColor,
                  w: FontWeight.w600,
                  s: 11,
                ),
              ),
              16.w,
              T(
                s.remaining,
                s: TS(
                  c: secondaryTextColor,
                  w: FontWeight.w500,
                  s: 11,
                ),
              ),
              T(
                timeRemaining.inMinutes > 0 ? "${timeRemaining.inMinutes}m" : "${timeRemaining.inSeconds}s",
                s: TS(
                  c: textColor,
                  w: FontWeight.w600,
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
