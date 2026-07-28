# HarmonyOS Kirin Delivery Contract

Lifecycle: active requirement, delivery pending
Last reviewed: 2026-07-27

This document owns the product contract for delivering RWKV App on Huawei HarmonyOS phones with a Kirin-optimized local model path. Passing an NNRT operator probe, producing a signed debug HAP, or generating one token is staged evidence and does not independently satisfy this contract.

## SPEC-RWKV-HARMONY-USER-PARITY — User Experience Parity

The HarmonyOS product must expose the same user-visible chat UI, navigation, model selection, settings, conversation history, reasoning presentation, Markdown and formula rendering, editing, regeneration, branching, stop behavior, and localization contract as the current Android RWKV App.

Parity covers the complete current Android RWKV Chat product surface. Every user-visible route, tab, menu, dialog, sheet, control, action, gesture, permission flow, model-management workflow, download state, persisted preference, conversation operation, generation state, empty state, loading state, unsupported state, and recoverable error path discoverable on the Android reference phone must have a mapped HarmonyOS counterpart. A visually similar chat shell or a representative subset of Android functions does not satisfy this assertion.

The shared Flutter application is preferred when its real-device build, plugin, persistence, input, rendering, lifecycle, and packaging checks pass. An ArkUI implementation is acceptable only if representative screen and interaction comparisons prove equivalent behavior. Platform-required visual or lifecycle differences must be documented during acceptance.

Inference requests must use the same conversation history, roles, prompt template, reasoning mode, sampler parameters, stop conditions, context policy, and generation limits as the corresponding Android workflow.

Reusing the Flutter runtime is not required. A native ArkUI implementation must reproduce the Android reference application's content hierarchy, controls, user-visible states, navigation, gestures, streaming behavior, settings, and representative visual appearance. Acceptance requires paired Android and HarmonyOS screenshots plus interaction results from the real reference phones. Platform-owned system chrome may differ when the difference is identified in the review.

Implementation and acceptance must maintain a page-and-function inventory captured from the real Android reference phone through screenshots, accessibility or UI-tree reads, and interaction traversal. The inventory must map each Android function and state to its HarmonyOS implementation and paired real-device evidence. Any intentionally platform-specific difference must be named and reviewed; an unexplained missing or nonfunctional Android capability fails parity.

## SPEC-RWKV-KIRIN-MODEL-IDENTITY — Logical Model And Artifact Identity

The HarmonyOS 2.9B option must represent the same logical `RWKV7-G1h 2.9B 20260710 ctx10240` model as the Android option. The logical model record must bind:

- canonical source-weight SHA-256
- tokenizer identity and SHA-256
- chat template and role contract
- reasoning defaults
- sampler and stop defaults
- context length
- deterministic quality and token-output fixtures

Every correctness, quality, performance, memory, thermal, UI, or acceptance claim for the HarmonyOS 2.9B option must be measured with this exact logical 2.9B model. Smaller checkpoints and different RWKV model revisions are diagnostic evidence only; they must not be used to characterize, compare, or accept the Kirin 2.9B path.

Kirin may use a different device artifact and quantization encoding. Its catalog entry must identify the source model and transformation provenance, contain size and SHA-256 metadata, and be selected only for compatible HarmonyOS and Kirin devices. The Kirin execution path must not route this artifact through GGUF or llama.cpp.

A controlled llama.cpp CPU baseline and the Kirin NNRT result must use the same registered source-weight SHA-256, tokenizer, Prompt and role contract, sampler, stop conditions, context, input fixtures, and output limits. The performance comparison must use an equivalent low-bit quantization target. When backend packaging prevents byte-identical quantized artifacts, the release evidence must disclose every encoding difference and include source-to-quantized logits and top-token checks before comparing speed.

The comparison deliverable must prepare both the Kirin NNRT artifact and a vendor-neutral CPU/GPU artifact from that one registered source checkpoint. Each conversion must record the source file, source SHA-256, converter revision, command or configuration, tensor encoding, quantization method, artifact size, and artifact SHA-256. The vendor-neutral artifact must run on CPU and may run on the same device GPU only when the selected runtime has a real supported GPU backend; an unavailable GPU path must be reported as unsupported rather than replaced with a simulated or different-device result.

Same-SoC performance evidence must measure the NPU, CPU, and any supported GPU path separately on the reviewed Kirin phone with one controlled test protocol. The protocol must fix tokenizer, Prompt bytes, prefill token count, generated token count, sampler, stop rules, context, warm-up, repetitions, temperature condition, and memory reporting. It must report Prefill, Decode, time to first token, peak memory, output tokens, and correctness for each executed backend.

## SPEC-RWKV-KIRIN-NPU-RUNTIME — Kirin NPU Execution

The Kirin artifact must use a low-bit representation designed for the verified Kirin NNRT path. Decode must reuse compiled graphs and executors; rebuilding transformer or head graphs for every token is prohibited.

Acceptance requires representative driver partition evidence for the actual 2.9B model path, not only isolated operator probes. Neural-network compute on the critical decode path must remain on the Kirin accelerator with any CPU participation identified and justified. Expanding the complete model to host F16, or repeatedly performing full host dequantization that prevents interactive use, does not qualify as Kirin-optimized delivery.

The artifact must pass:

- complete tensor and container verification
- source-to-quantized logits and top-token comparison
- fixed single-turn and multi-turn Chinese and English generation cases
- long-context and state-continuity checks
- first-token, sustained decode, peak memory, power, temperature, cancellation, foreground/background, and repeated-load measurements
- comparison with the current Android reference workflow using the same logical-model fixtures

Release evidence must state measured performance and the reviewed interactive-use threshold. Until that review passes, successful token generation remains engineering evidence only.

For the initial Kirin 9020 release, the exact 2.9B NPU path must sustain at least `5.0 tok/s` Decode after warm-up on the reviewed Huawei phone. Prefill throughput, time to first token, peak memory, power, and temperature are separate reported metrics and cannot substitute for this Decode gate. The approximately `20 tok/s` Snapdragon 8 Gen 3 result is a directional reference; the Kirin release gate remains the measured `5.0 tok/s` minimum under the controlled fixture.

The same-phone engineering sequence first establishes a llama.cpp CPU baseline, then measures the NNRT NPU path with the controlled identity and quantization conditions above. The production model option still selects the verified NNRT NPU artifact; the CPU result is a diagnostic and fallback baseline rather than evidence that the Kirin NPU requirement passed.

## SPEC-RWKV-HARMONY-DISTRIBUTION — Direct End-User Delivery

A user must be able to install and use the product without Windows, WSL, DevEco Studio, HDC, a developer certificate, or manually copying model files.

The released workflow must provide:

- production signing and an installable AppGallery, internal-test, or equivalent user-facing package
- a direct package download on the project website with version, supported-device and HarmonyOS requirements, file size, and SHA-256
- in-app compatible-model discovery and download
- free-space checks, pause and resume, retry, progress, SHA-256 verification, and safe replacement after a completed download
- explicit unsupported-device behavior instead of attempting an incompatible artifact
- persisted settings and conversations across restart and upgrade
- streaming generation, stop, screen-awake or approved long-running behavior, and safe foreground/background transitions
- removal of developer-only paths, debug keys, and HDC prerequisites from the user journey

Initial public compatibility may be limited to Kirin 9020 devices if that limitation is visible before download and all acceptance evidence names the tested phone and HarmonyOS version.

## Completion Rule

Final acceptance must cover the Flutter app, Flutter/native adapter, NNRT engine, HarmonyOS package, model catalog and hosting, production distribution path, and representative real-device outcomes together. Partial records may document milestones but cannot mark either linked product input as verified.
