// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/db/db.steps.dart';
import 'package:zone/func/conversation_subtitle.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/message_type.dart' as model;
import 'package:zone/model/msg_node.dart';
import 'package:zone/model/ref_info.dart' as model;
import 'package:zone/store/p.dart';

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

  TextColumn get subtitle => text().nullable()();

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

  TextColumn get modelName => text().nullable()();

  TextColumn get runningMode => text().nullable()();

  TextColumn get build => text()();

  TextColumn get rawDecodeParams => text().nullable()();

  TextColumn get batchSlotLabels => text().nullable()();

  RealColumn get prefillSpeed => real().nullable()();

  RealColumn get decodeSpeed => real().nullable()();

  IntColumn get messageTokensCount => integer().nullable()();

  IntColumn get conversationTokensCount => integer().nullable()();
}

class _ConversationTitleRepairCandidate {
  final int createdAtUS;
  final int firstMsgId;
  final String title;

  const _ConversationTitleRepairCandidate({
    required this.createdAtUS,
    required this.firstMsgId,
    required this.title,
  });
}

class _ConversationSubtitleRepairCandidate {
  final int createdAtUS;
  final int botMsgId;

  const _ConversationSubtitleRepairCandidate({
    required this.createdAtUS,
    required this.botMsgId,
  });
}

@DriftDatabase(tables: [_Conversation, _Msg])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static const databaseFileName = 'rwkv_db.sqlite';

  bool _didRepairLegacyConversationTitles = false;

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(schema.msg, schema.msg.reference);
        },
        from2To3: (m, schema) async {
          await m.addColumn(schema.conv, schema.conv.subtitle);
        },
        from3To4: (m, schema) async {
          await m.addColumn(schema.msg, schema.msg.rawDecodeParams);
        },
        from4To5: (m, schema) async {
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(schema.msg));
        },
        from5To6: (m, schema) async {
          await m.addColumn(schema.msg, schema.msg.prefillSpeed);
          await m.addColumn(schema.msg, schema.msg.decodeSpeed);
        },
        from6To7: (m, schema) async {
          await m.addColumn(schema.msg, schema.msg.messageTokensCount);
          await m.addColumn(schema.msg, schema.msg.conversationTokensCount);
        },
        from7To8: (m, schema) async {
          await m.addColumn(schema.msg, schema.msg.batchSlotLabels);
        },
      ),
      beforeOpen: (details) async {
        if (!details.hadUpgrade) {
          return;
        }
        if (details.versionNow == 3) {
          final conversations = await select(conversation).get();
          for (final conv in conversations) {
            if (conv.subtitle != null && conv.subtitle!.isNotEmpty) {
              continue;
            }
            final msgNode = MsgNode.fromJson(conv.data, createAtInUS: conv.createdAtUS);
            final ids = msgNode.latestMsgIdsWithoutRoot;
            final id = ids.length >= 2 ? ids[1] : null;
            if (id == null) {
              continue;
            }
            final m = await (select(msg)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
            if (m == null) {
              continue;
            }
            final subtitle = buildConversationSubtitleFromResponseContent(m.content);
            if (subtitle.isEmpty) {
              continue;
            }
            await updateConv(conv.createdAtUS, subtitle: subtitle);
          }
        }
      },
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
      modelName: Value(message.modelName),
      runningMode: Value(message.runningMode),
      build: P.app.buildNumber.q,
      rawDecodeParams: Value(message.rawDecodeParams),
      batchSlotLabels: Value(message.batchSlotLabels == null ? null : jsonEncode(message.batchSlotLabels)),
      prefillSpeed: Value(message.prefillSpeed),
      decodeSpeed: Value(message.decodeSpeed),
      messageTokensCount: Value(message.messageTokensCount),
      conversationTokensCount: Value(message.conversationTokensCount),
    );
  }

  Future<List<model.Message>> getMessagesByIds(Iterable<int> ids) async {
    final msgDataList = await (select(msg)..where((tbl) => tbl.id.isIn(ids))).get();
    return msgDataList.map((msgData) => _msgDataToMessage(msgData)).toList();
  }

  String _stripUserMsgModifier(String text) {
    final String separator = Config.userMsgModifierSep;
    String processed = text.split(separator).first.trimRight();
    if (processed.isEmpty) {
      return processed;
    }

    final partialPrefixes = List<String>.generate(
      separator.length - 1,
      (int index) => separator.substring(0, separator.length - 1 - index),
    );

    for (final partialPrefix in partialPrefixes) {
      if (!processed.endsWith(partialPrefix)) {
        continue;
      }
      return processed.substring(0, processed.length - partialPrefix.length).trimRight();
    }
    return processed;
  }

  String _buildConversationTitle(String rawContent) {
    final withoutModifier = _stripUserMsgModifier(rawContent);
    final normalized = withoutModifier.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    if (normalized.length <= Config.maxTitleLength) {
      return normalized;
    }
    final truncated = normalized.substring(0, Config.maxTitleLength);
    final lastWhitespaceIndex = truncated.lastIndexOf(RegExp(r'\s'));
    if (lastWhitespaceIndex < Config.maxTitleLength ~/ 2) {
      return truncated.trimRight();
    }
    return truncated.substring(0, lastWhitespaceIndex).trimRight();
  }

  String _buildLegacyConversationTitle(String rawContent) {
    if (rawContent.length <= Config.legacyMaxTitleLength) {
      return rawContent;
    }
    return rawContent.substring(0, Config.legacyMaxTitleLength);
  }

  Future<bool> _updateConvTitleWithoutTouchingUpdatedAt(int createAtInUS, String title) async {
    final success =
        await (update(conversation)..where((tbl) => tbl.createdAtUS.equals(createAtInUS))).write(
          _ConversationCompanion(title: Value(title)),
        ) >
        0;
    return success;
  }

  Future<bool> _updateConvSubtitleWithoutTouchingUpdatedAt(int createAtInUS, String subtitle) async {
    final success =
        await (update(conversation)..where((tbl) => tbl.createdAtUS.equals(createAtInUS))).write(
          _ConversationCompanion(subtitle: Value(subtitle)),
        ) >
        0;
    return success;
  }

  Future<bool> _repairLegacyTruncatedTitles(List<ConversationData> conversations) async {
    if (_didRepairLegacyConversationTitles) {
      return false;
    }
    _didRepairLegacyConversationTitles = true;
    final candidates = <_ConversationTitleRepairCandidate>[];
    for (final conversationData in conversations) {
      if (conversationData.title.length != Config.legacyMaxTitleLength) {
        continue;
      }
      late final MsgNode msgNode;
      try {
        msgNode = MsgNode.fromJson(
          conversationData.data,
          createAtInUS: conversationData.createdAtUS,
        );
      } catch (e) {
        qqe("repair title: parse MsgNode failed, createAtUS=${conversationData.createdAtUS}, error=$e");
        continue;
      }
      final firstMsgId = msgNode.latestMsgIdsWithoutRoot.firstOrNull;
      if (firstMsgId == null) {
        continue;
      }
      candidates.add(
        _ConversationTitleRepairCandidate(
          createdAtUS: conversationData.createdAtUS,
          firstMsgId: firstMsgId,
          title: conversationData.title,
        ),
      );
    }
    if (candidates.isEmpty) {
      return false;
    }

    final firstMsgIds = <int>{
      for (final _ConversationTitleRepairCandidate candidate in candidates) candidate.firstMsgId,
    };
    final firstMsgDataList = await (select(msg)..where((tbl) => tbl.id.isIn(firstMsgIds))).get();
    final firstMsgById = <int, _MsgData>{
      for (final _MsgData firstMsgData in firstMsgDataList) firstMsgData.id: firstMsgData,
    };

    bool hasRepairedTitle = false;
    for (final _ConversationTitleRepairCandidate candidate in candidates) {
      final _MsgData? firstMsgData = firstMsgById[candidate.firstMsgId];
      if (firstMsgData == null) {
        continue;
      }
      final legacyTitle = _buildLegacyConversationTitle(firstMsgData.content);
      if (legacyTitle != candidate.title) {
        continue;
      }
      final repairedTitle = _buildConversationTitle(firstMsgData.content);
      if (repairedTitle == candidate.title) {
        continue;
      }
      final updated = await _updateConvTitleWithoutTouchingUpdatedAt(candidate.createdAtUS, repairedTitle);
      if (!updated) {
        continue;
      }
      hasRepairedTitle = true;
    }
    return hasRepairedTitle;
  }

  Future<bool> _repairMissingConversationSubtitles(List<ConversationData> conversations) async {
    final candidates = <_ConversationSubtitleRepairCandidate>[];
    for (final conversationData in conversations) {
      if (conversationData.subtitle != null && conversationData.subtitle!.isNotEmpty) {
        continue;
      }
      late final MsgNode msgNode;
      try {
        msgNode = MsgNode.fromJson(
          conversationData.data,
          createAtInUS: conversationData.createdAtUS,
        );
      } catch (e) {
        qqe("repair subtitle: parse MsgNode failed, createAtUS=${conversationData.createdAtUS}, error=$e");
        continue;
      }
      final ids = msgNode.latestMsgIdsWithoutRoot;
      final botMsgId = ids.length >= 2 ? ids[1] : null;
      if (botMsgId == null) {
        continue;
      }
      candidates.add(
        _ConversationSubtitleRepairCandidate(
          createdAtUS: conversationData.createdAtUS,
          botMsgId: botMsgId,
        ),
      );
    }
    if (candidates.isEmpty) {
      return false;
    }

    final botMsgIds = <int>{
      for (final _ConversationSubtitleRepairCandidate candidate in candidates) candidate.botMsgId,
    };
    final botMsgDataList = await (select(msg)..where((tbl) => tbl.id.isIn(botMsgIds))).get();
    final botMsgById = <int, _MsgData>{
      for (final _MsgData botMsgData in botMsgDataList) botMsgData.id: botMsgData,
    };

    bool hasRepairedSubtitle = false;
    for (final _ConversationSubtitleRepairCandidate candidate in candidates) {
      final _MsgData? botMsgData = botMsgById[candidate.botMsgId];
      if (botMsgData == null) {
        continue;
      }
      final subtitle = buildConversationSubtitleFromResponseContent(botMsgData.content);
      if (subtitle.isEmpty) {
        continue;
      }
      final updated = await _updateConvSubtitleWithoutTouchingUpdatedAt(candidate.createdAtUS, subtitle);
      if (!updated) {
        continue;
      }
      hasRepairedSubtitle = true;
    }
    return hasRepairedSubtitle;
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
      title = _buildConversationTitle(firstMsgContent);
    } else {
      title = P.preference.currentLangIsZh.q ? "新会话" : "New Conversation";
    }

    final convData = _conversationToConversationCompanion(msgNode, title: title);

    try {
      // 使用 Drift 的 insert 方法，并结合 onConflict 参数实现 UPSERT。
      // 如果主键唯一，则会触发 DoUpdate 策略
      await into(conversation).insert(convData, onConflict: DoUpdate((old) => convData));
      return true;
    } catch (e) {
      qqe("upsert failed: $e");
      return false;
    }
  }

  /// 根据会话的创建时间找到会话，并更新会话，如果会话不存在，则返回 false
  Future<bool> updateConv(int createAtInUS, {String? title, String? subtitle}) async {
    final success =
        await (update(conversation)..where((tbl) {
              return tbl.createdAtUS.equals(createAtInUS);
            }))
            .write(
              _ConversationCompanion(updatedAtUS: Value(HF.microseconds)).copyWith(
                title: title == null ? null : Value(title),
                subtitle: subtitle == null ? null : Value(subtitle),
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

    final conversationDataList = await query.get();
    final hasRepairedTitles = await _repairLegacyTruncatedTitles(conversationDataList);
    final hasRepairedSubtitles = await _repairMissingConversationSubtitles(conversationDataList);
    if (!hasRepairedTitles && !hasRepairedSubtitles) {
      return conversationDataList;
    }
    return await query.get();
  }

  Future<List<ConversationData>> allConversationsForExport() async {
    final query = select(conversation)
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAtUS),
        (t) => OrderingTerm.desc(t.createdAtUS),
      ]);

    final conversationDataList = await query.get();
    final hasRepairedTitles = await _repairLegacyTruncatedTitles(conversationDataList);
    final hasRepairedSubtitles = await _repairMissingConversationSubtitles(conversationDataList);
    if (!hasRepairedTitles && !hasRepairedSubtitles) {
      return conversationDataList;
    }
    return await query.get();
  }

  Future<void> exportSqliteSnapshot(String targetPath) async {
    await customStatement('VACUUM INTO ${_sqliteStringLiteral(targetPath)}');
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

String _sqliteStringLiteral(String value) {
  return "'${value.replaceAll("'", "''")}'";
}

model.Message _msgDataToMessage(_MsgData msgData) {
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
    paused: msgData.paused,
    ttsTarget: msgData.ttsTarget,
    ttsSpeakerName: msgData.ttsSpeakerName,
    ttsSourceAudioPath: msgData.ttsSourceAudioPath,
    ttsInstruction: msgData.ttsInstruction,
    ttsCFMSteps: msgData.ttsCFMSteps,
    isSensitive: msgData.isSensitive,
    modelName: msgData.modelName,
    runningMode: msgData.runningMode,
    rawDecodeParams: msgData.rawDecodeParams,
    batchSlotLabels: (jsonDecode(msgData.batchSlotLabels ?? "null") as Iterable?)?.map((dynamic e) => e.toString()).toList(),
    prefillSpeed: msgData.prefillSpeed,
    decodeSpeed: msgData.decodeSpeed,
    messageTokensCount: msgData.messageTokensCount,
    conversationTokensCount: msgData.conversationTokensCount,
  );
}
