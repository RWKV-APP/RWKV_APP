---
id: ACC-20260725-HARMONY-WINDOWS-TRANSFER
type: acceptance
date: 2026-07-25
owner: root Codex agent
inputs:
  - PI-20260725-HARMONY-WINDOWS-TRANSFER
decisions: []
canonical_assertions:
  - SPEC-RWKV-REPOSITORY-BOUNDARIES
  - SPEC-RWKV-VERIFICATION-BOUNDARY
  - SPEC-RWKV-WORKSPACE-OWNERSHIP
changed_surfaces:
  - .env.example
  - docs/architecture/harmony-windows-transfer.md
  - docs/architecture/workspace-map.md
  - docs/plans/2026-07-25-harmony-windows-transfer.md
  - docs/product-inputs/2026-07-25/PI-20260725-HARMONY-WINDOWS-TRANSFER.md
  - docs/spec-process/acceptance-records/ACC-20260725-HARMONY-WINDOWS-TRANSFER.md
  - docs/specs/02-repository-map.md
  - tools/package_harmony_windows_transfer.sh
  - tools/windows_transfer
  - rwkv_mobile:converter/convert_rwkv_to_nnrt_safetensors.py
  - rwkv_mobile:converter/nnrt_model_conversion_report.json
  - rwkv_mobile:converter/requirements-nnrt.txt
  - rwkv_mobile:converter/verify_rwkv_nnrt_safetensors.py
  - rwkv_mobile:src/backends/nnrt/nnrt_backend.cpp
  - rwkv_harmony:README.md
  - rwkv_harmony:docs/current-nnrt-partition-status.md
  - rwkv_harmony:docs/pura-80-pro-device-report.md
  - rwkv_harmony:entry/src/main/cpp/napi_init.cpp
  - rwkv_harmony:entry/src/main/cpp/nnrt_capability_suite.cpp
  - rwkv_harmony:entry/src/main/ets/pages/Index.ets
  - rwkv_harmony:tools/build_harmony_hap.ps1
  - rwkv_harmony:tools/build_signed_hap_from_cache.py
  - rwkv_harmony:tools/run_signed_hap.ps1
  - rwkv_harmony:tools/verify_harmony_hap.ps1
unresolved_conflicts:
  - CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
result: accepted
supersedes_acceptance: []
superseded_by: []
---

# HarmonyOS Windows transfer acceptance

## Mechanical evidence

- `dart run tools/bin/check_specification.dart` passed after registering the HarmonyOS repository alias and this transfer input
- `git diff --check` passed in `rwkv_app` and `rwkv_mobile`; Bash syntax and all transfer and converter Python files compiled successfully
- Two conversions of the 382,205,264-byte generic 0.1B source produced byte-identical 382,205,426-byte files with SHA-256 `3706582deaf23056ac284afcd1203d62102028bcc9fc88559858e6e3566ac208`
- The independent tensor verifier checked 402 source tensors and 403 prepared tensors: the marker was valid, every non-embedding tensor was exact, and the prepared embedding exactly matched the fixed four-thread FP32 LayerNorm reference
- The second full staging run audited and hashed 3,077 code-package files, 6 model-package files, 2 HAP-package files, and the 6-file outer transfer set
- Each internal ZIP and the all-in-one ZIP passed independent extraction, complete file-set comparison, and SHA-256 verification
- Negative archive tests confirmed that an extra top-level file and a duplicate ZIP member are rejected
- The secret audit found no private key, local environment value, signing material, nested dependency `.git`, symlink, forbidden Windows name, path collision, or unapproved source-machine absolute path
- The transfer fixed the signed HAP identity at 68,239,984 bytes and SHA-256 `baa91844b76fb7a96d0576cb3663ba87416c1e2cd6fbe1c08f5497e5683fd747`
- A behavior-equivalent restore simulation cloned all four Git repositories, checked out their recorded base revisions, applied staged and unstaged binary patches, copied untracked overlays, and reproduced every recorded `git status --porcelain=v1` line exactly
- Extracted review confirmed the NNRT converter, runtime hash allowlist, current partition-status note, raw current device log, self-test log, model conversion report, tokenizer, and HAP hashes

The unrelated Web Demo privacy conflict predates this acceptance and remains open. Its blocking scope does not overlap the private local transfer workflow

## Requirement review

The delivery preserves the complete current implementation state across `rwkv_app`, `rwkv_mobile`, `rwkv_mobile_flutter`, `rwkv_harmony`, and `app_website`. Git repositories carry base revision and branch provenance, staged and unstaged binary patches, untracked overlays, immutable state fingerprints, and an immediately usable final source snapshot. The non-Git HarmonyOS host is captured as a filtered Windows-safe source snapshot with required golden vectors, dependency source cache, and representative device evidence

The Windows guide covers integrity verification, sibling workspace restoration, secret-free Flutter environment creation, DevEco Studio and SDK setup, signing recreation, ArkUI and C++ build, HAP structure checks, HDC install and launch, logs, screenshots, model placement, and full-NPU acceptance. macOS SDK binaries, local signing secrets, environment values, IDE caches, and rebuildable outputs are excluded

## Semantic or visual review

The root agent opened an independently extracted transfer set and inspected representative frontend, native engine, HarmonyOS host, Windows PowerShell, model, manifest, and device-evidence files. The review also traced raw partition logs instead of relying on UI labels

That outcome review found a material runtime boundary and corrected the package before acceptance: the current model has 15 NPU-only NNRT graphs and 12 hybrid NPU/CPU T=16 prefill graphs. The 26/26 capability suite also contains a recorded CPU-only L2Norm partition. The package now describes both facts, retains the raw logs, and treats all-27-graph `CPU:0` as future real-device acceptance

No visual UI acceptance was required for the transfer artifact. The existing signed HAP is included for private comparison and same-device recovery, with an explicit warning that HAP integrity does not prove NPU-only execution

## Exclusions

- Native Windows PowerShell, DevEco Studio, signing, CMake, HDC, and phone execution were unavailable on the source Mac and remain destination-machine checks
- The source Mac's HarmonyOS SDK and HDC installation were no longer present, so no new HAP or screenshot was produced in this transfer turn
- The included `370658...` model has source-Mac tensor and integrity evidence; Windows token-1 and real-device generation remain required
- The current 12 hybrid T=16 prefill graphs do not satisfy the user's full-NPU goal and remain implementation work
- PyTorch package versions and Python 3.12 are recorded, while cross-platform wheel hashes and bitwise Windows reproduction are not claimed
- The 2.9B GGUF files are excluded from the main archive because their current HarmonyOS route uses llama.cpp CPU/ARM NEON
- No Git commit, push, public upload, or private signing-key transfer was performed
