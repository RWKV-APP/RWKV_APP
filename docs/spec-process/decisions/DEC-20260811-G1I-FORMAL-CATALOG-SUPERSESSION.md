---
id: DEC-20260811-G1I-FORMAL-CATALOG-SUPERSESSION
type: decision
date: 2026-08-11
status: approved
approved_by: user
inputs: []
observations:
  - OBS-20260811-G1I-G1H-CATALOG-OVERLAP
  - OBS-20260811-G1I-G1G-CATALOG-OVERLAP
conflicts: []
supersedes: []
superseded_by: []
acceptance_records: []
canonical_assertions:
  - SPEC-RWKV-QUANTIZATION-CATALOG-CONTROL
  - SPEC-RWKV-QUANTIZATION-DELIVERY
affected_surfaces:
  - docs/contracts/model_quantization_catalog.md
  - lib/model/file_download_source.dart
  - remote/latest.json
  - test/file_download_source_test.dart
  - test/g1i_catalog_supersession_test.dart
---

# Promote G1i and supersede equivalent older-generation catalog slots

## Decision

G1i is the formal RWKV7 catalog generation for the equivalent G1h slots covered
by this decision and for the specifically identified G1g slot below. Every
replacement must preserve model size, quantization, application backend,
artifact shape, platform and SoC compatibility.

Promote the currently declared G1i platforms and SoCs out of Debug visibility.
Delete a G1h row when G1i replaces its full scope. If a G1h row also serves
platforms that the G1i row does not yet declare, retain only that unmatched
platform scope. Keep G1h entries that do not yet have an equivalent G1i catalog
slot.

On iOS, replace the existing G1h WebRWKV NF4 1.5B and 2.9B slots with the
published G1i WebRWKV NF4 artifacts. Add iOS only to those two G1i rows and
leave the matching G1h rows available only on Web. Do not extend G1i 7.2B or
13.3B WebRWKV to iOS under this decision because no G1h iOS slot exists at
those sizes.

On Snapdragon 8 Gen 3 Android, remove the G1g 7.2B QNN w4a16 RMPack row because
the formal G1i 7.2B row matches its complete model-size, quantization, backend,
artifact-shape, platform and SoC slot. Do not remove other G1g rows whose SoC
or consumer scope is not covered by a formal G1i row.

Represent every formal G1i artifact with the source-selectable relative path
`HaloWang/rwkv-weights/resolve/main/...`. The download-source resolver maps that
namespace to `models/HaloWang1991/rwkv-weights/resolve/master/...` when the user
selects ModelScope, and leaves it in the Hugging Face namespace for Hugging
Face and compatible mirrors. Do not put an absolute ModelScope or Hugging Face
URL in these rows because an absolute URL bypasses source selection.

This decision authorizes the local bundled catalog and its canonical contract.
It does not deploy the remote configuration, upload artifacts, delete remote
weights, or by itself claim iOS real-device acceptance. The iPad Debug load and
representative generation gate remains separate.

## Reason

The user explicitly selected G1i as the formal successor to G1h and requested
equivalent replacement without removing compatibility that G1i does not yet
cover, then explicitly extended that equivalent replacement to the iPad/iOS
application catalog. The user subsequently required these rows to remain
switchable between ModelScope and Hugging Face instead of forcing one host.
The user then confirmed that the equivalent G1g 7.2B Snapdragon 8 Gen 3 slot
should also be replaced by the existing formal G1i row.
