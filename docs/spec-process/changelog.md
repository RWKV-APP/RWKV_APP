# Spec Sync Loop Changelog

Process version: v1.8
Effective date: 2026-08-10

Only the newest version is active.

## v1.8 - 2026-08-10

Status: active

Changes:

- Added `SPEC-SYNC-ROOT-INTAKE-BOUNDARY`
- Kept raw requests, copied conversations, voice transcripts, per-task Changes, plans, conflict provenance, and combined acceptance in private Root Missions
- Prohibited new `docs/product-inputs/` records, Changes Markdown, task briefs, checked-in request plans, and PI/DEC/OBS/CF/ACC records for Root-routed work
- Preserved target ownership of canonical Specification, source, tests, architecture, and required durable product documentation
- Retained pre-v1.8 target input and process records as a validated read-only historical archive without bulk deletion or extension
- Added `SPEC-RWKV-CHAT-SAME-APP-ACCEPTANCE` for canonical RWKV Chat identity, persistence namespace, and user-consumed App acceptance

Authority:

- Explicit user rulings retained by the private Root Harness Specification graph

## v1.7 private-intake boundary amendment - 2026-08-06

Status: historical

Changes:

- Moved raw and near-raw product input out of `rwkv_app` into the private Root Harness
- Prohibited new `docs/product-inputs/` records in this repository
- Kept opaque private source IDs as provenance while requiring project records to stand on normalized assertions, decisions, surfaces, and evidence
- Reclassified active product and technical truth as contracts and removed unresolved proposal narratives from project authority
- Preserved legacy local PI parsing only as a migration compatibility path
- Added checker coverage for external private input references

Authority:

- Explicit user ruling recorded by `DEC-20260806-PRIVATE-INTAKE-BOUNDARY`

## v1.7 - 2026-07-23

Status: historical process baseline

Changes:

- Established the first repository-native Specification system for `rwkv_app`
- Preserved raw input, single canonical ownership, narrow conflict blocking, provenance-only Git history, independent delivery state, and root-agent acceptance from the audited `geo-ai` workflow
- Kept Agent memory as recall context while preserving checked-in Specification as shared truth
- Replaced aggregate Markdown ledgers with one strict front-matter record per input, decision, observation, conflict, and acceptance
- Added stable `SPEC-*` assertion IDs and lifecycle-aware authority-map validation
- Added `pending` effective state and `blocked` delivery state with a strict combination matrix
- Added ID/date/filename consistency, required backlinks, cycle checks, current/resolved conflict dates, declared chronology checks, and supersedable acceptance attempts
- Preserved bidirectional supersession links across three-generation input and decision history while keeping only the terminal record current
- Added structured assertion and affected-surface routing for decisions and observations
- Required resolving decisions, supersession links, and accepted delivery snapshots to cover the exact related assertions and surfaces
- Required every current accepted acceptance record to independently cover each input it names, even when another complete record also exists
- Required conflict provenance links to be topically related and collectively cover the conflict assertions and affected surfaces
- Added high-confidence credential and signed-URL scanning for records and supporting evidence
- Restored explicit anti-overfitting acceptance guardrails for surprising samples, generalized rules, and independent holdout review
- Added repository aliases for adapter, engine, and website implementation surfaces
- Replaced Node/pnpm and hard-coded working-directory assumptions with a root-first Dart checker, repository-root discovery, and CI coverage
- Added cross-platform machine-local evidence-path detection without treating all fenced command examples as evidence
- Kept hooks outside the mandatory workflow while forbidding automation from silently changing truth or acceptance
- Removed implicit legacy-format bypasses; all target records are strict from the first day

Notes:

- The source reference was an uncommitted `geo-ai` working-tree implementation, not a stable source revision
- GEO business records, pnpm commands, ports, backend/frontend paths, and deployment rules were intentionally excluded
- The user explicitly authorized migration plus correction of unreasonable design and omissions
