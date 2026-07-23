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
  });
}
