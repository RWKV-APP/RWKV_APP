// Project imports:
import 'package:zone/model/agent.dart';
import 'package:zone/model/agent_case.dart';

const int agentEvaluationSchemaVersion = 2;
const String agentEvaluationBenchmarkId = "primitive-bench";
const String agentEvaluationBenchmarkVersion = "0.1";
const int agentEvaluationSeed = 42;

final class AgentEvaluationManifest {
  final int schemaVersion;
  final String benchmarkId;
  final String benchmarkVersion;
  final String benchmarkSha256;
  final int caseCount;
  final String runId;
  final AgentEvaluationMode mode;
  final int repeatCount;
  final List<String> selectedCases;
  final int plannedRuns;
  final Map<String, Object?> app;
  final Map<String, Object?> device;
  final Map<String, Object?> model;
  final Map<String, Object?> sampler;

  const AgentEvaluationManifest({
    required this.schemaVersion,
    required this.benchmarkId,
    required this.benchmarkVersion,
    required this.benchmarkSha256,
    required this.caseCount,
    required this.runId,
    required this.mode,
    required this.repeatCount,
    required this.selectedCases,
    required this.plannedRuns,
    required this.app,
    required this.device,
    required this.model,
    required this.sampler,
  });

  AgentJson toJson() {
    return <String, Object?>{
      "schemaVersion": schemaVersion,
      "benchmark": <String, Object?>{
        "id": benchmarkId,
        "version": benchmarkVersion,
        "sha256": benchmarkSha256,
        "caseCount": caseCount,
      },
      "runId": runId,
      "mode": mode.name,
      "repeatCount": repeatCount,
      "selection": <String, Object?>{
        "caseNames": selectedCases,
        "plannedRuns": plannedRuns,
      },
      "app": app,
      "device": device,
      "model": model,
      "sampler": sampler,
    };
  }
}

final class AgentEvaluationReport {
  final AgentEvaluationManifest manifest;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<AgentCaseRunRecord> records;
  final String? error;

  const AgentEvaluationReport({
    required this.manifest,
    required this.startedAt,
    required this.completedAt,
    required this.records,
    this.error,
  });

  AgentEvaluationReport copyWith({
    DateTime? completedAt,
    List<AgentCaseRunRecord>? records,
    String? error,
  }) {
    return AgentEvaluationReport(
      manifest: manifest,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      records: records ?? this.records,
      error: error ?? this.error,
    );
  }

  AgentJson toJson() {
    int strictPassed = 0;
    int assistedPassed = 0;
    int invalid = 0;
    final failureCounts = <String, int>{};
    final interventionCounts = <String, int>{};
    for (final record in records) {
      if (record.verdict.passed) strictPassed += 1;
      if (record.verdict.assistedPassed) assistedPassed += 1;
      if (!record.verdict.validForModelScore) invalid += 1;
      for (final code in record.verdict.failureCodes) {
        failureCounts[code] = (failureCounts[code] ?? 0) + 1;
      }
      for (final entry in record.verdict.interventionCounts.entries) {
        interventionCounts[entry.key] = (interventionCounts[entry.key] ?? 0) + entry.value;
      }
    }
    return <String, Object?>{
      "manifest": manifest.toJson(),
      "startedAt": startedAt.toUtc().toIso8601String(),
      if (completedAt != null) "completedAt": completedAt!.toUtc().toIso8601String(),
      "sessionStatus": error != null
          ? "infrastructure_failed"
          : completedAt == null
          ? "running"
          : "completed",
      if (error != null) "error": error,
      "summary": <String, Object?>{
        "completedRuns": records.length,
        "strictPassed": strictPassed,
        "assistedPassed": assistedPassed,
        "failed": records.length - strictPassed - invalid,
        "invalid": invalid,
        "strictPassRate": records.isEmpty ? 0 : strictPassed / records.length,
        "assistedPassRate": records.isEmpty ? 0 : assistedPassed / records.length,
        "failureCounts": failureCounts,
        "interventionCounts": interventionCounts,
      },
      "records": records.map((record) => record.toJson()).toList(),
    };
  }
}
