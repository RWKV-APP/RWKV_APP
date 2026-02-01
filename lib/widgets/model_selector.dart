// ignore: unused_import
import 'dart:developer';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_download_source.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:zone/func/gb_display.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/widgets/model_item.dart';
import 'package:zone/widgets/role_play_item.dart';
import 'package:zone/widgets/tts_group_item.dart';
import 'package:zone/widgets/world_group_item.dart';

class ModelSelector extends ConsumerWidget {
  final bool rolePlayOnly;
  final bool showNeko;
  final ScrollController scrollController;
  static DemoType? _preferredDemoType;

  static Future<void> show({
    bool rolePlayOnly = false,
    bool showNeko = false,
    DemoType? preferredDemoType,
  }) async {
    if (showNeko) preferredDemoType = .chat;

    if (P.fileManager.modelSelectorShown.q) return;
    P.fileManager.modelSelectorShown.q = true;

    final context = getContext();
    if (context == null) {
      P.fileManager.modelSelectorShown.q = false;
      return;
    }

    // Fire and forget model updates
    (() async {
      P.fileManager.checkLocal();
      await P.app.syncConfig();
      await P.fileManager.syncAvailableModels();
      P.fileManager.checkLocal();
    })();

    if (P.app.pageKey.q == .talk) {
      _preferredDemoType = .tts;
    }

    if (preferredDemoType != null) {
      _preferredDemoType = preferredDemoType;
    }

    if (rolePlayOnly && P.app.pageKey.q != .rolePlaying) {
      return;
    }

    final usingPth = P.rwkv.usingPth.q;
    if (usingPth == true) P.fileManager.localPthFileOption.q = LocalPthFileOption.localPthFiles;
    if (usingPth != true) P.fileManager.localPthFileOption.q = LocalPthFileOption.filesInConfig;

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .8,
        maxChildSize: .9,
        expand: false,
        snap: false,
        builder: (context, scrollController) => ModelSelector(
          scrollController: scrollController,
          showNeko: showNeko,
          rolePlayOnly: rolePlayOnly,
        ),
      ),
    );

    _preferredDemoType = null;

    P.fileManager.modelSelectorShown.q = false;
  }

  const ModelSelector({super.key, required this.scrollController, required this.showNeko, required this.rolePlayOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final isDesktop = ref.watch(P.app.isDesktop);
    final localPthFileOption = ref.watch(P.fileManager.localPthFileOption);
    final pageKey = ref.watch(P.app.pageKey);

    return ClipRRect(
      borderRadius: 16.r,
      child: Container(
        margin: const .only(top: 12),
        child: ListView(
          padding: .only(left: isDesktop ? 12 : 8, right: isDesktop ? 12 : 8),
          controller: scrollController,
          children: [
            const _Title(),
            if (isDesktop && pageKey == .chat) const _LocalSwitcher(),
            if (localPthFileOption == LocalPthFileOption.filesInConfig) const _Options(),
            if (localPthFileOption == LocalPthFileOption.filesInConfig) _ModelList(showNeko: showNeko, rolePlayOnly: rolePlayOnly),
            if (localPthFileOption == LocalPthFileOption.localPthFiles) const _LocalOptions(),
            16.h,
            paddingBottom.h,
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(s.chat_please_select_a_model, style: const TS(s: 18, w: .w600)),
        ),
        const IconButton(
          onPressed: pop,
          icon: Icon(Icons.close),
        ),
      ],
    );
  }
}

class _Options extends ConsumerWidget {
  const _Options();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final demoType = ModelSelector._preferredDemoType ?? ref.watch(P.app.demoType);
    final qb = ref.watch(P.app.qb);

    return Column(
      crossAxisAlignment: .start,
      children: [
        const _DownloadSource(),
        if (demoType == .chat)
          Text(
            "👉${s.str_model_selection_dialog_hint}👈",
            style: TS(c: qb.q(.7), s: 12, w: .w500),
          ),
      ],
    );
  }
}

class _ModelList extends ConsumerWidget {
  final bool showNeko;
  final bool rolePlayOnly;

  const _ModelList({required this.showNeko, required this.rolePlayOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoType = ref.watch(P.app.demoType);
    final preferredDemoType = ModelSelector._preferredDemoType ?? demoType;

    Set<FileInfo> availableModels = switch (preferredDemoType) {
      .see => ref.watch(P.fileManager.seeWeights),
      .tts => ref.watch(P.fileManager.ttsWeights),
      .chat => ref.watch(P.fileManager.chatWeights),
      .sudoku => ref.watch(P.fileManager.sudokuWeights),
      .othello => ref.watch(P.fileManager.othelloWeights),
      .fifthteenPuzzle => ref.watch(P.fileManager.sudokuWeights),
    };

    final ttsCores = ref.watch(P.fileManager.ttsCores);
    final userType = ref.watch(P.preference.userType);
    final pageKey = ref.watch(P.app.pageKey);

    if (rolePlayOnly && pageKey == .rolePlaying) {
      availableModels = availableModels.where((e) => e.state.isNotEmpty).toSet();
      availableModels.addAll(P.fileManager.roleplayWeights.q);
      return Column(
        crossAxisAlignment: .stretch,
        children: availableModels.map((e) => RolePlayItem(file: e)).toList(),
      );
    }

    final inTranslator = pageKey == .translator || pageKey == .ocr;
    final inBenchmark = pageKey == .benchmark;

    if (inTranslator) {
      availableModels = availableModels.where((e) => e.tags.contains("translate")).toSet();
    } else {
      availableModels = availableModels.where((e) => !e.tags.contains("translate")).toSet();
    }

    if (inBenchmark) {
      availableModels = availableModels.whereNot((e) => e.tags.contains('DeepEmbedding')).toSet();
    }

    // 检查是否需要显示NPU不支持提示（仅Android设备）
    final hasNpuModel = availableModels.any((e) => e.tags.contains("npu") && e.socSupported && e.platformSupported && showNeko == e.isNeko);

    final shouldShowNpuHint =
        Platform.isAndroid && !inTranslator && !inBenchmark && !rolePlayOnly && !hasNpuModel && availableModels.isNotEmpty;

    List<Widget> items = switch (preferredDemoType) {
      .see =>
        WorldType.values
            .where((e) => e.available)
            .expand(
              (e) => e.socPairs
                  .where((pair) => pair.$1.isEmpty || pair.$1 == P.rwkv.socName.q)
                  .sortedBy<num>((pair) => -pair.$1.length)
                  .map((pair) => WorldGroupItem(e, socPair: pair)),
            )
            .toList(),
      .tts => ttsCores.sorted(_compare).map((fileInfo) => TTSGroupItem(fileInfo)).toList(),
      .chat || .sudoku =>
        availableModels
            .where((e) => showNeko == e.isNeko)
            .sorted(_compare)
            .map(
              (fileInfo) => ModelItem(
                fileInfo,
                userType.isGreaterThan(.user),
                loadButtonTextShowLoad: pageKey == .benchmark,
              ),
            )
            .toList(),
      .fifthteenPuzzle || .othello => [],
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (shouldShowNpuHint) const _NpuNotSupportedHint(),
        ...items,
      ],
    );
  }

  /// 根据专有加速进行排序
  ///
  /// 只要没用 CPU 就排前面
  int _compare(FileInfo a, FileInfo b) {
    final aHasMLX = a.tags.contains("mlx");
    final bHasMLX = b.tags.contains("mlx");
    if (aHasMLX != bHasMLX) return aHasMLX ? -1 : 1;

    final aHasNpu = a.tags.contains("npu");
    final bHasNpu = b.tags.contains("npu");
    if (aHasNpu != bHasNpu) return aHasNpu ? -1 : 1;

    final aHasGpu = a.tags.contains("gpu");
    final bHasGpu = b.tags.contains("gpu");
    if (aHasGpu != bHasGpu) return aHasGpu ? -1 : 1;

    final aHasWebRWKV = a.tags.contains("webRwkv");
    final bHasWebRWKV = b.tags.contains("webRwkv");
    if (aHasWebRWKV != bHasWebRWKV) return aHasWebRWKV ? -1 : 1;

    return (b.modelSize ?? 0).compareTo(a.modelSize ?? 0);
  }
}

class _NpuNotSupportedHint extends ConsumerStatefulWidget {
  const _NpuNotSupportedHint();

  @override
  ConsumerState<_NpuNotSupportedHint> createState() => _NpuNotSupportedHintState();
}

class _NpuNotSupportedHintState extends ConsumerState<_NpuNotSupportedHint> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final supportedNpus = P.fileManager.getSupportedNpuChips();
    final currentSocName = ref.watch(P.rwkv.socName);
    final frontendSocName = ref.watch(P.rwkv.frontendSocName);

    if (supportedNpus.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasValidSoc = currentSocName.isNotEmpty && currentSocName != "Unknown";

    return GD(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: Container(
        margin: const .only(top: 8, bottom: 8),
        padding: const .all(8),
        decoration: BoxDecoration(
          color: qb.q(.1),
          borderRadius: 8.r,
          border: Border.all(color: qb.q(.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: qb.q(.8)),
                4.w,
                Expanded(
                  child: Text(
                    hasValidSoc ? s.npu_not_supported_title(currentSocName) : s.npu_not_supported_title(frontendSocName ?? "Unknown"),
                    style: TS(c: qb.q(.9), s: 14, w: .w600),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              8.h,
              if (hasValidSoc) ...[
                Row(
                  children: [
                    Text(
                      "您的设备：",
                      style: TS(c: qb.q(.7), s: 12),
                    ),
                    6.w,
                    Container(
                      padding: const .symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: qb.q(.2),
                        borderRadius: 6.r,
                        border: Border.all(
                          color: qb.q(.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 14,
                            color: qb.q(.8),
                          ),
                          4.w,
                          Text(
                            currentSocName,
                            style: TS(
                              c: qb.q(.9),
                              s: 11,
                              w: .w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                8.h,
              ],
              Text(
                "我们目前支持以下SoC芯片中的NPU：",
                style: TS(c: qb.q(.7), s: 12),
              ),
              8.h,
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: supportedNpus.map((chip) {
                  return Container(
                    padding: const .symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.q(.2),
                      borderRadius: 4.r,
                      border: Border.all(
                        color: primary.q(.9),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        Padding(
                          padding: const .only(right: 4),
                          child: Icon(
                            Icons.memory,
                            size: 14,
                            color: primary,
                          ),
                        ),
                        Text(
                          chip,
                          style: TS(
                            c: primary,
                            s: 11,
                            w: .w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              8.h,
              Text(
                s.adapting_more_inference_chips,
                style: TS(c: qb.q(.7), s: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadSource extends ConsumerWidget {
  const _DownloadSource();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(P.fileManager.downloadSource);
    final primary = Theme.of(context).colorScheme.primary;
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final currentLangIsZh = ref.watch(P.preference.currentLangIsZh);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        4.h,
        Text(
          S.current.download_server_,
          style: TS(c: qb.q(.7), s: 12, w: .w600),
        ),
        4.h,
        Wrap(
          runSpacing: 4,
          spacing: 4,
          children: FileDownloadSource.values
              .where((e) {
                return (kDebugMode || !e.isDebug) && !e.hidden;
              })
              .map((e) {
                String downloadSourceName = e.name;
                if (currentLangIsZh) {
                  downloadSourceName += (e == FileDownloadSource.huggingface ? S.current.overseas : "");
                }
                return GestureDetector(
                  onTap: () {
                    P.fileManager.downloadSource.q = e;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: e == currentSource ? primary : Colors.transparent,
                      borderRadius: 4.r,
                      border: Border.all(
                        color: primary,
                      ),
                    ),
                    constraints: const BoxConstraints(minHeight: 30),
                    padding: const .symmetric(horizontal: 6, vertical: 2),
                    child: IntrinsicWidth(
                      child: Center(
                        child: Text(
                          downloadSourceName,
                          style: TS(c: e == currentSource ? qw : qb.q(.7), s: 14),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
        8.h,
      ],
    );
  }
}

enum LocalPthFileOption {
  filesInConfig,
  localPthFiles
  ;

  String displayName(S s) => switch (this) {
    filesInConfig => s.local_pth_option_files_in_config,
    localPthFiles => s.local_pth_option_local_pth_files,
  };
}

class _LocalSwitcher extends ConsumerWidget {
  const _LocalSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final localPthFileOption = ref.watch(P.fileManager.localPthFileOption);
    final primary = Theme.of(context).colorScheme.primary;
    final options = LocalPthFileOption.values;
    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);
    final usingPth = ref.watch(P.rwkv.usingPth);

    return Column(
      crossAxisAlignment: .start,
      children: [
        T(
          s.select_weights_or_local_pth_hint,
          s: TS(c: qb.q(.7), s: 12, w: .w500),
        ),
        4.h,
        Wrap(
          runSpacing: 4,
          spacing: 4,
          children: options.map((e) {
            final isSelected = e == localPthFileOption;

            final inUse = switch (usingPth) {
              true => e == LocalPthFileOption.localPthFiles,
              false => e == LocalPthFileOption.filesInConfig,
              null => false,
            };

            late final Color textColor;
            late final Color iconColor;

            if (isSelected) {
              textColor = qw;
            } else {
              textColor = qb.q(.7);
            }

            iconColor = textColor;

            return GD(
              onTap: () {
                P.fileManager.localPthFileOption.q = e;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: e == localPthFileOption ? primary : Colors.transparent,
                  borderRadius: 4.r,
                  border: Border.all(
                    color: primary,
                  ),
                ),
                padding: const .all(4),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text(
                      e.displayName(s),
                      style: TS(c: textColor, s: 12, w: .w500),
                    ),
                    if (inUse) ...[
                      4.w,
                      Icon(
                        Icons.check,
                        color: iconColor,
                        size: 28,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        4.h,
      ],
    );
  }
}

String _truncatePath(String pathStr, [int maxLen = 56]) {
  if (pathStr.length <= maxLen) return pathStr;
  const head = 26;
  final tail = maxLen - head - 3;
  return '${pathStr.substring(0, head)}...${pathStr.substring(pathStr.length - tail)}';
}

Future<void> _openContainingFolder(String filePath) async {
  try {
    final dirPath = path.dirname(filePath);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await launchUrl(Uri.directory(dirPath));
    }
  } catch (e) {
    Alert.error(e.toString());
  }
}

String? _ctxFromFileName(FileInfo fileInfo) {
  final m = RegExp(r'ctx(\d+)', caseSensitive: false).firstMatch(fileInfo.name);
  if (m != null) return m.group(1);
  return null;
}

class _LocalPthFileItem extends ConsumerWidget {
  final FileInfo fileInfo;

  const _LocalPthFileItem(this.fileInfo);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final currentModel = ref.watch(P.rwkv.latestModel);
    final isCurrent = currentModel == fileInfo;
    final customTheme = ref.watch(P.app.customTheme);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final date = fileInfo.dateDisplayString;
    final ctxLength = _ctxFromFileName(fileInfo);

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
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        fileInfo.name,
                        style: const TS(w: .w600),
                      ),
                      Text(
                        gbDisplay(fileInfo.fileSize),
                        style: TS(c: qb.q(.7), w: .w500),
                      ),
                      if (isCurrent) ...[
                        4.w,
                        Icon(Icons.check, size: 16, color: qb.q(.8)),
                        4.w,
                        Text(s.loaded, style: TS(c: qb.q(.8), s: 12)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openContainingFolder(fileInfo.raw),
                  icon: const Icon(Icons.folder_open),
                  tooltip: s.open_containing_folder,
                  style: ButtonStyle(
                    minimumSize: .all(const Size(32, 32)),
                    padding: .all(.zero),
                  ),
                ),
              ],
            ),
            4.h,
            Text(
              _truncatePath(fileInfo.raw),
              style: TS(c: qb.q(.6), s: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (date != null || ctxLength != null) ...[
              4.h,
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (date != null)
                    Container(
                      padding: const .symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: qb.q(.15),
                        borderRadius: 4.r,
                      ),
                      child: Text(date, style: TS(c: qb.q(.8), s: 11)),
                    ),
                  if (ctxLength != null)
                    Container(
                      padding: const .symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: qb.q(.15),
                        borderRadius: 4.r,
                      ),
                      child: Text(s.ctx_length_label(ctxLength), style: TS(c: qb.q(.8), s: 11)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocalOptions extends ConsumerWidget {
  const _LocalOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final loadedModels = ref.watch(P.rwkv.loadedModels);
    final loadingStatus = ref.watch(P.rwkv.loadingStatus);
    final fileInfos = loadedModels.keys.where((e) => e.fromPthFile).toList();
    final usingPth = ref.watch(P.rwkv.usingPth);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);

    final localPthLoading = loadingStatus.entries.any((e) {
      if (!e.key.fromPthFile) return false;
      final status = e.value;
      return status == LoadingStatus.loading || status == LoadingStatus.loadModelWithExtra || status == LoadingStatus.setQnnLibraryPath;
    });

    return Column(
      crossAxisAlignment: .start,
      children: [
        T(
          s.local_pth_files_section_title,
          s: TS(c: qb.q(.7), s: 12, w: .w500),
        ),
        4.h,
        if (usingPth != true && loadedModels.isNotEmpty) ...[
          Container(
            padding: const .all(8),
            decoration: BoxDecoration(
              color: qb.q(.1),
              borderRadius: 8.r,
              border: Border.all(color: qb.q(.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: qb.q(.8)),
                6.w,
                Expanded(
                  child: Text(
                    s.current_model_from_latest_json_not_pth,
                    style: TS(c: qb.q(.9), s: 12),
                  ),
                ),
              ],
            ),
          ),
          8.h,
        ],
        Row(
          children: [
            T(
              s.local_pth_you_can_select,
              s: TS(c: qb.q(.7), s: 12),
            ),
            4.w,
            IconButton(
              onPressed: () async {
                await showOkAlertDialog(
                  context: context,
                  title: s.what_is_pth_file_title,
                  message: s.what_is_pth_file_message,
                );
              },
              icon: const Icon(Icons.info_outline),
              iconSize: 14,
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(const Size(16, 16)),
                padding: WidgetStateProperty.all(.zero),
              ),
            ),
          ],
        ),
        4.h,
        if (localPthLoading) ...[
          Container(
            padding: const .all(12),
            decoration: BoxDecoration(
              color: qb.q(.1),
              borderRadius: 8.r,
              border: Border.all(color: qb.q(.2), width: 1),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: qb.q(.8),
                  ),
                ),
                12.w,
                Text(
                  s.model_loading,
                  style: TS(c: qb.q(.8), s: 12),
                ),
              ],
            ),
          ),
          8.h,
        ],
        if (!localPthLoading && fileInfos.isNotEmpty) ...[
          for (var i = 0; i < fileInfos.length; i++) ...[
            if (i > 0) 8.h,
            _LocalPthFileItem(fileInfos[i]),
          ],
          8.h,
        ],
        if (!localPthLoading && fileInfos.isEmpty) ...[
          Text(
            s.no_local_pth_loaded_yet,
            style: TS(c: qb.q(.6), s: 12),
          ),
          4.h,
        ],
        FilledButton(
          onPressed: () async {
            final fileInfo = await P.fileManager.pickLocalPthFile();
            if (fileInfo == null) return;
            Alert.success(S.current.you_can_now_start_to_chat_with_rwkv);
            await Future.delayed(1000.ms);
            pop();
          },
          child: Text(
            s.select_local_pth_file_button,
            style: TS(c: qw, s: 12, w: .w500),
          ),
        ),
      ],
    );
  }
}
