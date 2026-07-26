---
id: OBS-20260723-TELEMETRY-PRIVACY-DRIFT
type: observation
date: 2026-07-23
status: recorded
inputs: []
conflicts: []
decision: null
canonical_assertions:
  - SPEC-RWKV-TELEMETRY-PRIVACY-CONTRACT
affected_surfaces:
  - docs/privacy_policy.html
  - docs/architecture/store-map.md
  - lib/store/telemetry.dart
  - lib/store/chat_generation_completion.dart
  - lib/store/benchmark.dart
---

# Telemetry implementation drifts from checked-in privacy and architecture wording

## Observation

`docs/privacy_policy.html` says the app does not collect device information or track usage. `docs/architecture/store-map.md` describes `P.telemetry` as opt-in.

`lib/store/telemetry.dart` currently initializes telemetry as enabled, creates a persistent install ID, reads device, operating-system, CPU, GPU, memory, model, and performance fields, and posts a report to `/public-api/telemetry/perf`. Ordinary chat completion and benchmark paths can invoke that report.

## Implication

The implementation and derived architecture description drift from the active `SPEC-RWKV-TELEMETRY-PRIVACY-CONTRACT`. No independent, traceable product ruling authorizing the current default and disclosure contract was found during this migration, so implementation state alone is not promoted into a competing canonical rule.

## Proposed next step

In a separately authorized telemetry repair, synchronize runtime behavior and derived architecture wording with the current active no-transmission contract. If the intended product behavior is instead to retain or redesign network telemetry, first obtain an explicit human ruling on consent, default state, collected fields, purpose, retention, recipient, disclosure, and user controls; then supersede the canonical contract and synchronize policy, UI, implementation, architecture docs, and acceptance.

## Resolution
