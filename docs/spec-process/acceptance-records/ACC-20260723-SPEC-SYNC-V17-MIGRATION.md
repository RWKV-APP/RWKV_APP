---
id: ACC-20260723-SPEC-SYNC-V17-MIGRATION
type: acceptance
date: 2026-07-23
owner: root Codex agent
inputs:
  - PI-20260723-SPEC-SYSTEM-MIGRATION
decisions:
  - DEC-20260723-ADAPT-SPEC-SYNC-V17
canonical_assertions:
  - SPEC-SYNC-CLASSIFICATION
  - SPEC-SYNC-AUTHORITY
  - SPEC-SYNC-STATE-MODEL
  - SPEC-SYNC-CONFLICTS
  - SPEC-SYNC-ACCEPTANCE
  - SPEC-SYNC-ACCEPTANCE-GUARDRAILS
  - SPEC-SYNC-AUTHORITY-MAP
  - SPEC-SYNC-EXECUTION-PLANS
changed_surfaces:
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
unresolved_conflicts:
  - CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
result: accepted
supersedes_acceptance: []
superseded_by: []
---

# Specification v1.7 migration acceptance

## Mechanical evidence

- The audited source was `geo-ai` base revision `9c3b088c1beb9ca1b4aae76b7055c18fb6b1126a` plus its visible uncommitted v1.6 working tree
- The 19-file source-core manifest recomputed to SHA-256 `13edab8abde22126129bba29540712367525a7dde188d8ea9d11ed119ce5616e`
- Source `pnpm check:spec-loop` passed and source `pnpm test:spec-loop` passed 28 of 28 tests
- Target Dart formatting checked four Specification-related files with zero changes
- `dart analyze` in `tools/` reported no issues and the complete tools suite passed 69 of 69 tests, including 68 Specification checker tests
- The checker passed through the repository-root CLI, the `tools/ --root ..` CI form, and `agent_check.dart --spec-only`
- Repository `dart analyze` reported no issues and `flutter test` passed 323 of 323 tests
- The full `dart run tools/bin/agent_check.dart` integration path passed the Specification graph, analysis, Flutter tests, and non-blocking rule scan
- The rule scan reported 29 historical warnings in untouched application files and no warning in this migration's Dart files
- The repository skill validator reported `Skill is valid!`; Agent instruction mirror content matched; `docs/` contained no generated `.dart_tool`
- Two independent final reviews found no remaining P0, P1, or necessary P2 issue after graph, path, secret-redaction, and documentation consistency fixes
- The target work started from revision `11921eacf30881cb2bb24568d988069abbffb7f5`; the working tree remains intentionally uncommitted under repository policy

The Web Demo conflict was identified before this final acceptance on the same calendar day, so it is included in the snapshot for visibility. Its blocking scope does not overlap the accepted process assertions.

## Requirement review

The migration preserves the source system's useful separation of raw input, canonical ownership, delivery truth, semantic conflict, provenance, and root-owned acceptance. The root review traced the complete source workflow, checker, tests, working-tree provenance, and state-hardening changes before comparing them with the target repository.

The target implementation deliberately changes source mechanics that were unsafe or source-specific:

- strict per-file front matter replaces aggregate Markdown ledgers and prevents copied body text from becoming metadata
- stable `SPEC-*` IDs, unique authority ownership, explicit lifecycle, `pending`, `blocked`, and a strict state matrix replace ambiguous topic and delivery state
- required backlinks, related-source coverage, decision coverage, three-generation supersession, chronology, cycles, and independent acceptance coverage close record-graph gaps
- Dart-native root discovery, optional repository aliases, symlink and realpath containment, CI integration, and Windows-aware Agent mirroring replace Node, pnpm, current-directory, and single-platform assumptions
- high-confidence secret scanning and global diagnostic redaction cover records and supporting evidence without echoing detected values
- exact active assertions and independent holdout review prevent acceptance preference or one sample from creating product restrictions

The target authority map routes existing product, architecture, evaluation, model, and cross-repository surfaces without importing GEO business records or runtime assumptions. README toolchain and Linux support wording were synchronized with the active `pubspec.yaml` baseline. The migration also recorded observed privacy and telemetry drift without silently changing product behavior.

## Semantic or visual review

The root agent inspected the combined source-to-target mapping, all changed and added files, the complete record graph, authority owners and anchors, checker and regression fixtures, CI entrypoint, Agent skill, localized README edits, privacy policy wording, telemetry call path, and cloud Web Demo request path.

Representative outcome review used the checker against the real repository from both supported command forms and exercised malformed metadata, invalid state combinations, unrelated graph links, three-generation history, stale or incomplete acceptance, secret families, diagnostic no-echo behavior, record and directory symlinks, and alias realpath escapes through the passing test suite.

No Flutter UI, model behavior, network runtime, or rendered visual was changed. Visual, real-model, real-device, and connected-service acceptance are therefore not applicable to the delivered Specification infrastructure.

## Exclusions

- No product ruling was made for `CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW`; cloud Web Demo transmission and public disclosure remain unresolved
- `OBS-20260723-TELEMETRY-PRIVACY-DRIFT` remains open; telemetry runtime was not changed
- `OBS-20260723-PRIVACY-POLICY-DATE` remains open; the policy page was not edited
- No optional sibling repository implementation was modified
- No Git commit, push, deployment, real-device run, or real-model run was performed
