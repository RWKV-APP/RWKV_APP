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
      Alert.warning("该文件夹已添加");
      return;
    }
    await addFolder(path);
  }

  Future<void> onRemoveFolderClicked(Folder folder) async {
    if (folder.files.isNotEmpty) {
      final res = await showOkCancelAlertDialog(
        context: getContext()!,
        title: "确定要忘记该位置吗？",
        message: "忘记该位置后，该文件夹将不再显示在本地文件夹列表中",
      );
      if (res != OkCancelResult.ok) return;
    }
    await removeFolder(folder);
    Alert.success("忘记该位置成功");
  }

  Future<void> onRefreshFolderClicked(Folder folder) async {
    qq;
    await refreshFolder(folder);
    Alert.success("刷新完成");
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

    final computeFuture = compute<String, List<FileInfo>>(
      (String path) {
        final files = <FileInfo>[];
        for (final file in directory.listSync()) {
          final isTargetFile = file.path.endsWith('.pth');
          if (!isTargetFile) {
            continue;
          }
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
        return files.sorted((a, b) => a.fileSize.compareTo(b.fileSize));
      },
      folder.path,
      debugLabel: 'refreshFolder',
    );

    final waiting = await Future.wait([
      computeFuture,
      Future.delayed(const Duration(seconds: 1)),
    ]);

    final newFolder = folder.copyWith(files: waiting.first, state: FolderState.loaded);
    folders.q = folders.q.map((e) => e.path == newFolder.path ? newFolder : e).toList();
  }

  Future<void> refreshAllFolders() async {
    await Future.wait(folders.q.map((e) => refreshFolder(e)));
  }
}
