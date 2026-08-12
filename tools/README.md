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

## Other Scripts

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
