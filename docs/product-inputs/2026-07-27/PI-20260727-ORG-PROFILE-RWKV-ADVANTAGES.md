---
id: PI-20260727-ORG-PROFILE-RWKV-ADVANTAGES
type: product_input
captured_date: 2026-07-27
source_date: 2026-07-27
source: user-provided stakeholder chat and approved WAIC messaging material
category: product
status: merged
effective_status: active
delivery_status: verified
canonical_assertions:
  - SPEC-RWKV-PRODUCT-PURPOSE
  - SPEC-RWKV-DESIGN-PRINCIPLES
delivery_surfaces:
  - PRODUCT.md
  - rwkv_org_profile:profile/README.md
  - rwkv_org_profile:profile/assets/hero.svg
  - rwkv_org_profile:profile/assets/hero-mobile.svg
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260727-ORG-PROFILE-RWKV-ADVANTAGES
---

# Highlight RWKV architecture advantages on the organization profile

## Raw statement

> 据我们的聊天记录，然后再优化一波我们的组织页面。对，然后优化了之后别忘了同步一下，就是推到那个 Git 上
>
> Stakeholder feedback: “没有突出 RWKV 的特点和优势”
>
> “这是 [REDACTED: stakeholder name] 确认过的 WAIC 申报内容，答案比较新，可能也比较能满足他对于 RWKV 介绍的要求，可以参考一下”

The supporting chat screenshots and WAIC document contained unrelated contact details, personal biographies, and temporary machine-local attachment paths. Those details are omitted because they are not needed to preserve the product request.

## Extracted assertions

- The public organization profile must make RWKV's distinguishing architecture visible in the first screen instead of leading only with generic application capabilities
- The core explanation must cover parallelizable training, recurrent inference, `O(T)` total processing for a sequence of length `T`, `O(1)` recurrent state with respect to sequence length, and the absence of a KV cache that grows with context
- Complexity claims must name sequence length as the varying dimension and must not imply that model size, batch size, runtime memory, or all hardware costs are constant
- Concrete speed, concurrency, backend, platform, device, and accelerator claims are implementation- and hardware-dependent and require current public verification before publication
- The profile may connect the architecture to streaming, long-running sessions, on-device inference, and high-concurrency serving without presenting scenario suitability as a universal benchmark guarantee
- The revised profile and responsive hero artwork must be synchronized to the public organization Git repository after visual and semantic verification
