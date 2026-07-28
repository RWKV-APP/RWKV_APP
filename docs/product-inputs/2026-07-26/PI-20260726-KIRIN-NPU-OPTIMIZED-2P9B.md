---
id: PI-20260726-KIRIN-NPU-OPTIMIZED-2P9B
type: product_input
captured_date: 2026-07-26
source_date: 2026-07-26
source: user
category: product
status: merged
effective_status: active
delivery_status: in_progress
canonical_assertions:
  - SPEC-RWKV-KIRIN-MODEL-IDENTITY
  - SPEC-RWKV-KIRIN-NPU-RUNTIME
  - SPEC-RWKV-HARMONY-DISTRIBUTION
delivery_surfaces:
  - docs/requirements/harmony_kirin_delivery.md
  - remote
  - rwkv_mobile:converter
  - rwkv_mobile:src/backends/nnrt
  - rwkv_mobile_flutter:.
  - rwkv_harmony:.
  - app_website:.
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE
---

# Deliver the same 2.9B model through a Kirin-optimized NPU artifact

## Raw statement

> 同样的权重，而且这个同样的权重还要针对麒麟的 NPU 进行特别的优化。这是我们最终的效果，最终想要完成的事。

> 量化一下再跑，看看现在 rwkv_app 用的是什么量化，看看现在 rwkv_mobile 是怎么量化的。

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- The HarmonyOS 2.9B option represents the same logical G1h source model, tokenizer, prompt contract, reasoning defaults, and generation semantics as the corresponding Android option
- The Kirin artifact is separately quantized and optimized for the Kirin NPU execution path
- The Kirin 2.9B path does not use GGUF or llama.cpp
- Users discover, download, verify, and load the compatible artifact entirely inside the released phone application
- Full-model quality, performance, memory, thermal, lifecycle, and real NPU partition evidence are required before completion
