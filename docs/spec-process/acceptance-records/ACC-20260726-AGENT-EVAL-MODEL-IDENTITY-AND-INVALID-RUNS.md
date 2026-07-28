---
id: ACC-20260726-AGENT-EVAL-MODEL-IDENTITY-AND-INVALID-RUNS
type: acceptance
date: 2026-07-26
owner: root Codex agent
inputs:
  - PI-20260726-AGENT-EVAL-NO-MODEL-SHA-VALIDATION
  - PI-20260726-AGENT-EVAL-INVALID-CANCELLATION
decisions:
  - DEC-20260726-AGENT-EVAL-MODEL-IDENTITY
canonical_assertions:
  - SPEC-RWKV-AGENTIC-EVAL
changed_surfaces:
  - assets/agent_cases/primitive_bench_manifest.json
  - docs/agentic-evaluation/README.md
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - docs/product-inputs/2026-07-26/PI-20260726-AGENT-EVAL-INVALID-CANCELLATION.md
  - docs/product-inputs/2026-07-26/PI-20260726-AGENT-EVAL-NO-MODEL-SHA-VALIDATION.md
  - docs/spec-process/acceptance-records/ACC-20260726-AGENT-EVAL-MODEL-IDENTITY-AND-INVALID-RUNS.md
  - docs/spec-process/decisions/DEC-20260726-AGENT-EVAL-MODEL-IDENTITY.md
  - lib/func/agent_runtime.dart
  - lib/model/agent_case.dart
  - lib/model/agent_evaluation.dart
  - lib/store/agent.dart
  - test/agent_evaluation_test.dart
  - test/agent_protocol_test.dart
  - tools/agent_eval_reference.dart
unresolved_conflicts:
  - CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
result: accepted
supersedes_acceptance: []
superseded_by: []
---

# Agentic Evaluation model identity and invalid-run acceptance

## Mechanical evidence

- `flutter test test/agent_protocol_test.dart test/agent_evaluation_test.dart` passed all 31 tests
- `dart test test/agent_eval_report_test.dart` passed from the `tools` package
- Targeted Flutter analysis of the changed App and test files completed with no issues
- `dart analyze agent_eval_reference.dart` completed with no issues from the `tools` package
- `dart run tools/agent_eval_reference.dart --help` succeeded and showed that `--model-sha256` is optional unverified metadata
- `flutter build windows --debug` completed successfully
- `git diff --check` completed successfully
- `dart run bin/check_specification.dart --root ..` passed from the `tools` package

The unrelated Web Demo privacy conflict remains open and does not overlap Agentic Evaluation model identity or invalid-run scoring

## Requirement review

The App no longer opens or streams the selected model file when creating an Agentic Evaluation report. It copies only an already supplied hash, uses `not_provided` when none exists, and always records `sha256Verified: false`. The reference runner no longer requires a model hash and retains its former opt-out flag only as a command-compatible no-op

Every cancellation return path now sets `validForModelScore: false`. Scoring exits before task-specific capability checks for any invalid result, retains the invalidation status and `invalid_run` code, and excludes the record from pass and failure totals. The scoring schema version advanced to 2

## Semantic or visual review

The root agent rebuilt and opened the Windows debug App, loaded the existing RWKV7-G1h 13.3B model, and started the arithmetic Agent case. The interface changed to `Running 1/1` within 841 milliseconds, eliminating the previously observed model-file hashing delay

The root agent then stopped the live run to exercise the original failure. The UI showed `Completed 1/1 · PASS 0 · FAIL 0 · INVALID 1` and listed only `agent ended with status cancelled` plus `run is invalid for model scoring`. The persisted report for run `20260726092306877223-cc52ad` contained `sha256: not_provided`, `sha256Verified: false`, `resultStatus: cancelled`, `validForModelScore: false`, and failure codes `cancelled` and `invalid_run`

An independent infrastructure-failure test confirmed that the reusable invalid-run rule also excludes task-specific failures from a non-cancellation invalid result

## Exclusions

- The complete 30-case benchmark was not rerun
- The 13.3B arithmetic case was intentionally cancelled, so model capability and generation completion were not evaluated
- No external reference endpoint was contacted
- Benchmark asset SHA remains part of benchmark identity; the approved prohibition concerns model-file SHA calculation and validation
