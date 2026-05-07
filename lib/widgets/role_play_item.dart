// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/models/model_info.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_downloader/downloader.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_item.dart';

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
    final file = widget.file;

    if (P.remote.modelSelectorShown.q) {
      Navigator.pop(context);
    }

    await P.rwkvAutoLoad.loadRoleplayChatModel(fileInfo: file, state: state);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = ref.watch(P.remote.locals(widget.file));
    final appTheme = ref.watch(P.app.theme);

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
                color: appTheme.settingItem,
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
