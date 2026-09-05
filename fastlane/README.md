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
[bundle exec] fastlane apple
```

Continue the published release on a Mac with the frozen version, build and native libraries. See [Apple continuation](../tools/README.md#apple-continuation) for prerequisites and resume behavior.

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
