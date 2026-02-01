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
import 'package:zone/model/folder.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:zone/func/gb_display.dart';
import 'package:zone/widgets/model_item.dart';
import 'package:zone/widgets/model_tag.dart';
import 'package:zone/widgets/role_play_item.dart';
import 'package:zone/widgets/tts_group_item.dart';
import 'package:zone/widgets/world_group_item.dart';

/// 模型选择器
///
/// 初始化方法为私有, 目前通过 `show` 方法来显示模型选择器
class ModelSelector extends ConsumerWidget {
  static const String panelKey = 'ModelSelector';
  static DemoType? _preferredDemoType;

  final bool _rolePlayOnly;
  final bool _showNeko;
  final ScrollController _scrollController;

  static double get _listPadding => P.app.isMobile.q ? 8 : 12;

  static Future<void> show({
    bool rolePlayOnly = false,
    bool showNeko = false,
    DemoType? preferredDemoType,
  }) async {
    final beforeShow = () async {
      if (showNeko) preferredDemoType = .chat;

      if (P.remote.modelSelectorShown.q) return;
      P.remote.modelSelectorShown.q = true;

      final context = getContext();
      if (context == null) {
        P.remote.modelSelectorShown.q = false;
        return;
      }

      // Fire and forget model updates
      (() async {
        P.remote.checkLocal();
        await P.app.syncConfig();
        await P.remote.syncAvailableModels();
        P.remote.checkLocal();
      })();

      if (P.app.pageKey.q == .talk) _preferredDemoType = .tts;

      if (preferredDemoType != null) _preferredDemoType = preferredDemoType;

      if (rolePlayOnly && P.app.pageKey.q != .rolePlaying) {
        return;
      }
    };

    await P.ui.showPanel(
      key: panelKey,
      beforeShow: beforeShow,
      builder: (scrollController) => ModelSelector._(
        scrollController: scrollController,
        showNeko: showNeko,
        rolePlayOnly: rolePlayOnly,
      ),
      afterHide: (res) {
        _preferredDemoType = null;
        P.remote.modelSelectorShown.q = false;
      },
    );
  }

  const ModelSelector._({
    required ScrollController scrollController,
    required bool showNeko,
    required bool rolePlayOnly,
  }) : _showNeko = showNeko,
       _rolePlayOnly = rolePlayOnly,
       _scrollController = scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final isMobile = ref.watch(P.app.isMobile);
    final folders = ref.watch(P.pth.folders);
    final canUsePth = ref.watch(P.app.pageKey) == .chat || ref.watch(P.app.pageKey) == .completion;

    final items = [
      const _SelectionHint(),
      if (!isMobile && canUsePth)
        ...[
          const _LocalPthFolderHeader(),
          if (folders.isEmpty) const _LocalPthEmpty(),
          if (folders.isNotEmpty) ...folders.map((e) => _LocalPthFolder(e)),
        ].widgetJoin((index) => 8.h),
      if (!isMobile && canUsePth) ...[
        4.h,
        const _ModelsInConfigHeader(),
      ],
      ...[
        const _ModelsInConfigDownloadSource(),
        _ModelsInConfigFile(showNeko: _showNeko, rolePlayOnly: _rolePlayOnly),
      ],
      (16 + paddingBottom).h,
    ];

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        children: [
          _PanelBar(scrollController: _scrollController),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: .only(
                left: _listPadding,
                right: _listPadding,
                bottom: _listPadding,
              ),
              controller: _scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return items[index];
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelBar extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _PanelBar({required this.scrollController});

  @override
  ConsumerState<_PanelBar> createState() => _PanelBarState();
}

class _PanelBarState extends ConsumerState<_PanelBar> {
  double _opacity = 0.0;

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final position = widget.scrollController.position;
    double opacity = position.pixels / 100.0;
    if (opacity < 0) opacity = 0;
    if (opacity > 1) opacity = 1;
    if (opacity != _opacity) {
      _opacity = opacity;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final qb = ref.watch(P.app.qb);
    final s = S.of(context);
    final customTheme = ref.watch(P.app.customTheme);

    return Container(
      constraints: BoxConstraints(
        minHeight: kToolbarHeight - 4,
      ),
      padding: .only(top: 4),
      decoration: BoxDecoration(
        color: customTheme.settingItem.q(_opacity * _opacity),
        border: Border(
          bottom: BorderSide(color: qb.q(.2 * _opacity * _opacity), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          (ModelSelector._listPadding + (8 * _opacity)).w,
          Expanded(
            child: Text(
              s.chat_please_select_a_model,
              style: const TS(s: 18, w: .w600),
            ),
          ),
          const IconButton(
            onPressed: pop,
            icon: Icon(Icons.close),
          ),
          4.w,
        ],
      ),
    );
  }
}

class _SelectionHint extends ConsumerWidget {
  const _SelectionHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final demoType = ModelSelector._preferredDemoType ?? ref.watch(P.app.demoType);
    final qb = ref.watch(P.app.qb);
    if (demoType != .chat) {
      return const SizedBox.shrink();
    }
    return Text(
      "👉${s.str_model_selection_dialog_hint}👈",
      style: TS(c: qb.q(.7), s: 12, w: .w500),
    );
  }
}

class _ModelsInConfigFile extends ConsumerWidget {
  final bool showNeko;
  final bool rolePlayOnly;

  const _ModelsInConfigFile({required this.showNeko, required this.rolePlayOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoType = ref.watch(P.app.demoType);
    final preferredDemoType = ModelSelector._preferredDemoType ?? demoType;

    Set<FileInfo> availableModels = switch (preferredDemoType) {
      .see => ref.watch(P.remote.seeWeights),
      .tts => ref.watch(P.remote.ttsWeights),
      .chat => ref.watch(P.remote.chatWeights),
      .sudoku => ref.watch(P.remote.sudokuWeights),
      .othello => ref.watch(P.remote.othelloWeights),
      .fifthteenPuzzle => ref.watch(P.remote.sudokuWeights),
    };

    final ttsCores = ref.watch(P.remote.ttsCores);
    final userType = ref.watch(P.preference.userType);
    final pageKey = ref.watch(P.app.pageKey);

    if (rolePlayOnly && pageKey == .rolePlaying) {
      availableModels = availableModels.where((e) => e.state.isNotEmpty).toSet();
      availableModels.addAll(P.remote.roleplayWeights.q);
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
    final supportedNpus = P.remote.getSupportedNpuChips;
    final currentSocName = ref.watch(P.rwkv.socName);
    final frontendSocName = ref.watch(P.rwkv.frontendSocName);

    if (supportedNpus.isEmpty) return const SizedBox.shrink();

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
                      S.current.your_device,
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
                S.current.we_support_npu_socs,
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

class _ModelsInConfigDownloadSource extends ConsumerWidget {
  const _ModelsInConfigDownloadSource();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(P.remote.downloadSource);
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
                    P.remote.downloadSource.q = e;
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

class _LocalPthFileItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final VoidCallback? onStartToChat;

  const _LocalPthFileItem(this.fileInfo, {this.onStartToChat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final currentModel = ref.watch(P.rwkv.latestModel);
    final isCurrent = currentModel == fileInfo;
    final loadingStatus = ref.watch(P.rwkv.loadingStatus);
    final loading =
        loadingStatus[fileInfo] == LoadingStatus.loading ||
        loadingStatus[fileInfo] == LoadingStatus.loadModelWithExtra ||
        loadingStatus[fileInfo] == LoadingStatus.setQnnLibraryPath;
    final customTheme = ref.watch(P.app.customTheme);
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final date = fileInfo.dateDisplayString;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisAlignment: .center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: [
                  Text(fileInfo.name, style: const TS(w: .w600)),
                  Text(
                    gbDisplay(fileInfo.fileSize),
                    style: TS(c: qb.q(.7), w: .w500),
                  ),
                ],
              ),
              4.h,
              Wrap(
                spacing: 4,
                runSpacing: 8,
                children: [
                  if (date != null) ModelTag(tag: date),
                  if (fileInfo.ctxLength != null) ModelTag(tag: s.ctx_length_label(fileInfo.ctxLength ?? "")),
                ],
              ),
            ],
          ),
        ),
        8.w,
        if (onStartToChat != null && !isCurrent)
          GestureDetector(
            onTap: loading ? null : () => onStartToChat!(),
            child: Container(
              decoration: BoxDecoration(
                color: (loading) ? kCG.q(.5) : kCG,
                borderRadius: 8.r,
              ),
              padding: const .all(8),
              child: Text(loading ? s.loading : s.start_to_chat, style: TS(c: qw)),
            ),
          ),
        if (isCurrent)
          GestureDetector(
            onTap: null,
            child: Container(
              decoration: BoxDecoration(color: kG.q(.5), borderRadius: 8.r),
              padding: const .all(8),
              child: Text(s.chatting, style: TS(c: qw)),
            ),
          ),
      ],
    );
  }
}

class _ModelsInConfigHeader extends ConsumerWidget {
  const _ModelsInConfigHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return T(S.current.prebuilt_models_intro);
  }
}

class _LocalPthFolderHeader extends ConsumerWidget {
  const _LocalPthFolderHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(P.pth.folders);
    return Row(
      children: [
        Expanded(child: T(S.current.below_are_your_local_folders)),
        if (folders.isNotEmpty) T(S.current.click_plus_to_add_more_folders),
        if (folders.isNotEmpty)
          IconButton(onPressed: P.pth.onAddFolderClicked, icon: const Icon(Icons.add), tooltip: S.current.add_local_folder),
      ],
    );
  }
}

class _LocalPthEmpty extends ConsumerWidget {
  const _LocalPthEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);

    return Container(
      decoration: BD(
        color: kC,
        borderRadius: 8.r,
        border: Border.all(color: qb.q(.5), width: 1),
      ),
      padding: const .all(12),
      child: Column(
        crossAxisAlignment: .center,
        children: [
          Row(
            children: [
              Expanded(
                child: T(
                  S.current.no_local_folders,
                  textAlign: .center,
                ),
              ),
            ],
          ),
          4.h,
          IconButton(onPressed: () => P.pth.onAddFolderClicked(), icon: const Icon(Icons.add), tooltip: S.current.add_local_folder),
          4.h,
          Row(
            children: [
              Expanded(
                child: T(
                  S.current.click_plus_add_local_folder,
                  textAlign: .center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocalPthFolder extends ConsumerWidget {
  final Folder folder;

  const _LocalPthFolder(this.folder);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    final customTheme = ref.watch(P.app.customTheme);
    final folderName = path.basename(folder.path);
    final state = folder.state;
    final folderPath = folder.path;
    final folderPathDisplay = _truncatePath(folderPath);
    final files = folder.files;
    return C(
      decoration: BD(
        color: customTheme.settingItem,
        borderRadius: 8.r,
      ),
      padding: const .all(8),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    T(
                      S.current.local_folder_name(folderName),
                      s: TS(c: qb.q(.8), w: .w500),
                    ),
                    2.h,
                    Text(
                      S.current.path_label(folderPathDisplay),
                      style: TS(c: qb.q(.8), s: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => P.pth.onRefreshFolderClicked(folder),
                icon: const Icon(Icons.refresh),
                tooltip: S.current.refresh,
              ),
              IconButton(
                onPressed: () => P.pth.onOpenFolderClicked(folder),
                icon: const Icon(Icons.folder_open),
                tooltip: S.current.open_folder,
              ),
              IconButton(
                onPressed: () => P.pth.onRemoveFolderClicked(folder),
                icon: const Icon(Icons.close),
                tooltip: S.current.forget_this_location,
              ),
            ],
          ),
          8.h,
          if (state == FolderState.loading) ...[
            Row(
              children: [
                T(S.current.scanning_folder_for_pth, s: TS(c: kCG)),
                8.w,
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kCG,
                  ),
                ),
              ],
            ),
            8.h,
          ],
          if (files.isEmpty && state == FolderState.loaded) ...[
            T(S.current.current_folder_has_no_local_models),
            8.h,
          ],
          if (state == FolderState.notfound) ...[
            T(S.current.folder_not_found_on_device),
            8.h,
          ],
          if (state == FolderState.restricted) ...[
            T(S.current.folder_not_accessible_check_permission),
            8.h,
          ],
          if (files.isNotEmpty)
            ...files
                .map(
                  (e) => Container(
                    decoration: BoxDecoration(
                      color: customTheme.settingItem,
                      borderRadius: 8.r,
                      border: Border.all(color: qb.q(.1), width: .5),
                    ),
                    padding: const .all(4),
                    child: Row(
                      crossAxisAlignment: .center,
                      children: [
                        Expanded(
                          child: _LocalPthFileItem(e, onStartToChat: () => P.pth.onStartPthFileForChat(e)),
                        ),
                        IconButton(
                          onPressed: () => P.pth.onDeleteFileClicked(folder, e),
                          icon: Icon(
                            Icons.delete_forever_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          tooltip: S.current.delete,
                        ),
                      ],
                    ),
                  ),
                )
                .toList()
                .widgetJoin((index) => 8.h),
          4.h,
        ],
      ),
    );
  }
}
