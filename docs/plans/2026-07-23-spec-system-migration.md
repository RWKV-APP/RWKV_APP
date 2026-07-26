# Specification v1.7 Migration Plan

Status: completed
Started: 2026-07-23

## Scope

Migrate the complete Specification workflow from the audited `geo-ai` working-tree v1.6 design into `rwkv_app`, adapt it to Flutter/Dart and sibling-repository ownership, repair confirmed process gaps, integrate deterministic checks, and record final acceptance.

## Linked Truth

- Input: `PI-20260723-SPEC-SYSTEM-MIGRATION`
- Decision: `DEC-20260723-ADAPT-SPEC-SYNC-V17`
- Assertions: `SPEC-SYNC-CLASSIFICATION`, `SPEC-SYNC-AUTHORITY`, `SPEC-SYNC-STATE-MODEL`, `SPEC-SYNC-CONFLICTS`, `SPEC-SYNC-ACCEPTANCE`, `SPEC-SYNC-ACCEPTANCE-GUARDRAILS`, `SPEC-SYNC-AUTHORITY-MAP`, `SPEC-SYNC-EXECUTION-PLANS`
- Current conflict: `CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW`

## Intended Behavior

- Future product/process input enters a strict, traceable Specification flow before implementation
- Every topic has one lifecycle-aware canonical owner and stable assertion IDs
- Conflicts pause only dependent behavior
- Delivery and acceptance remain independent from specification merge state
- The checker runs through Dart locally and in CI

## Exclusions

- GEO business records and runtime assumptions
- A product ruling on the privacy/data-flow conflict
- App runtime changes unrelated to Specification infrastructure
- Git commit or deployment

## Milestones

- [x] Audit source workflow, current working-tree v1.6, checker, tests, and Git provenance
- [x] Audit target architecture, documentation, CI, existing product truth, and drift
- [x] Define target v1.7 record, authority, state, conflict, reference, and acceptance model
- [x] Add canonical docs, records, skill, Agent triggers, and target source inventory
- [x] Complete Dart checker, tests, standard-check integration, and CI integration
- [x] Run focused and repository-level verification
- [x] Perform root combined review and write accepted or partial `ACC-*`

## Progress

- 2026-07-23 17:53 CST: Source and target audits, v1.7 process design, canonical docs, initial records, skill, authority map, and CI wiring are complete. Checker fixtures, standard-check integration, full verification, and final acceptance remain in progress.
- 2026-07-23 18:51 CST: Source checks passed 28 of 28 tests; target tools passed 69 of 69 tests, App tests passed 323 of 323, both analysis scopes were clean, all checker entrypoints passed, and the full standard check completed.
- 2026-07-23 18:51 CST: Root combined review and two independent final reviews found no remaining P0, P1, or necessary P2 issue. `ACC-20260723-SPEC-SYNC-V17-MIGRATION` accepted the delivered process scope.

## Discoveries And Decisions

- The source v1.6 implementation was not committed at source base revision `9c3b088c1beb9ca1b4aae76b7055c18fb6b1126a`; the reproducible audited core manifest digest is `13edab8abde22126129bba29540712367525a7dde188d8ea9d11ed119ce5616e`
- Aggregate Markdown parsing, effective-day legacy handling, pending state, authority validation, backlinks, conflict dates, acceptance supersession, external paths, cwd behavior, and CI all needed correction
- `rwkv_app` Agent mirror is a symlink at `.github/copilot-instructions.md`; deleted `CLAUDE.md` and `GEMINI.md` should not be recreated
- README toolchain minimum drifted from the 3.44.0 canonical baseline
- Public privacy wording and the explicit cloud Web Demo contract require a human product/privacy ruling
- Telemetry default/disclosure drift and the dynamic privacy-policy date are independent observations, not bundled into that conflict
- `DEC-20260723-ADAPT-SPEC-SYNC-V17` approves a Dart-native v1.7 adaptation, strict per-file records, explicit decision authority, portable path checks, and automation safety boundaries

## Mechanical Checks

- Skill structure validation passed
- Source Specification checker passed and source tests passed 28 of 28
- Target Specification tests passed 68 of 68; the full tools suite passed 69 of 69
- Real repository checks passed from the root command, the `tools/ --root ..` CI form, and both root/tools `agent_check --spec-only` paths
- Tools and App analysis reported no issues; Flutter tests passed 323 of 323
- The full standard Agent check passed; its non-blocking rule scan reported 29 historical warnings outside the migration files
- Source manifest recomputation, Agent mirror comparison, Markdown whitespace scan, and Git diff checks passed

## Result-Level Review

The root agent inspected the complete source-to-target mapping, combined diff, record graph, authority map, actual privacy and telemetry evidence, checker fixtures, skill, localized README synchronization, and CI entrypoint. The delivered scope has no App UI, model-output, network-runtime, or rendered-visual change.

## Remaining Gaps

- A future user ruling remains necessary for the cloud Web Demo transmission and disclosure contract
- Telemetry runtime drift and the non-auditable privacy-policy date remain separate open observations
- Real-device, real-model, deployment, and optional sibling-repository validation were excluded because this migration changes process infrastructure only

## Retrospective

The source separation of input, authority, conflict, delivery, and acceptance transferred cleanly. Strict records, stable assertions, full graph coverage, portable path handling, independent acceptance closure, and diagnostic redaction removed the main ways the source implementation could report false confidence. The remaining privacy and telemetry items are visible as narrowly scoped records rather than being silently selected or mixed into this process delivery.

## Outcome

The repository-native Spec Sync Loop v1.7 is implemented, integrated with the standard check and CI, and accepted by `ACC-20260723-SPEC-SYNC-V17-MIGRATION`. No required migration work remains.
