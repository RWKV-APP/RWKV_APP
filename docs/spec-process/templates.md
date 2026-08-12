# Specification Record Templates

Process version: v1.8

These templates define the validated historical v1.7 target-side record archive.
Do not use them to create a new PI, DEC, OBS, CF, or ACC file for Root-routed
work under `SPEC-SYNC-ROOT-INTAKE-BOUNDARY`; active request provenance and
acceptance stay in the private Root Harness.

Each historical record is one Markdown file with strict front matter. Metadata
supports scalar values, `null`, empty lists written as `[]`, and indented scalar
lists. Unknown or missing fields fail validation. The body remains free-form
except for the required headings.

## Historical Product Or Process Input

This schema validates only pre-v1.8 records already present under
`docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md`. Do not create a new PI or
rewrite its raw body for Root-routed work.

```markdown
---
id: PI-YYYYMMDD-SLUG
type: product_input
captured_date: YYYY-MM-DD
source_date: YYYY-MM-DD
source: user or evidence description
category: product
status: inbox
effective_status: pending
delivery_status: not_started
canonical_assertions:
  - SPEC-EXAMPLE
delivery_surfaces:
  - lib/example.dart
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records: []
---

# Short input title

## Raw statement

Preserve the existing meaningful wording and marked redactions.

## Extracted assertions

- One independently evolving assertion
```

`category` is `product`, `process`, or `mixed`. `source_date` is a valid
`YYYY-MM-DD` date or the literal `unknown`; it is never null. Existing state,
decision, conflict, acceptance, and supersession references remain strict when
the referenced record is present. A pre-v1.8 project record may preserve a
syntactically valid opaque PI in `inputs` when the local historical archive is
absent or partial, without authorizing a new target-side request record.

## Decision

Path: `docs/spec-process/decisions/DEC-YYYYMMDD-SLUG.md`

```markdown
---
id: DEC-YYYYMMDD-SLUG
type: decision
date: YYYY-MM-DD
status: approved
approved_by: user or named decision owner
inputs:
  - PI-YYYYMMDD-SLUG
observations: []
conflicts: []
supersedes: []
superseded_by: []
acceptance_records: []
canonical_assertions:
  - SPEC-EXAMPLE
affected_surfaces:
  - docs/example.md
---

# Short decision title

## Decision

State the approved ruling.

## Reason

State the evidence and authority for the ruling.
```

Decision `status` is `approved`, `superseded`, or `rejected`. `approved_by` names the human authority whose ruling made the decision valid; a copied source label alone is not approval. A rejected decision records an explicit human rejection and can support a dismissed input, but it cannot resolve an observation or conflict.

## Observation

Path: `docs/spec-process/observations/OBS-YYYYMMDD-SLUG.md`

```markdown
---
id: OBS-YYYYMMDD-SLUG
type: observation
date: YYYY-MM-DD
status: recorded
inputs: []
conflicts: []
decision: null
canonical_assertions:
  - SPEC-EXAMPLE
affected_surfaces:
  - docs/example.md
---

# Short observation title

## Observation

Describe the verified issue or friction.

## Implication

Explain the risk or cost.

## Proposed next step

State the suggested review or repair.

## Resolution

```

A `recorded` observation has a proposed next step and an intentionally empty Resolution section. A `resolved` observation has a non-empty resolution and links the approved decision when a product or process ruling was required. Every observation names the stable assertions and surfaces it audits so it remains connected to the record graph.

## Conflict

Current path: `docs/spec-process/conflicts/current/CF-YYYYMMDD-SLUG.md`

Resolved path: `docs/spec-process/conflicts/resolved/CF-YYYYMMDD-SLUG.md`

```markdown
---
id: CF-YYYYMMDD-SLUG
type: conflict
status: unresolved
opened_date: YYYY-MM-DD
resolved_date: null
inputs:
  - PI-YYYYMMDD-SLUG
observations: []
canonical_assertions:
  - SPEC-EXAMPLE
affected_surfaces:
  - docs/example.md
blocking_scope: exact behavior that must pause
decision: null
---

# Short conflict title

## Existing assertion

State the current traceable assertion.

## New or observed assertion

State the competing assertion.

## Required decision

Ask the exact question the user must decide.

## Resolution

```

An unresolved current conflict has an intentionally empty Resolution section. A resolved conflict has a non-empty resolution, a resolution date, and an approved decision.

Every linked PI or OBS shares a canonical assertion and affected surface with the conflict. Their combined assertions and surfaces cover the complete conflict scope.

## Acceptance

Path: `docs/spec-process/acceptance-records/ACC-YYYYMMDD-SLUG.md`

```markdown
---
id: ACC-YYYYMMDD-SLUG
type: acceptance
date: YYYY-MM-DD
owner: root Codex agent
inputs:
  - PI-YYYYMMDD-SLUG
decisions: []
canonical_assertions:
  - SPEC-EXAMPLE
changed_surfaces:
  - lib/example.dart
unresolved_conflicts: []
result: accepted
supersedes_acceptance: []
superseded_by: []
---

# Short delivery title

## Mechanical evidence

List commands and exact results.

## Requirement review

Explain how the complete delivery satisfies the canonical assertions.

## Semantic or visual review

Record the representative real outcome and root review, or explain why it is not applicable.

## Exclusions

Name anything intentionally out of scope or unverified.
```

Acceptance `owner` is `root Codex agent`. Acceptance `result` is `accepted`, `rejected`, or `partial`.

A current accepted record independently covers every input it names, including
that input's canonical assertions, governing decisions, and declared delivery
surfaces. A complete local historical graph remains strict. For an immutable
pre-v1.8 snapshot that mixes local and opaque PI inputs and explicitly names
both PI paths in its immutable `changed_surfaces` inventory, validate the
project assertions, changed surfaces, and evidence without requiring a
backlink or closure rewrite of the local PI. Mixed records without that surface
inventory remain strict. Use `partial` for a staged review that does not yet
provide complete coverage.
