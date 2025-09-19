import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/flutter_roleplay.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_downloader/downloader.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart' show P, $FileManager;
import 'package:zone/widgets/model_item.dart';

import '../gen/l10n.dart' show S;

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
  }

  void onStateTap(ModelStateFile state) {
    setState(() {
      currentStateFile = state;
    });
    final info = ModelInfo(
      id: widget.file.fileName,
      modelPath: P.fileManager.locals(widget.file).q.targetPath,
      statePath: P.fileManager.locals(state).q.targetPath,
      backend: widget.file.backend!,
      topP: state.decodeParam['topP'],
      temperature: state.decodeParam['temperature']?.toDouble(),
      penaltyDecay: state.decodeParam['penaltyDecay']?.toDouble(),
      presencePenalty: state.decodeParam['presencePenalty']?.toDouble(),
      frequencyPenalty: state.decodeParam['frequencyPenalty']?.toDouble(),
    );
    RoleplayManage.onModelDownloadComplete(info);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = ref.watch(P.fileManager.locals(widget.file));
    final customTheme = ref.watch(P.app.customTheme);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModelItem(
            widget.file,
            true,
            showLoadModel: false,
            showDelete: currentModelName != widget.file.fileName,
          ),
          if (local.hasFile) const SizedBox(height: 8),
          if (local.hasFile) Text(S.current.state_list, style: TextStyle(fontWeight: FontWeight.w500)),
          if (local.hasFile)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: customTheme.settingItem,
              ),
              child: Column(
                children: [
                  for (final state in widget.file.state) ...[
                    _ModelStateItem(
                      state: state,
                      onSelectTap: currentStateFile?.fileName == state.fileName ? null : () => onStateTap(state),
                    ),
                    if (state != widget.file.state.last)
                      Divider(
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
    final localFile = ref.watch(P.fileManager.locals(state));
    final downloading = localFile.state == TaskState.running;
    final progress = localFile.progress.isNaN || localFile.progress.isInfinite ? null : localFile.progress / 100;
    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
              P.fileManager.deleteFile(fileInfo: state);
            },
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline),
          ),
        if (localFile.hasFile)
          FilledButton(
            onPressed: onSelectTap,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              backgroundColor: WidgetStateProperty.all(onSelectTap == null ? Colors.grey.shade300 : Colors.green),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            child: Text(onSelectTap == null ? S.current.loaded : S.current.load_),
          ),
      ],
    );
  }
}
