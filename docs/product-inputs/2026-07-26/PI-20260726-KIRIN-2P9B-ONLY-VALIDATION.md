---
id: PI-20260726-KIRIN-2P9B-ONLY-VALIDATION
type: product_input
captured_date: 2026-07-26
source_date: 2026-07-26
source: user
category: product
status: merged
effective_status: active
delivery_status: in_progress
canonical_assertions:
  - SPEC-RWKV-KIRIN-MODEL-IDENTITY
  - SPEC-RWKV-KIRIN-NPU-RUNTIME
delivery_surfaces:
  - docs/requirements/harmony_kirin_delivery.md
  - rwkv_mobile:converter
  - rwkv_mobile:src/backends/nnrt
  - rwkv_harmony:.
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records:
  - ACC-20260726-KIRIN-2P9B-ENGINEERING-VALIDATION
  - ACC-20260727-HARMONY-KIRIN-INTEGRATION-MILESTONE
---

# Validate Kirin delivery exclusively with the exact 2.9B model

## Raw statement

> 我说要用 2.9B 的模型去验证，去在华为的手机上去验证

> 我要求你必须仅仅使用 2.9B 的模型去给我验证，不要再给我说 0.1B 了

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- Huawei phone validation must use the exact logical G1h 2.9B model required by `SPEC-RWKV-KIRIN-MODEL-IDENTITY`
- Results from smaller or different checkpoints cannot be used to characterize, compare, or accept the Kirin 2.9B path
- Successful validation requires real generation from the complete 2.9B model on the Huawei phone together with Kirin NPU execution evidence
