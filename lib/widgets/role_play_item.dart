import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/models/model_info.dart' show ModelInfo;
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage, RoleplayManageModelType;
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_downloader/downloader.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart' show $RWKVLoad, $Remote, P;
import 'package:zone/widgets/model_item.dart';

import 'package:zone/gen/l10n.dart' show S;

ModelInfo? rolePlayCurrentModel;

class RolePlayItem extends ConsumerStatefulWidget {
  final FileInfo file;

  const RolePlayItem({super.key, required this.file});

  @override
  ConsumerState<RolePlayItem> createState() => _RolePlayItemState();
}

class _RolePlayItemState extends ConsumerState<RolePlayItem> {
  String currentModelName = '';
  ModelStateFile? currentStateFile;

  @override
  void initState() {
    super.initState();
    if (rolePlayCurrentModel != null) {
      currentModelName = rolePlayCurrentModel!.modelPath.split('/').last;
      final stateName = rolePlayCurrentModel!.statePath.split('/').last;
      currentStateFile = widget.file.state.firstWhereOrNull((e) => e.fileName == stateName) ?? widget.file.state.first;
    }
    qqq('current model name: $currentModelName, current state name: ${currentStateFile?.fileName}');
  }

  void onLoadTap(ModelStateFile? state) async {
    setState(() {
      currentStateFile = state;
    });
    final info = ModelInfo(
      id: widget.file.fileName,
      modelPath: P.remote.locals(widget.file).q.targetPath,
      statePath: state == null ? '' : P.remote.locals(state).q.targetPath,
      backend: widget.file.backend!,
      topP: state?.decodeParam['topP'],
      temperature: state?.decodeParam['temperature']?.toDouble(),
      penaltyDecay: state?.decodeParam['penaltyDecay']?.toDouble(),
      presencePenalty: state?.decodeParam['presencePenalty']?.toDouble(),
      frequencyPenalty: state?.decodeParam['frequencyPenalty']?.toDouble(),
      modelType: RoleplayManageModelType.chat,
    );
    final sp = await P.rwkv.loadChat(fileInfo: widget.file);
    RoleplayManage.onModelDownloadComplete(info, [sp.$1, sp.$2], P.rwkv.receivePort);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = ref.watch(P.remote.locals(widget.file));
    final customTheme = ref.watch(P.app.theme);

    final noState = widget.file.state.isEmpty;

    if (noState) {
      return ModelItem(
        widget.file,
        true,
        isCurrentModel: currentModelName == widget.file.fileName,
        onLoadModelTap: () => onLoadTap(null),
        showLoadModel: noState,
        showDelete: currentModelName != widget.file.fileName,
      );
    }

    return Container(
      margin: const .symmetric(vertical: 8),
      padding: const .symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: .circular(12),
        border: .all(color: theme.primaryColor),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          ModelItem(
            widget.file,
            true,
            showLoadModel: false,
            showDelete: currentModelName != widget.file.fileName,
          ),
          if (local.hasFile) const SizedBox(height: 8),
          if (local.hasFile) Text(S.current.state_list, style: const TextStyle(fontWeight: .w500)),
          if (local.hasFile)
            Container(
              padding: const .symmetric(vertical: 8, horizontal: 12),
              margin: const .only(top: 8),
              decoration: BoxDecoration(
                borderRadius: .circular(8),
                color: customTheme.settingItem,
              ),
              child: Column(
                children: [
                  for (final state in widget.file.state) ...[
                    _ModelStateItem(
                      state: state,
                      onSelectTap: currentStateFile?.fileName == state.fileName ? null : () => onLoadTap(state),
                    ),
                    if (state != widget.file.state.last)
                      const Divider(
                        height: 8,
                        thickness: 0.4,
                        indent: 2,
                        endIndent: 2,
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ModelStateItem extends ConsumerWidget {
  final ModelStateFile state;
  final VoidCallback? onSelectTap;

  const _ModelStateItem({required this.state, this.onSelectTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localFile = ref.watch(P.remote.locals(state));
    final downloading = localFile.state == TaskState.running;
    final progress = localFile.progress.isNaN || localFile.progress.isInfinite ? null : localFile.progress / 100;
    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                state.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: .w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (downloading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              color: theme.primaryColor,
              backgroundColor: theme.primaryColorLight,
            ),
          ),
        if (downloading) const SizedBox(width: 8),
        DownloadActions(
          file: state,
          state: localFile.state,
        ),
        if (onSelectTap != null && localFile.hasFile)
          IconButton(
            onPressed: () {
              P.remote.deleteFile(fileInfo: state);
            },
            visualDensity: .compact,
            icon: const Icon(Icons.delete_outline),
          ),
        if (localFile.hasFile)
          FilledButton(
            onPressed: onSelectTap,
            style: ButtonStyle(
              visualDensity: .compact,
              padding: .all(.zero),
              backgroundColor: .all(onSelectTap == null ? Colors.grey.shade300 : Colors.green),
              shape: .all(
                RoundedRectangleBorder(borderRadius: .circular(8)),
              ),
            ),
            child: Text(onSelectTap == null ? S.current.loaded : S.current.load_),
          ),
      ],
    );
  }
}
