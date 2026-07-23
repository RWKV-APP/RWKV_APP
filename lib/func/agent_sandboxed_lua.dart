// Dart imports:
import 'dart:async';
import 'dart:isolate';

// Package imports:
import 'package:lua_dardo_co/lua.dart';

final class AgentSandboxedLua {
  static const int maxCodeLength = 16_000;
  static const int maxFileCount = 256;
  static const int maxFileLength = 1_000_000;
  static const int maxOutputLength = 4_000;
  static const Duration defaultTimeout = Duration(seconds: 2);

  final Duration executionTimeout;

  const AgentSandboxedLua({
    this.executionTimeout = defaultTimeout,
  });

  Future<String> run({
    required String code,
    required Map<String, String> files,
  }) async {
    if (code.length > maxCodeLength) {
      return "ERROR: Lua source exceeds $maxCodeLength characters";
    }
    if (files.length > maxFileCount) {
      return "ERROR: Lua file count exceeds $maxFileCount";
    }
    for (final content in files.values) {
      if (content.length <= maxFileLength) continue;
      return "ERROR: Lua file exceeds $maxFileLength characters";
    }

    final responsePort = ReceivePort();
    Isolate? isolate;
    try {
      isolate = await Isolate.spawn<Map<String, Object?>>(
        _evaluateInIsolate,
        <String, Object?>{
          "responsePort": responsePort.sendPort,
          "code": code,
          "files": Map<String, String>.from(files),
        },
        debugName: "rwkv_agent_lua",
      );
      final response = await responsePort.first.timeout(executionTimeout);
      if (response is! Map) {
        return "ERROR: Lua runtime returned an invalid response";
      }
      final error = response["error"];
      if (error is String && error.isNotEmpty) {
        return _formatError(error);
      }
      final rawOutput = response["output"];
      if (rawOutput is! String) {
        return "ERROR: Lua runtime returned invalid output";
      }
      return _truncate(rawOutput);
    } on TimeoutException {
      return "ERROR: Lua execution timed out";
    } catch (error) {
      return _formatError("failed to run isolated Lua: $error");
    } finally {
      isolate?.kill(priority: Isolate.immediate);
      responsePort.close();
    }
  }

  String _truncate(String rawOutput) {
    final output = rawOutput.trim();
    if (output.isEmpty) return "ok: lua completed with no output";
    if (output.length <= maxOutputLength) return output;
    return "${output.substring(0, maxOutputLength)}\n... truncated ...";
  }

  String _formatError(String rawError) {
    final lines = rawError.replaceAll("\r\n", "\n").replaceAll("\r", "\n").split("\n");
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length <= 500) return "ERROR: $trimmed";
      return "ERROR: ${trimmed.substring(0, 500)} ...";
    }
    return "ERROR: Lua runtime error";
  }
}

void _evaluateInIsolate(Map<String, Object?> request) {
  final responsePort = request["responsePort"];
  if (responsePort is! SendPort) return;

  try {
    final code = request["code"];
    final rawFiles = request["files"];
    if (code is! String || rawFiles is! Map) {
      responsePort.send(<String, String>{
        "error": "Lua isolate received invalid input",
      });
      return;
    }

    final files = <String, String>{};
    for (final entry in rawFiles.entries) {
      if (entry.key is! String || entry.value is! String) continue;
      files[entry.key as String] = entry.value as String;
    }

    final output = StringBuffer();
    final state = LuaState.newState();
    state.openLibs();
    for (final name in <String>[
      "debug",
      "dofile",
      "io",
      "loadfile",
      "os",
      "package",
      "require",
    ]) {
      state.pushNil();
      state.setGlobal(name);
    }
    state.pushDartFunction((luaState) {
      final values = <String>[];
      final count = luaState.getTop();
      for (int index = 1; index <= count; index += 1) {
        values.add(luaState.toString2(index) ?? "");
      }
      output.writeln(values.join("\t"));
      return 0;
    });
    state.setGlobal("print");

    state.pushDartFunction((luaState) {
      final path = luaState.toString2(1);
      final content = path == null ? null : files[path];
      if (content == null) {
        luaState.pushNil();
        return 1;
      }
      luaState.pushString(content);
      return 1;
    });
    state.setGlobal("read_file");

    state.newTable();
    for (final entry in files.entries) {
      state.pushString(entry.value);
      state.setField(-2, entry.key);
    }
    state.setGlobal("FILES");

    final helperLoadStatus = state.loadString(
      r'''
function string.lines(value)
  return string.gmatch(value, "[^\r\n]+")
end
''',
    );
    if (helperLoadStatus != ThreadStatus.luaOk) {
      responsePort.send(<String, String>{
        "error": state.toStr(-1) ?? "Lua helper syntax error",
      });
      return;
    }
    final helperCallStatus = state.pCall(0, 0, 0);
    if (helperCallStatus != ThreadStatus.luaOk) {
      responsePort.send(<String, String>{
        "error": state.toStr(-1) ?? "Lua helper runtime error",
      });
      return;
    }

    final loadStatus = state.loadString(code);
    if (loadStatus != ThreadStatus.luaOk) {
      responsePort.send(<String, String>{
        "error": state.toStr(-1) ?? "Lua syntax error",
      });
      return;
    }
    final callStatus = state.pCall(0, luaMultret, 0);
    if (callStatus != ThreadStatus.luaOk) {
      responsePort.send(<String, String>{
        "error": state.toStr(-1) ?? "Lua runtime error",
      });
      return;
    }
    if (state.getTop() > 0) {
      final result = state.toString2(1);
      state.pop(1);
      if (result != null) {
        if (output.isNotEmpty && !output.toString().endsWith("\n")) {
          output.writeln();
        }
        output.write(result);
      }
    }
    responsePort.send(<String, String>{
      "output": output.toString(),
    });
  } catch (error) {
    responsePort.send(<String, String>{
      "error": error.toString(),
    });
  }
}
