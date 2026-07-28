---
id: PI-20260727-KIRIN-2P9B-FIVE-TOKENS
type: product_input
captured_date: 2026-07-27
source_date: 2026-07-27
source: user
category: product
status: merged
effective_status: active
delivery_status: in_progress
canonical_assertions:
  - SPEC-RWKV-KIRIN-MODEL-IDENTITY
  - SPEC-RWKV-KIRIN-NPU-RUNTIME
delivery_surfaces:
  - docs/requirements/harmony_kirin_delivery.md
  - remote
  - rwkv_mobile:converter
  - rwkv_mobile:src/backends/nnrt
  - rwkv_harmony:.
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE
---

# Reach five-token decode with the same 2.9B model on Kirin

## Raw statement

> RWKV mobile 部分可以先试 llama.cpp，再试华为自己的 NPU。期望的效果是 2.9B，在同样的量化情况下，不管使用 llama.cpp 还是华为自己的 NPU，都使用同样的权重。

> 8 Gen 3 大概是 20 tokens 每秒，我期望华为手机的输出速度大概是 5 tokens 每秒。

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- Establish a same-phone llama.cpp CPU baseline before judging the Kirin NNRT path
- Every CPU and NPU comparison uses the exact registered G1h 2.9B source weights, tokenizer, Prompt contract, sampler, stop rules, and controlled fixtures
- CPU and NPU comparisons use an equivalent low-bit quantization target; backend-required encoding differences must be disclosed and quality-checked
- The supported Kirin 9020 production NPU path must sustain at least 5.0 decoded tokens per second for the exact 2.9B model after warm-up
- Prefill, time to first token, memory, power, temperature, and sustained Decode are reported separately
