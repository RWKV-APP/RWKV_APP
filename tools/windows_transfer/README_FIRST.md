# RWKV HarmonyOS Windows transfer

This folder is a private transfer set for continuing the current RWKV Chat, HarmonyOS NNRT, and Kirin 9020 development work on another computer

Before extraction, compare the all-in-one ZIP with the adjacent `.sha256` file:

```powershell
(Get-FileHash .\RWKV-Harmony-Windows-Transfer-YYYY-MM-DD.zip -Algorithm SHA256).Hash.ToLowerInvariant()
```

The value must equal the first field in the sidecar. Then start inside the extracted folder:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\VERIFY_ALL_WINDOWS.ps1
```

Then expand `archives\rwkv-harmony-windows-code.zip`, run the verifier inside it, and read `START_HERE_WINDOWS.md`

Archives are separated deliberately:

- `rwkv-harmony-windows-code.zip` contains source snapshots, dirty-worktree provenance, tools, selected evidence, and the operating guide
- `rwkv-kirin-0.1b-model.zip` contains the source-Mac host-verified, device-unvalidated NNRT-prepared 0.1B safetensors model, conversion report, verifier, and tokenizer
- `rwkv-known-good-signed-hap.zip` contains the last signed dual-backend HAP available on the source Mac; it may include debug Profile and device authorization metadata, so do not publish it

The folder excludes private keys, keystore passwords, local `.env` values, Mac SDK executables, IDE caches, nested Git history, and rebuildable output directories. Restore creates a secret-free `.env` from `.env.example`

Treat the whole transfer set as private source material and send it only through a channel you control
