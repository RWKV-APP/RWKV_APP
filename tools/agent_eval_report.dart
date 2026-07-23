// Dart imports:
import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final options = _Options.parse(arguments);
  if (options.help || options.inputPaths.isEmpty) {
    stdout.write(_usage);
    exitCode = options.help ? 0 : 64;
    return;
  }

  final reports = <_Report>[];
  for (final path in options.inputPaths) {
    reports.add(_Report.read(path));
  }
  final content = switch (options.format) {
    "csv" => _buildCsv(reports),
    "json" => const JsonEncoder.withIndent("  ").convert(
      reports.map((report) => report.comparisonJson()).toList(),
    ),
    _ => _buildMarkdown(reports),
  };
  final outputPath = options.outputPath;
  if (outputPath == null) {
    stdout.writeln(content);
    return;
  }
  File(outputPath).writeAsStringSync(content, flush: true);
  stdout.writeln(outputPath);
}

String _buildMarkdown(List<_Report> reports) {
  final buffer = StringBuffer()
    ..writeln("# Agentic Evaluation Comparison")
    ..writeln()
    ..writeln("| Run | Model | Quantization | Backend | Mode | Session | Runs | Strict | Assisted | Invalid |")
    ..writeln("|---|---|---|---|---:|---|---:|---:|---:|---:|");
  for (final report in reports) {
    buffer.writeln(
      "| ${_md(report.runId)} | ${_md(report.modelName)} | ${_md(report.quantization)} | "
      "${_md(report.backend)} | ${_md(report.mode)} | ${_md(report.sessionStatus)} | "
      "${report.completed}/${report.plannedRuns} | "
      "${report.strictPassed}/${report.completed} | "
      "${report.assistedPassed}/${report.completed} | ${report.invalid} |",
    );
  }

  final caseNames = <String>{};
  for (final report in reports) {
    caseNames.addAll(report.cases.keys);
  }
  if (caseNames.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln("## Per-case results")
      ..writeln()
      ..write("| Case |");
    for (final report in reports) {
      buffer.write(" ${_md(report.runId)} |");
    }
    buffer
      ..writeln()
      ..write("|---|");
    for (int index = 0; index < reports.length; index++) {
      buffer.write("---|");
    }
    buffer.writeln();
    final sortedCases = caseNames.toList()..sort();
    for (final caseName in sortedCases) {
      buffer.write("| ${_md(caseName)} |");
      for (final report in reports) {
        buffer.write(" ${report.cases[caseName] ?? "—"} |");
      }
      buffer.writeln();
    }
  }

  buffer
    ..writeln()
    ..writeln("## Failure taxonomy")
    ..writeln();
  for (final report in reports) {
    buffer
      ..writeln("### ${report.runId}")
      ..writeln();
    if (report.failureCounts.isEmpty) {
      buffer.writeln("- No scored failures");
    } else {
      final entries = report.failureCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        buffer.writeln("- `${entry.key}`: ${entry.value}");
      }
    }
    buffer
      ..writeln()
      ..writeln("Host interventions:");
    if (report.interventionCounts.isEmpty) {
      buffer.writeln("- None");
    } else {
      final entries = report.interventionCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        buffer.writeln("- `${entry.key}`: ${entry.value}");
      }
    }
    buffer.writeln();
  }
  return buffer.toString().trimRight();
}

String _buildCsv(List<_Report> reports) {
  final buffer = StringBuffer()
    ..writeln(
      "run_id,model,quantization,backend,mode,session_status,completed,planned_runs,strict_passed,assisted_passed,invalid,benchmark_sha256",
    );
  for (final report in reports) {
    buffer.writeln(
      <Object?>[
        report.runId,
        report.modelName,
        report.quantization,
        report.backend,
        report.mode,
        report.sessionStatus,
        report.completed,
        report.plannedRuns,
        report.strictPassed,
        report.assistedPassed,
        report.invalid,
        report.benchmarkSha256,
      ].map(_csv).join(","),
    );
  }
  return buffer.toString().trimRight();
}

String _md(String value) {
  return value.replaceAll("|", r"\|").replaceAll("\n", " ");
}

String _csv(Object? value) {
  final text = value?.toString() ?? "";
  return '"${text.replaceAll('"', '""')}"';
}

final class _Options {
  final List<String> inputPaths;
  final String format;
  final String? outputPath;
  final bool help;

  const _Options({
    required this.inputPaths,
    required this.format,
    required this.outputPath,
    required this.help,
  });

  factory _Options.parse(List<String> arguments) {
    final inputPaths = <String>[];
    String format = "markdown";
    String? outputPath;
    bool help = false;
    for (int index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == "--help" || argument == "-h") {
        help = true;
        continue;
      }
      if (argument == "--format" && index + 1 < arguments.length) {
        index += 1;
        format = arguments[index].toLowerCase();
        continue;
      }
      if (argument == "--output" && index + 1 < arguments.length) {
        index += 1;
        outputPath = arguments[index];
        continue;
      }
      inputPaths.add(argument);
    }
    if (!const <String>{"markdown", "csv", "json"}.contains(format)) {
      throw FormatException("Unsupported format: $format");
    }
    return _Options(
      inputPaths: inputPaths,
      format: format,
      outputPath: outputPath,
      help: help,
    );
  }
}

final class _Report {
  final Map<String, Object?> root;

  const _Report(this.root);

  factory _Report.read(String path) {
    final decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is! Map) {
      throw FormatException("Report must be a JSON object: $path");
    }
    return _Report(_map(decoded));
  }

  Map<String, Object?> get manifest => _map(root["manifest"]);
  Map<String, Object?> get model => _map(manifest["model"]);
  Map<String, Object?> get benchmark => _map(manifest["benchmark"]);
  Map<String, Object?> get selection => _map(manifest["selection"]);
  Map<String, Object?> get summary => _map(root["summary"]);

  String get runId => manifest["runId"]?.toString() ?? "unknown";
  String get modelName => model["name"]?.toString() ?? "unknown";
  String get quantization => model["quantization"]?.toString() ?? "unknown";
  String get backend => model["backend"]?.toString() ?? "unknown";
  String get mode => manifest["mode"]?.toString() ?? "unknown";
  String get sessionStatus => root["sessionStatus"]?.toString() ?? "unknown";
  String get benchmarkSha256 => benchmark["sha256"]?.toString() ?? "unknown";
  int get completed => _integer(summary["completedRuns"]);
  int get plannedRuns => _integer(selection["plannedRuns"]);
  int get strictPassed => _integer(summary["strictPassed"]);
  int get assistedPassed => _integer(summary["assistedPassed"]);
  int get invalid => _integer(summary["invalid"]);
  Map<String, int> get failureCounts => _integerMap(summary["failureCounts"]);
  Map<String, int> get interventionCounts => _integerMap(summary["interventionCounts"]);

  Map<String, String> get cases {
    final values = root["records"];
    if (values is! List) return <String, String>{};
    final result = <String, String>{};
    for (final value in values) {
      final record = _map(value);
      final caseValue = _map(record["case"]);
      final verdict = _map(record["verdict"]);
      final name = caseValue["name"]?.toString() ?? "";
      if (name.isEmpty) continue;
      final attempt = _integer(record["attempt"]);
      final status = verdict["validForModelScore"] == false
          ? "INVALID"
          : verdict["strictPassed"] == true
          ? "PASS"
          : verdict["assistedPassed"] == true
          ? "ASSISTED"
          : "FAIL";
      final key = attempt <= 1 ? name : "$name#$attempt";
      result[key] = status;
    }
    return result;
  }

  Map<String, Object?> comparisonJson() {
    return <String, Object?>{
      "runId": runId,
      "model": modelName,
      "quantization": quantization,
      "backend": backend,
      "mode": mode,
      "sessionStatus": sessionStatus,
      "completed": completed,
      "plannedRuns": plannedRuns,
      "strictPassed": strictPassed,
      "assistedPassed": assistedPassed,
      "invalid": invalid,
      "benchmarkSha256": benchmarkSha256,
      "failureCounts": failureCounts,
      "interventionCounts": interventionCounts,
      "cases": cases,
    };
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return <String, Object?>{};
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) continue;
    result[entry.key as String] = entry.value;
  }
  return result;
}

Map<String, int> _integerMap(Object? value) {
  final source = _map(value);
  return <String, int>{
    for (final entry in source.entries) entry.key: _integer(entry.value),
  };
}

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? "") ?? 0;
}

const String _usage = """
Usage:
  dart run tools/agent_eval_report.dart [options] REPORT.json [REPORT.json ...]

Options:
  --format markdown|csv|json   Output format (default: markdown)
  --output PATH                Write output to PATH instead of stdout
  --help                       Show this help
""";
