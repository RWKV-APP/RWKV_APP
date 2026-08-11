---
id: ACC-20260806-PRIVATE-INTAKE-BOUNDARY
type: acceptance
date: 2026-08-06
owner: root Codex agent
inputs:
  - PI-20260806-RWKV-APP-PRIVATE-INTAKE-BOUNDARY
decisions:
  - DEC-20260806-PRIVATE-INTAKE-BOUNDARY
canonical_assertions:
  - SPEC-SYNC-PRIVATE-INTAKE-BOUNDARY
changed_surfaces:
  - AGENTS.md
  - SPEC-LOOP.md
  - .agents/skills/spec-sync/SKILL.md
  - .agents/skills/spec-sync/agents/openai.yaml
  - docs/specification.md
  - docs/specs/00-inventory.md
  - docs/specs/01-authority-map.md
  - docs/specs/02-repository-map.md
  - docs/spec-process/rules.md
  - docs/spec-process/templates.md
  - docs/spec-process/changelog.md
  - docs/spec-process/eval-cases.md
  - docs/spec-process/acceptance-records/README.md
  - docs/spec-process/decisions/DEC-20260806-PRIVATE-INTAKE-BOUNDARY.md
  - docs/spec-process/observations/OBS-20260806-RAW-INPUT-REPOSITORY-BOUNDARY.md
  - docs/architecture/workspace-map.md
  - docs/contracts/desktop_ui_redesign.md
  - docs/contracts/local_agent_file_actions.md
  - docs/contracts/model_quantization_catalog.md
  - docs/contracts/multi_question_parallel.md
  - tools/lib/specification/specification_checker.dart
  - tools/test/specification_checker_test.dart
unresolved_conflicts: []
result: partial
supersedes_acceptance: []
superseded_by: []
---

# Private Root intake boundary migration

## Mechanical evidence

- The App audit found zero files under `docs/product-inputs/` and zero files
  under `docs/requirements/`.
- The private Root archive contains 41 retained files, including the migration
  index and 32 opaque `PI-*` source records.
- `dart test test/specification_checker_test.dart` passed all 70 tests from the
  `tools` package.
- Dart formatting reported no changes for the checker and its focused test.
- Relevant App and Root `git diff --check` invocations passed.

## Requirement review

Raw and near-raw input is no longer stored in the RWKV App repository. Legacy
inputs and proposal narratives are retained privately by the Root Harness.
RWKV App now exposes normalized active contracts and its agent workflow forbids
recreating a local product-input tree.

The checker accepts opaque private `PI-*` references when no local input records
exist, while retaining strict legacy parsing for migration review. Historical
project records can preserve removed source paths and external surfaces without
making those paths current authority.

## Semantic or visual review

This migration has no rendered UI surface. The root review inspected the
archive counts, App absence checks, current contract set, process instructions,
checker behavior, and focused test results.

## Exclusions

- Full repository-wide acceptance remains outside this migration-specific
  record, so the result stays partial.
- No commit, push, publication, package, deployment, or remote mutation was
  performed.
