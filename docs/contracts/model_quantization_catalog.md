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

## SPEC-RWKV-QUANTIZATION-DELIVERY — Artifact And App Acceptance

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
6. verify representative loading and generation on every platform or device
   claimed by the row through the canonical App's visible user-facing UI under
   `SPEC-RWKV-CHAT-VISIBLE-UI-E2E-ACCEPTANCE`

Uploading artifacts, deploying a new remote catalog, or promoting debug rows to
release visibility are separate distribution actions and require explicit
authorization. A local conversion success or valid JSON file is not sufficient
application acceptance.

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

The identified earlier-generation replacement is limited to the G1g 7.2B
Android QNN w4a16 RMPack for Snapdragon 8 Gen 3. The formal G1i 7.2B row
occupies that complete slot, so the duplicate G1g row is removed. Other G1g
rows remain available when they target a SoC or consumer slot not declared by
an equivalent formal G1i row.

The current G1i Apple catalog exposes the non-QNN llama.cpp, WebRWKV, and MLX
rows for 1.5B, 2.9B, and 7.2B on both macOS and iOS. G1i 13.3B is intentionally
unsupported on iPhone and iPad, so its non-QNN Apple catalog scope includes
`macos` and excludes `ios`. Snapdragon QNN rows remain Android-only. Catalog
visibility is the user-facing selection contract and is not a claim that every
declared size or backend has passed runtime or performance acceptance on every
Apple device. Those outcomes remain separately recorded and never justify
inventing `macos_debug`, adding an unsupported iOS entry, or silently removing
an approved platform.

G1i CoreML is explicitly deferred for the current release. `remote/latest.json`
must contain no G1i CoreML row, and no new G1i CoreML artifact is converted,
published, promoted, or released until a later explicit human ruling reopens
that cohort. Existing G1f CoreML catalog rows remain available. G1i CoreML
bytes that were already published remain preserved at their immutable remote
paths; artifact availability does not make them current catalog or release
candidates, and this deferral does not authorize remote deletion.

This supersession changes catalog selection, not artifact identity or remote
distribution state. Every promoted G1i row must retain a source-selectable
relative URL plus its size and SHA-256 identity metadata. It must not pin an
absolute ModelScope or Hugging Face endpoint because that bypasses the user's
download-source selection. Deploying the bundled catalog to the remote
configuration service remains a separate authorized action.
