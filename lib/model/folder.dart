// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'package:zone/model/file_info.dart';

class PthFileEntry {
  const PthFileEntry({required this.path, this.bookmark});

  final String path;
  final String? bookmark;

  Map<String, dynamic> toJson() => {'path': path, if (bookmark != null) 'bookmark': bookmark};

  static PthFileEntry fromJson(Map<String, dynamic> json) => PthFileEntry(
    path: json['path']! as String,
    bookmark: json['bookmark'] as String?,
  );
}

/// 持久化用的 pth 文件夹条目：路径 + 可选的 macOS security-scoped bookmark 数据。
class PthFolderEntry {
  const PthFolderEntry({required this.path, this.bookmark, this.fileEntries = const []});

  final String path;
  final String? bookmark;
  final List<PthFileEntry> fileEntries;

  Map<String, dynamic> toJson() => {
    'path': path,
    if (bookmark != null) 'bookmark': bookmark,
    if (fileEntries.isNotEmpty) 'files': fileEntries.map((e) => e.toJson()).toList(),
  };

  static PthFolderEntry fromJson(Map<String, dynamic> json) => PthFolderEntry(
    path: json['path']! as String,
    bookmark: json['bookmark'] as String?,
    fileEntries: ((json['files'] as List<dynamic>?) ?? const []).map((e) => PthFileEntry.fromJson(e as Map<String, dynamic>)).toList(),
  );

  PthFolderEntry copyWith({
    String? path,
    String? bookmark,
    List<PthFileEntry>? fileEntries,
  }) {
    return PthFolderEntry(
      path: path ?? this.path,
      bookmark: bookmark ?? this.bookmark,
      fileEntries: fileEntries ?? this.fileEntries,
    );
  }

  PthFolderEntry mergeFileEntries(List<PthFileEntry> entries) {
    if (entries.isEmpty) return this;

    final merged = [...fileEntries];
    for (final entry in entries) {
      if (merged.any((e) => e.path == entry.path)) continue;
      merged.add(entry);
    }
    return copyWith(fileEntries: merged);
  }
}

enum FolderState {
  loading,
  loaded,
  notfound,
  restricted,
}

class Folder extends Equatable {
  final String path;
  final FolderState state;
  final List<FileInfo> files;

  const Folder({
    required this.path,
    required this.state,
    required this.files,
  });

  @override
  List<Object?> get props => [path, state, ...files];

  Folder copyWith({
    String? path,
    FolderState? state,
    List<FileInfo>? files,
  }) {
    return Folder(
      path: path ?? this.path,
      state: state ?? this.state,
      files: files ?? this.files,
    );
  }
}
