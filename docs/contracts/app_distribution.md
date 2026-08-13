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

The public download website is owned by `app_website`. It may advertise a
ModelScope source only after the corresponding dataset file is visible through
the provider's anonymous file-tree and resolve surfaces. Creating the remote
dataset, granting write authority, uploading files, and deploying the website
remain explicit release actions rather than consequences of a local code change.

## SPEC-RWKV-APPLE-RELEASE-AUTH-GATE

TestFlight automation defaults to App Store Connect API-key authentication.
The key ID, issuer ID, and private-key path or content are runtime secrets; the
private key stays outside Git and logs. External tester distribution requires
an API key whose App Store Connect role permits build metadata and tester
management.

When API-key configuration is absent or incomplete, `all`, `resume_upload`,
`ios_upload`, and `ios_upload_to_testflight` must stop before starting an Apple
login. They must not silently reuse an Apple ID session, request a trusted
device code, send an SMS, or wait on an invisible prompt. The authentication
preflight runs before build, upload, or other release effects that would make
the operator wait for this decision.

An Apple ID login is an exceptional foreground path. It requires both the
explicit `allow_interactive_apple_auth:true` option and the exact one-attempt
acknowledgement printed by the preflight, plus an interactive terminal. One
failed or expired attempt ends the lane; release automation never requests an
SMS code or starts another Apple login automatically. Root reports the blocked
state and waits for a fresh user instruction.

Resume automation may provide a private version-bound TestFlight checkpoint.
The checkpoint is written only after Fastlane finishes build processing and
tester distribution, uses mode `0600`, and must match the exact version and
build before a later run skips TestFlight. A missing, invalid, or mismatched
checkpoint never suppresses the upload.
