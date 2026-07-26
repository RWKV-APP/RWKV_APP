---
id: PI-20260725-HARMONY-WINDOWS-TRANSFER
type: product_input
captured_date: 2026-07-25
source_date: 2026-07-25
source: user
category: process
status: merged
effective_status: active
delivery_status: verified
canonical_assertions:
  - SPEC-RWKV-REPOSITORY-BOUNDARIES
  - SPEC-RWKV-VERIFICATION-BOUNDARY
  - SPEC-RWKV-WORKSPACE-OWNERSHIP
delivery_surfaces:
  - tools/package_harmony_windows_transfer.sh
  - docs/architecture/harmony-windows-transfer.md
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260725-HARMONY-WINDOWS-TRANSFER
---

# Package the HarmonyOS NPU workspace for Windows transfer

## Raw statement

> 我打算完全迁移这个项目在一台全新的 Windows 电脑上去做，能不能把必要的代码整合打包一下？然后把必要的过程整包打合一下？然后都放到某个桌面的文件夹中，然后我发到另外一台电脑上

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- Create one transferable desktop folder containing the source state required to continue the current Huawei HarmonyOS and Kirin NPU work on a new Windows computer
- Preserve uncommitted cross-repository implementation changes rather than relying only on Git history
- Include a repeatable Windows setup, signing, build, install, device verification, and troubleshooting process
- Produce an archive and integrity manifest that can be checked after transfer
- Exclude macOS-only SDK binaries and private signing material; document how Windows recreates those machine-specific prerequisites
