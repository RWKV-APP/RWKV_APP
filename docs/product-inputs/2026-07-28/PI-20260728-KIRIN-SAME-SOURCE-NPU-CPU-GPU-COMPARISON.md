---
id: PI-20260728-KIRIN-SAME-SOURCE-NPU-CPU-GPU-COMPARISON
type: product_input
captured_date: 2026-07-28
source_date: 2026-07-28
source: user message in Codex
category: product
status: merged
effective_status: active
delivery_status: in_progress
canonical_assertions:
  - SPEC-RWKV-KIRIN-MODEL-IDENTITY
  - SPEC-RWKV-KIRIN-NPU-RUNTIME
delivery_surfaces:
  - docs/requirements/harmony_kirin_delivery.md
  - rwkv_mobile:converter
  - rwkv_mobile:src/backends
  - rwkv_harmony:tools
  - rwkv_harmony:entry/src/main/cpp
  - rwkv_harmony:entry/src/main/ets/pages/Index.ets
  - rwkv_harmony:build/parity
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records: []
---

# Kirin same-source NPU and CPU/GPU comparison

## Raw statement

> 我要求你再给我整理一套这个并非华为的NPU的这种权重,然后再测试一下就是两组权重的区别。也就是说,我们要拿到同样的权重,拿到同样的原始的PPA文件,然后分别把它们转化成NPU可用的权重以及这种跑在CPU和GPU上的权重,然后看一下就是在同样的SoC下使用这两种方式跑,它们的性能区别是怎样的。

## Extracted assertions

- Start both conversion paths from the same registered original RWKV7-G1h 2.9B checkpoint and prove the source identity with SHA-256
- Produce one Kirin NPU artifact set and one vendor-neutral artifact set suitable for CPU and for a real supported GPU backend
- Record the complete conversion provenance, quantization encoding, size, and SHA-256 for both artifact sets
- Run both sets on the same Kirin SoC with the same tokenizer, Prompt, sampler, token counts, warm-up, repetitions, and thermal protocol
- Compare Prefill, Decode, time to first token, peak memory, correctness, and output tokens
- Report a missing same-device GPU backend explicitly instead of substituting a simulated result or a result from another SoC
