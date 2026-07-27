---
id: ACC-20260727-ORG-PROFILE-RWKV-ADVANTAGES
type: acceptance
date: 2026-07-27
owner: root Codex agent
inputs:
  - PI-20260727-ORG-PROFILE-RWKV-ADVANTAGES
decisions: []
canonical_assertions:
  - SPEC-RWKV-PRODUCT-PURPOSE
  - SPEC-RWKV-DESIGN-PRINCIPLES
changed_surfaces:
  - PRODUCT.md
  - docs/product-inputs/2026-07-27/PI-20260727-ORG-PROFILE-RWKV-ADVANTAGES.md
  - docs/spec-process/acceptance-records/ACC-20260727-ORG-PROFILE-RWKV-ADVANTAGES.md
  - docs/specs/00-inventory.md
  - docs/specs/01-authority-map.md
  - docs/specs/02-repository-map.md
  - rwkv_org_profile:profile/README.md
  - rwkv_org_profile:profile/assets/hero.svg
  - rwkv_org_profile:profile/assets/hero-mobile.svg
unresolved_conflicts:
  - CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
result: accepted
supersedes_acceptance: []
superseded_by: []
---

# RWKV organization profile advantages acceptance

## Mechanical evidence

- `dart run tools/bin/check_specification.dart` passed after registering the organization-profile repository alias, canonical product wording, input, and acceptance graph
- `git diff --check` passed in both `rwkv_app` and the organization-profile repository
- `xmllint --noout` accepted both responsive SVG files
- `rsvg-convert` rendered the desktop Hero at 1440 by 600 pixels and the mobile Hero at 720 by 920 pixels
- Every unique HTTP link extracted from `profile/README.md` returned HTTP 200 after redirects
- The GitHub Markdown API rendered the complete profile successfully, including its headings, responsive Hero, product gallery, and Mermaid source
- Organization-profile commits `b184279` and `e5c9e16` were pushed to `RWKV-APP/.github` `main`
- The public organization description was updated through the GitHub API and read back as `Open-source RWKV products for efficient on-device AI — from multi-backend runtimes to apps.`

## Requirement review

The public profile now begins with RWKV's distinctive architecture instead of generic local-AI capability copy. Its first screen states parallelizable training, recurrent inference, linear sequence processing, fixed-size recurrent state, and the absence of a KV cache that grows with context.

The profile distinguishes the upstream RWKV architecture from RWKV-APP's product role. It then connects the architecture to the model packages, multi-backend native runtime, Flutter FFI bridge, five-platform client, real product screenshots, downloads, related repositories, and community entrypoints.

All complexity claims explicitly use sequence length as the varying dimension. The copy also states that model weights, activations, batch size, concurrent streams, backend allocations, and accelerator availability remain model-, device-, and runtime-dependent.

## Semantic or visual review

The root agent inspected all nine rendered pages of the supplied WAIC document and compared its architecture description with the original RWKV paper, the RWKV-7 paper, the upstream RWKV-LM repository, and the current mobile runtime surfaces. The profile uses the durable architecture claims and omits private contact details, biographies, awards, partner claims, research counts, and configuration-specific benchmark numbers.

The root agent inspected the rendered desktop and mobile SVGs directly, then reviewed the live GitHub organization page at 1440 by 1000 and 390 by 844 viewports. The desktop first screen preserves a clear hierarchy between headline, calls to action, and inference diagram. The responsive mobile Hero remains legible and uses a compact vertical composition. A two-column advantage table that wrapped poorly at 390 pixels was replaced with a full-width vertical list and reviewed again on the live page.

The live review also confirmed the updated organization metadata, real app gallery, rendered Mermaid stack, download section, project links, and bilingual content hierarchy.

## Exclusions

- The profile does not publish the WAIC material's `10000+ tokens/s`, `1000` concurrent streams, publication count, partner deployments, awards, patent inventory, RWKV-8 delivery claims, or personal biographies
- It does not claim infinite context, lossless memory, universally constant application memory, absolute wall-clock speed, universal NPU support, or superiority on every device
- No RWKV App runtime, model configuration, product behavior, download artifact, or privacy/data-flow behavior was changed
- `CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW` remains unresolved; the profile therefore makes no universal claim that every workflow keeps all data on the device
