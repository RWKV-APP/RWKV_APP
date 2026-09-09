# App Binary Distribution Contract

## SPEC-RWKV-APP-BINARY-DISTRIBUTION

RWKV App release automation publishes each supported direct-download package to
the existing Hugging Face dataset and to a dedicated public ModelScope dataset.
Both providers must use the same platform directory, artifact filename, version,
build number, and artifact bytes. GitHub Release and store-specific channels
remain independent distribution surfaces.

The default ModelScope dataset is `HaloWang1991/rwkv-chat` on the `master`
branch. Deployments may override the endpoint, repository ID, or revision by
environment variable without changing the artifact mapping contract.

GitHub Actions owns Linux and Windows package publication. Fastlane owns Android
APK and macOS DMG publication. Authentication tokens are supplied only through
runtime secrets and must never be written to tracked files or command output.

App publication authorizes the declared installer packages and channels. It does
not authorize publishing build receipts, provenance JSON, logs, local paths or
other internal evidence. Keep those records locally under Git-ignored paths;
publishing additional material requires an explicit, separately scoped user
request. GitHub package upload entrypoints accept only the supported RWKV Chat
APK, macOS DMG, Linux x64 tar.gz/AppImage and Windows x64/ARM64 ZIP/installer
filenames, and reject metadata before any release mutation. Wildcard batches
must pass that check in full before uploading their first file.

Before Fastlane creates and pushes a release tag, its release commit must include
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

The Apple-only Fastlane entrypoint continues the same release on an Apple Silicon
Mac using Flutter 3.47.2 and its bundled Dart 3.13.2. The current
`release.json.flutterVersion` is the build requirement for this continuation;
already published packages retain their original toolchain provenance.
`release.json.apple` declares the continuation source branch, integration
branch, and original published base tag/commit. The continuation may include
subsequent catalog and Apple fixes without moving the original tag or changing
the provenance of already published non-Apple packages. Before authentication,
the lane checks the App fetch/push repository, clean worktree, exact branch and
remote tip, integration ancestry, unchanged base tag, and fixed Flutter/tool
prerequisites. The pinned adapter and native commits must still be the remote
tips of their declared branches; newer commits require a reviewed pin update.
The immutable native release tag must resolve to its declared commit.

After authentication, it prepares the clean sibling adapter at the pinned
commit and verifies each iOS/macOS native file's full size and SHA-256 against
the pinned manifest. Unexpected files inside the native packaging scope block
the build. Flutter package metadata and CocoaPods plugin links must resolve to
that same sibling checkout. Every fresh platform build cleans prior outputs,
enforces the committed dependency lockfile, and checks source and native inputs
again before publication. Generated release artwork may differ; source code and
the dependency lockfile may not. A run-local identity receipt survives build
cleanup and records the App commit, manifest digest, dependency pins and native
file digests without personal paths or credentials.
On exit the lane restores only its own tracked generated artwork when the file
still matches the captured generated digest; subsequent user changes and
untracked files remain intact, and no whole-worktree reset is permitted.

The lane publishes a signed and notarized macOS DMG to the existing GitHub
release, ModelScope and Hugging Face, and uploads the matching iOS version/build
to TestFlight. Every enabled provider requires credentials before work starts.
It does not bump the version, run the all-platform lane, move an existing tag,
or replace accepted packages from other platforms. Resume checks completed
remote artifacts before skipping stages. Existing macOS and TestFlight builds
also require local provenance receipts matching the exact run identity and
artifact digest; a matching version/build alone is insufficient. Receipts live
under ignored `tools/output/release-provenance/`, outside Flutter build cleanup,
and never become GitHub assets. The macOS receipt is saved before package upload
so an interrupted upload can resume by comparing the remote package digest.
The iOS receipt is saved after a successful TestFlight upload. On another host,
transfer the exact receipts privately with the release handoff; missing or
conflicting evidence stops reuse with a local recovery instruction, without
requesting or uploading a public receipt. Apple build, signing and TestFlight
acceptance remain pending until actually performed on a capable Mac.

## SPEC-RWKV-APPLE-RELEASE-AUTH-GATE

TestFlight release automation defaults to a foreground Apple ID
preauthentication stage. Before changing a version, building an application,
or uploading any release artifact, the lane starts a fresh, process-local
Spaceship session and performs App Store Connect login. The stage does not
read an IPA, build an IPA, invoke an upload action, or send any artifact to App
Store Connect. If Apple requires two-factor verification, the trusted-device
code is therefore requested and entered before the long-running release work.
Apple remains the authority on whether a fresh login actually requires a code.

`tools/apple_auth.command` provides a standalone foreground Apple ID check via
the existing `ios_auth_preflight` lane. It authenticates only, even when the
environment selects API-key mode. It accepts no release arguments, requires
the installed locked Ruby bundle, and performs no dependency installation,
source synchronization, build, signing, or publication. It can run before local
source changes are committed. The process removes its temporary session on
exit; a later release performs fresh authentication in its own process.

The default stage must run in a visible foreground TTY. It isolates the release
from cached Spaceship cookies and `FASTLANE_SESSION`, disables automatic SMS
selection, and retains the newly verified cookie only for the current Fastlane
process. Later TestFlight work in that process reuses the verified session.
The temporary cookie directory is private, is never printed, and is removed
after the upload or when the process exits. Authentication failure stops the
lane before any version, build, commit, push, or upload effect.

App Store Connect API-key authentication remains an optional explicit mode for
non-interactive operation. It is selected with `apple_auth_mode:api_key` or
`RWKV_APPLE_AUTH_MODE=api_key`; only that mode requires the key ID, issuer ID,
and private-key path or content. The private key remains outside Git and logs.
Merely having API-key variables in the environment does not override the
default Apple ID preauthentication path.
