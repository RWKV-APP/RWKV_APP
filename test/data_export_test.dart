import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:zone/db/db.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/store/p.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('data export helpers', () {
    test('builds safe archive file names with debug marker', () {
      final fileName = buildDataExportArchiveFileName(
        archiveType: DataExportArchiveType.markdown,
        now: DateTime(2026, 5, 7, 8, 9, 1),
        socName: 'Snapdragon 8 Elite?',
        appVersion: '4.4.7',
        buildNumber: '721',
        engineVersion: 'abc/def-dirty',
        debug: true,
      );

      expect(fileName, 'rwkv_export_Snapdragon_8_Elite_4.4.7+721_abc_def-dirty_debug_20260507_080901_markdown.zip');
    });

    test('builds safe archive file names without debug marker', () {
      final fileName = buildDataExportArchiveFileName(
        archiveType: DataExportArchiveType.sqlite,
        now: DateTime(2026, 5, 7, 8, 9, 1),
        socName: 'sm8550',
        appVersion: '4.4.7',
        buildNumber: '721',
        engineVersion: 'abcdef',
        debug: false,
      );

      expect(fileName, 'rwkv_export_sm8550_4.4.7+721_abcdef_20260507_080901_sqlite.zip');
    });

    test('chooses markdown fences longer than message content backticks', () {
      final markdown = dataExportMarkdownCodeBlock('hello\n```dart\nprint(1);\n```');

      expect(markdown.startsWith('````\n'), isTrue);
      expect(markdown.endsWith('\n````'), isTrue);
    });

    test('keeps all branch messages in tree order', () {
      final root = MsgNode(0, createAtInUS: 100);
      final first = root.add(MsgNode(1, createAtInUS: 100));
      first.add(MsgNode(2, createAtInUS: 100), keepLatest: true);
      first.add(MsgNode(3, createAtInUS: 100), keepLatest: true);

      final nodeInfos = buildDataExportMessageNodeInfos(root);
      final orderedMessages = orderMessagesForDataExport(
        root,
        const <Message>[
          Message(id: 3, content: 'branch b', isMine: false, paused: false),
          Message(id: 1, content: 'prompt', isMine: true, paused: false),
          Message(id: 2, content: 'branch a', isMine: false, paused: false),
        ],
      );

      expect(nodeInfos.map((info) => info.id).toList(), const <int>[1, 2, 3]);
      expect(nodeInfos.map((info) => info.parentId).toList(), const <int?>[null, 1, 1]);
      expect(nodeInfos.map((info) => info.depth).toList(), const <int>[0, 1, 1]);
      expect(orderedMessages.map((message) => message.id).toList(), const <int>[1, 2, 3]);
    });
  });

  group('database export helpers', () {
    test('reads all conversations and writes an openable SQLite snapshot', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final tempDir = await Directory.systemTemp.createTemp('rwkv_export_test_');
      addTearDown(() async {
        await db.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final root = MsgNode(0, createAtInUS: 100);
      root.add(MsgNode(1, createAtInUS: 100)).add(MsgNode(2, createAtInUS: 100));
      await db.customStatement(
        "INSERT INTO conv (created_at_u_s, title, data, app_build_number) "
        "VALUES (100, 'Export test', ${_sqlText(root.toJson())}, '1')",
      );
      await db.customStatement(
        "INSERT INTO msg (id, content, is_mine, type, is_reasoning, paused, build) "
        "VALUES (1, 'hello', 1, 'text', 0, 0, '1')",
      );
      await db.customStatement(
        "INSERT INTO msg (id, content, is_mine, type, is_reasoning, paused, build) "
        "VALUES (2, 'hi', 0, 'text', 0, 0, '1')",
      );

      final conversations = await db.allConversationsForExport();
      final messages = await db.getMessagesByIds(const <int>{1, 2});
      final snapshotPath = path.join(tempDir.path, 'snapshot.sqlite');
      await db.exportSqliteSnapshot(snapshotPath);
      final snapshotDb = AppDatabase(NativeDatabase(File(snapshotPath)));
      addTearDown(snapshotDb.close);

      final snapshotConversations = await snapshotDb.allConversationsForExport();
      final snapshotMessages = await snapshotDb.getMessagesByIds(const <int>{1, 2});

      expect(conversations.map((conversation) => conversation.title).toList(), const <String>['Export test']);
      expect(messages.map((message) => message.content).toSet(), const <String>{'hello', 'hi'});
      expect(File(snapshotPath).existsSync(), isTrue);
      expect(snapshotConversations.map((conversation) => conversation.title).toList(), const <String>['Export test']);
      expect(snapshotMessages.map((message) => message.content).toSet(), const <String>{'hello', 'hi'});
    });
  });
}

String _sqlText(String value) {
  return "'${value.replaceAll("'", "''")}'";
}
