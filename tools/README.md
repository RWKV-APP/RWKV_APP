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

Run this continuation on an Apple Silicon Mac from the App's
`codex/apple-release-4.8.0` branch. It preserves version **4.8.0**, build **755**,
and the existing public `4.8.0` tag. That older tag identifies the accepted
non-Apple packages; it does not contain the Apple continuation fixes.

| Input | Required identity |
| --- | --- |
| App origin | `https://github.com/RWKV-APP/RWKV_APP.git` |
| App branch | `codex/apple-release-4.8.0`, clean and synchronized with origin |
| Flutter / Dart | `3.47.2` / `3.13.2` |
| Adapter sibling | `rwkv_mobile_flutter`, origin `RWKV-APP/rwkv_mobile_flutter` |
| Adapter commit | `c87936afbcc40fa99d6d9bdaa18884d96193a825` |
| Native release | `4.8.0-native.4`, commit `205d4848f2b769efe4a1df268e1cdf6548158b5d` |
| Native platforms | `macos` and `ios`; the macOS native library requires Apple Silicon |
| DMG destinations | Existing GitHub 4.8.0 Release, ModelScope `HaloWang1991/rwkv-chat`, Hugging Face `HaloWang/rwkv-chat` |
| iOS destination | TestFlight for the canonical App, version 4.8.0 / build 755 |

**Get or update the source**

For a new workspace, run these commands from the chosen parent directory. The
App and adapter must remain exact-name siblings. `git clone` refuses an existing
nonempty destination; use the update steps below for an existing App checkout.

```sh
git clone --branch codex/apple-release-4.8.0 https://github.com/RWKV-APP/RWKV_APP.git rwkv_app
git clone https://github.com/RWKV-APP/rwkv_mobile_flutter.git rwkv_mobile_flutter
cd rwkv_app
```

For an existing checkout, run this block from its `rwkv_app` directory. It stops
on local changes or a wrong origin before switching branches. Preserve and resolve
those changes explicitly; do not use a reset, forced checkout, or automatic stash.

```sh
set -e
case "$(git remote get-url origin)" in
  https://github.com/RWKV-APP/RWKV_APP.git|git@github.com:RWKV-APP/RWKV_APP.git) ;;
  *) echo "Expected origin RWKV-APP/RWKV_APP" >&2; exit 1 ;;
esac
if [ -n "$(git status --porcelain)" ]; then
  git status --short
  echo "Preserve local changes before switching release branches" >&2
  exit 1
fi
git remote set-branches --add origin codex/apple-release-4.8.0
git fetch origin --tags
if git show-ref --verify --quiet refs/heads/codex/apple-release-4.8.0; then
  git switch codex/apple-release-4.8.0
else
  git switch --track -c codex/apple-release-4.8.0 origin/codex/apple-release-4.8.0
fi
git pull --ff-only origin codex/apple-release-4.8.0
```

The lane verifies the App source and repository identities, then prepares the
adapter at the exact commit above. It refuses to discard adapter changes. Only
the pinned `ios` and `macos` native libraries are fetched and verified against
`native-libraries.json`; no local native-engine compilation is needed.

**Prepare the Mac environment**

Install and select full Xcode with its macOS/iOS SDKs and command-line tools,
accept its license. CocoaPods 1.17.0 is installed by the same bundle as Fastlane,
matching both committed Pod lockfiles; a separate global installation is insufficient
for subprocesses of `bundle exec fastlane`.
The bundle also declares `abbrev` and `mutex_m`, required by Fastlane/HighLine
and CocoaPods on Ruby 3.4+.
Use a managed Ruby 3.2+ (including its development headers) with Bundler
2.6.2, Python 3.10+ with venv support, and GitHub CLI. Put the exact Flutter
3.47.2 SDK on `PATH`; the default Flutter installation may be another version.
`create-dmg` is optional: the packaging action can use macOS `hdiutil`.

From `rwkv_app`, prepare the Python and Ruby dependencies without adding them to
tracked source:

```sh
python3 -m venv ../.venv-rwkv-apple-4.8.0
source ../.venv-rwkv-apple-4.8.0/bin/activate
python3 -m pip install huggingface_hub modelscope-hub
gem install bundler -v 2.6.2
export BUNDLE_PATH="$HOME/.bundle/rwkv-apple-4.8.0"
export BUNDLE_FROZEN=true
bundle install
flutter --version
xcodebuild -version
bundle exec pod --version
gh auth status
```

Use an authenticated GitHub CLI account with write access to the App Release and
read access to the adapter/native repositories. If it is not signed in, run
`gh auth login` on that Mac. Restore the Mac's private release environment or
Fastlane Dotenv configuration; do not commit credential values or signing files.

| Credential or capability | Purpose |
| --- | --- |
| `HF_TOKEN` | Write to dataset `HaloWang/rwkv-chat`; `HF_DATASETS_ID` may explicitly name that dataset |
| `MODELSCOPE_API_TOKEN` | Write to dataset `HaloWang1991/rwkv-chat`; `MODELSCOPE_REPO_ID` may explicitly name that dataset |
| `APPLE_ID_EMAIL`, `MACOS_APP_PASSWORD`, `MACOS_TEAM_ID` | macOS notarization with an app-specific Apple password |
| Developer ID Application certificate and private key | Sign the macOS app; optionally select with `MACOS_SIGNING_IDENTITY` |
| `MACOS_CERTIFICATE_PATH`, `MACOS_CERTIFICATE_PWD` | Optional P12 import when the signing identity is not already available in the keychain |
| iOS distribution signing identity and provisioning profile | Archive/export the canonical App for TestFlight under the configured team |
| Apple ID with App Store Connect access and available two-factor authentication | Default fresh foreground TestFlight authentication; `FASTLANE_USER` can select the login account |

Explicit API-key mode uses `RWKV_APPLE_AUTH_MODE=api_key` together with
`APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID` and
`APP_STORE_CONNECT_KEY_FILEPATH`. Keep the `.p8` file private; this mode still
needs the macOS notarization credentials above and sufficient App Store Connect
permissions for the requested beta distribution. `SENTRY_AUTH_TOKEN` is optional
for symbol upload.

**Check Apple login separately**

Run `tools/apple_auth.command` in a visible terminal, or double-click it in
Finder. It loads the existing Fastlane Dotenv configuration and starts a fresh
Apple ID / App Store Connect login through `ios_auth_preflight`. Enter any
password or verification code directly in that terminal. The script always
selects Apple ID mode, accepts no release arguments, and exits after checking
authentication. It uses the installed bundle pinned by `Gemfile.lock` without
installing or updating dependencies.

This check does not require a clean Git tree, Flutter, signing certificates, or
provider-upload credentials. It does not build, sign, upload, or change Git
state. Its temporary session is removed on exit, so a later `fastlane apple`
run authenticates again. A successful login does not prove signing readiness
or that a TestFlight build was uploaded.

**Check and run**

These read-only checks can run separately before authentication. They check
source/environment prerequisites; they do not authenticate Apple or prove that
signing and provider credentials are usable.

```sh
python3 scripts/release_identity.py --check-apple-source &&
bundle exec python3 scripts/release_identity.py --check-apple-environment
```

Start the complete continuation in a visible foreground terminal:

```sh
bundle exec fastlane apple
```

The lane checks source, environment and required credentials, performs fresh
Apple authentication, prepares the exact adapter/native inputs, then runs
`flutter pub get --enforce-lockfile` and asset preparation. Each new platform
build cleans its generated outputs, resolves the same lockfile, verifies the
actual build inputs, builds with `--no-pub`, and checks the resolved plugin/Pods
inputs again before subsequent distribution steps. It writes its local preparation identity
to ignored `tools/output/apple-release-identity.json`.

All three DMG channels are enabled by `release.json`. Rerunning the command can
reuse a published DMG only when its bytes and local `.provenance.json` receipt match
the exact App commit, release manifest digest, adapter commit, native release and
native file digests. The iOS receipt `rwkv_chat_4.8.0_755_ios.provenance.json`
binds the uploaded IPA to those same inputs. An existing TestFlight version/build
alone is insufficient: missing or mismatched provenance stops reuse. Receipts
stay under ignored `tools/output/release-provenance/`, survive `flutter clean`,
and are never uploaded as GitHub Release assets. The macOS receipt is saved
before package upload; the iOS receipt is saved after TestFlight upload.
Transfer original receipts privately when continuing on another host. Restore
missing receipts from that private handoff; do not publish evidence to satisfy
a resume check. GitHub upload entrypoints reject JSON, logs and other files
outside the supported App package filenames before any release mutation. Matching
builds may resume beta distribution; Apple processing or external beta review
can remain pending and must be checked in App Store Connect.

The continuation does not increment version/build, move the original 4.8.0 tag,
or replace accepted non-Apple packages. Windows helper tests do not verify an
Apple build: signing, notarization, TestFlight and actual Mac/iPhone/iPad behavior
remain unverified until performed on the corresponding Apple environment.

Offline release helper checks:

```sh
python3 -m unittest discover -s scripts -p 'test_*.py'
bundle exec ruby tools/fastlane/frozen_release_test.rb
bundle exec ruby tools/fastlane/apple_auth_gate_test.rb
ruby tools/fastlane/apple_build_test.rb
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
