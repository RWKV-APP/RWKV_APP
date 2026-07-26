---
id: DEC-20260723-ADAPT-SPEC-SYNC-V17
type: decision
date: 2026-07-23
status: approved
approved_by: current user
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
observations:
  - OBS-20260723-SOURCE-SPEC-PORTABILITY-GAPS
conflicts: []
supersedes: []
superseded_by: []
acceptance_records:
  - ACC-20260723-SPEC-SYNC-V17-MIGRATION
canonical_assertions:
  - SPEC-SYNC-CLASSIFICATION
  - SPEC-SYNC-AUTHORITY
  - SPEC-SYNC-STATE-MODEL
  - SPEC-SYNC-CONFLICTS
  - SPEC-SYNC-ACCEPTANCE
  - SPEC-SYNC-ACCEPTANCE-GUARDRAILS
  - SPEC-SYNC-AUTHORITY-MAP
  - SPEC-SYNC-EXECUTION-PLANS
affected_surfaces:
  - .agents/skills/spec-sync/SKILL.md
  - .agents/skills/spec-sync/agents/openai.yaml
  - .github/copilot-instructions.md
  - .github/workflows/unit-tests.yml
  - AGENTS.md
  - PRODUCT.md
  - README.md
  - SPEC-LOOP.md
  - docs/README.ja.md
  - docs/README.ko.md
  - docs/README.ru.md
  - docs/README.zh-hans.md
  - docs/README.zh-hant.md
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - docs/albatross-http-api-requirements.md
  - docs/architecture/store-map.md
  - docs/architecture/vl-model-update-guide.md
  - docs/architecture/workspace-map.md
  - docs/plans/PLANS.md
  - docs/plans/2026-07-23-spec-system-migration.md
  - docs/product-inputs/2026-07-23/PI-20260723-SPEC-SYSTEM-MIGRATION.md
  - docs/product-inputs/README.md
  - docs/product-inputs/evidence/2026-07-23-geo-ai-spec-v16-core-manifest.md
  - docs/requirements/coding_agent_optimization.md
  - docs/requirements/multi_question_parallel.md
  - docs/requirements/rwkv_lightning_cuda_integration_plan.md
  - docs/spec-process/acceptance-records/ACC-20260723-SPEC-SYNC-V17-MIGRATION.md
  - docs/spec-process/acceptance-records/README.md
  - docs/spec-process/changelog.md
  - docs/spec-process/conflicts/README.md
  - docs/spec-process/conflicts/current/CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW.md
  - docs/spec-process/conflicts/resolved/README.md
  - docs/spec-process/decisions/DEC-20260723-ADAPT-SPEC-SYNC-V17.md
  - docs/spec-process/decisions/README.md
  - docs/spec-process/eval-cases.md
  - docs/spec-process/observations/OBS-20260723-PRIVACY-POLICY-DATE.md
  - docs/spec-process/observations/OBS-20260723-SOURCE-SPEC-PORTABILITY-GAPS.md
  - docs/spec-process/observations/OBS-20260723-TELEMETRY-PRIVACY-DRIFT.md
  - docs/spec-process/observations/OBS-20260723-WEB-DEMO-PRIVACY-CONFLICT.md
  - docs/spec-process/observations/README.md
  - docs/spec-process/rules.md
  - docs/spec-process/templates.md
  - docs/specification.md
  - docs/specs/00-inventory.md
  - docs/specs/01-authority-map.md
  - docs/specs/02-repository-map.md
  - pubspec.yaml
  - tools/README.md
  - tools/bin/agent_check.dart
  - tools/bin/check_specification.dart
  - tools/lib/specification/specification_checker.dart
  - tools/test/specification_checker_test.dart
---

# Adopt an adapted Spec Sync Loop v1.7

## Decision

Adopt a repository-native Spec Sync Loop v1.7 for `rwkv_app`.

Preserve the source workflow's separation of raw input, canonical truth, delivery, conflict, provenance, and acceptance. Replace aggregate record ledgers with one Markdown file per strict record, add stable `SPEC-*` IDs, add `pending` and `blocked` states, validate defined relationship and chronology rules, support repository-qualified references, and implement checks in Dart under `tools/`.

Use explicit local and CI commands as the portable enforcement path. Do not impose a repository-wide ban on hooks; permit unrelated hooks while prohibiting automation from silently changing canonical truth, approving decisions, resolving conflicts, or creating final acceptance. Detect durable machine-local evidence paths across supported desktop operating systems without rejecting harmless command examples.

Preserve the source acceptance guardrail that review preference cannot create product law. A behavior-changing repair must point to an exact active assertion; otherwise it becomes an observation and human question. A reusable fix derived from a confirmed defect must be reviewed on the original case and an independent holdout.

Do not migrate GEO business inputs, decisions, conflicts, acceptance history, pnpm commands, ports, backend/frontend paths, or deployment assumptions. Do not silently resolve genuine `rwkv_app` product conflicts discovered during the migration.

## Reason

The user explicitly requested a complete migration with corrections rather than a verbatim copy. The source audit found that the visible v1.6 system was still an uncommitted working-tree state and that its parser, state model, authority validation, cross-ledger links, acceptance chronology, path handling, working-directory behavior, and CI coverage had material gaps.

The target repository is Flutter/Dart, uses `tools/` for engineering helpers, has multiple sibling implementation repositories, and already has a Dart CI surface. v1.7 makes those facts part of the design while avoiding unrelated restrictions on future repository tooling.
