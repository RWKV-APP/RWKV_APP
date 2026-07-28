---
id: ACC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
type: acceptance
date: 2026-07-26
owner: root Codex agent
inputs:
  - PI-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
decisions:
  - DEC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
canonical_assertions:
  - SPEC-RWKV-AGENTIC-EVAL
changed_surfaces:
  - docs/agentic-evaluation/README.md
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - docs/product-inputs/2026-07-26/PI-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY.md
  - docs/spec-process/acceptance-records/ACC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY.md
  - docs/spec-process/decisions/DEC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY.md
  - lib/model/agent.dart
  - lib/store/agent.dart
  - test/agent_transport_test.dart
unresolved_conflicts:
  - CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
result: accepted
supersedes_acceptance: []
superseded_by: []
---

# Agentic Evaluation first-token safety acceptance

## Mechanical evidence

- `flutter test test/agent_transport_test.dart` passed all 6 tests
- `dart analyze lib/model/agent.dart lib/store/agent.dart test/agent_transport_test.dart` completed with no issues
- `dart run tools/bin/check_specification.dart` passed Specification v1.7
- The Windows Debug App rebuilt against the current Visual Studio toolchain and launched successfully

The unrelated Web Demo privacy conflict remains open and does not overlap Agentic Evaluation generation startup

## Requirement review

Agentic Evaluation now validates a supported deterministic sampler before native generation and records the same values in the report. The active preset is seed 42, temperature 0.2, top-k 500, top-p 0, zero presence and frequency penalties, and penalty decay 0.99

The Agent transport subscribes before sending `GenerateAsync`, snapshots and filters stale response-buffer content, and accepts buffer updates only from one-time Agent-owned polls for the active model ID. No fresh output within 20 seconds produces `first_token_timeout`, attempts to stop the active model, and keeps the run out of model scoring

The implementation does not read or hash the model file. The accepted report retained `sha256: not_provided` and `sha256Verified: false`

## Semantic or visual review

The root agent opened the rebuilt Windows Debug App and loaded `RWKV7-G1h 13.3B` using the native `llamacpp` GPU `Q4_K_M` model. The arithmetic Agent case completed with `PASS`, called `multiply` with `4827` and `391`, received `1887357`, and returned the same final answer

Run `20260726144957899930-f72725` started at `2026-07-26T14:49:57.899930Z` and completed at `2026-07-26T14:50:00.524166Z`. The first generation segment completed in 1122 milliseconds, its tool-call continuation completed in 623 milliseconds, and the second generation completed in 703 milliseconds. The full persisted run completed in about 2.62 seconds with zero invalid runs

This confirms that the repaired 13.3B Agent path produces output promptly and no longer remains silent for six minutes

## Exclusions

- The complete 30-case benchmark was not rerun
- The 20-second failure path was covered by unit-level configuration and isolation checks, while the real 13.3B run exercised the successful output path
- No external reference endpoint was contacted
