// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/func/agent_runtime.dart';
import 'package:zone/func/agent_sandbox.dart';
import 'package:zone/func/g1h_agent_protocol.dart';
import 'package:zone/model/agent.dart';

void main() {
  group('G1hAgentProtocol', () {
    const protocol = G1hAgentProtocol();

    test('builds the G1h tool prompt', () {
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>["multiply"],
      );

      final prompt = protocol.buildPrompt(
        system: 'Use tools when useful.',
        user: 'What is 2 times 3?',
        tools: sandbox.tools,
      );

      expect(prompt, startsWith('<s>System: Use tools when useful.'));
      expect(prompt, contains('<tools>'));
      expect(prompt, contains('"name":"multiply"'));
      expect(prompt, contains('<tool_call>'));
      expect(prompt, endsWith('Assistant: <think>'));
    });

    test('parses a complete tool call after thinking', () {
      final output = protocol.parse(
        '<think>I should calculate.</think>\n'
        '<tool_call>\n'
        '{"name":"multiply","arguments":{"a":2,"b":3}}\n'
        '</tool_call>',
        callOrdinal: 4,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.id, 'call_4');
      expect(output.toolCall?.name, 'multiply');
      expect(output.toolCall?.arguments, <String, Object?>{'a': 2, 'b': 3});
    });

    test('extracts fenced JSON and ignores trailing text', () {
      final output = protocol.parse(
        '<tool_call>\n```json\n'
        '{"name":"read_file","arguments":{"path":"a{b}.txt"}}\n'
        '```\nThis text is outside the call.</tool_call>',
        callOrdinal: 2,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.name, 'read_file');
      expect(
        output.toolCall?.arguments,
        <String, Object?>{'path': 'a{b}.txt'},
      );
    });

    test('repairs multiline code and inner quotes in tool JSON', () {
      final output = protocol.parse(
        '''
<tool_call>
{"name":"write_file","arguments":{"path":"app.py","content":"def run():
    print("READY")
"}}
</tool_call>
''',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.name, 'write_file');
      expect(
        output.toolCall?.arguments["content"],
        'def run():\n    print("READY")\n',
      );
    });

    test('repairs trailing commas in tool JSON', () {
      final output = protocol.parse(
        '<tool_call>'
        '{"name":"read_file","arguments":{"path":"a.txt",},}'
        '</tool_call>',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.arguments, <String, Object?>{'path': 'a.txt'});
    });

    test('strict mode rejects JSON that assisted mode repairs', () {
      const raw = '<tool_call>{"name":"read_file","arguments":{"path":"a.txt",},}</tool_call>';

      final strict = protocol.parse(
        raw,
        callOrdinal: 1,
        mode: .strict,
      );
      final assisted = protocol.parse(
        raw,
        callOrdinal: 1,
        mode: .assisted,
      );

      expect(strict.kind, G1hAgentOutputKind.malformedToolCall);
      expect(assisted.kind, G1hAgentOutputKind.toolCall);
      expect(
        assisted.toolCall?.interventions,
        contains(AgentInterventionKind.jsonRepair),
      );
    });

    test('strict mode rejects non-canonical tool envelopes', () {
      const raw = '<tool_call>{"read_file":{"path":"answer.txt"}}</tool_call>';

      final strict = protocol.parse(
        raw,
        callOrdinal: 1,
        mode: .strict,
      );
      final assisted = protocol.parse(
        raw,
        callOrdinal: 1,
        mode: .assisted,
      );

      expect(strict.kind, G1hAgentOutputKind.malformedToolCall);
      expect(assisted.kind, G1hAgentOutputKind.toolCall);
      expect(
        assisted.toolCall?.interventions,
        contains(AgentInterventionKind.envelopeNormalization),
      );
    });

    test('completes containers when the model closed the tool envelope', () {
      final output = protocol.parse(
        '''
<tool_call>
{"name":"write_file","arguments":{"path":"app.py","content":"def run():
    print(\\"READY\\")
</tool_call>
''',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.name, 'write_file');
      expect(
        output.toolCall?.arguments["content"],
        'def run():\n    print("READY")',
      );
    });

    test('repairs unescaped quotes inside multiline script content', () {
      final output = protocol.parse(
        '''
<tool_call>
{"name":"write_file","arguments":{"path":"align.awk","content":"NR==1{printf \\"%-10s\\", \$1; print ""}
NR>1{printf "%-10s", \$1; print ""}"}}
</tool_call>
''',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.name, 'write_file');
      expect(
        output.toolCall?.arguments["content"],
        'NR==1{printf "%-10s", \$1; print ""}\n'
        'NR>1{printf "%-10s", \$1; print ""}',
      );
    });

    test('normalizes a single-key tool object', () {
      final output = protocol.parse(
        '<tool_call>{"read_file":{"path":"settings.txt"}}</tool_call>',
        callOrdinal: 3,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.id, 'call_3');
      expect(output.toolCall?.name, 'read_file');
      expect(
        output.toolCall?.arguments,
        <String, Object?>{'path': 'settings.txt'},
      );
    });

    test('normalizes a tool name followed by an arguments object', () {
      final output = protocol.parse(
        '<tool_call>list_files\n{"path":"."}</tool_call>',
        callOrdinal: 2,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.id, 'call_2');
      expect(output.toolCall?.name, 'list_files');
      expect(
        output.toolCall?.arguments,
        <String, Object?>{'path': '.'},
      );
    });

    test('completes a tool object before a hallucinated foreign boundary', () {
      final output = protocol.parse(
        '<tool_call>'
        '{"name":"run_lua","arguments":{"code":"print(42)"}'
        '\n</tool_response>\n\nUser:',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.toolCall);
      expect(output.toolCall?.name, 'run_lua');
      expect(
        output.toolCall?.arguments,
        <String, Object?>{'code': 'print(42)'},
      );
    });

    test('keeps a partial JSON object open for continuation', () {
      final output = protocol.parse(
        '<tool_call>{"name":"read_file","arguments":{"path":"answer',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.incompleteToolCall);
    });

    test('identifies an incomplete tool call', () {
      final output = protocol.parse(
        '<think>Need a tool.</think><tool_call>',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.incompleteToolCall);
    });

    test('extracts the final answer after thinking', () {
      final output = protocol.parse(
        '<think>Done.</think>\nThe answer is 6.<EOD>',
        callOrdinal: 1,
      );

      expect(output.kind, G1hAgentOutputKind.finalAnswer);
      expect(output.finalAnswer, 'The answer is 6.');
    });

    test('truncates a repeated think-close cycle after the first answer', () {
      const output = "\ncalculated\n</think>\n1887357\n</think>\n1887357";

      expect(
        protocol.truncateAtRepeatedThinkClose(output),
        "\ncalculated\n</think>\n1887357",
      );
    });

    test('truncates three long repeated text spans', () {
      final block = List<String>.filled(
        5,
        "I should inspect the available files before choosing the answer. ",
      ).join();
      final repeated = List<String>.filled(
        3,
        block,
      ).join();

      final truncated = protocol.truncateAtRepeatedText(repeated);

      expect(truncated, isNotNull);
      expect(truncated!.length, lessThan(repeated.length));
      expect(truncated, contains("inspect the available files"));
    });

    test('keeps ordinary long output unchanged', () {
      final output = List<String>.generate(
        40,
        (index) => "Distinct reasoning line $index with enough detail.\n",
      ).join();

      expect(protocol.truncateAtRepeatedText(output), isNull);
    });
  });

  group('AgentRuntime', () {
    test('runs tool calls until a final answer', () async {
      final model = _ScriptedAgentModel(<String>[
        '<think>Calculate.</think><tool_call>'
            '{"name":"multiply","arguments":{"a":4827,"b":391}}'
            '</tool_call>',
        '<think>The tool returned the result.</think>1887357',
      ]);
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>["multiply"],
      );
      final runtime = AgentRuntime(
        model: model,
        toolHost: sandbox,
        mode: .assisted,
      );

      final result = await runtime.run(
        system: 'Use tools.',
        user: 'What is 4827 times 391?',
      );

      expect(result.status, AgentRunStatus.completed);
      expect(result.finalAnswer, '1887357');
      expect(sandbox.usedTools, <String>['multiply']);
      expect(model.prompts.last, contains('<tool_response>\n1887357\n</tool_response>'));
      expect(result.events.map((event) => event.kind), containsAll(<AgentEventKind>[.toolCall, .toolResult, .finalAnswer]));
    });

    test('continues an opening-only tool call', () async {
      final model = _ScriptedAgentModel(<String>[
        '<think>Inspect.</think><tool_call>',
        '{"name":"list_files","arguments":{"path":"."}}</tool_call>',
        '<think>Found it.</think>done',
      ]);
      final sandbox = AgentSandbox(
        files: const <String, String>{'answer.txt': 'BLUEBIRD'},
        toolNames: const <String>["list_files"],
      );
      final runtime = AgentRuntime(model: model, toolHost: sandbox);

      final result = await runtime.run(
        system: 'Use tools.',
        user: 'Inspect files.',
      );

      expect(result.status, AgentRunStatus.completed);
      expect(result.finalAnswer, 'done');
      expect(model.prompts[1], endsWith('<tool_call>'));
      expect(model.prompts[2], contains('<tool_response>\nanswer.txt\n</tool_response>'));
    });

    test('ends immediately after submit', () async {
      final model = _ScriptedAgentModel(<String>[
        '<tool_call>{"name":"submit","arguments":{"answer":"BLUEBIRD"}}</tool_call>',
      ]);
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>["submit"],
      );
      final runtime = AgentRuntime(model: model, toolHost: sandbox);

      final result = await runtime.run(
        system: 'Submit the answer.',
        user: 'Submit BLUEBIRD.',
      );

      expect(result.status, AgentRunStatus.submitted);
      expect(result.finalAnswer, 'BLUEBIRD');
      expect(sandbox.submitted, 'BLUEBIRD');
    });

    test('normalizes arguments against the advertised tool schema', () async {
      final model = _ScriptedAgentModel(<String>[
        '<tool_call>{"name":"run_tests","arguments":{"path":"test.py"}}</tool_call>',
        '<tool_call>{"name":"submit","arguments":{"answer":"tests passed","extra":true}}</tool_call>',
      ]);
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>["run_tests", "submit"],
      );
      final runtime = AgentRuntime(
        model: model,
        toolHost: sandbox,
        mode: .assisted,
      );

      final result = await runtime.run(
        system: 'Run tests.',
        user: 'Submit after tests.',
      );

      expect(result.status, AgentRunStatus.submitted);
      expect(result.finalAnswer, 'tests passed');
      final calls = result.events.where((event) => event.kind == .toolCall).map((event) => event.toolCall).toList();
      expect(calls.first?.arguments, isEmpty);
      expect(calls.last?.arguments, <String, Object?>{'answer': 'tests passed'});
    });

    test('recovers from a tool call that stays incomplete', () async {
      final model = _ScriptedAgentModel(<String>[
        '<think>Inspect.</think><tool_call>',
        '{"name":"read_file","arguments":{"path":"answer',
        '<tool_call>{"name":"read_file","arguments":{"path":"answer.txt"}}</tool_call>',
        '<think>Done.</think>BLUEBIRD',
      ]);
      final sandbox = AgentSandbox(
        files: const <String, String>{'answer.txt': 'BLUEBIRD'},
        toolNames: const <String>["read_file"],
      );
      final runtime = AgentRuntime(model: model, toolHost: sandbox);

      final result = await runtime.run(
        system: 'Inspect.',
        user: 'Read the answer.',
      );

      expect(result.status, AgentRunStatus.completed);
      expect(result.finalAnswer, 'BLUEBIRD');
      expect(
        result.events.map((event) => event.title),
        contains('Incomplete tool call'),
      );
    });

    test('adds schema guidance after argument validation errors', () async {
      final model = _ScriptedAgentModel(<String>[
        '<tool_call>{"name":"run_awk","arguments":{"script_path":"align.awk"}}</tool_call>',
        '<think>Cannot continue.</think>stopped',
      ]);
      final sandbox = AgentSandbox(
        files: const <String, String>{
          'align.awk': '{ print }',
          'data.tsv': 'name\tqty',
        },
        toolNames: const <String>["run_awk"],
      );
      final runtime = AgentRuntime(model: model, toolHost: sandbox);

      await runtime.run(
        system: 'Use tools.',
        user: 'Run the script.',
      );

      expect(model.prompts.last, contains('Correct argument schema:'));
      expect(model.prompts.last, contains('"input_path"'));
    });

    test('stops repeated identical calls', () async {
      final model = _ScriptedAgentModel(
        <String>[
          '<tool_call>{"name":"list_files","arguments":{"path":"."}}</tool_call>',
          '<tool_call> { "name": "list_files", "arguments": { "path": "." } } </tool_call>',
          '<tool_call>{"name":"list_files","arguments":{"path":"."}}</tool_call>',
        ],
      );
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>["list_files"],
      );
      final runtime = AgentRuntime(
        model: model,
        toolHost: sandbox,
        maxRepeatedCalls: 2,
      );

      final result = await runtime.run(
        system: 'Use tools.',
        user: 'Loop.',
      );

      expect(result.status, AgentRunStatus.failed);
      expect(result.events.last.title, 'Repeated tool call');
    });

    test('reports cancellation without a model error event', () async {
      bool cancelled = false;
      final model = _ThrowingAgentModel(
        onGenerate: () {
          cancelled = true;
        },
      );
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>["list_files"],
      );
      final runtime = AgentRuntime(model: model, toolHost: sandbox);

      final result = await runtime.run(
        system: 'Use tools.',
        user: 'Inspect.',
        isCancelled: () => cancelled,
      );

      expect(result.status, AgentRunStatus.cancelled);
      expect(result.events, isEmpty);
    });

    test('marks infrastructure failures invalid for model scoring', () async {
      const model = _InfrastructureAgentModel();
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>["submit"],
      );
      final runtime = AgentRuntime(model: model, toolHost: sandbox);

      final result = await runtime.run(
        system: 'Submit the answer.',
        user: 'Submit BLUEBIRD.',
      );

      expect(result.status, AgentRunStatus.infrastructureFailed);
      expect(result.validForModelScore, isFalse);
      expect(result.events.single.title, 'Infrastructure error');
    });
  });
}

final class _ScriptedAgentModel implements AgentModel {
  final List<String> outputs;
  final List<String> prompts = <String>[];
  int _index = 0;

  _ScriptedAgentModel(this.outputs);

  @override
  Future<AgentGeneration> generate(
    String prompt, {
    required AgentEvaluationMode mode,
  }) async {
    prompts.add(prompt);
    if (_index >= outputs.length) {
      throw StateError('No scripted output for call ${_index + 1}');
    }
    final result = outputs[_index];
    _index += 1;
    return AgentGeneration.raw(result);
  }
}

final class _ThrowingAgentModel implements AgentModel {
  final void Function() onGenerate;

  const _ThrowingAgentModel({
    required this.onGenerate,
  });

  @override
  Future<AgentGeneration> generate(
    String prompt, {
    required AgentEvaluationMode mode,
  }) async {
    final _ = prompt;
    onGenerate();
    throw StateError('Generation stopped');
  }
}

final class _InfrastructureAgentModel implements AgentModel {
  const _InfrastructureAgentModel();

  @override
  Future<AgentGeneration> generate(
    String prompt, {
    required AgentEvaluationMode mode,
  }) async {
    throw const AgentInfrastructureException(
      code: 'backend_status_timeout',
      message: 'test timeout',
    );
  }
}
