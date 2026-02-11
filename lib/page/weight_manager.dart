import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart' as path;
import 'package:sprintf/sprintf.dart' show sprintf;
import 'package:zone/func/extensions/num.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/func/format_bytes.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/local_file.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';

/// 权重管理页面, 管理通过 latest.json 配置的文件
class PageWeightManager extends ConsumerWidget {
  const PageWeightManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final isMobile = ref.watch(P.app.isMobile);
    final syncingLocalFiles = ref.watch(P.remote.syncingLocalFiles);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.weights_mangement, style: theme.textTheme.titleLarge),
        actions: isMobile
            ? [
                IconButton(
                  tooltip: syncingLocalFiles ? s.syncing : s.refresh,
                  icon: syncingLocalFiles
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  onPressed: syncingLocalFiles
                      ? null
                      : () async {
                          await P.remote.sync();
                          Alert.success(s.refresh_complete);
                        },
                ),
              ]
            : null,
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
    final paddingBottom = ref.watch(P.app.paddingBottom);
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      padding: .only(bottom: paddingBottom),
      constraints: const BoxConstraints(minHeight: kToolbarHeight),
      decoration: BoxDecoration(
        color: appTheme.scaffoldBg,
        border: Border(top: BorderSide(color: theme.dividerColor, width: .5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                P.remote.pickAndExportAllWeightFiles(context: context);
                500.msLater.then((_) => P.remote.sync());
              },
              icon: const Icon(Icons.share),
              label: Text(s.export_all_weight_files),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                P.remote.pickAndImportWeightFiles(context: context);
                500.msLater.then((_) => P.remote.sync());
              },
              icon: const Icon(Icons.add),
              label: Text(s.import_weight_file),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = ref.watch(P.app.isDesktop);
    final chatWeights = ref.watch(P.remote.chatWeights);
    final ttsWeights = ref.watch(P.remote.ttsWeights);
    final roleplayWeights = ref.watch(P.remote.roleplayWeights);
    final seeWeights = ref.watch(P.remote.seeWeights);
    final sudokuWeights = ref.watch(P.remote.sudokuWeights);
    final othelloWeights = ref.watch(P.remote.othelloWeights);
    final qb = ref.watch(P.app.qb);

    final unrecognizedFiles = ref.watch(P.remote.unrecognizedFiles);
    final mlxCacheDirectories = ref.watch(P.remote.mlxCacheDirectories);

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
    final hasVisibleFiles = hasDownloadedFiles || unrecognizedFiles.isNotEmpty || mlxCacheDirectories.isNotEmpty;

    // Show empty state if no downloaded files

    final s = S.of(context);

    final locals = P.remote.locals;

    final children = [
      if (allWeights.any((e) => locals(e).q.downloading)) _DownloadingSection(allWeights: allWeights),
      if (!hasVisibleFiles) const _EmptyStateGuide(),
      if (chatWeights.where((e) => locals(e).q.hasFile).isNotEmpty) _WeightSection(title: s.rwkv_chat, weights: chatWeights),
      if (roleplayWeights.where((e) => locals(e).q.hasFile).isNotEmpty) _WeightSection(title: s.role_play, weights: roleplayWeights),
      if (seeWeights.where((e) => locals(e).q.hasFile).isNotEmpty)
        _WeightSection(title: s.visual_understanding_and_ocr, weights: seeWeights),
      if (ttsWeights.where((e) => locals(e).q.hasFile).isNotEmpty) _WeightSection(title: s.tts, weights: ttsWeights),
      if (sudokuWeights.where((e) => locals(e).q.hasFile).isNotEmpty) _WeightSection(title: "Sudoku", weights: sudokuWeights),
      if (othelloWeights.where((e) => locals(e).q.hasFile).isNotEmpty) _WeightSection(title: s.rwkv_othello, weights: othelloWeights),
      if (mlxCacheDirectories.isNotEmpty) const _MlxCacheSection(),
      if (unrecognizedFiles.isNotEmpty) _OtherFilesSection(),
    ];

    return Column(
      children: [
        const _TotalSizeSection(),
        if (isDesktop) ...[
          const _CustomDirectoryTile(),
          Container(
            decoration: BoxDecoration(color: qb.q(.3)),
            height: .5,
          ),
        ],
        Expanded(
          child: RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () async {
              await P.remote.sync();
              Alert.success(s.refresh_complete);
            },
            child: ListView.separated(
              itemBuilder: (context, index) => children[index],
              separatorBuilder: (context, index) => Padding(
                padding: const .symmetric(horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(color: qb.q(.3)),
                  height: .5,
                ),
              ),
              itemCount: children.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalSizeSection extends ConsumerWidget {
  const _TotalSizeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final totalSize = ref.watch(P.remote.totalSizeInModelsDir);
    final qb = ref.watch(P.app.qb);
    final isDesktop = ref.watch(P.app.isDesktop);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.storage_outlined),
            const SizedBox(width: 8),
            Text(
              s.total_disk_usage + ": " + formatBytes(totalSize),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        if (!isDesktop) const SizedBox(height: 8),
        if (!isDesktop)
          Container(
            decoration: BoxDecoration(color: qb.q(.3)),
            height: .5,
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
    final effectiveModelsDir = ref.watch(P.remote.effectiveModelsDir);
    final syncingLocalFiles = ref.watch(P.remote.syncingLocalFiles);

    final s = S.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const .fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.weights_saving_directory,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(effectiveModelsDir),
                const SizedBox(height: 4),
                Text(
                  isUsingCustomDir ? s.using_custom_directory : s.using_default_directory,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: syncingLocalFiles
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                tooltip: s.refresh,
                onPressed: syncingLocalFiles
                    ? null
                    : () async {
                        await P.remote.sync();
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
        ],
      ),
    );
  }
}

class _DownloadingSection extends ConsumerWidget {
  final List<FileInfo> allWeights;

  const _DownloadingSection({required this.allWeights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<(FileInfo, LocalFile)> downloadingEntries = <(FileInfo, LocalFile)>[];

    for (final FileInfo fileInfo in allWeights) {
      final LocalFile local = ref.watch(P.remote.locals(fileInfo));
      if (local.downloading) {
        downloadingEntries.add((fileInfo, local));
      }
    }

    if (downloadingEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    final qb = ref.watch(P.app.qb);

    int totalSize = 0;
    for (final (FileInfo fileInfo, LocalFile localFile) in downloadingEntries) {
      final double progressRatio = localFile.progress.clamp(0, 100).toDouble() / 100.0;
      final int estimatedDownloadedBytes = (fileInfo.fileSize * progressRatio).round();
      int occupiedBytes = estimatedDownloadedBytes;
      if (occupiedBytes < 0) {
        occupiedBytes = 0;
      }
      if (occupiedBytes > fileInfo.fileSize) {
        occupiedBytes = fileInfo.fileSize;
      }
      totalSize += occupiedBytes;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: s.downloading,
          totalSize: totalSize,
        ),
        for (final (FileInfo fileInfo, LocalFile localFile) in downloadingEntries)
          _DownloadingItem(
            fileInfo: fileInfo,
            localFile: localFile,
          ),
        Padding(
          padding: const .symmetric(horizontal: 8),
          child: Container(
            decoration: BoxDecoration(color: qb.q(.3)),
            height: .5,
          ),
        ),
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
    final List<FileInfo> downloadedWeights = weights.where((FileInfo w) {
      final local = ref.watch(P.remote.locals(w));
      return local.hasFile;
    }).toList()..sort((FileInfo a, FileInfo b) => b.fileSize.compareTo(a.fileSize));

    if (downloadedWeights.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalSize = 0;
    for (final FileInfo fileInfo in downloadedWeights) {
      totalSize += fileInfo.fileSize;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: title,
          totalSize: totalSize,
        ),
        ...downloadedWeights.map((FileInfo e) => _WeightItem(fileInfo: e)),
      ],
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
    final qb = ref.watch(P.app.qb);

    return Padding(
      padding: const .fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileInfo.name,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: qb.q(_tagBgOpacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const .symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  formatBytes(fileInfo.fileSize),
                  style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: qb.q(_tagBgOpacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const .symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  targetLabel,
                  style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
                ),
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
    );
  }
}

const _tagTextSize = 12.0;
const _tagBgOpacity = .1;
const _tagTextColorOpacity = .7;

class _WeightItem extends ConsumerWidget {
  final FileInfo fileInfo;
  const _WeightItem({required this.fileInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Theme.of(context);
    final local = ref.watch(P.remote.locals(fileInfo));
    if (!local.hasFile) {
      return const SizedBox.shrink();
    }

    final basename = path.basename(local.targetPath);
    final needToShowBasename = basename != fileInfo.name;

    final qb = ref.watch(P.app.qb);

    return Padding(
      padding: const .fromLTRB(16, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileInfo.name),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 4,
                  spacing: 4,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: qb.q(_tagBgOpacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const .symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        formatBytes(fileInfo.fileSize),
                        style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
                      ),
                    ),
                    if (needToShowBasename)
                      Text(
                        basename,
                        style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Row(
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
                    Alert.info(S.current.delete_finished);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MlxCacheSection extends ConsumerWidget {
  const _MlxCacheSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);

    final List<MlxCacheDirectory> directories = [...ref.watch(P.remote.mlxCacheDirectories)]
      ..sort((MlxCacheDirectory a, MlxCacheDirectory b) => b.directorySize.compareTo(a.directorySize));
    if (directories.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalSize = 0;
    for (final MlxCacheDirectory directory in directories) {
      totalSize += directory.directorySize;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: s.mlx_cache,
          totalSize: totalSize,
        ),
        Padding(
          padding: const .fromLTRB(16, 0, 16, 4),
          child: Text(
            s.mlx_cache_notice,
            style: theme.textTheme.bodySmall,
          ),
        ),
        for (final MlxCacheDirectory directory in directories)
          _MlxCacheItem(
            directory: directory,
            onDeleted: P.remote.sync,
          ),
      ],
    );
  }
}

class _MlxCacheItem extends ConsumerWidget {
  final MlxCacheDirectory directory;
  final Future<void> Function() onDeleted;

  const _MlxCacheItem({
    required this.directory,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return Padding(
      padding: const .fromLTRB(16, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(directory.directoryName, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const .symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: qb.q(_tagBgOpacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formatBytes(directory.directorySize),
                        style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final String message =
                  "${S.current.delete_mlx_cache_confirmation} (${directory.directoryName})\n\n${S.current.mlx_cache_notice}";
              final result = await showOkCancelAlertDialog(
                context: context,
                title: S.current.delete,
                message: message,
                okLabel: S.current.delete,
                isDestructiveAction: true,
              );
              if (result != OkCancelResult.ok) {
                return;
              }
              try {
                await P.remote.deleteMlxCacheDirectory(directory);
                await onDeleted();
                Alert.info(S.current.delete_finished);
              } catch (e) {
                if (context.mounted) {
                  await showOkAlertDialog(
                    context: context,
                    title: S.current.delete,
                    message: S.current.failed_to_delete_file("$e"),
                    okLabel: S.current.got_it,
                  );
                }
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
    // Check if weight lists have changed

    final List<UnrecognizedFile> files = [...ref.watch(P.remote.unrecognizedFiles)]
      ..sort((UnrecognizedFile a, UnrecognizedFile b) => b.fileSize.compareTo(a.fileSize));
    if (files.isEmpty) return const SizedBox.shrink();

    int totalSize = 0;
    for (final UnrecognizedFile file in files) {
      totalSize += file.fileSize;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: S.current.other_files,
          totalSize: totalSize,
        ),
        for (final UnrecognizedFile file in files)
          _OtherFileItem(
            file: file,
            onDeleted: P.remote.sync,
          ),
      ],
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  final String title;
  final int totalSize;

  const _SectionHeader({
    required this.title,
    required this.totalSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    return Padding(
      padding: const .fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const .symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: qb.q(_tagBgOpacity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formatBytes(totalSize),
              style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherFileItem extends ConsumerWidget {
  final UnrecognizedFile file;
  final Future<void> Function() onDeleted;

  const _OtherFileItem({
    required this.file,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    S.of(context);
    Theme.of(context);

    final basename = path.basename(file.filePath);
    final needToShowBasename = basename != file.fileName;

    final qb = ref.watch(P.app.qb);

    return Padding(
      padding: const .fromLTRB(16, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.fileName),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const .symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: qb.q(_tagBgOpacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formatBytes(file.fileSize),
                        style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
                      ),
                    ),
                    if (needToShowBasename)
                      Text(
                        basename,
                        style: TS(s: _tagTextSize, c: qb.q(_tagTextColorOpacity)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
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
                      message: S.current.failed_to_delete_file("$e"),
                      okLabel: S.current.got_it,
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyStateGuide extends ConsumerWidget {
  const _EmptyStateGuide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const .all(64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: theme.colorScheme.primary.q(.5),
            ),
            const SizedBox(height: 24),
            Text(
              s.no_weight_files_guide_title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              s.no_weight_files_guide_message,
              style: theme.textTheme.bodyMedium,
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
