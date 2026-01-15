// ignore: unused_import
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
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

    return ClipRRect(
      borderRadius: 16.r,
      child: Container(
        margin: const .only(top: 12),
        child: ListView(
          padding: .only(left: isDesktop ? 12 : 8, right: isDesktop ? 12 : 8),
          controller: scrollController,
          children: [
            const _Header(),
            const _Hints(),
            _ModelList(showNeko: showNeko, rolePlayOnly: rolePlayOnly),
            16.h,
            paddingBottom.h,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: T(s.chat_please_select_a_model, s: const TS(s: 18, w: .w600)),
        ),
        const IconButton(
          onPressed: pop,
          icon: Icon(Icons.close),
        ),
      ],
    );
  }
}

class _Hints extends ConsumerWidget {
  const _Hints();

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
          T(
            "👉${s.str_model_selection_dialog_hint}👈",
            s: TS(c: qb.q(.7), s: 12, w: .w500),
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
                  child: T(
                    hasValidSoc ? s.npu_not_supported_title(currentSocName) : s.npu_not_supported_title("Unknown"),
                    s: TS(c: qb.q(.9), s: 14, w: .w600),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              8.h,
              if (hasValidSoc) ...[
                Row(
                  children: [
                    T(
                      "您的设备：",
                      s: TS(c: qb.q(.7), s: 12),
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
                          T(
                            currentSocName,
                            s: TS(
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
              T(
                "我们目前支持以下SoC芯片中的NPU：",
                s: TS(c: qb.q(.7), s: 12),
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
                        T(
                          chip,
                          s: TS(
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
              T(
                s.adapting_more_inference_chips,
                s: TS(c: qb.q(.7), s: 12),
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
        T(
          S.current.download_server_,
          s: TS(c: qb.q(.7), s: 12, w: .w600),
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
                    padding: const .symmetric(horizontal: 6, vertical: 2),
                    child: T(
                      downloadSourceName,
                      s: TS(c: e == currentSource ? qw : qb.q(.7), s: 14),
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
