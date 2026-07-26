import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const String specificationProcessVersion = 'v1.7';
const String specificationProcessEffectiveDate = '2026-07-23';

final class SpecificationIssue implements Comparable<SpecificationIssue> {
  final String path;
  final int line;
  final String code;
  final String message;

  const SpecificationIssue({
    required this.path,
    required this.line,
    required this.code,
    required this.message,
  });

  String get formatted {
    final location = line > 0 ? '$path:$line' : path;
    return '$location [$code] $message';
  }

  @override
  int compareTo(SpecificationIssue other) {
    final pathComparison = path.compareTo(other.path);
    if (pathComparison != 0) {
      return pathComparison;
    }
    final lineComparison = line.compareTo(other.line);
    if (lineComparison != 0) {
      return lineComparison;
    }
    final codeComparison = code.compareTo(other.code);
    if (codeComparison != 0) {
      return codeComparison;
    }
    return message.compareTo(other.message);
  }

  @override
  String toString() {
    return formatted;
  }
}

final class SpecificationCheckResult {
  final List<SpecificationIssue> issues;

  SpecificationCheckResult(Iterable<SpecificationIssue> issues)
    : issues = List<SpecificationIssue>.unmodifiable(_sortedUniqueIssues(issues));

  bool get isValid {
    return issues.isEmpty;
  }

  static List<SpecificationIssue> _sortedUniqueIssues(Iterable<SpecificationIssue> source) {
    final unique = <String, SpecificationIssue>{};
    for (final issue in source) {
      final sanitizedIssue = SpecificationIssue(
        path: _redactSensitiveDiagnosticText(issue.path),
        line: issue.line,
        code: issue.code,
        message: _redactSensitiveDiagnosticText(issue.message),
      );
      final key = '${sanitizedIssue.path}\u0000${sanitizedIssue.line}\u0000${sanitizedIssue.code}\u0000${sanitizedIssue.message}';
      unique[key] = sanitizedIssue;
    }
    final result = unique.values.toList();
    result.sort();
    return result;
  }
}

Directory? findSpecificationRepositoryRoot([Directory? start]) {
  Directory cursor = Directory(path.normalize((start ?? Directory.current).absolute.path));
  if (!cursor.existsSync()) {
    return null;
  }
  while (true) {
    if (_hasRepositoryMarkers(cursor)) {
      return cursor;
    }
    final parent = cursor.parent;
    if (parent.path == cursor.path) {
      return null;
    }
    cursor = parent;
  }
}

bool _hasRepositoryMarkers(Directory directory) {
  final separator = Platform.pathSeparator;
  final hasAgents = File('${directory.path}${separator}AGENTS.md').existsSync();
  final hasPubspec = File('${directory.path}${separator}pubspec.yaml').existsSync();
  final hasLib = Directory('${directory.path}${separator}lib').existsSync();
  final hasTools = Directory('${directory.path}${separator}tools').existsSync();
  return hasAgents && hasPubspec && hasLib && hasTools;
}

bool specificationInstructionMirrorMatches({
  required List<int> agentsBytes,
  required List<int> copilotBytes,
  bool? isWindows,
}) {
  if (_byteListsEqual(agentsBytes, copilotBytes)) {
    return true;
  }
  if (!(isWindows ?? Platform.isWindows)) {
    return false;
  }
  final copilotPlaceholder = utf8.decode(copilotBytes, allowMalformed: true);
  return const {
    '../AGENTS.md',
    '../AGENTS.md\n',
    '../AGENTS.md\r\n',
  }.contains(copilotPlaceholder);
}

bool _byteListsEqual(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index += 1) {
    if (left[index] == right[index]) {
      continue;
    }
    return false;
  }
  return true;
}

enum _RecordKind {
  productInput(
    prefix: 'PI',
    typeValue: 'product_input',
    dateField: 'captured_date',
  ),
  decision(
    prefix: 'DEC',
    typeValue: 'decision',
    dateField: 'date',
  ),
  observation(
    prefix: 'OBS',
    typeValue: 'observation',
    dateField: 'date',
  ),
  conflict(
    prefix: 'CF',
    typeValue: 'conflict',
    dateField: 'opened_date',
  ),
  acceptance(
    prefix: 'ACC',
    typeValue: 'acceptance',
    dateField: 'date',
  );

  final String prefix;
  final String typeValue;
  final String dateField;

  const _RecordKind({
    required this.prefix,
    required this.typeValue,
    required this.dateField,
  });
}

enum _MetadataValueKind {
  scalar,
  nullValue,
  list,
}

enum _ReferenceTargetStatus {
  exists,
  missing,
  escapesRoot,
}

final class _SensitivePattern {
  final String category;
  final RegExp expression;
  final int valueGroup;

  const _SensitivePattern({
    required this.category,
    required this.expression,
    required this.valueGroup,
  });
}

const String _privateKeyLabelPattern =
    r'(?:RSA PRIVATE KEY|EC PRIVATE KEY|OPENSSH PRIVATE KEY|DSA PRIVATE KEY|PGP PRIVATE KEY BLOCK|ENCRYPTED PRIVATE KEY|PRIVATE KEY)';

final List<_SensitivePattern> _sensitivePatterns = [
  _SensitivePattern(
    category: 'PEM private key',
    expression: RegExp(
      '-----BEGIN $_privateKeyLabelPattern-----',
      caseSensitive: false,
    ),
    valueGroup: 0,
  ),
  _SensitivePattern(
    category: 'GitHub access token',
    expression: RegExp(r'\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b'),
    valueGroup: 0,
  ),
  _SensitivePattern(
    category: 'Slack access token',
    expression: RegExp(r'\bxox[baprs]-[A-Za-z0-9-]{20,}\b'),
    valueGroup: 0,
  ),
  _SensitivePattern(
    category: 'provider API token',
    expression: RegExp(
      r'\b(?:sk-(?:proj-|ant-)?[A-Za-z0-9_-]{20,}|hf_[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20,}|npm_[A-Za-z0-9]{20,}|(?:sk|rk)_(?:live|test)_[A-Za-z0-9]{16,})\b',
    ),
    valueGroup: 0,
  ),
  _SensitivePattern(
    category: 'AWS access key ID',
    expression: RegExp(r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
    valueGroup: 0,
  ),
  _SensitivePattern(
    category: 'JSON Web Token',
    expression: RegExp(
      r'\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b',
    ),
    valueGroup: 0,
  ),
  _SensitivePattern(
    category: 'Bearer token',
    expression: RegExp(
      r'\bBearer[ \t]+([A-Za-z0-9._~+/-]{20,})\b',
      caseSensitive: false,
    ),
    valueGroup: 1,
  ),
  _SensitivePattern(
    category: 'Basic authorization credential',
    expression: RegExp(
      r'\bAuthorization[ \t]*:[ \t]*Basic[ \t]+([A-Za-z0-9+/]{16,}={0,2})',
      caseSensitive: false,
    ),
    valueGroup: 1,
  ),
  _SensitivePattern(
    category: 'HTTP cookie credential',
    expression: RegExp(
      r'\b(?:Cookie|Set-Cookie)[ \t]*:[ \t]*((?:[A-Za-z0-9_.-]+=[^;\s,]{8,})(?:;[ \t]*[A-Za-z0-9_.-]+=[^;\s,]+)*)',
      caseSensitive: false,
    ),
    valueGroup: 1,
  ),
  _SensitivePattern(
    category: 'credential assignment',
    expression: RegExp(
      r'''(?:^|[ \t"'`])(?:password|passwd|api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|secret[_-]?key|token)\b[ \t]*[:=][ \t]*["'`]?([A-Za-z0-9._~+/\[\]{}$<>-]{16,})''',
      caseSensitive: false,
    ),
    valueGroup: 1,
  ),
  _SensitivePattern(
    category: 'signed URL query credential',
    expression: RegExp(
      r'[?&](?:x-amz-signature|x-amz-credential|x-amz-security-token|awsaccesskeyid|x-goog-signature|x-goog-credential|googleaccessid|signature|sig|token|access[_-]?token|refresh[_-]?token|auth[_-]?token|api[_-]?key|access[_-]?key|client[_-]?secret|secret[_-]?key|key-pair-id|credential|key)=([^&#\s]{16,})',
      caseSensitive: false,
    ),
    valueGroup: 1,
  ),
];

final RegExp _secretBearingUrlPattern = RegExp(
  r'https?://[^\s"<>]*[?&](?:x-amz-signature|x-amz-credential|x-amz-security-token|awsaccesskeyid|x-goog-signature|x-goog-credential|googleaccessid|signature|sig|token|access[_-]?token|refresh[_-]?token|auth[_-]?token|api[_-]?key|access[_-]?key|client[_-]?secret|secret[_-]?key|key-pair-id|credential|key)=[^\s"<>]+',
  caseSensitive: false,
);

String _redactSensitiveDiagnosticText(String value) {
  String result = value.replaceAll(_secretBearingUrlPattern, '[REDACTED]');
  for (final pattern in _sensitivePatterns) {
    result = result.replaceAll(pattern.expression, '[REDACTED]');
  }
  return result;
}

final class _MetadataValue {
  final _MetadataValueKind kind;
  final String? scalar;
  final List<String> items;
  final int line;

  const _MetadataValue.scalar(this.scalar, this.line) : kind = _MetadataValueKind.scalar, items = const [];

  const _MetadataValue.nullValue(this.line) : kind = _MetadataValueKind.nullValue, scalar = null, items = const [];

  const _MetadataValue.list(this.items, this.line) : kind = _MetadataValueKind.list, scalar = null;
}

final class _ParsedMarkdown {
  final Map<String, _MetadataValue> metadata;
  final String body;
  final int bodyStartLine;
  final List<SpecificationIssue> issues;

  const _ParsedMarkdown({
    required this.metadata,
    required this.body,
    required this.bodyStartLine,
    required this.issues,
  });
}

final class _PendingList {
  final String key;
  final int line;
  final List<String> items = [];

  _PendingList(this.key, this.line);
}

final class _RecordLocation {
  final _RecordKind kind;
  final String relativePath;
  final String? productInputDirectoryDate;
  final bool? currentConflictDirectory;

  const _RecordLocation({
    required this.kind,
    required this.relativePath,
    this.productInputDirectoryDate,
    this.currentConflictDirectory,
  });
}

final class _SpecificationRecord {
  final _RecordKind kind;
  final String relativePath;
  final Map<String, _MetadataValue> metadata;
  final String body;
  final int bodyStartLine;
  final String? productInputDirectoryDate;
  final bool? currentConflictDirectory;

  _SpecificationRecord({
    required this.kind,
    required this.relativePath,
    required this.metadata,
    required this.body,
    required this.bodyStartLine,
    required this.productInputDirectoryDate,
    required this.currentConflictDirectory,
  });

  String? scalar(String key) {
    final value = metadata[key];
    if (value == null || value.kind != _MetadataValueKind.scalar) {
      return null;
    }
    return value.scalar;
  }

  List<String> list(String key) {
    final value = metadata[key];
    if (value == null || value.kind != _MetadataValueKind.list) {
      return const [];
    }
    return value.items;
  }

  List<String> singleReferenceAsList(String key) {
    final value = metadata[key];
    if (value == null || value.kind == _MetadataValueKind.nullValue) {
      return const [];
    }
    if (value.kind == _MetadataValueKind.list) {
      return value.items;
    }
    final scalarValue = value.scalar;
    if (scalarValue == null || scalarValue.isEmpty) {
      return const [];
    }
    return [scalarValue];
  }

  int lineFor(String key) {
    return metadata[key]?.line ?? 1;
  }

  String? get id {
    return scalar('id');
  }

  String? get recordDate {
    return scalar(kind.dateField);
  }
}

enum _ExpectedMetadataType {
  scalar,
  scalarOrNull,
  list,
  singleReference,
}

final class _RepositoryAlias {
  final String alias;
  final String root;
  final bool required;
  final String rowPath;
  final int line;

  const _RepositoryAlias({
    required this.alias,
    required this.root,
    required this.required,
    required this.rowPath,
    required this.line,
  });
}

final class _ResolvedReference {
  final String original;
  final String repositoryPath;
  final Directory repositoryRoot;
  final String? anchor;
  final bool checkExistence;

  const _ResolvedReference({
    required this.original,
    required this.repositoryPath,
    required this.repositoryRoot,
    required this.anchor,
    required this.checkExistence,
  });
}

final class _MarkdownTable {
  final List<String> headers;
  final List<_MarkdownTableRow> rows;
  final int headerLine;

  const _MarkdownTable({
    required this.headers,
    required this.rows,
    required this.headerLine,
  });
}

final class _MarkdownTableRow {
  final List<String> cells;
  final int line;

  const _MarkdownTableRow(this.cells, this.line);
}

final class SpecificationChecker {
  static const List<String> requiredFiles = [
    'AGENTS.md',
    '.github/copilot-instructions.md',
    'SPEC-LOOP.md',
    'docs/specification.md',
    'docs/specs/00-inventory.md',
    'docs/specs/01-authority-map.md',
    'docs/specs/02-repository-map.md',
    'docs/spec-process/rules.md',
    'docs/spec-process/changelog.md',
    'docs/spec-process/eval-cases.md',
    'docs/spec-process/templates.md',
    'docs/plans/PLANS.md',
    'docs/product-inputs/README.md',
    'docs/spec-process/decisions/README.md',
    'docs/spec-process/observations/README.md',
    'docs/spec-process/conflicts/README.md',
    'docs/spec-process/acceptance-records/README.md',
    '.agents/skills/spec-sync/SKILL.md',
    '.agents/skills/spec-sync/agents/openai.yaml',
  ];

  static const Map<String, List<String>> _requiredReferences = {
    'docs/specification.md': [
      'SPEC-LOOP.md',
      'docs/specs/00-inventory.md',
      'docs/specs/01-authority-map.md',
      'docs/specs/02-repository-map.md',
      'docs/spec-process/rules.md',
      'docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md',
      '.agents/skills/spec-sync/SKILL.md',
    ],
    'AGENTS.md': [
      'docs/specification.md',
      '.agents/skills/spec-sync/SKILL.md',
      'docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md',
      'docs/spec-process/conflicts/current/',
    ],
    '.agents/skills/spec-sync/SKILL.md': [
      'docs/specification.md',
      'docs/specs/00-inventory.md',
      'docs/specs/01-authority-map.md',
      'docs/specs/02-repository-map.md',
      'docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md',
      'docs/spec-process/conflicts/current/',
      'tools/bin/check_specification.dart',
      'SPEC-SYNC-ACCEPTANCE-GUARDRAILS',
    ],
    'docs/spec-process/eval-cases.md': [
      'SPEC-SYNC-ACCEPTANCE-GUARDRAILS',
    ],
    'docs/spec-process/rules.md': [
      'docs/specs/01-authority-map.md',
      'docs/specs/02-repository-map.md',
      'docs/spec-process/acceptance-records/',
    ],
    'docs/specs/00-inventory.md': [
      'docs/specs/01-authority-map.md',
      'docs/specs/02-repository-map.md',
    ],
  };

  static const Map<_RecordKind, Map<String, _ExpectedMetadataType>> _schemas = {
    _RecordKind.productInput: {
      'id': _ExpectedMetadataType.scalar,
      'type': _ExpectedMetadataType.scalar,
      'captured_date': _ExpectedMetadataType.scalar,
      'source_date': _ExpectedMetadataType.scalar,
      'source': _ExpectedMetadataType.scalar,
      'category': _ExpectedMetadataType.scalar,
      'status': _ExpectedMetadataType.scalar,
      'effective_status': _ExpectedMetadataType.scalar,
      'delivery_status': _ExpectedMetadataType.scalar,
      'canonical_assertions': _ExpectedMetadataType.list,
      'delivery_surfaces': _ExpectedMetadataType.list,
      'conflicts': _ExpectedMetadataType.list,
      'supersedes': _ExpectedMetadataType.list,
      'superseded_by': _ExpectedMetadataType.list,
      'decisions': _ExpectedMetadataType.list,
      'acceptance_records': _ExpectedMetadataType.list,
    },
    _RecordKind.decision: {
      'id': _ExpectedMetadataType.scalar,
      'type': _ExpectedMetadataType.scalar,
      'date': _ExpectedMetadataType.scalar,
      'status': _ExpectedMetadataType.scalar,
      'approved_by': _ExpectedMetadataType.scalar,
      'inputs': _ExpectedMetadataType.list,
      'observations': _ExpectedMetadataType.list,
      'conflicts': _ExpectedMetadataType.list,
      'supersedes': _ExpectedMetadataType.list,
      'superseded_by': _ExpectedMetadataType.list,
      'acceptance_records': _ExpectedMetadataType.list,
      'canonical_assertions': _ExpectedMetadataType.list,
      'affected_surfaces': _ExpectedMetadataType.list,
    },
    _RecordKind.observation: {
      'id': _ExpectedMetadataType.scalar,
      'type': _ExpectedMetadataType.scalar,
      'date': _ExpectedMetadataType.scalar,
      'status': _ExpectedMetadataType.scalar,
      'inputs': _ExpectedMetadataType.list,
      'conflicts': _ExpectedMetadataType.list,
      'decision': _ExpectedMetadataType.singleReference,
      'canonical_assertions': _ExpectedMetadataType.list,
      'affected_surfaces': _ExpectedMetadataType.list,
    },
    _RecordKind.conflict: {
      'id': _ExpectedMetadataType.scalar,
      'type': _ExpectedMetadataType.scalar,
      'status': _ExpectedMetadataType.scalar,
      'opened_date': _ExpectedMetadataType.scalar,
      'resolved_date': _ExpectedMetadataType.scalarOrNull,
      'inputs': _ExpectedMetadataType.list,
      'observations': _ExpectedMetadataType.list,
      'canonical_assertions': _ExpectedMetadataType.list,
      'affected_surfaces': _ExpectedMetadataType.list,
      'blocking_scope': _ExpectedMetadataType.scalar,
      'decision': _ExpectedMetadataType.singleReference,
    },
    _RecordKind.acceptance: {
      'id': _ExpectedMetadataType.scalar,
      'type': _ExpectedMetadataType.scalar,
      'date': _ExpectedMetadataType.scalar,
      'owner': _ExpectedMetadataType.scalar,
      'inputs': _ExpectedMetadataType.list,
      'decisions': _ExpectedMetadataType.list,
      'canonical_assertions': _ExpectedMetadataType.list,
      'changed_surfaces': _ExpectedMetadataType.list,
      'unresolved_conflicts': _ExpectedMetadataType.list,
      'result': _ExpectedMetadataType.scalar,
      'supersedes_acceptance': _ExpectedMetadataType.list,
      'superseded_by': _ExpectedMetadataType.list,
    },
  };

  static const Map<_RecordKind, List<String>> _requiredBodySections = {
    _RecordKind.productInput: [
      'Raw statement',
      'Extracted assertions',
    ],
    _RecordKind.decision: [
      'Decision',
      'Reason',
    ],
    _RecordKind.observation: [
      'Observation',
      'Implication',
      'Proposed next step',
      'Resolution',
    ],
    _RecordKind.conflict: [
      'Existing assertion',
      'New or observed assertion',
      'Required decision',
      'Resolution',
    ],
    _RecordKind.acceptance: [
      'Mechanical evidence',
      'Requirement review',
      'Semantic or visual review',
      'Exclusions',
    ],
  };

  static const Map<String, Map<String, Set<String>>> _productInputStateMatrix = {
    'inbox': {
      'pending': {
        'not_started',
        'planned',
      },
    },
    'deferred': {
      'pending': {
        'not_started',
        'planned',
      },
    },
    'conflict': {
      'pending': {
        'blocked',
      },
    },
    'merged': {
      'active': {
        'not_started',
        'planned',
        'in_progress',
        'implemented',
        'verified',
        'not_applicable',
      },
      'superseded': {
        'not_started',
        'planned',
        'in_progress',
        'implemented',
        'verified',
        'not_applicable',
      },
    },
    'dismissed': {
      'historical': {
        'not_applicable',
      },
    },
  };

  final Directory root;
  final List<SpecificationIssue> _issues = [];
  final List<_SpecificationRecord> _records = [];
  final Map<String, _SpecificationRecord> _recordsById = {};
  final Map<String, _RepositoryAlias> _aliases = {};
  final Set<String> _registeredAssertions = {};
  final Map<String, String> _assertionLifecycles = {};

  SpecificationChecker(Directory root) : root = Directory(path.normalize(root.absolute.path));

  SpecificationCheckResult check() {
    _issues.clear();
    _records.clear();
    _recordsById.clear();
    _aliases.clear();
    _registeredAssertions.clear();
    _assertionLifecycles.clear();

    _checkRepositoryRoot();
    _checkRequiredFiles();
    _checkRequiredReferences();
    _checkCoreVersion();
    _checkTemplateContract();
    _checkStateMatrixContract();
    _checkInstructionMirror();
    _checkMachineLocalPaths();
    _checkSensitiveMaterial();
    _checkPlans();
    _parseRepositoryMap();
    _scanRecords();
    _parseAuthorityMap();
    _validateRecords();
    return SpecificationCheckResult(_issues);
  }

  void _addIssue(
    String relativePath,
    String code,
    String message, {
    int line = 0,
  }) {
    _issues.add(
      SpecificationIssue(
        path: relativePath,
        line: line,
        code: code,
        message: message,
      ),
    );
  }

  String _absolutePath(String relativePath) {
    return path.join(root.path, path.fromUri(relativePath));
  }

  String _relativePath(FileSystemEntity entity) {
    return path.relative(entity.path, from: root.path).replaceAll(Platform.pathSeparator, '/');
  }

  void _checkRepositoryRoot() {
    if (_hasRepositoryMarkers(root)) {
      return;
    }
    _addIssue(
      '.',
      'invalid-root',
      'Repository root must contain AGENTS.md, pubspec.yaml, lib/, and tools/',
    );
  }

  void _checkRequiredFiles() {
    for (final relativePath in requiredFiles) {
      final file = File(_absolutePath(relativePath));
      if (file.existsSync()) {
        continue;
      }
      _addIssue(relativePath, 'required-file', 'Required Specification file is missing');
    }
  }

  void _checkRequiredReferences() {
    for (final entry in _requiredReferences.entries) {
      final file = File(_absolutePath(entry.key));
      if (!file.existsSync()) {
        continue;
      }
      final content = _readTextFile(entry.key);
      if (content == null) {
        continue;
      }
      for (final requiredReference in entry.value) {
        if (content.contains(requiredReference)) {
          continue;
        }
        _addIssue(
          entry.key,
          'required-reference',
          'Must reference $requiredReference',
        );
      }
    }
  }

  void _checkCoreVersion() {
    const versionedFiles = [
      'SPEC-LOOP.md',
      'docs/specification.md',
      'docs/specs/00-inventory.md',
      'docs/specs/01-authority-map.md',
      'docs/specs/02-repository-map.md',
      'docs/spec-process/rules.md',
      'docs/spec-process/templates.md',
      'docs/spec-process/changelog.md',
      'docs/spec-process/eval-cases.md',
      'docs/spec-process/acceptance-records/README.md',
    ];
    const dateRequiredFiles = {
      'SPEC-LOOP.md',
      'docs/specs/00-inventory.md',
      'docs/specs/01-authority-map.md',
      'docs/spec-process/rules.md',
      'docs/spec-process/changelog.md',
    };
    for (final relativePath in versionedFiles) {
      final content = _readTextFile(relativePath);
      if (content == null) {
        continue;
      }
      final version = _extractCurrentVersion(content);
      final effectiveDate = _extractCurrentEffectiveDate(content);
      if (version != specificationProcessVersion) {
        _addIssue(
          relativePath,
          'process-version',
          'Current process version must be $specificationProcessVersion, found ${version ?? '(missing)'}',
        );
      }
      final declaresEffectiveDate = RegExp(
        r'^\s*(?:[-*]\s*)?Effective date:',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(content);
      if (!dateRequiredFiles.contains(relativePath) && !declaresEffectiveDate) {
        continue;
      }
      if (effectiveDate != specificationProcessEffectiveDate) {
        _addIssue(
          relativePath,
          'process-date',
          'Current process effective date must be $specificationProcessEffectiveDate, found ${effectiveDate ?? '(missing)'}',
        );
      }
    }
  }

  void _checkTemplateContract() {
    const relativePath = 'docs/spec-process/templates.md';
    final content = _readTextFile(relativePath);
    if (content == null) {
      return;
    }
    const sectionNames = {
      _RecordKind.productInput: 'Product Or Process Input',
      _RecordKind.decision: 'Decision',
      _RecordKind.observation: 'Observation',
      _RecordKind.conflict: 'Conflict',
      _RecordKind.acceptance: 'Acceptance',
    };
    const expectedPaths = {
      _RecordKind.productInput: [
        'docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md',
      ],
      _RecordKind.decision: [
        'docs/spec-process/decisions/DEC-YYYYMMDD-SLUG.md',
      ],
      _RecordKind.observation: [
        'docs/spec-process/observations/OBS-YYYYMMDD-SLUG.md',
      ],
      _RecordKind.conflict: [
        'docs/spec-process/conflicts/current/CF-YYYYMMDD-SLUG.md',
        'docs/spec-process/conflicts/resolved/CF-YYYYMMDD-SLUG.md',
      ],
      _RecordKind.acceptance: [
        'docs/spec-process/acceptance-records/ACC-YYYYMMDD-SLUG.md',
      ],
    };
    final lines = content.split(RegExp(r'\r?\n'));
    final sectionIndexes = <String, List<int>>{};
    final outerHeadingIndexes = <int>[];
    bool inFence = false;
    for (int index = 0; index < lines.length; index += 1) {
      if (RegExp(r'^\s*```').hasMatch(lines[index])) {
        inFence = !inFence;
        continue;
      }
      if (inFence) {
        continue;
      }
      final heading = RegExp(r'^##\s+(.+?)\s*#*\s*$').firstMatch(lines[index]);
      if (heading == null) {
        continue;
      }
      outerHeadingIndexes.add(index);
      final name = _normalizeHeading(heading.group(1) ?? '');
      sectionIndexes.putIfAbsent(name, () => <int>[]).add(index);
    }
    for (final entry in sectionNames.entries) {
      final sectionName = entry.value;
      final indexes = sectionIndexes[_normalizeHeading(sectionName)] ?? const [];
      if (indexes.length != 1) {
        _addIssue(
          relativePath,
          'template-contract',
          'Template must contain exactly one "$sectionName" section',
        );
        continue;
      }
      final start = indexes.single;
      final outerPosition = outerHeadingIndexes.indexOf(start);
      final end = outerPosition >= 0 && outerPosition + 1 < outerHeadingIndexes.length
          ? outerHeadingIndexes[outerPosition + 1]
          : lines.length;
      final sectionLines = lines.sublist(start + 1, end);
      final paths = <String>[];
      for (final line in sectionLines) {
        final pathMatch = RegExp(
          r'^(?:(?:Current|Resolved)\s+)?Path:\s*`([^`]+)`\s*$',
          caseSensitive: false,
        ).firstMatch(line.trim());
        final templatePath = pathMatch?.group(1);
        if (templatePath == null) {
          continue;
        }
        paths.add(templatePath);
      }
      final requiredPaths = expectedPaths[entry.key] ?? const [];
      if (!_stringListsEqual(paths, requiredPaths)) {
        _addIssue(
          relativePath,
          'template-contract',
          '"$sectionName" Path declarations must be ${requiredPaths.join(', ')}',
          line: start + 1,
        );
      }
      final fencedMarkdown = _extractMarkdownFence(sectionLines);
      if (fencedMarkdown == null) {
        _addIssue(
          relativePath,
          'template-contract',
          '"$sectionName" must contain exactly one fenced markdown record template',
          line: start + 1,
        );
        continue;
      }
      final parsed = _parseFrontMatter(relativePath, fencedMarkdown);
      if (parsed.issues.isNotEmpty) {
        _addIssue(
          relativePath,
          'template-contract',
          '"$sectionName" template front matter must use the supported flat syntax',
          line: start + 1,
        );
      }
      final actualFields = parsed.metadata.keys.toSet();
      final expectedFields = (_schemas[entry.key] ?? const {}).keys.toSet();
      if (!_stringSetsEqual(actualFields, expectedFields)) {
        final missing = expectedFields.difference(actualFields).toList()..sort();
        final extra = actualFields.difference(expectedFields).toList()..sort();
        _addIssue(
          relativePath,
          'template-contract',
          '"$sectionName" metadata fields differ from the checker schema; missing: ${missing.isEmpty ? 'none' : missing.join(', ')}; '
              'extra: ${extra.isEmpty ? 'none' : extra.join(', ')}',
          line: start + 1,
        );
      }
      final schema = _schemas[entry.key] ?? const {};
      for (final schemaEntry in schema.entries) {
        final value = parsed.metadata[schemaEntry.key];
        if (value == null || _metadataTypeMatches(value, schemaEntry.value)) {
          continue;
        }
        _addIssue(
          relativePath,
          'template-contract',
          '"$sectionName" field ${schemaEntry.key} must be ${_expectedTypeDescription(schemaEntry.value)}',
          line: start + 1,
        );
      }
      final hasNonEmptyH1 = RegExp(
        r'^#[ \t]+\S.*$',
        multiLine: true,
      ).hasMatch(parsed.body);
      if (!hasNonEmptyH1) {
        _addIssue(
          relativePath,
          'template-contract',
          '"$sectionName" body must contain a non-empty H1',
          line: start + 1,
        );
      }
      final actualHeadings = RegExp(
        r'^#{2,6}\s+(.+?)\s*#*\s*$',
        multiLine: true,
      ).allMatches(parsed.body).map((RegExpMatch match) => _normalizeHeading(match.group(1) ?? '')).toList();
      final expectedHeadings = (_requiredBodySections[entry.key] ?? const []).map(_normalizeHeading).toList();
      if (_stringListsEqual(actualHeadings, expectedHeadings)) {
        continue;
      }
      _addIssue(
        relativePath,
        'template-contract',
        '"$sectionName" body headings must be ${(_requiredBodySections[entry.key] ?? const []).join(', ')}',
        line: start + 1,
      );
    }
  }

  String? _extractMarkdownFence(List<String> lines) {
    final fences = <String>[];
    int? start;
    for (int index = 0; index < lines.length; index += 1) {
      if (start == null) {
        if (lines[index].trim().toLowerCase() != '```markdown') {
          continue;
        }
        start = index + 1;
        continue;
      }
      if (lines[index].trim() != '```') {
        continue;
      }
      fences.add(lines.sublist(start, index).join('\n'));
      start = null;
    }
    if (fences.length != 1 || start != null) {
      return null;
    }
    return fences.single;
  }

  bool _stringListsEqual(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (int index = 0; index < left.length; index += 1) {
      if (left[index] == right[index]) {
        continue;
      }
      return false;
    }
    return true;
  }

  bool _stringSetsEqual(Set<String> left, Set<String> right) {
    return left.length == right.length && left.containsAll(right);
  }

  void _checkStateMatrixContract() {
    const relativePath = 'docs/spec-process/rules.md';
    final content = _readTextFile(relativePath);
    if (content == null) {
      return;
    }
    const headers = [
      'status',
      'effective_status',
      'delivery_status',
    ];
    final table = _findMarkdownTable(content, headers);
    if (table == null) {
      _addIssue(
        relativePath,
        'state-matrix-contract',
        'Rules must contain the status | effective_status | delivery_status table',
      );
      return;
    }
    final expectedRows = <String, Set<String>>{};
    for (final statusEntry in _productInputStateMatrix.entries) {
      for (final effectiveEntry in statusEntry.value.entries) {
        expectedRows['${statusEntry.key}|${effectiveEntry.key}'] = effectiveEntry.value;
      }
    }
    if (table.rows.length != expectedRows.length) {
      _addIssue(
        relativePath,
        'state-matrix-contract',
        'State matrix must contain exactly ${expectedRows.length} rows',
        line: table.headerLine,
      );
    }
    final seenRows = <String>{};
    for (final row in table.rows) {
      final status = _plainCell(row.cells[0]).toLowerCase();
      final effectiveStatus = _plainCell(row.cells[1]).toLowerCase();
      final key = '$status|$effectiveStatus';
      final expectedDeliveries = expectedRows[key];
      final actualDeliveries = _parseDeliveryMatrixCell(row.cells[2]);
      if (expectedDeliveries == null || actualDeliveries == null) {
        _addIssue(
          relativePath,
          'state-matrix-contract',
          'Unexpected state matrix row: ${row.cells.join(' | ')}',
          line: row.line,
        );
        continue;
      }
      if (!seenRows.add(key)) {
        _addIssue(
          relativePath,
          'state-matrix-contract',
          'State matrix row $key is duplicated',
          line: row.line,
        );
      }
      if (_stringSetsEqual(actualDeliveries, expectedDeliveries)) {
        continue;
      }
      final expected = expectedDeliveries.toList()..sort();
      _addIssue(
        relativePath,
        'state-matrix-contract',
        'State matrix row $key must allow exactly ${expected.join(', ')}',
        line: row.line,
      );
    }
    for (final key in expectedRows.keys) {
      if (seenRows.contains(key)) {
        continue;
      }
      _addIssue(
        relativePath,
        'state-matrix-contract',
        'State matrix is missing row $key',
        line: table.headerLine,
      );
    }
  }

  Set<String>? _parseDeliveryMatrixCell(String cell) {
    final knownDeliveries = <String>{};
    for (final effectiveStates in _productInputStateMatrix.values) {
      for (final deliveries in effectiveStates.values) {
        knownDeliveries.addAll(deliveries);
      }
    }
    final normalized = cell
        .replaceAll('`', ' ')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\bor\b', caseSensitive: false), ' ')
        .trim()
        .toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    final tokens = normalized.split(RegExp(r'\s+'));
    final result = <String>{};
    for (final token in tokens) {
      if (!knownDeliveries.contains(token)) {
        return null;
      }
      result.add(token);
    }
    return result;
  }

  void _checkPlans() {
    const plansPath = 'docs/plans';
    final directory = Directory(_absolutePath(plansPath));
    if (!directory.existsSync()) {
      return;
    }
    const requiredSections = [
      'Scope',
      'Linked Truth',
      'Intended Behavior',
      'Exclusions',
      'Milestones',
      'Mechanical Checks',
      'Result-Level Review',
      'Progress',
      'Discoveries And Decisions',
      'Remaining Gaps',
      'Retrospective',
      'Outcome',
    ];
    final entities = directory.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is! File || !entity.path.endsWith('.md') || path.basename(entity.path) == 'PLANS.md') {
        continue;
      }
      final relativePath = _relativePath(entity);
      final content = _readTextFile(relativePath);
      if (content == null) {
        continue;
      }
      final lines = content.split(RegExp(r'\r?\n'));
      final sectionIndexes = <String, List<int>>{};
      final outerH2Indexes = <int>[];
      bool hasH1 = false;
      bool inFence = false;
      String? status;
      String? started;
      for (int index = 0; index < lines.length; index += 1) {
        if (RegExp(r'^\s*(?:```|~~~)').hasMatch(lines[index])) {
          inFence = !inFence;
          continue;
        }
        if (inFence) {
          continue;
        }
        final statusMatch = RegExp(
          r'^\s*Status:\s*(.+?)\s*$',
          caseSensitive: false,
        ).firstMatch(lines[index]);
        if (statusMatch != null) {
          status = statusMatch.group(1)?.trim().toLowerCase();
        }
        final startedMatch = RegExp(
          r'^\s*Started:\s*(\S+)\s*$',
          caseSensitive: false,
        ).firstMatch(lines[index]);
        if (startedMatch != null) {
          started = startedMatch.group(1);
        }
        final heading = RegExp(r'^(#{1,6})[ \t]+(.+?)\s*#*\s*$').firstMatch(lines[index]);
        if (heading == null) {
          continue;
        }
        final level = heading.group(1)?.length ?? 0;
        final headingName = (heading.group(2) ?? '').trim();
        if (level == 1 && headingName.isNotEmpty) {
          hasH1 = true;
        }
        if (level != 2) {
          continue;
        }
        outerH2Indexes.add(index);
        final normalizedName = _normalizeHeading(headingName);
        sectionIndexes.putIfAbsent(normalizedName, () => <int>[]).add(index);
      }
      if (!hasH1) {
        _addIssue(
          relativePath,
          'plan-contract',
          'Plan must contain a non-empty H1',
        );
      }
      if (!const {'in progress', 'completed', 'blocked'}.contains(status)) {
        _addIssue(
          relativePath,
          'plan-status',
          'Plan Status must be in progress, completed, or blocked',
        );
      }
      if (started == null || !_validDate(started)) {
        _addIssue(
          relativePath,
          'plan-started',
          'Plan Started must be a valid YYYY-MM-DD date',
        );
      }
      for (final section in requiredSections) {
        final indexes = sectionIndexes[_normalizeHeading(section)] ?? const [];
        if (indexes.length != 1) {
          _addIssue(
            relativePath,
            'plan-contract',
            'Plan must contain exactly one "$section" section required by docs/plans/PLANS.md',
          );
          continue;
        }
        final sectionStart = indexes.single;
        final headingPosition = outerH2Indexes.indexOf(sectionStart);
        final sectionEnd = headingPosition >= 0 && headingPosition + 1 < outerH2Indexes.length
            ? outerH2Indexes[headingPosition + 1]
            : lines.length;
        final sectionBody = lines.sublist(sectionStart + 1, sectionEnd).join('\n');
        if (!_meaningfulMarkdown(sectionBody)) {
          _addIssue(
            relativePath,
            'plan-contract',
            'Plan section "$section" must be meaningful',
            line: sectionStart + 1,
          );
          continue;
        }
        if (section != 'Progress') {
          continue;
        }
        final progressDates = RegExp(
          r'\b\d{4}-\d{2}-\d{2}\b',
        ).allMatches(sectionBody).map((RegExpMatch match) => match.group(0)).whereType<String>();
        if (progressDates.any(_validDate)) {
          continue;
        }
        _addIssue(
          relativePath,
          'plan-contract',
          'Plan Progress must contain at least one valid YYYY-MM-DD date',
          line: sectionStart + 1,
        );
      }
    }
  }

  String? _extractCurrentVersion(String content) {
    final labeled = RegExp(
      r'^\s*(?:[-*]\s*)?(?:Process version|Current version|Version):\s*`?(v\d+(?:\.\d+)*)`?\s*$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(content);
    if (labeled != null) {
      return labeled.group(1)?.toLowerCase();
    }
    final heading = RegExp(
      r'^#{1,6}\s+`?(v\d+(?:\.\d+)*)`?\b',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(content);
    return heading?.group(1)?.toLowerCase();
  }

  String? _extractCurrentEffectiveDate(String content) {
    final labeled = RegExp(
      r'^\s*(?:[-*]\s*)?(?:Effective date|Current date|Date):\s*`?(\d{4}-\d{2}-\d{2})`?\s*$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(content);
    if (labeled != null) {
      return labeled.group(1);
    }
    final versionHeading = RegExp(
      r'^#{1,6}\s+`?v\d+(?:\.\d+)*`?.*?(\d{4}-\d{2}-\d{2})',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(content);
    return versionHeading?.group(1);
  }

  void _checkInstructionMirror() {
    final agents = File(_absolutePath('AGENTS.md'));
    final copilot = File(_absolutePath('.github/copilot-instructions.md'));
    if (!agents.existsSync() || !copilot.existsSync()) {
      return;
    }
    final agentsBytes = agents.readAsBytesSync();
    final copilotBytes = copilot.readAsBytesSync();
    if (specificationInstructionMirrorMatches(
      agentsBytes: agentsBytes,
      copilotBytes: copilotBytes,
    )) {
      return;
    }
    _addIssue(
      '.github/copilot-instructions.md',
      'instruction-mirror',
      'Must be byte-for-byte identical to AGENTS.md',
    );
  }

  String? _readTextFile(String relativePath) {
    final file = File(_absolutePath(relativePath));
    if (!file.existsSync()) {
      return null;
    }
    try {
      return utf8.decode(file.readAsBytesSync());
    } on FormatException catch (error) {
      _addIssue(
        relativePath,
        'invalid-utf8',
        'Markdown must be valid UTF-8: $error',
      );
      return null;
    } on FileSystemException catch (error) {
      _addIssue(
        relativePath,
        'read-error',
        'Could not read file: ${error.message}',
      );
      return null;
    }
  }

  void _checkMachineLocalPaths() {
    final candidates = <String>{};
    const directFiles = [
      'SPEC-LOOP.md',
      'docs/specification.md',
    ];
    for (final relativePath in directFiles) {
      if (File(_absolutePath(relativePath)).existsSync()) {
        candidates.add(relativePath);
      }
    }
    const directories = [
      'docs/specs',
      'docs/spec-process',
      'docs/product-inputs',
      'docs/plans',
    ];
    for (final directoryPath in directories) {
      final directory = Directory(_absolutePath(directoryPath));
      if (FileSystemEntity.typeSync(directory.path, followLinks: false) == FileSystemEntityType.link) {
        continue;
      }
      if (!directory.existsSync()) {
        continue;
      }
      final entities = directory.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
          continue;
        }
        candidates.add(_relativePath(entity));
      }
    }
    final patterns = [
      RegExp(r'''(?:^|[\s("'`<=>])(?<path>\/Users\/[^\s)>'"`]+)'''),
      RegExp(r'''(?:^|[\s("'`<=>])(?<path>\/home\/[^\s)>'"`]+)'''),
      RegExp(r'''(?:^|[\s("'`<=>])(?<path>\/(?:private\/)?var\/folders\/[^\s)>'"`]+)'''),
      RegExp(r'''(?:^|[\s("'`<=>])(?<path>\/(?:private\/)?tmp\/[^\s)>'"`]+)'''),
      RegExp(r'''(?:^|[\s("'`<=>])(?<path>[A-Za-z]:[\\/][^\s)>'"`]+)'''),
      RegExp(r'''(?:^|[\s("'`<=>])(?<path>\\\\[^\\\s]+\\[^\s)>'"`]+)'''),
      RegExp(r'''(?<path>\bfile:(?:/{1,3})[^\s)>'"`]+)''', caseSensitive: false),
    ];
    for (final relativePath in candidates) {
      final content = _readTextFile(relativePath);
      if (content == null) {
        continue;
      }
      final lines = content.split(RegExp(r'\r?\n'));
      bool inFence = false;
      String? fenceMarker;
      final scanFencedContent = _isSpecificationRecordOrPlan(relativePath);
      for (int index = 0; index < lines.length; index += 1) {
        final line = lines[index];
        final fence = RegExp(r'^\s*(`{3,}|~{3,})').firstMatch(line);
        if (fence != null) {
          final marker = fence.group(1);
          if (!inFence) {
            inFence = true;
            fenceMarker = marker?[0];
            continue;
          }
          if (marker != null && marker.startsWith(fenceMarker ?? marker[0])) {
            inFence = false;
            fenceMarker = null;
          }
          continue;
        }
        if (inFence && !scanFencedContent) {
          continue;
        }
        bool matched = false;
        for (final pattern in patterns) {
          final matches = pattern.allMatches(line);
          if (matches.isEmpty) {
            continue;
          }
          for (final match in matches) {
            final localPath = match.namedGroup('path') ?? match.group(0) ?? '';
            if (_isPlaceholderMachinePath(localPath)) {
              continue;
            }
            matched = true;
            break;
          }
          if (matched) {
            break;
          }
        }
        if (!matched) {
          continue;
        }
        _addIssue(
          relativePath,
          'machine-path',
          'Durable Specification content contains a machine-local absolute path or file URL',
          line: index + 1,
        );
      }
    }
  }

  bool _isSpecificationRecordOrPlan(String relativePath) {
    if (relativePath.startsWith('docs/plans/')) {
      return true;
    }
    if (relativePath.startsWith('docs/product-inputs/evidence/')) {
      return true;
    }
    if (RegExp(r'^docs/product-inputs/\d{4}-\d{2}-\d{2}/PI-.*\.md$').hasMatch(relativePath)) {
      return true;
    }
    return RegExp(
      r'^docs/spec-process/(?:decisions|observations|conflicts/(?:current|resolved)|acceptance-records)/(?:DEC|OBS|CF|ACC)-.*\.md$',
    ).hasMatch(relativePath);
  }

  bool _isPlaceholderMachinePath(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('...') ||
        normalized.contains('<user') ||
        normalized.contains('<name') ||
        normalized.contains('{user') ||
        normalized.contains(r'$user') ||
        normalized.contains('%username%');
  }

  void _checkSensitiveMaterial() {
    const directories = [
      'docs/product-inputs',
      'docs/spec-process/decisions',
      'docs/spec-process/observations',
      'docs/spec-process/conflicts',
      'docs/spec-process/acceptance-records',
    ];
    final candidates = <String>{};
    for (final directoryPath in directories) {
      final directory = Directory(_absolutePath(directoryPath));
      if (FileSystemEntity.typeSync(directory.path, followLinks: false) == FileSystemEntityType.link) {
        continue;
      }
      if (!directory.existsSync()) {
        continue;
      }
      final entities = directory.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
          continue;
        }
        final relativePath = _relativePath(entity);
        if (_isSensitiveMaterialCandidate(relativePath)) {
          candidates.add(relativePath);
        }
      }
    }
    for (final relativePath in candidates) {
      final content = _readTextFile(relativePath);
      if (content == null) {
        continue;
      }
      final lines = content.split(RegExp(r'\r?\n'));
      for (int index = 0; index < lines.length; index += 1) {
        for (final pattern in _sensitivePatterns) {
          final matches = pattern.expression.allMatches(lines[index]);
          for (final match in matches) {
            final candidate = match.group(pattern.valueGroup) ?? '';
            final explicitlyRedactedPem = pattern.category == 'PEM private key' && _hasExplicitPemRedaction(lines, index);
            if (_isSecretPlaceholder(candidate) || explicitlyRedactedPem) {
              continue;
            }
            _addIssue(
              relativePath,
              'secret-material',
              'Possible ${pattern.category} detected; replace the value with an explicit redaction marker',
              line: index + 1,
            );
          }
        }
      }
    }
  }

  bool _isSensitiveMaterialCandidate(String relativePath) {
    if (relativePath.startsWith('docs/product-inputs/evidence/')) {
      return true;
    }
    if (RegExp(r'^docs/product-inputs/\d{4}-\d{2}-\d{2}/PI-.*\.md$').hasMatch(relativePath)) {
      return true;
    }
    return RegExp(
      r'^docs/spec-process/(?:decisions|observations|conflicts/(?:current|resolved)|acceptance-records)/(?:DEC|OBS|CF|ACC)-.*\.md$',
    ).hasMatch(relativePath);
  }

  bool _isSecretPlaceholder(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('redacted') ||
        normalized.contains('%5bredacted%5d') ||
        normalized.contains('placeholder') ||
        normalized.contains('your_') ||
        normalized.contains('your-') ||
        normalized.contains(r'${') ||
        normalized.contains('{{')) {
      return true;
    }
    if (RegExp(
      r'^<[^>]*(?:token|secret|key|credential|password)[^>]*>$',
      caseSensitive: false,
    ).hasMatch(value.trim())) {
      return true;
    }
    final valueOnly = value.split(RegExp(r'[=\s]')).last;
    return RegExp(r'^[0xX*._-]+$').hasMatch(valueOnly);
  }

  bool _hasExplicitPemRedaction(List<String> lines, int headerIndex) {
    final headerLine = lines[headerIndex].trim();
    final sameLineRedaction = RegExp(
      '-----BEGIN $_privateKeyLabelPattern-----'
      r'[ \t]*(?:\[REDACTED\]|<REDACTED>|\$\{[A-Z0-9_]+\}|\{\{[A-Z0-9_]+\}\})[ \t]*$',
      caseSensitive: false,
    );
    if (sameLineRedaction.hasMatch(headerLine)) {
      return true;
    }
    final header = RegExp(
      '^-----BEGIN ($_privateKeyLabelPattern)-----\$',
      caseSensitive: false,
    ).firstMatch(headerLine);
    if (header == null) {
      return false;
    }
    int markerIndex = headerIndex + 1;
    while (markerIndex < lines.length && lines[markerIndex].trim().isEmpty) {
      markerIndex += 1;
    }
    if (markerIndex >= lines.length || !_isExplicitRedactionMarker(lines[markerIndex].trim())) {
      return false;
    }
    int footerIndex = markerIndex + 1;
    while (footerIndex < lines.length && lines[footerIndex].trim().isEmpty) {
      footerIndex += 1;
    }
    if (footerIndex >= lines.length) {
      return false;
    }
    final keyKind = header.group(1) ?? '';
    return lines[footerIndex].trim().toLowerCase() == '-----end ${keyKind.toLowerCase()}-----';
  }

  bool _isExplicitRedactionMarker(String value) {
    if (const {'[REDACTED]', '<REDACTED>'}.contains(value.toUpperCase())) {
      return true;
    }
    return RegExp(
      r'^(?:\$\{[A-Z0-9_]+\}|\{\{[A-Z0-9_]+\}\})$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  void _parseRepositoryMap() {
    const relativePath = 'docs/specs/02-repository-map.md';
    final content = _readTextFile(relativePath);
    if (content == null) {
      return;
    }
    const expectedHeaders = [
      'Alias',
      'Root',
      'Required',
      'Description',
    ];
    final table = _findMarkdownTable(content, expectedHeaders);
    if (table == null) {
      _addIssue(
        relativePath,
        'repository-map-table',
        'Must contain the table: Alias | Root | Required | Description',
      );
      return;
    }
    for (final row in table.rows) {
      final alias = _plainCell(row.cells[0]);
      final repositoryRoot = _plainCell(row.cells[1]);
      final requiredValue = _plainCell(row.cells[2]).toLowerCase();
      final description = _plainCell(row.cells[3]);
      if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(alias)) {
        _addIssue(
          relativePath,
          'repository-alias',
          'Alias "$alias" must use lowercase letters, digits, underscores, or hyphens',
          line: row.line,
        );
        continue;
      }
      if (_aliases.containsKey(alias)) {
        _addIssue(
          relativePath,
          'repository-alias',
          'Alias "$alias" is duplicated',
          line: row.line,
        );
        continue;
      }
      final required = _parseRequiredCell(requiredValue);
      if (required == null) {
        _addIssue(
          relativePath,
          'repository-required',
          'Required must be yes/no, true/false, or required/optional',
          line: row.line,
        );
        continue;
      }
      if (!_validRepositoryRoot(repositoryRoot)) {
        _addIssue(
          relativePath,
          'repository-root',
          'Root "$repositoryRoot" must be a relative filesystem path without a file URL',
          line: row.line,
        );
        continue;
      }
      if (description.isEmpty) {
        _addIssue(
          relativePath,
          'repository-description',
          'Description must not be empty',
          line: row.line,
        );
      }
      final repositoryAlias = _RepositoryAlias(
        alias: alias,
        root: repositoryRoot,
        required: required,
        rowPath: relativePath,
        line: row.line,
      );
      _aliases[alias] = repositoryAlias;
      if (!required) {
        continue;
      }
      final resolvedRoot = Directory(path.normalize(path.join(root.path, repositoryRoot)));
      if (resolvedRoot.existsSync()) {
        continue;
      }
      _addIssue(
        relativePath,
        'repository-root-missing',
        'Required repository root "$repositoryRoot" for alias "$alias" does not exist',
        line: row.line,
      );
    }
  }

  bool? _parseRequiredCell(String value) {
    if (const {'yes', 'true', 'required'}.contains(value)) {
      return true;
    }
    if (const {'no', 'false', 'optional'}.contains(value)) {
      return false;
    }
    return null;
  }

  bool _validRepositoryRoot(String value) {
    if (value.isEmpty) {
      return false;
    }
    if (value.contains('\\') || value.contains('\u0000')) {
      return false;
    }
    if (value.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(value)) {
      return false;
    }
    if (RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*://').hasMatch(value)) {
      return false;
    }
    if (value == '.') {
      return true;
    }
    final segments = value.split('/');
    if (segments.every((String segment) => segment.isNotEmpty && segment != '..')) {
      return true;
    }
    if (segments.length < 2 || segments.first != '..') {
      return false;
    }
    for (int index = 1; index < segments.length; index += 1) {
      final segment = segments[index];
      if (segment.isEmpty || segment == '.' || segment == '..') {
        return false;
      }
    }
    return true;
  }

  _MarkdownTable? _findMarkdownTable(String content, List<String> expectedHeaders) {
    final lines = content.split(RegExp(r'\r?\n'));
    for (int index = 0; index < lines.length; index += 1) {
      final cells = _splitMarkdownTableLine(lines[index]);
      if (cells == null || !_headersEqual(cells, expectedHeaders)) {
        continue;
      }
      if (index + 1 >= lines.length) {
        return null;
      }
      final separators = _splitMarkdownTableLine(lines[index + 1]);
      if (separators == null || separators.length != expectedHeaders.length) {
        return null;
      }
      bool separatorValid = true;
      for (final separator in separators) {
        if (RegExp(r'^:?-{3,}:?$').hasMatch(separator.trim())) {
          continue;
        }
        separatorValid = false;
        break;
      }
      if (!separatorValid) {
        return null;
      }
      final rows = <_MarkdownTableRow>[];
      for (int rowIndex = index + 2; rowIndex < lines.length; rowIndex += 1) {
        if (lines[rowIndex].trim().isEmpty) {
          break;
        }
        final rowCells = _splitMarkdownTableLine(lines[rowIndex]);
        if (rowCells == null || rowCells.length != expectedHeaders.length) {
          break;
        }
        rows.add(_MarkdownTableRow(rowCells, rowIndex + 1));
      }
      return _MarkdownTable(
        headers: cells,
        rows: rows,
        headerLine: index + 1,
      );
    }
    return null;
  }

  bool _headersEqual(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) {
      return false;
    }
    for (int index = 0; index < actual.length; index += 1) {
      if (actual[index].trim().toLowerCase() == expected[index].toLowerCase()) {
        continue;
      }
      return false;
    }
    return true;
  }

  List<String>? _splitMarkdownTableLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|') || !trimmed.endsWith('|')) {
      return null;
    }
    final body = trimmed.substring(1, trimmed.length - 1);
    final cells = <String>[];
    final buffer = StringBuffer();
    bool escaped = false;
    for (int index = 0; index < body.length; index += 1) {
      final character = body[index];
      if (escaped) {
        buffer.write(character);
        escaped = false;
        continue;
      }
      if (character == '\\') {
        escaped = true;
        buffer.write(character);
        continue;
      }
      if (character != '|') {
        buffer.write(character);
        continue;
      }
      cells.add(buffer.toString().trim());
      buffer.clear();
    }
    cells.add(buffer.toString().trim());
    return cells;
  }

  String _plainCell(String value) {
    String result = value.trim();
    if (result.startsWith('`') && result.endsWith('`') && result.length >= 2) {
      result = result.substring(1, result.length - 1).trim();
    }
    return result;
  }

  void _scanRecords() {
    _scanProductInputs();
    _scanSimpleRecordDirectory(
      'docs/spec-process/decisions',
      _RecordKind.decision,
    );
    _scanSimpleRecordDirectory(
      'docs/spec-process/observations',
      _RecordKind.observation,
    );
    _scanConflictDirectory();
    _scanSimpleRecordDirectory(
      'docs/spec-process/acceptance-records',
      _RecordKind.acceptance,
    );
  }

  void _scanProductInputs() {
    const basePath = 'docs/product-inputs';
    final directory = Directory(_absolutePath(basePath));
    if (_rejectRecordRootLink(basePath, directory)) {
      return;
    }
    if (!directory.existsSync()) {
      _addIssue(basePath, 'record-directory', 'Product input directory is missing');
      return;
    }
    final entities = directory.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (_rejectRecordLink(entity)) {
        continue;
      }
      if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
        continue;
      }
      final relativePath = _relativePath(entity);
      if (path.basename(relativePath) == 'README.md') {
        continue;
      }
      final relativeFromBase = path.relative(entity.path, from: directory.path);
      final segments = path.split(relativeFromBase);
      if (segments.isNotEmpty && segments.first == 'evidence') {
        if (RegExp(r'^PI-[A-Z0-9]+(?:-[A-Z0-9]+)*\.md$').hasMatch(segments.last)) {
          _addIssue(
            relativePath,
            'evidence-record',
            'Evidence files must not use PI record filenames or act as product input records',
          );
        }
        continue;
      }
      if (segments.length != 2 || !_validDate(segments[0])) {
        _addIssue(
          relativePath,
          'record-path',
          'Product input Markdown must be docs/product-inputs/YYYY-MM-DD/PI-*.md',
        );
        continue;
      }
      if (!RegExp(r'^PI-[A-Z0-9]+(?:-[A-Z0-9]+)*\.md$').hasMatch(segments[1])) {
        _addIssue(
          relativePath,
          'record-filename',
          'Product input filename must be PI-YYYYMMDD-SLUG.md',
        );
        continue;
      }
      _parseRecord(
        _RecordLocation(
          kind: _RecordKind.productInput,
          relativePath: relativePath,
          productInputDirectoryDate: segments[0],
        ),
      );
    }
  }

  void _scanSimpleRecordDirectory(String basePath, _RecordKind kind) {
    final directory = Directory(_absolutePath(basePath));
    if (_rejectRecordRootLink(basePath, directory)) {
      return;
    }
    if (!directory.existsSync()) {
      _addIssue(basePath, 'record-directory', 'Record directory is missing');
      return;
    }
    final entities = directory.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (_rejectRecordLink(entity)) {
        continue;
      }
      if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
        continue;
      }
      final relativePath = _relativePath(entity);
      if (path.basename(relativePath) == 'README.md') {
        continue;
      }
      final relativeFromBase = path.relative(entity.path, from: directory.path);
      final segments = path.split(relativeFromBase);
      final filenamePattern = RegExp('^${kind.prefix}-[A-Z0-9]+(?:-[A-Z0-9]+)*\\.md\$');
      if (segments.length != 1 || !filenamePattern.hasMatch(segments.single)) {
        _addIssue(
          relativePath,
          'record-filename',
          '${kind.prefix} Markdown filename must be ${kind.prefix}-YYYYMMDD-SLUG.md directly under $basePath',
        );
        continue;
      }
      _parseRecord(
        _RecordLocation(
          kind: kind,
          relativePath: relativePath,
        ),
      );
    }
  }

  void _scanConflictDirectory() {
    const basePath = 'docs/spec-process/conflicts';
    final directory = Directory(_absolutePath(basePath));
    if (_rejectRecordRootLink(basePath, directory)) {
      return;
    }
    if (!directory.existsSync()) {
      _addIssue(basePath, 'record-directory', 'Conflict directory is missing');
      return;
    }
    final entities = directory.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (_rejectRecordLink(entity)) {
        continue;
      }
      if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
        continue;
      }
      final relativePath = _relativePath(entity);
      if (path.basename(relativePath) == 'README.md') {
        continue;
      }
      final relativeFromBase = path.relative(entity.path, from: directory.path);
      final segments = path.split(relativeFromBase);
      final validPartition = segments.length == 2 && const {'current', 'resolved'}.contains(segments[0]);
      final validFilename = segments.isNotEmpty && RegExp(r'^CF-[A-Z0-9]+(?:-[A-Z0-9]+)*\.md$').hasMatch(segments.last);
      if (!validPartition || !validFilename) {
        _addIssue(
          relativePath,
          'record-filename',
          'Conflict Markdown must be conflicts/current/CF-*.md or conflicts/resolved/CF-*.md',
        );
        continue;
      }
      _parseRecord(
        _RecordLocation(
          kind: _RecordKind.conflict,
          relativePath: relativePath,
          currentConflictDirectory: segments[0] == 'current',
        ),
      );
    }
  }

  bool _rejectRecordRootLink(String basePath, Directory directory) {
    if (FileSystemEntity.typeSync(directory.path, followLinks: false) != FileSystemEntityType.link) {
      return false;
    }
    _addIssue(
      basePath,
      'record-symlink',
      'Specification record roots must be real directories, not symbolic links',
    );
    return true;
  }

  bool _rejectRecordLink(FileSystemEntity entity) {
    if (entity is! Link) {
      return false;
    }
    _addIssue(
      _relativePath(entity),
      'record-symlink',
      'Specification record and evidence directories must not contain symbolic links',
    );
    return true;
  }

  void _parseRecord(_RecordLocation location) {
    final content = _readTextFile(location.relativePath);
    if (content == null) {
      return;
    }
    final parsed = _parseFrontMatter(location.relativePath, content);
    _issues.addAll(parsed.issues);
    final record = _SpecificationRecord(
      kind: location.kind,
      relativePath: location.relativePath,
      metadata: parsed.metadata,
      body: parsed.body,
      bodyStartLine: parsed.bodyStartLine,
      productInputDirectoryDate: location.productInputDirectoryDate,
      currentConflictDirectory: location.currentConflictDirectory,
    );
    _records.add(record);
    _validateSchema(record);
    _validateRecordIdentity(record);
    _validateBody(record);
    final recordId = record.id;
    if (recordId == null || !_validIdForKind(recordId, record.kind)) {
      return;
    }
    final existing = _recordsById[recordId];
    if (existing != null) {
      _addIssue(
        record.relativePath,
        'duplicate-id',
        'ID $recordId is already used by ${existing.relativePath}',
        line: record.lineFor('id'),
      );
      _addIssue(
        existing.relativePath,
        'duplicate-id',
        'ID $recordId is also used by ${record.relativePath}',
        line: existing.lineFor('id'),
      );
      return;
    }
    _recordsById[recordId] = record;
  }

  _ParsedMarkdown _parseFrontMatter(String relativePath, String content) {
    String normalized = content;
    if (normalized.startsWith('\uFEFF')) {
      normalized = normalized.substring(1);
    }
    final lines = normalized.split(RegExp(r'\r?\n'));
    final issues = <SpecificationIssue>[];
    if (lines.isEmpty || lines.first != '---') {
      issues.add(
        SpecificationIssue(
          path: relativePath,
          line: 1,
          code: 'frontmatter',
          message: 'Record must start with an exact --- front matter delimiter',
        ),
      );
      return _ParsedMarkdown(
        metadata: const {},
        body: normalized,
        bodyStartLine: 1,
        issues: issues,
      );
    }
    int closingIndex = -1;
    for (int index = 1; index < lines.length; index += 1) {
      if (lines[index] != '---') {
        continue;
      }
      closingIndex = index;
      break;
    }
    if (closingIndex < 0) {
      issues.add(
        SpecificationIssue(
          path: relativePath,
          line: 1,
          code: 'frontmatter',
          message: 'Front matter is missing its closing --- delimiter',
        ),
      );
      return _ParsedMarkdown(
        metadata: const {},
        body: '',
        bodyStartLine: lines.length + 1,
        issues: issues,
      );
    }
    final metadata = <String, _MetadataValue>{};
    _PendingList? pendingList;

    void finishPendingList() {
      final pending = pendingList;
      if (pending == null) {
        return;
      }
      if (pending.items.isEmpty) {
        issues.add(
          SpecificationIssue(
            path: relativePath,
            line: pending.line,
            code: 'frontmatter-value',
            message: '${pending.key} has an empty value; use null or [] explicitly',
          ),
        );
      }
      metadata[pending.key] = _MetadataValue.list(
        List<String>.unmodifiable(pending.items),
        pending.line,
      );
      pendingList = null;
    }

    for (int index = 1; index < closingIndex; index += 1) {
      final line = lines[index];
      final lineNumber = index + 1;
      if (line.trim().isEmpty) {
        continue;
      }
      final listItem = RegExp(r'^  -\s+(.+?)\s*$').firstMatch(line);
      if (listItem != null) {
        final pending = pendingList;
        if (pending == null) {
          issues.add(
            SpecificationIssue(
              path: relativePath,
              line: lineNumber,
              code: 'frontmatter-list',
              message: 'List item must follow a key with no inline value',
            ),
          );
          continue;
        }
        final parsedItem = _parseScalarToken(listItem.group(1) ?? '');
        if (parsedItem == null || parsedItem.isEmpty) {
          issues.add(
            SpecificationIssue(
              path: relativePath,
              line: lineNumber,
              code: 'frontmatter-list',
              message: 'List item must be a non-empty scalar',
            ),
          );
          continue;
        }
        pending.items.add(parsedItem);
        continue;
      }
      finishPendingList();
      final keyMatch = RegExp(r'^([a-z][a-z0-9_]*):(.*)$').firstMatch(line);
      if (keyMatch == null) {
        issues.add(
          SpecificationIssue(
            path: relativePath,
            line: lineNumber,
            code: 'frontmatter-syntax',
            message: 'Only flat snake_case keys, scalar values, null, [], and two-space lists are supported',
          ),
        );
        continue;
      }
      final key = keyMatch.group(1) ?? '';
      final rawValue = (keyMatch.group(2) ?? '').trim();
      if (metadata.containsKey(key)) {
        issues.add(
          SpecificationIssue(
            path: relativePath,
            line: lineNumber,
            code: 'frontmatter-duplicate',
            message: 'Metadata field $key is duplicated',
          ),
        );
        continue;
      }
      if (rawValue.isEmpty) {
        pendingList = _PendingList(key, lineNumber);
        continue;
      }
      if (rawValue == 'null' || rawValue == '~') {
        metadata[key] = _MetadataValue.nullValue(lineNumber);
        continue;
      }
      if (rawValue == '[]') {
        metadata[key] = _MetadataValue.list(const [], lineNumber);
        continue;
      }
      final parsedScalar = _parseScalarToken(rawValue);
      if (parsedScalar == null || parsedScalar.isEmpty) {
        issues.add(
          SpecificationIssue(
            path: relativePath,
            line: lineNumber,
            code: 'frontmatter-value',
            message: 'Metadata field $key must use a supported non-empty scalar, null, [], or indented list',
          ),
        );
        continue;
      }
      metadata[key] = _MetadataValue.scalar(parsedScalar, lineNumber);
    }
    finishPendingList();
    final bodyLines = lines.sublist(closingIndex + 1);
    return _ParsedMarkdown(
      metadata: Map<String, _MetadataValue>.unmodifiable(metadata),
      body: bodyLines.join('\n'),
      bodyStartLine: closingIndex + 2,
      issues: issues,
    );
  }

  String? _parseScalarToken(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }
    if (value.startsWith('"')) {
      if (!value.endsWith('"') || value.length < 2) {
        return null;
      }
      try {
        final decoded = jsonDecode(value);
        if (decoded is! String) {
          return null;
        }
        return decoded;
      } on FormatException {
        return null;
      }
    }
    if (value.startsWith("'")) {
      if (!value.endsWith("'") || value.length < 2) {
        return null;
      }
      return value.substring(1, value.length - 1).replaceAll("''", "'");
    }
    if (value == 'null' || value == '~' || value == '[]') {
      return null;
    }
    if (RegExp(r'^[\[{\]|>&*!]').hasMatch(value)) {
      return null;
    }
    if (value.startsWith('#')) {
      return null;
    }
    return value;
  }

  void _validateSchema(_SpecificationRecord record) {
    final schema = _schemas[record.kind] ?? const {};
    for (final key in record.metadata.keys) {
      if (schema.containsKey(key)) {
        continue;
      }
      _addIssue(
        record.relativePath,
        'unknown-field',
        'Unknown ${record.kind.typeValue} metadata field: $key',
        line: record.lineFor(key),
      );
    }
    for (final entry in schema.entries) {
      final value = record.metadata[entry.key];
      if (value == null) {
        _addIssue(
          record.relativePath,
          'missing-field',
          'Missing required metadata field: ${entry.key}',
        );
        continue;
      }
      if (_metadataTypeMatches(value, entry.value)) {
        if (value.kind == _MetadataValueKind.scalar && (value.scalar ?? '').trim().isEmpty) {
          _addIssue(
            record.relativePath,
            'empty-field',
            'Metadata field ${entry.key} must not be empty',
            line: value.line,
          );
        }
        continue;
      }
      _addIssue(
        record.relativePath,
        'field-type',
        'Metadata field ${entry.key} must be ${_expectedTypeDescription(entry.value)}',
        line: value.line,
      );
    }
  }

  bool _metadataTypeMatches(_MetadataValue value, _ExpectedMetadataType expected) {
    if (expected == _ExpectedMetadataType.scalar) {
      return value.kind == _MetadataValueKind.scalar;
    }
    if (expected == _ExpectedMetadataType.scalarOrNull) {
      return value.kind == _MetadataValueKind.scalar || value.kind == _MetadataValueKind.nullValue;
    }
    if (expected == _ExpectedMetadataType.list) {
      return value.kind == _MetadataValueKind.list;
    }
    if (value.kind == _MetadataValueKind.scalar || value.kind == _MetadataValueKind.nullValue) {
      return true;
    }
    return value.kind == _MetadataValueKind.list && value.items.isEmpty;
  }

  String _expectedTypeDescription(_ExpectedMetadataType expected) {
    if (expected == _ExpectedMetadataType.scalar) {
      return 'a scalar';
    }
    if (expected == _ExpectedMetadataType.scalarOrNull) {
      return 'a scalar or null';
    }
    if (expected == _ExpectedMetadataType.list) {
      return '[] or an indented list';
    }
    return 'a scalar, null, or []';
  }

  void _validateRecordIdentity(_SpecificationRecord record) {
    final recordType = record.scalar('type');
    if (recordType != null && recordType != record.kind.typeValue) {
      _addIssue(
        record.relativePath,
        'record-type',
        'type must be ${record.kind.typeValue}, found $recordType',
        line: record.lineFor('type'),
      );
    }
    final recordId = record.id;
    if (recordId == null) {
      return;
    }
    if (!_validIdForKind(recordId, record.kind)) {
      _addIssue(
        record.relativePath,
        'record-id',
        'ID must match ${record.kind.prefix}-YYYYMMDD-SLUG using uppercase letters, digits, and hyphens',
        line: record.lineFor('id'),
      );
      return;
    }
    final expectedFilename = '$recordId.md';
    final actualFilename = path.basename(record.relativePath);
    if (actualFilename != expectedFilename) {
      _addIssue(
        record.relativePath,
        'record-filename',
        'Filename must be $expectedFilename to match id',
        line: record.lineFor('id'),
      );
    }
    final recordDate = record.recordDate;
    if (recordDate == null) {
      return;
    }
    if (!_validDate(recordDate)) {
      _addIssue(
        record.relativePath,
        'record-date',
        '${record.kind.dateField} must be a valid YYYY-MM-DD date',
        line: record.lineFor(record.kind.dateField),
      );
      return;
    }
    final compactDate = recordDate.replaceAll('-', '');
    final idDate = RegExp(r'^[A-Z]+-(\d{8})-').firstMatch(recordId)?.group(1);
    if (idDate != compactDate) {
      _addIssue(
        record.relativePath,
        'id-date',
        'ID date $idDate must match ${record.kind.dateField} $recordDate',
        line: record.lineFor('id'),
      );
    }
    if (record.kind != _RecordKind.productInput) {
      return;
    }
    final directoryDate = record.productInputDirectoryDate;
    if (directoryDate == recordDate) {
      return;
    }
    _addIssue(
      record.relativePath,
      'directory-date',
      'Product input directory date $directoryDate must match captured_date $recordDate',
      line: record.lineFor('captured_date'),
    );
  }

  bool _validIdForKind(String value, _RecordKind kind) {
    final pattern = RegExp('^${kind.prefix}-\\d{8}-[A-Z0-9]+(?:-[A-Z0-9]+)*\$');
    return pattern.hasMatch(value);
  }

  bool _validDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return false;
    }
    final parsed = DateTime.tryParse('${value}T00:00:00Z');
    if (parsed == null) {
      return false;
    }
    return parsed.toUtc().toIso8601String().substring(0, 10) == value;
  }

  void _validateBody(_SpecificationRecord record) {
    final lines = record.body.split(RegExp(r'\r?\n'));
    bool inFence = false;
    String? fenceMarker;
    bool hasH1 = false;
    final headingIndexes = <int>[];
    final headingNames = <String>[];
    for (int index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      final fence = RegExp(r'^\s*(`{3,}|~{3,})').firstMatch(line);
      if (fence != null) {
        final marker = fence.group(1);
        if (!inFence) {
          inFence = true;
          fenceMarker = marker?[0];
          continue;
        }
        if (marker != null && marker.startsWith(fenceMarker ?? marker[0])) {
          inFence = false;
          fenceMarker = null;
        }
        continue;
      }
      if (inFence) {
        continue;
      }
      final heading = RegExp(r'^(#{1,6})\s+(.+?)\s*#*\s*$').firstMatch(line);
      if (heading == null) {
        continue;
      }
      final level = heading.group(1)?.length ?? 0;
      final name = (heading.group(2) ?? '').trim();
      if (level == 1 && name.isNotEmpty) {
        hasH1 = true;
      }
      if (level < 2 || name.isEmpty) {
        continue;
      }
      headingIndexes.add(index);
      headingNames.add(_normalizeHeading(name));
    }
    if (!hasH1) {
      _addIssue(
        record.relativePath,
        'body-h1',
        'Record body must contain a non-empty H1 heading',
        line: record.bodyStartLine,
      );
    }
    final requiredSections = _requiredBodySections[record.kind] ?? const [];
    for (final requiredSection in requiredSections) {
      final normalizedRequired = _normalizeHeading(requiredSection);
      final sectionIndex = headingNames.indexOf(normalizedRequired);
      if (sectionIndex < 0) {
        _addIssue(
          record.relativePath,
          'body-section',
          'Record body must contain a non-empty "$requiredSection" section',
          line: record.bodyStartLine,
        );
        continue;
      }
      final startIndex = headingIndexes[sectionIndex] + 1;
      final endIndex = sectionIndex + 1 < headingIndexes.length ? headingIndexes[sectionIndex + 1] : lines.length;
      final sectionBody = lines.sublist(startIndex, endIndex).join('\n');
      if (_meaningfulMarkdown(sectionBody)) {
        continue;
      }
      final mayBeEmptyResolution =
          normalizedRequired == 'resolution' &&
          ((record.kind == _RecordKind.observation && record.scalar('status') == 'recorded') ||
              (record.kind == _RecordKind.conflict && record.scalar('status') == 'unresolved'));
      if (mayBeEmptyResolution) {
        continue;
      }
      _addIssue(
        record.relativePath,
        'body-section',
        'Section "$requiredSection" must not be empty',
        line: record.bodyStartLine + headingIndexes[sectionIndex],
      );
    }
  }

  String _normalizeHeading(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _meaningfulMarkdown(String value) {
    final withoutComments = value.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
    final withoutFormatting = withoutComments.replaceAll(RegExp(r'[`*_>#\[\]()|+-]'), '').trim();
    return withoutFormatting.isNotEmpty;
  }

  void _parseAuthorityMap() {
    const relativePath = 'docs/specs/01-authority-map.md';
    final content = _readTextFile(relativePath);
    if (content == null) {
      return;
    }
    const expectedHeaders = [
      'Topic',
      'Assertion IDs',
      'Lifecycle',
      'Canonical owner',
      'Required drift surfaces',
    ];
    final table = _findMarkdownTable(content, expectedHeaders);
    if (table == null) {
      _addIssue(
        relativePath,
        'authority-table',
        'Must contain the table: Topic | Assertion IDs | Lifecycle | Canonical owner | Required drift surfaces',
      );
      return;
    }
    final inventory = _readTextFile('docs/specs/00-inventory.md') ?? '';
    final topics = <String>{};
    const lifecycles = {
      'active',
      'proposal',
      'historical',
      'deferred',
      'conflicted',
    };
    for (final row in table.rows) {
      final topic = _plainCell(row.cells[0]);
      final normalizedTopic = topic.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalizedTopic.isEmpty) {
        _addIssue(
          relativePath,
          'authority-topic',
          'Topic must not be empty',
          line: row.line,
        );
      } else if (!topics.add(normalizedTopic)) {
        _addIssue(
          relativePath,
          'authority-topic',
          'Topic "$topic" is duplicated',
          line: row.line,
        );
      }
      final assertionIds = _parseAssertionCell(
        relativePath,
        row.cells[1],
        row.line,
      );
      if (assertionIds.isEmpty) {
        _addIssue(
          relativePath,
          'authority-assertion',
          'Each authority row must register at least one SPEC-* assertion ID',
          line: row.line,
        );
      }
      final lifecycle = _plainCell(row.cells[2]).toLowerCase();
      for (final assertionId in assertionIds) {
        if (_registeredAssertions.add(assertionId)) {
          _assertionLifecycles[assertionId] = lifecycle;
          continue;
        }
        _addIssue(
          relativePath,
          'authority-assertion',
          'Assertion ID $assertionId is registered more than once',
          line: row.line,
        );
      }
      if (!lifecycles.contains(lifecycle)) {
        _addIssue(
          relativePath,
          'authority-lifecycle',
          'Lifecycle "$lifecycle" must be active, proposal, historical, deferred, or conflicted',
          line: row.line,
        );
      }
      final ownerReferences = _splitReferenceCell(row.cells[3]);
      if (ownerReferences.length != 1) {
        _addIssue(
          relativePath,
          'authority-owner',
          'Each topic must have exactly one canonical owner',
          line: row.line,
        );
      } else {
        final owner = ownerReferences.single;
        final resolvedOwner = _validateRepositoryReference(
          relativePath,
          owner,
          row.line,
          field: 'Canonical owner',
        );
        if (!inventory.contains(owner)) {
          _addIssue(
            'docs/specs/00-inventory.md',
            'inventory-owner',
            'Inventory must mention canonical owner $owner',
          );
        }
        if (resolvedOwner != null) {
          _checkOwnerAssertions(
            relativePath,
            row.line,
            resolvedOwner,
            assertionIds,
          );
        }
      }
      final driftReferences = _splitReferenceCell(row.cells[4]);
      for (final driftReference in driftReferences) {
        _validateRepositoryReference(
          relativePath,
          driftReference,
          row.line,
          field: 'Required drift surfaces',
        );
      }
    }
  }

  List<String> _parseAssertionCell(String relativePath, String cell, int line) {
    final normalized = cell
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll('`', ' ')
        .replaceAll(',', ' ')
        .replaceAll(';', ' ')
        .trim();
    if (normalized.isEmpty || normalized == '[]') {
      return const [];
    }
    final tokens = normalized.split(RegExp(r'\s+'));
    final result = <String>[];
    for (final token in tokens) {
      if (RegExp(r'^SPEC-[A-Z0-9]+(?:-[A-Z0-9]+)*$').hasMatch(token)) {
        result.add(token);
        continue;
      }
      _addIssue(
        relativePath,
        'authority-assertion',
        'Invalid assertion ID "$token"; expected SPEC-SLUG',
        line: line,
      );
    }
    return result;
  }

  List<String> _splitReferenceCell(String cell) {
    final plain = cell.trim();
    if (plain.isEmpty || plain == '[]' || plain.toLowerCase() == 'none') {
      return const [];
    }
    final normalized = plain.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n').replaceAll(';', '\n').replaceAll(',', '\n');
    final parts = normalized.split('\n');
    final result = <String>[];
    for (final part in parts) {
      final trimmedPart = part.trim();
      final markdownLink = RegExp(r'^\[[^\]]+\]\(([^)]+)\)$').firstMatch(trimmedPart);
      final reference = markdownLink == null ? _plainCell(trimmedPart) : (markdownLink.group(1) ?? '').trim();
      if (reference.isEmpty) {
        continue;
      }
      result.add(reference);
    }
    return result;
  }

  _ResolvedReference? _validateRepositoryReference(
    String sourcePath,
    String rawReference,
    int line, {
    required String field,
  }) {
    final reference = _plainCell(rawReference);
    if (_looksLikeAbsoluteMachinePath(reference)) {
      _addIssue(
        sourcePath,
        'absolute-reference',
        '$field reference "$reference" must not be an absolute machine path or file URL',
        line: line,
      );
      return null;
    }
    final aliasMatch = RegExp(
      r'^([a-z][a-z0-9_-]*):([A-Za-z0-9._/-]+)(?:#([^\s#]+))?$',
    ).firstMatch(reference);
    if (aliasMatch != null) {
      final aliasName = aliasMatch.group(1) ?? '';
      final repositoryPath = aliasMatch.group(2) ?? '';
      final anchor = aliasMatch.group(3);
      if (!_validRelativeReferencePath(repositoryPath)) {
        _addIssue(
          sourcePath,
          'repository-reference',
          '$field reference "$reference" contains an invalid repository path',
          line: line,
        );
        return null;
      }
      final alias = _aliases[aliasName];
      if (alias == null) {
        _addIssue(
          sourcePath,
          'repository-reference',
          '$field reference "$reference" uses unknown alias "$aliasName"',
          line: line,
        );
        return null;
      }
      final repositoryRoot = Directory(path.normalize(path.join(root.path, alias.root)));
      final checkExistence = repositoryRoot.existsSync();
      if (checkExistence) {
        final targetStatus = _referenceTargetStatus(repositoryRoot, repositoryPath);
        if (targetStatus == _ReferenceTargetStatus.missing) {
          _addIssue(
            sourcePath,
            'repository-reference-missing',
            '$field reference "$reference" does not exist',
            line: line,
          );
          return null;
        }
        if (targetStatus == _ReferenceTargetStatus.escapesRoot) {
          _addIssue(
            sourcePath,
            'repository-reference-escape',
            '$field reference "$reference" resolves outside repository alias "$aliasName"',
            line: line,
          );
          return null;
        }
      }
      return _ResolvedReference(
        original: reference,
        repositoryPath: repositoryPath,
        repositoryRoot: repositoryRoot,
        anchor: anchor,
        checkExistence: checkExistence,
      );
    }
    final localMatch = RegExp(r'^([A-Za-z0-9._/-]+)(?:#([^\s#]+))?$').firstMatch(reference);
    if (localMatch == null) {
      _addIssue(
        sourcePath,
        'repository-reference',
        '$field reference "$reference" must be repo-relative or alias:path[#anchor]',
        line: line,
      );
      return null;
    }
    final repositoryPath = localMatch.group(1) ?? '';
    final anchor = localMatch.group(2);
    if (!_validRelativeReferencePath(repositoryPath)) {
      _addIssue(
        sourcePath,
        'repository-reference',
        '$field reference "$reference" contains an invalid repository path',
        line: line,
      );
      return null;
    }
    final targetStatus = _referenceTargetStatus(root, repositoryPath);
    if (targetStatus == _ReferenceTargetStatus.missing) {
      _addIssue(
        sourcePath,
        'repository-reference-missing',
        '$field reference "$reference" does not exist',
        line: line,
      );
      return null;
    }
    if (targetStatus == _ReferenceTargetStatus.escapesRoot) {
      _addIssue(
        sourcePath,
        'repository-reference-escape',
        '$field reference "$reference" resolves outside this repository',
        line: line,
      );
      return null;
    }
    return _ResolvedReference(
      original: reference,
      repositoryPath: repositoryPath,
      repositoryRoot: root,
      anchor: anchor,
      checkExistence: true,
    );
  }

  bool _looksLikeAbsoluteMachinePath(String value) {
    if (value.startsWith('/') || value.startsWith('\\')) {
      return true;
    }
    if (RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value)) {
      return true;
    }
    return RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*://').hasMatch(value);
  }

  bool _validRelativeReferencePath(String value) {
    if (value.isEmpty || value.startsWith('/') || value.contains('\\')) {
      return false;
    }
    final segments = value.split('/');
    for (final segment in segments) {
      if (segment.isEmpty || segment == '..') {
        return false;
      }
    }
    return true;
  }

  _ReferenceTargetStatus _referenceTargetStatus(
    Directory repositoryRoot,
    String repositoryPath,
  ) {
    final absolute = path.normalize(path.join(repositoryRoot.path, repositoryPath));
    final relative = path.relative(absolute, from: repositoryRoot.path);
    if (relative == '..' || relative.startsWith('../') || path.isAbsolute(relative)) {
      return _ReferenceTargetStatus.escapesRoot;
    }
    if (FileSystemEntity.typeSync(absolute, followLinks: true) == FileSystemEntityType.notFound) {
      return _ReferenceTargetStatus.missing;
    }
    try {
      final resolvedRoot = path.normalize(repositoryRoot.resolveSymbolicLinksSync());
      final resolvedTarget = path.normalize(File(absolute).resolveSymbolicLinksSync());
      final resolvedRelative = path.relative(resolvedTarget, from: resolvedRoot);
      if (resolvedRelative == '..' || resolvedRelative.startsWith('../') || path.isAbsolute(resolvedRelative)) {
        return _ReferenceTargetStatus.escapesRoot;
      }
    } on FileSystemException {
      return _ReferenceTargetStatus.missing;
    }
    return _ReferenceTargetStatus.exists;
  }

  void _checkOwnerAssertions(
    String authorityPath,
    int line,
    _ResolvedReference owner,
    List<String> assertionIds,
  ) {
    if (!owner.checkExistence) {
      return;
    }
    final absolute = path.join(owner.repositoryRoot.path, owner.repositoryPath);
    if (FileSystemEntity.typeSync(absolute, followLinks: true) != FileSystemEntityType.file) {
      _addIssue(
        authorityPath,
        'authority-owner',
        'Canonical owner ${owner.original} must resolve to a file',
        line: line,
      );
      return;
    }
    String content;
    try {
      content = utf8.decode(File(absolute).readAsBytesSync());
    } on Object {
      _addIssue(
        authorityPath,
        'authority-owner',
        'Could not read canonical owner ${owner.original}',
        line: line,
      );
      return;
    }
    for (final assertionId in assertionIds) {
      if (RegExp('(^|[^A-Z0-9-])${RegExp.escape(assertionId)}([^A-Z0-9-]|\$)').hasMatch(content)) {
        continue;
      }
      _addIssue(
        authorityPath,
        'authority-owner-assertion',
        'Canonical owner ${owner.original} must contain $assertionId',
        line: line,
      );
    }
  }

  void _validateRecords() {
    for (final record in _records) {
      _validateRecordDates(record);
      _validateCanonicalAssertions(record);
      _validateSurfaceReferences(record);
      _validateListDuplicates(record);
      _validateReferenceTargets(record);
      if (record.kind == _RecordKind.productInput) {
        _validateProductInputState(record);
        continue;
      }
      if (record.kind == _RecordKind.decision) {
        _validateDecisionState(record);
        continue;
      }
      if (record.kind == _RecordKind.observation) {
        _validateObservationState(record);
        continue;
      }
      if (record.kind == _RecordKind.conflict) {
        _validateConflictState(record);
        continue;
      }
      _validateAcceptanceState(record);
    }
    _validateBacklinks();
    _validateSupersession(
      _RecordKind.productInput,
      supersedesField: 'supersedes',
      supersededByField: 'superseded_by',
    );
    _validateSupersession(
      _RecordKind.decision,
      supersedesField: 'supersedes',
      supersededByField: 'superseded_by',
    );
    _validateSupersession(
      _RecordKind.acceptance,
      supersedesField: 'supersedes_acceptance',
      supersededByField: 'superseded_by',
    );
    _validateConflictLifecycle();
    _validateAcceptanceChronology();
    _validateVerifiedInputs();
    _validateAcceptedAcceptanceClosure();
  }

  void _validateRecordDates(_SpecificationRecord record) {
    if (record.kind == _RecordKind.productInput) {
      final sourceDate = record.scalar('source_date');
      if (sourceDate == null || sourceDate == 'unknown') {
        return;
      }
      if (_validDate(sourceDate)) {
        final capturedDate = record.scalar('captured_date');
        if (capturedDate != null && _validDate(capturedDate) && sourceDate.compareTo(capturedDate) > 0) {
          _addIssue(
            record.relativePath,
            'source-date',
            'source_date $sourceDate must not be later than captured_date $capturedDate',
            line: record.lineFor('source_date'),
          );
        }
        return;
      }
      _addIssue(
        record.relativePath,
        'source-date',
        'source_date must be a valid YYYY-MM-DD date or the literal unknown',
        line: record.lineFor('source_date'),
      );
      return;
    }
    if (record.kind != _RecordKind.conflict) {
      return;
    }
    final openedDate = record.scalar('opened_date');
    final resolvedDate = record.scalar('resolved_date');
    if (resolvedDate == null) {
      return;
    }
    if (!_validDate(resolvedDate)) {
      _addIssue(
        record.relativePath,
        'resolved-date',
        'resolved_date must be a valid YYYY-MM-DD date or null',
        line: record.lineFor('resolved_date'),
      );
      return;
    }
    if (openedDate == null || !_validDate(openedDate) || resolvedDate.compareTo(openedDate) >= 0) {
      return;
    }
    _addIssue(
      record.relativePath,
      'resolved-date',
      'resolved_date $resolvedDate must not be earlier than opened_date $openedDate',
      line: record.lineFor('resolved_date'),
    );
  }

  void _validateCanonicalAssertions(_SpecificationRecord record) {
    const fieldsByKind = {
      _RecordKind.productInput: 'canonical_assertions',
      _RecordKind.decision: 'canonical_assertions',
      _RecordKind.observation: 'canonical_assertions',
      _RecordKind.conflict: 'canonical_assertions',
      _RecordKind.acceptance: 'canonical_assertions',
    };
    final field = fieldsByKind[record.kind];
    if (field == null) {
      return;
    }
    final assertionIds = record.list(field);
    final requiresAssertions =
        record.kind != _RecordKind.productInput || record.scalar('status') == 'merged' || record.scalar('status') == 'conflict';
    if (requiresAssertions && assertionIds.isEmpty) {
      _addIssue(
        record.relativePath,
        'canonical-assertion',
        '$field must contain at least one registered SPEC-* assertion ID',
        line: record.lineFor(field),
      );
    }
    for (final assertionId in assertionIds) {
      if (!RegExp(r'^SPEC-[A-Z0-9]+(?:-[A-Z0-9]+)*$').hasMatch(assertionId)) {
        _addIssue(
          record.relativePath,
          'canonical-assertion',
          '$field contains invalid assertion ID "$assertionId"',
          line: record.lineFor(field),
        );
        continue;
      }
      if (_registeredAssertions.contains(assertionId)) {
        continue;
      }
      _addIssue(
        record.relativePath,
        'canonical-assertion',
        '$field references unregistered assertion ID $assertionId',
        line: record.lineFor(field),
      );
    }
  }

  void _validateSurfaceReferences(_SpecificationRecord record) {
    const fieldsByKind = {
      _RecordKind.productInput: 'delivery_surfaces',
      _RecordKind.decision: 'affected_surfaces',
      _RecordKind.observation: 'affected_surfaces',
      _RecordKind.conflict: 'affected_surfaces',
      _RecordKind.acceptance: 'changed_surfaces',
    };
    final field = fieldsByKind[record.kind];
    if (field == null) {
      return;
    }
    final references = record.list(field);
    final requiresSurfaces =
        record.kind != _RecordKind.productInput ||
        (record.scalar('status') == 'merged' && record.scalar('delivery_status') != 'not_applicable');
    if (requiresSurfaces && references.isEmpty) {
      _addIssue(
        record.relativePath,
        'delivery-surface',
        '$field must contain at least one repository-qualified reference',
        line: record.lineFor(field),
      );
    }
    for (final reference in references) {
      _validateRepositoryReference(
        record.relativePath,
        reference,
        record.lineFor(field),
        field: field,
      );
    }
  }

  void _validateListDuplicates(_SpecificationRecord record) {
    for (final entry in record.metadata.entries) {
      if (entry.value.kind != _MetadataValueKind.list) {
        continue;
      }
      final seen = <String>{};
      for (final item in entry.value.items) {
        if (seen.add(item)) {
          continue;
        }
        _addIssue(
          record.relativePath,
          'duplicate-list-item',
          'Metadata field ${entry.key} contains duplicate item $item',
          line: entry.value.line,
        );
      }
    }
  }

  void _validateReferenceTargets(_SpecificationRecord record) {
    if (record.kind == _RecordKind.productInput) {
      _validateReferenceList(record, 'conflicts', _RecordKind.conflict);
      _validateReferenceList(record, 'supersedes', _RecordKind.productInput);
      _validateReferenceList(record, 'superseded_by', _RecordKind.productInput);
      _validateReferenceList(record, 'decisions', _RecordKind.decision);
      _validateReferenceList(record, 'acceptance_records', _RecordKind.acceptance);
      return;
    }
    if (record.kind == _RecordKind.decision) {
      _validateReferenceList(record, 'inputs', _RecordKind.productInput);
      _validateReferenceList(record, 'observations', _RecordKind.observation);
      _validateReferenceList(record, 'conflicts', _RecordKind.conflict);
      _validateReferenceList(record, 'supersedes', _RecordKind.decision);
      _validateReferenceList(record, 'superseded_by', _RecordKind.decision);
      _validateReferenceList(record, 'acceptance_records', _RecordKind.acceptance);
      return;
    }
    if (record.kind == _RecordKind.observation) {
      _validateReferenceList(record, 'inputs', _RecordKind.productInput);
      _validateReferenceList(record, 'conflicts', _RecordKind.conflict);
      _validateReferenceList(
        record,
        'decision',
        _RecordKind.decision,
        singleReference: true,
      );
      return;
    }
    if (record.kind == _RecordKind.conflict) {
      _validateReferenceList(record, 'inputs', _RecordKind.productInput);
      _validateReferenceList(record, 'observations', _RecordKind.observation);
      _validateReferenceList(
        record,
        'decision',
        _RecordKind.decision,
        singleReference: true,
      );
      return;
    }
    _validateReferenceList(record, 'inputs', _RecordKind.productInput);
    _validateReferenceList(record, 'decisions', _RecordKind.decision);
    _validateReferenceList(record, 'unresolved_conflicts', _RecordKind.conflict);
    _validateReferenceList(record, 'supersedes_acceptance', _RecordKind.acceptance);
    _validateReferenceList(record, 'superseded_by', _RecordKind.acceptance);
  }

  void _validateReferenceList(
    _SpecificationRecord record,
    String field,
    _RecordKind expectedKind, {
    bool singleReference = false,
  }) {
    final references = singleReference ? record.singleReferenceAsList(field) : record.list(field);
    if (singleReference && references.length > 1) {
      _addIssue(
        record.relativePath,
        'reference-cardinality',
        '$field may reference at most one ${expectedKind.prefix} record',
        line: record.lineFor(field),
      );
    }
    for (final reference in references) {
      if (!_validIdForKind(reference, expectedKind)) {
        _addIssue(
          record.relativePath,
          'record-reference',
          '$field reference "$reference" must be a ${expectedKind.prefix}-YYYYMMDD-SLUG ID',
          line: record.lineFor(field),
        );
        continue;
      }
      if (reference == record.id) {
        _addIssue(
          record.relativePath,
          'self-reference',
          '$field must not reference the record itself',
          line: record.lineFor(field),
        );
        continue;
      }
      final target = _recordsById[reference];
      if (target == null) {
        _addIssue(
          record.relativePath,
          'unknown-reference',
          '$field references unknown record $reference',
          line: record.lineFor(field),
        );
        continue;
      }
      if (target.kind == expectedKind) {
        continue;
      }
      _addIssue(
        record.relativePath,
        'reference-kind',
        '$field reference $reference must point to a ${expectedKind.typeValue} record',
        line: record.lineFor(field),
      );
    }
  }

  void _validateProductInputState(_SpecificationRecord record) {
    final status = record.scalar('status');
    final effectiveStatus = record.scalar('effective_status');
    final deliveryStatus = record.scalar('delivery_status');
    final category = record.scalar('category');
    if (category != null && !const {'product', 'process', 'mixed'}.contains(category)) {
      _addIssue(
        record.relativePath,
        'input-category',
        'category must be product, process, or mixed',
        line: record.lineFor('category'),
      );
    }
    if (status == null || effectiveStatus == null || deliveryStatus == null) {
      return;
    }
    final allowedEffectiveStatuses = _productInputStateMatrix[status];
    if (allowedEffectiveStatuses == null) {
      _addIssue(
        record.relativePath,
        'input-status',
        'Unknown product input status "$status"',
        line: record.lineFor('status'),
      );
      return;
    }
    final knownEffectiveStatuses = <String>{};
    final knownDeliveryStatuses = <String>{};
    for (final matrixEntry in _productInputStateMatrix.values) {
      knownEffectiveStatuses.addAll(matrixEntry.keys);
      for (final deliveries in matrixEntry.values) {
        knownDeliveryStatuses.addAll(deliveries);
      }
    }
    if (!knownEffectiveStatuses.contains(effectiveStatus)) {
      _addIssue(
        record.relativePath,
        'effective-status',
        'Unknown effective_status "$effectiveStatus"',
        line: record.lineFor('effective_status'),
      );
      return;
    }
    if (!knownDeliveryStatuses.contains(deliveryStatus)) {
      _addIssue(
        record.relativePath,
        'delivery-status',
        'Unknown delivery_status "$deliveryStatus"',
        line: record.lineFor('delivery_status'),
      );
      return;
    }
    final allowedDeliveries = allowedEffectiveStatuses[effectiveStatus];
    if (allowedDeliveries == null || !allowedDeliveries.contains(deliveryStatus)) {
      _addIssue(
        record.relativePath,
        'input-state-matrix',
        '$status + $effectiveStatus does not allow $deliveryStatus delivery',
        line: record.lineFor('status'),
      );
    }
    if (status == 'inbox' || status == 'deferred') {
      return;
    }
    if (status == 'conflict') {
      final currentConflicts = _currentConflictsFor(record);
      if (currentConflicts.isNotEmpty) {
        _validateInputConflictCoverage(record);
        return;
      }
      _addIssue(
        record.relativePath,
        'input-conflict',
        'conflict input must reference at least one current unresolved CF record',
        line: record.lineFor('conflicts'),
      );
      return;
    }
    if (status == 'merged') {
      _validateInputConflictCoverage(record);
      _validateInputSupersededState(record, effectiveStatus);
      return;
    }
    final rejectingDecision = record.list('decisions').any((String id) {
      return _recordsById[id]?.scalar('status') == 'rejected';
    });
    if (rejectingDecision) {
      return;
    }
    _addIssue(
      record.relativePath,
      'dismissed-decision',
      'dismissed input must link a rejecting DEC record',
      line: record.lineFor('decisions'),
    );
  }

  List<_SpecificationRecord> _currentConflictsFor(_SpecificationRecord input) {
    final result = <_SpecificationRecord>[];
    for (final conflictId in input.list('conflicts')) {
      final conflict = _recordsById[conflictId];
      if (conflict?.kind != _RecordKind.conflict) {
        continue;
      }
      if (conflict?.scalar('status') != 'unresolved' || conflict?.currentConflictDirectory != true) {
        continue;
      }
      result.add(conflict!);
    }
    return result;
  }

  void _validateInputConflictCoverage(_SpecificationRecord input) {
    final currentConflicts = _currentConflictsFor(input);
    for (final assertionId in input.list('canonical_assertions')) {
      final lifecycle = _assertionLifecycles[assertionId];
      final requiresCoverage = input.scalar('status') == 'conflict' || lifecycle == 'conflicted';
      if (!requiresCoverage) {
        continue;
      }
      final covered = currentConflicts.any((_SpecificationRecord conflict) {
        return conflict.list('canonical_assertions').contains(assertionId);
      });
      if (covered) {
        continue;
      }
      _addIssue(
        input.relativePath,
        'input-conflict-coverage',
        'Assertion $assertionId must be covered by a linked current CF record',
        line: input.lineFor('canonical_assertions'),
      );
    }
  }

  void _validateInputSupersededState(_SpecificationRecord record, String? effectiveStatus) {
    final supersededBy = record.list('superseded_by');
    if (effectiveStatus == 'active' && supersededBy.isNotEmpty) {
      _addIssue(
        record.relativePath,
        'input-supersession-state',
        'active input must not have superseded_by references',
        line: record.lineFor('superseded_by'),
      );
      return;
    }
    if (effectiveStatus != 'superseded' || supersededBy.isNotEmpty) {
      return;
    }
    _addIssue(
      record.relativePath,
      'input-supersession-state',
      'superseded input must have at least one superseded_by reference',
      line: record.lineFor('superseded_by'),
    );
  }

  void _validateDecisionState(_SpecificationRecord record) {
    const statuses = {
      'approved',
      'rejected',
      'superseded',
    };
    final status = record.scalar('status');
    if (status != null && !statuses.contains(status)) {
      _addIssue(
        record.relativePath,
        'decision-status',
        'Decision status must be approved, rejected, or superseded',
        line: record.lineFor('status'),
      );
      return;
    }
    final hasSubject = record.list('inputs').isNotEmpty || record.list('observations').isNotEmpty || record.list('conflicts').isNotEmpty;
    if (!hasSubject) {
      _addIssue(
        record.relativePath,
        'decision-subject',
        'Decision must reference at least one input, observation, or conflict',
        line: record.lineFor('inputs'),
      );
    }
    final supersededBy = record.list('superseded_by');
    if (status == 'superseded' && supersededBy.isEmpty) {
      _addIssue(
        record.relativePath,
        'decision-supersession-state',
        'superseded decision must have a superseded_by reference',
        line: record.lineFor('superseded_by'),
      );
      return;
    }
    if (status == 'superseded' || supersededBy.isEmpty) {
      return;
    }
    _addIssue(
      record.relativePath,
      'decision-supersession-state',
      '$status decision must not have superseded_by references',
      line: record.lineFor('superseded_by'),
    );
  }

  void _validateObservationState(_SpecificationRecord record) {
    final status = record.scalar('status');
    final decisions = record.singleReferenceAsList('decision');
    if (status == 'recorded') {
      if (decisions.isEmpty) {
        return;
      }
      _addIssue(
        record.relativePath,
        'observation-state',
        'recorded observation must have a null decision',
        line: record.lineFor('decision'),
      );
      return;
    }
    if (status == 'resolved') {
      final decision = decisions.length == 1 ? _recordsById[decisions.single] : null;
      if (decision?.kind == _RecordKind.decision && decision?.scalar('status') == 'approved') {
        _validateResolutionDecisionCoverage(record, decision!);
        return;
      }
      _addIssue(
        record.relativePath,
        'observation-state',
        'resolved observation must reference exactly one approved decision',
        line: record.lineFor('decision'),
      );
      return;
    }
    if (status == null) {
      return;
    }
    _addIssue(
      record.relativePath,
      'observation-status',
      'Observation status must be recorded or resolved',
      line: record.lineFor('status'),
    );
  }

  void _validateConflictState(_SpecificationRecord record) {
    final status = record.scalar('status');
    final resolvedDate = record.scalar('resolved_date');
    final decisions = record.singleReferenceAsList('decision');
    final isCurrent = record.currentConflictDirectory == true;
    final hasInputOrObservation = record.list('inputs').isNotEmpty || record.list('observations').isNotEmpty;
    if (!hasInputOrObservation) {
      _addIssue(
        record.relativePath,
        'conflict-source',
        'Conflict must reference at least one PI or OBS record',
        line: record.lineFor('inputs'),
      );
    } else {
      _validateConflictSourceCoverage(record);
    }
    if (isCurrent) {
      if (status == 'unresolved' && resolvedDate == null && decisions.isEmpty) {
        return;
      }
      _addIssue(
        record.relativePath,
        'conflict-state',
        'Current conflict requires status unresolved, resolved_date null, and decision null',
        line: record.lineFor('status'),
      );
      return;
    }
    final decision = decisions.length == 1 ? _recordsById[decisions.single] : null;
    if (status == 'resolved' &&
        resolvedDate != null &&
        decision?.kind == _RecordKind.decision &&
        decision?.scalar('status') == 'approved') {
      final decisionDate = decision?.scalar('date');
      if (decisionDate != null && _validDate(decisionDate) && _validDate(resolvedDate) && decisionDate.compareTo(resolvedDate) > 0) {
        _addIssue(
          record.relativePath,
          'conflict-decision-date',
          'Resolved conflict decision ${decision?.id} dated $decisionDate must not be later than resolved_date $resolvedDate',
          line: record.lineFor('decision'),
        );
      }
      _validateResolutionDecisionCoverage(record, decision!);
      return;
    }
    _addIssue(
      record.relativePath,
      'conflict-state',
      'Resolved conflict requires status resolved, a resolved_date, and exactly one approved DEC decision',
      line: record.lineFor('status'),
    );
  }

  void _validateResolutionDecisionCoverage(
    _SpecificationRecord record,
    _SpecificationRecord decision,
  ) {
    final assertionsCovered = _isSuperset(
      decision.list('canonical_assertions'),
      record.list('canonical_assertions'),
    );
    final surfacesCovered = _isSuperset(
      decision.list('affected_surfaces'),
      record.list('affected_surfaces'),
    );
    if (assertionsCovered && surfacesCovered) {
      return;
    }
    _addIssue(
      record.relativePath,
      'resolution-decision-coverage',
      'Approved decision ${decision.id} must cover all canonical_assertions and affected_surfaces from this resolved record',
      line: record.lineFor('decision'),
    );
  }

  void _validateConflictSourceCoverage(_SpecificationRecord conflict) {
    final sources = <_SpecificationRecord>[];
    for (final inputId in conflict.list('inputs')) {
      final source = _recordsById[inputId];
      if (source?.kind == _RecordKind.productInput) {
        sources.add(source!);
      }
    }
    for (final observationId in conflict.list('observations')) {
      final source = _recordsById[observationId];
      if (source?.kind == _RecordKind.observation) {
        sources.add(source!);
      }
    }
    final sourceAssertions = <String>{};
    final sourceSurfaces = <String>{};
    for (final source in sources) {
      final surfaceField = source.kind == _RecordKind.productInput ? 'delivery_surfaces' : 'affected_surfaces';
      final assertions = source.list('canonical_assertions');
      final surfaces = source.list(surfaceField);
      sourceAssertions.addAll(assertions);
      sourceSurfaces.addAll(surfaces);
      final relevant =
          _setsOverlap(assertions, conflict.list('canonical_assertions')) && _setsOverlap(surfaces, conflict.list('affected_surfaces'));
      if (relevant) {
        continue;
      }
      _addIssue(
        conflict.relativePath,
        'conflict-source-coverage',
        'Linked source ${source.id} must share a canonical assertion and affected surface with this conflict',
        line: conflict.lineFor(source.kind == _RecordKind.productInput ? 'inputs' : 'observations'),
      );
    }
    final assertionsCovered = conflict.list('canonical_assertions').every(sourceAssertions.contains);
    final surfacesCovered = conflict.list('affected_surfaces').every(sourceSurfaces.contains);
    if (assertionsCovered && surfacesCovered) {
      return;
    }
    _addIssue(
      conflict.relativePath,
      'conflict-source-coverage',
      'The union of linked PI and OBS sources must cover every conflict assertion and affected surface',
      line: conflict.lineFor('canonical_assertions'),
    );
  }

  void _validateAcceptanceState(_SpecificationRecord record) {
    final owner = record.scalar('owner');
    if (owner != null && owner != 'root Codex agent') {
      _addIssue(
        record.relativePath,
        'acceptance-owner',
        'Acceptance owner must be exactly "root Codex agent"',
        line: record.lineFor('owner'),
      );
    }
    final result = record.scalar('result');
    if (const {'accepted', 'partial', 'rejected'}.contains(result)) {
      if (record.list('inputs').isNotEmpty) {
        return;
      }
      _addIssue(
        record.relativePath,
        'acceptance-input',
        'Acceptance record must reference at least one product input',
        line: record.lineFor('inputs'),
      );
      return;
    }
    if (result == null) {
      return;
    }
    _addIssue(
      record.relativePath,
      'acceptance-result',
      'Acceptance result must be accepted, partial, or rejected',
      line: record.lineFor('result'),
    );
  }

  void _validateBacklinks() {
    for (final record in _records) {
      if (record.kind == _RecordKind.productInput) {
        _requireBacklinks(
          record,
          'conflicts',
          targetField: 'inputs',
        );
        _requireBacklinks(
          record,
          'decisions',
          targetField: 'inputs',
        );
        _requireBacklinks(
          record,
          'acceptance_records',
          targetField: 'inputs',
        );
        continue;
      }
      if (record.kind == _RecordKind.decision) {
        _requireBacklinks(
          record,
          'inputs',
          targetField: 'decisions',
        );
        _requireBacklinks(
          record,
          'observations',
          targetField: 'decision',
          targetSingleReference: true,
        );
        _requireBacklinks(
          record,
          'conflicts',
          targetField: 'decision',
          targetSingleReference: true,
        );
        _requireBacklinks(
          record,
          'acceptance_records',
          targetField: 'decisions',
        );
        continue;
      }
      if (record.kind == _RecordKind.observation) {
        _requireBacklinks(
          record,
          'conflicts',
          targetField: 'observations',
        );
        _requireBacklinks(
          record,
          'decision',
          targetField: 'observations',
          sourceSingleReference: true,
        );
        continue;
      }
      if (record.kind == _RecordKind.conflict) {
        _requireBacklinks(
          record,
          'inputs',
          targetField: 'conflicts',
        );
        _requireBacklinks(
          record,
          'observations',
          targetField: 'conflicts',
        );
        _requireBacklinks(
          record,
          'decision',
          targetField: 'conflicts',
          sourceSingleReference: true,
        );
        continue;
      }
      _requireBacklinks(
        record,
        'inputs',
        targetField: 'acceptance_records',
      );
      _requireBacklinks(
        record,
        'decisions',
        targetField: 'acceptance_records',
      );
    }
  }

  void _requireBacklinks(
    _SpecificationRecord source,
    String sourceField, {
    required String targetField,
    bool sourceSingleReference = false,
    bool targetSingleReference = false,
  }) {
    final sourceId = source.id;
    if (sourceId == null) {
      return;
    }
    final targetIds = sourceSingleReference ? source.singleReferenceAsList(sourceField) : source.list(sourceField);
    for (final targetId in targetIds) {
      final target = _recordsById[targetId];
      if (target == null) {
        continue;
      }
      final backlinks = targetSingleReference ? target.singleReferenceAsList(targetField) : target.list(targetField);
      if (backlinks.contains(sourceId)) {
        continue;
      }
      _addIssue(
        source.relativePath,
        'missing-backlink',
        '$sourceField reference $targetId requires $targetId.$targetField to include $sourceId',
        line: source.lineFor(sourceField),
      );
    }
  }

  void _validateSupersession(
    _RecordKind kind, {
    required String supersedesField,
    required String supersededByField,
  }) {
    final records = _records.where((_SpecificationRecord record) => record.kind == kind).toList();
    for (final record in records) {
      final recordId = record.id;
      if (recordId == null) {
        continue;
      }
      for (final supersededId in record.list(supersedesField)) {
        final superseded = _recordsById[supersededId];
        if (superseded == null || superseded.kind != kind) {
          continue;
        }
        final successorDate = record.recordDate;
        final supersededDate = superseded.recordDate;
        if (successorDate != null &&
            supersededDate != null &&
            _validDate(successorDate) &&
            _validDate(supersededDate) &&
            successorDate.compareTo(supersededDate) < 0) {
          _addIssue(
            record.relativePath,
            'supersession-date',
            'Superseding record ${record.id} dated $successorDate must not predate $supersededId dated $supersededDate',
            line: record.lineFor(supersedesField),
          );
        }
        _validateSupersessionSemantics(
          record,
          superseded,
          supersedesField,
        );
        if (superseded.list(supersededByField).contains(recordId)) {
          continue;
        }
        _addIssue(
          record.relativePath,
          'supersession-backlink',
          '$supersedesField $supersededId requires its $supersededByField to include $recordId',
          line: record.lineFor(supersedesField),
        );
      }
      for (final successorId in record.list(supersededByField)) {
        final successor = _recordsById[successorId];
        if (successor == null || successor.kind != kind) {
          continue;
        }
        if (successor.list(supersedesField).contains(recordId)) {
          continue;
        }
        _addIssue(
          record.relativePath,
          'supersession-backlink',
          '$supersededByField $successorId requires its $supersedesField to include $recordId',
          line: record.lineFor(supersededByField),
        );
      }
    }
    _validateSupersessionCycles(
      records,
      supersedesField,
    );
  }

  void _validateSupersessionSemantics(
    _SpecificationRecord successor,
    _SpecificationRecord superseded,
    String supersedesField,
  ) {
    bool valid;
    if (successor.kind == _RecordKind.productInput) {
      final successorEffectiveStatus = successor.scalar('effective_status');
      final successorStateValid =
          successor.scalar('status') == 'merged' &&
          ((successorEffectiveStatus == 'active' && successor.list('superseded_by').isEmpty) ||
              (successorEffectiveStatus == 'superseded' && successor.list('superseded_by').isNotEmpty));
      valid =
          successorStateValid &&
          superseded.scalar('status') == 'merged' &&
          superseded.scalar('effective_status') == 'superseded' &&
          _setsOverlap(
            successor.list('canonical_assertions'),
            superseded.list('canonical_assertions'),
          );
    } else if (successor.kind == _RecordKind.decision) {
      final successorStatus = successor.scalar('status');
      final successorStateValid =
          (successorStatus == 'approved' && successor.list('superseded_by').isEmpty) ||
          (successorStatus == 'superseded' && successor.list('superseded_by').isNotEmpty);
      valid =
          successorStateValid &&
          superseded.scalar('status') == 'superseded' &&
          _setsOverlap(
            successor.list('canonical_assertions'),
            superseded.list('canonical_assertions'),
          );
    } else {
      valid =
          _setsOverlap(
            successor.list('inputs'),
            superseded.list('inputs'),
          ) &&
          _setsOverlap(
            successor.list('canonical_assertions'),
            superseded.list('canonical_assertions'),
          );
    }
    if (valid) {
      return;
    }
    _addIssue(
      successor.relativePath,
      'supersession-semantics',
      '${successor.kind.prefix} supersession must satisfy the required state and shared-subject rules',
      line: successor.lineFor(supersedesField),
    );
  }

  void _validateSupersessionCycles(
    List<_SpecificationRecord> records,
    String supersedesField,
  ) {
    final state = <String, int>{};
    final stack = <String>[];
    final reportedCycles = <String>{};

    void visit(String id) {
      final currentState = state[id] ?? 0;
      if (currentState == 2) {
        return;
      }
      if (currentState == 1) {
        final cycleStart = stack.indexOf(id);
        final cycle = cycleStart >= 0 ? [...stack.sublist(cycleStart), id] : [...stack, id];
        final cycleKey = cycle.toSet().toList()..sort();
        final normalizedKey = cycleKey.join('|');
        if (!reportedCycles.add(normalizedKey)) {
          return;
        }
        final record = _recordsById[id];
        if (record == null) {
          return;
        }
        _addIssue(
          record.relativePath,
          'supersession-cycle',
          'Supersession cycle detected: ${cycle.join(' -> ')}',
          line: record.lineFor(supersedesField),
        );
        return;
      }
      state[id] = 1;
      stack.add(id);
      final record = _recordsById[id];
      if (record != null) {
        for (final targetId in record.list(supersedesField)) {
          final target = _recordsById[targetId];
          if (target == null || target.kind != record.kind) {
            continue;
          }
          visit(targetId);
        }
      }
      stack.removeLast();
      state[id] = 2;
    }

    for (final record in records) {
      final recordId = record.id;
      if (recordId == null) {
        continue;
      }
      visit(recordId);
    }
  }

  void _validateConflictLifecycle() {
    final currentAssertions = <String>{};
    for (final record in _records) {
      final isCurrentConflict =
          record.kind == _RecordKind.conflict && record.currentConflictDirectory == true && record.scalar('status') == 'unresolved';
      if (!isCurrentConflict) {
        continue;
      }
      for (final assertionId in record.list('canonical_assertions')) {
        currentAssertions.add(assertionId);
        final lifecycle = _assertionLifecycles[assertionId];
        if (lifecycle == null || lifecycle == 'conflicted') {
          continue;
        }
        _addIssue(
          record.relativePath,
          'conflict-lifecycle',
          'Current conflict assertion $assertionId must have conflicted lifecycle, found $lifecycle',
          line: record.lineFor('canonical_assertions'),
        );
      }
    }
    for (final entry in _assertionLifecycles.entries) {
      if (entry.value != 'conflicted' || currentAssertions.contains(entry.key)) {
        continue;
      }
      _addIssue(
        'docs/specs/01-authority-map.md',
        'conflict-lifecycle',
        'Conflicted assertion ${entry.key} must be referenced by at least one current unresolved CF record',
      );
    }
  }

  void _validateAcceptanceChronology() {
    for (final record in _records) {
      if (record.kind != _RecordKind.acceptance) {
        continue;
      }
      final acceptanceDate = record.scalar('date');
      if (acceptanceDate == null || !_validDate(acceptanceDate)) {
        continue;
      }
      for (final inputId in record.list('inputs')) {
        final input = _recordsById[inputId];
        final inputDate = input?.scalar('captured_date');
        if (inputDate == null || !_validDate(inputDate) || inputDate.compareTo(acceptanceDate) <= 0) {
          continue;
        }
        _addIssue(
          record.relativePath,
          'acceptance-date',
          'Input $inputId captured on $inputDate is later than acceptance date $acceptanceDate',
          line: record.lineFor('inputs'),
        );
      }
      for (final decisionId in record.list('decisions')) {
        final decision = _recordsById[decisionId];
        final decisionDate = decision?.scalar('date');
        if (decisionDate == null || !_validDate(decisionDate) || decisionDate.compareTo(acceptanceDate) <= 0) {
          continue;
        }
        _addIssue(
          record.relativePath,
          'acceptance-date',
          'Decision $decisionId dated $decisionDate is later than acceptance date $acceptanceDate',
          line: record.lineFor('decisions'),
        );
      }
      for (final conflictId in record.list('unresolved_conflicts')) {
        final conflict = _recordsById[conflictId];
        if (conflict == null || conflict.kind != _RecordKind.conflict) {
          continue;
        }
        final openedDate = conflict.scalar('opened_date');
        final resolvedDate = conflict.scalar('resolved_date');
        if (openedDate != null && _validDate(openedDate) && openedDate.compareTo(acceptanceDate) > 0) {
          _addIssue(
            record.relativePath,
            'acceptance-conflict-snapshot',
            'Conflict $conflictId opened on $openedDate after acceptance date $acceptanceDate',
            line: record.lineFor('unresolved_conflicts'),
          );
        }
        if (resolvedDate == null || !_validDate(resolvedDate) || acceptanceDate.compareTo(resolvedDate) <= 0) {
          continue;
        }
        _addIssue(
          record.relativePath,
          'acceptance-conflict-snapshot',
          'Conflict $conflictId resolved on $resolvedDate and was not unresolved at acceptance date $acceptanceDate',
          line: record.lineFor('unresolved_conflicts'),
        );
      }
      final recordedUnresolved = record.list('unresolved_conflicts').toSet();
      final acceptedAssertions = record.list('canonical_assertions').toSet();
      for (final conflict in _records) {
        if (conflict.kind != _RecordKind.conflict) {
          continue;
        }
        final conflictId = conflict.id;
        final openedDate = conflict.scalar('opened_date');
        final resolvedDate = conflict.scalar('resolved_date');
        if (conflictId == null || openedDate == null || !_validDate(openedDate) || openedDate.compareTo(acceptanceDate) >= 0) {
          continue;
        }
        final wasOpen = resolvedDate == null || (_validDate(resolvedDate) && acceptanceDate.compareTo(resolvedDate) < 0);
        if (!wasOpen) {
          continue;
        }
        final overlaps = conflict.list('canonical_assertions').any(acceptedAssertions.contains);
        if (!overlaps || recordedUnresolved.contains(conflictId)) {
          continue;
        }
        _addIssue(
          record.relativePath,
          'acceptance-conflict-snapshot',
          'unresolved_conflicts must include open overlapping conflict $conflictId at acceptance date $acceptanceDate',
          line: record.lineFor('unresolved_conflicts'),
        );
      }
    }
  }

  void _validateVerifiedInputs() {
    for (final record in _records) {
      if (record.kind != _RecordKind.productInput || record.scalar('delivery_status') != 'verified') {
        continue;
      }
      bool hasCurrentAcceptedRecord = false;
      for (final acceptanceId in record.list('acceptance_records')) {
        final acceptance = _recordsById[acceptanceId];
        if (acceptance == null || acceptance.kind != _RecordKind.acceptance) {
          continue;
        }
        final current = acceptance.list('superseded_by').isEmpty;
        final accepted = acceptance.scalar('result') == 'accepted';
        final includesInput = acceptance.list('inputs').contains(record.id);
        final assertionsCovered = _isSuperset(
          acceptance.list('canonical_assertions'),
          record.list('canonical_assertions'),
        );
        final decisionsCovered = _isSuperset(
          acceptance.list('decisions'),
          record.list('decisions'),
        );
        final surfacesCovered = _isSuperset(
          acceptance.list('changed_surfaces'),
          record.list('delivery_surfaces'),
        );
        if (!current || !accepted || !includesInput || !assertionsCovered || !decisionsCovered || !surfacesCovered) {
          continue;
        }
        hasCurrentAcceptedRecord = true;
        break;
      }
      if (hasCurrentAcceptedRecord) {
        continue;
      }
      _addIssue(
        record.relativePath,
        'verified-acceptance',
        'verified delivery requires one current accepted ACC that covers the input, assertions, decisions, and delivery surfaces',
        line: record.lineFor('delivery_status'),
      );
    }
  }

  void _validateAcceptedAcceptanceClosure() {
    for (final acceptance in _records) {
      final isCurrentAccepted =
          acceptance.kind == _RecordKind.acceptance &&
          acceptance.scalar('result') == 'accepted' &&
          acceptance.list('superseded_by').isEmpty;
      if (!isCurrentAccepted) {
        continue;
      }
      for (final inputId in acceptance.list('inputs')) {
        final input = _recordsById[inputId];
        if (input == null || input.kind != _RecordKind.productInput) {
          continue;
        }
        final independentlyCovered =
            input.scalar('delivery_status') == 'verified' &&
            _isSuperset(
              acceptance.list('canonical_assertions'),
              input.list('canonical_assertions'),
            ) &&
            _isSuperset(
              acceptance.list('decisions'),
              input.list('decisions'),
            ) &&
            _isSuperset(
              acceptance.list('changed_surfaces'),
              input.list('delivery_surfaces'),
            );
        if (independentlyCovered) {
          continue;
        }
        _addIssue(
          acceptance.relativePath,
          'accepted-acceptance-closure',
          'Each current accepted ACC must independently cover every linked verified input, its assertions, decisions, and delivery surfaces',
          line: acceptance.lineFor('inputs'),
        );
      }
    }
  }

  bool _isSuperset(List<String> candidate, List<String> required) {
    final candidateSet = candidate.toSet();
    return required.every(candidateSet.contains);
  }

  bool _setsOverlap(List<String> left, List<String> right) {
    final rightSet = right.toSet();
    return left.any(rightSet.contains);
  }
}
