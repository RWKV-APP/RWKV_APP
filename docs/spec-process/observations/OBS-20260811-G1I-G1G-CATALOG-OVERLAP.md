---
id: OBS-20260811-G1I-G1G-CATALOG-OVERLAP
type: observation
date: 2026-08-11
status: resolved
inputs: []
conflicts: []
decision: DEC-20260811-G1I-FORMAL-CATALOG-SUPERSESSION
canonical_assertions:
  - SPEC-RWKV-QUANTIZATION-CATALOG-CONTROL
  - SPEC-RWKV-QUANTIZATION-DELIVERY
affected_surfaces:
  - docs/contracts/model_quantization_catalog.md
  - remote/latest.json
---

# G1i and G1g occupy the same Snapdragon 8 Gen 3 catalog slot

## Observation

The Chat catalog contained both G1i and G1g 7.2B Android QNN w4a16 RMPack
rows limited to Snapdragon 8 Gen 3. The G1i row already supplies the complete
consumer slot with a published formal artifact.

## Implication

Keeping both rows exposed a duplicate older-generation choice after G1i had
become the formal selection for the same model size, quantization, backend,
artifact shape, platform and SoC.

## Proposed next step

Remove only the equivalent G1g 7.2B Snapdragon 8 Gen 3 row and retain G1g rows
whose SoC or consumer scope has no formal G1i replacement.

## Resolution

`DEC-20260811-G1I-FORMAL-CATALOG-SUPERSESSION` approved the exact replacement,
and the local catalog now contains only the formal G1i row for that slot.
