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

CI uploads package assets into an already-created GitHub Release and preserves
its draft or published state. A repeated upload must match the existing size
and SHA-256; a different file with the same name is rejected. Publication is a
separate step after the enabled package matrix and acceptance checks complete.

RWKV Chat 4.8.0 uses build 755. Its first delivery includes Windows x64 and
ARM64 installers and ZIPs, Linux x64 tar.gz and AppImage, and the Android arm64
APK. GitHub and ModelScope are enabled; Hugging Face upload and verification
are explicitly deferred for this release. A missing deferred provider must
remain visible as deferred, never as verified parity. Later uploads reuse the
accepted bytes and their digests.

The Apple-only Fastlane entrypoint continues the same release on a Mac. It
checks the App tag, version/build, adapter commit and native library identity,
then publishes a signed and notarized macOS DMG to the existing GitHub release
and ModelScope dataset and uploads the matching iOS version/build to TestFlight.
It does not bump the version, run the all-platform lane, move an existing tag,
or replace accepted packages from other platforms. Resume checks completed
remote artifacts before skipping stages. Apple build, signing and TestFlight
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
