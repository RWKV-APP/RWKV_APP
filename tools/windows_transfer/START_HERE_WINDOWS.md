# Retired Windows restore instructions

> Do not execute this package. The legacy `rwkv_harmony` plus `rwkv_mobile`
> workspace has been retired. Current HarmonyOS work uses
> `rwkv_harmony_standalone`, and current native-engine work uses
> `rwkv-mobile`. The remaining instructions are historical evidence only.

## 1. Verify the code archive

After expanding `rwkv-harmony-windows-code.zip`, open PowerShell in the expanded directory:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\VERIFY_CODE_WINDOWS.ps1
```

## 2. Restore the sibling workspace

For an immediately usable source snapshot:

```powershell
.\RESTORE_WORKSPACES.ps1 -Destination C:\rwkv-kirin-workspace
```

To clone the public Git remotes at the recorded base revisions and reconstruct the staged, unstaged, and untracked state:

```powershell
.\RESTORE_WORKSPACES.ps1 -Destination C:\rwkv-kirin-workspace -AttachGitHistory
```

Do not rename `rwkv_harmony` or `rwkv_mobile`, and keep them beside each other

## 3. Install DevEco Studio

Install stable DevEco Studio 6.1.1 Release for Windows and its HarmonyOS 6.1.1/API 24 Native SDK. Open `C:\rwkv-kirin-workspace\rwkv_harmony`

Let DevEco recreate `local.properties` and generated dependency directories. The transfer intentionally excludes the Mac copies

## 4. Recreate debug signing

Log in to the Huawei developer account, connect and unlock the Pura 80 Pro, then configure automatic debug signing under:

```text
File > Project Structure > Project > Signing Configs
```

No private signing key or password is stored in this transfer

## 5. Restore the model

Expand and verify `rwkv-kirin-0.1b-model.zip`. Its `370658...` model is source-Mac host-verified and still requires Windows token-1 plus phone validation. Send the model and tokenizer to the debug application sandbox using the commands in `docs\architecture\harmony-windows-transfer.md`

## 6. Build and verify the phone

Use DevEco Run for the first signed build, then follow the PowerShell scripts in `rwkv_harmony\tools`

The 26/26 NNRT suite is a functional regression and includes at least one recorded CPU partition. Current T=16 prefill also has 12 hybrid NPU/CPU graphs. The full-NPU target is reached only after a long Prompt exercises all 27 model graphs and every graph reports `CPU:0` with at least one NPU partition

For the complete process and current limitations, read:

```text
rwkv_app\docs\architecture\harmony-windows-transfer.md
rwkv_harmony\README.md
rwkv_harmony\docs\pura-80-pro-device-report.md
rwkv_harmony\docs\current-nnrt-partition-status.md
```
