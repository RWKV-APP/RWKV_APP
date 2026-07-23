// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/func/agent_sandbox.dart';
import 'package:zone/func/agent_sandboxed_lua.dart';
import 'package:zone/model/agent.dart';

void main() {
  group('AgentSandbox paths', () {
    test('normalizes safe relative paths', () {
      expect(AgentSandbox.normalizePath('./src//main.dart'), 'src/main.dart');
      expect(AgentSandbox.normalizePath('.'), '.');
    });

    test('rejects paths that can escape the sandbox', () {
      expect(() => AgentSandbox.normalizePath('/etc/passwd'), throwsFormatException);
      expect(() => AgentSandbox.normalizePath('../secret'), throwsFormatException);
      expect(() => AgentSandbox.normalizePath(r'C:\Users\secret'), throwsFormatException);
      expect(() => AgentSandbox.normalizePath('safe/\u0000bad'), throwsFormatException);
    });
  });

  group('AgentSandbox tools', () {
    test('implements every advertised Primitive Bench capability', () {
      final sandbox = AgentSandbox(files: const <String, String>{});

      expect(
        sandbox.tools.map((tool) => tool.name).toSet(),
        AgentSandbox.allToolNames.toSet(),
      );
    });

    test('validates arguments before invoking a tool', () async {
      final sandbox = AgentSandbox(
        files: const <String, String>{},
        toolNames: const <String>['list_schedules'],
      );

      final result = await _call(
        sandbox,
        'list_schedules',
        <String, Object?>{'state': 'deleted'},
      );

      expect(result.isError, isTrue);
      expect(result.content, contains('pending, done, all'));
    });

    test('reads, writes, searches, lists, stats, and changes emulated files', () async {
      final sandbox = AgentSandbox(
        files: const <String, String>{
          'src/a.txt': 'alpha\nbeta\n',
        },
      );

      expect((await _call(sandbox, 'list_files', <String, Object?>{'path': '.'})).content, 'src/a.txt');
      expect((await _call(sandbox, 'read_file', <String, Object?>{'path': 'src/a.txt'})).content, '1: alpha\n2: beta');
      expect((await _call(sandbox, 'search', <String, Object?>{'query': 'BETA'})).content, 'src/a.txt:2: beta');
      expect((await _call(sandbox, 'stat', <String, Object?>{'path': 'src/a.txt'})).content, contains('mode: rw-'));

      final writeResult = await _call(
        sandbox,
        'write_file',
        <String, Object?>{'path': 'src/b.txt', 'content': 'created'},
      );
      expect(writeResult.isError, isFalse);
      expect(sandbox.files['src/b.txt'], 'created');

      expect(
        (await _call(sandbox, 'chmod', <String, Object?>{'path': 'src/b.txt', 'mode': '+x'})).content,
        'ok: mode rwx src/b.txt',
      );
      expect((await _call(sandbox, 'ls', <String, Object?>{'path': 'src'})).content, contains('rwx src/b.txt'));
    });

    test('never reads or writes a host path', () async {
      final sandbox = AgentSandbox(files: const <String, String>{});

      final readResult = await _call(
        sandbox,
        'read_file',
        <String, Object?>{'path': '/etc/passwd'},
      );
      final writeResult = await _call(
        sandbox,
        'write_file',
        <String, Object?>{'path': '../outside', 'content': 'bad'},
      );

      expect(readResult.isError, isTrue);
      expect(readResult.content, contains('absolute paths are not allowed'));
      expect(writeResult.isError, isTrue);
      expect(writeResult.content, contains('.. path segments are not allowed'));
    });

    test('bounds tool output returned to the model', () async {
      final sandbox = AgentSandbox(
        files: <String, String>{
          'large.txt': List<String>.filled(40_000, 'x').join(),
        },
      );

      final result = await _call(
        sandbox,
        'read_file',
        <String, Object?>{'path': 'large.txt'},
      );

      expect(
        result.content.length,
        lessThanOrEqualTo(
          AgentSandbox.maxToolResultLength + '\n... truncated by sandbox ...'.length,
        ),
      );
      expect(result.content, endsWith('... truncated by sandbox ...'));
    });

    test('simulates permission repair and configured execution', () async {
      final sandbox = AgentSandbox(
        files: const <String, String>{'tool.py': 'print("LAUNCHED")'},
        runOutputs: const <String, String>{'tool.py': 'LAUNCHED'},
        toolNames: const <String>['run_file', 'chmod'],
      );

      expect(
        (await _call(sandbox, 'run_file', <String, Object?>{'path': 'tool.py'})).content,
        contains('permission denied'),
      );
      await _call(sandbox, 'chmod', <String, Object?>{'path': 'tool.py', 'mode': '755'});
      expect(
        (await _call(sandbox, 'run_file', <String, Object?>{'path': 'tool.py'})).content,
        'LAUNCHED',
      );
    });

    test('runs deterministic tests without invoking the host', () async {
      final sandbox = AgentSandbox(
        files: const <String, String>{'app.conf': 'mode = development\n'},
        scenario: 'patch_config',
        toolNames: const <String>['write_file', 'run_tests'],
      );

      expect((await _call(sandbox, 'run_tests', const <String, Object?>{})).content, startsWith('FAIL'));
      await _call(
        sandbox,
        'write_file',
        <String, Object?>{'path': 'app.conf', 'content': 'mode = production\n'},
      );
      expect((await _call(sandbox, 'run_tests', const <String, Object?>{})).content, startsWith('PASS'));
      expect(sandbox.testsPassed, isTrue);
    });
  });

  group('AgentSandboxedLua', () {
    const lua = AgentSandboxedLua();

    test('calculates with in-memory files', () async {
      final output = await lua.run(
        code: "local n = tonumber(FILES['number.txt']); print(n * 3)",
        files: const <String, String>{'number.txt': '14'},
      );

      expect(output, '42');
    });

    test('captures every print argument', () async {
      final output = await lua.run(
        code: "print('orders', 3, 'total')",
        files: const <String, String>{},
      );

      expect(output, 'orders\t3\ttotal');
    });

    test('supports Lua 5.3 string patterns and table library', () async {
      final output = await lua.run(
        code: """
local values = {}
for number in string.gmatch(FILES['numbers.csv'], '%d+') do
  table.insert(values, tonumber(number))
end
table.sort(values)
print(table.concat(values, ','))
""",
        files: const <String, String>{'numbers.csv': '9,2,14'},
      );

      expect(output, '2,9,14');
    });

    test('exposes only in-memory file helpers to Lua', () async {
      final output = await lua.run(
        code: """
local direct = read_file('data.txt')
local rows = {}
for line in FILES['data.txt']:lines() do
  table.insert(rows, line)
end
print(direct)
print(#rows)
""",
        files: const <String, String>{'data.txt': 'alpha\nbeta'},
      );

      expect(output, 'alpha\nbeta\n2');
    });

    test('does not expose host APIs', () async {
      final osOutput = await lua.run(
        code: "return type(os)",
        files: const <String, String>{},
      );
      final ioOutput = await lua.run(
        code: "return type(io)",
        files: const <String, String>{},
      );
      final packageOutput = await lua.run(
        code: "return type(package)",
        files: const <String, String>{},
      );
      final fileOutput = await lua.run(
        code: "return type(loadfile) .. ',' .. type(dofile) .. ',' .. type(require)",
        files: const <String, String>{},
      );

      expect(osOutput, 'nil');
      expect(ioOutput, 'nil');
      expect(packageOutput, 'nil');
      expect(fileOutput, 'nil,nil,nil');
    });

    test('terminates an infinite program outside the app isolate', () async {
      const shortLua = AgentSandboxedLua(
        executionTimeout: Duration(milliseconds: 100),
      );
      final output = await shortLua.run(
        code: "while true do end",
        files: const <String, String>{},
      );

      expect(output, 'ERROR: Lua execution timed out');
    });
  });
}

Future<AgentToolResult> _call(
  AgentSandbox sandbox,
  String name,
  AgentJson arguments,
) {
  return sandbox.call(
    AgentToolCall(
      id: 'test',
      name: name,
      arguments: arguments,
      raw: '',
    ),
  );
}
