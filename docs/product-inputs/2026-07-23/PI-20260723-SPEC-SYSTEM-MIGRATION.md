---
id: PI-20260723-SPEC-SYSTEM-MIGRATION
type: product_input
captured_date: 2026-07-23
source_date: 2026-07-23
source: current user request
category: process
status: merged
effective_status: active
delivery_status: verified
canonical_assertions:
  - SPEC-SYNC-CLASSIFICATION
  - SPEC-SYNC-AUTHORITY
  - SPEC-SYNC-STATE-MODEL
  - SPEC-SYNC-CONFLICTS
  - SPEC-SYNC-ACCEPTANCE
  - SPEC-SYNC-ACCEPTANCE-GUARDRAILS
  - SPEC-SYNC-AUTHORITY-MAP
  - SPEC-SYNC-EXECUTION-PLANS
delivery_surfaces:
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
  - tools/bin/check_specification.dart
  - tools/bin/agent_check.dart
  - tools/lib/specification/specification_checker.dart
  - tools/README.md
  - tools/test/specification_checker_test.dart
conflicts: []
supersedes: []
superseded_by: []
decisions:
  - DEC-20260723-ADAPT-SPEC-SYNC-V17
acceptance_records:
  - ACC-20260723-SPEC-SYNC-V17-MIGRATION
---

# Migrate and improve the Specification system

## Raw statement

> /goal 这边给你一个长程任务吧，我期望你完全理解一下 ../geo 这个项目中的 Specification system，并且把这个项目中的 Specification system 迁移至当前项目。而且我还期望就是你在迁移过程中，如果遇到有哪些不合理的东西，然后你要修改，并不能，并不要原封不动地照抄
>
> 帮我实现一下
>
> 后遇到有什么疏漏的地方，你也请修改一下

The referenced sibling repository was resolved to the existing `../geo-ai` repository after checking the workspace.

## Extracted assertions

- Understand the complete source Specification system before implementation
- Migrate the workflow into `rwkv_app`
- Adapt it to the target repository instead of copying source-specific assumptions
- Correct unreasonable source design and omissions found during migration
- Complete the implementation and repair further omissions discovered during verification
