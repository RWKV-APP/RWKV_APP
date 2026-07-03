import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:local_web_search/src/models/search_query_generation_result.dart';
// ignore: depend_on_referenced_packages
import 'package:local_web_search/src/query/search_query_generator.dart';

const String _defaultContainerDb =
    '/Users/wangce/Library/Containers/com.rwkv.chat.v7.100m/Data/Library/Application Support/com.rwkv.chat.v7.100m/rwkv_db.sqlite';
const String _defaultSupportDb = '/Users/wangce/Library/Application Support/com.rwkv.chat.v7.100m/rwkv_db.sqlite';
const String _historyProbePrompt = 'User: 这个有什么坑？';
final RegExp _opaqueQueryTokenPattern = RegExp(
  r'[A-Za-z0-9+/=_-]{24,}',
);
final List<String> _queryNoiseFragments = <String>[
  '这个',
  '那个',
  '这些',
  '那些',
  '有什么坑',
  '上有什么坑',
  '哈哈',
];
final Set<String> _taskShellQueryTerms = <String>{
  'single-file',
  'html',
  'css',
  'javascript',
  'return',
  'complete',
  'document',
};

Future<void> main(List<String> args) async {
  final options = _EvalOptions.parse(args);
  final dbPath = options.dbPath ?? _firstExistingDbPath();
  if (dbPath == null) {
    stderr.writeln('RWKV Chat database was not found.');
    exitCode = 1;
    return;
  }

  final conversations = await _loadConversations(dbPath);
  final messagesById = await _loadMessages(dbPath);
  final dbMessageCount = messagesById.length;
  final dbUserMessageCount = _countMessages(
    messagesById,
    (message) => message.isMine,
  );
  int treeMessageNodeCount = 0;
  int treeUserNodeCount = 0;
  final samples = <_ConversationSample>[];
  for (final conversation in conversations) {
    final allPaths = _allMessageIdPathsFromTree(conversation.treeJson);
    treeMessageNodeCount += allPaths.length;
    treeUserNodeCount += _countUserTerminalPaths(allPaths, messagesById);
    final paths = options.finalOnly ? <List<int>>[_latestMessageIdsFromTree(conversation.treeJson)] : allPaths;

    for (final messageIds in paths) {
      final finalMessage = messageIds.isEmpty ? null : messagesById[messageIds.last];
      if (!options.finalOnly && finalMessage?.isMine != true) continue;

      final lines = _messageLinesForPath(messageIds, messagesById);
      if (lines.isEmpty) continue;
      final userTurnIndex = _userTurnIndexForPath(messageIds, messagesById);
      samples.add(
        _ConversationSample(
          conversationId: conversation.id,
          title: conversation.title,
          turnIndex: userTurnIndex,
          pathIndex: messageIds.length - 1,
          sampleKind: 'conversation',
          messages: List<String>.unmodifiable(lines),
          result: SearchQueryGenerator.build(lines),
        ),
      );
    }

    if (!options.historyProbes) continue;

    final latestPath = _latestMessageIdsFromTree(conversation.treeJson);
    final latestLines = _messageLinesForPath(latestPath, messagesById);
    if (latestLines.isEmpty) continue;

    final probeLines = <String>[...latestLines, _historyProbePrompt];
    samples.add(
      _ConversationSample(
        conversationId: conversation.id,
        title: conversation.title,
        turnIndex: _userTurnIndexForPath(latestPath, messagesById) + 1,
        pathIndex: latestPath.length,
        sampleKind: 'history_probe',
        messages: List<String>.unmodifiable(probeLines),
        result: SearchQueryGenerator.build(probeLines),
      ),
    );
  }

  if (options.json) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(
        _buildReport(
          dbPath: dbPath,
          conversationCount: conversations.length,
          dbMessageCount: dbMessageCount,
          dbUserMessageCount: dbUserMessageCount,
          treeMessageNodeCount: treeMessageNodeCount,
          treeUserNodeCount: treeUserNodeCount,
          samples: samples,
          options: options,
        ),
      ),
    );
    return;
  }

  _printSummary(
    dbPath: dbPath,
    conversationCount: conversations.length,
    dbMessageCount: dbMessageCount,
    dbUserMessageCount: dbUserMessageCount,
    treeMessageNodeCount: treeMessageNodeCount,
    treeUserNodeCount: treeUserNodeCount,
    samples: samples,
    options: options,
  );
}

String? _firstExistingDbPath() {
  final candidates = <String>[_defaultContainerDb, _defaultSupportDb];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

Future<List<_ConversationRow>> _loadConversations(String dbPath) async {
  final rows = await _sqliteJson(
    dbPath,
    '''
select created_at_u_s as id,
       coalesce(updated_at_u_s, created_at_u_s) as sort_key,
       title,
       data
from conv
order by sort_key desc;
''',
  );
  final conversations = <_ConversationRow>[];
  for (final row in rows) {
    conversations.add(
      _ConversationRow(
        id: row['id'] as int,
        title: row['title'] as String,
        treeJson: row['data'] as String,
      ),
    );
  }
  return conversations;
}

Future<Map<int, _MessageRow>> _loadMessages(String dbPath) async {
  final rows = await _sqliteJson(
    dbPath,
    '''
select id, is_mine, content
from msg
order by id asc;
''',
  );
  final messages = <int, _MessageRow>{};
  for (final row in rows) {
    final id = row['id'] as int;
    messages[id] = _MessageRow(
      id: id,
      isMine: row['is_mine'] == 1,
      content: row['content'] as String,
    );
  }
  return messages;
}

Future<List<Map<String, dynamic>>> _sqliteJson(String dbPath, String sql) async {
  final result = await Process.run('sqlite3', <String>['-json', dbPath, sql]);
  if (result.exitCode != 0) {
    throw StateError(result.stderr.toString());
  }
  final stdoutText = result.stdout.toString().trim();
  if (stdoutText.isEmpty) return <Map<String, dynamic>>[];
  final decoded = jsonDecode(stdoutText) as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
}

List<int> _latestMessageIdsFromTree(String treeJson) {
  final decoded = jsonDecode(treeJson) as Map<String, dynamic>;
  final rootId = decoded['root_id'] as int;
  final nodes = decoded['nodes'] as List<dynamic>;
  final latestById = <int, int?>{};
  for (final node in nodes) {
    final data = node as Map<String, dynamic>;
    latestById[data['id'] as int] = data['latest_id'] as int?;
  }

  final ids = <int>[];
  int? current = rootId;
  while (current != null) {
    if (current != 0) ids.add(current);
    current = latestById[current];
  }
  return ids;
}

List<List<int>> _allMessageIdPathsFromTree(String treeJson) {
  final decoded = jsonDecode(treeJson) as Map<String, dynamic>;
  final rootId = decoded['root_id'] as int;
  final nodes = decoded['nodes'] as List<dynamic>;
  final childrenById = <int, List<int>>{};
  for (final node in nodes) {
    final data = node as Map<String, dynamic>;
    final id = data['id'] as int;
    final rawChildren = data['children_ids'] as List<dynamic>;
    final children = <int>[];
    for (final rawChild in rawChildren) {
      children.add(rawChild as int);
    }
    childrenById[id] = children;
  }

  final paths = <List<int>>[];

  void visit(int nodeId, List<int> path) {
    final children = childrenById[nodeId] ?? const <int>[];
    for (final childId in children) {
      final nextPath = <int>[...path, childId];
      paths.add(nextPath);
      visit(childId, nextPath);
    }
  }

  visit(rootId, const <int>[]);
  return paths;
}

List<String> _messageLinesForPath(
  List<int> messageIds,
  Map<int, _MessageRow> messagesById,
) {
  final lines = <String>[];
  for (final id in messageIds) {
    final message = messagesById[id];
    if (message == null) continue;
    final role = message.isMine ? 'User' : 'Assistant';
    lines.add('$role: ${message.content}');
  }
  return lines;
}

int _userTurnIndexForPath(
  List<int> messageIds,
  Map<int, _MessageRow> messagesById,
) {
  int count = 0;
  for (final id in messageIds) {
    final message = messagesById[id];
    if (message?.isMine != true) continue;
    count += 1;
  }
  return count;
}

int _countMessages(
  Map<int, _MessageRow> messagesById,
  bool Function(_MessageRow message) test,
) {
  int count = 0;
  for (final message in messagesById.values) {
    if (!test(message)) continue;
    count += 1;
  }
  return count;
}

int _countUserTerminalPaths(
  List<List<int>> paths,
  Map<int, _MessageRow> messagesById,
) {
  int count = 0;
  for (final path in paths) {
    if (path.isEmpty) continue;
    final message = messagesById[path.last];
    if (message?.isMine != true) continue;
    count += 1;
  }
  return count;
}

void _printSummary({
  required String dbPath,
  required int conversationCount,
  required int dbMessageCount,
  required int dbUserMessageCount,
  required int treeMessageNodeCount,
  required int treeUserNodeCount,
  required List<_ConversationSample> samples,
  required _EvalOptions options,
}) {
  final shouldSearchCount = _countSamples(
    samples,
    (sample) => sample.result.shouldSearch,
  );
  final usedHistoryCount = _countSamples(
    samples,
    (sample) => sample.result.usedHistory,
  );
  final emptyQueryCount = _countSamples(
    samples,
    (sample) => sample.result.query.isEmpty,
  );
  final reasonBuckets = _reasonBuckets(samples);
  final issueBuckets = _issueBuckets(samples);
  final issueSampleCount = _countSamples(
    samples,
    (sample) => _qualityIssues(sample).isNotEmpty,
  );

  stdout.writeln('DB: $dbPath');
  stdout.writeln(
    'Mode: ${options.finalOnly ? 'final conversation snapshots' : 'all user node paths'}',
  );
  stdout.writeln('Conversations: $conversationCount');
  stdout.writeln('DB message rows: $dbMessageCount');
  stdout.writeln('DB user message rows: $dbUserMessageCount');
  stdout.writeln('Tree message nodes: $treeMessageNodeCount');
  stdout.writeln('Tree user terminal nodes: $treeUserNodeCount');
  stdout.writeln('Samples: ${samples.length}');
  final historyProbeCount = _countSamples(
    samples,
    (sample) => sample.sampleKind == 'history_probe',
  );
  stdout.writeln('History probes: $historyProbeCount');
  stdout.writeln('shouldSearch: $shouldSearchCount');
  stdout.writeln('usedHistory: $usedHistoryCount');
  stdout.writeln('emptyQuery: $emptyQueryCount');
  stdout.writeln('issueSamples: $issueSampleCount');
  stdout.writeln('reasonBuckets:');
  for (final entry in reasonBuckets.entries) {
    stdout.writeln('  ${entry.value.toString().padLeft(3)} | ${entry.key}');
  }
  stdout.writeln('issueBuckets:');
  if (issueBuckets.isEmpty) {
    stdout.writeln('    0 | no_quality_issues');
  } else {
    for (final entry in issueBuckets.entries) {
      stdout.writeln('  ${entry.value.toString().padLeft(3)} | ${entry.key}');
    }
  }
  stdout.writeln('');

  final visibleSamples = (options.issuesOnly ? samples.where((sample) => _qualityIssues(sample).isNotEmpty) : samples)
      .take(options.limit)
      .toList();
  for (final sample in visibleSamples) {
    final qualityIssues = _qualityIssues(sample);
    stdout.writeln('---');
    stdout.writeln('conversation: ${sample.conversationId}');
    stdout.writeln('sampleKind: ${sample.sampleKind}');
    stdout.writeln('turn: ${sample.turnIndex}');
    stdout.writeln('pathIndex: ${sample.pathIndex}');
    stdout.writeln('title: ${_oneLine(sample.title, 100)}');
    stdout.writeln('messages: ${sample.messages.length}');
    stdout.writeln('shouldSearch: ${sample.result.shouldSearch}');
    stdout.writeln('usedHistory: ${sample.result.usedHistory}');
    stdout.writeln('reason: ${sample.result.reason}');
    stdout.writeln(
      'qualityIssues: ${qualityIssues.isEmpty ? 'none' : qualityIssues.join(', ')}',
    );
    stdout.writeln('latest: ${_oneLine(sample.result.latestUserMessage?.content ?? '', 140)}');
    stdout.writeln('query: ${sample.result.query}');
    stdout.writeln(
      'supporting: ${sample.result.supportingMessages.map((message) => message.messageIndex).join(', ')}',
    );
    stdout.writeln(
      'topTerms: ${sample.result.candidateTerms.take(8).map((term) => term.value).join(', ')}',
    );
    if (!options.verbose) continue;
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(sample.result.toJson()));
  }
}

Map<String, dynamic> _buildReport({
  required String dbPath,
  required int conversationCount,
  required int dbMessageCount,
  required int dbUserMessageCount,
  required int treeMessageNodeCount,
  required int treeUserNodeCount,
  required List<_ConversationSample> samples,
  required _EvalOptions options,
}) {
  return <String, dynamic>{
    'dbPath': dbPath,
    'mode': options.finalOnly ? 'final_conversation_snapshots' : 'all_user_node_paths',
    'conversationCount': conversationCount,
    'dbMessageCount': dbMessageCount,
    'dbUserMessageCount': dbUserMessageCount,
    'treeMessageNodeCount': treeMessageNodeCount,
    'treeUserTerminalNodeCount': treeUserNodeCount,
    'sampleCount': samples.length,
    'historyProbeCount': _countSamples(
      samples,
      (sample) => sample.sampleKind == 'history_probe',
    ),
    'shouldSearchCount': _countSamples(
      samples,
      (sample) => sample.result.shouldSearch,
    ),
    'usedHistoryCount': _countSamples(
      samples,
      (sample) => sample.result.usedHistory,
    ),
    'emptyQueryCount': _countSamples(
      samples,
      (sample) => sample.result.query.isEmpty,
    ),
    'issueSampleCount': _countSamples(
      samples,
      (sample) => _qualityIssues(sample).isNotEmpty,
    ),
    'reasonBuckets': _reasonBuckets(samples),
    'issueBuckets': _issueBuckets(samples),
    'samples': (options.issuesOnly ? samples.where((sample) => _qualityIssues(sample).isNotEmpty) : samples)
        .take(options.limit)
        .map((sample) => sample.toJson(verbose: options.verbose))
        .toList(),
  };
}

int _countSamples(
  List<_ConversationSample> samples,
  bool Function(_ConversationSample sample) test,
) {
  int count = 0;
  for (final sample in samples) {
    if (!test(sample)) continue;
    count += 1;
  }
  return count;
}

Map<String, int> _reasonBuckets(List<_ConversationSample> samples) {
  final counts = <String, int>{};
  for (final sample in samples) {
    counts[sample.result.reason] = (counts[sample.result.reason] ?? 0) + 1;
  }

  final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return <String, int>{for (final entry in entries) entry.key: entry.value};
}

Map<String, int> _issueBuckets(List<_ConversationSample> samples) {
  final counts = <String, int>{};
  for (final sample in samples) {
    final issues = _qualityIssues(sample);
    for (final issue in issues) {
      counts[issue] = (counts[issue] ?? 0) + 1;
    }
  }

  final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return <String, int>{for (final entry in entries) entry.key: entry.value};
}

List<String> _qualityIssues(_ConversationSample sample) {
  final issues = <String>[];
  final result = sample.result;
  final query = result.query.trim();

  if (result.shouldSearch && query.isEmpty) {
    issues.add('search_without_query');
  }
  if (!result.shouldSearch && query.isNotEmpty) {
    issues.add('disabled_with_query');
  }
  if (result.usedHistory && result.supportingMessages.isEmpty) {
    issues.add('used_history_without_support');
  }
  if (sample.sampleKind == 'history_probe' && result.shouldSearch && !result.usedHistory) {
    issues.add('history_probe_without_history');
  }
  if (_opaqueQueryTokenPattern.hasMatch(query)) {
    issues.add('opaque_query_token');
  }
  for (final fragment in _queryNoiseFragments) {
    if (!query.contains(fragment)) continue;
    issues.add('query_contains_noise:$fragment');
  }
  if (query.length > 140) {
    issues.add('query_too_long');
  }
  if (sample.sampleKind == 'history_probe' && result.usedHistory && _queryWordCount(query) <= 1 && query.length < 8) {
    issues.add('under_specific_history_query');
  }
  if (sample.sampleKind == 'history_probe' && result.usedHistory) {
    final lowerQuery = query.toLowerCase();
    for (final term in _taskShellQueryTerms) {
      if (!lowerQuery.contains(term)) continue;
      issues.add('history_query_contains_task_shell:$term');
    }
  }
  return issues;
}

int _queryWordCount(String query) {
  if (query.trim().isEmpty) return 0;
  return query.trim().split(' ').where((part) => part.trim().isNotEmpty).length;
}

String _oneLine(String text, int maxLength) {
  final compact = _compactWhitespace(text);
  if (compact.length <= maxLength) return compact;
  return '${compact.substring(0, maxLength).trim()}...';
}

String _compactWhitespace(String text) {
  final buffer = StringBuffer();
  bool pendingSpace = false;
  for (int index = 0; index < text.length; index += 1) {
    final codeUnit = text.codeUnitAt(index);
    final whitespace = codeUnit == 9 || codeUnit == 10 || codeUnit == 11 || codeUnit == 12 || codeUnit == 13 || codeUnit == 32;
    if (whitespace) {
      pendingSpace = buffer.isNotEmpty;
      continue;
    }
    if (pendingSpace && buffer.isNotEmpty) {
      buffer.write(' ');
    }
    pendingSpace = false;
    buffer.writeCharCode(codeUnit);
  }
  return buffer.toString().trim();
}

class _EvalOptions {
  final String? dbPath;
  final int limit;
  final bool verbose;
  final bool json;
  final bool finalOnly;
  final bool historyProbes;
  final bool issuesOnly;

  const _EvalOptions({
    required this.dbPath,
    required this.limit,
    required this.verbose,
    required this.json,
    required this.finalOnly,
    required this.historyProbes,
    required this.issuesOnly,
  });

  factory _EvalOptions.parse(List<String> args) {
    String? dbPath;
    int limit = 12;
    bool verbose = false;
    bool json = false;
    bool finalOnly = false;
    bool historyProbes = false;
    bool issuesOnly = false;

    for (int index = 0; index < args.length; index += 1) {
      final arg = args[index];
      if (arg == '--verbose') {
        verbose = true;
        continue;
      }
      if (arg == '--json') {
        json = true;
        continue;
      }
      if (arg == '--final-only') {
        finalOnly = true;
        continue;
      }
      if (arg == '--history-probes') {
        historyProbes = true;
        continue;
      }
      if (arg == '--issues-only') {
        issuesOnly = true;
        continue;
      }
      if (arg == '--db' && index + 1 < args.length) {
        dbPath = args[index + 1];
        index += 1;
        continue;
      }
      if (arg == '--limit' && index + 1 < args.length) {
        limit = int.tryParse(args[index + 1]) ?? limit;
        index += 1;
      }
    }

    return _EvalOptions(
      dbPath: dbPath,
      limit: limit,
      verbose: verbose,
      json: json,
      finalOnly: finalOnly,
      historyProbes: historyProbes,
      issuesOnly: issuesOnly,
    );
  }
}

class _ConversationRow {
  final int id;
  final String title;
  final String treeJson;

  const _ConversationRow({
    required this.id,
    required this.title,
    required this.treeJson,
  });
}

class _MessageRow {
  final int id;
  final bool isMine;
  final String content;

  const _MessageRow({
    required this.id,
    required this.isMine,
    required this.content,
  });
}

class _ConversationSample {
  final int conversationId;
  final String title;
  final int turnIndex;
  final int pathIndex;
  final String sampleKind;
  final List<String> messages;
  final SearchQueryGenerationResult result;

  const _ConversationSample({
    required this.conversationId,
    required this.title,
    required this.turnIndex,
    required this.pathIndex,
    required this.sampleKind,
    required this.messages,
    required this.result,
  });

  Map<String, dynamic> toJson({required bool verbose}) {
    final base = <String, dynamic>{
      'conversationId': conversationId,
      'sampleKind': sampleKind,
      'turnIndex': turnIndex,
      'pathIndex': pathIndex,
      'title': title,
      'messageCount': messages.length,
      'latestUserMessage': result.latestUserMessage?.content,
      'shouldSearch': result.shouldSearch,
      'usedHistory': result.usedHistory,
      'reason': result.reason,
      'query': result.query,
      'qualityIssues': _qualityIssues(this),
      'supportingMessageIndexes': result.supportingMessages.map((message) => message.messageIndex).toList(),
      'candidateTerms': result.candidateTerms.take(12).map((term) => term.toJson()).toList(),
    };
    if (!verbose) return base;
    return <String, dynamic>{
      ...base,
      'messages': messages,
      'queryGeneration': result.toJson(),
    };
  }
}
