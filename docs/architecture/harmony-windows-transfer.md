# Retired HarmonyOS Kirin workspace transfer to Windows

> Status: historical and non-executable as of 2026-08-28. The legacy
> `rwkv_harmony` plus `rwkv_mobile` transfer topology has been retired. Do not
> use this document to create or restore those directories. Current HarmonyOS
> product work belongs to `rwkv_harmony_standalone`; current native-engine work
> uses the sibling `rwkv-mobile` checkout. The remaining text is preserved only
> as historical migration evidence.

This guide described how to preserve and resume an earlier Huawei Pura 80 Pro and Kirin 9020 workspace on a new Windows computer

## Transfer boundary

The portable workspace keeps these directories as siblings:

```text
rwkv_app/
rwkv_mobile/
rwkv_mobile_flutter/
rwkv_harmony/
app_website/
```

The current HarmonyOS host compiles `rwkv_mobile` directly from the sibling directory. The native NNRT backend and converter are still uncommitted working-tree files, while `rwkv_harmony` has no Git metadata. A transfer made only from remote Git revisions would lose the active implementation

The generated transfer set therefore contains:

- final source snapshots for all five directories
- base Git revision, branch, status, staged patch, unstaged patch, and untracked overlay for each Git repository
- the non-Git HarmonyOS source snapshot
- Windows restore, checksum, build, signing, install, launch, log, and screenshot instructions
- deterministic golden files and selected Kirin device evidence
- a separate source-Mac host-verified Kirin 0.1B model archive
- a separate last-known signed HAP archive when that artifact exists

Private signing keys, passwords, local environment values, IDE state, macOS SDKs, generated build paths, and rebuildable caches are excluded. Four tracked source documents or developer tools retain historical Mac path examples and are explicitly allowlisted by the transfer audit

## Windows prerequisites

Huawei lists Windows 10 or 11 64-bit, at least 16 GB RAM, and at least 100 GB disk for DevEco Studio. For C++ builds and local model work, 32 GB RAM and 200 GB free disk are a more comfortable practical target

Install the current stable DevEco Studio 6.1.1 Release from Huawei. In SDK Manager, install the matching HarmonyOS SDK with API 24, Native SDK, HMS SDK, CMake, Ninja, HDC, Hvigor, and OHPM. The project currently declares:

```text
compileSdkVersion  6.1.1(24)
targetSdkVersion   6.1.0(23)
compatibleSdkVersion 5.0.2(14)
ABI                arm64-v8a
```

Do not copy the macOS SDK directory to Windows. DevEco Studio and the official Command Line Tools provide platform-specific SDK executables

Official references:

- [DevEco Studio and Windows system requirements](https://developer.huawei.com/consumer/cn/deveco-studio/)
- [Command-line build, signing, HDC install, and Ability launch](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-command-line-building-app)
- [HarmonyOS application signing overview](https://developer.huawei.com/consumer/cn/develop-novice-guide/)
- [build-profile.json5 configuration](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-hvigor-build-profile-V5)
- [Neural Network Runtime Kit](https://developer.huawei.com/consumer/cn/sdk/neural-network-runtime-kit)

## Restore

1. Copy the complete transfer folder to a local NTFS directory
2. Open PowerShell in that folder and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\VERIFY_ALL_WINDOWS.ps1
```

3. Expand `archives\rwkv-harmony-windows-code.zip`
4. Enter the expanded code directory and run its verifier
5. Restore working directories:

```powershell
.\RESTORE_WORKSPACES.ps1 -Destination C:\rwkv-kirin-workspace
```

This creates immediately usable source snapshots without Git history. To recreate Git metadata and the original staged, unstaged, and untracked state from the public remotes, add `-AttachGitHistory`

Before using Git on Windows:

```powershell
git config --global core.autocrlf false
git config --system core.longpaths true
```

The long-path command requires an elevated terminal. It is strongly recommended because CMake dependency directories can exceed the legacy Windows path limit

## First DevEco synchronization

1. Open `C:\rwkv-kirin-workspace\rwkv_harmony` in DevEco Studio
2. Mark the project as trusted
3. Confirm `rwkv_mobile` is beside `rwkv_harmony`
4. Let DevEco install OHPM dependencies from the lockfiles
5. Confirm the selected SDK is HarmonyOS 6.1.1/API 24 with Native SDK support
6. Do not restore the transferred Mac `local.properties`; DevEco creates a Windows-specific file
7. The restore script creates `rwkv_app\.env` from the included secret-free `.env.example`; add local values only when a feature actually needs them

The DevEco terminal should report usable tools:

```powershell
node -v
hvigorw -v
ohpm -v
hdc version
hdc list targets
```

## Signing

A signed HAP is required for a physical phone. The ordinary transfer archive contains no private key, keystore password, cached encrypted signing block, or Mac credential path

On Windows, log in to the same Huawei developer account and configure a new debug signing identity in:

```text
File > Project Structure > Project > Signing Configs
```

Use DevEco automatic signing for the connected Pura 80 Pro. The root `build-profile.json5` intentionally stays free of signing material

If DevEco reports a signature mismatch while updating the previously installed bundle, preserve any model file you still need before uninstalling. Removing the installed application also removes its private model directory

## Build

The simplest first build is the DevEco Run button after signing is configured

The transfer also includes Windows scripts under `rwkv_harmony\tools`:

```powershell
$env:HARMONY_COMMAND_LINE_TOOLS = 'C:\path\to\command-line-tools'
.\tools\build_harmony_hap.ps1
.\tools\verify_harmony_hap.ps1 .\build\artifacts\rwkv-chat-harmony-nnrt-unsigned.hap
python .\tools\build_signed_hap_from_cache.py
```

The signing helper reads DevEco's own encrypted cached signing configuration for the current Windows account only during the build and restores the secret-free profile in a `finally` block

The HAP verifier checks package layout, ARM64 native objects, and the dynamic-dependency allowlist. It does not determine whether inference ran on NPU, CPU, or a mixed driver partition

## Install and run

Keep the phone unlocked for Ability launch and interactive verification

```powershell
$env:HDC_BIN = 'C:\path\to\sdk\default\openharmony\toolchains\hdc.exe'
.\tools\run_signed_hap.ps1 .\entry\build\default\outputs\default\entry-default-signed.hap
```

Equivalent official HDC commands:

```powershell
hdc list targets
hdc file send .\entry-default-signed.hap data/local/tmp/entry-default-signed.hap
hdc shell bm install -p data/local/tmp/entry-default-signed.hap
hdc shell rm -rf data/local/tmp/entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.rwkvzone.kirinlab -m entry
hdc shell hilog -x > .\kirinlab-hilog.txt
```

Capture a real-device screenshot:

```powershell
hdc shell snapshot_display -f /data/local/tmp/rwkv.jpeg
hdc file recv /data/local/tmp/rwkv.jpeg .\rwkv.jpeg
```

## Model restore

Expand `archives\rwkv-kirin-0.1b-model.zip` and verify its internal manifest. The expected specialized model is:

```text
rwkv7-g1d-0.1b-20260129-ctx8192-nnrt-f16.st
bytes   382205426
sha256  3706582deaf23056ac284afcd1203d62102028bcc9fc88559858e6e3566ac208
```

This file was regenerated and compared tensor-by-tensor on the source Mac. Its conversion report marks device validation as false. The runtime also accepts the earlier device-tested artifact with SHA-256 `23d636c3c4f37f29db180316ede77cae7cb602879b57c94c295947919258a0d5`

For a debug-signed application, send the model and tokenizer to the application sandbox:

```powershell
hdc file send -b com.rwkvzone.kirinlab .\rwkv7-g1d-0.1b-20260129-ctx8192-nnrt-f16.st ./data/storage/el2/base/haps/entry/files/
hdc file send -b com.rwkvzone.kirinlab .\b_rwkv_vocab_v20230424.txt ./data/storage/el2/base/haps/entry/files/
```

The converter and independent tensor verifier are preserved under `rwkv_mobile\converter`. Use CPython 3.12 and the version-pinned packages in `requirements-nnrt.txt`. The lock does not pin platform wheel hashes, and PyTorch does not guarantee bitwise identity across operating systems. A Windows rebuild is usable by this App only after its complete SHA-256 matches a registered artifact and it passes token-1 and phone generation checks

The two local 2.9B GGUF files are excluded from the main transfer because they use llama.cpp CPU/ARM NEON and do not satisfy the NPU-only target

## NPU acceptance

Current evidence has an important boundary:

- the current 27 NNRT graphs contain 15 `NPU:1, CPU:0` partitions and 12 T=16 prefill partitions reported as `NPU:4, CPU:3`
- the 1,899-token Prefill result of 91.1 tok/s came from this hybrid NPU/CPU prefill path
- the 26/26 suite is a functional and numerical NNRT regression; its L2Norm case has a recorded `NPU:0, CPU:1` partition
- the transferred signed HAP contains both NNRT and llama.cpp/Vulkan, and the 2.9B GGUF route uses CPU

Read `rwkv_harmony\docs\current-nnrt-partition-status.md` and keep the current device logs in `evidence\device`

For the 0.1B model, accept the Windows migration only after all of these are true on the connected Pura 80 Pro:

- the model and device page names `NPU_ohos.boot.hardware.kirin9020_v2_0`
- the selected model is the 0.1B NNRT-prepared safetensors file, with 2.9B GGUF files moved out of the app sandbox
- the 26-operation NNRT self-test reports `26/26` as a functional regression
- token-1 golden verification passes
- a Chinese prompt produces a coherent response and reports separate prefill and decode rates
- HiLog contains the NNRT/NPU execution records
- a long Prompt triggers all 27 current model graphs, every graph reports `CPU:0`, and every graph reports at least one NPU partition

The current 12 hybrid prefill graphs are a known failing result for the full-NPU criterion. The Windows computer can build and drive direct NNRT inference and is the continuation environment for removing those CPU partitions. CANN DOPT/OMG quantization and AscendC custom-operator work still require Huawei's supported Linux environment; Windows or WSL support for that toolchain should not be assumed
