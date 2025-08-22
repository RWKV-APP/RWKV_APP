// ignore: unused_import
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/group_info.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:zone/widgets/model_item.dart';

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
    missingFileInfos.forEach((e) => P.fileManager.getFile(fileInfo: e));
  }

  Future<void> _onDeleteAllTap() async {
    final helperModels = P.fileManager.ttsWeights.q.where((e) => !e.tags.contains("core")).toList();
    final core = fileInfo;
    [...helperModels, core].forEach((e) => P.fileManager.deleteFile(fileInfo: e));
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

    P.rwkv.clearStates();
    P.chat.clearMessages();

    try {
      await P.rwkv.loadSparkTTS(
        modelPath: modelLocalFile.targetPath,
        backend: fileInfo.backend!,
        wav2vec2Path: localWav2vec2File.targetPath,
        detokenizePath: localDetokenizeFile.targetPath,
        bicodecTokenzerPath: localTokenizeFile.targetPath,
      );
      P.tts.getTTSSpkNames();
      Navigator.pop(getContext()!);
    } catch (e) {
      qqe("$e");
      Alert.error(e.toString());
      P.rwkv.currentGroupInfo.q = null;
      return;
    }

    P.rwkv.currentGroupInfo.q = GroupInfo(displayName: fileInfo.name);
    P.rwkv.currentModel.q = fileInfo;
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
    final primaryColor = Theme.of(context).colorScheme.primaryContainer;

    final files = fileInfos.m((e) {
      return ref.watch(P.fileManager.locals(e));
    });

    final allDownloaded = files.every((e) => e.hasFile);
    final allMissing = files.every((e) => !e.hasFile);
    final downloading = files.any((e) => e.downloading);

    final currentModel = ref.watch(P.rwkv.currentModel);
    final alreadyStarted = currentModel == fileInfo;
    final loading = ref.watch(P.rwkv.loading);
    final qw = ref.watch(P.app.qw);

    // debugger();

    return ClipRRect(
      borderRadius: 8.r,
      child: Container(
        decoration: BoxDecoration(color: qw, borderRadius: 8.r),
        margin: const EI.o(t: 8),
        padding: const EI.o(t: 8, l: 8, r: 8, b: 8),
        child: Column(
          crossAxisAlignment: CAA.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                T(fileInfo.name, s: const TS(s: 18, w: FontWeight.w600)),
                const T("TTS", s: TS(s: 12, w: FontWeight.w400)),
              ],
            ),
            Row(
              children: [
                if (downloading) 8.h,
                if (allMissing && !downloading)
                  TextButton(
                    onPressed: _onDownloadAllTap,
                    child: T(
                      s.download_all,
                      s: TS(
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!allMissing && !allDownloaded && !downloading)
                  TextButton(
                    onPressed: _onDownloadAllTap,
                    child: T(
                      s.download_missing,
                      s: const TS(
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                if (allDownloaded && !alreadyStarted)
                  TextButton(
                    onPressed: _onDeleteAllTap,
                    child: T(
                      s.delete_all,
                      s: const TS(
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                if (alreadyStarted)
                  TextButton(
                    onPressed: null,
                    child: T(
                      s.exploring,
                      s: const TS(
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                if (allDownloaded && !alreadyStarted)
                  TextButton(
                    onPressed: loading ? null : _onSparkTap,
                    child: T(
                      loading ? s.loading : s.start_to_chat,
                      s: const TS(
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                if (alreadyStarted)
                  TextButton(
                    onPressed: loading ? null : _onContinueTap,
                    child: T(
                      loading ? s.loading : s.back_to_chat,
                      s: const TS(
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            ...fileInfos.m(
              (e) => Container(
                decoration: BoxDecoration(
                  color: kC,
                  border: Border.all(color: primaryColor),
                  borderRadius: 6.r,
                ),
                padding: const EI.s(v: 4, h: 4),
                margin: const EI.o(t: 8),
                child: FileKeyItem(e, showDownloaded: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
