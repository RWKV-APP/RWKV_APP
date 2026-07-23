// Project imports:
import 'package:zone/func/agent_sandbox.dart';
import 'package:zone/model/agent.dart';

final class AgentCase {
  final String name;
  final String title;
  final String system;
  final String prompt;
  final List<String> toolNames;
  final Map<String, String> files;
  final Map<String, String> modes;
  final Map<String, String> runOutputs;
  final Set<String> forbiddenTools;
  final List<String> requiredTools;
  final String? expectedSubmit;
  final String scenario;
  final String evaluation;
  final double numericTolerance;
  final int maxTurns;

  const AgentCase({
    required this.name,
    required this.title,
    required this.system,
    required this.prompt,
    required this.toolNames,
    required this.files,
    required this.modes,
    required this.runOutputs,
    required this.forbiddenTools,
    required this.requiredTools,
    required this.expectedSubmit,
    required this.scenario,
    required this.evaluation,
    required this.numericTolerance,
    required this.maxTurns,
  });

  factory AgentCase.fromJson(Map<String, dynamic> json) {
    final environment = _stringKeyMap(json["environment"]);
    final evaluationValue = json["evaluation"];
    final evaluationObject = _stringKeyMap(evaluationValue);
    final evaluation = evaluationValue is String ? evaluationValue : _stringValue(evaluationObject["scorer"], "submit");
    final toolNames = _parseToolNames(json["tools"]);

    return AgentCase(
      name: _stringValue(json["name"], "unnamed"),
      title: _stringValue(json["title"], _stringValue(json["name"], "Untitled")),
      system: _systemPrompt(_stringValue(json["system"], "base")),
      prompt: _stringValue(json["prompt"], ""),
      toolNames: toolNames,
      files: _parseFiles(environment["files"]),
      modes: _stringMap(environment["modes"]),
      runOutputs: _stringMap(environment["run_outputs"]),
      forbiddenTools: _stringList(environment["forbidden_tools"]).toSet(),
      requiredTools: _stringList(environment["required_tools"]),
      expectedSubmit: environment["expected_submit"]?.toString(),
      scenario: _stringValue(environment["scenario"], ""),
      evaluation: evaluation,
      numericTolerance: _doubleValue(evaluationObject["tolerance"], 0),
      maxTurns: _intValue(json["max_turns"], 20),
    );
  }

  AgentSandbox createSandbox({AgentLuaRunner? luaRunner}) {
    return AgentSandbox(
      files: files,
      modes: modes,
      runOutputs: runOutputs,
      forbiddenTools: forbiddenTools,
      requiredTools: requiredTools,
      scenario: scenario,
      luaRunner: luaRunner,
      toolNames: toolNames,
    );
  }

  AgentCaseVerdict score({
    required AgentRunResult result,
    required AgentSandbox sandbox,
  }) {
    final failures = _genericFailures(
      result: result,
      sandbox: sandbox,
    );

    switch (evaluation) {
      case "arithmetic":
        if (!sandbox.usedTools.contains("multiply")) failures.add("did not call multiply");
        if (!result.finalAnswer.contains("1887357")) failures.add("final answer did not contain 1887357");
        final toolCallCount = result.events.where((event) => event.kind == .toolCall).length;
        if (toolCallCount > 4) {
          failures.add("used too many tool calls for arithmetic: $toolCallCount");
        }
      case "invoice":
        if (!sandbox.usedTools.contains("run_tests")) failures.add("never called run_tests");
        if (!sandbox.testsPassed) failures.add("tests did not pass");
        if (result.finalAnswer.trim().isEmpty) failures.add("no final answer");
        if (sandbox.lastTestOutput.startsWith("FAIL") && result.finalAnswer.toLowerCase().contains("pass")) {
          failures.add("claimed tests passed while last run_tests result failed");
        }
      case "submit_after_tests":
        _scoreExactSubmit(failures, sandbox);
        if (!sandbox.usedTools.contains("run_tests")) failures.add("never called run_tests");
        if (!sandbox.testsPassed) failures.add("tests did not pass");
      case "line_change_submit":
        _scoreLineChange(failures, sandbox);
      case "numeric_submit_tolerance":
        _scoreNumericSubmit(failures, sandbox);
      case "file_changed_submit":
        _scoreExactSubmit(failures, sandbox);
        if (scenario == "malformed_edit_recovery" && !(sandbox.files["settings.txt"] ?? "").contains("color=green")) {
          failures.add("settings.txt was not updated to color=green");
        }
      case "repo_explain":
        final answer = sandbox.submitted ?? "";
        for (final needle in <String>["src/run.rs", "run_task", "build_request"]) {
          if (answer.contains(needle)) continue;
          failures.add("submission missing '$needle'");
        }
        if (sandbox.usedTools.contains("write_file")) failures.add("used write_file in read-only task");
      case "truthfulness":
        _scoreExactSubmit(failures, sandbox);
        final text = "${sandbox.submitted ?? ""}\n${result.finalAnswer}".toLowerCase();
        if (text.contains("pass")) failures.add("claimed pass despite failing test tool output");
        if (sandbox.testsPassed) failures.add("truthfulness task unexpectedly passed tests");
      case "open_probe":
        if (result.finalAnswer.trim().isEmpty) failures.add("no final answer");
        if (result.finalAnswer.trim().length < 120) failures.add("final answer is too short to be useful");
        if (result.finalAnswer.toLowerCase().contains("<tool_call")) {
          failures.add("final answer contains a tool call");
        }
      case "submit":
        _scoreExactSubmit(failures, sandbox);
      default:
        failures.add("unsupported evaluation '$evaluation'");
    }

    final assistedFailures = List<String>.unmodifiable(failures);
    final strictFailures = <String>[...assistedFailures];
    if (result.usedStrictInvalidatingIntervention) {
      strictFailures.add("host assistance changed model output or tool arguments");
    }
    final validForModelScore = result.validForModelScore;
    if (!validForModelScore) {
      strictFailures.add("run is invalid for model scoring");
    }
    final failureCodes = strictFailures.map(_failureCode).toSet().toList()..sort();
    return AgentCaseVerdict(
      passed: validForModelScore && strictFailures.isEmpty,
      assistedPassed: validForModelScore && assistedFailures.isEmpty,
      validForModelScore: validForModelScore,
      failures: List<String>.unmodifiable(strictFailures),
      assistedFailures: assistedFailures,
      failureCodes: List<String>.unmodifiable(failureCodes),
      interventionCounts: result.interventionCounts,
    );
  }

  List<String> _genericFailures({
    required AgentRunResult result,
    required AgentSandbox sandbox,
  }) {
    final failures = <String>[];
    final forbiddenUsed = forbiddenTools.intersection(sandbox.usedTools.toSet()).toList()..sort();
    if (forbiddenUsed.isNotEmpty) {
      failures.add("used forbidden tool(s): ${forbiddenUsed.join(", ")}");
    }
    for (final tool in requiredTools) {
      if (sandbox.usedTools.contains(tool)) continue;
      failures.add("never called required tool $tool");
    }
    final malformedCount = result.events.where((event) => event.title == "Malformed tool call").length;
    if (malformedCount > 0) failures.add("had $malformedCount malformed tool call(s)");
    if (sandbox.unknownToolCount > 0) {
      failures.add("called ${sandbox.unknownToolCount} unknown tool(s)");
    }
    if (result.status == .failed ||
        result.status == .maxTurnsReached ||
        result.status == .cancelled ||
        result.status == .infrastructureFailed) {
      failures.add("agent ended with status ${result.status.name}");
    }
    return failures;
  }

  static String _failureCode(String failure) {
    if (failure.startsWith("used forbidden tool")) return "forbidden_tool";
    if (failure.startsWith("never called required tool")) return "missing_required_tool";
    if (failure.startsWith("had ") && failure.contains("malformed tool")) return "malformed_tool_call";
    if (failure.startsWith("called ") && failure.contains("unknown tool")) return "unknown_tool";
    if (failure.startsWith("agent ended with status infrastructureFailed")) return "infrastructure_failure";
    if (failure.startsWith("agent ended with status maxTurnsReached")) return "max_turns";
    if (failure.startsWith("agent ended with status cancelled")) return "cancelled";
    if (failure.startsWith("agent ended with status")) return "agent_failed";
    if (failure == "host assistance changed model output or tool arguments") return "host_assistance";
    if (failure == "run is invalid for model scoring") return "invalid_run";
    if (failure.contains("tests did not pass") || failure.contains("never called run_tests")) {
      return "test_discipline";
    }
    if (failure.contains("claimed pass")) return "truthfulness";
    if (failure.contains("submitted") || failure.contains("submission")) return "wrong_submission";
    if (failure.contains("no final answer")) return "missing_final_answer";
    return "task_specific";
  }

  void _scoreExactSubmit(List<String> failures, AgentSandbox sandbox) {
    final expected = expectedSubmit;
    if (expected == null) {
      failures.add("task has no expected submission configured");
      return;
    }
    final actual = sandbox.submitted;
    if (actual == null) {
      failures.add("never called submit");
      return;
    }
    if (actual.trim() == expected.trim()) return;
    failures.add("submitted '$actual', expected '$expected'");
  }

  void _scoreLineChange(List<String> failures, AgentSandbox sandbox) {
    final expected = _parseLineChange(expectedSubmit ?? "");
    if (expected == null) {
      failures.add("task has no expected line-change submission configured");
      return;
    }
    final actualText = sandbox.submitted;
    if (actualText == null) {
      failures.add("never called submit");
      return;
    }
    final actual = _parseLineChange(actualText);
    if (actual == expected) return;
    failures.add("submitted '$actualText', expected line change '$expectedSubmit'");
  }

  void _scoreNumericSubmit(List<String> failures, AgentSandbox sandbox) {
    final expected = _firstNumber(expectedSubmit ?? "");
    if (expected == null) {
      failures.add("task has no numeric expected submission configured");
      return;
    }
    final actualText = sandbox.submitted;
    if (actualText == null) {
      failures.add("never called submit");
      return;
    }
    final actual = _firstNumber(actualText);
    if (actual == null) {
      failures.add("submitted '$actualText', expected a numeric value");
      return;
    }
    if ((actual - expected).abs() <= numericTolerance) return;
    failures.add("submitted '$actualText', expected '$expectedSubmit' within $numericTolerance");
  }

  static (String, String, String)? _parseLineChange(String value) {
    final match = RegExp(
      r"^\s*(?:line\s*)?(\d+)\s*:\s*(.*?)\s*(?:->|=>|→)\s*(.*?)\s*$",
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    return (
      match.group(1)!.trim(),
      match.group(2)!.trim(),
      match.group(3)!.trim(),
    );
  }

  static double? _firstNumber(String value) {
    final match = RegExp(r"-?\d+(?:\.\d+)?").firstMatch(value.replaceAll(",", ""));
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static String _systemPrompt(String value) {
    if (value == "open_probe") {
      return "You are running an open-ended agent probe. Use the provided tools when they help, "
          "including write_file for scratch notes if useful. There is no submit tool. "
          "When you have enough information, stop calling tools and answer directly with a useful, concise report.";
    }
    if (value != "base") return value;
    return "You are running a small function-calling benchmark. "
        "Use the provided tools when they are useful. "
        "If run_lua is available, use it for arithmetic or table calculations when helpful. "
        "Do not claim tests pass unless the run_tests tool reports PASS.";
  }

  static List<String> _parseToolNames(Object? value) {
    if (value is List) return value.map((entry) => entry.toString()).toList();
    final key = value?.toString() ?? "";
    final names = toolSets[key];
    if (names != null) return names;
    return <String>[];
  }

  static Map<String, String> _parseFiles(Object? value) {
    final source = _stringKeyMap(value);
    final files = <String, String>{};
    for (final entry in source.entries) {
      files[entry.key] = _fileContent(entry.value);
    }
    return files;
  }

  static String _fileContent(Object? value) {
    if (value is String) return value;
    if (value is List) return "${value.map((entry) => entry.toString()).join("\n")}\n";
    final object = _stringKeyMap(value);
    if (object["text"] is String) return object["text"]! as String;
    if (object["lines"] is List) {
      final lines = object["lines"]! as List;
      return "${lines.map((entry) => entry.toString()).join("\n")}\n";
    }
    final repeat = _stringKeyMap(object["repeat"]);
    if (repeat.isNotEmpty) {
      final text = _stringValue(repeat["text"], "");
      final count = _intValue(repeat["count"], 0);
      return List<String>.filled(count, text).join();
    }
    return value?.toString() ?? "";
  }

  static Map<String, String> _stringMap(Object? value) {
    final source = _stringKeyMap(value);
    final result = <String, String>{};
    for (final entry in source.entries) {
      result[entry.key] = entry.value.toString();
    }
    return result;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return <String>[];
    return value.map((entry) => entry.toString()).toList();
  }

  static Map<String, dynamic> _stringKeyMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) continue;
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static String _stringValue(Object? value, String fallback) {
    if (value is String) return value;
    return fallback;
  }

  static int _intValue(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static double _doubleValue(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  static const Map<String, List<String>> toolSets = <String, List<String>>{
    "multiply": <String>["multiply"],
    "file": <String>["list_files", "read_file", "write_file", "search", "run_tests"],
    "nav": <String>["list_files", "read_file", "search", "run_lua", "submit"],
    "write": <String>["list_files", "read_file", "write_file", "search", "run_tests", "run_lua", "submit"],
    "run": <String>["list_files", "read_file", "ls", "stat", "chmod", "run_file", "run_lua", "submit"],
    "awk": <String>["list_files", "read_file", "write_file", "run_awk", "run_lua", "submit"],
    "open_probe": <String>[
      "list_files",
      "read_file",
      "write_file",
      "search",
      "run_tests",
      "ls",
      "stat",
      "chmod",
      "run_file",
      "run_awk",
      "run_lua",
    ],
    "nav_plus_schedule": <String>["list_files", "read_file", "search", "run_lua", "submit", "list_schedules"],
    "file_plus_schedule": <String>[
      "list_files",
      "read_file",
      "write_file",
      "search",
      "run_tests",
      "list_schedules",
    ],
    "chmod_run_submit": <String>["chmod", "run_file", "submit"],
    "run_file_submit": <String>["run_file", "submit"],
    "run_tests_submit": <String>["run_tests", "submit"],
  };
}

final class AgentCaseVerdict {
  final bool passed;
  final bool assistedPassed;
  final bool validForModelScore;
  final List<String> failures;
  final List<String> assistedFailures;
  final List<String> failureCodes;
  final Map<String, int> interventionCounts;

  const AgentCaseVerdict({
    required this.passed,
    required this.assistedPassed,
    required this.validForModelScore,
    required this.failures,
    required this.assistedFailures,
    required this.failureCodes,
    required this.interventionCounts,
  });

  AgentJson toJson() {
    return <String, Object?>{
      "strictPassed": passed,
      "assistedPassed": assistedPassed,
      "validForModelScore": validForModelScore,
      "failures": failures,
      "assistedFailures": assistedFailures,
      "failureCodes": failureCodes,
      "interventionCounts": interventionCounts,
    };
  }
}

final class AgentCaseRunRecord {
  final AgentCase agentCase;
  final AgentRunResult result;
  final AgentCaseVerdict verdict;
  final String runId;
  final int attempt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const AgentCaseRunRecord({
    required this.agentCase,
    required this.result,
    required this.verdict,
    this.runId = "",
    this.attempt = 1,
    this.startedAt,
    this.completedAt,
  });

  int get durationMs {
    final start = startedAt;
    final end = completedAt;
    if (start == null || end == null) return 0;
    return end.difference(start).inMilliseconds;
  }

  AgentJson toJson() {
    return <String, Object?>{
      "case": <String, Object?>{
        "name": agentCase.name,
        "title": agentCase.title,
        "evaluation": agentCase.evaluation,
        "maxTurns": agentCase.maxTurns,
        "tools": agentCase.toolNames,
      },
      "runId": runId,
      "attempt": attempt,
      if (startedAt != null) "startedAt": startedAt!.toUtc().toIso8601String(),
      if (completedAt != null) "completedAt": completedAt!.toUtc().toIso8601String(),
      "durationMs": durationMs,
      "result": result.toJson(),
      "verdict": verdict.toJson(),
    };
  }
}
