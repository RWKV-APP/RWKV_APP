part of 'p.dart';

class _Pth {
  late final folders = qs<List<Folder>>([]);
}

/// Private methods
extension _$Pth on _Pth {
  FV _init() async {
    final paths = await P.preference.getPthFolderPaths();
    for (final path in paths) {
      final folder = Folder(path: path, state: FolderState.loading, files: []);
      folders.q = [...folders.q, folder];
      refreshFolder(folder);
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
    await addFolder(path);
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
    await launchUrl(Uri.directory(folder.path));
  }

  Future<void> addFolder(String path) async {
    final folder = Folder(path: path, state: FolderState.loading, files: []);
    folders.q = [...folders.q, folder];
    refreshFolder(folder);
    await P.preference.addPthFolderPath(path);
  }

  Future<void> removeFolder(Folder foler) async {
    folders.q = folders.q.where((e) => e.path != foler.path).toList();
    await P.preference.removePthFolderPath(foler.path);
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
        return (files.sorted((a, b) => a.fileSize.compareTo(b.fileSize)), false);
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
    );
    if (res != OkCancelResult.ok) return;
    await removeFile(folder, file);
  }

  Future<void> removeFile(Folder folder, FileInfo file) async {
    final newFiles = folder.files.where((e) => e.fileName != file.fileName).toList();
    final newFolder = folder.copyWith(files: newFiles);
    folders.q = folders.q.map((e) => e.path == newFolder.path ? newFolder : e).toList();
  }
}
