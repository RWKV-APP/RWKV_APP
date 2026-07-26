# Spec Sync Loop Rules

Process version: v1.7
Effective date: 2026-07-23
Scope: `rwkv_app`

Official trigger terms:

- `Specification flow`
- `Specification`

The v1.7 target design is adapted from the `geo-ai` working-tree v1.6 system. It keeps the original traceability and narrow-conflict principles while replacing aggregate Markdown ledgers, date-based legacy bypasses, incomplete state combinations, and Node/pnpm-specific checks.

## SPEC-SYNC-CLASSIFICATION — Request Classification

Classify every request before changing business behavior:

- `product`: user-visible behavior, API contract, model or Prompt rules, UI behavior, privacy/data-flow promises, acceptance criteria, stakeholder wording, or a user paraphrase of product intent
- `process`: Specification structure, state, authority, conflict handling, verification, or agent behavior
- `mixed`: independently meaningful product and process assertions
- `implementation-only`: mechanics that preserve current canonical behavior
- `general chat`: explanation or brainstorming with no request to change project truth

Product, process, and mixed input enters the Specification flow before implementation. Implementation-only input and general chat do not create a `PI-*` record.

## SPEC-SYNC-AUTHORITY — Truth And Ownership

Truth is organized into four layers:

1. The canonical owner registered for a stable `SPEC-*` assertion in `docs/specs/01-authority-map.md`
2. Derived user or developer documentation that must reflect the owner
3. Implementation and runtime truth that proves current behavior and exposes drift
4. Raw inputs, observations, decisions, conflicts, Git history, tests, and acceptance records that preserve provenance

Resolve truth in this order:

1. An applicable current conflict blocks only its named delivery scope
2. An explicit human ruling becomes authoritative after capture and canonical synchronization
3. An active assertion in the registered canonical owner governs implementation
4. Other layers are compared with that assertion to detect drift

Git history can support chronology and provenance. A newer commit without a traceable ruling cannot resolve a semantic contradiction.

Agent memory can help locate prior context, but it is not a canonical layer and cannot override checked-in truth. Verify remembered facts that may have changed against the current owner and delivery surfaces.

Each authority-map row must have a unique topic, one canonical owner, one lifecycle, and one or more globally unique `SPEC-*` IDs. The owner must contain each registered ID. A proposal, historical item, deferred item, or conflicted item cannot be treated as an active implementation contract.

Use repository aliases from `docs/specs/02-repository-map.md` for external delivery surfaces.

Every repository reference must remain inside its registered alias root after path and symlink resolution. Strict PI, DEC, OBS, CF, and ACC records cannot be symlinks.

## Product And Process Input

Store each input at:

```text
docs/product-inputs/YYYY-MM-DD/PI-YYYYMMDD-SLUG.md
```

The directory date is the capture date. `source_date` preserves the original communication date or uses the literal `unknown`; null is not allowed. Split assertions into separate records when they can evolve independently.

The meaningful raw statement and its redaction notes are immutable provenance. Review, effect, delivery, references, and supersession metadata can evolve without rewriting that source body.

All v1.7 records are strict from the first effective day. There is no automatic legacy mode based on filename date, record date, Git age, or missing fields.

Before writing raw input:

- replace credentials, private keys, tokens, cookies, signed URLs, and access-bearing query strings with `[REDACTED]`
- remove unnecessary personal data
- replace machine-local evidence paths with repository evidence or a descriptive unavailable-evidence note
- preserve the meaningful wording and explicitly state each redaction

The checker rejects high-confidence secret shapes in strict records and supporting evidence, including private-key blocks, known access-token prefixes, authorization credentials, and access-bearing signed URL parameters. This automated scan supplements human redaction review and does not detect every form of personal or sensitive data.

Safe supporting audit artifacts may be stored under `docs/product-inputs/evidence/`. They are provenance only, are not parsed as `PI-*` records, and cannot establish product authority without a linked strict input or observation.

The templates and exact metadata fields live in `docs/spec-process/templates.md`.

An input's `source` preserves provenance and does not automatically establish priority. Every `DEC-*` record names the human decision authority in `approved_by`, plus the stable assertions and affected surfaces governed by that ruling.

## SPEC-SYNC-STATE-MODEL — Input State

`status` describes review and synchronization:

- `inbox`: captured but not reviewed
- `merged`: synchronized into the canonical owner
- `conflict`: contradicts current truth and requires a ruling
- `deferred`: intentionally waiting for later review
- `dismissed`: reviewed and rejected before becoming canonical

`effective_status` describes current authority:

- `pending`: not yet canonical because review, deferral, or conflict remains
- `active`: current canonical truth
- `superseded`: formerly canonical and explicitly replaced
- `historical`: retained provenance that was never current or no longer acts as a product rule

`delivery_status` describes implementation and acceptance:

- `not_started`
- `planned`
- `in_progress`
- `blocked`
- `implemented`
- `verified`
- `not_applicable`

Allowed combinations are strict:

| status | effective_status | delivery_status |
| --- | --- | --- |
| inbox | pending | not_started or planned |
| deferred | pending | not_started or planned |
| conflict | pending | blocked |
| merged | active | not_started, planned, in_progress, implemented, verified, or not_applicable |
| merged | superseded | not_started, planned, in_progress, implemented, verified, or not_applicable |
| dismissed | historical | not_applicable |

`merged` never means implemented or verified. `verified` requires a linked, current, accepted `ACC-*` record. A rejected proposal requires its rejecting `DEC-*`. New records must not combine independently active, superseded, and conflicted assertions; split them at capture time.

A `merged` or `conflict` input must name at least one stable canonical assertion. A `merged` input with applicable delivery work must name at least one delivery surface. Inbox and deferred records may leave those lists empty until topic routing is reviewed.

## Supersession

When a later ruling replaces a formerly canonical assertion:

1. search the stable assertion ID and read its connected PI, DEC, OBS, CF, and ACC history
2. preserve both raw records
3. link `supersedes` and `superseded_by` in both directions
4. keep the earlier record `merged + superseded`
5. keep the later record `merged + active` only after canonical synchronization
6. require the input pair to share at least one stable canonical assertion
7. require the replacing record's date to be the same as or later than the replaced record
8. reject self-links, missing targets, one-way links, and cycles

A replacing input is `merged + active` when its supersession link is first established. If a later input replaces it, the intermediate input becomes `merged + superseded` and retains both its outgoing `supersedes` link and incoming `superseded_by` link. The same durable-chain rule applies to decisions: an intermediate decision remains `superseded` while preserving both directions. Only the terminal current input or decision remains active or approved.

A dismissed proposal was never canonical and is not described as superseded.

An approved decision can supersede a decision marked `superseded` only when they share a stable assertion. Acceptance attempts can supersede each other only when they share at least one input and stable assertion. The earlier acceptance record's date, result, evidence body, and delivery-time conflict snapshot remain unchanged; only relationship metadata such as `superseded_by` may be appended.

## SPEC-SYNC-CONFLICTS — Semantic Conflicts

Create a current conflict when traceable assertions leave intended behavior genuinely ambiguous. Plain implementation or documentation drift against an unambiguous active assertion is drift to synchronize.

Store conflicts under:

```text
docs/spec-process/conflicts/current/CF-YYYYMMDD-SLUG.md
docs/spec-process/conflicts/resolved/CF-YYYYMMDD-SLUG.md
```

A conflict must:

- link at least one exact `PI-*` or `OBS-*` record, with backlinks
- keep every linked input or observation topically related through a shared assertion and affected surface
- cover all conflict assertions and affected surfaces through the union of its linked provenance records
- name at least one stable `SPEC-*` assertion and at least one affected delivery surface
- include existing and competing assertions
- define the narrow blocking scope
- ask for the exact human ruling needed
- use `opened_date`

An unresolved conflict has no decision or resolution date. A resolved conflict moves directories, links an approved `DEC-*` in both directions, records `resolved_date`, and preserves the resolution. The resolving decision must cover every canonical assertion and affected surface named by the conflict. Every stable assertion referenced by a current conflict has lifecycle `conflicted` in the authority map, and every conflicted assertion has a current conflict. The checker validates backlinks, lifecycle, chronology, and placement.

## Process Evolution

Record a discovered issue as `OBS-*` and route it through non-empty `canonical_assertions` and `affected_surfaces` lists. A core process change requires an approved `DEC-*`, synchronized rules, a changelog entry, relevant Eval Cases, checker coverage, and acceptance. Decision status is `approved`, `superseded`, or `rejected`; only an approved decision that covers the observation's assertions and affected surfaces can resolve it.

The workflow does not depend on an automatic hook. Agents run the deterministic checker explicitly and CI runs it for pull requests. A repository hook may assist unrelated work, but no hook or automation may silently edit canonical truth, approve a decision, resolve a conflict, or create final acceptance.

`.github/copilot-instructions.md` remains the tracked symlink to `../AGENTS.md`. The checker requires identical resolved content; only a Windows checkout with symlinks disabled may use Git's exact `../AGENTS.md` placeholder representation.

Use `docs/plans/PLANS.md` for complex, multi-stage, or cross-repository implementation. A plan tracks execution and handoff state; it does not replace the canonical Specification records.

## SPEC-SYNC-ACCEPTANCE — Verification And Acceptance

Engineering checks prove only the properties they exercise. Generated language, parsed content, model behavior, device behavior, connected workflows, visual layouts, reports, exports, and cross-repository outcomes require representative result-level review.

The root Codex agent delivering the task owns final combined requirement and response acceptance, including delegated contributions. The record field is exactly `owner: root Codex agent`. The root agent must inspect the combined diff, relevant sources, and every persisted or rendered representation in scope. Tests, scripts, status codes, counts, screenshots, scores, model judges, and sub-agent reports remain evidence.

An `ACC-*` record captures:

- exact input and decision IDs
- stable canonical assertion IDs
- changed surfaces
- mechanical evidence
- the root agent's requirement and semantic or visual review
- unresolved conflicts as they existed on the acceptance date
- exclusions and known limits
- accepted, rejected, or partial result

Store records under `docs/spec-process/acceptance-records/` using the strict template.

Every acceptance record names at least one stable canonical assertion and one changed surface. Acceptance supersession must be bidirectional, acyclic, chronological, and topic-related.

A `verified` input requires at least one single current, non-superseded, accepted `ACC-*` record that independently covers the input, all of its canonical assertions, all governing decisions, and all declared delivery surfaces. Several partial records cannot be combined implicitly; create a final aggregate acceptance record after staged review. Every current accepted acceptance record must independently provide that complete coverage for every input it names, and each named input must have `delivery_status: verified`.

### SPEC-SYNC-ACCEPTANCE-GUARDRAILS — Prevent Review Preference From Becoming Product Law

Before changing business logic, Prompt rules, normalization, validation, or rejection behavior because an outcome looks wrong, name the exact active canonical assertion and acceptance criterion being enforced.

If no exact active assertion exists:

- record the issue as an observation and ask for a product ruling
- do not create a new product restriction from reviewer preference, implementation convenience, or one surprising sample
- do not turn a single example into a keyword blacklist, regular-expression rejection, or generalized prohibition

When a confirmed defect reveals a reusable rule, implement the narrow general rule and review both the original case and at least one independent holdout case. Record what the evidence proves and what remains unverified.

Chronology validation covers ID/date/filename consistency, known source dates not later than capture, conflict open/resolution order and resolution decisions, supersession order, and acceptance snapshots. It does not infer the undocumented origin time of evidence archived later.

Conflict and acceptance records use day precision, so same-day event order is unknown. An applicable conflict is definitely open and must appear when `opened_date < acceptance date` and its resolution is absent or later than the acceptance date. A conflict opened or resolved on the acceptance date may be included or omitted with supporting evidence. A conflict opened later or resolved earlier must not appear. A later resolution never rewrites an older snapshot.

## Commands

Run the Specification checker from the repository root:

```bash
dart run tools/bin/check_specification.dart
```

When starting elsewhere, change to the repository root before running the command. The CLI also supports repository-root discovery and explicit `--root` for package and CI integration, but the Dart runner itself can create `.dart_tool/` in an arbitrary launch directory.

Run broader repository checks according to the changed module and `AGENTS.md`. Finish with:

```bash
git diff --check
```
