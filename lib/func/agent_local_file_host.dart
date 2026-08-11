// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:path/path.dart' as p;

// Project imports:
import 'package:zone/model/agent.dart';

enum AgentLocalFileOperation {
  create,
  update,
  delete,
}

final class AgentLocalFileApproval {
  final AgentLocalFileOperation operation;
  final String relativePath;
  final String? content;

  const AgentLocalFileApproval({
    required this.operation,
    required this.relativePath,
    this.content,
  });
}

typedef AgentLocalFileApprovalCallback =
    Future<bool> Function(
      AgentLocalFileApproval approval,
    );

final class AgentLocalFileHost implements AgentToolHost {
  static const int maxFileBytes = 1_000_000;
  static const int maxDirectoryEntries = 512;

  final String workspacePath;
  final String _canonicalWorkspacePath;
  final AgentLocalFileApprovalCallback requestApproval;

  AgentLocalFileHost._({
    required this.workspacePath,
    required this._canonicalWorkspacePath,
    required this.requestApproval,
  });

  static Future<AgentLocalFileHost> create({
    required String workspacePath,
    required AgentLocalFileApprovalCallback requestApproval,
  }) async {
    final directory = Directory(p.normalize(p.absolute(workspacePath)));
    if (!await directory.exists()) {
      throw ArgumentError.value(
        workspacePath,
        "workspacePath",
        "Authorized workspace does not exist",
      );
    }
    final canonicalWorkspacePath = p.normalize(
      await directory.resolveSymbolicLinks(),
    );
    return AgentLocalFileHost._(
      workspacePath: directory.path,
      canonicalWorkspacePath: canonicalWorkspacePath,
      requestApproval: requestApproval,
    );
  }

  static const List<AgentToolDefinition> toolDefinitions = <AgentToolDefinition>[
    AgentToolDefinition(
      name: "list_files",
      description:
          "List real files and directories inside the user-authorized workspace. Use only relative paths; use '.' for the workspace root.",
      parameters: <String, Object?>{
        "type": "object",
        "properties": <String, Object?>{
          "path": <String, Object?>{"type": "string"},
        },
        "required": <String>["path"],
        "additionalProperties": false,
      },
    ),
    AgentToolDefinition(
      name: "read_file",
      description: "Read one real UTF-8 text file inside the user-authorized workspace. Use a relative path.",
      parameters: <String, Object?>{
        "type": "object",
        "properties": <String, Object?>{
          "path": <String, Object?>{"type": "string"},
        },
        "required": <String>["path"],
        "additionalProperties": false,
      },
    ),
    AgentToolDefinition(
      name: "write_file",
      description:
          "Create or replace one real UTF-8 text file inside the user-authorized workspace. The user must approve the exact mutation.",
      parameters: <String, Object?>{
        "type": "object",
        "properties": <String, Object?>{
          "path": <String, Object?>{"type": "string"},
          "content": <String, Object?>{"type": "string"},
        },
        "required": <String>["path", "content"],
        "additionalProperties": false,
      },
    ),
    AgentToolDefinition(
      name: "delete_file",
      description:
          "Permanently delete one real file inside the user-authorized workspace. Directories cannot be deleted. The user must approve.",
      parameters: <String, Object?>{
        "type": "object",
        "properties": <String, Object?>{
          "path": <String, Object?>{"type": "string"},
        },
        "required": <String>["path"],
        "additionalProperties": false,
      },
    ),
    AgentToolDefinition(
      name: "submit",
      description: "Submit a concise truthful result after the requested real-file work is complete.",
      parameters: <String, Object?>{
        "type": "object",
        "properties": <String, Object?>{
          "answer": <String, Object?>{"type": "string"},
        },
        "required": <String>["answer"],
        "additionalProperties": false,
      },
    ),
  ];

  @override
  List<AgentToolDefinition> get tools {
    return toolDefinitions;
  }

  @override
  Future<AgentToolResult> call(AgentToolCall call) async {
    try {
      final validationError = _validateArguments(call);
      if (validationError != null) {
        return _result(call, "ERROR: $validationError");
      }

      final content = switch (call.name) {
        "list_files" => await _listFiles(call.arguments),
        "read_file" => await _readFile(call.arguments),
        "write_file" => await _writeFile(call.arguments),
        "delete_file" => await _deleteFile(call.arguments),
        "submit" => "ok: submitted",
        _ => "ERROR: unknown or unavailable tool '${call.name}'",
      };
      return _result(call, content);
    } on FileSystemException catch (error) {
      return _result(call, "ERROR: ${error.message}");
    } on FormatException catch (error) {
      return _result(call, "ERROR: ${error.message}");
    } on _AgentLocalFileException catch (error) {
      return _result(call, "ERROR: ${error.message}");
    }
  }

  String? _validateArguments(AgentToolCall call) {
    AgentToolDefinition? definition;
    for (final candidate in toolDefinitions) {
      if (candidate.name != call.name) continue;
      definition = candidate;
      break;
    }
    if (definition == null) return "unknown or unavailable tool '${call.name}'";

    final properties = definition.parameters["properties"];
    if (properties is! Map) return "invalid tool schema";
    for (final key in call.arguments.keys) {
      if (properties.containsKey(key)) continue;
      return "unexpected argument '$key'";
    }

    final required = definition.parameters["required"];
    if (required is! List) return null;
    for (final key in required) {
      if (key is! String) continue;
      if (call.arguments.containsKey(key)) continue;
      return "missing required argument '$key'";
    }
    return null;
  }

  Future<String> _listFiles(AgentJson arguments) async {
    final rawPath = _stringArgument(arguments, "path");
    final resolved = await _resolveDirectory(rawPath);
    final entries = await Directory(resolved.absolutePath)
        .list(
          followLinks: false,
        )
        .take(maxDirectoryEntries + 1)
        .toList();
    entries.sort((first, second) => first.path.compareTo(second.path));
    if (entries.length > maxDirectoryEntries) {
      throw const _AgentLocalFileException(
        "directory contains more than 512 entries",
      );
    }

    final output = <String>[];
    for (final entry in entries) {
      final type = await FileSystemEntity.type(entry.path, followLinks: false);
      final name = p.basename(entry.path);
      if (type == .directory) {
        output.add("directory $name/");
        continue;
      }
      if (type == .file) {
        final length = await File(entry.path).length();
        output.add("file $name ($length bytes)");
        continue;
      }
      if (type == .link) {
        output.add("link $name");
      }
    }
    if (output.isEmpty) return "(empty directory)";
    return output.join("\n");
  }

  Future<String> _readFile(AgentJson arguments) async {
    final rawPath = _stringArgument(arguments, "path");
    final resolved = await _resolveFile(rawPath, mustExist: true);
    final content = await _readUtf8File(resolved.absolutePath);
    return content;
  }

  Future<String> _writeFile(AgentJson arguments) async {
    final rawPath = _stringArgument(arguments, "path");
    final content = _stringArgument(arguments, "content");
    final encoded = utf8.encode(content);
    if (encoded.length > maxFileBytes) {
      throw const _AgentLocalFileException(
        "content exceeds the 1000000-byte text-file limit",
      );
    }

    final before = await _resolveFile(rawPath, mustExist: false);
    final operation = before.exists ? AgentLocalFileOperation.update : AgentLocalFileOperation.create;
    final approved = await requestApproval(
      AgentLocalFileApproval(
        operation: operation,
        relativePath: before.relativePath,
        content: content,
      ),
    );
    if (!approved) return "ERROR: user rejected ${operation.name} for ${before.relativePath}";

    final afterApproval = await _resolveFile(rawPath, mustExist: false);
    if (afterApproval.exists != before.exists) {
      throw const _AgentLocalFileException(
        "file state changed while approval was pending; retry the action",
      );
    }

    await File(afterApproval.absolutePath).writeAsString(
      content,
      encoding: utf8,
      flush: true,
    );
    final verified = await _readUtf8File(afterApproval.absolutePath);
    if (verified != content) {
      throw const _AgentLocalFileException(
        "write verification failed because the stored content differs",
      );
    }
    return "ok: ${operation.name}d ${afterApproval.relativePath}; exact UTF-8 content verified";
  }

  Future<String> _deleteFile(AgentJson arguments) async {
    final rawPath = _stringArgument(arguments, "path");
    final before = await _resolveFile(rawPath, mustExist: true);
    final approved = await requestApproval(
      AgentLocalFileApproval(
        operation: .delete,
        relativePath: before.relativePath,
      ),
    );
    if (!approved) return "ERROR: user rejected delete for ${before.relativePath}";

    final afterApproval = await _resolveFile(rawPath, mustExist: true);
    await File(afterApproval.absolutePath).delete();
    final type = await FileSystemEntity.type(
      afterApproval.absolutePath,
      followLinks: false,
    );
    if (type != .notFound) {
      throw const _AgentLocalFileException(
        "delete verification failed because the file still exists",
      );
    }
    return "ok: deleted ${afterApproval.relativePath}; absence verified";
  }

  Future<String> _readUtf8File(String absolutePath) async {
    final file = File(absolutePath);
    final length = await file.length();
    if (length > maxFileBytes) {
      throw const _AgentLocalFileException(
        "file exceeds the 1000000-byte text-file limit",
      );
    }
    final bytes = await file.readAsBytes();
    return utf8.decode(bytes, allowMalformed: false);
  }

  Future<_ResolvedLocalFile> _resolveFile(
    String rawPath, {
    required bool mustExist,
  }) async {
    final relativePath = _normalizeRelativePath(rawPath, allowRoot: false);
    final lexicalPath = p.normalize(
      p.join(_canonicalWorkspacePath, relativePath),
    );
    if (!_isInsideWorkspace(lexicalPath)) {
      throw const _AgentLocalFileException(
        "path resolves outside the authorized workspace",
      );
    }

    final parent = Directory(p.dirname(lexicalPath));
    if (!await parent.exists()) {
      throw const _AgentLocalFileException(
        "parent directory does not exist",
      );
    }
    final canonicalParent = p.normalize(
      await parent.resolveSymbolicLinks(),
    );
    if (!_isInsideWorkspace(canonicalParent, includeRoot: true)) {
      throw const _AgentLocalFileException(
        "parent directory resolves outside the authorized workspace",
      );
    }

    final candidatePath = p.normalize(
      p.join(canonicalParent, p.basename(lexicalPath)),
    );
    final type = await FileSystemEntity.type(
      candidatePath,
      followLinks: false,
    );
    if (type == .link) {
      throw const _AgentLocalFileException(
        "symbolic links cannot be used as files",
      );
    }
    if (type == .directory) {
      throw const _AgentLocalFileException(
        "path identifies a directory, not a file",
      );
    }
    if (type == .notFound) {
      if (mustExist) {
        throw const _AgentLocalFileException("file does not exist");
      }
      return _ResolvedLocalFile(
        relativePath: relativePath,
        absolutePath: candidatePath,
        exists: false,
      );
    }
    if (type != .file) {
      throw const _AgentLocalFileException(
        "path is not a regular file",
      );
    }

    final canonicalFile = p.normalize(
      await File(candidatePath).resolveSymbolicLinks(),
    );
    if (!_isInsideWorkspace(canonicalFile)) {
      throw const _AgentLocalFileException(
        "file resolves outside the authorized workspace",
      );
    }
    return _ResolvedLocalFile(
      relativePath: relativePath,
      absolutePath: canonicalFile,
      exists: true,
    );
  }

  Future<_ResolvedLocalDirectory> _resolveDirectory(String rawPath) async {
    final relativePath = _normalizeRelativePath(rawPath, allowRoot: true);
    final lexicalPath = relativePath == "." ? _canonicalWorkspacePath : p.normalize(p.join(_canonicalWorkspacePath, relativePath));
    if (!_isInsideWorkspace(lexicalPath, includeRoot: true)) {
      throw const _AgentLocalFileException(
        "directory resolves outside the authorized workspace",
      );
    }
    final directory = Directory(lexicalPath);
    if (!await directory.exists()) {
      throw const _AgentLocalFileException(
        "directory does not exist",
      );
    }
    final canonicalDirectory = p.normalize(
      await directory.resolveSymbolicLinks(),
    );
    if (!_isInsideWorkspace(canonicalDirectory, includeRoot: true)) {
      throw const _AgentLocalFileException(
        "directory link resolves outside the authorized workspace",
      );
    }
    return _ResolvedLocalDirectory(
      relativePath: relativePath,
      absolutePath: canonicalDirectory,
    );
  }

  String _normalizeRelativePath(
    String rawPath, {
    required bool allowRoot,
  }) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      throw const _AgentLocalFileException("path must not be empty");
    }
    if (p.isAbsolute(trimmed) || RegExp(r"^[a-zA-Z]:[\\/]").hasMatch(trimmed)) {
      throw const _AgentLocalFileException(
        "absolute paths are not allowed",
      );
    }
    final parts = trimmed.replaceAll("\\", "/").split("/");
    for (final part in parts) {
      if (part != "..") continue;
      throw const _AgentLocalFileException(
        "parent path segments are not allowed",
      );
    }
    final normalized = p.normalize(trimmed.replaceAll("\\", p.separator));
    if (normalized == ".") {
      if (allowRoot) return ".";
      throw const _AgentLocalFileException(
        "a file path is required",
      );
    }
    return normalized;
  }

  bool _isInsideWorkspace(
    String candidatePath, {
    bool includeRoot = false,
  }) {
    final root = p.normalize(_canonicalWorkspacePath);
    final candidate = p.normalize(candidatePath);
    final comparableRoot = Platform.isWindows ? root.toLowerCase() : root;
    final comparableCandidate = Platform.isWindows ? candidate.toLowerCase() : candidate;
    if (includeRoot && comparableCandidate == comparableRoot) return true;
    return p.isWithin(comparableRoot, comparableCandidate);
  }

  String _stringArgument(AgentJson arguments, String key) {
    final value = arguments[key];
    if (value is String) return value;
    throw _AgentLocalFileException(
      "$key must be a string",
    );
  }

  AgentToolResult _result(AgentToolCall call, String content) {
    return AgentToolResult(
      callId: call.id,
      toolName: call.name,
      content: content,
      isError: content.startsWith("ERROR:"),
    );
  }
}

final class _ResolvedLocalFile {
  final String relativePath;
  final String absolutePath;
  final bool exists;

  const _ResolvedLocalFile({
    required this.relativePath,
    required this.absolutePath,
    required this.exists,
  });
}

final class _ResolvedLocalDirectory {
  final String relativePath;
  final String absolutePath;

  const _ResolvedLocalDirectory({
    required this.relativePath,
    required this.absolutePath,
  });
}

final class _AgentLocalFileException implements Exception {
  final String message;

  const _AgentLocalFileException(this.message);

  @override
  String toString() {
    return message;
  }
}
