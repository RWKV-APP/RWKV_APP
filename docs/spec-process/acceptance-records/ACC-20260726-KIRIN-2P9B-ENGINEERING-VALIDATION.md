---
id: ACC-20260726-KIRIN-2P9B-ENGINEERING-VALIDATION
type: acceptance
date: 2026-07-26
owner: root Codex agent
inputs:
  - PI-20260726-KIRIN-2P9B-ONLY-VALIDATION
decisions: []
canonical_assertions:
  - SPEC-RWKV-KIRIN-MODEL-IDENTITY
  - SPEC-RWKV-KIRIN-NPU-RUNTIME
changed_surfaces:
  - docs/product-inputs/2026-07-26/PI-20260726-KIRIN-2P9B-ONLY-VALIDATION.md
  - docs/requirements/harmony_kirin_delivery.md
  - docs/spec-process/acceptance-records/ACC-20260726-KIRIN-2P9B-ENGINEERING-VALIDATION.md
  - rwkv_mobile:converter/verify_rwkv_nnrt_safetensors.py
  - rwkv_mobile:src/backends/nnrt/nnrt_backend.cpp
  - rwkv_harmony:build/device-screens
  - rwkv_harmony:build/logs/g1h-schema12-load-pid3331.log
  - rwkv_harmony:build/models
unresolved_conflicts: []
result: partial
supersedes_acceptance: []
superseded_by: []
---

# Kirin exact 2.9B engineering validation

## Mechanical evidence

- The source artifact is `rwkv7-g1h-2.9b-20260710-ctx10240.pth`, 5,896,273,469 bytes, SHA-256 `295595b3b8dbff3f8c2a0585975622ddaba4feea7a377022f0bd75347c90c9b3`
- The F16 NNRT artifact is 5,896,235,146 bytes, SHA-256 `13d6b81bc670493ad43709bd12765accf2b105db9ed7c9a49ca7b2d29bb90f07`
- The W4A16 NNRT artifact is 2,075,535,362 bytes, SHA-256 `8dc40a6b29b5478c3b6c531345dce4b8bb27d2177cb5a7a5214ba0ccf0bc06ef`
- The independent F16 verifier passed for all 1,062 source tensors and 1,095 prepared tensors. Every non-embedding tensor converted exactly, the FP32 embedding LayerNorm matched exactly, and all 32 FFN value tensors were verified as 64 prepared shards
- The independent W4A16 verifier passed for all 1,576 prepared tensors. All 481 packed U4 tensors matched requantization, every F16 tensor and F32 scale matched exactly, and container lengths, names, shapes, packing, group size, and embedding normalization were valid
- W4A16 sampled 15,392 dequantized values with mean absolute error `0.0034470576`, root mean squared error `0.0071243666`, and maximum absolute error `0.1177455485`
- The captured Kirin driver log contains 21 representative model-graph partition records with `NPU:1, CPU:0, GPU:0, ISP:0`
- Runtime inspection confirmed that each compilation is bound to the Kirin accelerator, requests NPU-only device order, and disables HiAI fallback
- The streaming runtime was changed so the four 2.9B output-head graphs are compiled on first use and retained for subsequent tokens instead of being rebuilt and host-dequantized for every token
- A release HAP containing that graph-reuse change built successfully through DevEco Studio, passed the ARM64 package and dependency verifier, and has SHA-256 `25e66b6eb5af9f0adfa69af41d30529b47c46a4a5ea7da36d86fd4047230b7e5`
- `dart run tools/bin/check_specification.dart` was invoked through the repository wrapper and exceeded the wrapper timeout. Running the same checker with the repository Dart executable completed with `Specification v1.7 check passed`

## Requirement review

The exact logical model identity is verified from the source SHA-256 through both prepared artifacts. No alternate checkpoint contributes to this record.

The F16 artifact completed real generation on a HUAWEI Pura 80 Pro with Kirin 9020. For prompt `1+1=?`, the captured UI shows model `RWKV7-G1h 2.9B · NNRT F16` and final output `1+1=2`. The prompt was sent at 12:05:43, one generated token was visible at 12:07:52, three tokens were visible at 12:08:55, and completion was captured at 12:10:15. The UI reported Prefill `0.1 tok/s` and Decode `0.0 tok/s` at one-decimal precision.

The W4A16 artifact also completed real generation on the same phone. The captured UI shows model `RWKV7-G1h 2.9B · NNRT W4A16`, prompt `1+1=?`, first token `2`, and later text `2. What`. Generation began at 12:39:54, the first token was captured at 12:43:48, and two tokens were reported at 12:44:56. The UI reported Prefill `0.1 tok/s` and Decode `0.0 tok/s` at one-decimal precision.

This proves that the complete 2.9B model can execute through the Kirin NNRT path and produce tokens. It does not satisfy the Kirin-optimized delivery contract. The current W4A16 representation is a storage and transfer compression format: packed weights are expanded on the host into F16 constants before graph compilation. It therefore does not provide native low-bit Kirin compute.

Runtime inspection of the device-tested baseline shows that its streaming path constructs 32 transformer graphs and four head graphs during each token evaluation. Repeated graph compilation and executor construction dominate latency and violate the compiled-graph reuse requirement.

The staged graph-reuse change removes repeated construction of the four output-head graphs after their first use. The 32 transformer layer graphs are still rebuilt for every token, so the dominant latency and the contract violation remain.

## Semantic or visual review

The F16 trivial-answer fixture passed. The W4A16 first token matched the expected answer, while its continuation did not preserve the F16 output. W4A16 therefore has not passed generation-quality parity.

The current Android reference for the same logical 2.9B model records Prefill `34.6–51.0 tok/s`, Decode `17.4–18.8 tok/s`, and approximately `0.84–0.87 s` to first token. The Huawei captures report Prefill `0.1 tok/s` and Decode below the UI's `0.1 tok/s` display precision. Because the prompts differ, this is a directional comparison rather than a controlled benchmark. Even using the most conservative rounding bound, current Huawei decode is more than 348 times slower than the Android reference.

## Exclusions

- HDC reported no connected Huawei target during this review, so a fresh live run and complete new partition-log capture could not be collected
- The newly built output-head reuse path has package-build evidence only; its device correctness, memory use, and speed change remain unmeasured until HDC reconnects
- The existing raw driver log contains 21 representative NPU-only records; it does not independently enumerate all 36 graphs from the successful generation
- Fixed same-prompt Android and Huawei generation, multi-turn Chinese and English quality, long context, recurrent-state continuity, memory, power, temperature, cancellation, background behavior, and repeated-load measurements remain pending
- User-interface parity, in-app model download, production signing, and direct end-user distribution are outside this staged runtime record
