---
id: OBS-20260723-SOURCE-SPEC-PORTABILITY-GAPS
type: observation
date: 2026-07-23
status: resolved
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
conflicts: []
decision: DEC-20260723-ADAPT-SPEC-SYNC-V17
canonical_assertions:
  - SPEC-SYNC-CLASSIFICATION
  - SPEC-SYNC-AUTHORITY
  - SPEC-SYNC-STATE-MODEL
  - SPEC-SYNC-CONFLICTS
  - SPEC-SYNC-ACCEPTANCE
  - SPEC-SYNC-ACCEPTANCE-GUARDRAILS
  - SPEC-SYNC-AUTHORITY-MAP
affected_surfaces:
  - docs/product-inputs/evidence/2026-07-23-geo-ai-spec-v16-core-manifest.md
  - docs/spec-process/rules.md
  - docs/spec-process/templates.md
  - docs/specs/01-authority-map.md
  - .agents/skills/spec-sync/SKILL.md
  - tools/lib/specification/specification_checker.dart
  - tools/test/specification_checker_test.dart
  - .github/workflows/unit-tests.yml
---

# Source Specification system required structural adaptation

## Observation

The audit used `geo-ai` base revision `9c3b088c1beb9ca1b4aae76b7055c18fb6b1126a` plus its dirty working-tree v1.6 changes. The exact core file list, working-tree Git blob IDs, and reproducible manifest digest `13edab8abde22126129bba29540712367525a7dde188d8ea9d11ed119ce5616e` are preserved in `docs/product-inputs/evidence/2026-07-23-geo-ai-spec-v16-core-manifest.md`. That visible v1.6 system had strong process semantics but was not a stable committed source revision.

Its Markdown entry parser could ignore malformed records, its strict mode could be bypassed on the effective date, and its effective state had no accurate value for pending or conflicted assertions.

The checker did not fully validate authority-map ownership, conflict-to-input backlinks, conflict decisions, observation decisions, invalid state combinations, acceptance dates, acceptance supersession, or external repository references. It also assumed Node, pnpm, Git, the current working directory, GEO paths, and macOS-specific local-path exceptions.

## Implication

A verbatim copy could report a green workflow while silently missing a record, treating unresolved input as active, using a stale acceptance, or rejecting valid Flutter and sibling-repository paths. It would also introduce source business history and runtime assumptions that do not belong to `rwkv_app`.

## Proposed next step

Adopt the audited semantic core through a new strict record format, target-specific authority map, stable assertion IDs, Dart checker, relationship graph validation, and CI integration.

## Resolution

`DEC-20260723-ADAPT-SPEC-SYNC-V17` approved the adapted v1.7 design and its target-specific implementation.
