# HarmonyOS Windows transfer package

Status: completed

Started: 2026-07-25

## Linked Truth

This plan delivers `PI-20260725-HARMONY-WINDOWS-TRANSFER` under `SPEC-RWKV-REPOSITORY-BOUNDARIES`, `SPEC-RWKV-VERIFICATION-BOUNDARY`, and `SPEC-RWKV-WORKSPACE-OWNERSHIP`

The package covers the Flutter frontend, native engine, Flutter adapter, HarmonyOS host prototype, model conversion and verification tools, current dirty-worktree state, and the evidence needed to resume Kirin NPU development

The unrelated current conflict `CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW` does not block this migration package

## Scope

Create a portable source, model, known-good artifact, provenance, and operating-guide set that can be copied from the current Mac to a new Windows development computer

## Intended behavior

- A single Windows-compatible ZIP expands into a self-contained transfer folder
- Source snapshots contain tracked, untracked, and modified files needed for the current work
- A manifest records origin repositories, revisions, dirty state, file hashes, expected large assets, and excluded machine-specific material
- Windows instructions cover DevEco Studio and SDK setup, debug signing, native build, HAP install, launch, logs, screenshot capture, and NPU-only acceptance
- A verification script detects transfer corruption and missing required files before development resumes

## Exclusions

- macOS executable SDKs and caches that cannot run on Windows
- private signing keys, certificates, passwords, tokens, cookies, and access-bearing URLs
- disposable build products that can be reproduced on Windows
- unrelated large caches and local IDE state

## Milestones

1. Inventory the live repositories, dirty worktrees, HarmonyOS project, build dependencies, signing references, model files, and existing evidence
2. Add a repeatable packaging tool and a durable Windows migration guide
3. Generate the desktop transfer folder, source snapshots, offline source dependencies, selected model assets, manifests, and checksums
4. Create a Windows-compatible ZIP and verify it by independent extraction and hash checking
5. Inspect representative source, process, and evidence files from the extracted copy

## Mechanical checks

- Run `dart run tools/bin/check_specification.dart`
- Run `git diff --check` in every changed Git repository
- Run the package verifier against both the staging folder and an independently extracted ZIP
- Compare recorded Git revisions and dirty-state patches with each source snapshot
- Check that secret and signing-key patterns are absent from the package

## Result-level review

The root Codex agent will inspect the extracted Windows instructions, the current NNRT implementation, the HarmonyOS host entrypoints, model manifests, and the verification output. A successful archive command alone is insufficient

## Progress

- 2026-07-25: Captured the Windows migration requirement and started live workspace inventory
- 2026-07-25: Inventoried five sibling workspaces, current dirty and untracked state, signing exclusions, model assets, device evidence, and DevEco/HDC prerequisites
- 2026-07-25: Added Windows PowerShell build, HAP verification, install, launch, log, screenshot, integrity, and workspace-restore tools
- 2026-07-25: Regenerated the NNRT-prepared 0.1B model twice with identical bytes and independently compared all 403 prepared tensors against the 402-tensor generic source
- 2026-07-25: Corrected the transferred runtime boundary after reviewing raw device partitions: 15 current graphs are NPU-only and 12 T=16 prefill graphs remain hybrid NPU/CPU
- 2026-07-25: Completed two full packaging loops; the second independently verified 3,077 code files, 6 model files, 2 HAP files, and the 6-file outer transfer set
- 2026-07-25: Reconstructed all four Git repositories from base revisions plus staged, unstaged, and untracked overlays and matched every recorded status exactly

## Discoveries and decisions

- The transfer must preserve working-tree files because the current Kirin NNRT backend is intentionally uncommitted
- Platform SDK executables and debug signing identity are machine-specific and will be recreated on Windows
- The 0.1B NNRT-prepared model and tokenizer are included with exact size, SHA-256, conversion report, dependencies, and an independent tensor verifier
- The two 2.9B GGUF files are documented but excluded because their current HarmonyOS route uses llama.cpp CPU/ARM NEON
- Historical absolute path fields in Harmony JSON evidence are sanitized in the transfer copy; four tracked developer documents or tools with example Mac paths remain under an explicit audit allowlist
- The current signed HAP is included as a private comparison artifact and is fixed to 68,239,984 bytes and SHA-256 `baa91844b76fb7a96d0576cb3663ba87416c1e2cd6fbe1c08f5497e5683fd747`
- The current full-NPU objective remains open because 12 T=16 prefill graphs have recorded CPU partitions

## Outcome

The packaging implementation, restore path, model archive, signed-HAP archive, source-state preservation, secret audit, malicious-ZIP rejection, and independent extraction path passed the complete staging exercise

The delivery invocation writes `RWKV-Harmony-Windows-Transfer-2026-07-25` and its all-in-one ZIP plus portable SHA-256 sidecar to the source Mac Desktop. The generated manifests inside that final folder are the definitive hashes for transfer

## Remaining gaps

- PowerShell scripts received static and behavior-equivalent restore review on macOS; native PowerShell and DevEco execution require the destination Windows computer
- The source Mac no longer has its HarmonyOS SDK or HDC installation, so this transfer turn could not rebuild the HAP or rerun the phone
- The `370658...` model is source-Mac host-verified and still needs Windows token-1 plus real-device generation acceptance
- The 12 hybrid prefill graphs still need implementation work before the user's full-NPU criterion can pass

## Retrospective

The first packaging loop exposed over-broad runtime claims and insufficient archive hardening. Independent review added repository state fingerprints, complete ZIP-root verification, PowerShell 5.1-compatible path handling, secret-free environment restoration, nested-history exclusion, fixed HAP identity, device-log preservation, and explicit host-versus-device model evidence before final delivery
