import 'package:drift/drift.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/state/p.dart';
import 'dart:convert';
import '../model/message.dart';

part 'db.g.dart';

class Conversation extends Table {
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get title => text().named('New Conversation')();
  TextColumn get data => text()();

  TextColumn get build => text()();
}

class Msg extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  BoolColumn get isMine => boolean()();
  BoolColumn get changing => boolean().withDefault(const Constant(false))();
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

@DriftDatabase(tables: [Conversation, Msg])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  // Convert Message to Msg data for insertion
  MsgCompanion _messageToMsgCompanion(Message message) {
    return MsgCompanion.insert(
      id: Value(message.id),
      content: message.content,
      isMine: message.isMine,
      changing: Value(false),
      type: message.type.name,
      isReasoning: message.isReasoning,
      paused: message.paused,
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
      build: '', // Set appropriate value for build field
    );
  }

  Future<bool> saveMessage(Message message) async {
    return await into(msg).insert(_messageToMsgCompanion(message)) > 0;
  }

  Future<bool> updateMessage(Message message) async {
    return await (update(msg)..where((tbl) => tbl.id.equals(message.id))).write(_messageToMsgCompanion(message)) > 0;
  }

  Future<bool> deleteMessage(int id) async {
    return await (delete(msg)..where((tbl) => tbl.id.equals(id))).go() > 0;
  }

  Future<List<Message>> getAllMessages() async {
    final msgDataList = await select(msg).get();
    return msgDataList.map((msgData) => Message.fromMsgData(msgData)).toList();
  }

  Future<Message?> getMessageById(int id) async {
    final msgData = await (select(msg)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return msgData != null ? Message.fromMsgData(msgData) : null;
  }

  Future<List<Message>> getMessagesByIds(List<int> ids) async {
    final msgDataList = await (select(msg)..where((tbl) => tbl.id.isIn(ids))).get();
    return msgDataList.map((msgData) => Message.fromMsgData(msgData)).toList();
  }

  ConversationCompanion _conversationToConversationCompanion(MsgNode msgNode) {
    return ConversationCompanion.insert(
      title: msgNode.toJson(),
      data: msgNode.toJson(),
      build: P.app.buildNumber.q,
    );
  }

  Future<List<MsgNode>> getConversations() async {
    final conversationDataList = await select(conversation).get();
    return conversationDataList.map((conversationData) => MsgNode.fromJson(conversationData.data)).toList();
  }

  Future<MsgNode?> getConversationById(int id) async {
    return null;
    // TODO: 为 MsgNode 实现 greateAt 方法, 然后根据 createdAt 查询
    final conversationData = await (select(conversation)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return conversationData != null ? MsgNode.fromJson(conversationData.data) : null;
  }

  Future<bool> saveConversation(MsgNode msgNode) async {
    return await into(conversation).insert(_conversationToConversationCompanion(msgNode)) > 0;
  }

  Future<bool> updateConversation(MsgNode msgNode) async {
    return false;
    // TODO: 为 MsgNode 实现 greateAt 方法, 然后根据 createdAt 查询
    // return await (update(
    //       conversation,
    //     )..where((tbl) => tbl.createdAt.equals(msgNode.createdAt))).write(_conversationToConversationCompanion(msgNode)) >
    //     0;
  }
}
