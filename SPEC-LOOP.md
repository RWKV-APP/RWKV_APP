# Spec Sync Loop

Process version: v1.8
Effective date: 2026-08-10

Spec Sync Loop turns a private Root Harness Delivery Contract into durable
project truth. Raw or near-raw source material, per-task Changes, plans,
conflict provenance, and acceptance stay in the Root Mission; this repository
keeps canonical product and technical truth plus its delivery surfaces.

It is a checked-in, semi-automatic workflow. It does not act as a live memory
bus across chat tools, repositories, or sessions.

## Purpose

The system separates four layers:

- Private Root intake preserves the source request, routing, planning, rulings, and combined delivery evidence
- Canonical Specification states the current target-owned contract for one topic
- Delivery surfaces show what documentation, code, configuration, tests, and runtime behavior currently do
- Historical target input and process records preserve pre-v1.8 project provenance without receiving new Root-routed records

## Operating Loop

1. Capture and classify the request in a private Root Mission
2. Dispatch the smallest useful Project Delivery Contract
3. Resolve the topic through `docs/specs/01-authority-map.md` and its stable `SPEC-*` IDs
4. Compare the assertion with the canonical owner and applicable historical conflicts
5. Synchronize compatible canonical truth, or leave it unchanged while a semantic conflict is retained in Root
6. Update derived documentation, implementation, runtime configuration, and tests
7. Run engineering checks and inspect representative real outcomes
8. Record combined acceptance in the Root Mission Result

## Safety Rules

- `SPEC-SYNC-PRIVATE-INTAKE-BOUNDARY` keeps raw or near-raw source material and private paths outside this repository
- `SPEC-SYNC-ROOT-INTAKE-BOUNDARY` prohibits new target-side PI files, Changes Markdown, task briefs, checked-in request plans, and PI/DEC/OBS/CF/ACC records for Root-routed work
- The target continues to own canonical Specification, source code, tests, architecture, and required durable product documentation
- Existing target PI, DEC, OBS, CF, and ACC files remain a validated read-only historical archive and are neither bulk-deleted nor extended
- Conversation and opaque private source IDs are provenance, not canonical truth
- Agent memory may aid recall, but checked-in Specification remains shared truth and drift-prone remembered facts require current verification
- Every topic has one canonical owner
- Derived documentation, code, tests, runtime configuration, and Git history can reveal drift but cannot silently redefine intended behavior
- Current conflicts pause only the behavior that depends on the unresolved assertion
- Core process safety changes require explicit user approval
- Automated checks support acceptance but do not replace semantic, visual, real-model, real-device, or cross-surface review
- Final combined acceptance remains the responsibility of the root Codex agent delivering the task
- Secrets, credentials, signed URLs, personal data, and machine-local evidence paths must not enter this repository

## v1.8 Root Intake Model

v1.8 keeps every new Root-routed request record in the private Harness and
retains the v1.7 target validator only for historical project records. The
historical validator continues to provide stable assertion IDs, strict
metadata, conflict chronology, supersession relationships, repository-qualified
references, and deterministic drift checks.

For app-level RWKV Chat acceptance,
`SPEC-RWKV-CHAT-SAME-APP-ACCEPTANCE` requires the canonical app identity,
persistence namespace, and user-consumed surface. A renamed, alternate-ID, or
separately sandboxed acceptance app is not App-level proof.

Detailed rules live in `docs/spec-process/rules.md`; strict historical record
schemas live in `docs/spec-process/templates.md`.
