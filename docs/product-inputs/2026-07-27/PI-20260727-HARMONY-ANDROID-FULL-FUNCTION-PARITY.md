---
id: PI-20260727-HARMONY-ANDROID-FULL-FUNCTION-PARITY
type: product_input
captured_date: 2026-07-27
source_date: 2026-07-27
source: user
category: product
status: merged
effective_status: active
delivery_status: in_progress
canonical_assertions:
  - SPEC-RWKV-HARMONY-USER-PARITY
delivery_surfaces:
  - docs/requirements/harmony_kirin_delivery.md
  - lib
  - rwkv_harmony:.
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE
---

# Reproduce every Android RWKV Chat function on HarmonyOS

## Raw statement

> 我认为你还没有完全复刻 UI 的实现，当我说复刻时，我期望你在 HarmonyOS 的 RWKV Chat 上实现 Android 侧的 RWKV Chat 中的所有功能。你需要使用截屏能力和读屏能力，去一点儿一点地对齐我们双端的 App。

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- HarmonyOS parity covers every user-visible function and workflow discoverable in the current Android RWKV Chat, not only the chat home screen or a representative subset
- The Android reference phone must be audited with real screenshots, accessibility or UI-tree reads, and interaction traversal
- Every Android page, control, state, modal, gesture, persisted behavior, and error path must map to an implemented and real-device-verified HarmonyOS counterpart
- Acceptance requires paired Android and HarmonyOS evidence plus a complete feature matrix with no unexplained missing Android function
