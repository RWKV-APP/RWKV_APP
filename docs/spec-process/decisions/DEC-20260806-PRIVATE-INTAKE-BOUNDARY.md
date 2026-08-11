---
id: DEC-20260806-PRIVATE-INTAKE-BOUNDARY
type: decision
date: 2026-08-06
status: approved
approved_by: user
inputs:
  - PI-20260806-RWKV-APP-PRIVATE-INTAKE-BOUNDARY
observations:
  - OBS-20260806-RAW-INPUT-REPOSITORY-BOUNDARY
conflicts: []
supersedes: []
superseded_by: []
acceptance_records:
  - ACC-20260806-PRIVATE-INTAKE-BOUNDARY
canonical_assertions:
  - SPEC-SYNC-PRIVATE-INTAKE-BOUNDARY
affected_surfaces:
  - docs/spec-process/rules.md
  - docs/specification.md
  - SPEC-LOOP.md
  - AGENTS.md
  - .agents/skills/spec-sync/SKILL.md
  - tools/lib/specification/specification_checker.dart
---

# Keep raw RWKV App input in the private Root Harness

## Decision

Raw and near-raw user or stakeholder input is owned by the private Root Harness
and must not be stored in the RWKV App repository. RWKV App retains only the
normalized product and technical contracts, decisions, observations, conflicts,
and acceptance evidence needed to own its project truth.

## Reason

The user explicitly rejected committing source-like requirement material to the
RWKV App remote and directed that it be migrated to the Harness. Separating
private intake from normalized project truth preserves both privacy and project
authority without losing traceability.
