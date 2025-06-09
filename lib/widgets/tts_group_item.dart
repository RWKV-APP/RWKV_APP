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
import 'package:zone/route/method.dart';
import 'package:zone/route/router.dart';
import 'package:zone/state/p.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:zone/widgets/model_item.dart';

class TTSGroupItem extends ConsumerWidget {
  final FileInfo fileInfo;

  TTSGroupItem(
    this.fileInfo, {
    super.key,
  }) : assert(fileInfo.tags.contains("core"), "fileInfo must be a core model");

  void _onDownloadAllTap() async {
    final helperModels = P.fileManager.availableModels.q.where((e) => !e.tags.contains("core")).toList();
    final core = fileInfo;
    final missingFileInfos = [...helperModels, core].where((e) => P.fileManager.locals(e).q.hasFile == false).toList();
    missingFileInfos.forEach((e) => P.fileManager.getFile(fileInfo: e));
  }

  void _onDeleteAllTap() async {
    final helperModels = P.fileManager.availableModels.q.where((e) => !e.tags.contains("core")).toList();
    final core = fileInfo;
    [...helperModels, core].forEach((e) => P.fileManager.deleteFile(fileInfo: e));
  }

  void _onStartToChatTap() async {
    if (P.rwkv.loading.q) {
      Alert.warning("Please wait for the model to load...");
      return;
    }
    final availableModels = P.fileManager.availableModels.q;
    final fileInfos = availableModels.toList();

    final campPlusFileKey = fileInfos.firstWhereOrNull((e) => e.tags.contains("campplus"));
    final flowEncoderFileKey = fileInfos.firstWhereOrNull((e) => e.tags.contains("flow.encoder"));
    final flowDecoderEstimatorFileKey = fileInfos.firstWhereOrNull((e) => e.tags.contains("flow.decoder.estimator"));
    final hiftGeneratorFileKey = fileInfos.firstWhereOrNull((e) => e.tags.contains("hift"));
    final speechTokenizerFileKey = fileInfos.firstWhereOrNull((e) => e.tags.contains("speech.tokenizer"));

    if (campPlusFileKey == null) {
      Alert.error("Campplus file not found");
      qqe;
      return;
    }

    if (flowEncoderFileKey == null) {
      Alert.error("Flow encoder file not found");
      qqe;
      return;
    }

    if (flowDecoderEstimatorFileKey == null) {
      Alert.error("Flow decoder estimator file not found");
      qqe;
      return;
    }

    if (hiftGeneratorFileKey == null) {
      Alert.error("Hift generator file not found");
      qqe;
      return;
    }

    if (speechTokenizerFileKey == null) {
      Alert.error("TTS tokenizer file not found");
      qqe;
      return;
    }

    final modelLocalFile = P.fileManager.locals(fileInfo).q;
    final localCampPlusFile = P.fileManager.locals(campPlusFileKey).q;
    final localFlowEncoderFile = P.fileManager.locals(flowEncoderFileKey).q;
    final localFlowDecoderEstimatorFile = P.fileManager.locals(flowDecoderEstimatorFileKey).q;
    final localHiftGeneratorFile = P.fileManager.locals(hiftGeneratorFileKey).q;
    final localSpeechTokenizerFile = P.fileManager.locals(speechTokenizerFileKey).q;
    P.rwkv.currentGroupInfo.q = GroupInfo(displayName: fileInfo.name);

    P.rwkv.clearStates();
    P.chat.clearMessages();

    try {
      await P.rwkv.loadTTSModels(
        modelPath: modelLocalFile.targetPath,
        backend: fileInfo.backend!,
        enableReasoning: false,
        campPlusPath: localCampPlusFile.targetPath,
        flowEncoderPath: localFlowEncoderFile.targetPath,
        flowDecoderEstimatorPath: localFlowDecoderEstimatorFile.targetPath,
        hiftGeneratorPath: localHiftGeneratorFile.targetPath,
        speechTokenizerPath: localSpeechTokenizerFile.targetPath,
      );
      P.tts.setTTSCFMSteps(P.tts.cfmSteps.q);
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
    pop();
  }

  void _onContinueTap() async {
    qq;
    pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final availableModels = P.fileManager.availableModels.q;
    final fileInfos = availableModels.toList().where((e) => !e.tags.contains("core")).toList();
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

    return ClipRRect(
      borderRadius: 8.r,
      child: C(
        decoration: BD(color: qw, borderRadius: 8.r),
        margin: const EI.o(t: 8),
        padding: const EI.o(t: 8, l: 8, r: 8, b: 8),
        child: Column(
          crossAxisAlignment: CAA.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                T(fileInfo.name, s: const TS(s: 18, w: FW.w600)),
                const T("TTS", s: TS(s: 12, w: FW.w400)),
              ],
            ),
            Row(
              children: [
                if (downloading) 8.h,
                if (allMissing && !downloading)
                  TextButton(
                    onPressed: _onDownloadAllTap,
                    child: const T(
                      "Download All",
                      s: TS(
                        w: FW.w600,
                      ),
                    ),
                  ),
                if (!allMissing && !allDownloaded && !downloading)
                  TextButton(
                    onPressed: _onDownloadAllTap,
                    child: T(
                      s.download_missing,
                      s: const TS(
                        w: FW.w600,
                      ),
                    ),
                  ),
                if (allDownloaded && !alreadyStarted)
                  TextButton(
                    onPressed: _onDeleteAllTap,
                    child: T(
                      s.delete_all,
                      s: const TS(
                        w: FW.w600,
                      ),
                    ),
                  ),
                if (alreadyStarted)
                  TextButton(
                    onPressed: null,
                    child: T(
                      s.exploring,
                      s: const TS(
                        w: FW.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                if (allDownloaded && !alreadyStarted)
                  TextButton(
                    onPressed: loading ? null : _onStartToChatTap,
                    child: T(
                      loading ? s.loading : s.start_to_chat,
                      s: const TS(
                        w: FW.w600,
                      ),
                    ),
                  ),
                if (alreadyStarted)
                  TextButton(
                    onPressed: loading ? null : _onContinueTap,
                    child: T(
                      loading ? s.loading : s.back_to_chat,
                      s: const TS(
                        w: FW.w600,
                      ),
                    ),
                  ),
              ],
            ),
            ...fileInfos.m(
              (e) => C(
                decoration: BD(
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
