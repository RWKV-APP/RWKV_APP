---
id: PI-20260726-AGENT-EVAL-INVALID-CANCELLATION
type: product_input
captured_date: 2026-07-26
source_date: 2026-07-26
source: user
category: product
status: merged
effective_status: active
delivery_status: verified
canonical_assertions:
  - SPEC-RWKV-AGENTIC-EVAL
delivery_surfaces:
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - docs/agentic-evaluation/README.md
  - assets/agent_cases/primitive_bench_manifest.json
  - lib/func/agent_runtime.dart
  - lib/model/agent_case.dart
  - lib/model/agent_evaluation.dart
  - test/agent_protocol_test.dart
  - test/agent_evaluation_test.dart
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260726-AGENT-EVAL-MODEL-IDENTITY-AND-INVALID-RUNS
---

# Keep cancelled Agentic Evaluation runs out of model failure scores

## Raw statement

> 对于第二个问题,自行想一下解决方案。

The referenced second issue was the observed Windows result where a manually cancelled run was counted as `FAIL` with `INVALID 0`

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- A manually cancelled Agentic Evaluation run must be invalid for model scoring
- Invalid runs must be counted under `INVALID` and excluded from `PASS` and `FAIL`
- Invalid runs should preserve their invalidation reason without producing task-specific capability failures from an incomplete attempt
