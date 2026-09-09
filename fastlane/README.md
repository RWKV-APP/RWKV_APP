fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### apple

```sh
bundle exec fastlane apple
```

Continue 4.8.0 / build 755 on an Apple Silicon Mac from the clean, synchronized
`codex/apple-release-4.8.0` branch of `RWKV-APP/RWKV_APP`. Use Flutter 3.47.2 and
the fixed adapter/native identities in `release.json`; do not check out the old
4.8.0 tag for this continuation.

The lane checks source and environment before fresh Apple authentication,
prepares the pinned Apple native libraries, uses `flutter pub get
--enforce-lockfile`, and verifies each platform's inputs before and after the
build. The macOS DMG is published to GitHub, ModelScope and Hugging Face; the iOS
IPA goes to TestFlight. Reuse requires an exact source/native/artifact provenance
receipt, including for an existing TestFlight version/build. Receipts stay in
ignored `tools/output/release-provenance/`; the lane never uploads them to
GitHub. Only supported App package filenames may enter GitHub upload actions.
When moving a release to another Mac, transfer its original receipts privately.

See [Apple continuation](../tools/README.md#apple-continuation) for safe clone or
fetch/switch/pull commands, Mac dependencies, signing and provider credentials,
read-only preflight commands, and resume boundaries. These instructions and
helper tests do not constitute an Apple build, signing or device acceptance.


### all

```sh
[bundle exec] fastlane all
```



### ios_upload

```sh
[bundle exec] fastlane ios_upload
```

Preauthenticate with Apple ID before building, then build and upload an IPA; API-key mode is optional

### ios_upload_to_testflight

```sh
[bundle exec] fastlane ios_upload_to_testflight
```

Preauthenticate with Apple ID, then upload an existing IPA; API-key mode is optional

### ios_auth_preflight

```sh
[bundle exec] fastlane ios_auth_preflight
```

Authenticate to App Store Connect without building or uploading an artifact

For a standalone foreground Apple ID check, run `tools/apple_auth.command` from
the repository root or double-click it in Finder. The temporary login session
is removed on exit; a later release authenticates again.

### global_replace

```sh
[bundle exec] fastlane global_replace
```



### switch_env

```sh
[bundle exec] fastlane switch_env
```



### test

```sh
[bundle exec] fastlane test
```



### lint

```sh
[bundle exec] fastlane lint
```



### bump_version_and_build_number

```sh
[bundle exec] fastlane bump_version_and_build_number
```



### dart_fix

```sh
[bundle exec] fastlane dart_fix
```



### sort_imports

```sh
[bundle exec] fastlane sort_imports
```



### git_reset

```sh
[bundle exec] fastlane git_reset
```



### build_assets

```sh
[bundle exec] fastlane build_assets
```



### android_play_store

```sh
[bundle exec] fastlane android_play_store
```



### macos_build_and_upload

```sh
[bundle exec] fastlane macos_build_and_upload
```



### test_huggingface

```sh
[bundle exec] fastlane test_huggingface
```



### resume_upload

```sh
[bundle exec] fastlane resume_upload
```

Resume remaining release stages after no-artifact Apple preauthentication

### test_macos_dmg

```sh
[bundle exec] fastlane test_macos_dmg
```



----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
