---
id: CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
type: conflict
status: unresolved
opened_date: 2026-07-23
resolved_date: null
inputs: []
observations:
  - OBS-20260723-WEB-DEMO-PRIVACY-CONFLICT
canonical_assertions:
  - SPEC-RWKV-WEB-DEMO-DATA-FLOW
affected_surfaces:
  - docs/privacy_policy.html
  - PRODUCT.md
  - README.md
  - docs/README.zh-hans.md
  - docs/README.zh-hant.md
  - docs/README.ja.md
  - docs/README.ko.md
  - docs/README.ru.md
  - AGENTS.md
  - lib/store/web_demo.dart
blocking_scope: changes that select or publicly assert the Web Demo prompt-transmission and disclosure contract
decision: null
---

# Privacy policy and cloud Web Demo data flow disagree

## Existing assertion

The checked-in privacy policy says the app has no servers, stores all generated or processed data only on device, and never sends data externally. Public product copy says prompts and outputs remain on device after a model is loaded.

## New or observed assertion

The Web Demo exposes official cloud modes that send user prompt content to configured remote chat-completion endpoints. Repository instructions explicitly require built-in default cloud endpoints and request authentication for that feature.

## Required decision

Choose whether the cloud Web Demo remains a supported product workflow and, if so, define its user-facing network disclosure and any required consent or controls. Otherwise define the local-only replacement. State which policy, product copy, UI, implementation, and tests must change.

## Resolution
