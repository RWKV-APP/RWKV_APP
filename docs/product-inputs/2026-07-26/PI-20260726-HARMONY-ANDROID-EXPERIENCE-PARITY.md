---
id: PI-20260726-HARMONY-ANDROID-EXPERIENCE-PARITY
type: product_input
captured_date: 2026-07-26
source_date: 2026-07-26
source: user
category: product
status: merged
effective_status: active
delivery_status: in_progress
canonical_assertions:
  - SPEC-RWKV-HARMONY-USER-PARITY
  - SPEC-RWKV-HARMONY-DISTRIBUTION
delivery_surfaces:
  - docs/requirements/harmony_kirin_delivery.md
  - pubspec.yaml
  - lib
  - rwkv_mobile_flutter:.
  - rwkv_harmony:.
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE
---

# Deliver the Android RWKV experience directly on HarmonyOS

## Raw statement

> 我们最终想让用户能直接，就是直接在华为手机上直接获得和那个其他安卓手机上的同样的这种完全一样的体验。同样的 UI，然后同样的推演情。

> 没做完就继续，做完了就跟我说停，就不要继续做了。

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- A normal user installs and uses the HarmonyOS product directly on a Huawei phone without a development computer or manual HDC workflow
- The HarmonyOS build exposes the same user-visible UI, interaction flow, persisted chat behavior, and inference semantics as the Android RWKV App
- Work remains in progress until complete real-device and distribution acceptance passes
- Once every acceptance surface passes, report completion and stop further implementation
