---
name: spec-sync
description: Synchronize product and process truth into the rwkv_app Specification before implementation. Use when the user mentions Specification or Specification flow, provides product behavior, API or model expectations, UI rules, acceptance criteria, copied stakeholder messages, voice-transcribed requirements, cross-repository contracts, or requests a change to the Specification process itself.
---

# Spec Sync

Turn product conversation into checked-in, traceable project truth before changing behavior.

## Read First

1. Read `docs/specification.md`
2. Read `docs/specs/00-inventory.md`
3. Read `docs/specs/01-authority-map.md`
4. Read the relevant canonical owner and its required drift surfaces
5. Search the exact relevant `SPEC-*` IDs under `docs/product-inputs/` and `docs/spec-process/`, then read the connected PI, DEC, OBS, CF, and ACC records needed to understand provenance, supersession, and current delivery state
6. Read all records under `docs/spec-process/conflicts/current/`
7. Read `docs/spec-process/rules.md` when the input affects this workflow

Do not read every historical record when exact-ID search identifies the relevant graph. Use repository aliases from `docs/specs/02-repository-map.md` for cross-repository references. Do not store machine-local absolute paths as durable links.

Memory can help locate context, but it cannot override checked-in Specification. Verify remembered facts that may have changed against the current owner and delivery surfaces.

## Classify The Request

- `product`: user-visible behavior, API contract, model or Prompt behavior, UI rules, privacy/data-flow promises, acceptance criteria, or stakeholder wording
- `process`: Specification structure, state, authority, conflict handling, verification, or agent behavior
- `mixed`: independently meaningful product and process assertions
- `implementation-only`: mechanics that preserve current canonical behavior
- `general chat`: explanation or brainstorming with no request to change project truth

Handle product, process, or mixed input before implementation. Do not create a product-input record for implementation-only work or general chat.

## Capture Product Or Process Input

1. Split assertions that can evolve independently into separate records
2. Create one record for each independently evolving assertion at `docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md`
3. Copy the meaningful raw wording under `## Raw statement`
4. Remove credentials, tokens, signed URLs, personal data, and machine-local attachment paths; mark each redaction explicitly
5. Extract concise assertions and identify stable `SPEC-*` IDs plus delivery surfaces
6. Compare the assertions with the current canonical owner and applicable conflicts

Use `docs/spec-process/templates.md` for record structure. Records are strict from the first day; do not create legacy-format entries.

## Merge Or Record A Conflict

For a compatible assertion:

1. Update the canonical owner first
2. Synchronize required derived, implementation, runtime, and evidence surfaces
3. Set the input to `merged`
4. Track current effect and delivery independently

For a semantic conflict:

1. Create `docs/spec-process/conflicts/current/CF-YYYYMMDD-SLUG.md`
2. Link the exact `PI-*` and/or `OBS-*` records in both directions
3. Name the competing assertions, stable `SPEC-*` IDs, affected surfaces, and narrow blocking scope
4. Set a directly conflicting input to `conflict + pending + blocked`
5. Stop only behavior changes that depend on the unresolved assertion
6. Ask the user for the exact ruling needed

Implementation or derived-document drift against an unambiguous canonical assertion is ordinary drift. Synchronize it without manufacturing a conflict. Git history is provenance and sequence evidence; commit order alone cannot resolve product ambiguity.

## Resolve And Supersede

After an explicit human ruling:

1. Create or update the `DEC-*` record, set `approved_by` to the explicit human decision authority, and use `approved` or `rejected` according to that ruling
2. Synchronize the canonical owner and required drift surfaces
3. Update affected input states
4. Link all supersession relationships in both directions
5. Move a resolved conflict from `conflicts/current/` to `conflicts/resolved/`
6. Preserve raw statements and historical acceptance snapshots

Use `dismissed + historical + not_applicable` for a rejected proposal that never became canonical. Use `merged + superseded` for a formerly canonical assertion that a later ruling replaced.

Only an approved decision can resolve an observation or conflict. A source label, copied message, implementation state, Git order, or Agent preference is not human approval.

## Verify And Accept

Run the deterministic checker:

```bash
dart run tools/bin/check_specification.dart
```

Then run focused engineering checks required by the changed module and `AGENTS.md`.

The root Codex agent delivering the task owns final combined acceptance, including delegated work. Automated checks, status codes, counts, screenshots, model judges, and sub-agent reports are evidence only. For generated, parsed, visual, device, model, network, or cross-repository behavior, personally inspect representative real outcomes and all relevant representations.

Create an `ACC-*` record only after the recorded review is true. Set an input to `verified` only when it links to a current, accepted acceptance record.

## SPEC-SYNC-ACCEPTANCE-GUARDRAILS

Before changing business logic, Prompt rules, normalization, validation, or rejection behavior because a result looks wrong:

1. Name the exact active `SPEC-*` assertion and acceptance criterion being enforced
2. If none exists, create an `OBS-*` and ask for a product ruling instead of inventing a restriction
3. Do not turn one sample or reviewer preference into a keyword blacklist, regular-expression rejection, or generalized prohibition
4. For a confirmed general defect, implement the narrow reusable rule and review the original case plus at least one independent holdout case
5. Record the evidence boundary and remaining unverified behavior in acceptance
