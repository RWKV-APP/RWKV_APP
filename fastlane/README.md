# RWKV App Fastlane Release Notes

The `all` and `resume_upload` lanes can change versions, commit, push, upload
artifacts, and reset the worktree. Run them only after reviewing the exact lane,
Git state, credentials, and intended release destinations.

## TestFlight authentication

Automated TestFlight lanes use an App Store Connect API key by default. Set
`APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and
`APP_STORE_CONNECT_KEY_FILEPATH` in the runtime environment, with the `.p8`
file stored outside this repository using mode `0600`.

Run `fastlane ios_auth_preflight` to validate the local configuration without
contacting Apple or sending a verification code. Missing API-key configuration
stops `all`, `resume_upload`, `ios_upload`, and `ios_upload_to_testflight`
before Apple ID authentication begins.

Apple ID authentication is available only as an explicit one-attempt foreground
operation. It requires `allow_interactive_apple_auth:true`, the exact
acknowledgement named by the preflight error, and an interactive terminal. Do
not use this mode in a background or redirected release process.

For Resume work, pass a private `testflight_checkpoint_path`. A successful
TestFlight upload and tester distribution writes a mode-`0600` checkpoint for
the exact `version+build`; a matching checkpoint skips TestFlight on a later
Resume without starting another Apple authentication session.

## ModelScope App distribution

Android APK and macOS DMG publication mirrors the Hugging Face dataset layout:

- Android: `android-arm64/<artifact-name>.apk`
- macOS: `macos-universal/<artifact-name>.dmg`

Configure these values in the runtime environment or secret manager:

```text
MODELSCOPE_API_TOKEN=<write-capable token>
MODELSCOPE_REPO_ID=HaloWang1991/rwkv-chat
MODELSCOPE_ENDPOINT=https://modelscope.cn
MODELSCOPE_REVISION=master
```

The target is a public ModelScope `dataset` repository. It must exist before a
release lane runs. Repository creation is a separate, explicit release action:

```bash
ms-hub create HaloWang1991/rwkv-chat \
  --repo-type dataset \
  --visibility public \
  --description "RWKV Chat application release packages"
```

The custom `modelscope` action delegates to
`scripts/upload_to_modelscope.py`, keeps the token in the process environment,
and does not place it on the command line. When the token is absent, the normal
Android and macOS lanes skip ModelScope while preserving the existing release
channels.

After the first upload, verify the dataset file tree and an anonymous resolve
URL before enabling or deploying the ModelScope source in `app_website`.
