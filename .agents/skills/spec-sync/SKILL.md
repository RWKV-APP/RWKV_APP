---
name: spec-sync
description: Synchronize a private Root Harness Delivery Contract into rwkv_app canonical product or process truth before implementation, without storing request-provenance Markdown in the target repository. Use when the user mentions Specification or Specification flow, provides product behavior, API or model expectations, UI rules, acceptance criteria, copied stakeholder messages, voice-transcribed requirements, cross-repository contracts, or requests a change to the Specification process itself.
---

# Spec Sync

Turn the sanitized Root Delivery Contract into checked-in canonical project
truth before changing behavior. Request provenance remains in the private Root
Harness.

## Read First

1. Read `docs/specification.md`
2. Read `docs/specs/00-inventory.md`
3. Read `docs/specs/01-authority-map.md`
4. Read the relevant canonical owner and its required drift surfaces
5. Search the exact relevant `SPEC-*` IDs under canonical owners, historical `docs/product-inputs/`, and `docs/spec-process/`, then read only the connected historical PI, DEC, OBS, CF, and ACC records needed to understand project provenance, supersession, and current delivery state
6. Read all records under `docs/spec-process/conflicts/current/`
7. Read `docs/spec-process/rules.md` when the input affects this workflow

Do not read every historical record when exact-ID search identifies the relevant
graph. Use repository aliases from `docs/specs/02-repository-map.md` for
cross-repository references. Do not store machine-local absolute paths as
durable links.

Memory can help locate context, but it cannot override checked-in
Specification. Verify remembered facts that may have changed against the
current owner and delivery surfaces.

## Classify The Request

- `product`: user-visible behavior, API contract, model or Prompt behavior, UI rules, privacy/data-flow promises, acceptance criteria, or stakeholder wording
- `process`: Specification structure, state, authority, conflict handling, verification, or agent behavior
- `mixed`: independently meaningful product and process assertions
- `implementation-only`: mechanics that preserve current canonical behavior
- `general chat`: explanation or brainstorming with no request to change project truth

Handle product, process, or mixed input before implementation. Under
`SPEC-SYNC-ROOT-INTAKE-BOUNDARY`, none of these classes creates target-side
request-provenance Markdown for a Root-routed task.

## Use Root Mission Intake

1. Confirm that the private Root Harness captured the source in a Mission and dispatched the smallest useful Delivery Contract
2. Keep raw wording, copied chat, voice transcription, redactions, per-task Changes notes, planning, conflict provenance, and delivery evidence in that Root Mission
3. Do not create a new `docs/product-inputs/` record, Changes Markdown, standalone task brief, checked-in request plan, or PI/DEC/OBS/CF/ACC record for Root-routed work
4. Remove credentials, tokens, signed URLs, personal data, machine-local attachment paths, private motivation, and unnecessary source wording from target-safe material
5. Extract concise shareable assertions, identify stable `SPEC-*` IDs, and identify target-owned delivery surfaces
6. Compare those assertions with the current canonical owner and applicable historical conflicts

If a request reaches this repository without a Root Mission, return it to the
Root Harness before target mutation. Existing project PI, DEC, OBS, CF, and ACC
files remain a strict read-only historical archive; do not bulk-delete or
extend it for new Root-routed work.

## Merge Or Record A Conflict

For a compatible assertion:

1. Update the canonical owner first
2. Synchronize required derived, implementation, runtime, and durable product documentation surfaces
3. Track current effect, validation, and acceptance in the Root Mission Result

For a semantic conflict:

1. Record the competing assertions, stable `SPEC-*` IDs, affected surfaces, and narrow blocking scope in the private Root Mission
2. Leave target canonical truth unchanged while the ruling is unresolved
3. Stop only behavior changes that depend on the unresolved assertion
4. Ask the user for the exact ruling needed through the Root task

Implementation or derived-document drift against an unambiguous canonical
assertion is ordinary drift. Synchronize it without manufacturing a conflict.
Git history is provenance and sequence evidence; commit order alone cannot
resolve product ambiguity.

## Resolve And Supersede

After an explicit human ruling:

1. Record the ruling and supersession in the private Root Mission or Root Specification graph
2. Synchronize the target canonical owner and required drift surfaces
3. Preserve existing target-side historical records without creating a new request-provenance record

Only an explicit human ruling can resolve a semantic contradiction. A source
label, copied message, implementation state, Git order, or agent preference is
not human approval.

## Verify And Accept

Run the deterministic checker:

```bash
dart run tools/bin/check_specification.dart
```

Then run focused engineering checks required by the changed module and
`AGENTS.md`.

For app-level RWKV Chat acceptance, apply
`SPEC-RWKV-CHAT-SAME-APP-ACCEPTANCE`: keep the canonical product name,
application or bundle identifier, persistence namespace, and user-consumed app
surface. Never create a renamed or separately sandboxed acceptance app. If the
same-app path cannot protect existing user state, stop for explicit direction
instead of changing the app identity.

Also apply `SPEC-RWKV-CHAT-VISIBLE-UI-E2E-ACCEPTANCE` to every App, device,
model-download, model-runtime, and performance acceptance. Drive and observe
the complete operation through the real visible user-facing UI. A hidden
background runner, acceptance-only startup hook, command-line model selector,
direct store call, direct engine call, or merely launching the App is not
acceptance. If the selected device UI cannot be controlled and observed end to
end, refuse the test and report the exact blocker instead of silently falling
back to background execution.

The root Codex agent delivering the task owns final combined acceptance,
including delegated work. Automated checks, status codes, counts, screenshots,
model judges, and sub-agent reports are evidence only. For generated, parsed,
visual, device, model, network, or cross-repository behavior, personally inspect
representative real outcomes and all relevant representations.

Record combined acceptance in the Root Mission Result. Existing target-side
ACC files remain historical snapshots; do not create a new ACC merely to mirror
Root acceptance.

## SPEC-SYNC-ACCEPTANCE-GUARDRAILS

Before changing business logic, Prompt rules, normalization, validation, or
rejection behavior because a result looks wrong:

1. Name the exact active `SPEC-*` assertion and acceptance criterion being enforced
2. If none exists, record a Root observation and ask for a product ruling instead of inventing a restriction
3. Do not turn one sample or reviewer preference into a keyword blacklist, regular-expression rejection, or generalized prohibition
4. For a confirmed general defect, implement the narrow reusable rule and review the original case plus at least one independent holdout case
5. Record the evidence boundary and remaining unverified behavior in Root acceptance
