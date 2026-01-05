import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart';

class PageWeightManager extends ConsumerWidget {
  const PageWeightManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.weights_mangement)),
      body: const _Body(),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = P.app.isDesktop.q;
    return ListView(
      children: [
        if (isDesktop) const _CustomDirectoryTile(),
        const _WeightList(),
      ],
    );
  }
}

class _CustomDirectoryTile extends ConsumerWidget {
  const _CustomDirectoryTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customDir = ref.watch(P.preference.customModelsDir);
    final defaultDir = ref.watch(P.app.documentsDir)?.path ?? "";

    return ListTile(
      title: const Text("Custom Model Directory"),
      subtitle: Text(customDir ?? defaultDir),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              P.fileManager.openModelDirectory();
            },
          ),
          if (customDir != null)
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () async {
                final result = await showOkCancelAlertDialog(
                  context: context,
                  title: "Reset to Default?",
                  message: "Weights will be moved back to the default directory.",
                  okLabel: S.current.ok,
                );
                if (result == OkCancelResult.ok) {
                  await _showMigrationDialog(context, null);
                }
              },
            ),

          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              String? result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                final confirm = await showOkCancelAlertDialog(
                  context: context,
                  title: "Change Directory?",
                  message: "Existing weights will be moved to the new directory.",
                  okLabel: S.current.ok,
                );
                if (confirm == OkCancelResult.ok) {
                  await _showMigrationDialog(context, result);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showMigrationDialog(BuildContext context, String? newPath) async {
    final progressNotifier = ValueNotifier<(String, int, int)>(("", 0, 0));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MigrationProgressDialog(progressNotifier: progressNotifier),
    );

    await P.fileManager.updateCustomDirectory(
      newPath,
      onProgress: (currentFile, completed, total) {
        progressNotifier.value = (currentFile, completed, total);
      },
    );

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _MigrationProgressDialog extends StatelessWidget {
  final ValueNotifier<(String, int, int)> progressNotifier;

  const _MigrationProgressDialog({required this.progressNotifier});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Moving Weights..."),
      content: ValueListenableBuilder<(String, int, int)>(
        valueListenable: progressNotifier,
        builder: (context, value, child) {
          final (currentFile, completed, total) = value;
          final progress = total > 0 ? completed / total : 0.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Moving: $currentFile"),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text("$completed / $total"),
            ],
          );
        },
      ),
    );
  }
}

class _WeightList extends ConsumerWidget {
  const _WeightList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatWeights = ref.watch(P.fileManager.chatWeights);

    final ttsWeights = ref.watch(P.fileManager.ttsWeights);

    final roleplayWeights = ref.watch(P.fileManager.roleplayWeights);

    final seeWeights = ref.watch(P.fileManager.seeWeights);

    final sudokuWeights = ref.watch(P.fileManager.sudokuWeights);

    final othelloWeights = ref.watch(P.fileManager.othelloWeights);

    final allWeights = [
      ...chatWeights,
      ...ttsWeights,
      ...roleplayWeights,
      ...seeWeights,
      ...sudokuWeights,
      ...othelloWeights,
    ];

    return Column(
      children: [
        _TotalUsageTile(allWeights: allWeights),
        _WeightSection(title: S.current.rwkv_chat, weights: chatWeights),
        _WeightSection(title: S.current.choose_prebuilt_character, weights: roleplayWeights),
        _WeightSection(title: S.current.visual_understanding_and_ocr, weights: seeWeights),
        _WeightSection(title: S.current.tts, weights: ttsWeights),
        _WeightSection(title: "Sudoku", weights: sudokuWeights),
        _WeightSection(title: S.current.rwkv_othello, weights: othelloWeights),
      ],
    );
  }
}

class _WeightSection extends ConsumerWidget {
  final String title;

  final Set<FileInfo> weights;

  const _WeightSection({required this.title, required this.weights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter for downloaded weights

    final downloadedWeights = weights.where((w) {
      final local = ref.watch(P.fileManager.locals(w));

      return local.hasFile;
    }).toList();

    if (downloadedWeights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),

          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,

              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ...downloadedWeights.map((e) => _WeightItem(fileInfo: e)),

        const Divider(height: 1),
      ],
    );
  }
}

class _TotalUsageTile extends ConsumerWidget {
  final List<FileInfo> allWeights;

  const _TotalUsageTile({required this.allWeights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int totalBytes = 0;

    for (final weight in allWeights) {
      final local = ref.watch(P.fileManager.locals(weight));

      if (local.hasFile) {
        totalBytes += weight.fileSize;
      }
    }

    return ListTile(
      title: const Text("Total Disk Usage"),

      trailing: Text(_formatBytes(totalBytes), style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";

    const suffixes = ["B", "KB", "MB", "GB", "TB"];

    var i = (log(bytes) / log(1024)).floor();

    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }
}

class _WeightItem extends ConsumerWidget {
  final FileInfo fileInfo;
  const _WeightItem({required this.fileInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(P.fileManager.locals(fileInfo));
    if (!local.hasFile) {
      return const SizedBox.shrink();
    }

    return ListTile(
      title: Text(fileInfo.name),
      subtitle: Text(_formatBytes(fileInfo.fileSize)),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          final result = await showOkCancelAlertDialog(
            context: context,
            title: S.current.delete,
            message: "${S.current.are_you_sure_you_want_to_delete_this_model} (${fileInfo.name})",
            okLabel: S.current.delete,
            isDestructiveAction: true,
          );
          if (result == OkCancelResult.ok) {
            await P.fileManager.deleteFile(fileInfo: fileInfo);
          }
        },
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }
}
