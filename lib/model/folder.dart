import 'package:equatable/equatable.dart';
import 'package:zone/model/file_info.dart';

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
