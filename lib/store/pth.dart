part of 'p.dart';

class _Pth {
  late final folders = qs<List<Folder>>([]);

  /// macOS：已通过 security-scoped bookmark 取得访问权限的目录，移除文件夹时需 stopAccessing
  final _macosScopedResources = <String, FileSystemEntity>{};

  final _macosFileScopedResources = <String, FileSystemEntity>{};

  final _folderEntries = <String, PthFolderEntry>{};
}

FileInfo _fileInfoFromLocalModelFile(LocalModelFile file) {
  final backend = switch (file.kind) {
    LocalModelFileKind.pth => Backend.webRwkv,
    LocalModelFileKind.rwkvGguf => Backend.llamacpp,
  };
  final modelSize = _modelSizeFromSizeLabel(file.ggufSizeLabel);
  return FileInfo(
    fileName: file.fileName,
    name: file.displayName,
    fileSize: file.fileSize,
    fileType: FileType.weights,
    raw: file.path,
    isDebug: false,
    backend: backend,
    sha256: null,
    modelSize: modelSize,
    quantization: file.ggufQuantization,
    updatedAt: null,
    timestamp: null,
    date: null,
    fromPthFile: file.kind == LocalModelFileKind.pth,
    fromLocalGgufFile: file.kind == LocalModelFileKind.rwkvGguf,
    ggufArchitecture: file.ggufArchitecture,
    ggufFileType: file.ggufFileType,
    ggufSizeLabel: file.ggufSizeLabel,
    ggufQuantizationVersion: file.ggufQuantizationVersion,
    ggufArchitectureVersion: file.ggufArchitectureVersion,
    ggufContextLength: file.ggufContextLength,
    ggufBlockCount: file.ggufBlockCount,
    ggufEmbeddingLength: file.ggufEmbeddingLength,
    ggufFeedForwardLength: file.ggufFeedForwardLength,
  );
}

double? _modelSizeFromSizeLabel(String? sizeLabel) {
  if (sizeLabel == null) return null;
  final match = RegExp(r'(\d+(?:\.\d+)?)([bBmMkK])').firstMatch(sizeLabel.trim());
  if (match == null) return null;
  final rawValue = double.tryParse(match.group(1) ?? "");
  if (rawValue == null) return null;
  final unit = match.group(2)?.toLowerCase();
  return switch (unit) {
    "b" => rawValue,
    "m" => rawValue / 1000,
    "k" => rawValue / 1000000,
    _ => null,
  };
}

/// Private methods
extension _$Pth on _Pth {
  Future<void> _init() async {
    if (!P.preference.hasUnlinkDefaultModelsDirOnce) {
      final defaultModelsDir = P.remote.defaultModelsDir.q;
      if (defaultModelsDir.isEmpty) {
        qqw("Default models dir is not ready, skip adding it to pth folder entries");
      } else {
        qqr("add default models dir to pth folder entries");
        await P.preference.addPthFolderEntry(PthFolderEntry(path: defaultModelsDir));
      }
    }

    await _atuoCreateModelsDir();
    final entries = await P.preference.getPthFolderEntries();
    for (final entry in entries) {
      final accessibleEntry = await _startAccessingEntry(entry);
      final folder = Folder(path: accessibleEntry.path, state: FolderState.loading, files: const []);
      _folderEntries[accessibleEntry.path] = accessibleEntry;
      folders.q = [...folders.q, folder];
      refreshFolder(folder);
    }
    return;
  }

  Future<void> _atuoCreateModelsDir() async {
    if (!Platform.isWindows) return;
    if (Args.useWindowsSandboxModels) {
      qqr("Windows sandbox mode enabled, skip creating models dir in exe path");
      return;
    }
    qqr("Create models dir in exe dir");
    final exeDir = File(Platform.resolvedExecutable).parent;
    final modelsDir = Directory(join(exeDir.path, 'models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
  }
}

/// Public methods
extension $Pth on _Pth {
  Future<void> onAddFolderClicked() async {
    final path = await file_picker.FilePicker.getDirectoryPath();
    if (path == null) return;
    if (_containsFolderPath(path)) {
      Alert.warning(S.current.folder_already_added);
      return;
    }
    final entry = await _createFolderEntry(path);
    await addFolder(entry);
  }

  Future<void> onLocalModelDropDone(List<desktop_drop.DropItem> files) async {
    if (files.isEmpty) return;

    final entries = <PthFolderEntry>[];
    for (final file in files) {
      final entry = await _folderEntryFromDropItem(file);
      if (entry == null) continue;
      final index = entries.indexWhere((e) => _isSameFolderPath(e.path, entry.path));
      if (index != -1) {
        entries[index] = entries[index].mergeFileEntries(entry.fileEntries);
        continue;
      }
      entries.add(entry);
    }

    if (entries.isEmpty) return;

    bool hasHandled = false;
    for (final entry in entries) {
      final existingFolder = _folderByPath(entry.path);
      if (existingFolder != null) {
        await _mergeFolderEntry(existingFolder, entry);
        hasHandled = true;
        continue;
      }
      await addFolder(entry);
      hasHandled = true;
    }

    if (hasHandled) return;
    Alert.warning(S.current.folder_already_added);
  }

  Future<void> onRemoveFolderClicked(Folder folder) async {
    if (folder.files.isNotEmpty) {
      final res = await showOkCancelAlertDialog(
        context: getContext()!,
        title: S.current.confirm_forget_location_title,
        message: S.current.confirm_forget_location_message,
      );
      if (res != OkCancelResult.ok) return;
    }
    await removeFolder(folder);

    if (folder.path == P.remote.defaultModelsDir.q) {
      await P.preference.setHasUnlinkDefaultModelsDirOnce(true);
    }

    Alert.success(S.current.forget_location_success);
  }

  Future<void> onRefreshFolderClicked(Folder folder) async {
    qq;
    await refreshFolder(folder);
    Alert.success(S.current.refresh_complete);
  }

  Future<void> onRefreshAllFoldersClicked() async {
    refreshAllFolders();
  }

  Future<void> onOpenFolderClicked(Folder folder) async {
    final entry = _folderEntries[folder.path];
    final fileEntry = entry?.fileEntries.firstOrNull;
    if (entry?.bookmark == null && fileEntry != null) {
      await _startAccessingFileEntry(fileEntry);
      await openFileLocation(fileEntry.path);
      return;
    }
    await openFolder(folder.path);
  }

  bool isRecognizedLocalModelPath(String filePath) {
    final targetPath = normalize(filePath);
    for (final folder in folders.q) {
      for (final file in folder.files) {
        if (normalize(file.raw) == targetPath) return true;
      }
    }
    return false;
  }

  /// 加载指定本地模型文件并开始聊天；点击后立即收起模型选择面板，成功/失败在内部处理。
  Future<void> onStartLocalModelFileForChat(FileInfo fileInfo) async {
    if (P.remote.modelSelectorShown.q) {
      await pop();
    }
    await P.rwkvModel.startLocalModelForChat(fileInfo);
  }

  Future<void> onStartPthFileForChat(FileInfo fileInfo) async {
    await onStartLocalModelFileForChat(fileInfo);
  }

  Future<void> addFolder(PthFolderEntry entry) async {
    final accessibleEntry = await _startAccessingEntry(entry);
    if (_containsFolderPath(accessibleEntry.path)) return;
    final folder = Folder(path: accessibleEntry.path, state: FolderState.loading, files: const []);
    _folderEntries[accessibleEntry.path] = accessibleEntry;
    folders.q = [...folders.q, folder];
    refreshFolder(folder);
    await P.preference.addPthFolderEntry(accessibleEntry);
  }

  Future<void> removeFolder(Folder foler) async {
    if (Platform.isMacOS) {
      final entity = _macosScopedResources.remove(foler.path);
      if (entity != null) {
        try {
          await SecureBookmarks().stopAccessingSecurityScopedResource(entity);
        } catch (e) {
          qqw("Pth stopAccessing failed for ${foler.path}: $e");
        }
      }
      final entry = _folderEntries[foler.path];
      if (entry != null) {
        for (final fileEntry in entry.fileEntries) {
          final fileEntity = _macosFileScopedResources.remove(fileEntry.path);
          if (fileEntity == null) continue;
          try {
            await SecureBookmarks().stopAccessingSecurityScopedResource(fileEntity);
          } catch (e) {
            qqw("Pth file stopAccessing failed for ${fileEntry.path}: $e");
          }
        }
      }
    }
    _folderEntries.remove(foler.path);
    folders.q = folders.q.where((e) => e.path != foler.path).toList();
    await P.preference.removePthFolderEntry(foler.path);
  }

  Future<void> refreshFolder(Folder folder) async {
    folders.q = folders.q.map((e) => e.path == folder.path ? folder.copyWith(state: FolderState.loading) : e).toList();
    final entry = _folderEntries[folder.path];
    final directory = Directory(folder.path);
    if (!await directory.exists()) {
      final explicitFiles = await _fileInfosFromEntryFiles(entry);
      final state = explicitFiles.isEmpty ? FolderState.notfound : FolderState.loaded;
      folders.q = folders.q.map((e) => e.path == folder.path ? folder.copyWith(files: explicitFiles, state: state) : e).toList();
      return;
    }

    final computeFuture = compute<String, LocalModelDiscoveryResult>(
      discoverLocalModelFiles,
      folder.path,
      debugLabel: 'refreshFolder',
    );

    final waiting = await Future.wait<Object?>([
      computeFuture,
      Future.delayed(const Duration(seconds: 1)),
    ]);

    final discoveryResult = waiting.first! as LocalModelDiscoveryResult;
    final files = <FileInfo>[
      for (final file in discoveryResult.files) _fileInfoFromLocalModelFile(file),
    ];
    files.addAll(await _fileInfosFromEntryFiles(entry, existingFiles: files));
    final hasError = discoveryResult.hasError;

    final state = hasError && files.isEmpty ? FolderState.restricted : FolderState.loaded;
    final newFolder = folder.copyWith(files: files, state: state);
    folders.q = folders.q.map((e) => e.path == newFolder.path ? newFolder : e).toList();
  }

  Future<void> refreshAllFolders() async {
    await Future.wait(folders.q.map((e) => refreshFolder(e)));
  }

  Future<void> onDeleteFileClicked(Folder folder, FileInfo file) async {
    final res = await showOkCancelAlertDialog(
      context: getContext()!,
      title: S.current.confirm_delete_file_title,
      message: S.current.confirm_delete_file_message,
      isDestructiveAction: true,
    );
    if (res != OkCancelResult.ok) return;
    if (P.rwkvModel.allLoaded.q.keys.contains(file)) {
      await P.rwkvModel._releaseModelByWeightTypeIfNeeded(weightType: .chat);
    }
    await removeFile(folder, file);
  }

  Future<void> removeFile(Folder folder, FileInfo file) async {
    final newFiles = folder.files.where((e) => e.fileName != file.fileName).toList();
    final newFolder = folder.copyWith(files: newFiles);
    folders.q = folders.q.map((e) => e.path == newFolder.path ? newFolder : e).toList();
  }

  bool _containsFolderPath(String folderPath) {
    return folders.q.any((e) => _isSameFolderPath(e.path, folderPath));
  }

  Folder? _folderByPath(String folderPath) {
    return folders.q.firstWhereOrNull((e) => _isSameFolderPath(e.path, folderPath));
  }

  bool _isSameFolderPath(String a, String b) {
    return equals(normalize(a), normalize(b));
  }

  Future<PthFolderEntry?> _folderEntryFromDropItem(desktop_drop.DropItem item) async {
    final itemPath = item.path;
    if (itemPath.isEmpty) return null;
    if (item.fromPromise) return null;

    final droppedBookmark = _droppedAppleBookmark(item);
    final transientEntity = await _startAccessingDropItem(item, droppedBookmark);
    try {
      final type = await FileSystemEntity.type(itemPath, followLinks: true);
      if (type == FileSystemEntityType.directory) {
        return await _createFolderEntry(itemPath, fallbackBookmark: droppedBookmark);
      }

      if (type != FileSystemEntityType.file) return null;
      if (!isLocalModelFileExtension(itemPath)) return null;
      return PthFolderEntry(
        path: dirname(itemPath),
        fileEntries: [PthFileEntry(path: itemPath, bookmark: droppedBookmark)],
      );
    } finally {
      if (transientEntity != null) {
        await _stopAccessingTransientScopedResource(transientEntity);
      }
    }
  }

  String? _droppedAppleBookmark(desktop_drop.DropItem item) {
    if (!Platform.isMacOS) return null;
    final bookmark = item.extraAppleBookmark;
    if (bookmark == null || bookmark.isEmpty) return null;
    return base64Encode(bookmark);
  }

  Future<FileSystemEntity?> _startAccessingDropItem(desktop_drop.DropItem item, String? bookmark) async {
    if (!Platform.isMacOS) return null;
    if (bookmark == null || bookmark.isEmpty) return null;

    final isDirectory = item is desktop_drop.DropItemDirectory;
    return _startAccessingBookmark(bookmark, isDirectory: isDirectory, fallbackPath: item.path);
  }

  Future<void> _mergeFolderEntry(Folder existingFolder, PthFolderEntry incomingEntry) async {
    final existingEntry = _folderEntries[existingFolder.path] ?? PthFolderEntry(path: existingFolder.path);
    final entryWithBookmark = existingEntry.bookmark == null && incomingEntry.bookmark != null
        ? existingEntry.copyWith(bookmark: incomingEntry.bookmark)
        : existingEntry;
    final mergedEntry = entryWithBookmark.mergeFileEntries(incomingEntry.fileEntries);
    final accessibleEntry = await _startAccessingEntry(mergedEntry);
    _folderEntries[existingFolder.path] = accessibleEntry;
    await P.preference.removePthFolderEntry(existingFolder.path);
    await P.preference.addPthFolderEntry(accessibleEntry);
    await refreshFolder(existingFolder);
  }

  Future<List<FileInfo>> _fileInfosFromEntryFiles(PthFolderEntry? entry, {List<FileInfo> existingFiles = const []}) async {
    if (entry == null || entry.fileEntries.isEmpty) return const [];

    final files = <FileInfo>[];
    for (final fileEntry in entry.fileEntries) {
      if (existingFiles.any((e) => _isSameFolderPath(e.raw, fileEntry.path))) continue;
      final file = await discoverLocalModelFile(fileEntry.path);
      if (file == null) continue;
      files.add(_fileInfoFromLocalModelFile(file));
    }
    return files;
  }

  Future<FileSystemEntity?> _startAccessingBookmark(
    String bookmark, {
    required bool isDirectory,
    required String fallbackPath,
  }) async {
    if (!Platform.isMacOS) return null;

    try {
      final sb = SecureBookmarks();
      final entity = await sb.resolveBookmark(bookmark, isDirectory: isDirectory);
      final ok = await sb.startAccessingSecurityScopedResource(entity);
      if (ok) return entity;
      qqw("Pth startAccessing failed for $fallbackPath");
      return null;
    } catch (e) {
      qqw("Pth bookmark resolve failed for $fallbackPath: $e");
      return null;
    }
  }

  Future<void> _stopAccessingTransientScopedResource(FileSystemEntity entity) async {
    if (!Platform.isMacOS) return;

    try {
      await SecureBookmarks().stopAccessingSecurityScopedResource(entity);
    } catch (e) {
      qqw("Pth transient stopAccessing failed for ${entity.path}: $e");
    }
  }

  Future<PthFolderEntry> _startAccessingEntry(PthFolderEntry entry) async {
    final folderEntry = await _startAccessingFolderEntry(entry);
    for (final fileEntry in folderEntry.fileEntries) {
      await _startAccessingFileEntry(fileEntry);
    }
    return folderEntry;
  }

  Future<PthFolderEntry> _startAccessingFolderEntry(PthFolderEntry entry) async {
    final bookmark = entry.bookmark;
    if (bookmark == null || bookmark.isEmpty) return entry;

    final entity = await _startAccessingBookmark(bookmark, isDirectory: true, fallbackPath: entry.path);
    if (entity == null) return entry;

    _macosScopedResources[entity.path] = entity;
    if (entity.path == entry.path) return entry;
    return entry.copyWith(path: entity.path);
  }

  Future<void> _startAccessingFileEntry(PthFileEntry entry) async {
    final bookmark = entry.bookmark;
    if (bookmark == null || bookmark.isEmpty) return;
    if (_macosFileScopedResources.containsKey(entry.path)) return;

    final entity = await _startAccessingBookmark(bookmark, isDirectory: false, fallbackPath: entry.path);
    if (entity == null) return;
    _macosFileScopedResources[entry.path] = entity;
  }

  Future<PthFolderEntry> _createFolderEntry(String folderPath, {String? fallbackBookmark}) async {
    if (!Platform.isMacOS) return PthFolderEntry(path: folderPath, bookmark: null);
    if (fallbackBookmark != null && fallbackBookmark.isNotEmpty) {
      return PthFolderEntry(path: folderPath, bookmark: fallbackBookmark);
    }

    try {
      final sb = SecureBookmarks();
      final bookmark = await sb.bookmark(Directory(folderPath));
      return PthFolderEntry(path: folderPath, bookmark: bookmark);
    } catch (e) {
      qqw("Pth bookmark create failed for $folderPath: $e");
      return PthFolderEntry(path: folderPath, bookmark: null);
    }
  }
}
