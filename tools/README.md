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

## Apple release tools

Use the App source, adapter and native commits, Flutter version and delivery
channels in `release.json`. The
[App distribution contract](../docs/contracts/app_distribution.md) defines
source checks, signing, receipt handling and resume requirements.

On an Apple Silicon Mac, use the selected Xcode and Flutter SDK and keep the
App and pinned adapter as sibling checkouts. Install the locked Ruby bundle
with Bundler 2.6.2 and check CocoaPods before building. Use the native tools
and provider upload scripts for release operations.

```sh
BUNDLE_FROZEN=true bundle install
bundle exec pod --version
```

Run `tools/apple_auth.command` in a visible foreground terminal before
TestFlight release work. It accepts no arguments and uses
`APPLE_ID_EMAIL` and `MACOS_APP_PASSWORD` from the private environment for
`xcrun altool --list-providers`. The launcher only checks authentication.
The explicitly selected App Store Connect API-key mode has its own credential
preflight under the distribution contract.

On a prepared release checkout, verify Apple source and tool prerequisites:

```sh
python3 scripts/release_identity.py --check-apple-source
bundle exec python3 scripts/release_identity.py --check-apple-environment
```

Use `scripts/package_macos_dmg.py` for the signed macOS App bundle and
`scripts/upload_to_hf.py` and `scripts/upload_to_modelscope.py` for enabled
mirrors. Keep release credentials and provenance receipts local.

Run the release helper tests offline with
`python3 -m unittest discover -s scripts -p 'test_*.py'`.

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
