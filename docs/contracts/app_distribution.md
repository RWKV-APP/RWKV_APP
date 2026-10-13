# App Binary Distribution Contract

## Release 4.8.4

Version 4.8.4 uses build 761 and Flutter 3.47.5, retaining the complete
Android, iOS, macOS, Windows and Linux package and distribution matrix.
It fixes Android roleplay GGUF model-loading crashes by using ggml's pthread
pool, improves desktop CPU inference defaults, and improves WebRWKV GPU
compatibility and generation on supported Adreno and Mali devices.
Pin the affected Android, Windows and Linux native archives to the reviewed
release-compatible engine source and verified archive and file hashes.
Apple builds retain their existing native archive identities.
Core AI and new model-weight publication remain outside this release.

Use native Flutter/platform build and provider tools; Fastlane remains retired.
Generate localization from committed ARB files with pinned `intl_utils` 2.8.14
before platform builds. Verify the changed runtime paths in the canonical
visible App's chat page, using the exact VS Code `debug (halo)` launch for
physical-device Debug sessions. Native benchmarks and package checks remain
engineering evidence and do not replace App acceptance.
Prepend the approved three-item 4.8.4 section in all six locales while preserving
the complete 4.8.3, 4.8.2, 4.8.1 and 4.8.0 history. Freeze `release.json`,
adapter revision and native hashes before packaging, signing and publication.
Verify direct downloads, review submissions and public store availability
separately; pending review is not public availability.

## Release 4.8.3

Version 4.8.3 uses build 759 and Flutter 3.47.5, retaining the existing
Android, iOS, macOS, Windows and Linux package and distribution matrix.
The release includes confirmed import of uncatalogued RWKV GGUF models,
Dimensity 9500 generation performance improvements and iOS startup compatibility.
The Android native archive carries the reviewed NP9 optimization on the
release-compatible engine baseline; other platforms retain their existing
native bytes. Freeze the exact Android archive identity in the adapter manifest.
Core AI and new model-weight publication remain outside this release.

Use native Flutter/platform build and provider tools; Fastlane remains retired.
Generate localization from the committed ARB files before every platform build
with pinned `intl_utils` 2.8.14 and `dart pub global run intl_utils:generate`
after dependency resolution. Generated files
remain local build inputs. Preserve the approved 4.8.2, 4.8.1 and 4.8.0 sections
in all six locales of the cumulative 4.8.3 notes. Packaging, signing and channel
verification remain required. New device/model acceptance is explicitly waived
for this release; do not describe the waiver as a passed acceptance result.

## Release 4.8.2


RWKV Chat 4.8.2 delivery uses the same reviewed App source, dependency
lock and development toolchain, with platform builds on their respective hosts.
Use `.flutter-version`, `node tools/check_flutter_toolchain.mjs` and
`node tools/flutter.mjs` for that toolchain. Windows can be operated from the
coordinating client; a separate planning Agent is not a build requirement.

Fastlane is retired and its implementation has been removed. Use Flutter's
native build commands, the platform packager
and the existing provider upload scripts. Before any new release effect, freeze
the new version/build and toolchain in `release.json`, pin the reviewed adapter
and native artifacts, and verify the exact source snapshot on both hosts.
Keep host credentials, signing state and build caches local. Publish only after
the selected platform packages and distribution channels have been verified;
development synchronization and successful Debug launches alone are not release
acceptance. Preserve previously published release identities.

Version 4.8.2 uses build 758 and Flutter 3.47.5. Android, iOS, macOS, Windows
and Linux use the same reviewed App commit and pinned adapter/native libraries.
Android retains the 16 KB-aligned MTK libraries shipped in the preceding Play
release, with their own immutable archive pinned in the adapter manifest.
Other platform native files retain their existing digests.
Core AI experiments are excluded. Public release notes are “性能优化” and their
translations. Earlier release identities below retain historical provenance.

## SPEC-RWKV-APP-BINARY-DISTRIBUTION

RWKV App release automation publishes each supported direct-download package to
the existing Hugging Face dataset and to a dedicated public ModelScope dataset.
Both providers must use the same platform directory, artifact filename, version,
build number, and artifact bytes. GitHub Release and store-specific channels
remain independent distribution surfaces.

The default ModelScope dataset is `HaloWang1991/rwkv-chat` on the `master`
branch. Deployments may override the endpoint, repository ID, or revision by
environment variable without changing the artifact mapping contract.

GitHub Actions provides Linux and Windows package workflows. Android and Apple
builds use native Flutter/platform tools; publication uses the existing provider
scripts and official platform tools. Fastlane is not a build or upload dependency.
Authentication tokens are supplied only through private runtime configuration
and must never be written to tracked files or command output.

The bundled `.env` contains only the runtime `x-api-key`. Keep signing,
provider-upload and server credentials outside App resources. The shared
`node tools/flutter.mjs` entrypoint rejects other `.env` entries without
printing their values. Inspect the packaged environment asset before any
distribution; a source configuration check alone is insufficient.

App publication authorizes the declared installer packages and channels. It does
not authorize publishing build receipts, provenance JSON, logs, local paths or
other internal evidence. Keep those records locally under Git-ignored paths;
publishing additional material requires an explicit, separately scoped user
request. GitHub package upload entrypoints accept only the supported RWKV Chat
APK, macOS DMG, Linux x64 tar.gz/AppImage and Windows x64/ARM64 ZIP/installer
filenames, and reject metadata before any release mutation. Wildcard batches
must pass that check in full before uploading their first file.

Before an authorized release tag is created and pushed, its source commit must include
every changed or untracked source file needed by a clean checkout. Generated
release artwork remains local and is excluded from that commit. A clean checkout
of the tag must therefore contain every imported source file before GitHub
Actions starts Linux or Windows packaging.

The public download website is owned by `app_website`. It may advertise a
ModelScope source only after the corresponding dataset file is visible through
the provider's anonymous file-tree and resolve surfaces. Creating the remote
dataset, granting write authority, uploading files, and deploying the website
remain explicit release actions rather than consequences of a local code change.

## SPEC-RWKV-FROZEN-RELEASE — Shared Release Identity And Apple Continuation

`release.json` freezes the semantic version, build number, Flutter version, adapter commit,
native-library release and commit, and enabled distribution channels. Each
application build must match `pubspec.yaml` and use that adapter revision.
Native libraries come from the RWKV-APP fork at an immutable release with
verified archive checksums; a mutable `latest` release or adapter branch is not
a release dependency. The application tag identifies the exact App commit.

The G1J weight target is the 45-artifact, four-size partial cohort governed by
`docs/contracts/model_quantization_catalog.md`. `release.json.weights` records
each selected identity, quantization, consumer mapping and currently populated
distribution source separately from pending publication. Its counts must not
be interpreted as model-runtime or complete-release acceptance. The App
version, build, Flutter version, adapter and native pins remain unchanged when
preparing this catalog. An already-built package retains its original bundled
catalog and digest; a local catalog edit does not retroactively update it.

CI uploads package assets into an already-created GitHub Release and preserves
its draft or published state. A repeated upload must match the existing size
and SHA-256; a different file with the same name is rejected. Publication is a
separate step after the enabled package matrix and acceptance checks complete.

RWKV Chat 4.8.0 uses build 755. Its first delivery includes Windows x64 and
ARM64 installers and ZIPs, Linux x64 tar.gz and AppImage, and the Android arm64
APK. GitHub, ModelScope and Hugging Face are enabled. Provider uploads use
complete, size- and SHA-256-verified files on the operator's local publication
host. All GitHub and Hugging Face transfers for this delivery use that host.
The accepted non-Apple packages retain their build-source identity and bundled
catalog; the build-755 online model configuration is published separately.
macOS and iOS package delivery and platform validation are explicitly
deferred to a separate Apple continuation and do not block this delivery.
Apple application build targets are exactly `macos` and `ios`. iPhone and iPad
use the same iOS build; iPadOS is never a separate lane or package target.

Current Apple builds use the frozen source and toolchain through native Flutter,
Xcode, CocoaPods, signing and notarization tools. Verify source, dependency and
native-library identities before packaging; preserve unrelated changes and
previously published tags and bytes. The 4.8.0 identity above is historical,
not a current branch or toolchain selection.

For an authorized release, build with the committed dependency lock and the
pinned adapter/native inputs. Sign and notarize the macOS DMG with native Apple
tools, then use the existing GitHub, ModelScope and Hugging Face upload scripts.
Upload iOS through Apple's native provider tools and verify processing,
TestFlight distribution and App Store review independently. Existing package
or build-number presence alone does not establish provenance or completion.
Keep identity receipts and full artifact digests in ignored local output or
the private release handoff. Never publish those receipts as package assets.

## SPEC-RWKV-APPLE-RELEASE-AUTH-GATE

Apple authentication remains a release prerequisite. Before version changes,
builds or uploads for a TestFlight release, perform fresh, artifact-free
provider authentication in a visible foreground terminal. The default native
Apple ID mode uses an application-specific password from private runtime
configuration or Keychain. Pass a password by environment/Keychain reference,
never as a literal process argument, tracked file or log value.

After loading the existing private release environment, run
`tools/apple_auth.command` in that terminal. It accepts no arguments and invokes
`xcrun altool --list-providers` with `APPLE_ID_EMAIL` and an environment reference
to `MACOS_APP_PASSWORD`. It does not read an IPA, prepare source, install
dependencies, build, sign, upload or change Git state. Missing configuration,
a redirected launch or native authentication failure stops this check.
A successful standalone check does not prove signing or publication and does
not waive a fresh authentication check before a later release.

The release must retain its explicitly selected authentication mode and private
credential references. No cached web session substitutes for the native
preflight. If Apple's interactive flow requests a verification code or SMS
choice, the operator enters or selects it; automation must not do so or retry
that login automatically. Authentication failure stops before release effects.

App Store Connect API-key authentication remains an optional, explicitly
selected non-interactive mode. Validate the complete key ID, issuer and private
key configuration before effects; keep key material outside Git and logs.
Presence of API-key environment variables alone does not select that mode.
