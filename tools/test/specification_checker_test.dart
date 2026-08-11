import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tools/specification/specification_checker.dart';

void main() {
  group('SpecificationChecker', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('rwkv-specification-checker-');
      _createHappyFixture(root);
    });

    tearDown(() {
      if (!root.existsSync()) {
        return;
      }
      root.deleteSync(recursive: true);
    });

    test('accepts a complete v1.7 fixture', () {
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('accepts opaque private PI references without a local input tree', () {
      Directory(path.join(root.path, 'docs/product-inputs')).deleteSync(recursive: true);
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('discovers the root from root, tools, and docs', () {
      expect(findSpecificationRepositoryRoot(root)?.path, root.absolute.path);
      expect(findSpecificationRepositoryRoot(Directory(path.join(root.path, 'tools')))?.path, root.absolute.path);
      expect(findSpecificationRepositoryRoot(Directory(path.join(root.path, 'docs')))?.path, root.absolute.path);
    });

    test('accepts the Git symlink placeholder only on Windows', () {
      final agentsBytes = utf8.encode('# Instructions\n');
      final placeholderBytes = utf8.encode('../AGENTS.md');
      expect(
        specificationInstructionMirrorMatches(
          agentsBytes: agentsBytes,
          copilotBytes: placeholderBytes,
          isWindows: true,
        ),
        isTrue,
      );
      expect(
        specificationInstructionMirrorMatches(
          agentsBytes: agentsBytes,
          copilotBytes: placeholderBytes,
          isWindows: false,
        ),
        isFalse,
      );
      expect(
        specificationInstructionMirrorMatches(
          agentsBytes: agentsBytes,
          copilotBytes: agentsBytes,
          isWindows: false,
        ),
        isTrue,
      );
    });

    test('ignores body text that resembles metadata', () {
      final inputPath = _inputPath(root);
      _replace(
        inputPath,
        'The user requested the migration.',
        'The user requested the migration.\n\nStatus: conflict\n\nid: PI-19990101-FAKE',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('fails closed on malformed front matter', () {
      final inputPath = _inputPath(root);
      _replace(
        inputPath,
        'source: user',
        'source:\n    nested: user',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'frontmatter-syntax');
      _expectCode(result, 'frontmatter-value');
    });

    test('rejects unknown and missing metadata fields', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'source: user\n', '');
      _replace(inputPath, 'category: process', 'category: process\nlegacy_field: no');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'missing-field');
      _expectCode(result, 'unknown-field');
    });

    test('enforces strict IDs on the effective day', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'id: PI-20260723-SPEC-SYSTEM-MIGRATION\n', '');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'missing-field');
    });

    test('rejects ID date drift and duplicate IDs', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'captured_date: 2026-07-23', 'captured_date: 2026-07-24');
      final duplicatePath = path.join(
        root.path,
        'docs/product-inputs/2026-07-23/PI-20260723-DUPLICATE.md',
      );
      _write(duplicatePath, File(inputPath).readAsStringSync());
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'id-date');
      _expectCode(result, 'duplicate-id');
    });

    test('rejects non-record Markdown names inside record directories', () {
      _write(
        path.join(root.path, 'docs/spec-process/decisions/not-a-record.md'),
        '# Bad record\n',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'record-filename');
    });

    test('rejects every illegal product input state family', () {
      final invalidStates = <({String status, String effective, String delivery})>[
        (status: 'inbox', effective: 'active', delivery: 'not_started'),
        (status: 'deferred', effective: 'pending', delivery: 'implemented'),
        (status: 'conflict', effective: 'pending', delivery: 'blocked'),
        (status: 'merged', effective: 'pending', delivery: 'implemented'),
        (status: 'dismissed', effective: 'active', delivery: 'not_applicable'),
      ];
      for (final invalidState in invalidStates) {
        final caseRoot = Directory.systemTemp.createTempSync('rwkv-spec-state-');
        try {
          _createHappyFixture(caseRoot);
          final inputPath = _inputPath(caseRoot);
          _replace(inputPath, 'status: merged', 'status: ${invalidState.status}');
          _replace(inputPath, 'effective_status: active', 'effective_status: ${invalidState.effective}');
          _replace(inputPath, 'delivery_status: verified', 'delivery_status: ${invalidState.delivery}');
          final result = SpecificationChecker(caseRoot).check();
          final hasStateIssue = result.issues.any((SpecificationIssue issue) {
            return issue.code == 'input-state-matrix' || issue.code == 'input-conflict' || issue.code == 'dismissed-decision';
          });
          expect(
            hasStateIssue,
            isTrue,
            reason: '${invalidState.status}: ${_messages(result)}',
          );
        } finally {
          caseRoot.deleteSync(recursive: true);
        }
      }
    });

    test('validates product input category and acceptance owner', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'category: process', 'category: engineering');
      final acceptancePath = _acceptancePath(root);
      _replace(acceptancePath, 'owner: root Codex agent', 'owner: delegated agent');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'input-category');
      _expectCode(result, 'acceptance-owner');
    });

    test('allows merged not_applicable delivery without delivery surfaces', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'delivery_status: verified', 'delivery_status: not_applicable');
      _replace(
        inputPath,
        'delivery_surfaces:\n  - docs/specification.md',
        'delivery_surfaces: []',
      );
      _replace(
        _acceptancePath(root),
        'result: accepted',
        'result: partial',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('rejects active and superseded state/link mismatches', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'effective_status: active', 'effective_status: superseded');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'input-supersession-state');
    });

    test('rejects one-way product input supersession', () {
      final oldId = 'PI-20260723-OLD-RULE';
      _writeProductInput(
        root,
        id: oldId,
        effectiveStatus: 'superseded',
        supersededBy: const [],
      );
      final inputPath = _inputPath(root);
      _replace(inputPath, 'supersedes: []', 'supersedes:\n  - $oldId');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'supersession-backlink');
    });

    test('rejects product input supersession cycles', () {
      final oldId = 'PI-20260723-OLD-RULE';
      final currentId = 'PI-20260723-SPEC-SYSTEM-MIGRATION';
      _writeProductInput(
        root,
        id: oldId,
        effectiveStatus: 'superseded',
        supersedes: [currentId],
        supersededBy: [currentId],
      );
      final inputPath = _inputPath(root);
      _replace(inputPath, 'effective_status: active', 'effective_status: superseded');
      _replace(inputPath, 'supersedes: []', 'supersedes:\n  - $oldId');
      _replace(inputPath, 'superseded_by: []', 'superseded_by:\n  - $oldId');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'supersession-cycle');
    });

    test('requires product input supersession to share an assertion and valid states', () {
      const oldId = 'PI-20260723-OLD-RULE';
      const currentId = 'PI-20260723-SPEC-SYSTEM-MIGRATION';
      _writeProductInput(
        root,
        id: oldId,
        effectiveStatus: 'superseded',
        supersededBy: const [currentId],
      );
      final oldPath = path.join(
        root.path,
        'docs/product-inputs/2026-07-23/$oldId.md',
      );
      _replace(oldPath, 'SPEC-PROCESS-LOOP', 'SPEC-UNRELATED-RULE');
      _replace(
        _inputPath(root),
        'supersedes: []',
        'supersedes:\n  - $oldId',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'supersession-semantics');
    });

    test('accepts a three-generation product input supersession chain', () {
      const firstId = 'PI-20260723-FIRST-RULE';
      const secondId = 'PI-20260723-SECOND-RULE';
      const currentId = 'PI-20260723-SPEC-SYSTEM-MIGRATION';
      _writeProductInput(
        root,
        id: firstId,
        effectiveStatus: 'superseded',
        supersededBy: const [secondId],
      );
      _writeProductInput(
        root,
        id: secondId,
        effectiveStatus: 'superseded',
        supersedes: const [firstId],
        supersededBy: const [currentId],
      );
      _replace(
        _inputPath(root),
        'supersedes: []',
        'supersedes:\n  - $secondId',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('rejects a superseding record whose date is earlier', () {
      final futureId = 'PI-20260724-FUTURE-RULE';
      _writeProductInput(
        root,
        id: futureId,
        capturedDate: '2026-07-24',
        effectiveStatus: 'superseded',
        supersededBy: const ['PI-20260723-SPEC-SYSTEM-MIGRATION'],
      );
      final inputPath = _inputPath(root);
      _replace(inputPath, 'supersedes: []', 'supersedes:\n  - $futureId');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'supersession-date');
    });

    test('requires decision supersession to use approved and superseded states', () {
      const oldId = 'DEC-20260723-OLD-SPEC';
      const currentId = 'DEC-20260723-ADAPT-SPEC';
      _writeDecision(
        root,
        id: oldId,
        status: 'rejected',
        supersededBy: const [currentId],
      );
      _replace(
        _decisionPath(root),
        'supersedes: []',
        'supersedes:\n  - $oldId',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'supersession-semantics');
    });

    test('accepts a three-generation decision supersession chain', () {
      const firstId = 'DEC-20260723-FIRST-SPEC';
      const secondId = 'DEC-20260723-SECOND-SPEC';
      const currentId = 'DEC-20260723-ADAPT-SPEC';
      const acceptanceId = 'ACC-20260723-SPEC-MIGRATION';
      _writeDecision(
        root,
        id: firstId,
        status: 'superseded',
        supersededBy: const [secondId],
        acceptanceRecords: const [acceptanceId],
      );
      _writeDecision(
        root,
        id: secondId,
        status: 'superseded',
        supersedes: const [firstId],
        supersededBy: const [currentId],
        acceptanceRecords: const [acceptanceId],
      );
      _replace(
        _decisionPath(root),
        'supersedes: []',
        'supersedes:\n  - $secondId',
      );
      _replace(
        _inputPath(root),
        'decisions:\n  - DEC-20260723-ADAPT-SPEC',
        'decisions:\n  - DEC-20260723-ADAPT-SPEC\n  - $secondId\n  - $firstId',
      );
      _replace(
        _acceptancePath(root),
        'decisions:\n  - DEC-20260723-ADAPT-SPEC',
        'decisions:\n  - DEC-20260723-ADAPT-SPEC\n  - $secondId\n  - $firstId',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('enforces current conflict backlinks and conflicted lifecycle', () {
      _addCurrentConflict(root);
      final inputPath = _inputPath(root);
      _replace(inputPath, 'conflicts:\n  - CF-20260723-SPEC-CONFLICT', 'conflicts: []');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'missing-backlink');
      _expectCode(result, 'input-conflict');
    });

    test('requires a conflict input assertion to be covered by its current conflict', () {
      _addCurrentConflict(root);
      final specificationPath = path.join(root.path, 'docs/specification.md');
      File(specificationPath).writeAsStringSync(
        '${File(specificationPath).readAsStringSync()}\nSPEC-OTHER-CONFLICT\n',
      );
      final authorityPath = path.join(root.path, 'docs/specs/01-authority-map.md');
      _replace(authorityPath, '| conflicted |', '| active |');
      File(authorityPath).writeAsStringSync(
        '${File(authorityPath).readAsStringSync()}'
        '| Other conflict | `SPEC-OTHER-CONFLICT` | conflicted | `docs/specification.md` | `docs/spec-process/rules.md` |\n',
      );
      final conflictPath = path.join(
        root.path,
        'docs/spec-process/conflicts/current/CF-20260723-SPEC-CONFLICT.md',
      );
      _replace(conflictPath, 'SPEC-PROCESS-LOOP', 'SPEC-OTHER-CONFLICT');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'input-conflict-coverage');
    });

    test('requires every conflicted assertion to have a current conflict', () {
      final authorityPath = path.join(root.path, 'docs/specs/01-authority-map.md');
      _replace(authorityPath, '| active |', '| conflicted |');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'conflict-lifecycle');
    });

    test('rejects an OBS-only conflict with unrelated source truth', () {
      _addObservationOnlyConflict(root, unrelated: true);
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'conflict-source-coverage');
    });

    test('accepts union coverage across multiple relevant OBS conflict sources', () {
      _addObservationOnlyConflict(root, unrelated: false);
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('requires a resolved conflict decision to be approved', () {
      _addResolvedConflict(root);
      final decisionPath = _decisionPath(root);
      _replace(decisionPath, 'status: approved', 'status: rejected');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'conflict-state');
    });

    test('requires a resolved observation decision to be approved', () {
      _addResolvedObservation(root);
      final decisionPath = _decisionPath(root);
      _replace(decisionPath, 'status: approved', 'status: rejected');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'observation-state');
    });

    test('requires approved decisions to cover resolved record truth and surfaces', () {
      _addResolvedObservation(root);
      _addResolvedConflict(root);
      final observationPath = path.join(
        root.path,
        'docs/spec-process/observations/OBS-20260723-PROCESS-DRIFT.md',
      );
      final conflictPath = path.join(
        root.path,
        'docs/spec-process/conflicts/resolved/CF-20260723-SPEC-CONFLICT.md',
      );
      _replace(
        observationPath,
        'affected_surfaces:\n  - docs/specification.md',
        'affected_surfaces:\n  - docs/spec-process/rules.md',
      );
      _replace(
        conflictPath,
        'affected_surfaces:\n  - docs/specification.md',
        'affected_surfaces:\n  - docs/spec-process/rules.md',
      );
      final result = SpecificationChecker(root).check();
      final coverageIssues = result.issues.where((SpecificationIssue issue) {
        return issue.code == 'resolution-decision-coverage';
      }).toList();
      expect(coverageIssues, hasLength(2), reason: _messages(result));
    });

    test('requires decision and observation assertion and surface lists', () {
      final decisionPath = _decisionPath(root);
      _replace(
        decisionPath,
        'canonical_assertions:\n  - SPEC-PROCESS-LOOP',
        'canonical_assertions: []',
      );
      _replace(
        decisionPath,
        'affected_surfaces:\n  - docs/specification.md',
        'affected_surfaces: []',
      );
      _addResolvedObservation(root);
      final observationPath = path.join(
        root.path,
        'docs/spec-process/observations/OBS-20260723-PROCESS-DRIFT.md',
      );
      _replace(
        observationPath,
        'canonical_assertions:\n  - SPEC-PROCESS-LOOP',
        'canonical_assertions: []',
      );
      _replace(
        observationPath,
        'affected_surfaces:\n  - docs/specification.md',
        'affected_surfaces: []',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'canonical-assertion');
      _expectCode(result, 'delivery-surface');
    });

    test('rejects duplicate authority topics and assertion IDs', () {
      final authorityPath = path.join(root.path, 'docs/specs/01-authority-map.md');
      final row = '| Specification process | `SPEC-PROCESS-LOOP` | active | `docs/specification.md` | `docs/spec-process/rules.md` |';
      File(authorityPath).writeAsStringSync('${File(authorityPath).readAsStringSync()}$row\n');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'authority-topic');
      _expectCode(result, 'authority-assertion');
    });

    test('rejects multiple owners and missing authority paths', () {
      final authorityPath = path.join(root.path, 'docs/specs/01-authority-map.md');
      _replace(
        authorityPath,
        '`docs/specification.md` | `docs/spec-process/rules.md`',
        '`docs/specification.md`, `docs/missing.md` | `docs/missing-too.md`',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'authority-owner');
      _expectCode(result, 'repository-reference-missing');
    });

    test('does not drop plain references from a mixed Markdown-link cell', () {
      final authorityPath = path.join(root.path, 'docs/specs/01-authority-map.md');
      _replace(
        authorityPath,
        '`docs/spec-process/rules.md`',
        '[Rules](docs/spec-process/rules.md), `docs/missing-drift.md`',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'repository-reference-missing');
    });

    test('rejects unknown canonical assertions in records', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'SPEC-PROCESS-LOOP', 'SPEC-UNKNOWN-ASSERTION');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'canonical-assertion');
    });

    test('accepts syntax-only references into a missing optional repository', () {
      final repositoryMap = path.join(root.path, 'docs/specs/02-repository-map.md');
      File(repositoryMap).writeAsStringSync(
        '${File(repositoryMap).readAsStringSync()}| adapter | ../missing-adapter | no | Optional adapter checkout |\n',
      );
      final inputPath = _inputPath(root);
      _replace(
        inputPath,
        'delivery_surfaces:\n  - docs/specification.md',
        'delivery_surfaces:\n  - adapter:lib/bridge.dart',
      );
      _replace(
        _acceptancePath(root),
        'changed_surfaces:\n  - docs/specification.md',
        'changed_surfaces:\n  - adapter:lib/bridge.dart',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('preserves missing external surfaces in historical project records', () {
      final adapter = Directory(path.join(root.path, 'adapter'))..createSync();
      final repositoryMap = path.join(root.path, 'docs/specs/02-repository-map.md');
      File(repositoryMap).writeAsStringSync(
        '${File(repositoryMap).readAsStringSync()}| adapter | adapter | no | Historical adapter checkout |\n',
      );
      _replace(
        _acceptancePath(root),
        'changed_surfaces:\n  - docs/specification.md',
        'changed_surfaces:\n  - docs/specification.md\n  - adapter:removed.md',
      );
      expect(adapter.existsSync(), isTrue);
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('rejects missing required repository roots', () {
      final repositoryMap = path.join(root.path, 'docs/specs/02-repository-map.md');
      File(repositoryMap).writeAsStringSync(
        '${File(repositoryMap).readAsStringSync()}| adapter | ../missing-adapter | yes | Required adapter checkout |\n',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'repository-root-missing');
    });

    test('rejects repository roots and alias references that traverse outward', () {
      final repositoryMap = path.join(root.path, 'docs/specs/02-repository-map.md');
      File(repositoryMap).writeAsStringSync(
        '${File(repositoryMap).readAsStringSync()}'
        '| outside | ../../outside | no | Unsafe escape |\n'
        '| adapter | ../missing-adapter | no | Optional adapter |\n',
      );
      final inputPath = _inputPath(root);
      _replace(
        inputPath,
        'delivery_surfaces:\n  - docs/specification.md',
        'delivery_surfaces:\n  - adapter:../secret.md',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'repository-root');
      _expectCode(result, 'repository-reference');
    });

    test('allows repository-reference symlinks that stay inside the alias root', () {
      if (Platform.isWindows) {
        return;
      }
      final adapter = Directory(path.join(root.path, 'adapter'));
      adapter.createSync();
      _write(path.join(adapter.path, 'real.md'), '# Internal target\n');
      Link(path.join(adapter.path, 'linked.md')).createSync(
        path.join(adapter.path, 'real.md'),
      );
      final repositoryMap = path.join(root.path, 'docs/specs/02-repository-map.md');
      File(repositoryMap).writeAsStringSync(
        '${File(repositoryMap).readAsStringSync()}| adapter | adapter | yes | Fixture adapter |\n',
      );
      _replace(
        _inputPath(root),
        'delivery_surfaces:\n  - docs/specification.md',
        'delivery_surfaces:\n  - adapter:linked.md',
      );
      _replace(
        _acceptancePath(root),
        'changed_surfaces:\n  - docs/specification.md',
        'changed_surfaces:\n  - adapter:linked.md',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('rejects repository-reference symlinks that escape the alias root', () {
      if (Platform.isWindows) {
        return;
      }
      final adapter = Directory(path.join(root.path, 'adapter'));
      adapter.createSync();
      final outside = File(
        path.join(
          root.parent.path,
          '${path.basename(root.path)}-outside.md',
        ),
      );
      outside.writeAsStringSync('# Outside target\n');
      addTearDown(() {
        if (outside.existsSync()) {
          outside.deleteSync();
        }
      });
      Link(path.join(adapter.path, 'escaped.md')).createSync(outside.path);
      final repositoryMap = path.join(root.path, 'docs/specs/02-repository-map.md');
      File(repositoryMap).writeAsStringSync(
        '${File(repositoryMap).readAsStringSync()}| adapter | adapter | yes | Fixture adapter |\n',
      );
      _replace(
        _inputPath(root),
        'delivery_surfaces:\n  - docs/specification.md',
        'delivery_surfaces:\n  - adapter:escaped.md',
      );
      _replace(
        _acceptancePath(root),
        'changed_surfaces:\n  - docs/specification.md',
        'changed_surfaces:\n  - adapter:escaped.md',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'repository-reference-escape');
    });

    test('validates acceptance chronology and decision backlinks', () {
      final acceptancePath = _acceptancePath(root);
      _replace(acceptancePath, 'date: 2026-07-23', 'date: 2026-07-22');
      final decisionPath = _decisionPath(root);
      _replace(
        decisionPath,
        'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION',
        'acceptance_records: []',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'acceptance-date');
      _expectCode(result, 'missing-backlink');
    });

    test('requires source dates not to postdate capture', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'source_date: 2026-07-23', 'source_date: 2026-07-24');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'source-date');
    });

    test('requires source_date to use unknown instead of null', () {
      final inputPath = _inputPath(root);
      _replace(inputPath, 'source_date: 2026-07-23', 'source_date: null');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'field-type');
    });

    test('requires resolved conflict decisions not to postdate resolution', () {
      _addResolvedConflict(root);
      final decisionPath = _decisionPath(root);
      _replace(decisionPath, 'date: 2026-07-23', 'date: 2026-07-24');
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'conflict-decision-date');
    });

    test('allows a same-day resolved conflict in or out of the snapshot', () {
      _addResolvedConflict(root);
      final omittedResult = SpecificationChecker(root).check();
      expect(omittedResult.issues, isEmpty, reason: _messages(omittedResult));
      final acceptancePath = _acceptancePath(root);
      _replace(
        acceptancePath,
        'unresolved_conflicts: []',
        'unresolved_conflicts:\n  - CF-20260723-SPEC-CONFLICT',
      );
      final listedResult = SpecificationChecker(root).check();
      expect(listedResult.issues, isEmpty, reason: _messages(listedResult));
    });

    test('requires every open overlapping conflict in the acceptance snapshot', () {
      _addCurrentConflict(
        root,
        id: 'CF-20260722-SPEC-CONFLICT',
        openedDate: '2026-07-22',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'acceptance-conflict-snapshot');
    });

    test('allows omission of a conflict opened on the acceptance date', () {
      _addCurrentConflict(root);
      _replace(
        _acceptancePath(root),
        'result: accepted',
        'result: partial',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('does not let a superseded accepted record support verified', () {
      _addRejectedAcceptanceRetry(root);
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'verified-acceptance');
    });

    test('requires one acceptance record to cover every verified input dimension', () {
      final mutations = <({String from, String to})>[
        (
          from: 'canonical_assertions:\n  - SPEC-PROCESS-LOOP',
          to: 'canonical_assertions: []',
        ),
        (
          from: 'decisions:\n  - DEC-20260723-ADAPT-SPEC',
          to: 'decisions: []',
        ),
        (
          from: 'changed_surfaces:\n  - docs/specification.md',
          to: 'changed_surfaces:\n  - docs/spec-process/rules.md',
        ),
      ];
      for (final mutation in mutations) {
        final caseRoot = Directory.systemTemp.createTempSync('rwkv-acceptance-coverage-');
        try {
          _createHappyFixture(caseRoot);
          _replace(
            _acceptancePath(caseRoot),
            mutation.from,
            mutation.to,
          );
          final result = SpecificationChecker(caseRoot).check();
          _expectCode(result, 'verified-acceptance');
        } finally {
          caseRoot.deleteSync(recursive: true);
        }
      }
    });

    test('requires current accepted acceptance inputs to be verified', () {
      _replace(
        _inputPath(root),
        'delivery_status: verified',
        'delivery_status: implemented',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'accepted-acceptance-closure');
    });

    test('requires every current accepted ACC to cover its inputs independently', () {
      _addIncompleteAcceptedAcceptance(root);
      final result = SpecificationChecker(root).check();
      expect(
        result.issues.any((SpecificationIssue issue) {
          return issue.code == 'accepted-acceptance-closure' && issue.path.endsWith('ACC-20260723-INCOMPLETE.md');
        }),
        isTrue,
        reason: _messages(result),
      );
      expect(
        result.issues.where((SpecificationIssue issue) {
          return issue.code == 'verified-acceptance';
        }),
        isEmpty,
        reason: _messages(result),
      );
    });

    test('requires acceptance supersession to share an input and assertion', () {
      _addRejectedAcceptanceRetry(root);
      final retryPath = path.join(
        root.path,
        'docs/spec-process/acceptance-records/ACC-20260723-SPEC-RETRY.md',
      );
      _replace(
        retryPath,
        'canonical_assertions:\n  - SPEC-PROCESS-LOOP',
        'canonical_assertions:\n  - SPEC-UNRELATED-RULE',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'supersession-semantics');
    });

    test('rejects machine paths across supported operating systems and record fences', () {
      final inputPath = _inputPath(root);
      _replace(
        inputPath,
        'The user requested the migration.',
        r'''The user requested the migration.

```
/Users/alice/attachment.png
/home/alice/attachment.png
C:\Users\alice\attachment.png
\\server\share\attachment.png
/private/tmp/attachment.png
file:///Users/alice/attachment.png
```''',
      );
      final result = SpecificationChecker(root).check();
      final machineIssues = result.issues.where((SpecificationIssue issue) => issue.code == 'machine-path').toList();
      expect(machineIssues.length, greaterThanOrEqualTo(6), reason: _messages(result));
    });

    test('allows placeholder paths and command examples in non-record fences', () {
      final specificationPath = path.join(root.path, 'docs/specification.md');
      File(specificationPath).writeAsStringSync(
        '${File(specificationPath).readAsStringSync()}\n```${'\n'}/Users/alice/example-command${'\n'}```\n'
        '\nUse `/Users/<username>/...` only as an explanation of forbidden path shapes.\n',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('accepts non-record evidence Markdown without parsing it as a PI', () {
      final pemHeader = ['-----BEGIN ', 'PRIVATE KEY-----'].join();
      final encryptedPemHeader = ['-----BEGIN ENCRYPTED ', 'PRIVATE KEY-----'].join();
      final encryptedPemFooter = ['-----END ENCRYPTED ', 'PRIVATE KEY-----'].join();
      final pgpPemHeader = ['-----BEGIN PGP ', 'PRIVATE KEY BLOCK-----'].join();
      final pgpPemFooter = ['-----END PGP ', 'PRIVATE KEY BLOCK-----'].join();
      _write(
        path.join(root.path, 'docs/product-inputs/evidence/review-notes.md'),
        '''
# Review evidence

password: configured through the runtime environment
Bearer [REDACTED]
Authorization: Basic [REDACTED]
Cookie: session=[REDACTED]
Set-Cookie: auth=[REDACTED]
api_key: YOUR_API_KEY_PLACEHOLDER_1234
$pemHeader [REDACTED]
$encryptedPemHeader

[REDACTED]

$encryptedPemFooter
$pgpPemHeader
[REDACTED]
$pgpPemFooter
<https://example.test/file?token=YOUR_TOKEN_PLACEHOLDER_1234>
''',
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('rejects PI-shaped evidence and Markdown symlinks in record trees', () {
      _write(
        path.join(
          root.path,
          'docs/product-inputs/evidence/PI-20260723-MASQUERADE.md',
        ),
        '# Evidence only\n',
      );
      if (!Platform.isWindows) {
        Link(
          path.join(
            root.path,
            'docs/spec-process/decisions/DEC-20260723-LINK.md',
          ),
        ).createSync(_decisionPath(root));
        Link(
          path.join(
            root.path,
            'docs/product-inputs/evidence/review-link.md',
          ),
        ).createSync(_inputPath(root));
        Link(
          path.join(
            root.path,
            'docs/product-inputs/linked-date-directory',
          ),
        ).createSync(
          path.join(root.path, 'docs/product-inputs/2026-07-23'),
        );
      }
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'evidence-record');
      if (Platform.isWindows) {
        return;
      }
      final symlinkIssues = result.issues.where((SpecificationIssue issue) {
        return issue.code == 'record-symlink';
      }).toList();
      expect(symlinkIssues, hasLength(3), reason: _messages(result));
    });

    test('rejects a strict record root that is itself a symlink', () {
      if (Platform.isWindows) {
        return;
      }
      final decisions = Directory(
        path.join(root.path, 'docs/spec-process/decisions'),
      );
      final realDecisions = Directory(
        path.join(root.path, 'docs/spec-process/decisions-real'),
      );
      decisions.renameSync(realDecisions.path);
      Link(decisions.path).createSync(realDecisions.path);
      final evidence = Directory(
        path.join(root.path, 'docs/product-inputs/evidence'),
      );
      evidence.createSync();
      _write(path.join(evidence.path, 'review.md'), '# Evidence\n');
      final realEvidence = Directory(
        path.join(root.path, 'evidence-real'),
      );
      evidence.renameSync(realEvidence.path);
      Link(evidence.path).createSync(realEvidence.path);
      final result = SpecificationChecker(root).check();
      expect(
        result.issues.any((SpecificationIssue issue) {
          return issue.code == 'record-symlink' && issue.path == 'docs/spec-process/decisions';
        }),
        isTrue,
        reason: _messages(result),
      );
      expect(
        result.issues.any((SpecificationIssue issue) {
          return issue.code == 'record-symlink' && issue.path == 'docs/product-inputs/evidence';
        }),
        isTrue,
        reason: _messages(result),
      );
    });

    test('scans evidence Markdown fences for machine-local paths', () {
      _write(
        path.join(root.path, 'docs/product-inputs/evidence/local-path.md'),
        '''
# Evidence

```
/Users/alice/private-evidence.txt
```
''',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'machine-path');
    });

    test('detects high-confidence secret families without echoing their values', () {
      final values = <String>[
        ['-----BEGIN ENCRYPTED ', 'PRIVATE KEY-----'].join(),
        ['gh', 'p_', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'].join(),
        ['xo', 'xb-', '12345678901234567890ABCDE'].join(),
        ['sk', '-proj-', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ123456'].join(),
        ['AK', 'IA', 'ABCDEFGHIJKLMNOP'].join(),
        ['eyJabcdefghijk', 'eyJabcdefghijk', 'abcdefghijklm'].join('.'),
        'abcdefghijklmnopqrstuvwxyz012345',
        'dXNlcjphY3R1YWwtc2VjcmV0==',
        'sessionvalue0123456789',
        'setcookievalue01234567',
        'PasswordValue0123456789',
        'ApiKeyValue012345678901',
        'ApiHyphenKey0123456789',
        'AccessTokenValue01234567',
        'ClientSecretValue0123456',
        'GenericTokenValue0123456',
        'abcdef0123456789abcdef0123456789',
        'fedcba9876543210fedcba9876543210',
        'tokenqueryvalue0123456789',
        'accesskeyvalue01234567890',
        'querykeyvalue012345678901',
        'credentialvalue012345678',
        ['-----BEGIN PGP ', 'PRIVATE KEY BLOCK-----'].join(),
      ];
      _write(
        path.join(root.path, 'docs/product-inputs/evidence/sensitive.md'),
        '''
# Sensitive evidence

${values[0]}
${values[1]}
${values[2]}
${values[3]}
${values[4]}
${values[5]}
Authorization: Bearer ${values[6]}
Authorization: Basic ${values[7]}
Cookie: session_id=${values[8]}
Set-Cookie: auth_session=${values[9]}; HttpOnly
password = ${values[10]}
api_key: ${values[11]}
api-key=${values[12]}
access_token: ${values[13]}
client_secret: ${values[14]}
token: ${values[15]}
https://example.test/file?x-amz-signature=${values[16]}
https://example.test/file?sig=${values[17]}
https://example.test/file?token=${values[18]}
https://example.test/file?access_key=${values[19]}
https://example.test/file?key=${values[20]}
https://example.test/file?credential=${values[21]}
${values[22]}
''',
      );
      final result = SpecificationChecker(root).check();
      final secretIssues = result.issues.where((SpecificationIssue issue) {
        return issue.code == 'secret-material';
      }).toList();
      expect(secretIssues, hasLength(values.length), reason: _messages(result));
      final diagnostics = secretIssues.map((SpecificationIssue issue) => issue.formatted).join('\n');
      for (final value in values) {
        expect(diagnostics, isNot(contains(value)));
      }
    });

    test('rejects a PEM block with payload around a redaction marker', () {
      final pemHeader = ['-----BEGIN ', 'PRIVATE KEY-----'].join();
      final pemFooter = ['-----END ', 'PRIVATE KEY-----'].join();
      _write(
        path.join(root.path, 'docs/product-inputs/evidence/invalid-redaction.md'),
        '''
# Invalid PEM redaction

$pemHeader
[REDACTED]
YW55LWFkZGl0aW9uYWwtcGF5bG9hZA==
$pemFooter
''',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'secret-material');
    });

    test('redacts secrets from every diagnostic path and message', () {
      final githubToken = ['gh', 'p_', 'QWERTYUIOPASDFGHJKLZXCVBNM1234567890'].join();
      const signedValue = '0123456789abcdef0123456789abcdef';
      final signedUrl = ['https://example.test/download', '?token=', signedValue].join();
      _replace(
        _inputPath(root),
        'status: merged',
        'status: $githubToken',
      );
      _replace(
        _acceptancePath(root),
        'changed_surfaces:\n  - docs/specification.md',
        'changed_surfaces:\n  - $signedUrl',
      );
      _write(
        path.join(
          root.path,
          'docs/product-inputs/evidence/review-$githubToken.md',
        ),
        '# Evidence\n\n/Users/alice/private.txt\n',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'secret-material');
      _expectCode(result, 'absolute-reference');
      final diagnostics = _messages(result);
      expect(diagnostics, isNot(contains(githubToken)));
      expect(diagnostics, isNot(contains(signedValue)));
      expect(diagnostics, isNot(contains(signedUrl)));
      expect(
        result.issues.any((SpecificationIssue issue) {
          return issue.path.contains('[REDACTED]');
        }),
        isTrue,
        reason: diagnostics,
      );
    });

    test('scans strict record bodies for secrets without echoing them', () {
      final githubToken = ['gh', 'p_', 'ABCDEFGHIJKLMNOPQRSTUVWX9876543210'].join();
      _replace(
        _inputPath(root),
        'The user requested the migration.',
        'The user requested the migration.\n\n$githubToken',
      );
      final result = SpecificationChecker(root).check();
      expect(
        result.issues.any((SpecificationIssue issue) {
          return issue.code == 'secret-material' && issue.path.endsWith('PI-20260723-SPEC-SYSTEM-MIGRATION.md');
        }),
        isTrue,
        reason: _messages(result),
      );
      expect(_messages(result), isNot(contains(githubToken)));
    });

    test('does not let surrounding placeholder prose mask a captured secret', () {
      final githubToken = ['gh', 'p_', 'ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210'].join();
      const signedValue = '1234567890abcdef1234567890abcdef';
      _write(
        path.join(root.path, 'docs/product-inputs/evidence/masked-secret.md'),
        '''
# Masking regression

password: [REDACTED] but this unrelated value is $githubToken
Example endpoint: <https://example.test/file?token=$signedValue>
''',
      );
      final result = SpecificationChecker(root).check();
      final secretIssues = result.issues.where((SpecificationIssue issue) {
        return issue.code == 'secret-material';
      }).toList();
      expect(secretIssues, hasLength(2), reason: _messages(result));
      final diagnostics = secretIssues.map((SpecificationIssue issue) => issue.formatted).join('\n');
      expect(diagnostics, isNot(contains(githubToken)));
      expect(diagnostics, isNot(contains(signedValue)));
    });

    test('rejects template field, path, and body-heading drift', () {
      final mutations = <({String from, String to})>[
        (from: 'owner: root Codex agent\n', to: ''),
        (from: 'unresolved_conflicts: []\n', to: ''),
        (from: 'owner: root Codex agent', to: 'owner: []'),
        (from: '## Semantic or visual review', to: '## Review'),
        (
          from: '---\n# Acceptance\n\n## Mechanical evidence',
          to: '---\n#\n\n## Mechanical evidence',
        ),
        (
          from: 'Path: `docs/spec-process/acceptance-records/ACC-YYYYMMDD-SLUG.md`',
          to: 'Path: `docs/spec-process/acceptance-records/WRONG.md`',
        ),
      ];
      for (final mutation in mutations) {
        final caseRoot = Directory.systemTemp.createTempSync('rwkv-template-contract-');
        try {
          _createHappyFixture(caseRoot);
          final templatesPath = path.join(caseRoot.path, 'docs/spec-process/templates.md');
          _replace(templatesPath, mutation.from, mutation.to);
          final result = SpecificationChecker(caseRoot).check();
          expect(
            result.issues.any((SpecificationIssue issue) => issue.code == 'template-contract'),
            isTrue,
            reason: 'Mutation did not fail: ${mutation.from} -> ${mutation.to}\n${_messages(result)}',
          );
        } finally {
          caseRoot.deleteSync(recursive: true);
        }
      }
    });

    test('rejects state matrix drift from checker combinations', () {
      final rulesPath = path.join(root.path, 'docs/spec-process/rules.md');
      _replace(
        rulesPath,
        '| conflict | pending | blocked |',
        '| conflict | pending | implemented |',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'state-matrix-contract');
    });

    test('checks all declared process versions and in-progress plan structure', () {
      final templatesPath = path.join(root.path, 'docs/spec-process/templates.md');
      _replace(templatesPath, 'Process version: v1.7', 'Process version: v1.8');
      _write(
        path.join(root.path, 'docs/plans/2026-07-23-active.md'),
        '# Active plan\n\nStatus: in progress\n\n## Scope\n\nOnly scope.\n',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'process-version');
      _expectCode(result, 'plan-contract');
    });

    test('checks completed plans and rejects unknown plan status', () {
      _write(
        path.join(root.path, 'docs/plans/2026-07-23-completed.md'),
        '''
# Completed plan

Status: completed
Started: 2026-07-23

## Scope
Done.

## Linked Truth
Done.

## Intended Behavior
Done.

## Exclusions
Done.

## Milestones
Done.

## Mechanical Checks
Done.

## Result-Level Review
Done.

## Progress
2026-07-23: Done.

## Discoveries And Decisions
Done.

## Remaining Gaps
None.

## Retrospective
Done.
''',
      );
      _write(
        path.join(root.path, 'docs/plans/2026-07-23-unknown.md'),
        '''
# Unknown plan

Status: active
Started: not-a-date
''',
      );
      final result = SpecificationChecker(root).check();
      _expectCode(result, 'plan-contract');
      _expectCode(result, 'plan-status');
      _expectCode(result, 'plan-started');
    });

    test('accepts a completed plan with the full contract', () {
      _write(
        path.join(root.path, 'docs/plans/2026-07-23-complete.md'),
        _validPlanContent('completed'),
      );
      final result = SpecificationChecker(root).check();
      expect(result.issues, isEmpty, reason: _messages(result));
    });

    test('rejects completed plans with an empty section or empty H1', () {
      _write(
        path.join(root.path, 'docs/plans/2026-07-23-empty-section.md'),
        _validPlanContent('completed').replaceFirst(
          '## Outcome\nAccepted.',
          '## Outcome\n<!-- intentionally empty -->',
        ),
      );
      _write(
        path.join(root.path, 'docs/plans/2026-07-23-empty-h1.md'),
        _validPlanContent('completed').replaceFirst(
          '# Complete plan',
          '#',
        ),
      );
      final result = SpecificationChecker(root).check();
      expect(
        result.issues.any((SpecificationIssue issue) {
          return issue.code == 'plan-contract' && issue.message.contains('section "Outcome" must be meaningful');
        }),
        isTrue,
        reason: _messages(result),
      );
      expect(
        result.issues.any((SpecificationIssue issue) {
          return issue.code == 'plan-contract' && issue.message.contains('non-empty H1');
        }),
        isTrue,
        reason: _messages(result),
      );
    });
  });

  group('check_specification CLI', () {
    test('returns 0, 1, and 2 for success, validation, and usage outcomes', () {
      final root = Directory.systemTemp.createTempSync('rwkv-spec-cli-');
      try {
        _createHappyFixture(root);
        final success = _runCli(root.path);
        expect(success.exitCode, 0, reason: '${success.stdout}\n${success.stderr}');

        File(_inputPath(root)).writeAsStringSync('# no front matter\n');
        final validationFailure = _runCli(root.path);
        expect(validationFailure.exitCode, 1, reason: '${validationFailure.stdout}\n${validationFailure.stderr}');

        final usageFailure = Process.runSync(
          Platform.resolvedExecutable,
          const ['run', 'bin/check_specification.dart', '--unknown'],
          workingDirectory: Directory.current.path,
        );
        expect(usageFailure.exitCode, 2, reason: '${usageFailure.stdout}\n${usageFailure.stderr}');
      } finally {
        root.deleteSync(recursive: true);
      }
    });
  });
}

String _validPlanContent(String status) {
  return '''
# Complete plan

Status: $status
Started: 2026-07-23

## Scope
Done.

## Linked Truth
Done.

## Intended Behavior
Done.

## Exclusions
Done.

## Milestones
Done.

## Mechanical Checks
Done.

## Result-Level Review
Done.

## Progress
2026-07-23: Done.

## Discoveries And Decisions
Done.

## Remaining Gaps
None.

## Retrospective
Done.

## Outcome
Accepted.
''';
}

ProcessResult _runCli(String rootPath) {
  return Process.runSync(
    Platform.resolvedExecutable,
    [
      'run',
      'bin/check_specification.dart',
      '--root',
      rootPath,
    ],
    workingDirectory: Directory.current.path,
  );
}

void _createHappyFixture(Directory root) {
  _write(path.join(root.path, 'pubspec.yaml'), 'name: fixture\n');
  Directory(path.join(root.path, 'lib')).createSync(recursive: true);
  Directory(path.join(root.path, 'tools')).createSync(recursive: true);

  const agents = '''
# Agent instructions

Read `docs/specification.md` and use `.agents/skills/spec-sync/SKILL.md`.
Create `docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md`.
Track current conflicts under `docs/spec-process/conflicts/current/`.
''';
  _write(path.join(root.path, 'AGENTS.md'), agents);
  _write(path.join(root.path, '.github/copilot-instructions.md'), agents);

  final requiredContent = <String, String>{
    'SPEC-LOOP.md': '''
# Spec Sync Loop

Process version: v1.7
Effective date: 2026-07-23
''',
    'docs/specification.md': '''
# Fixture Specification

Process version: v1.7

SPEC-PROCESS-LOOP

See `SPEC-LOOP.md`, `docs/specs/00-inventory.md`, `docs/specs/01-authority-map.md`,
`docs/specs/02-repository-map.md`, `docs/spec-process/rules.md`,
`docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md`, and
`.agents/skills/spec-sync/SKILL.md`.
''',
    'docs/specs/00-inventory.md': '''
# Inventory

Process version: v1.7
Effective date: 2026-07-23

- `docs/specification.md`
- `docs/specs/01-authority-map.md`
- `docs/specs/02-repository-map.md`
''',
    'docs/specs/01-authority-map.md': '''
# Authority Map

Process version: v1.7
Effective date: 2026-07-23

| Topic | Assertion IDs | Lifecycle | Canonical owner | Required drift surfaces |
| --- | --- | --- | --- | --- |
| Specification process | `SPEC-PROCESS-LOOP` | active | `docs/specification.md` | `docs/spec-process/rules.md` |
''',
    'docs/specs/02-repository-map.md': '''
# Repository Map

Process version: v1.7

| Alias | Root | Required | Description |
| --- | --- | --- | --- |
''',
    'docs/spec-process/rules.md': '''
# Rules

Process version: v1.7
Effective date: 2026-07-23

See `docs/specs/01-authority-map.md`, `docs/specs/02-repository-map.md`, and
`docs/spec-process/acceptance-records/`.

| status | effective_status | delivery_status |
| --- | --- | --- |
| inbox | pending | not_started or planned |
| deferred | pending | not_started or planned |
| conflict | pending | blocked |
| merged | active | not_started, planned, in_progress, implemented, verified, or not_applicable |
| merged | superseded | not_started, planned, in_progress, implemented, verified, or not_applicable |
| dismissed | historical | not_applicable |
''',
    'docs/spec-process/changelog.md': '''
# Changelog

Process version: v1.7
Effective date: 2026-07-23

## v1.7 - 2026-07-23
''',
    'docs/spec-process/eval-cases.md': '''
# Eval Cases

Process version: v1.7

SPEC-SYNC-ACCEPTANCE-GUARDRAILS
''',
    'docs/spec-process/templates.md': '''
# Templates

Process version: v1.7

## Product Or Process Input

Path: `docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md`

```markdown
---
id: PI-YYYYMMDD-SLUG
type: product_input
captured_date: YYYY-MM-DD
source_date: YYYY-MM-DD
source: user
category: product
status: inbox
effective_status: pending
delivery_status: not_started
canonical_assertions:
  - SPEC-EXAMPLE
delivery_surfaces:
  - lib/example.dart
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records: []
---
# Input

## Raw statement

Statement.

## Extracted assertions

Assertion.
```

## Decision

Path: `docs/spec-process/decisions/DEC-YYYYMMDD-SLUG.md`

```markdown
---
id: DEC-YYYYMMDD-SLUG
type: decision
date: YYYY-MM-DD
status: approved
approved_by: user
inputs:
  - PI-YYYYMMDD-SLUG
observations: []
conflicts: []
supersedes: []
superseded_by: []
acceptance_records: []
canonical_assertions:
  - SPEC-EXAMPLE
affected_surfaces:
  - docs/example.md
---
# Decision

## Decision

Ruling.

## Reason

Reason.
```

## Observation

Path: `docs/spec-process/observations/OBS-YYYYMMDD-SLUG.md`

```markdown
---
id: OBS-YYYYMMDD-SLUG
type: observation
date: YYYY-MM-DD
status: recorded
inputs: []
conflicts: []
decision: null
canonical_assertions:
  - SPEC-EXAMPLE
affected_surfaces:
  - docs/example.md
---
# Observation

## Observation

Finding.

## Implication

Impact.

## Proposed next step

Review.

## Resolution
```

## Conflict

Current path: `docs/spec-process/conflicts/current/CF-YYYYMMDD-SLUG.md`

Resolved path: `docs/spec-process/conflicts/resolved/CF-YYYYMMDD-SLUG.md`

```markdown
---
id: CF-YYYYMMDD-SLUG
type: conflict
status: unresolved
opened_date: YYYY-MM-DD
resolved_date: null
inputs:
  - PI-YYYYMMDD-SLUG
observations: []
canonical_assertions:
  - SPEC-EXAMPLE
affected_surfaces:
  - docs/example.md
blocking_scope: exact scope
decision: null
---
# Conflict

## Existing assertion

Existing.

## New or observed assertion

New.

## Required decision

Question.

## Resolution
```

## Acceptance

Path: `docs/spec-process/acceptance-records/ACC-YYYYMMDD-SLUG.md`

```markdown
---
id: ACC-YYYYMMDD-SLUG
type: acceptance
date: YYYY-MM-DD
owner: root Codex agent
inputs:
  - PI-YYYYMMDD-SLUG
decisions: []
canonical_assertions:
  - SPEC-EXAMPLE
changed_surfaces:
  - lib/example.dart
unresolved_conflicts: []
result: accepted
supersedes_acceptance: []
superseded_by: []
---
# Acceptance

## Mechanical evidence

Evidence.

## Requirement review

Review.

## Semantic or visual review

Review.

## Exclusions

None.
```
''',
    'docs/plans/PLANS.md': '# Plans contract\n',
    'docs/product-inputs/README.md': '# Product inputs\n',
    'docs/spec-process/decisions/README.md': '# Decisions\n',
    'docs/spec-process/observations/README.md': '# Observations\n',
    'docs/spec-process/conflicts/README.md': '# Conflicts\n',
    'docs/spec-process/acceptance-records/README.md': '''
# Acceptance records

Process version: v1.7
''',
    '.agents/skills/spec-sync/SKILL.md': '''
# Spec Sync

Read `docs/specification.md`, `docs/specs/00-inventory.md`,
`docs/specs/01-authority-map.md`, `docs/specs/02-repository-map.md`,
`docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md`, and
`docs/spec-process/conflicts/current/`.
Run `tools/bin/check_specification.dart`.
Apply `SPEC-SYNC-ACCEPTANCE-GUARDRAILS`.
''',
    '.agents/skills/spec-sync/agents/openai.yaml': 'name: spec-sync\n',
  };
  for (final entry in requiredContent.entries) {
    _write(path.join(root.path, entry.key), entry.value);
  }
  _write(
    _inputPath(root),
    '''
---
id: PI-20260723-SPEC-SYSTEM-MIGRATION
type: product_input
captured_date: 2026-07-23
source_date: 2026-07-23
source: user
category: process
status: merged
effective_status: active
delivery_status: verified
canonical_assertions:
  - SPEC-PROCESS-LOOP
delivery_surfaces:
  - docs/specification.md
conflicts: []
supersedes: []
superseded_by: []
decisions:
  - DEC-20260723-ADAPT-SPEC
acceptance_records:
  - ACC-20260723-SPEC-MIGRATION
---
# Migrate the Specification system

## Raw statement

The user requested the migration.

## Extracted assertions

- Adapt the process to this repository.
''',
  );
  _write(
    _decisionPath(root),
    '''
---
id: DEC-20260723-ADAPT-SPEC
type: decision
date: 2026-07-23
status: approved
approved_by: user
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
observations: []
conflicts: []
supersedes: []
superseded_by: []
acceptance_records:
  - ACC-20260723-SPEC-MIGRATION
canonical_assertions:
  - SPEC-PROCESS-LOOP
affected_surfaces:
  - docs/specification.md
---
# Adapt the process

## Decision

Use the Dart-native v1.7 process.

## Reason

It is portable and strict.
''',
  );
  _write(
    _acceptancePath(root),
    '''
---
id: ACC-20260723-SPEC-MIGRATION
type: acceptance
date: 2026-07-23
owner: root Codex agent
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
decisions:
  - DEC-20260723-ADAPT-SPEC
canonical_assertions:
  - SPEC-PROCESS-LOOP
changed_surfaces:
  - docs/specification.md
unresolved_conflicts: []
result: accepted
supersedes_acceptance: []
superseded_by: []
---
# Specification migration acceptance

## Mechanical evidence

The checker passed.

## Requirement review

All requested mechanics are present.

## Semantic or visual review

The process graph was inspected.

## Exclusions

No runtime behavior changed.
''',
  );
}

void _writeProductInput(
  Directory root, {
  required String id,
  String capturedDate = '2026-07-23',
  required String effectiveStatus,
  List<String> supersedes = const [],
  List<String> supersededBy = const [],
}) {
  final supersedesYaml = _yamlList(supersedes);
  final supersededByYaml = _yamlList(supersededBy);
  final relativeDirectory = capturedDate;
  _write(
    path.join(root.path, 'docs/product-inputs/$relativeDirectory/$id.md'),
    '''
---
id: $id
type: product_input
captured_date: $capturedDate
source_date: $capturedDate
source: fixture
category: process
status: merged
effective_status: $effectiveStatus
delivery_status: not_applicable
canonical_assertions:
  - SPEC-PROCESS-LOOP
delivery_surfaces: []
conflicts: []
supersedes:$supersedesYaml
superseded_by:$supersededByYaml
decisions: []
acceptance_records: []
---
# Historical input

## Raw statement

Historical wording.

## Extracted assertions

Historical assertion.
''',
  );
}

void _writeDecision(
  Directory root, {
  required String id,
  required String status,
  List<String> supersedes = const [],
  List<String> supersededBy = const [],
  List<String> acceptanceRecords = const [],
}) {
  final supersedesYaml = _yamlList(supersedes);
  final supersededByYaml = _yamlList(supersededBy);
  final acceptanceRecordsYaml = _yamlList(acceptanceRecords);
  _write(
    path.join(root.path, 'docs/spec-process/decisions/$id.md'),
    '''
---
id: $id
type: decision
date: 2026-07-23
status: $status
approved_by: user
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
observations: []
conflicts: []
supersedes:$supersedesYaml
superseded_by:$supersededByYaml
acceptance_records:$acceptanceRecordsYaml
canonical_assertions:
  - SPEC-PROCESS-LOOP
affected_surfaces:
  - docs/specification.md
---
# Historical decision

## Decision

Historical ruling.

## Reason

Historical context.
''',
  );
}

void _addCurrentConflict(
  Directory root, {
  String id = 'CF-20260723-SPEC-CONFLICT',
  String openedDate = '2026-07-23',
}) {
  final inputPath = _inputPath(root);
  _replace(inputPath, 'status: merged', 'status: conflict');
  _replace(inputPath, 'effective_status: active', 'effective_status: pending');
  _replace(inputPath, 'delivery_status: verified', 'delivery_status: blocked');
  _replace(inputPath, 'conflicts: []', 'conflicts:\n  - $id');
  final authorityPath = path.join(root.path, 'docs/specs/01-authority-map.md');
  _replace(authorityPath, '| active |', '| conflicted |');
  _write(
    path.join(root.path, 'docs/spec-process/conflicts/current/$id.md'),
    '''
---
id: $id
type: conflict
status: unresolved
opened_date: $openedDate
resolved_date: null
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
observations: []
canonical_assertions:
  - SPEC-PROCESS-LOOP
affected_surfaces:
  - docs/specification.md
blocking_scope: Specification migration
decision: null
---
# Specification conflict

## Existing assertion

Existing behavior.

## New or observed assertion

Competing behavior.

## Required decision

Choose one behavior.

## Resolution
''',
  );
}

void _addObservationOnlyConflict(
  Directory root, {
  required bool unrelated,
}) {
  const conflictId = 'CF-20260723-OBS-PROVENANCE';
  final conflictAssertions = unrelated ? const ['SPEC-CONFLICT-A'] : const ['SPEC-CONFLICT-A', 'SPEC-CONFLICT-B'];
  final conflictSurfaces = unrelated ? const ['docs/spec-process/rules.md'] : const ['docs/specification.md', 'docs/spec-process/rules.md'];
  final observations = unrelated
      ? const [
          (
            id: 'OBS-20260723-UNRELATED-SOURCE',
            assertions: ['SPEC-PROCESS-LOOP'],
            surfaces: ['docs/specification.md'],
          ),
        ]
      : const [
          (
            id: 'OBS-20260723-CONFLICT-A',
            assertions: ['SPEC-CONFLICT-A'],
            surfaces: ['docs/specification.md'],
          ),
          (
            id: 'OBS-20260723-CONFLICT-B',
            assertions: ['SPEC-CONFLICT-B'],
            surfaces: ['docs/spec-process/rules.md'],
          ),
        ];
  final specificationPath = path.join(root.path, 'docs/specification.md');
  final authorityPath = path.join(root.path, 'docs/specs/01-authority-map.md');
  for (final assertionId in conflictAssertions) {
    File(specificationPath).writeAsStringSync(
      '${File(specificationPath).readAsStringSync()}\n$assertionId\n',
    );
    File(authorityPath).writeAsStringSync(
      '${File(authorityPath).readAsStringSync()}'
      '| $assertionId | `$assertionId` | conflicted | `docs/specification.md` | `docs/spec-process/rules.md` |\n',
    );
  }
  for (final observation in observations) {
    _write(
      path.join(
        root.path,
        'docs/spec-process/observations/${observation.id}.md',
      ),
      '''
---
id: ${observation.id}
type: observation
date: 2026-07-23
status: recorded
inputs: []
conflicts:
  - $conflictId
decision: null
canonical_assertions:${_yamlList(observation.assertions)}
affected_surfaces:${_yamlList(observation.surfaces)}
---
# Conflict source observation

## Observation

The source recorded relevant behavior.

## Implication

The behavior may conflict.

## Proposed next step

Review the conflict.

## Resolution
''',
    );
  }
  final observationIds = observations.map((observation) => observation.id).toList();
  _write(
    path.join(
      root.path,
      'docs/spec-process/conflicts/current/$conflictId.md',
    ),
    '''
---
id: $conflictId
type: conflict
status: unresolved
opened_date: 2026-07-23
resolved_date: null
inputs: []
observations:${_yamlList(observationIds)}
canonical_assertions:${_yamlList(conflictAssertions)}
affected_surfaces:${_yamlList(conflictSurfaces)}
blocking_scope: Observation provenance
decision: null
---
# Observation provenance conflict

## Existing assertion

Existing source behavior.

## New or observed assertion

Conflicting behavior.

## Required decision

Choose the governing behavior.

## Resolution
''',
  );
}

void _addResolvedConflict(Directory root) {
  final inputPath = _inputPath(root);
  _replace(inputPath, 'conflicts: []', 'conflicts:\n  - CF-20260723-SPEC-CONFLICT');
  final decisionPath = _decisionPath(root);
  _replace(decisionPath, 'conflicts: []', 'conflicts:\n  - CF-20260723-SPEC-CONFLICT');
  _write(
    path.join(root.path, 'docs/spec-process/conflicts/resolved/CF-20260723-SPEC-CONFLICT.md'),
    '''
---
id: CF-20260723-SPEC-CONFLICT
type: conflict
status: resolved
opened_date: 2026-07-23
resolved_date: 2026-07-23
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
observations: []
canonical_assertions:
  - SPEC-PROCESS-LOOP
affected_surfaces:
  - docs/specification.md
blocking_scope: Specification migration
decision: DEC-20260723-ADAPT-SPEC
---
# Specification conflict

## Existing assertion

Existing behavior.

## New or observed assertion

Competing behavior.

## Required decision

Choose one behavior.

## Resolution

The approved decision resolved it.
''',
  );
}

void _addResolvedObservation(Directory root) {
  const observationId = 'OBS-20260723-PROCESS-DRIFT';
  final decisionPath = _decisionPath(root);
  _replace(decisionPath, 'observations: []', 'observations:\n  - $observationId');
  _write(
    path.join(root.path, 'docs/spec-process/observations/$observationId.md'),
    '''
---
id: $observationId
type: observation
date: 2026-07-23
status: resolved
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
conflicts: []
decision: DEC-20260723-ADAPT-SPEC
canonical_assertions:
  - SPEC-PROCESS-LOOP
affected_surfaces:
  - docs/specification.md
---
# Process drift

## Observation

The process drifted.

## Implication

Validation was weaker.

## Proposed next step

Adopt v1.7.

## Resolution

The decision approved v1.7.
''',
  );
}

void _addRejectedAcceptanceRetry(Directory root) {
  const retryId = 'ACC-20260723-SPEC-RETRY';
  final acceptancePath = _acceptancePath(root);
  _replace(
    acceptancePath,
    'superseded_by: []',
    'superseded_by:\n  - $retryId',
  );
  final inputPath = _inputPath(root);
  _replace(
    inputPath,
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION',
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION\n  - $retryId',
  );
  final decisionPath = _decisionPath(root);
  _replace(
    decisionPath,
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION',
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION\n  - $retryId',
  );
  _write(
    path.join(root.path, 'docs/spec-process/acceptance-records/$retryId.md'),
    '''
---
id: $retryId
type: acceptance
date: 2026-07-23
owner: root Codex agent
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
decisions:
  - DEC-20260723-ADAPT-SPEC
canonical_assertions:
  - SPEC-PROCESS-LOOP
changed_surfaces:
  - docs/specification.md
unresolved_conflicts: []
result: rejected
supersedes_acceptance:
  - ACC-20260723-SPEC-MIGRATION
superseded_by: []
---
# Rejected retry

## Mechanical evidence

The command completed.

## Requirement review

A requirement failed.

## Semantic or visual review

The result was inspected.

## Exclusions

None.
''',
  );
}

void _addIncompleteAcceptedAcceptance(Directory root) {
  const acceptanceId = 'ACC-20260723-INCOMPLETE';
  _replace(
    _inputPath(root),
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION',
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION\n  - $acceptanceId',
  );
  _replace(
    _decisionPath(root),
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION',
    'acceptance_records:\n  - ACC-20260723-SPEC-MIGRATION\n  - $acceptanceId',
  );
  _write(
    path.join(
      root.path,
      'docs/spec-process/acceptance-records/$acceptanceId.md',
    ),
    '''
---
id: $acceptanceId
type: acceptance
date: 2026-07-23
owner: root Codex agent
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
decisions:
  - DEC-20260723-ADAPT-SPEC
canonical_assertions:
  - SPEC-PROCESS-LOOP
changed_surfaces:
  - docs/spec-process/rules.md
unresolved_conflicts: []
result: accepted
supersedes_acceptance: []
superseded_by: []
---
# Incomplete acceptance

## Mechanical evidence

The command completed.

## Requirement review

The surface review was incomplete.

## Semantic or visual review

The result was inspected.

## Exclusions

None.
''',
  );
}

String _yamlList(List<String> values) {
  if (values.isEmpty) {
    return ' []';
  }
  final buffer = StringBuffer();
  for (final value in values) {
    buffer.write('\n  - $value');
  }
  return buffer.toString();
}

String _inputPath(Directory root) {
  return path.join(
    root.path,
    'docs/product-inputs/2026-07-23/PI-20260723-SPEC-SYSTEM-MIGRATION.md',
  );
}

String _decisionPath(Directory root) {
  return path.join(
    root.path,
    'docs/spec-process/decisions/DEC-20260723-ADAPT-SPEC.md',
  );
}

String _acceptancePath(Directory root) {
  return path.join(
    root.path,
    'docs/spec-process/acceptance-records/ACC-20260723-SPEC-MIGRATION.md',
  );
}

void _write(String filePath, String content) {
  final file = File(filePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _replace(String filePath, String from, String to) {
  final file = File(filePath);
  final content = file.readAsStringSync();
  if (!content.contains(from)) {
    throw StateError('Fixture replacement source not found in $filePath: $from');
  }
  file.writeAsStringSync(content.replaceFirst(from, to));
}

void _expectCode(SpecificationCheckResult result, String code) {
  expect(
    result.issues.any((SpecificationIssue issue) => issue.code == code),
    isTrue,
    reason: 'Expected [$code].\n${_messages(result)}',
  );
}

String _messages(SpecificationCheckResult result) {
  return result.issues.map((SpecificationIssue issue) => issue.formatted).join('\n');
}
