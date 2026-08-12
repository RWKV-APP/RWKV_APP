# RWKV App Fastlane Release Notes

The `all` and `resume_upload` lanes can change versions, commit, push, upload
artifacts, and reset the worktree. Run them only after reviewing the exact lane,
Git state, credentials, and intended release destinations.

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
