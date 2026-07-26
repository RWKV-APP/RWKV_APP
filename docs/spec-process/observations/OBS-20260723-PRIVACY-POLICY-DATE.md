---
id: OBS-20260723-PRIVACY-POLICY-DATE
type: observation
date: 2026-07-23
status: recorded
inputs: []
conflicts: []
decision: null
canonical_assertions:
  - SPEC-RWKV-PRIVACY-POLICY-METADATA
affected_surfaces:
  - docs/privacy_policy.html
---

# Privacy policy displays the viewer date as its revision date

## Observation

`docs/privacy_policy.html` renders “Last updated” with `new Date().toLocaleDateString()`. The displayed value is the viewer's current date, not the date on which the policy text was approved or changed.

## Implication

The public page does not provide an auditable policy revision date and can appear newly revised on every visit.

## Proposed next step

When the privacy contract is next approved, replace the dynamic value with the actual policy revision date and verify the rendered page.

## Resolution
