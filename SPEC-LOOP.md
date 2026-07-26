# Spec Sync Loop

Process version: v1.7
Effective date: 2026-07-23

Spec Sync Loop turns product conversation into durable project truth. It keeps raw input, current specification, implementation, and delivery evidence connected without treating any one chat message or code change as the whole product contract.

It is a checked-in, semi-automatic workflow. It does not act as a live memory bus across chat tools, repositories, or sessions; external input still has to be captured and normalized into this repository.

## Purpose

The system separates four layers:

- Raw input preserves what a user, stakeholder, or repository audit actually supplied
- Canonical specification states the current contract for one topic
- Delivery surfaces show what documentation, code, configuration, and runtime behavior currently do
- Process records explain conflicts, decisions, supersession, observations, and acceptance

This separation lets Codex act on compatible requirements while preserving unresolved disagreements for an explicit human ruling.

## Operating Loop

1. Classify a request as product, process, mixed, implementation-only, or general chat
2. Capture product or process input as one strict, independently reviewable `PI-*` record
3. Resolve the topic through `docs/specs/01-authority-map.md` and its stable `SPEC-*` IDs
4. Compare the new assertion with the canonical owner and current `CF-*` records
5. Merge compatible truth or record a narrowly scoped conflict
6. Update canonical truth before dependent implementation
7. Synchronize derived documentation, implementation, runtime configuration, and evidence
8. Run engineering checks and inspect representative real outcomes
9. Record the combined result as `ACC-*`, then update delivery state independently

## Safety Rules

- Conversation is traceable evidence; compatible input becomes authoritative only after canonical synchronization
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
- Secrets, signed URLs, personal data, and machine-local evidence paths must be redacted before records enter source control

## v1.7 Record Model

v1.7 stores each `PI-*`, `DEC-*`, `OBS-*`, `CF-*`, and `ACC-*` record in its own Markdown file with strict front matter. Free-form raw text remains in the body, so copied chat headings or field-like text cannot corrupt metadata parsing.

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
