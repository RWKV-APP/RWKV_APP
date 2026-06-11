import 'dart:convert';
import 'dart:io';

const List<String> _arbFiles = [
  'lib/l10n/intl_en.arb',
  'lib/l10n/intl_ja.arb',
  'lib/l10n/intl_ko.arb',
  'lib/l10n/intl_ru.arb',
  'lib/l10n/intl_zh_Hans.arb',
  'lib/l10n/intl_zh_Hant.arb',
];

const List<String> _readmeFiles = [
  'README.md',
  'docs/README.zh-hans.md',
  'docs/README.zh-hant.md',
  'docs/README.ja.md',
  'docs/README.ko.md',
  'docs/README.ru.md',
];

const List<String> _contributingFiles = [
  'CONTRIBUTING.md',
  'docs/CONTRIBUTING.zh-hans.md',
  'docs/CONTRIBUTING.zh-hant.md',
  'docs/CONTRIBUTING.ja.md',
  'docs/CONTRIBUTING.ko.md',
  'docs/CONTRIBUTING.ru.md',
];

final class _RuleIssue {
  final String path;
  final int line;
  final String rule;
  final String message;
  final String source;

  const _RuleIssue({
    required this.path,
    required this.line,
    required this.rule,
    required this.message,
    required this.source,
  });
}

final class _LineRule {
  final String name;
  final RegExp pattern;
  final String message;
  final bool libOnly;

  const _LineRule({
    required this.name,
    required this.pattern,
    required this.message,
    this.libOnly = false,
  });
}

final List<_LineRule> _lineRules = [
  _LineRule(
    name: 'no-divider',
    pattern: RegExp(r'\bDivider\s*\('),
    message: 'Use Container(height: 0.5, color: ...) for lib separators',
    libOnly: true,
  ),
  _LineRule(
    name: 'no-list-tile',
    pattern: RegExp(r'\bListTile\s*\('),
    message: 'Use explicit Row and Column composition for lib list rows',
    libOnly: true,
  ),
  _LineRule(
    name: 'no-future-builder',
    pattern: RegExp(r'\bFutureBuilder\b'),
    message: 'Keep async state in store providers instead of FutureBuilder in lib UI',
    libOnly: true,
  ),
  _LineRule(
    name: 'media-query-size',
    pattern: RegExp(r'MediaQuery\.of\(context\)\.size\.width'),
    message: 'Use MediaQuery.sizeOf(context).width',
    libOnly: true,
  ),
  _LineRule(
    name: 'media-query-padding',
    pattern: RegExp(r'MediaQuery\.of\(context\)\.padding'),
    message: 'Use MediaQuery.paddingOf(context)',
    libOnly: true,
  ),
  _LineRule(
    name: 'no-with-opacity',
    pattern: RegExp(r'\.withOpacity\s*\('),
    message: 'Use .q(alpha) for color alpha adjustments',
    libOnly: true,
  ),
  _LineRule(
    name: 'avoid-then',
    pattern: RegExp(r'\.then\s*\('),
    message: 'Prefer async and await',
  ),
  _LineRule(
    name: 'avoid-foreach',
    pattern: RegExp(r'\.forEach\s*\('),
    message: 'Prefer for loops',
  ),
  _LineRule(
    name: 'no-relative-import',
    pattern: RegExp("^\\s*(import|export)\\s+['\\\"]\\.\\.?/"),
    message: 'Use package imports',
  ),
  _LineRule(
    name: 'no-show-import',
    pattern: RegExp(r'^\s*(import|export)\s+.*\s+show\s+'),
    message: 'Avoid show in imports and exports',
  ),
  _LineRule(
    name: 'material-symbols-static-import',
    pattern: RegExp(r'package:material_symbols_icons/(get|symbols_map)\.dart'),
    message: 'Use package:material_symbols_icons/symbols.dart only',
  ),
];

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printHelp();
    return;
  }

  final root = _findRepoRoot();
  final rulesOnly = arguments.contains('--rules-only');
  final strictRules = arguments.contains('--strict-rules');

  int exitCode = 0;
  if (!rulesOnly) {
    exitCode = await _runCommand(root, 'dart', ['analyze']);
    if (exitCode != 0) {
      exit(exitCode);
    }

    exitCode = await _runCommand(root, 'flutter', ['test']);
    if (exitCode != 0) {
      exit(exitCode);
    }
  }

  final ruleIssueCount = _runRuleScan(root);
  if (strictRules && ruleIssueCount > 0) {
    exit(1);
  }
}

void _printHelp() {
  stdout.writeln('Usage: dart run tools/bin/agent_check.dart [--rules-only] [--strict-rules]');
  stdout.writeln('');
  stdout.writeln('Default checks:');
  stdout.writeln('  dart analyze');
  stdout.writeln('  flutter test');
  stdout.writeln('  lightweight repository rule scan');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --rules-only    Run only the repository rule scan');
  stdout.writeln('  --strict-rules  Return a non-zero exit code when rule warnings exist');
}

Directory _findRepoRoot() {
  Directory cursor = Directory.current;
  while (true) {
    final hasPubspec = File('${cursor.path}${Platform.pathSeparator}pubspec.yaml').existsSync();
    final hasLib = Directory('${cursor.path}${Platform.pathSeparator}lib').existsSync();
    if (hasPubspec && hasLib) {
      return cursor;
    }

    final parent = cursor.parent;
    if (parent.path == cursor.path) {
      stderr.writeln('Could not find repository root from ${Directory.current.path}');
      exit(2);
    }
    cursor = parent;
  }
}

Future<int> _runCommand(Directory root, String executable, List<String> args) async {
  stdout.writeln('');
  stdout.writeln('== ${[executable, ...args].join(' ')} ==');
  final process = await Process.start(
    executable,
    args,
    workingDirectory: root.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('Command failed with exit code $exitCode: ${[executable, ...args].join(' ')}');
  }
  return exitCode;
}

int _runRuleScan(Directory root) {
  stdout.writeln('');
  stdout.writeln('== repository rule scan ==');

  final issues = <_RuleIssue>[
    ..._scanDartRules(root),
    ..._scanArbKeys(root),
    ..._scanRequiredDocs(root, _readmeFiles, 'readme-sync'),
    ..._scanRequiredDocs(root, _contributingFiles, 'contributing-sync'),
  ];

  issues.sort((a, b) {
    final pathCompare = a.path.compareTo(b.path);
    if (pathCompare != 0) return pathCompare;
    return a.line.compareTo(b.line);
  });

  if (issues.isEmpty) {
    stdout.writeln('No repository rule warnings found');
    return 0;
  }

  stdout.writeln('Found ${issues.length} repository rule warning(s)');
  for (final issue in issues) {
    stdout.writeln('${issue.path}:${issue.line} [${issue.rule}] ${issue.message}');
    if (issue.source.isNotEmpty) {
      stdout.writeln('  ${issue.source}');
    }
  }
  return issues.length;
}

List<_RuleIssue> _scanDartRules(Directory root) {
  final issues = <_RuleIssue>[];
  final directories = [
    Directory('${root.path}${Platform.pathSeparator}lib'),
    Directory('${root.path}${Platform.pathSeparator}test'),
    Directory('${root.path}${Platform.pathSeparator}tools'),
  ];

  for (final directory in directories) {
    if (!directory.existsSync()) continue;
    final entities = directory.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final relativePath = _relativePath(root, entity);
      if (_isGeneratedOrToolCachePath(relativePath)) continue;

      final lines = entity.readAsLinesSync();
      for (int index = 0; index < lines.length; index++) {
        final line = lines[index];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//')) continue;
        final code = _stripLineComment(line);

        for (final rule in _lineRules) {
          if (rule.libOnly && !relativePath.startsWith('lib/')) continue;
          if (!rule.pattern.hasMatch(code)) continue;
          issues.add(
            _RuleIssue(
              path: relativePath,
              line: index + 1,
              rule: rule.name,
              message: rule.message,
              source: line.trim(),
            ),
          );
        }
      }
    }
  }

  return issues;
}

String _stripLineComment(String line) {
  final commentIndex = line.indexOf('//');
  if (commentIndex < 0) return line;
  return line.substring(0, commentIndex);
}

bool _isGeneratedOrToolCachePath(String path) {
  if (path.startsWith('lib/gen/')) return true;
  if (path.startsWith('tools/.dart_tool/')) return true;
  if (path.contains('/__pycache__/')) return true;
  if (path.endsWith('.g.dart')) return true;
  if (path.endsWith('.freezed.dart')) return true;
  if (path.endsWith('.steps.dart')) return true;
  return false;
}

List<_RuleIssue> _scanArbKeys(Directory root) {
  final issues = <_RuleIssue>[];
  final keySets = <String, Set<String>>{};

  for (final relativePath in _arbFiles) {
    final file = File('${root.path}${Platform.pathSeparator}${_platformPath(relativePath)}');
    if (!file.existsSync()) {
      issues.add(
        _RuleIssue(
          path: relativePath,
          line: 1,
          rule: 'arb-sync',
          message: 'Missing ARB file',
          source: '',
        ),
      );
      continue;
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      issues.add(
        _RuleIssue(
          path: relativePath,
          line: 1,
          rule: 'arb-sync',
          message: 'ARB file is not a JSON object',
          source: '',
        ),
      );
      continue;
    }

    final keys = <String>{};
    for (final key in decoded.keys) {
      if (key.startsWith('@')) continue;
      keys.add(key);
    }
    keySets[relativePath] = keys;
  }

  if (keySets.length < 2) return issues;

  final baselinePath = _arbFiles.first;
  final baseline = keySets[baselinePath] ?? <String>{};
  for (final entry in keySets.entries) {
    final missing = baseline.difference(entry.value).toList()..sort();
    final extra = entry.value.difference(baseline).toList()..sort();
    if (missing.isEmpty && extra.isEmpty) continue;

    final details = [
      if (missing.isNotEmpty) 'missing: ${missing.join(', ')}',
      if (extra.isNotEmpty) 'extra: ${extra.join(', ')}',
    ].join('; ');
    issues.add(
      _RuleIssue(
        path: entry.key,
        line: 1,
        rule: 'arb-sync',
        message: 'ARB keys differ from $baselinePath',
        source: details,
      ),
    );
  }

  return issues;
}

List<_RuleIssue> _scanRequiredDocs(Directory root, List<String> paths, String rule) {
  final issues = <_RuleIssue>[];
  for (final relativePath in paths) {
    final file = File('${root.path}${Platform.pathSeparator}${_platformPath(relativePath)}');
    if (file.existsSync()) continue;
    issues.add(
      _RuleIssue(
        path: relativePath,
        line: 1,
        rule: rule,
        message: 'Expected synchronized document is missing',
        source: '',
      ),
    );
  }
  return issues;
}

String _relativePath(Directory root, File file) {
  final prefix = '${root.path}${Platform.pathSeparator}';
  if (file.path.startsWith(prefix)) {
    return file.path.substring(prefix.length).replaceAll(Platform.pathSeparator, '/');
  }
  return file.path.replaceAll(Platform.pathSeparator, '/');
}

String _platformPath(String path) {
  return path.replaceAll('/', Platform.pathSeparator);
}
