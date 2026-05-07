part of 'p.dart';

enum DataExportArchiveType {
  sqlite,
  markdown,
}

enum _DataExportAction {
  sqlite,
  markdown,
}

final class DataExportMessageNodeInfo {
  final int id;
  final int? parentId;
  final int depth;

  const DataExportMessageNodeInfo({
    required this.id,
    required this.parentId,
    required this.depth,
  });
}

final class _DataExportMessageEntry {
  final Message message;
  final int? parentId;
  final int depth;

  const _DataExportMessageEntry({
    required this.message,
    required this.parentId,
    required this.depth,
  });

  Map<String, dynamic> toJson() {
    return {
      "parentId": parentId,
      "depth": depth,
      "message": message.toJson(),
    };
  }
}

final class _DataExportConversationEntry {
  final ConversationData conversation;
  final List<_DataExportMessageEntry> messages;
  final List<int> missingMessageIds;
  final String? parseError;

  const _DataExportConversationEntry({
    required this.conversation,
    required this.messages,
    required this.missingMessageIds,
    required this.parseError,
  });

  Map<String, dynamic> toJson() {
    return {
      "createdAtUS": conversation.createdAtUS,
      "updatedAtUS": conversation.updatedAtUS,
      "title": conversation.title,
      "subtitle": conversation.subtitle,
      "appBuildNumber": conversation.appBuildNumber,
      "tree": _decodeJsonForExport(conversation.data),
      "parseError": parseError,
      "missingMessageIds": missingMessageIds,
      "messages": messages.map((message) => message.toJson()).toList(),
    };
  }
}

final class _DataExport {
  // ===========================================================================
  // Static
  // ===========================================================================

  static const _fallbackSegment = 'unknown';
  static final _unsafeFileNameChars = RegExp(r'[^A-Za-z0-9._+-]+');
  static final _trimmedFileNameChars = RegExp(r'^[._+-]+|[._+-]+$');
  static final _sqliteEscapedPathChars = RegExp(r'[\u0000-\u001F]');
  static const _maxFileNameSegmentLength = 80;
  static const _sqliteArchiveFileName = db.AppDatabase.databaseFileName;

  // ===========================================================================
  // Public
  // ===========================================================================

  Future<void> showExportDataSheet(BuildContext context) async {
    if (P.rwkvGeneration.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    P.app.hapticLight();
    final s = S.of(context);
    final action = await showModalActionSheet<_DataExportAction>(
      context: context,
      title: s.export_data,
      cancelLabel: s.cancel,
      actions: [
        SheetAction(label: s.export_sqlite_database, key: .sqlite),
        SheetAction(label: s.export_markdown_archive, key: .markdown),
      ],
    );

    if (action == null) return;
    await _runExport(action);
  }

  // ===========================================================================
  // Private
  // ===========================================================================

  Future<void> _runExport(_DataExportAction action) async {
    if (P.rwkvGeneration.generating.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return;
    }

    try {
      final archiveType = switch (action) {
        _DataExportAction.sqlite => DataExportArchiveType.sqlite,
        _DataExportAction.markdown => DataExportArchiveType.markdown,
      };
      final file = await _buildArchive(archiveType);
      if (file == null) {
        return;
      }
      await _deliverArchive(file);
    } catch (e, stackTrace) {
      qqe("Export data failed: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
      Alert.error("${S.current.export_failed}: $e");
    }
  }

  Future<File?> _buildArchive(DataExportArchiveType archiveType) async {
    final conversations = await _loadConversationEntries();
    if (archiveType == DataExportArchiveType.markdown && conversations.isEmpty) {
      Alert.warning(S.current.no_data);
      return null;
    }

    final fileName = buildDataExportArchiveFileName(
      archiveType: archiveType,
      now: DateTime.now(),
      socName: _currentSocName(),
      appVersion: P.app.version.q,
      buildNumber: P.app.buildNumber.q,
      engineVersion: P.rwkvBackend.commitId.q,
      debug: kDebugMode,
    );

    File? sqliteSnapshot;
    if (archiveType == DataExportArchiveType.sqlite) {
      sqliteSnapshot = await _createSqliteSnapshot(fileName);
    }

    final archive = await _writeZipArchive(
      fileName: fileName,
      archiveType: archiveType,
      conversations: conversations,
      sqliteSnapshot: sqliteSnapshot,
    );

    if (sqliteSnapshot == null) {
      return archive;
    }

    try {
      await sqliteSnapshot.delete();
    } catch (e) {
      qqw("Failed to delete temporary SQLite snapshot: $e");
    }
    return archive;
  }

  Future<File> _createSqliteSnapshot(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final baseName = basenameWithoutExtension(fileName);
    final file = File(join(tempDir.path, '$baseName.sqlite'));
    if (await file.exists()) {
      await file.delete();
    }
    await P.app._db.exportSqliteSnapshot(file.path);
    return file;
  }

  Future<List<_DataExportConversationEntry>> _loadConversationEntries() async {
    final conversations = await P.app._db.allConversationsForExport();
    final nodesByConversationId = <int, MsgNode>{};
    final parseErrorsByConversationId = <int, String>{};
    final allMessageIds = <int>{};

    for (final conversation in conversations) {
      try {
        final msgNode = MsgNode.fromJson(
          conversation.data,
          createAtInUS: conversation.createdAtUS,
        );
        nodesByConversationId[conversation.createdAtUS] = msgNode;
        allMessageIds.addAll(msgNode.allMsgIdsFromRoot);
      } catch (e) {
        parseErrorsByConversationId[conversation.createdAtUS] = e.toString();
      }
    }

    final messages = await P.app._db.getMessagesByIds(allMessageIds);
    final messagesById = {
      for (final message in messages) message.id: message,
    };
    final result = <_DataExportConversationEntry>[];

    for (final conversation in conversations) {
      final msgNode = nodesByConversationId[conversation.createdAtUS];
      if (msgNode == null) {
        result.add(
          _DataExportConversationEntry(
            conversation: conversation,
            messages: const [],
            missingMessageIds: const [],
            parseError: parseErrorsByConversationId[conversation.createdAtUS],
          ),
        );
        continue;
      }

      final nodeInfos = buildDataExportMessageNodeInfos(msgNode);
      final entries = <_DataExportMessageEntry>[];
      final missingMessageIds = <int>[];
      for (final nodeInfo in nodeInfos) {
        final message = messagesById[nodeInfo.id];
        if (message == null) {
          missingMessageIds.add(nodeInfo.id);
          continue;
        }
        entries.add(
          _DataExportMessageEntry(
            message: message,
            parentId: nodeInfo.parentId,
            depth: nodeInfo.depth,
          ),
        );
      }

      result.add(
        _DataExportConversationEntry(
          conversation: conversation,
          messages: entries,
          missingMessageIds: missingMessageIds,
          parseError: parseErrorsByConversationId[conversation.createdAtUS],
        ),
      );
    }

    return result;
  }

  Future<File> _writeZipArchive({
    required String fileName,
    required DataExportArchiveType archiveType,
    required List<_DataExportConversationEntry> conversations,
    required File? sqliteSnapshot,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final zipFile = File(join(tempDir.path, fileName));
    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    final encoder = ZipFileEncoder();
    bool opened = false;
    try {
      encoder.create(zipFile.path);
      opened = true;

      if (archiveType == DataExportArchiveType.sqlite) {
        if (sqliteSnapshot == null) {
          throw StateError("SQLite snapshot is missing");
        }
        await encoder.addFile(sqliteSnapshot, _sqliteArchiveFileName);
      }

      if (archiveType == DataExportArchiveType.markdown) {
        encoder.addArchiveFile(
          ArchiveFile.string(
            'conversations.md',
            _buildMarkdown(conversations),
          ),
        );
        encoder.addArchiveFile(
          ArchiveFile.string(
            'data.json',
            _prettyJson({
              "manifest": _buildManifest(
                archiveType: archiveType,
                fileName: fileName,
                conversations: conversations,
              ),
              "conversations": conversations.map((conversation) => conversation.toJson()).toList(),
            }),
          ),
        );
      }

      encoder.addArchiveFile(
        ArchiveFile.string(
          'manifest.json',
          _prettyJson(
            _buildManifest(
              archiveType: archiveType,
              fileName: fileName,
              conversations: conversations,
            ),
          ),
        ),
      );
    } finally {
      if (opened) {
        await encoder.close();
      }
    }

    return zipFile;
  }

  Map<String, dynamic> _buildManifest({
    required DataExportArchiveType archiveType,
    required String fileName,
    required List<_DataExportConversationEntry> conversations,
  }) {
    final missingMessageIds = <int>[
      for (final conversation in conversations) ...conversation.missingMessageIds,
    ];
    final parseErrors = <Map<String, dynamic>>[
      for (final conversation in conversations)
        if (conversation.parseError != null)
          {
            "createdAtUS": conversation.conversation.createdAtUS,
            "title": conversation.conversation.title,
            "error": conversation.parseError,
          },
    ];

    return {
      "exportedAt": DateTime.now().toIso8601String(),
      "archiveFileName": fileName,
      "type": archiveType.name,
      "appVersion": P.app.version.q,
      "buildNumber": P.app.buildNumber.q,
      "buildMode": _currentFlutterBuildMode(),
      "engineVersion": P.rwkvBackend.commitId.q,
      "socName": _currentSocName(),
      "os": Platform.operatingSystem,
      "conversationCount": conversations.length,
      "messageCount": conversations.fold<int>(0, (sum, conversation) => sum + conversation.messages.length),
      "attachmentsExported": false,
      "missingMessageIds": missingMessageIds,
      "parseErrors": parseErrors,
      if (archiveType == DataExportArchiveType.sqlite)
        "sqlite": {
          "fileName": _sqliteArchiveFileName,
          "schemaVersion": P.app._db.schemaVersion,
        },
    };
  }

  String _buildMarkdown(List<_DataExportConversationEntry> conversations) {
    final buffer = StringBuffer()
      ..writeln('# RWKV Conversations')
      ..writeln()
      ..writeln('- Exported at: ${DateTime.now().toIso8601String()}')
      ..writeln('- App version: ${P.app.version.q} (${P.app.buildNumber.q})')
      ..writeln('- Build mode: ${_currentFlutterBuildMode()}')
      ..writeln('- Engine version: ${P.rwkvBackend.commitId.q.isEmpty ? _fallbackSegment : P.rwkvBackend.commitId.q}')
      ..writeln('- SoC: ${_currentSocName()}')
      ..writeln('- Conversations: ${conversations.length}')
      ..writeln();

    for (final conversation in conversations) {
      _writeConversationMarkdown(buffer, conversation);
    }

    return buffer.toString();
  }

  void _writeConversationMarkdown(
    StringBuffer buffer,
    _DataExportConversationEntry entry,
  ) {
    final conversation = entry.conversation;
    buffer
      ..writeln('## ${_escapeMarkdownInline(conversation.title)}')
      ..writeln()
      ..writeln('- ID: ${conversation.createdAtUS}')
      ..writeln('- Created at: ${_formatExportTimeUS(conversation.createdAtUS)}')
      ..writeln('- Updated at: ${_formatNullableExportTimeUS(conversation.updatedAtUS)}');

    final subtitle = conversation.subtitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) {
      buffer.writeln('- Subtitle: ${_escapeMarkdownInline(subtitle)}');
    }

    if (entry.parseError != null) {
      buffer
        ..writeln('- Parse error: ${_escapeMarkdownInline(entry.parseError!)}')
        ..writeln();
      return;
    }

    if (entry.missingMessageIds.isNotEmpty) {
      buffer.writeln('- Missing message IDs: ${entry.missingMessageIds.join(', ')}');
    }

    buffer.writeln();
    for (final messageEntry in entry.messages) {
      _writeMessageMarkdown(buffer, messageEntry);
    }
  }

  void _writeMessageMarkdown(
    StringBuffer buffer,
    _DataExportMessageEntry entry,
  ) {
    final message = entry.message;
    final role = message.isMine ? 'User' : 'Assistant';
    buffer
      ..writeln('### $role - ${_formatExportTimeMS(message.id)}')
      ..writeln()
      ..writeln('- ID: ${message.id}')
      ..writeln('- Parent ID: ${entry.parentId ?? "root"}')
      ..writeln('- Depth: ${entry.depth}')
      ..writeln('- Type: ${message.type.name}')
      ..writeln('- Paused: ${message.paused}');

    if (message.modelName != null && message.modelName!.isNotEmpty) {
      buffer.writeln('- Model: ${_escapeMarkdownInline(message.modelName!)}');
    }
    if (message.runningMode != null && message.runningMode!.isNotEmpty) {
      buffer.writeln('- Running mode: ${_escapeMarkdownInline(message.runningMode!)}');
    }
    if (message.messageTokensCount != null) {
      buffer.writeln('- Message tokens: ${message.messageTokensCount}');
    }
    if (message.conversationTokensCount != null) {
      buffer.writeln('- Conversation tokens: ${message.conversationTokensCount}');
    }

    buffer
      ..writeln()
      ..writeln(dataExportMarkdownCodeBlock(message.content))
      ..writeln();
  }

  Future<void> _deliverArchive(File file) async {
    if (Platform.isIOS) {
      final xFile = XFile(file.path, mimeType: 'application/zip');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: basename(file.path),
          title: S.current.export_data,
        ),
      );
      return;
    }

    final exportDirectoryInfo = await P.remote._pickExportDirectory();
    if (exportDirectoryInfo == null) {
      return;
    }

    final (targetDirectory, displayDirectory) = exportDirectoryInfo;
    final fileName = basename(file.path);
    if (P.remote._isAndroidDocumentTreeTarget(targetDirectory)) {
      final status = await P.remote._exportFileToAndroidDocumentTree(
        sourceFile: file,
        targetDirectory: targetDirectory,
        fileName: fileName,
      );
      if (status == "exists") {
        Alert.error(S.current.file_already_exists);
        return;
      }
      Alert.success("${S.current.export_success}\n\n$displayDirectory");
      return;
    }

    final targetFile = File(join(targetDirectory, fileName));
    if (await targetFile.exists()) {
      Alert.error(S.current.file_already_exists);
      return;
    }
    await P.remote._copyFileForExport(sourceFile: file, targetFile: targetFile);
    Alert.success("${S.current.export_success}\n\n$displayDirectory");
  }

  String _currentSocName() {
    final model = P.rwkvModel.latest.q;
    final socName = _resolveSocName(
      nativeSocName: P.rwkvBackend.socName.q,
      frontendSocName: P.rwkvBackend.frontendSocName.q,
      macChipName: P.telemetry._macChipName.q,
      gpuName: P.telemetry._gpuName.q,
      cpuName: P.telemetry._cpuName.q,
      deviceModel: P.telemetry._deviceModel.q,
      backendName: model?.backend?.name ?? "",
    );
    if (socName.trim().isNotEmpty) {
      return socName.trim();
    }
    return Platform.operatingSystem;
  }
}

List<DataExportMessageNodeInfo> buildDataExportMessageNodeInfos(MsgNode msgNode) {
  final rootNode = msgNode.root ?? msgNode;
  final result = <DataExportMessageNodeInfo>[];

  void traverse(MsgNode node, int depth) {
    if (node.id != 0) {
      final parentId = node.parent?.id;
      result.add(
        DataExportMessageNodeInfo(
          id: node.id,
          parentId: parentId == 0 ? null : parentId,
          depth: depth,
        ),
      );
    }

    final childDepth = node.id == 0 ? depth : depth + 1;
    for (final child in node.children) {
      traverse(child, childDepth);
    }
  }

  traverse(rootNode, 0);
  return result;
}

List<Message> orderMessagesForDataExport(MsgNode msgNode, Iterable<Message> messages) {
  final messagesById = {
    for (final message in messages) message.id: message,
  };
  final result = <Message>[];
  final nodeInfos = buildDataExportMessageNodeInfos(msgNode);
  for (final nodeInfo in nodeInfos) {
    final message = messagesById[nodeInfo.id];
    if (message == null) {
      continue;
    }
    result.add(message);
  }
  return result;
}

String sanitizeDataExportFileNameSegment(String value, {String fallback = 'unknown'}) {
  final normalized = value
      .replaceAll(_DataExport._sqliteEscapedPathChars, '_')
      .replaceAll(_DataExport._unsafeFileNameChars, '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(_DataExport._trimmedFileNameChars, '')
      .trim();
  if (normalized.isEmpty) {
    return fallback;
  }
  if (normalized.length <= _DataExport._maxFileNameSegmentLength) {
    return normalized;
  }
  return normalized.substring(0, _DataExport._maxFileNameSegmentLength);
}

String buildDataExportArchiveFileName({
  required DataExportArchiveType archiveType,
  required DateTime now,
  required String socName,
  required String appVersion,
  required String buildNumber,
  required String engineVersion,
  required bool debug,
}) {
  final parts = <String>[
    'rwkv_export',
    sanitizeDataExportFileNameSegment(socName),
    '${sanitizeDataExportFileNameSegment(appVersion)}+${sanitizeDataExportFileNameSegment(buildNumber)}',
    sanitizeDataExportFileNameSegment(engineVersion),
    if (debug) 'debug',
    _formatDataExportTimestamp(now),
    archiveType.name,
  ];
  return '${parts.join('_')}.zip';
}

String dataExportMarkdownCodeBlock(String content) {
  int longestRun = 0;
  for (final match in RegExp(r'`+').allMatches(content)) {
    final length = match.group(0)?.length ?? 0;
    if (length > longestRun) {
      longestRun = length;
    }
  }
  final fenceLength = math.max(3, longestRun + 1);
  final fence = '`' * fenceLength;
  return '$fence\n$content\n$fence';
}

String _formatDataExportTimestamp(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');
  return '$year$month${day}_$hour$minute$second';
}

String _formatExportTimeUS(int timeUS) {
  return DateTime.fromMicrosecondsSinceEpoch(timeUS).toIso8601String();
}

String _formatNullableExportTimeUS(int? timeUS) {
  if (timeUS == null) {
    return 'unknown';
  }
  return _formatExportTimeUS(timeUS);
}

String _formatExportTimeMS(int timeMS) {
  return DateTime.fromMillisecondsSinceEpoch(timeMS).toIso8601String();
}

String _escapeMarkdownInline(String value) {
  return value.replaceAll('\\', r'\\').replaceAll('[', r'\[').replaceAll(']', r'\]');
}

String _prettyJson(Object value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}

Object _decodeJsonForExport(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded == null) {
      return value;
    }
    return decoded;
  } catch (_) {
    return value;
  }
}
