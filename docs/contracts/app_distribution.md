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
