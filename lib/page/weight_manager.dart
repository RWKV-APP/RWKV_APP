import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:path/path.dart' as path;
import 'package:sprintf/sprintf.dart' show sprintf;
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/local_file.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/store/p.dart';

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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _exportAllWeightFiles(context, ref),
                icon: const Icon(Icons.share),
                label: Text(s.export_all_weight_files),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _importWeightFile(context, ref),
                icon: const Icon(Icons.add),
                label: Text(s.import_weight_file),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importWeightFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['st', 'gguf', 'prefab', 'bin', 'rmpack', 'mnn', 'zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFiles = result.files;
      final totalFiles = pickedFiles.length;

      // First, validate all files and check for existing files
      final List<_FileImportInfo> fileInfos = [];
      bool hasExistingFiles = false;

      for (final pickedFile in pickedFiles) {
        final sourcePath = pickedFile.path;
        final fileName = pickedFile.name;

        File? sourceFile;
        Uint8List? fileBytes;

        if (sourcePath != null) {
          sourceFile = File(sourcePath);
          if (!await sourceFile.exists()) {
            fileInfos.add(
              _FileImportInfo(
                pickedFile: pickedFile,
                sourceFile: null,
                fileBytes: null,
                existingFileInfo: null,
                error: S.current.file_not_found,
              ),
            );
            continue;
          }
        } else {
          if (pickedFile.bytes == null) {
            fileInfos.add(
              _FileImportInfo(
                pickedFile: pickedFile,
                sourceFile: null,
                fileBytes: null,
                existingFileInfo: null,
                error: S.current.file_path_not_found,
              ),
            );
            continue;
          }
          fileBytes = pickedFile.bytes;
        }

        FileInfo? existingFileInfo;
        try {
          final fileNameToCheck = fileName.isNotEmpty ? fileName : (sourceFile != null ? path.basename(sourceFile.path) : "unknown");
          existingFileInfo = await P.fileManager.checkFileExistsInConfig(fileNameToCheck);
          if (existingFileInfo != null) {
            hasExistingFiles = true;
          }
        } catch (e) {
          final errorMessage = e.toString();
          if (errorMessage.contains("not found in configuration")) {
            fileInfos.add(
              _FileImportInfo(
                pickedFile: pickedFile,
                sourceFile: sourceFile,
                fileBytes: fileBytes,
                existingFileInfo: null,
                error: S.current.file_not_supported,
              ),
            );
            continue;
          } else {
            fileInfos.add(
              _FileImportInfo(
                pickedFile: pickedFile,
                sourceFile: sourceFile,
                fileBytes: fileBytes,
                existingFileInfo: null,
                error: e.toString(),
              ),
            );
            continue;
          }
        }

        fileInfos.add(
          _FileImportInfo(
            pickedFile: pickedFile,
            sourceFile: sourceFile,
            fileBytes: fileBytes,
            existingFileInfo: existingFileInfo,
            error: null,
          ),
        );
      }

      // If there are existing files, ask user for confirmation
      bool shouldOverwrite = false;
      if (hasExistingFiles) {
        final s = S.of(context);
        final existingCount = fileInfos.where((info) => info.existingFileInfo != null && info.error == null).length;
        final message = existingCount == 1
            ? s.overwrite_file_confirmation
            : "${s.overwrite_file_confirmation}\n\n($existingCount ${S.current.files})";

        final confirmResult = await showOkCancelAlertDialog(
          context: context,
          title: s.file_already_exists,
          message: message,
          okLabel: s.overwrite,
          cancelLabel: s.cancel,
          isDestructiveAction: true,
        );

        if (confirmResult != OkCancelResult.ok) {
          return; // User cancelled
        }
        shouldOverwrite = true;
      }

      // Show progress dialog
      final progressNotifier = ValueNotifier<(String, int, int)>(("", 0, totalFiles));
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ImportProgressDialog(progressNotifier: progressNotifier),
        );
      }

      int successCount = 0;
      int failCount = 0;
      final List<String> failedFiles = [];

      // Process each file
      for (var i = 0; i < fileInfos.length; i++) {
        final fileInfo = fileInfos[i];
        final pickedFile = fileInfo.pickedFile;
        final fileName = pickedFile.name;

        // Update progress
        progressNotifier.value = (fileName, i, totalFiles);

        // Skip files with errors
        if (fileInfo.error != null) {
          failCount++;
          failedFiles.add("$fileName: ${fileInfo.error}");
          continue;
        }

        // Import the file
        try {
          final fileNameToUse = pickedFile.name.isNotEmpty
              ? pickedFile.name
              : (fileInfo.sourceFile != null ? path.basename(fileInfo.sourceFile!.path) : "unknown");

          final success = await P.fileManager.importWeightFile(
            sourceFile: fileInfo.sourceFile,
            fileBytes: fileInfo.fileBytes,
            fileName: fileNameToUse,
            overwrite: shouldOverwrite && fileInfo.existingFileInfo != null,
          );

          if (success) {
            successCount++;
          } else {
            failCount++;
            failedFiles.add("$fileName: ${S.current.import_failed}");
          }
        } catch (e) {
          failCount++;
          failedFiles.add("$fileName: ${e.toString()}");
        }
      }

      // Close progress dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show result summary
      if (successCount > 0 && failCount == 0) {
        Alert.success(totalFiles == 1 ? S.current.import_success : "$successCount ${S.current.import_success}");
      } else if (successCount > 0 && failCount > 0) {
        final message = "$successCount ${S.current.import_success}\n$failCount ${S.current.import_failed}\n\n${failedFiles.join('\n')}";
        Alert.warning(message);
      } else {
        final message = "${S.current.import_failed}:\n${failedFiles.join('\n')}";
        Alert.error(message);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog if still open
        final errorMessage = e.toString();
        if (errorMessage.contains("not found in configuration")) {
          Alert.error(S.current.file_not_supported);
        } else {
          Alert.error("${S.current.import_failed}: $e");
        }
      }
    }
  }

  Future<void> _exportAllWeightFiles(BuildContext context, WidgetRef ref) async {
    try {
      final s = S.of(context);

      // Check if there are any files to export
      final allWeights = [
        ...ref.read(P.fileManager.chatWeights),
        ...ref.read(P.fileManager.roleplayWeights),
        ...ref.read(P.fileManager.ttsWeights),
        ...ref.read(P.fileManager.seeWeights),
        ...ref.read(P.fileManager.sudokuWeights),
        ...ref.read(P.fileManager.othelloWeights),
      ];

      final filesToExport = allWeights.where((fileInfo) {
        final local = ref.read(P.fileManager.locals(fileInfo));
        return local.hasFile;
      }).toList();

      if (filesToExport.isEmpty) {
        Alert.warning(s.no_weight_files_to_export);
        return;
      }

      // Show confirmation dialog explaining what will happen
      final confirmResult = await showOkCancelAlertDialog(
        context: context,
        title: s.export_all_weight_files,
        message: s.export_all_weight_files_description,
        okLabel: s.export_all_weight_files,
        cancelLabel: s.cancel,
      );

      if (confirmResult != OkCancelResult.ok) {
        return; // User cancelled
      }

      // Select target directory
      final targetDirectory = await file_picker.FilePicker.platform.getDirectoryPath();
      if (targetDirectory == null) {
        return; // User cancelled
      }

      // Show progress dialog
      final progressNotifier = ValueNotifier<(String, int, int)>(("", 0, 0));
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ExportProgressDialog(progressNotifier: progressNotifier),
        );
      }

      // Export all files
      try {
        final exportDirectory = await P.fileManager.exportAllWeightFiles(
          targetDirectory: targetDirectory,
          onProgress: (currentFile, completed, total) {
            progressNotifier.value = (currentFile, completed, total);
          },
        );

        if (context.mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          Alert.success("${S.current.export_success}\n\nDirectory: $exportDirectory");
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          Alert.error("${S.current.export_failed}: $e");
        }
      }
    } catch (e) {
      if (context.mounted) {
        Alert.error("${S.current.export_failed}: $e");
      }
    }
  }
}

class _ExportProgressDialog extends StatelessWidget {
  final ValueNotifier<(String, int, int)> progressNotifier;

  const _ExportProgressDialog({required this.progressNotifier});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: ValueListenableBuilder<(String, int, int)>(
        valueListenable: progressNotifier,
        builder: (context, value, _) {
          final (currentFile, completed, total) = value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              if (currentFile.isNotEmpty)
                Text(
                  currentFile,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (total > 0)
                Text(
                  "$completed / $total",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ImportProgressDialog extends StatelessWidget {
  final ValueNotifier<(String, int, int)> progressNotifier;

  const _ImportProgressDialog({required this.progressNotifier});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: ValueListenableBuilder<(String, int, int)>(
        valueListenable: progressNotifier,
        builder: (context, value, _) {
          final (currentFile, completed, total) = value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              if (currentFile.isNotEmpty)
                Text(
                  currentFile,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (total > 0)
                Text(
                  "$completed / $total",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          );
        },
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
  final GlobalKey<_OtherFilesSectionState> _otherFilesSectionKey = GlobalKey<_OtherFilesSectionState>();

  @override
  void initState() {
    super.initState();
    // Automatically refresh on page load without showing pull-to-refresh UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRefresh();
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      500.msLater,
      P.fileManager.checkLocal(),
    ]);

    _otherFilesSectionKey.currentState?._loadFiles();
  }

  // Expose method to refresh other files section from outside
  void refreshOtherFiles() {
    _otherFilesSectionKey.currentState?._loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = P.app.isDesktop.q;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        children: [
          if (isDesktop) const _CustomDirectoryTile(),
          _WeightList(otherFilesSectionKey: _otherFilesSectionKey),
        ],
      ),
    );
  }
}

class _CustomDirectoryTile extends ConsumerWidget {
  const _CustomDirectoryTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customDir = ref.watch(P.preference.customModelsDir);
    final documentsDir = ref.watch(P.app.effectiveDocumentsDir)?.path;
    final defaultDir = documentsDir != null ? path.join(documentsDir, Config.modelsDirName) : "";
    final s = S.of(context);

    final finalDirString = customDir ?? defaultDir;

    return ListTile(
      title: Text(s.weights_saving_directory),
      subtitle: Text(finalDirString),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              P.fileManager.openModelDirectory();
            },
          ),
        ],
      ),
    );
  }
}

class _UnrecognizedFile {
  final String fileName;
  final String filePath;
  final int fileSize;

  const _UnrecognizedFile({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
  });
}

class _FileImportInfo {
  final file_picker.PlatformFile pickedFile;
  final File? sourceFile;
  final Uint8List? fileBytes;
  final FileInfo? existingFileInfo;
  final String? error;

  const _FileImportInfo({
    required this.pickedFile,
    required this.sourceFile,
    required this.fileBytes,
    required this.existingFileInfo,
    required this.error,
  });
}

class _WeightList extends ConsumerWidget {
  final GlobalKey<_OtherFilesSectionState>? otherFilesSectionKey;

  const _WeightList({this.otherFilesSectionKey});

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

    // Check if there are any downloaded files
    final hasDownloadedFiles = allWeights.any((fileInfo) {
      final local = ref.watch(P.fileManager.locals(fileInfo));
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
        _OtherFilesSection(key: otherFilesSectionKey, allWeights: allWeights),
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
      final local = ref.watch(P.fileManager.locals(fileInfo));
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
      final local = ref.watch(P.fileManager.locals(w));

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

class WeightManagerUtils {
  static int calculateTotalUsage(List<FileInfo> allWeights, WidgetRef ref) {
    int totalBytes = 0;

    for (final weight in allWeights) {
      // Use ref.watch to ensure this widget rebuilds when locals state changes
      final local = ref.watch(P.fileManager.locals(weight));

      if (local.hasFile) {
        totalBytes += weight.fileSize;
      }
    }

    return totalBytes;
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";

    const suffixes = ["B", "KB", "MB", "GB", "TB"];

    var i = (log(bytes) / log(1024)).floor();

    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }
}

class _TotalUsageTile extends ConsumerWidget {
  final List<FileInfo> allWeights;

  const _TotalUsageTile({required this.allWeights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all locals to ensure this widget rebuilds when any file state changes
    for (final weight in allWeights) {
      ref.watch(P.fileManager.locals(weight));
    }

    final totalBytes = WeightManagerUtils.calculateTotalUsage(allWeights, ref);
    final s = S.of(context);

    return ListTile(
      title: Text(s.total_disk_usage),

      trailing: Text(WeightManagerUtils.formatBytes(totalBytes), style: Theme.of(context).textTheme.bodyLarge),
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
                child: Text(WeightManagerUtils.formatBytes(fileInfo.fileSize)),
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
            await P.fileManager.cancelDownload(fileInfo: fileInfo);
          }
        },
      ),
    );
  }
}

class _WeightItem extends ConsumerWidget {
  final FileInfo fileInfo;
  const _WeightItem({required this.fileInfo});

  Future<void> _exportWeightFile(BuildContext context, WidgetRef ref) async {
    try {
      // Select target directory
      final targetDirectory = await file_picker.FilePicker.platform.getDirectoryPath();
      if (targetDirectory == null) {
        return; // User cancelled
      }

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Export the file
      try {
        await P.fileManager.exportWeightFile(
          fileInfo: fileInfo,
          targetDirectory: targetDirectory,
        );

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Alert.success(S.current.export_success);
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          final errorMessage = e.toString();
          if (errorMessage.contains("already exists")) {
            Alert.error(S.current.file_already_exists);
          } else {
            Alert.error("${S.current.export_failed}: $e");
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Alert.error("${S.current.export_failed}: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(P.fileManager.locals(fileInfo));
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const .symmetric(horizontal: 4, vertical: 2),
            child: Text(_formatBytes(fileInfo.fileSize)),
          ),
          Text(path.basename(local.targetPath)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportWeightFile(context, ref),
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
                await P.fileManager.deleteFile(fileInfo: fileInfo);
              }
            },
          ),
        ],
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

class _OtherFilesSection extends ConsumerStatefulWidget {
  final List<FileInfo> allWeights;

  const _OtherFilesSection({super.key, required this.allWeights});

  @override
  ConsumerState<_OtherFilesSection> createState() => _OtherFilesSectionState();
}

class _OtherFilesSectionState extends ConsumerState<_OtherFilesSection> {
  Future<List<_UnrecognizedFile>>? _filesFuture;
  Set<FileInfo>? _lastWatchedWeights;

  Future<List<_UnrecognizedFile>> _getUnrecognizedFiles() async {
    final customDir = P.preference.customModelsDir.q;
    final documentsDir = P.app.effectiveDocumentsDir.q?.path;
    final defaultDir = documentsDir != null ? "$documentsDir/${Config.modelsDirName}" : null;
    final targetDir = customDir ?? defaultDir;

    if (targetDir == null) return [];

    final directory = Directory(targetDir);
    if (!await directory.exists()) return [];

    // Get all file names from config (not just available ones)
    // This ensures we correctly identify files even if they're not available on current platform
    final allWeightFileNames = P.fileManager.getAllConfigFileNames();

    // Build a set of temporary file paths that belong to active download tasks.
    // These are typically files with `.tmp` suffix that are still being written,
    // and should NOT be shown in the "other files" section.
    final downloadingTmpPaths = <String>{};
    final downloadingCandidates = [
      P.fileManager.chatWeights.q,
      P.fileManager.roleplayWeights.q,
      P.fileManager.ttsWeights.q,
      P.fileManager.seeWeights.q,
      P.fileManager.sudokuWeights.q,
      P.fileManager.othelloWeights.q,
    ].expand((e) => e).where((e) => e.available).toList();

    for (final fileInfo in downloadingCandidates) {
      final local = P.fileManager.locals(fileInfo).q;
      if (!local.downloading) continue;
      downloadingTmpPaths.add("${local.targetPath}.tmp");
    }

    final unrecognizedFiles = <_UnrecognizedFile>[];

    try {
      final entities = directory.listSync();
      for (final entity in entities) {
        if (entity is! File) continue;

        final filePath = entity.path;

        // Skip files that are temporary files of active download tasks
        if (downloadingTmpPaths.contains(filePath)) {
          continue;
        }

        final fileName = path.basename(filePath);
        if (allWeightFileNames.contains(fileName)) continue;

        final fileSize = await entity.length();

        unrecognizedFiles.add(
          _UnrecognizedFile(
            fileName: fileName,
            filePath: filePath,
            fileSize: fileSize,
          ),
        );
      }
    } catch (e) {
      // Ignore errors when listing directory
    }

    return unrecognizedFiles;
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    _filesFuture = _getUnrecognizedFiles();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Watch weight lists to trigger refresh when they change (e.g., after import)
    final chatWeights = ref.watch(P.fileManager.chatWeights);
    final roleplayWeights = ref.watch(P.fileManager.roleplayWeights);
    final ttsWeights = ref.watch(P.fileManager.ttsWeights);
    final seeWeights = ref.watch(P.fileManager.seeWeights);
    final sudokuWeights = ref.watch(P.fileManager.sudokuWeights);
    final othelloWeights = ref.watch(P.fileManager.othelloWeights);

    // Check if weight lists have changed
    final currentWeights = {
      ...chatWeights,
      ...roleplayWeights,
      ...ttsWeights,
      ...seeWeights,
      ...sudokuWeights,
      ...othelloWeights,
    };

    // Reload files when weight lists change
    if (_lastWatchedWeights != currentWeights) {
      _lastWatchedWeights = currentWeights;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await 1000.msLater;
        if (mounted) {
          _loadFiles();
        }
      });
    }

    // debugger();

    qr;

    return FutureBuilder<List<_UnrecognizedFile>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final files = snapshot.data!..sort((a, b) => b.fileSize.compareTo(a.fileSize));
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
                  _loadFiles();
                },
              ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

class _OtherFileItem extends ConsumerWidget {
  final _UnrecognizedFile file;
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
        crossAxisAlignment: .center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.q(.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_formatBytes(file.fileSize)),
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
              await File(file.filePath).delete();
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

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }
}

class _EmptyStateGuide extends ConsumerWidget {
  const _EmptyStateGuide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const .all(32.0),
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
