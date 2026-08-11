---
id: OBS-20260806-RAW-INPUT-REPOSITORY-BOUNDARY
type: observation
date: 2026-08-06
status: resolved
inputs:
  - PI-20260806-RWKV-APP-PRIVATE-INTAKE-BOUNDARY
conflicts: []
decision: DEC-20260806-PRIVATE-INTAKE-BOUNDARY
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

# Raw input was retained in the RWKV App repository

## Observation

The checked-in workflow required raw or near-raw user and stakeholder wording
to be stored under `docs/product-inputs/`. Several unresolved proposal and
historical requirement narratives also remained beside active product truth.

## Implication

Following that workflow would place private intake in the RWKV App repository
and make it eligible for an App-remote commit, contrary to the current source
ownership and disclosure boundary.

## Proposed next step

Move source-like material to the private Root Harness, retain only normalized
project contracts in RWKV App, and make the checker accept opaque private input
references without a local product-input tree.

## Resolution

Resolved by `DEC-20260806-PRIVATE-INTAKE-BOUNDARY` and the synchronized process,
contract, skill, and checker changes.
