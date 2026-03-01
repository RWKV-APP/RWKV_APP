// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'package:zone/model/file_info.dart';

/// 持久化用的 pth 文件夹条目：路径 + 可选的 macOS security-scoped bookmark 数据。
class PthFolderEntry {
  const PthFolderEntry({required this.path, this.bookmark});

  final String path;
  final String? bookmark;

  Map<String, dynamic> toJson() => {'path': path, if (bookmark != null) 'bookmark': bookmark};

  static PthFolderEntry fromJson(Map<String, dynamic> json) => PthFolderEntry(
        path: json['path']! as String,
        bookmark: json['bookmark'] as String?,
      );
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
