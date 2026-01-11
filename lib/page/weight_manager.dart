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
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart';

class PageWeightManager extends ConsumerWidget {
  const PageWeightManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.weights_mangement),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: () => _importWeightFile(context, ref),
              icon: const Icon(Icons.add),
              label: Text(S.current.import_weight_file),
            ),
          ),
        ],
      ),
      body: const _Body(),
    );
  }

  Future<void> _importWeightFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['st', 'gguf', 'prefab', 'bin', 'rmpack', 'mnn', 'zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;
      final sourcePath = pickedFile.path;
      final fileName = pickedFile.name;

      // On iOS, path might be null (e.g., when selecting from iCloud Drive)
      // In that case, we need to use bytes instead
      File? sourceFile;
      Uint8List? fileBytes;

      if (sourcePath != null) {
        sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) {
          Alert.error(S.current.file_not_found);
          return;
        }
      } else {
        // iOS: path is null, read bytes instead
        if (pickedFile.bytes == null) {
          Alert.error(S.current.file_path_not_found);
          return;
        }
        fileBytes = pickedFile.bytes;
      }

      // Check if file exists in config and at target location
      FileInfo? existingFileInfo;
      try {
        final fileNameToCheck = fileName.isNotEmpty ? fileName : (sourceFile != null ? path.basename(sourceFile.path) : "unknown");
        existingFileInfo = await P.fileManager.checkFileExistsInConfig(fileNameToCheck);
      } catch (e) {
        final errorMessage = e.toString();
        if (errorMessage.contains("not found in configuration")) {
          Alert.error(S.current.file_not_supported);
          return;
        } else {
          Alert.error("${S.current.import_failed}: $e");
          return;
        }
      }

      // If file exists, ask user for confirmation
      bool shouldOverwrite = false;
      if (existingFileInfo != null) {
        final s = S.of(context);
        final result = await showOkCancelAlertDialog(
          context: context,
          title: s.file_already_exists,
          message: s.overwrite_file_confirmation,
          okLabel: s.overwrite,
          cancelLabel: s.cancel,
          isDestructiveAction: true,
        );

        if (result != OkCancelResult.ok) {
          return; // User cancelled
        }
        shouldOverwrite = true;
      }

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Import with overwrite if file exists
      final success = await P.fileManager.importWeightFile(
        sourceFile: sourceFile,
        fileBytes: fileBytes,
        fileName: fileName.isNotEmpty ? fileName : (sourceFile != null ? path.basename(sourceFile.path) : "unknown"),
        overwrite: shouldOverwrite,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (success) {
        Alert.success(S.current.import_success);
        // Note: We don't need to invalidate weight lists or call checkLocal() here
        // because importWeightFile already updates the locals state for the imported file.
        // The UI will automatically refresh because _WeightSection watches locals().
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        final errorMessage = e.toString();
        if (errorMessage.contains("not found in configuration")) {
          Alert.error(S.current.file_not_supported);
        } else {
          Alert.error("${S.current.import_failed}: $e");
        }
      }
    }
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
      Future.delayed(500.ms),
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
    final defaultDir = documentsDir != null ? "$documentsDir/${Config.modelsDirName}" : "";
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

    return Column(
      children: [
        _TotalUsageTile(allWeights: allWeights),
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

    return ListTile(
      title: const Text("Total Disk Usage"),

      trailing: Text(WeightManagerUtils.formatBytes(totalBytes), style: Theme.of(context).textTheme.bodyLarge),
    );
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
          Text(local.targetPath.split("/").last),
        ],
      ),
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

    final unrecognizedFiles = <_UnrecognizedFile>[];

    try {
      final entities = directory.listSync();
      for (final entity in entities) {
        if (entity is! File) continue;

        final fileName = path.basename(entity.path);
        if (allWeightFileNames.contains(fileName)) continue;

        final fileSize = await entity.length();

        unrecognizedFiles.add(
          _UnrecognizedFile(
            fileName: fileName,
            filePath: entity.path,
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
    setState(() {
      _filesFuture = _getUnrecognizedFiles();
    });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFiles();
        }
      });
    }

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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.q(.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_formatBytes(file.fileSize)),
          ),
          Text(file.filePath.split("/").last),
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
