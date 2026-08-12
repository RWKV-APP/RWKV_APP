# Specification Source Inventory

Process version: v1.8
Effective date: 2026-08-10
Last reviewed: 2026-08-10

This inventory lists the checked-in surfaces used to resolve product truth, implementation ownership, drift, and delivery evidence. Inclusion does not make a file canonical; use `docs/specs/01-authority-map.md` for the single owner of each topic.

## Process And Authority

- `docs/specification.md`: canonical repository entrypoint and active cross-topic product boundaries
- `docs/specs/01-authority-map.md`: canonical topic, lifecycle, stable assertion ID, and owner registry
- `docs/specs/02-repository-map.md`: canonical repository aliases used in cross-repository references
- `docs/spec-process/rules.md`: canonical Specification flow mechanics and state model
- `docs/spec-process/templates.md`: strict front-matter and body templates
- `SPEC-LOOP.md`: derived workflow explanation
- `.agents/skills/spec-sync/SKILL.md`: derived Codex execution workflow
- `.agents/skills/spec-sync/agents/openai.yaml`: skill discovery metadata
- `AGENTS.md` and `.github/copilot-instructions.md`: synchronized repository instructions
- `docs/plans/PLANS.md`: historical checked-in execution-plan archive contract; new Root-routed plans stay in the private Root Mission

## Record And Evidence Surfaces

- Private Root Mission and Result records: current request provenance, plans, rulings, conflicts, delivery evidence, and combined acceptance
- `docs/product-inputs/YYYY-MM-DD/PI-*.md`: read-only pre-v1.8 input archive; no new records for Root-routed work
- `docs/product-inputs/evidence/2026-07-23-geo-ai-spec-v16-core-manifest.md`: reproducible historical source-core provenance for the Specification migration
- `docs/spec-process/decisions/DEC-*.md`: pre-v1.8 explicit ruling history
- `docs/spec-process/observations/OBS-*.md`: pre-v1.8 workflow or product drift observations
- `docs/spec-process/conflicts/current/CF-*.md`: unresolved historical semantic conflicts
- `docs/spec-process/conflicts/resolved/CF-*.md`: resolved historical conflict archive
- `docs/spec-process/acceptance-records/ACC-*.md`: historical delivery-time acceptance snapshots
- `docs/spec-process/changelog.md`: Specification process version history
- `docs/spec-process/eval-cases.md`: workflow behavior examples

## Canonical Product And Engineering Owners

- `PRODUCT.md`: product users, purpose, personality, design principles, and accessibility intent
- `pubspec.yaml`: Flutter and Dart baseline plus app package version
- `docs/architecture/workspace-map.md`: repository and symptom-to-entry ownership
- `docs/architecture/store-map.md`: Riverpod store ownership and verification pointers
- `docs/architecture/vl-model-update-guide.md`: VL model configuration/display update contract
- `docs/contracts/model_quantization_catalog.md`: catalog-driven model quantization and application acceptance contract
- `docs/contracts/app_distribution.md`: App binary publication channels, provider parity, and release authorization boundary
- `docs/agentic-evaluation/eval-spec-v0.1.md`: Agentic Evaluation protocol
- `docs/contracts/local_agent_file_actions.md`: user-authorized Windows local Agent file CRUD contract
- `docs/contracts/desktop_ui_redesign.md`: scoped desktop UI redesign authorization
- `docs/contracts/multi_question_parallel.md`: normalized multi-question parallel behavior contract

## Derived Public Documentation

- `README.md`
- `docs/README.zh-hans.md`
- `docs/README.zh-hant.md`
- `docs/README.ja.md`
- `docs/README.ko.md`
- `docs/README.ru.md`
- `CONTRIBUTING.md` and its synchronized locale files
- `docs/privacy_policy.html`
- `rwkv_org_profile:profile/README.md`: public RWKV-APP organization profile copy
- `rwkv_org_profile:profile/assets/hero.svg`: desktop organization-profile hero artwork
- `rwkv_org_profile:profile/assets/hero-mobile.svg`: mobile organization-profile hero artwork

## Implementation And Runtime Truth

- `lib/`: Flutter UI, Riverpod state, local services, data access, routing, and app workflows
- `assets/`: bundled model configuration, Agent cases, API dashboard, and app assets
- `remote/latest.json`: current remote model/download metadata
- `test/`: app regression tests
- `packages/local_web_search/`: local web search package and tests
- `tools/`: repository checks, evaluation utilities, asset helpers, and Specification checker
- `.github/workflows/`: CI and platform build workflows
- `android/`, `ios/`, `macos/`, `windows/`, and `linux/`: platform build surfaces

## Lifecycle Notes

- The Agentic Evaluation specification is active for its named evaluation workflow
- RWKV App quantization starts from the live `remote/latest.json` artifact matrix; converter and host tooling follow the selected catalog cohort
- Local Agent file actions are active in Windows Debug ordinary chat and remain separate from deterministic Agentic Evaluation scoring
- Desktop UI redesign is authorized; detailed reference sets, feature scope, Projects, Agent expansion, and visual acceptance proposals remain outside this repository until explicitly promoted
- The multi-question document records an implemented feature family but must still be compared with current code before delivery claims
- New raw intake, historical requirement narratives removed by explicit ruling, and unresolved proposals are owned by the private Root Harness rather than this repository; retained pre-v1.8 PI records remain read-only provenance
- App-level RWKV Chat acceptance uses the canonical product identity and persistence namespace; alternate-ID or separately sandboxed acceptance Apps are prohibited
- New Root-routed work does not extend the historical PI, DEC, OBS, CF, ACC, or checked-in plan archives
- Runtime model names, versions, download URLs, service endpoints, and platform support can drift; consult their canonical or runtime owner instead of copying them into broad Specification prose
