# RWKV App Specification

Process version: v1.8
Last reviewed: 2026-08-28

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
- Root-routed request provenance and combined acceptance: private Root Harness Mission and Result records, never copied into this repository
- Historical project input and process records: `docs/product-inputs/` and `docs/spec-process/`, retained read-only for pre-v1.8 provenance
- Current semantic conflicts: `docs/spec-process/conflicts/current/`
- Product identity and design principles: `PRODUCT.md`

Each topic has one canonical owner. Repeated wording in README files, implementation, runtime data, tests, product inputs, observations, decisions, conflicts, Git history, or acceptance records remains a drift or evidence surface unless the authority map names it as the owner.

## SPEC-RWKV-PRODUCT-SCOPE — Product Scope

RWKV App lets people download, run, evaluate, and compare RWKV models on phones and desktop computers. The app supports chat, speech, vision and OCR, local model management, local API workflows, performance and Agent evaluation, and an explicit Web Demo surface.

The supported application platforms are Android, iOS, Windows, macOS, and Linux. Platform availability of a specific model, backend, or feature remains governed by its narrower canonical owner and current implementation.

RWKV App quantization is governed by `SPEC-RWKV-QUANTIZATION-CATALOG-CONTROL` and `SPEC-RWKV-QUANTIZATION-DELIVERY`. Work begins with the live `remote/latest.json` artifact matrix and its application consumers; converter libraries and host accelerators are selected from the required catalog cohort and are not inferred as product targets from the word quantization.

The explicit human rulings on 2026-08-22 authorize formal G1i CoreML publication for 1.5B and 2.9B on macOS and iOS, followed by a separate macOS-only formal partial release of the accepted 7.2B artifact. Promote each exact accepted cohort through immutable TMP identity to formal ModelScope and byte-identical Hugging Face, verify both providers anonymously, then expose source-selectable formal rows in the bundled and production `latest.json` plus production `752.json` so RWKV Chat 4.7.0 and 4.7.1 can discover and download them. The formal G1i 1.5B and 2.9B rows fully replace the matching G1f CoreML consumer slots, so current bundled and production 4.7.0/4.7.1 catalogs omit those superseded G1f rows while historical build-743/build-750 snapshots and legacy provider bytes remain unchanged. This is a backend-scoped partial release: retained macOS runtime and performance evidence supports the artifact selection, while exact-device iOS load, generation, cache, memory, and performance acceptance remains unverified and cannot be inferred from catalog availability. Existing required G1i MediaTek rows retain their independent runtime status, so the delivery is not a standard complete Chat weight release. The 7.2B row declares only `macos`; it remains absent from iOS. Its package is backward-compatible with the released 4.7.0 and 4.7.1 CoreML config parser, but those released native runtimes ignore the new Decode and Prefill compute-unit hints and continue to load both functions with CPU and Neural Engine. The measured 7.2B CPU-and-GPU Decode improvement therefore requires a later App/runtime release and must not be claimed for 4.7.0 or 4.7.1 merely because their catalogs can download the formal artifact. G1i CoreML 13.3B remains a local Debug canary outside formal and online publication and remains excluded from iOS.

The Windows Debug App includes ordinary-chat real local Agent file actions governed by `SPEC-RWKV-LOCAL-AGENT-FILE-ACTIONS`. A clear natural-language file request can trigger workspace authorization, in-chat review of every mutation, and a verified assistant result. This workflow remains separate from deterministic Agentic Evaluation scoring.

Desktop UI redesign is authorized by `SPEC-RWKV-DESKTOP-UI-REDESIGN-AUTHORIZATION` in `docs/contracts/desktop_ui_redesign.md`. Detailed Chat-first layout, Projects, Agent UI expansion, reference-product comparisons, and visual acceptance proposals remain private intake until explicit rulings promote a normalized project contract.

## SPEC-RWKV-REPOSITORY-BOUNDARIES — Repository Ownership

This repository owns the Flutter application, routes, Riverpod state, local persistence, model selection, local API UI, user-facing workflows, app packaging, and repository-level release automation.

The `rwkv_mobile_flutter` repository owns the Flutter adapter and FFI bridge. The `rwkv-mobile` repository owns native inference-engine internals. The former sibling checkout named `rwkv_mobile` is retired and is not an integration dependency or fallback. The `app_website` repository owns the public download website and its HTTP services. Cross-repository requirements define the integration contract here while each external repository remains authoritative for its own implementation.

App binary publication across GitHub Release, Hugging Face, ModelScope, and the
public download website is governed by `SPEC-RWKV-APP-BINARY-DISTRIBUTION` in
`docs/contracts/app_distribution.md`.

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

## SPEC-RWKV-MODEL-PARAMETER-HELP — Model Settings Parameter Help

Model settings display an accessible information button beside Temperature,
Top P, Presence Penalty, Frequency Penalty, Penalty Decay, and Max Length.
Desktop users can hover, click, or activate the button from the keyboard to
read a tooltip, and dismiss it with Escape or an outside click. Android and
iOS users tap the button to read a scrollable bottom sheet with a close action
and safe-area padding. Closing help preserves the settings panel and values.

Each explanation states what the parameter controls and how higher and lower
values affect generation, using plain language in every supported locale.
Penalty Decay explains that values closer to 1 retain repetition penalties
longer. Max Length is a generated-token ceiling, including generated thinking
tokens, rather than a character count or a guaranteed response length. Help
does not promise factual accuracy, alter sampling, or change the existing
Apply, Cancel, and Reset behavior. Section labels identify reasoning mode in
the selected language.

## SPEC-RWKV-CHAT-SAME-APP-ACCEPTANCE — RWKV Chat Acceptance Uses One App Identity

Every App-level RWKV Chat acceptance must use the canonical RWKV Chat product
name, display name, application or bundle identifier, persistence namespace,
and user-consumed App surface for the target platform.

Do not create, rename, or retain an acceptance-only App, alternate bundle or
application identifier, parallel sandbox, or separate cache and local-storage
namespace solely for acceptance. Test catalogs, unpublished artifacts, prompts,
and instrumentation must enter through supported paths inside that same App
identity.

Preserve pre-existing conversations, settings, caches, downloaded models, and
other user state unless the current acceptance explicitly requires a bounded
change. A destructive reset requires separate approval. If same-App acceptance
cannot protect existing state safely, stop and request direction instead of
changing App identity.

Unit, widget, CLI, converter, and engine checks remain mechanical evidence; they
do not substitute for App-level proof through the user-consumed RWKV Chat App.

## SPEC-RWKV-CHAT-VISIBLE-UI-E2E-ACCEPTANCE — App Acceptance Requires Visible UI End To End

Every RWKV Chat App, device, model download, model-runtime, and performance
acceptance must execute through the canonical App's real, visible,
user-interactive UI from the first user action to the asserted result. The
evidence must show the user-facing model list or control, the UI action that
selects or starts the operation, visible progress or state transitions, and the
final UI outcome. A test that only launches the App without exercising the
relevant UI is not acceptance.

Do not use a hidden background runner, acceptance-only startup hook,
command-line model selection, direct store call, direct engine call, or
auto-exiting instrumentation path to perform App acceptance. Unit, widget,
static, CLI, build, and engine checks may support engineering diagnosis, but
they remain mechanical evidence and cannot replace or be reported as App,
device, runtime, download, or performance acceptance.

If the canonical App UI cannot be both controlled and observed end to end on
the selected device, refuse the requested test and state the exact UI,
automation, device, signing, permission, or observability blocker. Do not
silently fall back to a hidden runner or claim partial background execution as
the requested test.

## SPEC-SYNC-PRIVATE-INTAKE-BOUNDARY — Private Source Intake Boundary

New raw user wording, copied stakeholder communication, attachments, and other near-source material are retained only by the private Root Harness. Do not create a new `docs/product-inputs/` record or copy new private source bodies, private paths, or unnecessary personal context into this repository.

RWKV App keeps the normalized product and technical truth it owns. An existing
historical project input, decision, observation, conflict, or acceptance record may
retain an opaque source ID for traceability, but it must be independently
understandable from its project-safe assertions, surfaces, and evidence.

`docs/spec-process/templates.md` defines validation for the historical target
record archive. Run:

```bash
dart run tools/bin/check_specification.dart
```

Historical target conflicts remain under `docs/spec-process/conflicts/`.
New Root-routed contradictions stay in the private Root Mission while target
canonical truth remains unchanged.

## SPEC-SYNC-ROOT-INTAKE-BOUNDARY — Root-Routed Input Retention

Every RWKV request is first captured in a private Root Harness Mission. Raw
wording, copied chat, voice transcripts, redactions, per-task Changes briefs,
execution plans, rulings, conflict provenance, and combined acceptance stay in
Root Source, Mission, Result, and Specification-record surfaces.

A Root-routed task must not add `docs/product-inputs/`, Changes Markdown, a
standalone task brief, a checked-in request plan, or a new PI, DEC, OBS, CF, or
ACC record to this repository.

This boundary does not remove target authority. RWKV App continues to own
canonical Specification, source code, tests, architecture, and required
durable product documentation. Existing v1.7 PI, DEC, OBS, CF, and ACC files
remain a validated read-only historical archive and are neither bulk-deleted
nor extended for new Root Missions.
