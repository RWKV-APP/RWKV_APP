# Specification Acceptance Records

Process version: v1.8

This directory retains historical v1.7 delivery snapshots. For Root-routed
work, record combined delivery evidence and acceptance in the private Root
Mission Result; do not create a new target-side `ACC-*` only to mirror it.

Existing snapshots remain `ACC-YYYYMMDD-SLUG.md` files using
`docs/spec-process/templates.md`.

An acceptance record must include exact project decision, assertion, changed-surface, and unresolved-conflict references. It may include opaque private source IDs for provenance. Its date, ID date, and filename date must match; project decisions cannot occur after acceptance.

Mechanical evidence proves only the engineering properties exercised by those commands. The root Codex agent must separately record requirement review and any applicable semantic, visual, real-model, real-device, network, or cross-repository review.

`SPEC-SYNC-ACCEPTANCE-GUARDRAILS` applies when review suggests new business logic, Prompt, normalization, validation, or rejection behavior. Acceptance must cite an exact active assertion and must not promote a single sample or reviewer preference into a generalized product restriction.

Dates have day precision. List every applicable conflict that was definitely open before the acceptance day and not resolved until a later day. A conflict opened or resolved on the same day may be included or omitted when the evidence section explains the known order.

An acceptance record's date, result, evidence body, and delivery-time conflict snapshot are immutable. A later related attempt may supersede an earlier one through bidirectional acceptance links; appending relationship metadata such as `superseded_by` does not rewrite the earlier outcome.

One current, non-superseded record with `result: accepted` must independently cover its canonical assertions, decisions, changed surfaces, conflicts, evidence, and exclusions. Partial records may preserve staged evidence, but they do not combine implicitly. Private source lifecycle and delivery state remain owned by the Root Harness.
