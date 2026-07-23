// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:test/test.dart';

void main() {
  test("generates a comparison from an exported report", () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp("agent_eval_report_test_");
    addTearDown(() async {
      await temporaryDirectory.delete(recursive: true);
    });
    final reportFile = File("${temporaryDirectory.path}/report.json");
    await reportFile.writeAsString(
      jsonEncode(<String, Object?>{
        "manifest": <String, Object?>{
          "runId": "run-1",
          "mode": "strict",
          "benchmark": <String, Object?>{
            "sha256": "cases",
          },
          "selection": <String, Object?>{
            "caseNames": <String>["arithmetic"],
            "plannedRuns": 1,
          },
          "model": <String, Object?>{
            "name": "G1h",
            "quantization": "BF16",
            "backend": "reference",
          },
        },
        "sessionStatus": "completed",
        "summary": <String, Object?>{
          "completedRuns": 1,
          "strictPassed": 1,
          "assistedPassed": 1,
          "invalid": 0,
          "failureCounts": <String, int>{},
          "interventionCounts": <String, int>{},
        },
        "records": <Object?>[
          <String, Object?>{
            "attempt": 1,
            "case": <String, Object?>{"name": "arithmetic"},
            "verdict": <String, Object?>{
              "strictPassed": true,
              "assistedPassed": true,
              "validForModelScore": true,
            },
          },
        ],
      }),
    );

    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>[
        "run",
        "agent_eval_report.dart",
        reportFile.path,
      ],
      workingDirectory: Directory.current.path,
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains("Agentic Evaluation Comparison"));
    expect(
      result.stdout,
      contains("| run-1 | G1h | BF16 | reference | strict | completed | 1/1 | 1/1 | 1/1 | 0 |"),
    );
    expect(result.stdout, contains("| arithmetic | PASS |"));
  });
}
