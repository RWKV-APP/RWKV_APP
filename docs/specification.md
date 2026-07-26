# RWKV App Specification

Process version: v1.7
Last reviewed: 2026-07-23

This is the canonical entrypoint for product and process truth in `rwkv_app`.

When the user says `Specification flow` or `Specification`, treat that wording as this repository's specification synchronization and self-evolution workflow unless the surrounding request clearly names another artifact. Read this file, `docs/specs/01-authority-map.md`, the relevant canonical owner, and current conflicts before changing product behavior.

## Current Truth Sources

- Topic ownership and stable assertion IDs: `docs/specs/01-authority-map.md`
- Repository aliases for cross-repository delivery surfaces: `docs/specs/02-repository-map.md`
- Specification source inventory: `docs/specs/00-inventory.md`
- Canonical process mechanics and state model: `docs/spec-process/rules.md`
- Strict record templates: `docs/spec-process/templates.md`
- Derived workflow explanation: `SPEC-LOOP.md`
- Executable agent guidance: `.agents/skills/spec-sync/SKILL.md`
- Raw product and process input: `docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md`
- Current semantic conflicts: `docs/spec-process/conflicts/current/`
- Product identity and design principles: `PRODUCT.md`

Each topic has one canonical owner. Repeated wording in README files, implementation, runtime data, tests, product inputs, observations, decisions, conflicts, Git history, or acceptance records remains a drift or evidence surface unless the authority map names it as the owner.

## SPEC-RWKV-PRODUCT-SCOPE — Product Scope

RWKV App lets people download, run, evaluate, and compare RWKV models on phones and desktop computers. The app supports chat, speech, vision and OCR, local model management, local API workflows, performance and Agent evaluation, and an explicit Web Demo surface.

The supported application platforms are Android, iOS, Windows, macOS, and Linux. Platform availability of a specific model, backend, or feature remains governed by its narrower canonical owner and current implementation.

## SPEC-RWKV-REPOSITORY-BOUNDARIES — Repository Ownership

This repository owns the Flutter application, routes, Riverpod state, local persistence, model selection, local API UI, user-facing workflows, app packaging, and repository-level release automation.

The `rwkv_mobile_flutter` repository owns the Flutter adapter and FFI bridge. The `rwkv_mobile` repository owns native inference-engine internals. The `app_website` repository owns the public download website and its HTTP services. Cross-repository requirements define the integration contract here while each external repository remains authoritative for its own implementation.

## SPEC-RWKV-INFERENCE-BOUNDARY — Local And Connected Execution

Loaded local model inference runs on the user's device through CPU, GPU, or NPU backends and uses device memory or unified memory.

Local inference does not imply that every app feature is offline. Model downloads, remote model configuration, links, and other explicitly approved connected workflows can use the network. Product copy and acceptance must distinguish on-device inference from connected features and must follow each narrower data-flow assertion.

## SPEC-RWKV-TELEMETRY-PRIVACY-CONTRACT — Telemetry Privacy Contract

The current checked-in public policy says the app does not collect device information or track usage. Until an explicit approved decision supersedes that policy, telemetry must not transmit installation, device, model, usage, or performance data.

The current telemetry implementation does not comply with that active contract. The mismatch is recorded as `OBS-20260723-TELEMETRY-PRIVACY-DRIFT`; implementation state does not silently redefine the product rule. Correcting runtime behavior or approving a different collection and disclosure contract is outside this Specification-infrastructure migration and requires a separately reviewed product change.

## SPEC-RWKV-WEB-DEMO-DATA-FLOW — Cloud Web Demo Data-Flow Contract

The public contract for cloud Web Demo prompt transmission is currently unresolved under `CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW`.

Until that conflict receives an explicit ruling:

- do not add or strengthen absolute claims that every app workflow has no servers or never transmits data
- do not remove or expand cloud Web Demo transmission solely to choose a side
- keep changes unrelated to that narrow conflict moving
- inspect the privacy policy, localized product copy, Web Demo request path, and any user controls together when the user decides

The non-auditable dynamic policy date is separately recorded in `OBS-20260723-PRIVACY-POLICY-DATE`.

## SPEC-RWKV-PRIVACY-POLICY-METADATA — Privacy Policy Revision Provenance Proposal

No active canonical rule for the privacy policy revision date was found during migration. The current page computes “Last updated” from the viewer's date, and `OBS-20260723-PRIVACY-POLICY-DATE` records why that is not auditable.

The proposed future contract is to show a fixed date that identifies when the displayed policy text was actually approved or changed. This proposal does not authorize a page change. It becomes active only after an explicit human decision establishes the real revision date and approves the rule.

## SPEC-RWKV-VERIFICATION-BOUNDARY — Delivery Verification

Static analysis, unit tests, widget tests, builds, and deterministic scripts prove the engineering properties they cover. They do not by themselves prove real-model quality, real-device behavior, cross-platform usability, connected-service behavior, visual quality, or semantic correctness.

The root Codex agent delivering a task must inspect the combined diff and personally review representative outcomes at the level a user consumes them. For work that crosses the Flutter app, adapter, native engine, or website, verify every relevant repository and representation within the authorized scope.

## Product Input Policy

Product and process input is recorded under `docs/product-inputs/YYYY-MM-DD/` before or alongside the canonical update it authorizes. Split assertions that may evolve independently. Preserve the meaningful raw wording while redacting credentials, signed links, personal data, and machine-local attachment paths.

Use `docs/spec-process/templates.md` and run:

```bash
dart run tools/bin/check_specification.dart
```

An unresolved semantic contradiction belongs under `docs/spec-process/conflicts/current/`. Pause only the behavior named by its blocking scope and ask for the ruling recorded in its `Required decision` section.
