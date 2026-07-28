---
id: PI-20260727-HARMONY-WEBSITE-UI-PARITY
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
  - SPEC-RWKV-HARMONY-DISTRIBUTION
delivery_surfaces:
  - docs/requirements/harmony_kirin_delivery.md
  - lib
  - rwkv_harmony:.
  - app_website:.
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE
---

# Deliver the Android experience from the website on HarmonyOS

## Raw statement

> 我的最终目标是，用户可以成功地在我的网站上，使用麒麟或者华为的手机下载安装包。这个包里可以正常使用华为的 NPU 去执行运算。

> 我希望你把我们在安卓手机上的这个 UI 和交互，完全 1:1 地复制到这个华为的鸿蒙系统上。确实可以不再复用我们当前的 Flutter 项目。

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- A Huawei-phone user can download the production HarmonyOS package from the project website and install it without developer tooling
- The HarmonyOS application reproduces the Android application's user-visible UI, states, navigation, and interactions at 1:1 functional and visual parity
- The HarmonyOS UI may use native ArkUI and does not have to reuse the Flutter runtime
- The installed production package selects the verified Huawei NPU inference path for the supported Kirin device and model
