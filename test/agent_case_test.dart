// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/agent.dart';
import 'package:zone/model/agent_case.dart';

void main() {
  test('bundles all 30 Primitive Bench cases', () {
    final raw = File('assets/agent_cases/primitive_bench.json').readAsStringSync();
    final decoded = jsonDecode(raw) as List<dynamic>;
    final cases = <AgentCase>[];
    for (final value in decoded) {
      cases.add(AgentCase.fromJson((value as Map<dynamic, dynamic>).cast<String, dynamic>()));
    }

    expect(cases, hasLength(30));
    expect(cases.first.name, 'arithmetic');
    expect(cases.last.name, 'markdown_release_notes');
    expect(
      cases.expand((agentCase) => agentCase.toolNames).toSet(),
      containsAll(AgentSandboxCapabilityNames.all),
    );
  });

  test('parses Primitive Bench case JSON into an isolated case', () {
    final agentCase = AgentCase.fromJson(<String, dynamic>{
      'name': 'find_read_submit',
      'title': 'Find Read Submit',
      'system': 'base',
      'prompt': 'Find the answer.',
      'tools': 'nav',
      'environment': <String, dynamic>{
        'files': <String, dynamic>{
          'answer.txt': <String>['BLUEBIRD'],
          'noise.txt': <String, dynamic>{
            'repeat': <String, dynamic>{'text': 'noise\n', 'count': 3},
          },
        },
        'expected_submit': 'BLUEBIRD',
        'required_tools': <String>['list_files', 'read_file', 'submit'],
      },
      'evaluation': 'submit',
      'max_turns': 10,
    });

    expect(agentCase.name, 'find_read_submit');
    expect(agentCase.toolNames, containsAll(<String>['list_files', 'read_file', 'search', 'run_lua', 'submit']));
    expect(agentCase.files['answer.txt'], 'BLUEBIRD\n');
    expect(agentCase.files['noise.txt'], 'noise\nnoise\nnoise\n');
    expect(agentCase.maxTurns, 10);
  });

  test('scores an exact submitted answer', () async {
    final agentCase = AgentCase.fromJson(<String, dynamic>{
      'name': 'find_read_submit',
      'title': 'Find Read Submit',
      'system': 'base',
      'prompt': 'Find the answer.',
      'tools': 'nav',
      'environment': <String, dynamic>{
        'files': <String, dynamic>{'answer.txt': 'BLUEBIRD\n'},
        'expected_submit': 'BLUEBIRD',
        'required_tools': <String>['read_file', 'submit'],
      },
      'evaluation': 'submit',
      'max_turns': 10,
    });
    final sandbox = agentCase.createSandbox();
    await sandbox.call(
      const AgentToolCall(
        id: '1',
        name: 'read_file',
        arguments: <String, Object?>{'path': 'answer.txt'},
        raw: '',
      ),
    );
    await sandbox.call(
      const AgentToolCall(
        id: '2',
        name: 'submit',
        arguments: <String, Object?>{'answer': 'BLUEBIRD'},
        raw: '',
      ),
    );

    final verdict = agentCase.score(
      result: const AgentRunResult(
        status: AgentRunStatus.submitted,
        finalAnswer: 'BLUEBIRD',
        prompt: '',
        events: <AgentEvent>[],
        turns: 2,
      ),
      sandbox: sandbox,
    );

    expect(verdict.passed, isTrue);
    expect(verdict.failures, isEmpty);
  });

  test('reports missing tools and a wrong submission', () async {
    final agentCase = AgentCase.fromJson(<String, dynamic>{
      'name': 'find_read_submit',
      'title': 'Find Read Submit',
      'system': 'base',
      'prompt': 'Find the answer.',
      'tools': 'nav',
      'environment': <String, dynamic>{
        'files': <String, dynamic>{'answer.txt': 'BLUEBIRD\n'},
        'expected_submit': 'BLUEBIRD',
        'required_tools': <String>['read_file', 'submit'],
      },
      'evaluation': 'submit',
      'max_turns': 10,
    });
    final sandbox = agentCase.createSandbox();
    await sandbox.call(
      const AgentToolCall(
        id: '1',
        name: 'submit',
        arguments: <String, Object?>{'answer': 'WRONG'},
        raw: '',
      ),
    );

    final verdict = agentCase.score(
      result: const AgentRunResult(
        status: AgentRunStatus.submitted,
        finalAnswer: 'WRONG',
        prompt: '',
        events: <AgentEvent>[],
        turns: 1,
      ),
      sandbox: sandbox,
    );

    expect(verdict.passed, isFalse);
    expect(verdict.failures, contains('never called required tool read_file'));
    expect(verdict.failures, contains("submitted 'WRONG', expected 'BLUEBIRD'"));
  });

  test('rejects an unknown tool even if submission later matches', () async {
    final agentCase = AgentCase.fromJson(<String, dynamic>{
      'name': 'find_read_submit',
      'title': 'Find Read Submit',
      'system': 'base',
      'prompt': 'Find the answer.',
      'tools': 'nav',
      'environment': <String, dynamic>{
        'files': <String, dynamic>{'answer.txt': 'BLUEBIRD\n'},
        'expected_submit': 'BLUEBIRD',
      },
      'evaluation': 'submit',
      'max_turns': 10,
    });
    final sandbox = agentCase.createSandbox();
    await sandbox.call(
      const AgentToolCall(
        id: '1',
        name: 'shell',
        arguments: <String, Object?>{},
        raw: '',
      ),
    );
    await sandbox.call(
      const AgentToolCall(
        id: '2',
        name: 'submit',
        arguments: <String, Object?>{'answer': 'BLUEBIRD'},
        raw: '',
      ),
    );

    final verdict = agentCase.score(
      result: const AgentRunResult(
        status: AgentRunStatus.submitted,
        finalAnswer: 'BLUEBIRD',
        prompt: '',
        events: <AgentEvent>[],
        turns: 2,
      ),
      sandbox: sandbox,
    );

    expect(verdict.passed, isFalse);
    expect(verdict.failures, contains('called 1 unknown tool(s)'));
  });
}

abstract final class AgentSandboxCapabilityNames {
  static const Set<String> all = <String>{
    'multiply',
    'list_files',
    'read_file',
    'write_file',
    'search',
    'ls',
    'stat',
    'chmod',
    'run_file',
    'run_awk',
    'run_lua',
    'run_tests',
    'submit',
    'list_schedules',
  };
}
