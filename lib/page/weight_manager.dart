import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart' as path;
import 'package:sprintf/sprintf.dart' show sprintf;
import 'package:zone/gen/l10n.dart';
import 'package:zone/func/format_bytes.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/local_file.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/store/p.dart';

/// 权重管理页面, 管理通过 latest.json 配置的文件
class PageWeightManager extends ConsumerWidget {
  const PageWeightManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.weights_mangement),
      ),
      body: const _Body(),
      bottomNavigationBar: const _BottomBar(),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => P.remote.pickAndExportAllWeightFiles(
                context: context,
              ),
              icon: const Icon(Icons.share),
              label: Text(s.export_all_weight_files),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () => P.remote.pickAndImportWeightFiles(context: context),
              icon: const Icon(Icons.add),
              label: Text(s.import_weight_file),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRefresh();
    });
  }

  Future<void> _onRefresh() async {
    qr;
    await Future.wait([
      500.msLater,
      P.remote.checkLocal(),
      P.remote.refreshUnrecognizedFiles(),
    ]);
    qr;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = P.app.isDesktop.q;
    return Column(
      children: [
        // Fixed header - doesn't scroll
        if (isDesktop) const _CustomDirectoryTile(),
        if (isDesktop) const Divider(height: 1),
        // Scrollable content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              children: const [
                _WeightList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomDirectoryTile extends ConsumerWidget {
  const _CustomDirectoryTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUsingCustomDir = ref.watch(P.remote.usingCustomModelsDir);
    final effectiveDir = ref.watch(P.remote.effectiveModelsDir) ?? "";
    final s = S.of(context);

    return ListTile(
      title: Text(s.weights_saving_directory),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(effectiveDir),
          const SizedBox(height: 4),
          Text(
            isUsingCustomDir ? s.using_custom_directory : s.using_default_directory,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.refresh,
            onPressed: () async {
              await P.remote.checkLocal();
              Alert.success(s.refresh_complete);
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: s.open_folder,
            onPressed: P.remote.openModelDirectory,
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move),
            tooltip: s.set_custom_directory,
            onPressed: () => P.remote.pickAndSetCustomModelsDir(context: context),
          ),
          if (isUsingCustomDir)
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: s.reset,
              onPressed: () => P.remote.resetToDefaultModelsDir(context: context),
            ),
        ],
      ),
    );
  }
}

class _WeightList extends ConsumerWidget {
  const _WeightList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatWeights = ref.watch(P.remote.chatWeights);
    final ttsWeights = ref.watch(P.remote.ttsWeights);
    final roleplayWeights = ref.watch(P.remote.roleplayWeights);
    final seeWeights = ref.watch(P.remote.seeWeights);
    final sudokuWeights = ref.watch(P.remote.sudokuWeights);
    final othelloWeights = ref.watch(P.remote.othelloWeights);

    final allWeights = [
      ...chatWeights,
      ...ttsWeights,
      ...roleplayWeights,
      ...seeWeights,
      ...sudokuWeights,
      ...othelloWeights,
    ];

    // Check if there are any downloaded files
    final hasDownloadedFiles = allWeights.any((fileInfo) {
      final local = ref.watch(P.remote.locals(fileInfo));
      return local.hasFile;
    });

    // Show empty state if no downloaded files
    if (!hasDownloadedFiles) {
      return const _EmptyStateGuide();
    }

    return Column(
      children: [
        _TotalUsageTile(allWeights: allWeights),
        _DownloadingSection(allWeights: allWeights),
        _WeightSection(title: S.current.rwkv_chat, weights: chatWeights),
        _WeightSection(title: S.current.role_play, weights: roleplayWeights),
        _WeightSection(title: S.current.visual_understanding_and_ocr, weights: seeWeights),
        _WeightSection(title: S.current.tts, weights: ttsWeights),
        _WeightSection(title: "Sudoku", weights: sudokuWeights),
        _WeightSection(title: S.current.rwkv_othello, weights: othelloWeights),
        _OtherFilesSection(),
      ],
    );
  }
}

class _DownloadingSection extends ConsumerWidget {
  final List<FileInfo> allWeights;

  const _DownloadingSection({required this.allWeights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadingEntries = <(FileInfo, LocalFile)>[];

    for (final fileInfo in allWeights) {
      final local = ref.watch(P.remote.locals(fileInfo));
      if (local.downloading) {
        downloadingEntries.add((fileInfo, local));
      }
    }

    if (downloadingEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            s.downloading,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final entry in downloadingEntries)
          _DownloadingItem(
            fileInfo: entry.$1,
            localFile: entry.$2,
          ),
        const Divider(height: 1),
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
      final local = ref.watch(P.remote.locals(w));
      return local.hasFile;
    }).toList()..sort((a, b) => b.fileSize.compareTo(a.fileSize));

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
    // Watch all locals to ensure this widget rebuilds when any file state changes
    for (final weight in allWeights) {
      ref.watch(P.remote.locals(weight));
    }

    final totalBytes = P.remote.calculateTotalDiskUsage();
    final s = S.of(context);

    return ListTile(
      title: Text(s.total_disk_usage),
      trailing: Text(
        formatBytes(totalBytes),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _DownloadingItem extends ConsumerWidget {
  final FileInfo fileInfo;
  final LocalFile localFile;

  const _DownloadingItem({
    required this.fileInfo,
    required this.localFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);

    final progress = localFile.progress / 100;
    double networkSpeed = localFile.networkSpeed.clamp(0, 99999999).toDouble();
    Duration timeRemaining = localFile.timeRemaining;
    if (timeRemaining.isNegative) timeRemaining = Duration.zero;

    final remainText = timeRemaining.inMinutes == 0
        ? '${timeRemaining.inSeconds}s'
        : '${timeRemaining.inMinutes}m${timeRemaining.inSeconds % 60}s';

    final weightType = fileInfo.weightType;
    final targetLabel = switch (weightType) {
      .chat => s.rwkv_chat,
      .see => s.visual_understanding_and_ocr,
      .tts => s.tts,
      .sudoku => 'Sudoku',
      .othello => s.rwkv_othello,
      .roleplay => s.role_play,
      null => s.unknown,
    };

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return ListTile(
      title: Text(fileInfo.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.q(.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(formatBytes(fileInfo.fileSize)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.q(.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(targetLabel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (progress.isNaN || progress <= 0 || progress.isInfinite) ? null : progress,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 4),
          Text(
            sprintf(
              s.str_downloading_info,
              [
                (progress.isNaN || progress <= 0 || progress.isInfinite) ? 0.0 : progress * 100.0,
                networkSpeed,
                remainText,
              ],
            ),
            style: TextStyle(
              fontFamily: monospaceFF,
              fontFamilyFallback: const ['Roboto Mono', 'Roboto', 'CourierNew', 'Menlo', 'PingFang SC'],
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.cancel),
        tooltip: s.cancel_download,
        onPressed: () async {
          final result = await showOkCancelAlertDialog(
            context: context,
            title: s.cancel_download,
            message: "${s.cancel_download} (${fileInfo.name})",
            okLabel: s.cancel_download,
            isDestructiveAction: true,
          );
          if (result == OkCancelResult.ok) {
            await P.remote.cancelDownload(fileInfo: fileInfo);
          }
        },
      ),
    );
  }
}

class _WeightItem extends ConsumerWidget {
  final FileInfo fileInfo;
  const _WeightItem({required this.fileInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(P.remote.locals(fileInfo));
    if (!local.hasFile) {
      return const SizedBox.shrink();
    }

    return ListTile(
      title: Text(fileInfo.name),
      subtitle: Wrap(
        runSpacing: 4,
        spacing: 4,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.q(.1),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(formatBytes(fileInfo.fileSize)),
          ),
          Text(path.basename(local.targetPath)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => P.remote.pickAndExportWeightFile(fileInfo: fileInfo),
            tooltip: S.current.export_weight_file,
          ),
          IconButton(
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
                await P.remote.deleteFile(fileInfo: fileInfo);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OtherFilesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch weight lists to trigger refresh when they change (e.g., after import)
    final chatWeights = ref.watch(P.remote.chatWeights);
    final roleplayWeights = ref.watch(P.remote.roleplayWeights);
    final ttsWeights = ref.watch(P.remote.ttsWeights);
    final seeWeights = ref.watch(P.remote.seeWeights);
    final sudokuWeights = ref.watch(P.remote.sudokuWeights);
    final othelloWeights = ref.watch(P.remote.othelloWeights);

    // Check if weight lists have changed
    final currentWeights = {
      ...chatWeights,
      ...roleplayWeights,
      ...ttsWeights,
      ...seeWeights,
      ...sudokuWeights,
      ...othelloWeights,
    };

    final files = ref.watch(P.remote.unrecognizedFiles)..sort((a, b) => b.fileSize.compareTo(a.fileSize));
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            S.current.other_files,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final file in files)
          _OtherFileItem(
            file: file,
            onDeleted: () {
              P.remote.refreshUnrecognizedFiles();
            },
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class _OtherFileItem extends ConsumerWidget {
  final UnrecognizedFile file;
  final VoidCallback onDeleted;

  const _OtherFileItem({
    required this.file,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(file.fileName),
      subtitle: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.q(.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(formatBytes(file.fileSize)),
          ),
          Text(path.basename(file.filePath)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          final result = await showOkCancelAlertDialog(
            context: context,
            title: S.current.delete,
            message: "${S.current.are_you_sure_you_want_to_delete_this_model} (${file.fileName})",
            okLabel: S.current.delete,
            isDestructiveAction: true,
          );
          if (result == OkCancelResult.ok) {
            try {
              await P.remote.deleteUnrecognizedFile(file);
              onDeleted();
            } catch (e) {
              if (context.mounted) {
                await showOkAlertDialog(
                  context: context,
                  title: S.current.delete,
                  message: "Failed to delete file: $e",
                  okLabel: S.current.got_it,
                );
              }
            }
          }
        },
      ),
    );
  }
}

class _EmptyStateGuide extends ConsumerWidget {
  const _EmptyStateGuide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.primary.q(.5),
            ),
            const SizedBox(height: 24),
            Text(
              s.no_weight_files_guide_title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              s.no_weight_files_guide_message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                pop();
                P.app.onTabSelected(PageKey.tabs.indexOf(PageKey.home));
              },
              icon: const Icon(Icons.home),
              label: Text(s.go_to_home_page),
            ),
          ],
        ),
      ),
    );
  }
}
