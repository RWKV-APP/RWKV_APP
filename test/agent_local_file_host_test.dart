// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/func/agent_local_file_host.dart';
import 'package:zone/model/agent.dart';

void main() {
  group("AgentLocalFileHost", () {
    late Directory workspace;

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp(
        "rwkv-agent-local-file-",
      );
    });

    tearDown(() async {
      if (!await workspace.exists()) return;
      await workspace.delete(recursive: true);
    });

    test("creates, reads, updates, lists, and deletes a real text file", () async {
      final approvals = <AgentLocalFileApproval>[];
      final host = await AgentLocalFileHost.create(
        workspacePath: workspace.path,
        requestApproval: (approval) async {
          approvals.add(approval);
          return true;
        },
      );

      final createResult = await _call(
        host,
        "write_file",
        <String, Object?>{
          "path": "sample.txt",
          "content": "first",
        },
      );
      expect(createResult.isError, isFalse);
      expect(createResult.content, contains("created sample.txt"));
      expect(
        await File("${workspace.path}${Platform.pathSeparator}sample.txt").readAsString(),
        "first",
      );

      final readResult = await _call(
        host,
        "read_file",
        <String, Object?>{"path": "sample.txt"},
      );
      expect(readResult.content, "first");

      final updateResult = await _call(
        host,
        "write_file",
        <String, Object?>{
          "path": "sample.txt",
          "content": "second",
        },
      );
      expect(updateResult.isError, isFalse);
      expect(updateResult.content, contains("updated sample.txt"));

      final listResult = await _call(
        host,
        "list_files",
        <String, Object?>{"path": "."},
      );
      expect(listResult.content, contains("file sample.txt"));

      final deleteResult = await _call(
        host,
        "delete_file",
        <String, Object?>{"path": "sample.txt"},
      );
      expect(deleteResult.isError, isFalse);
      expect(deleteResult.content, contains("absence verified"));
      expect(
        await File("${workspace.path}${Platform.pathSeparator}sample.txt").exists(),
        isFalse,
      );

      expect(
        approvals.map((approval) => approval.operation).toList(),
        <AgentLocalFileOperation>[
          .create,
          .update,
          .delete,
        ],
      );
    });

    test("rejected mutation leaves the real file unchanged", () async {
      final target = File(
        "${workspace.path}${Platform.pathSeparator}sample.txt",
      );
      await target.writeAsString("original");
      final host = await AgentLocalFileHost.create(
        workspacePath: workspace.path,
        requestApproval: (approval) async {
          return false;
        },
      );

      final result = await _call(
        host,
        "write_file",
        <String, Object?>{
          "path": "sample.txt",
          "content": "changed",
        },
      );

      expect(result.isError, isTrue);
      expect(result.content, contains("user rejected update"));
      expect(await target.readAsString(), "original");
    });

    test("rejects absolute paths and parent traversal", () async {
      final host = await AgentLocalFileHost.create(
        workspacePath: workspace.path,
        requestApproval: (approval) async {
          return true;
        },
      );

      final absoluteResult = await _call(
        host,
        "read_file",
        <String, Object?>{"path": pAbsoluteTestPath()},
      );
      final traversalResult = await _call(
        host,
        "write_file",
        <String, Object?>{
          "path": "../outside.txt",
          "content": "blocked",
        },
      );

      expect(absoluteResult.isError, isTrue);
      expect(absoluteResult.content, contains("absolute paths are not allowed"));
      expect(traversalResult.isError, isTrue);
      expect(
        traversalResult.content,
        contains("parent path segments are not allowed"),
      );
    });

    test("never deletes a directory", () async {
      final directory = Directory(
        "${workspace.path}${Platform.pathSeparator}nested",
      );
      await directory.create();
      final host = await AgentLocalFileHost.create(
        workspacePath: workspace.path,
        requestApproval: (approval) async {
          return true;
        },
      );

      final result = await _call(
        host,
        "delete_file",
        <String, Object?>{"path": "nested"},
      );

      expect(result.isError, isTrue);
      expect(result.content, contains("directory, not a file"));
      expect(await directory.exists(), isTrue);
    });
  });
}

String pAbsoluteTestPath() {
  if (Platform.isWindows) return r"C:\outside.txt";
  return "/tmp/outside.txt";
}

Future<AgentToolResult> _call(
  AgentLocalFileHost host,
  String name,
  AgentJson arguments,
) {
  return host.call(
    AgentToolCall(
      id: "test",
      name: name,
      arguments: arguments,
      raw: "",
    ),
  );
}
