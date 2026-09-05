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

## Apple continuation

On the App checkout at the published release tag, run `fastlane apple` (or
`fl apple` when `fl` is the local Fastlane alias). For 4.8.0 this preserves
build 755 and appends the macOS DMG to the existing 4.8.0 GitHub Release and
ModelScope dataset, then uploads the same iOS version/build to TestFlight.
Hugging Face remains disabled by this release's `release.json`.

The Mac needs Xcode, Flutter 3.44.8, Fastlane, Python 3.10+, an authenticated
GitHub CLI, the exact sibling `rwkv_mobile_flutter` checkout, and existing Apple
signing credentials. The lane checks the App tag and a clean source tree, then
fetches and checks out the adapter commit in `release.json` if necessary. It
refuses to discard local adapter changes and verifies the pinned iOS/macOS
native libraries before building. The native macOS library targets Apple Silicon.

Set `MODELSCOPE_API_TOKEN`, `APPLE_ID_EMAIL`, `MACOS_APP_PASSWORD` and
`MACOS_TEAM_ID` in the Mac's existing private release environment. A Developer ID
Application certificate must be available in the keychain; `MACOS_SIGNING_IDENTITY`
can select it explicitly. Existing `MACOS_CERTIFICATE_PATH` and
`MACOS_CERTIFICATE_PWD` support importing a P12 for the run. Never commit these
values. The existing Apple ID preauthentication gate runs first in the foreground;
App Store Connect API-key authentication remains an explicit optional mode.

Rerunning the same command downloads and verifies an already published DMG and
continues its remaining uploads without rebuilding or replacing accepted bytes.
ModelScope checks the remote size and SHA-256 anonymously. An existing TestFlight
version/build resumes distribution without uploading another IPA. Apple processing
or external beta review may remain pending and must be checked on App Store Connect.
The command never increments the build number or resets the App worktree.

Offline release helper checks:

```sh
python3 -m unittest discover -s scripts -p 'test_*.py'
ruby tools/fastlane/frozen_release_test.rb
ruby tools/fastlane/apple_auth_gate_test.rb
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
