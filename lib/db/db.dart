// ignore: unused_import
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zone/config.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/msg_node.dart';
import 'package:zone/state/p.dart';
import 'dart:convert';

import 'db.steps.dart';

part 'db.g.dart';

@DataClassName("ConversationData")
class _Conversation extends Table {
  @override
  Set<Column> get primaryKey => {createdAtUS};

  @override
  String? get tableName => "conv";

  IntColumn get createdAtUS => integer()();

  IntColumn get updatedAtUS => integer().nullable()();

  TextColumn get title => text().withDefault(const Constant("New Conversation"))();

  TextColumn get data => text()();

  TextColumn get appBuildNumber => text()();
}

@DataClassName("_MsgData")
class _Msg extends Table {
  @override
  Set<Column> get primaryKey => {id};

  @override
  String? get tableName => "msg";

  IntColumn get id => integer()();

  TextColumn get content => text()();

  TextColumn get reference => text().nullable()();

  BoolColumn get isMine => boolean()();

  TextColumn get type => text()();

  BoolColumn get isReasoning => boolean()();

  BoolColumn get paused => boolean()();

  TextColumn get imageUrl => text().nullable()();

  TextColumn get audioUrl => text().nullable()();

  IntColumn get audioLength => integer().nullable()();

  BoolColumn get isSensitive => boolean().withDefault(const Constant(false))();

  IntColumn get ttsCFMSteps => integer().nullable()();

  TextColumn get ttsTarget => text().nullable()();

  TextColumn get ttsSpeakerName => text().nullable()();

  TextColumn get ttsSourceAudioPath => text().nullable()();

  TextColumn get ttsInstruction => text().nullable()();

  RealColumn get ttsOverallProgress => real().nullable()();

  TextColumn get ttsPerWavProgress => text().nullable()();

  TextColumn get ttsFilePaths => text().nullable()();

  TextColumn get modelName => text().nullable()();

  TextColumn get runningMode => text().nullable()();

  TextColumn get build => text()();
}

@DriftDatabase(tables: [_Conversation, _Msg])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(schema.msg, schema.msg.reference);
        },
      ),
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'rwkv_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  // Convert Message to Msg data for insertion
  _MsgCompanion _messageToMsgCompanion(model.Message message) {
    return _MsgCompanion.insert(
      id: Value(message.id),
      content: message.content,
      isMine: message.isMine,
      type: message.type.name,
      isReasoning: message.isReasoning,
      paused: message.paused,
      reference: Value(message.reference.serialize()),
      imageUrl: Value(message.imageUrl),
      audioUrl: Value(message.audioUrl),
      audioLength: Value(message.audioLength),
      isSensitive: Value(message.isSensitive),
      ttsCFMSteps: Value(message.ttsCFMSteps),
      ttsTarget: Value(message.ttsTarget),
      ttsSpeakerName: Value(message.ttsSpeakerName),
      ttsSourceAudioPath: Value(message.ttsSourceAudioPath),
      ttsInstruction: Value(message.ttsInstruction),
      ttsOverallProgress: Value(message.ttsOverallProgress),
      ttsPerWavProgress: Value(message.ttsPerWavProgress != null ? json.encode(message.ttsPerWavProgress) : null),
      ttsFilePaths: Value(message.ttsFilePaths != null ? json.encode(message.ttsFilePaths) : null),
      modelName: Value(message.modelName),
      runningMode: Value(message.runningMode),
      build: P.app.buildNumber.q,
    );
  }

  Future<List<model.Message>> getMessagesByIds(Iterable<int> ids) async {
    final msgDataList = await (select(msg)..where((tbl) => tbl.id.isIn(ids))).get();
    return msgDataList.map((msgData) => _msgDataToMessage(msgData)).toList();
  }

  _ConversationCompanion _conversationToConversationCompanion(MsgNode msgNode, {required String title}) {
    return _ConversationCompanion.insert(
      createdAtUS: Value(msgNode.createAtInUS),
      title: Value(title),
      data: msgNode.toJson(),
      appBuildNumber: P.app.buildNumber.q,
      updatedAtUS: Value(HF.microseconds),
    );
  }

  /// 将 MsgNode 同步到数据库，使用 UPSERT 机制处理插入或更新。
  ///
  /// 1. 如果 msgNode.id == 0 且 children 为空，则不进行任何操作并返回 true。
  /// 2. 使用 msgNode.createAtInUS 作为冲突键，确保并发调用时的原子性。
  ///
  /// 参数:
  /// - msgNode: 要同步的消息节点树
  ///
  /// 返回值:
  /// - 如果操作成功（插入或更新），则返回 true；否则返回 false。
  Future<bool> upsertConv(MsgNode msgNode) async {
    final firstMsgId = msgNode.latestMsgIdsWithoutRoot.firstOrNull;

    late final String title;
    if (firstMsgId != null) {
      final firstMsg = P.msg.pool.q[firstMsgId];
      final firstMsgContent = firstMsg?.content ?? "";
      title = firstMsgContent.length > Config.maxTitleLength ? firstMsgContent.substring(0, Config.maxTitleLength) : firstMsgContent;
    } else {
      title = P.preference.currentLangIsZh ? "新会话" : "New Conversation";
    }

    final convData = _conversationToConversationCompanion(msgNode, title: title);

    qqr("msgNode.createAtInUS: ${msgNode.createAtInUS}");

    try {
      // 使用 Drift 的 insert 方法，并结合 onConflict 参数实现 UPSERT。
      // 如果主键唯一，则会触发 DoUpdate 策略
      final res = await into(conversation).insert(convData, onConflict: DoUpdate((old) => convData));
      qqr("upsert successful: insert result: $res");
      return true;
    } catch (e) {
      qqr("upsert failed: $e");
      return false;
    }
  }

  /// 根据会话的创建时间找到会话，并重命名会话，如果会话不存在，则返回 false
  Future<bool> renameConv(int createAtInUS, String title) async {
    final success =
        await (update(conversation)..where((tbl) {
              return tbl.createdAtUS.equals(createAtInUS);
            }))
            .write(
              _ConversationCompanion(
                title: Value(title),
                updatedAtUS: Value(HF.microseconds),
              ),
            ) >
        0;
    return success;
  }

  Future<bool> upsertMsg(model.Message message) async {
    final msgData = _messageToMsgCompanion(message);
    try {
      await into(msg).insert(msgData, onConflict: DoUpdate((old) => msgData));
      return true;
    } catch (e) {
      qqr("upsert failed: $e");
      return false;
    }
  }

  /// 1. 最近更新的(updatedAt)在最前面, 第二排序顺位是 createdAt
  /// 2. 如果 limit 为 null, 则返回所有
  /// 3. 如果 offset 为 null, 则从 0 开始
  /// 4. 如果 limit 和 offset 都为 null, 则返回所有
  /// 5. limit 默认为 20, offset 默认为 0
  Future<List<ConversationData>> convPage({
    int pageIndex = 0,
    int pageSize = 999,
  }) async {
    final query = select(conversation)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAtUS),
        (t) => OrderingTerm.desc(t.createdAtUS),
      ])
      ..limit(pageSize, offset: pageIndex * pageSize);

    return await query.get();
  }

  Future<ConversationData?> findConvByCreateAtInUS(int createAtInUS) async {
    final query = select(conversation)..where((tbl) => tbl.createdAtUS.equals(createAtInUS));
    final res = await query.getSingleOrNull();
    return res;
  }

  /// 根据 MsgNode.createAt 删除
  Future<bool> deleteConv(int createAtInUS) async {
    return await (delete(conversation)..where((tbl) => tbl.createdAtUS.equals(createAtInUS))).go() > 0;
  }

  Future<bool> deleteMsgsByCreateAtInUS(Iterable<int> ids) async {
    return await (delete(msg)..where((tbl) => tbl.id.isIn(ids))).go() > 0;
  }
}

model.Message _msgDataToMessage(_MsgData msgData) {
  List<double>? ttsPerWavProgress;
  if (msgData.ttsPerWavProgress != null && msgData.ttsPerWavProgress!.isNotEmpty) {
    final List<dynamic> parsed = json.decode(msgData.ttsPerWavProgress!);
    ttsPerWavProgress = parsed.cast<double>();
  }

  List<String>? ttsFilePaths;
  if (msgData.ttsFilePaths != null && msgData.ttsFilePaths!.isNotEmpty) {
    final List<dynamic> parsed = json.decode(msgData.ttsFilePaths!);
    ttsFilePaths = parsed.cast<String>();
  }

  return model.Message(
    id: msgData.id,
    content: msgData.content,
    isMine: msgData.isMine,
    changing: false,
    reference: model.RefInfo.deserialize(msgData.reference),
    type: model.MessageType.values.firstWhere((e) => e.name == msgData.type),
    imageUrl: msgData.imageUrl,
    audioUrl: msgData.audioUrl,
    audioLength: msgData.audioLength,
    isReasoning: msgData.isReasoning,
    paused: msgData.paused,
    ttsTarget: msgData.ttsTarget,
    ttsSpeakerName: msgData.ttsSpeakerName,
    ttsSourceAudioPath: msgData.ttsSourceAudioPath,
    ttsInstruction: msgData.ttsInstruction,
    ttsCFMSteps: msgData.ttsCFMSteps,
    isSensitive: msgData.isSensitive,
    ttsOverallProgress: msgData.ttsOverallProgress,
    ttsPerWavProgress: ttsPerWavProgress,
    ttsFilePaths: ttsFilePaths,
    modelName: msgData.modelName,
    runningMode: msgData.runningMode,
  );
}
