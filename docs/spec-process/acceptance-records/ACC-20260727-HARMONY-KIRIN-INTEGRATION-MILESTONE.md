---
id: ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE
type: acceptance
date: 2026-07-27
owner: root Codex agent
inputs:
  - PI-20260726-HARMONY-ANDROID-EXPERIENCE-PARITY
  - PI-20260726-KIRIN-2P9B-ONLY-VALIDATION
  - PI-20260726-KIRIN-NPU-OPTIMIZED-2P9B
  - PI-20260727-HARMONY-ANDROID-FULL-FUNCTION-PARITY
  - PI-20260727-HARMONY-WEBSITE-UI-PARITY
  - PI-20260727-KIRIN-2P9B-FIVE-TOKENS
decisions: []
canonical_assertions:
  - SPEC-RWKV-HARMONY-USER-PARITY
  - SPEC-RWKV-KIRIN-MODEL-IDENTITY
  - SPEC-RWKV-KIRIN-NPU-RUNTIME
  - SPEC-RWKV-HARMONY-DISTRIBUTION
changed_surfaces:
  - docs/product-inputs/2026-07-26/PI-20260726-HARMONY-ANDROID-EXPERIENCE-PARITY.md
  - docs/product-inputs/2026-07-26/PI-20260726-KIRIN-2P9B-ONLY-VALIDATION.md
  - docs/product-inputs/2026-07-26/PI-20260726-KIRIN-NPU-OPTIMIZED-2P9B.md
  - docs/product-inputs/2026-07-27/PI-20260727-HARMONY-ANDROID-FULL-FUNCTION-PARITY.md
  - docs/product-inputs/2026-07-27/PI-20260727-HARMONY-WEBSITE-UI-PARITY.md
  - docs/product-inputs/2026-07-27/PI-20260727-KIRIN-2P9B-FIVE-TOKENS.md
  - docs/requirements/harmony_kirin_delivery.md
  - docs/spec-process/acceptance-records/ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE.md
  - rwkv_harmony:docs/android-harmony-feature-matrix.md
  - rwkv_harmony:entry/src/main/ets/pages/Index.ets
  - rwkv_harmony:entry/src/main/ets/components/MarkdownView.ets
  - rwkv_harmony:entry/src/main/ets/model/ModelAssets.ets
  - rwkv_harmony:entry/src/main/ets/model/KirinModelManifest.ets
  - rwkv_harmony:entry/src/main/cpp/cann_cpu_support.cpp
  - rwkv_harmony:entry/src/main/cpp/cann_rwkv_runtime.cpp
  - rwkv_harmony:tools/build_prompt_calibrated_cann_rwkv7_groups.sh
  - rwkv_harmony:tools/prepare_kirin_grouped_model_release.ps1
  - rwkv_harmony:tools/quantize_cann_rwkv7_layer.py
  - rwkv_harmony:tools/sync_kirin_model_manifest_artifacts.ps1
  - rwkv_harmony:build/parity
  - rwkv_harmony:build/signing/rwkv-chat-harmony-huawei-release-signed.hap
  - app_website:frontend/src/app/page.tsx
  - app_website:frontend/src/features/download/downloadRules.ts
  - app_website:frontend/src/i18n/homepage.ts
unresolved_conflicts: []
result: partial
supersedes_acceptance: []
superseded_by: []
---

# HarmonyOS Kirin integration milestone

## Mechanical evidence

- The final ArkUI source built successfully through Hvigor in 28.909 seconds
- The generated ARM64 HAP is 9,176,981 bytes with SHA-256 `21c13e66d30f8f8faca0c1cf0f4ee6c888e735c040534aa9f24e97e40173b2b0`
- Huawei `hap-sign-tool verify-app` found signing block version 3, verified `libc++_shared.so`, `libentry.so` and `librwkv_mobile.so`, verified the SHA-256 digest, and returned `verify-app success`
- Signature inspection identifies the embedded Provision Profile as `debug`, so this artifact is valid for the registered development device and is not a public end-user release artifact
- The same HAP installed as an upgrade and launched successfully on the reviewed arm64 Huawei `LMR-AL00` device running `OpenHarmony-6.1.0.115`; after removing the `/data/local/tmp` development fallback, the controlled on-device CANN benchmark completed from application-private model storage at `198.886 ms/token`, or `5.028 tok/s`; the final hot-device repeat after the large-group experiments completed at `204.246 ms/token`, or `4.896 tok/s`
- The public [v3 exact-model release](https://github.com/RWKV-APP/RWKV_APP/releases/tag/harmony-kirin9020-model-v3) contains 14 runtime artifacts totaling 2,237,114,134 bytes and one manifest; all 15 release assets total 2,237,119,919 bytes
- Mechanical comparison of the v3 JSON manifest and `KirinModelManifest.ets` found 14/14 matching file names, sizes and SHA-256 values, matching totals, and zero mismatches
- `pnpm check` completed with no errors for `app_website`; existing repository lint warnings remain
- `pnpm build` completed for the contracts, static Next.js frontend, Prisma client, and NestJS backend

## Requirement review

- Every current Huawei performance and correctness result uses logical model `RWKV7-G1h 2.9B 20260710 ctx10240`
- The exact source checkpoint, tokenizer, prepared W4A16 artifact, manifest sizes, SHA-256 values and conversion provenance remain bound by `SPEC-RWKV-KIRIN-MODEL-IDENTITY`
- The production path executes all 32 transformer layers with compiled CANN graphs on the Kirin NPU and reuses graphs and executors across tokens; the selected layout is grouped graphs for layers 0–1, 6–29 and 30–31 plus individual graphs for layers 2–5
- CPU participation is limited to embedding lookup, recurrent control calculations, state exchange and the W8 output head; it is reported in the application rather than described as full-NPU execution
- An eight-part W8 NPU output-head experiment remained at `load-head` for approximately 4 minutes 45 seconds on the target device and prevented the model from becoming ready; all eight temporary artifacts were removed, the final package retained the CPU W8 output head, and the next automatic benchmark completed normally
- Three eight-layer graphs and four six-layer graphs compiled successfully, but both layouts remained at `load-layer-6-build` for more than 100 seconds on the target device; all seven temporary device artifacts were removed and the final runtime retained the stable four-layer group maximum
- The fixed quality check recorded relative L2 `0.08248`, cosine similarity `0.99672`, and LAMBADA `5/5`
- The OpenAI-compatible local API returned the exact requested response in a real request

## Controlled performance review

The same-phone CPU comparison used the exact G1h 2.9B logical source model with a Q4_K_M GGUF artifact. The Huawei NPU package uses W4A16 because NNRT and GGUF require different encodings. This is an equivalent low-bit comparison, not a byte-identical artifact comparison.

| Path | Prefill | Decode |
| --- | ---: | ---: |
| CPU llama.cpp GGUF Q4_K_M | about 8.1 tok/s | about 3.7 tok/s |
| Kirin CANN / NNRT W4A16 grouped graphs, controlled whole-step benchmark | not measured by this decode-only fixture | 5.02 tok/s; final HAP repeat 5.028 tok/s |
| Kirin CANN / NNRT W4A16 grouped graphs, real chat | 5.4 tok/s | 5.2 tok/s |
| Kirin CANN / NNRT W4A16 grouped graphs, LAMBADA 5/5 | fixture-specific | mean 4.88 tok/s |
| Kirin CANN / NNRT W4A16 grouped graphs, hot-device repeat | not measured by this decode-only fixture | 4.65 tok/s; final post-experiment repeat 4.896 tok/s |

The real-chat Kirin Prefill result is approximately 67 percent of the CPU Prefill rate. The controlled Kirin benchmark and real-chat Decode results are approximately 36–41 percent faster than the CPU baseline; the hot-device repeat remains approximately 26 percent faster than CPU. The implementation has crossed the `5.0 tok/s` gate in a controlled benchmark and a real chat, while the `4.65–4.88 tok/s` hot and multi-item results show that thermally sustained performance is not yet consistently above the gate.

## Semantic or visual review

- Android and HarmonyOS screenshots plus UI trees were captured for the home page, navigation, Chat, Completion, Vision entry, TTS, Role Play, Translator, Performance, API, conversations, settings, language, fonts, appearance, advanced prompts, export, cache and weight management
- The Ask panel now selects all ten Android prefixes by effective application language, applies the Android default prefix, clears a selected prefix on a second tap when conversation history exists, and exposes counts 2 through 8
- Follow-up question generation retains prior unique questions across retries and excludes them from subsequent prompts
- A real Kirin run generated two distinct questions, enabled `Send All`, produced one Q1/Q2 user message, generated both answers sequentially, and displayed switchable `Q1 · 1/2` and `Q2 · 2/2` branches
- The two batch answers reported Prefill `4.0 tok/s` and Decode `3.7` and `3.8 tok/s`
- Multi-style real generation and restart persistence were verified with `今 · 1/2` and `英 · 2/2` branches
- The Android-style update workflow now calls the current distribution and release-notes APIs, performs semantic-version comparison across platform build-number schemes, supports download and skip-version actions, and was verified on the HarmonyOS device
- Native ArkUI rich-text rendering was verified for headings, bold, italic, strike-through, links, inline code, quotations, ordered and unordered lists, horizontal tables, code blocks and images; the TeX path now renders stacked fractions with a fraction bar, nested roots, superscripts, subscripts, matrices, cases, aligned formulas, Greek letters and common set and calculus symbols
- Fenced code covers the Android language catalog with common and language-specific keywords, line and block comments, Python triple-quoted strings, JSON/YAML/CSS properties, HTML tags, Rust lifetimes, decorators and six-level rainbow brackets; Python, JSON, SQL, HTML and Rust fixtures were captured on the Kirin device
- The complex TeX fixture was captured on the Kirin device with a 2 by 2 matrix, a two-row piecewise function, a summation containing a stacked fraction, inline exponents, Greek letters and a cube root; the final evidence is `rwkv_harmony:build/parity/tex-pass/harmony-complex-tex-final.jpeg`
- Android and HarmonyOS Neko home cards and model selectors were captured in paired screenshots; the Harmony selector exposes both the 1.5B Neko NPU W8A16 and CPU Q6_K catalog entries
- Android and HarmonyOS debug menus and runtime-log panels were captured in paired screenshots; the Harmony panel reports Kirin 9020 NNRT, NPU accelerators, CANN package verification, 32/32 NPU layers and the measured token rate
- Android and HarmonyOS branch-delete controls now expand inline beneath the selected assistant message and expose model, performance and delete actions; both destructive confirmation dialogs were captured with UI trees, the Harmony test removed only the selected variant from a two-variant message, persisted one remaining variant, and then restored the pre-test conversations file with an identical SHA-256
- The optimized runtime produced a readable real answer about Paris while reporting Prefill `5.4 tok/s` and Decode `5.2 tok/s`
- The final five-item LAMBADA compatibility run returned all five expected completions with `5/5` exact match and mean Decode `4.88 tok/s`
- The conversations file was restored after all UI fixtures and final HAP installation; a receive-back SHA-256 check matched the pre-test backup at `99696ebb871c071cbfbc40d3dd9c64c26fc434214278e6daf1756e03bb028c09` and contained all three original records

## Distribution review

- The application can discover, download, pause, resume, verify and load the exact 2.9B model without HDC file copying
- The website has a HarmonyOS platform card, Kirin messaging and a download URL contract
- The website intentionally keeps HarmonyOS download disabled while no public release-signed HAP is available
- The current signed HAP cannot be published as a general direct download because its debug Provision Profile is bound to registered development devices
- The current AppGallery Connect browser session is signed out, so no existing application record or production signing material can be inspected or created without the developer account authentication step

## 2026-07-28 Palm-Infra CPU-side optimization

- The reviewed [TencentYoutuResearch/Palm-Infra](https://github.com/TencentYoutuResearch/Palm-Infra) checkout was commit `df480daff998402c731eb7eb7e7fd7f029fac9ce`; the relevant reusable idea was to compute multiple decode outputs per activation load instead of invoking an independent row dot product for every output
- `rwkv_harmony:entry/src/main/cpp/cann_cpu_support.cpp` now uses an independently implemented eight-row AArch64 INT8 dot-product kernel in both the standalone and batched quantized matrix-vector pools; the output-head pool uses four pinned workers after a true-device 4-versus-6-thread comparison
- The same-device pre-change benchmark recorded `4.68 tok/s`, with average controls `5.60503 ms`, NPU `188.524 ms`, and output head `18.6025 ms`
- A comparable warm post-change benchmark recorded `4.78 tok/s`, with average controls `5.18559 ms`, NPU `186.304 ms`, and output head `16.6482 ms`; controls improved by about 7.5 percent and the CPU output head by about 10.5 percent
- A hotter four-thread repeat recorded `4.58 tok/s`, with average controls `6.71323 ms`, NPU `194.218 ms`, and output head `16.4521 ms`; the output head remained faster while NPU and control time showed the existing thermal sensitivity
- After excluding timing lines, all 85 model-output summary lines were byte-identical between the pre-change and optimized traces
- The optimized LAMBADA run completed `5/5` with `100.00%` exact-match accuracy and mean Decode `4.69 tok/s`
- The rebuilt HAP has SHA-256 `8496f2d7a6227b2272d0a65e6da318753c1d9f75630d54e0f7a6d928ce8bfd49`, installed successfully as an upgrade on the target Huawei device, and passed `hap-sign-tool verify-app`, including native-library code-sign verification and SHA-256 digest verification

## Exclusions

- Thermally sustained Decode is not yet consistently above the required `5.0 tok/s` release gate even though the controlled benchmark and real-chat run crossed it
- The verified complex TeX and multi-language code subsets are substantially closer to Flutter, but the complete LaTeX command set and deeply nested TextMate grammar behavior do not yet have pixel-level parity with `flutter_math_fork` and `syntax_highlight`
- Dedicated RWKV-VL and SparkTTS model packages are represented by HarmonyOS local Vision and offline TTS alternatives rather than equivalent imported model artifacts
- Public installation still requires an AppGallery release, internal-test release, enterprise release, or production certificate and Provision Profile that are not present in the workspace
- The website changes passed local production build but were not deployed because no valid public HAP exists and the production deployment authority was not available
