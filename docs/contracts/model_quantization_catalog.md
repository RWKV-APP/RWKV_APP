# Model Quantization Catalog Contract

This document owns the RWKV App meaning of model quantization work. It governs
how a source checkpoint becomes an artifact that the application can discover,
download, select, and run. Exact live model rows remain in
`remote/latest.json`; this document does not duplicate that mutable matrix.

## SPEC-RWKV-QUANTIZATION-CATALOG-CONTROL — Catalog-Driven Quantization

For an RWKV App quantization request, inspect the live
`remote/latest.json` and its application consumers before selecting a converter,
backend, output format, or working node. The file is the core application model
catalog and the initial worklist for quantized artifacts, not incidental release
metadata.

Its `model_config` rows declare the current artifact matrix through fields such
as model size, quantization, application backend, supported platforms, SoC
limits, URL, file size, digest, tags, date, and debug visibility. The app bundles
this file as its fallback configuration and can replace it with the fetched
remote configuration. `FileInfo` parsing and remote-store filtering then use
the rows for model visibility, compatibility, local-file recognition, download
identity, and integrity metadata.

The catalog `quantization` field is a user-facing weight label, but named
technical formats remain distinguishable from generic weight-width aliases.
Every bundled build catalog and the `latest.json` fallback apply the following
normalization boundary:

- preserve named formats such as `Q4_K_M`, `NF4`, `Q6_K`, `Q8_0`, `LUT4`,
  `LUT6`, `LUT8`, `FP16`, and `BF16`, using their conventional uppercase spelling
- use `W4` for generic `INT4`, `4-Bit`, `w4a16`, `a16w4`, and equivalent
  activation/weight-order aliases
- use `W6` for generic `INT6`, `6-Bit`, `w6a16`, `a16w6`, and equivalent aliases
- use `W8` for generic `INT8`, `8-Bit`, `w8a16`, `a16w8`, and equivalent aliases
- keep existing `W4`, `W6`, and `W8` values unchanged
- preserve previously unseen technical format names until an explicit product
  ruling adds a display alias

Do not infer a `Wn` label solely from a digit embedded in a named format.
`Q6_K` and `Q8_0` retain their GGUF scheme identities, and `LUT6` does not imply
`W6`. G1f and G1i Core ML mixed INT4/LUT6 artifacts display `W4` because their
approved primary projection weight label is W4; that model-specific decision
does not convert standalone LUT formats into generic W labels. Artifact
filenames, URLs, immutable manifests, conversion records, and runtime evidence
continue to retain their exact technical schemes.

Capability tags are executable catalog contracts, not descriptive labels. In
particular, the VL `thinking` tag is governed by
`SPEC-RWKV-VL-THINKING-CAPABILITY`: only a VL cohort verified to support the
configured on/off prefixes may carry it, every required row in that cohort must
carry it, and the See UI derives both control visibility and the model-list
`Thinking` capability tag from the loaded or listed core row.

A catalog `backend` identifies the intended application consumer. Conversion
libraries, accelerators, and host compute are implementation choices selected
only after the required catalog rows are known. Existing MNN entries for other
models do not make MNN a default quantization target. CUDA availability on a
conversion host does not make CUDA an RWKV App output or catalog target unless
an explicit product requirement and consumer path say so.

The current contents of `remote/latest.json` are runtime data. Adding a local or
debug row is evidence of intended availability only; it does not by itself prove
that the artifact was produced, uploaded, downloadable, loadable, accepted on a
declared platform, or approved for release.

Catalog platform values name real consumer operating systems. `macos_debug` is
not a valid product platform and must not appear in current or retained catalog
JSON or in platform-filtering code. Debug or experimental state, when genuinely
needed, uses separate lifecycle metadata and never creates a synthetic
operating-system name.

### Verified Weight Discovery, Download, And Load Flow

The application resolves catalog weights through the following path:

1. `P.app.syncConfig()` first loads the sandbox copy, or the bundled
   `remote/latest.json` when no sandbox copy exists. Unless remote configuration
   is disabled, it then requests `GET <Config.domain>/get-demo-config`, replaces
   the active configuration with a successful response, persists that response,
   and re-runs model discovery and local-file checks. The default
   `Config.domain` is `https://api.rwkv.halowang.cloud`.
2. `P.remote.syncAvailableModels()` parses each demo's `model_config` rows through
   `FileInfo.fromJSON()`. The catalog URL path basename becomes the local file
   name; backend, platform, SoC, debug visibility, declared byte size, optional
   digest, and other row metadata determine visibility and downstream behavior.
   When the local-model scanner de-duplicates an exact GGUF file name against
   catalog rows, only rows that support the current operating system may hide
   that local file. A catalog row limited to other platforms must not make a
   manually supplied local GGUF disappear from the current platform's picker.
3. Relative catalog URLs are resolved by the user-selected download source. The
   reviewed catalog uses Hugging Face-style relative namespaces. The legacy
   `mollysama/rwkv-mobile-models/resolve/main/...` namespace maps to
   `models/RWKV/rwkv-mobile-models/resolve/master/...` on ModelScope. Formal G1i
   rows use `HaloWang/rwkv-weights/resolve/main/...` and map to
   `models/HaloWang1991/rwkv-weights/resolve/master/...` on ModelScope. Hugging
   Face uses the relative path unchanged, while AIFastHub or HF Mirror apply
   their own host and download suffix. Chinese locales default to ModelScope;
   other locales default to Hugging Face. The UI can select ModelScope,
   AIFastHub, HF Mirror, or Hugging Face.
4. Absolute `http://` or `https://` catalog URLs bypass the selected source and
   are used unchanged. Such rows must therefore be reviewed as direct endpoints,
   not assumed to inherit the selected mirror's transport or namespace policy.
5. `P.remote.getFile()` creates an `rwkv_downloader` task from the resolved URL
   to the model target path and supplies the row's declared byte size as the
   accepted size. A custom desktop model directory overrides the default.
   Otherwise Windows uses `<executable directory>/models` unless sandbox mode is
   enabled, macOS and Linux use `<documents>/models`, and mobile uses
   `<documents>/rwkv_chat_models`.
6. Starting chat passes the local model path, the catalog backend, and the
   bundled `assets/config/chat/rwkv_vocab_v20230424.txt` tokenizer through a
   typed `LoadRWKVModel` request to the local `rwkv_mobile_flutter` adapter. The
   adapter selects the backend-specific native load call, reports progress and
   terminal `LoadModelSteps`, and returns a non-negative model ID only after the
   native runtime reports a successful load.

In compact form, the owned flow is:

```text
bundled or cached catalog -> remote config override -> FileInfo/filtering
-> selected mirror or direct absolute URL -> rwkv_downloader -> local model file
-> LoadRWKVModel -> rwkv_mobile_flutter isolate -> native backend -> model ID
```

The catalog and download path currently establish local presence by declared
byte size, not content identity. `FileInfo` parses an optional `sha256`, but the
inspected download and local-file checks do not enforce it. Downloader
initialization also currently enables `allowAllSsl`; successful HTTPS transfer
must therefore not be represented as certificate-verified artifact provenance.
Download completion, runtime load completion, representative generation, and
real-device acceptance remain separate evidence states.

## SPEC-RWKV-QUANTIZATION-DELIVERY — Artifact Publication And App Acceptance

Quantization delivery proceeds against an explicit catalog cohort:

1. identify the exact source checkpoint and its digest
2. define the intended `latest.json` rows, including model size, quantization,
   application backend, platform or SoC limits, and debug or release visibility
3. produce the artifact cohort with a reproducible conversion recipe and record
   file identities, sizes, and digests
4. synchronize each intended catalog row without silently adding unrelated
   formats or backends
5. validate JSON parsing, `FileInfo` mapping, platform and SoC filtering, local
   recognition, download identity, file size and digest behavior
6. record catalog publication and device runtime acceptance as independent
   states; when download, loading, generation, or performance acceptance is
   claimed for a platform or device, verify it through the canonical App's
   visible user-facing UI under
   `SPEC-RWKV-CHAT-VISIBLE-UI-E2E-ACCEPTANCE`

Uploading artifacts, deploying a new remote catalog, or promoting debug rows to
release visibility are separate distribution actions and require explicit
authorization. Exact-device visible-UI acceptance is not a prerequisite for an
explicitly authorized artifact or catalog publication when immutable artifact
identity, size and digest, formal distribution sources, catalog parsing and
filtering, and compatibility with the already released application/runtime
contract are verified. Publication alone is not application, download,
runtime, generation, device, or performance acceptance, and no such claim may
be made until its independent acceptance is complete.

`remote/latest.json` is the core catalog, but specialized consumers can require
additional application mappings. For example, a VL model row may also require
the mappings governed by `docs/architecture/vl-model-update-guide.md`. Those
additional surfaces must be checked when the selected cohort needs them.

## G1i Formal Supersession Policy

G1i is the formal catalog generation for equivalent G1h slots and for the
specifically approved G1g slot below. A replacement must not change the
application consumer contract: model size, quantization, backend, artifact
shape, platform and, when applicable, SoC limitation must match.

Promoting a G1i row uses only real product platform names and declares only the
consumer operating systems that the App intentionally supports for that model
size and backend. Reusing exact weight bytes across Apple consumers does not
require every Mac-compatible model to appear on iPhone or iPad. Do not hide an
approved platform behind a Debug-only pseudo-platform, and do not add `ios`
solely because the same artifact lineage is used on macOS. Record load,
generation, performance, cache, memory, and device limitations as separate
runtime evidence. Remove the corresponding G1h row when its complete
compatibility scope is replaced. When one G1h row also covers platforms not
declared for G1i, narrow the G1h platform list to the unmatched scope instead
of removing the row. Retain G1h rows for unique backends, platforms or SoCs
until an equivalent G1i artifact and consumer contract are available.

The identified earlier-generation replacements include the G1g 1.5B, 2.9B,
and 7.2B Apple MLX `W6` rows plus the G1g 7.2B Android QNN `W4` RMPacks for
Snapdragon 8 Gen 3 and 8s Gen 3. The artifact filenames retain their exact
six-bit MLX and `a16w4` schemes. The formal G1i rows occupy those complete
slots, so the duplicate G1g rows are removed. Other G1g rows remain available
when they target a SoC or consumer slot not declared by an equivalent formal
G1i row.

The current G1i Apple catalog exposes the non-QNN llama.cpp, WebRWKV, and MLX
rows for 1.5B, 2.9B, and 7.2B on both macOS and iOS. G1i 13.3B is intentionally
unsupported on iPhone and iPad, so its non-QNN Apple catalog scope includes
`macos` and excludes `ios`. Mobile Snapdragon QNN rows remain Android-only;
Snapdragon X Elite and X2 Elite QNN rows use the released Windows consumer
contract. Catalog visibility is the user-facing selection contract and is not a
claim that every declared size or backend has passed runtime or performance
acceptance on every Apple device. Those outcomes remain separately recorded and
never justify inventing `macos_debug`, adding an unsupported iOS entry, or
silently removing an approved platform.

The current Android G1i QNN catalog exposes 1.5B for Snapdragon 8 Elite Gen5,
8 Gen 5, 8 Elite, 8 Gen 3, 8s Gen 3, 7+ Gen 3, 8 Gen 2, 8+ Gen 1, 888, and
778. It exposes 2.9B for the same set except 778. Where an approved artifact
has identical bytes for more than one compatible SoC, each SoC keeps its own
catalog row and shares the immutable URL, size, and SHA-256 identity.

The current Windows G1i QNN catalog exposes 1.5B and 2.9B for Snapdragon X
Elite, X Plus, and X1 through the X Elite artifact, and for Snapdragon X2 Elite
Extreme, X2 Elite, and X2 Plus through the X2 Elite artifact. These rows replace
the equivalent G1h Windows QNN slots. Their formal artifact publication and
catalog visibility do not claim exact-device runtime or performance acceptance.

An unpromoted Windows G1i 7.2B QNN test cohort may be exposed to those same
Snapdragon X and X2 SoC groups through the online `latest.json` while its bytes
remain in `HaloWang1991/rwkv-weights-tmp`. Each such row must use the exact
anonymous HTTPS ModelScope resolve URL at a 40-hex immutable revision, stay
under the `artifacts/` namespace, declare `availableIn: ["modelscope"]`, and
match the independently verified byte size and SHA-256. The direct absolute URL
intentionally bypasses the user's selected mirror for this ModelScope-only test
cohort. Catalog publication remains pre-release visibility, not formal artifact
promotion or device runtime acceptance; formal promotion replaces the row with
the byte-identical source-selectable dual-repository URL.

The current Android G1i MediaTek catalog exposes the 1.5B `W8` NP7 artifact
for Dimensity 9300 and the 1.5B `W8` plus 2.9B `W4` NP9 artifacts for
Dimensity 9500. The Dimensity 9300 1.5B row replaces its equivalent G1h NP7
slot. There is no formal Dimensity 9300 2.9B G1i catalog row in this cohort.
Formal artifact publication and catalog visibility remain separate from
exact-device loading, generation, and performance acceptance.

The G1i 1.5B `Q6_K` and the 2.9B, 7.2B, and 13.3B `Q4_K_M` llama.cpp artifacts
retain those named catalog labels. They are Linux consumer artifacts. Each
Linux scope replaces only the equivalent G1h size and technical quantization
slot after the exact G1i bytes have been discovered, loaded, and used for
representative generation through the canonical Linux App UI. G1h rows for
other backends, platforms, or SoCs remain available until an equivalent G1i
consumer contract independently passes its acceptance boundary.

The explicit human rulings on 2026-08-22 authorize formal publication of the
accepted G1i CoreML 1.5B and 2.9B artifacts for macOS and iOS, followed by a
separate macOS-only formal partial release of the accepted 7.2B artifact. The
formal G1i 1.5B and 2.9B rows fully replace the matching G1f CoreML consumer
slots, so the superseded G1f rows are absent from the current bundled
`latest.json`, build-752 catalog, and their production selectors. Historical
build-743 and build-750 catalog snapshots remain unchanged, and delisting does
not delete the legacy provider artifacts. Promote each exact accepted cohort
through immutable TMP identity first to
formal ModelScope and then byte-identically to Hugging Face, verify both
providers anonymously, and expose source-selectable formal URLs with size and
SHA-256 identity in the bundled `latest.json` plus the production `latest.json`
and `752.json`. These formal rows do not use Debug lifecycle metadata. Build
752 and the latest fallback must both return the rows so RWKV Chat 4.7.0 and
4.7.1 can discover and download them. The 7.2B row declares only `macos` and
must not acquire iOS availability through the shared Apple weight lineage.

This publication is explicitly backend-scoped and partial. The retained macOS
visible performance and runtime evidence supports the formal artifact choice;
exact-device iOS load, generation, cache, memory, and performance acceptance
remains unverified and must not be inferred from shared Apple bytes or catalog
availability. Existing required G1i MediaTek rows also retain their independent
runtime-acceptance status, so this delivery is not a standard complete Chat
weight release. The formal 7.2B package is compatible with the released 4.7.0
and 4.7.1 config parser because unknown YAML keys are ignored, but those native
runtimes still load Decode and Prefill with CPU and Neural Engine. Catalog
publication to those versions therefore does not deliver the separately
measured CPU-and-GPU Decode speedup; that execution placement requires a later
App/runtime release. The 13.3B CoreML row remains a local Debug canary outside
formal or online publication and remains excluded from iOS.

This supersession changes catalog selection, not artifact identity or remote
distribution state. Every promoted G1i row must retain a source-selectable
relative URL plus its size and SHA-256 identity metadata. It must not pin an
absolute ModelScope or Hugging Face endpoint because that bypasses the user's
download-source selection. Deploying the bundled catalog to the remote
configuration service remains a separate authorized action.
