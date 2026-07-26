---
id: OBS-20260723-WEB-DEMO-PRIVACY-CONFLICT
type: observation
date: 2026-07-23
status: recorded
inputs: []
conflicts:
  - CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
decision: null
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
---

# Public privacy wording conflicts with the explicit cloud Web Demo contract

## Observation

`docs/privacy_policy.html` says RWKV Chat has no servers, stores all processed data only on the device, and never sends data externally. The localized README files also describe prompts, outputs, and loaded-model inference as remaining on device.

The Web Demo has explicitly named cloud modes that send prompt content to configured remote chat-completion endpoints. `AGENTS.md` requires built-in default cloud endpoints and request authentication for that feature. These are two traceable product rules with incompatible public data-flow implications.

## Implication

The repository cannot honestly claim both that every app workflow keeps all data on device and that the cloud Web Demo sends prompts to a remote service. The unresolved scope is limited to Web Demo data transmission and the public disclosure of that transmission.

## Proposed next step

Ask the user to choose the Web Demo product contract: retain cloud execution with accurate disclosure and any required controls, make Web Demo local-only, or define another explicit behavior. Synchronize the privacy policy, product copy, Web Demo UI, implementation, and acceptance after that ruling.

## Resolution
