# RWKV App Tools

This directory contains repository helper scripts for development, checks, assets, and release support

## Agent Check

Run the standard coding-agent check from the repository root:

```bash
dart run tools/bin/agent_check.dart
```

The command runs these steps in order:

1. The blocking Specification graph check
2. `dart analyze`
3. `flutter test`
4. A lightweight repository rule scan

For a faster structural scan:

```bash
dart run tools/bin/agent_check.dart --rules-only
```

For only the blocking Specification graph:

```bash
dart run tools/bin/agent_check.dart --spec-only
```

For CI-style enforcement of rule warnings:

```bash
dart run tools/bin/agent_check.dart --strict-rules
```

The rule scan currently reports warnings for patterns such as `Divider`, `ListTile`, `.then()`, `withOpacity`, old `MediaQuery.of(context)` access, relative imports, `show` imports, ARB key drift, and missing synchronized README / CONTRIBUTING files

Rule warnings are non-blocking by default so historical code can be cleaned incrementally

## Specification Check

Run the strict Specification graph check from the repository root:

```bash
dart run tools/bin/check_specification.dart
```

Change to the repository root before invoking the Dart script. The CLI has repository-root discovery and `--root` support for package and CI integration, but launching `dart run` directly from an arbitrary documentation directory can create a local `.dart_tool/` cache there

The checker validates `SPEC-SYNC-ROOT-INTAKE-BOUNDARY`, current process
surfaces, and the historical target-side record archive: strict front matter,
stable IDs and dates, state combinations, authority ownership, local and
sibling-repository references, conflicts, supersession, acceptance chronology,
required backlinks, process versions, and synchronized Agent instructions

Specification failures are blocking even though historical lightweight rule warnings remain non-blocking by default

## Native release support

Read `docs/contracts/app_distribution.md` and the frozen `release.json` before
packaging or publication. Fastlane has been removed. Use the shared
`node tools/flutter.mjs` entrypoint for the pinned Flutter/Dart SDK, native
platform signing/packaging tools and the existing provider upload scripts.
An explicit release request is required for upload, publication or Git writes.

CocoaPods remains pinned independently in `Gemfile` and `Gemfile.lock`. Use a
managed Ruby with the lockfile's Bundler version and full Xcode. From the
repository root, resolve the locked Ruby dependencies and check CocoaPods:

```sh
bundle _2.6.2_ install
bundle _2.6.2_ exec pod --version
node tools/check_flutter_toolchain.mjs
```

Keep signing identities, provisioning profiles, application-specific passwords
and provider tokens in Keychain or private host configuration, outside App
resources. The bundled `.env` may contain only `x-api-key`; the shared Flutter
entrypoint validates this boundary. Inspect the actual packaged environment
asset before distribution. Preserve unrelated local changes and generated files.

### Apple authentication check

After loading the existing private release environment, run
`tools/apple_auth.command` in a visible foreground terminal. It accepts no
arguments and invokes Apple's `xcrun altool --list-providers` using
`APPLE_ID_EMAIL` and an environment reference to `MACOS_APP_PASSWORD`.
The password never appears in command arguments. The check requires no Ruby
bundle, application artifact or signing certificate and does not build, sign,
upload or modify Git. A redirected launch, missing configuration or failed
native authentication stops it. It checks Apple ID mode independently of any
API-key variables. A later release needs its own fresh authentication check.

Apple publication uses native build/signing tools and the explicitly selected
provider authentication mode. For macOS use `codesign`, `hdiutil`,
`xcrun notarytool` and `xcrun stapler`; for iOS use the native archive/export
and provider upload tools. Verify store processing/review and direct-download
availability separately. Existing Apple certificates, profiles and private
credentials are retained.

### Release identity and uploads

`scripts/release_identity.py` validates `release.json` against `pubspec.yaml`,
pinned dependency repositories and native identities. Its GitHub upload option
rejects unsupported filenames and refuses replacement by different bytes.
`scripts/upload_to_hf.py` and `scripts/upload_to_modelscope.py` retain provider
publication support. Keep receipts and raw diagnostics private; only declared
App packages may be uploaded to public release channels.

Focused offline checks:

```sh
python3 -m unittest discover -s scripts -p 'test_apple_auth_launcher.py'
python3 -m unittest discover -s scripts -p 'test_release_identity.py'
node tools/check_runtime_env.mjs
```

## Script index

| Script | Purpose | Notes |
| --- | --- | --- |
| `deploy_latest_json.py` | Deploy `remote/latest.json` | Network operation |
| `deploy_suggestions_json.py` | Deploy `remote/suggestions.json` | Network operation |
| `download_remote_json.py` | Download remote JSON metadata | Network operation |
| `inspect_remote.py` | Inspect remote model metadata | Read-only |
| `read_restart_script.py` | Read remote restart script details | Read-only |
| `update_model_filesize.py` | Update model filesize metadata | Mutates JSON files |
| `fix_json_newlines.py` | Normalize JSON newline content | Mutates JSON files |
| `test_openai_api.py` | Probe OpenAI-compatible API behavior | Network or local server operation |
| `remove_non_dev_branches.sh` | Remove local branches except dev | Destructive local Git operation |
| `bin/tools.dart` | Generate version branding images | Writes generated images |

Generated outputs should stay under ignored paths such as `tools/output`
