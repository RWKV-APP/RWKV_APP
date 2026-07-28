// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/model/agent.dart';
import 'package:zone/model/agent_case.dart';
import 'package:zone/model/agent_evaluation.dart';

void main() {
  test('benchmark manifest matches the bundled case asset', () {
    final caseBytes = File("assets/agent_cases/primitive_bench.json").readAsBytesSync();
    final manifest =
        jsonDecode(
              File("assets/agent_cases/primitive_bench_manifest.json").readAsStringSync(),
            )
            as Map<String, dynamic>;
    final cases = jsonDecode(utf8.decode(caseBytes)) as List<dynamic>;

    expect(manifest["schema_version"], agentEvaluationSchemaVersion);
    expect(manifest["version"], agentEvaluationBenchmarkVersion);
    expect(manifest["case_count"], cases.length);
    expect(manifest["cases_sha256"], sha256.convert(caseBytes).toString());
  });

  test('report separates strict, assisted, invalid, and interventions', () async {
    final agentCase = AgentCase.fromJson(<String, dynamic>{
      "name": "submit_case",
      "title": "Submit",
      "prompt": "Submit BLUEBIRD",
      "tools": <String>["submit"],
      "environment": <String, dynamic>{
        "expected_submit": "BLUEBIRD",
      },
      "evaluation": "submit",
    });
    final sandbox = agentCase.createSandbox();
    await sandbox.call(
      const AgentToolCall(
        id: "call_1",
        name: "submit",
        arguments: <String, Object?>{"answer": "BLUEBIRD"},
        raw: '{"name":"submit","arguments":{"answer":"BLUEBIRD"}}',
      ),
    );
    final assistedResult = AgentRunResult(
      status: .submitted,
      finalAnswer: "BLUEBIRD",
      prompt: "prompt",
      events: const <AgentEvent>[
        AgentEvent(
          kind: .modelOutput,
          turn: 1,
          title: "Model output",
          content: "effective",
          rawContent: "raw",
          interventions: <AgentInterventionKind>[
            .jsonRepair,
          ],
        ),
      ],
      turns: 1,
    );
    final invalidResult = AgentRunResult(
      status: .infrastructureFailed,
      finalAnswer: "",
      prompt: "prompt",
      events: const <AgentEvent>[
        AgentEvent(
          kind: .error,
          turn: 1,
          title: "Infrastructure error",
          content: "backend_status_timeout",
        ),
      ],
      turns: 1,
      validForModelScore: false,
    );
    final now = DateTime.utc(2026, 7, 20);
    final records = <AgentCaseRunRecord>[
      AgentCaseRunRecord(
        agentCase: agentCase,
        result: assistedResult,
        verdict: agentCase.score(result: assistedResult, sandbox: sandbox),
        runId: "run",
        startedAt: now,
        completedAt: now,
      ),
      AgentCaseRunRecord(
        agentCase: agentCase,
        result: invalidResult,
        verdict: agentCase.score(result: invalidResult, sandbox: sandbox),
        runId: "run",
        attempt: 2,
        startedAt: now,
        completedAt: now,
      ),
    ];
    final report = AgentEvaluationReport(
      manifest: const AgentEvaluationManifest(
        schemaVersion: agentEvaluationSchemaVersion,
        benchmarkId: agentEvaluationBenchmarkId,
        benchmarkVersion: agentEvaluationBenchmarkVersion,
        benchmarkSha256: "cases",
        caseCount: 1,
        runId: "run",
        mode: .assisted,
        repeatCount: 2,
        selectedCases: <String>["submit_case"],
        plannedRuns: 2,
        app: <String, Object?>{},
        device: <String, Object?>{},
        model: <String, Object?>{},
        sampler: <String, Object?>{},
      ),
      startedAt: now,
      completedAt: now,
      records: records,
    );

    final json = report.toJson();
    final summary = json["summary"]! as Map<String, Object?>;
    final interventions = summary["interventionCounts"]! as Map<String, int>;

    expect(summary["completedRuns"], 2);
    expect(summary["strictPassed"], 0);
    expect(summary["assistedPassed"], 1);
    expect(summary["invalid"], 1);
    expect(interventions["jsonRepair"], 1);
    expect(
      records.last.verdict.failureCodes,
      <String>["infrastructure_failure", "invalid_run"],
    );
  });

  test('cancelled runs are invalid without task-specific failures', () {
    final agentCase = AgentCase.fromJson(<String, dynamic>{
      "name": "arithmetic",
      "title": "Arithmetic",
      "prompt": "Multiply.",
      "tools": <String>["multiply"],
      "evaluation": "arithmetic",
    });
    final sandbox = agentCase.createSandbox();
    const result = AgentRunResult(
      status: .cancelled,
      finalAnswer: "",
      prompt: "prompt",
      events: <AgentEvent>[],
      turns: 0,
      validForModelScore: false,
    );

    final verdict = agentCase.score(result: result, sandbox: sandbox);
    final now = DateTime.utc(2026, 7, 26);
    final report = AgentEvaluationReport(
      manifest: const AgentEvaluationManifest(
        schemaVersion: agentEvaluationSchemaVersion,
        benchmarkId: agentEvaluationBenchmarkId,
        benchmarkVersion: agentEvaluationBenchmarkVersion,
        benchmarkSha256: "cases",
        caseCount: 1,
        runId: "cancelled",
        mode: .strict,
        repeatCount: 1,
        selectedCases: <String>["arithmetic"],
        plannedRuns: 1,
        app: <String, Object?>{},
        device: <String, Object?>{},
        model: <String, Object?>{},
        sampler: <String, Object?>{},
      ),
      startedAt: now,
      completedAt: now,
      records: <AgentCaseRunRecord>[
        AgentCaseRunRecord(
          agentCase: agentCase,
          result: result,
          verdict: verdict,
          runId: "cancelled",
          startedAt: now,
          completedAt: now,
        ),
      ],
    );
    final summary = report.toJson()["summary"]! as Map<String, Object?>;

    expect(verdict.validForModelScore, isFalse);
    expect(verdict.failureCodes, <String>["cancelled", "invalid_run"]);
    expect(verdict.failures, isNot(contains("did not call multiply")));
    expect(verdict.failures, isNot(contains("final answer did not contain 1887357")));
    expect(summary["failed"], 0);
    expect(summary["invalid"], 1);
  });
}
