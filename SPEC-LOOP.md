# Spec Sync Loop

Process version: v1.7
Effective date: 2026-07-23

Spec Sync Loop turns product conversation into durable project truth. Raw or near-raw source material stays in the private Root Harness; this repository keeps only the normalized product contract, project decisions, implementation, and delivery evidence.

It is a checked-in, semi-automatic workflow. It does not act as a live memory bus across chat tools, repositories, or sessions. External input is retained privately by the Root Harness and translated into the smallest project-safe contract needed here.

## Purpose

The system separates four layers:

- Private Root intake preserves what a user, stakeholder, or repository audit actually supplied
- Canonical specification states the current contract for one topic
- Delivery surfaces show what documentation, code, configuration, and runtime behavior currently do
- Process records explain conflicts, decisions, supersession, observations, and acceptance

This separation lets Codex act on compatible requirements while preserving unresolved disagreements for an explicit human ruling.

## Operating Loop

1. Classify a request as product, process, mixed, implementation-only, or general chat
2. Retain raw product or process input in the private Root Harness and assign an opaque source ID
3. Resolve the topic through `docs/specs/01-authority-map.md` and its stable `SPEC-*` IDs
4. Compare the new assertion with the canonical owner and current `CF-*` records
5. Write only the normalized compatible truth or a narrowly scoped project conflict
6. Update canonical truth before dependent implementation
7. Synchronize derived documentation, implementation, runtime configuration, and evidence
8. Run engineering checks and inspect representative real outcomes
9. Record the combined result as `ACC-*`, then update delivery state independently

## Safety Rules

- Conversation is traceable private evidence; it is not stored in this repository and becomes authoritative only after canonical synchronization
- Agent memory may aid recall, but checked-in Specification remains shared truth and drift-prone remembered facts require current verification
- Every topic has one canonical owner
- Derived documentation, code, tests, runtime configuration, and Git history can reveal drift but cannot silently redefine intended behavior
- Git history proves sequence and provenance only when paired with a traceable ruling
- Current conflicts pause only the behavior that depends on the unresolved assertion
- Core process safety changes require explicit user approval
- `merged` means synchronized specification, not implemented or verified delivery
- Automated checks support acceptance but do not replace semantic, visual, real-model, real-device, or cross-surface review
- Final combined acceptance remains the responsibility of the root Codex agent delivering the task
- Acceptance evaluates outcomes against approved assertions and cannot invent new product restrictions
- `SPEC-SYNC-ACCEPTANCE-GUARDRAILS` requires an exact active assertion before review preference changes product logic, plus original-case and independent-holdout review for generalized fixes
- Secrets, signed URLs, personal data, machine-local evidence paths, and unnecessary source wording must not enter this repository

## v1.7 Project Record Model

Project-local v1.7 records are `DEC-*`, `OBS-*`, `CF-*`, and `ACC-*` Markdown files with strict front matter. Their `inputs` fields may retain opaque `PI-*` source IDs owned by the private Root Harness, but the source body and private path do not enter this repository. Legacy local `PI-*` files are accepted only while reading an older checkout and must not be newly created.

The version also adds:

- stable `SPEC-*` assertion IDs
- `pending` effective state for unreviewed or unresolved input
- `blocked` delivery state for conflict-dependent work
- strict ID, date, filename, required-backlink, declared-chronology, and cycle checks
- current/resolved conflict timestamps
- supersedable acceptance records
- repository-qualified references for adapter, engine, and website surfaces
- a Dart-native checker with repository-root discovery and explicit `--root` support

Detailed state rules and schemas live in `docs/spec-process/rules.md` and `docs/spec-process/templates.md`.
