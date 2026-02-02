part of 'p.dart';

class _Pth {
  late final folders = qs<List<Folder>>([]);

  /// macOS：已通过 security-scoped bookmark 取得访问权限的目录，移除文件夹时需 stopAccessing
  final _macosScopedResources = <String, FileSystemEntity>{};
}

/// Private methods
extension _$Pth on _Pth {
  FV _init() async {
    if (!P.preference.hasUnlinkDefaultModelsDirOnce) {
      qqr("add default models dir to pth folder entries");
      final defaultModelsDir = P.remote.getDefaultModelsDir();
      if (defaultModelsDir != null) {
        await P.preference.addPthFolderEntry(PthFolderEntry(path: defaultModelsDir));
      } else {
        qqe("default models dir is null");
      }
    }

    await _atuoCreateModelsDir();
    final entries = await P.preference.getPthFolderEntries();
    for (final entry in entries) {
      String path = entry.path;
      if (Platform.isMacOS && entry.bookmark != null && entry.bookmark!.isNotEmpty) {
        try {
          final sb = SecureBookmarks();
          final entity = await sb.resolveBookmark(entry.bookmark!, isDirectory: true);
          final ok = await sb.startAccessingSecurityScopedResource(entity);
          if (ok) {
            _macosScopedResources[entity.path] = entity;
            path = entity.path;
          }
        } catch (e) {
          qqw("Pth bookmark resolve failed for ${entry.path}: $e");
        }
      }
      final folder = Folder(path: path, state: FolderState.loading, files: const []);
      folders.q = [...folders.q, folder];
      refreshFolder(folder);
    }
  }

  Future<void> _atuoCreateModelsDir() async {
    if (!Platform.isWindows) return;
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
    final path = await file_picker.FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    if (folders.q.any((e) => e.path == path)) {
      Alert.warning(S.current.folder_already_added);
      return;
    }
    PthFolderEntry entry;
    if (Platform.isMacOS) {
      try {
        final sb = SecureBookmarks();
        final bookmark = await sb.bookmark(Directory(path));
        entry = PthFolderEntry(path: path, bookmark: bookmark);
      } catch (e) {
        qqw("Pth bookmark create failed for $path: $e");
        entry = PthFolderEntry(path: path, bookmark: null);
      }
    } else {
      entry = PthFolderEntry(path: path, bookmark: null);
    }
    await addFolder(entry);
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

    if (folder.path == P.remote.getDefaultModelsDir()) {
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
    await openFolder(folder.path);
  }

  /// 加载指定 pth 文件并开始聊天；成功/失败与 pop 由 P.rwkv.startPthForChat 内部用 Alert 处理。
  Future<void> onStartPthFileForChat(FileInfo fileInfo) async {
    await P.rwkv.startPthForChat(fileInfo);
  }

  Future<void> addFolder(PthFolderEntry entry) async {
    final folder = Folder(path: entry.path, state: FolderState.loading, files: const []);
    folders.q = [...folders.q, folder];
    refreshFolder(folder);
    await P.preference.addPthFolderEntry(entry);
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
    }
    folders.q = folders.q.where((e) => e.path != foler.path).toList();
    await P.preference.removePthFolderEntry(foler.path);
  }

  Future<void> refreshFolder(Folder folder) async {
    folders.q = folders.q.map((e) => e.path == folder.path ? folder.copyWith(state: FolderState.loading) : e).toList();
    final directory = Directory(folder.path);
    if (!await directory.exists()) {
      folders.q = folders.q.map((e) => e.path == folder.path ? folder.copyWith(state: FolderState.notfound) : e).toList();
      return;
    }

    final computeFuture = compute<String, (List<FileInfo>, bool hasError)>(
      (String path) {
        final files = <FileInfo>[];
        late final List<File> pthFiles;
        try {
          pthFiles = directory.listSync().where((e) => e is File && e.path.endsWith('.pth')).cast<File>().toList();
        } catch (e) {
          qqe("Error listing files: $e");
          pthFiles = [];
          return (files, true);
        }
        for (final file in pthFiles) {
          final fileInfo = FileInfo(
            fileName: basename(file.path),
            name: basename(file.path),
            fileSize: file.statSync().size,
            fileType: FileType.weights,
            raw: file.path,
            isDebug: false,
            backend: Backend.webRwkv,
            sha256: null,
            modelSize: null,
            quantization: null,
            updatedAt: null,
            timestamp: null,
            date: null,
            fromPthFile: true,
          );
          files.add(fileInfo);
        }
        return (files.sorted((a, b) => b.fileSize.compareTo(a.fileSize)), false);
      },
      folder.path,
      debugLabel: 'refreshFolder',
    );

    final waiting = await Future.wait([
      computeFuture,
      Future.delayed(const Duration(seconds: 1)),
    ]);

    final (files, hasError) = waiting.first;

    final newFolder = folder.copyWith(files: files, state: hasError ? FolderState.restricted : FolderState.loaded);
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
    if (P.rwkv.loadedModels.q.keys.contains(file)) {
      await P.rwkv._releaseModelByWeightTypeIfNeeded(weightType: .chat);
    }
    await removeFile(folder, file);
  }

  Future<void> removeFile(Folder folder, FileInfo file) async {
    final newFiles = folder.files.where((e) => e.fileName != file.fileName).toList();
    final newFolder = folder.copyWith(files: newFiles);
    folders.q = folders.q.map((e) => e.path == newFolder.path ? newFolder : e).toList();
  }
}
