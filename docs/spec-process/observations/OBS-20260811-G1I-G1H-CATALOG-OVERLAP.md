---
id: OBS-20260811-G1I-G1H-CATALOG-OVERLAP
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

# G1i and G1h occupy overlapping catalog slots

## Observation

The local Chat catalog contained G1i Debug rows and G1h rows with the same
model size, quantization, application backend, platform and SoC scope. Keeping
both generations in the same selectable slot made the older generation remain
the formal choice even though the matching G1i artifact had already been
published.

## Implication

The catalog did not express G1i as the current formal generation and exposed
duplicate choices on the platforms already declared for G1i.

## Proposed next step

Approve a generation-supersession rule that promotes G1i for equivalent slots,
removes fully replaced G1h rows and narrows partially replaced G1h rows to
their unmatched compatibility scope.

## Resolution

`DEC-20260811-G1I-FORMAL-CATALOG-SUPERSESSION` approved the proposed rule and
the local catalog was synchronized to it. The approved iOS extension replaces
the G1h WebRWKV NF4 1.5B and 2.9B slots with G1i while retaining G1h on Web;
iPad Debug load and generation acceptance remains pending.
