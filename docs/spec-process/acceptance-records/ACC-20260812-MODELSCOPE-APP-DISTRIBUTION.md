---
id: ACC-20260812-MODELSCOPE-APP-DISTRIBUTION
type: acceptance
date: 2026-08-12
owner: root Codex agent
inputs:
  - PI-20260812-MODELSCOPE-APP-DISTRIBUTION
decisions:
  - DEC-20260812-MODELSCOPE-APP-DISTRIBUTION
canonical_assertions:
  - SPEC-RWKV-APP-BINARY-DISTRIBUTION
changed_surfaces:
  - .env.example
  - .gitignore
  - .github/workflows
  - docs/contracts/app_distribution.md
  - docs/specification.md
  - docs/specs/00-inventory.md
  - docs/specs/01-authority-map.md
  - docs/spec-process/decisions/DEC-20260812-MODELSCOPE-APP-DISTRIBUTION.md
  - fastlane/Fastfile
  - fastlane/README.md
  - fastlane/actions/modelscope.rb
  - scripts/sync_secrets_to_github.sh
  - scripts/test_upload_to_modelscope.py
  - scripts/upload_to_modelscope.py
  - app_website:.
unresolved_conflicts: []
result: partial
supersedes_acceptance: []
superseded_by: []
---

# ModelScope App distribution integration

## Mechanical evidence

- `python scripts/test_upload_to_modelscope.py` passed 2 tests.
- The upload script dry-run produced the expected ModelScope dataset resolve
  URL without importing credentials or making an upload.
- A parity check confirmed identical local artifact arguments and repository
  paths for Hugging Face and ModelScope in all 8 Linux and Windows workflows.
- `actionlint` v1.7.12 passed all 8 changed workflows after its published
  SHA-256 was verified.
- `dart run tools/bin/check_specification.dart` passed Specification v1.7.
- The existing website distribution Jest suite passed 5 tests, including the
  ModelScope dataset-tree and encoded resolve-URL case.
- `pnpm check` passed website contract, backend, and frontend type checks and
  lint with 0 errors; 71 existing or non-blocking backend warnings and one
  existing Next.js image warning remain.
- Root Harness `doctor` and `spec check` passed; unrelated optional project
  checkout warnings remain.

## Requirement review

The GitHub Actions workflows publish every existing Linux and Windows package
to the configured ModelScope dataset using the same file and path used for
Hugging Face. Fastlane mirrors Android APK and macOS DMG paths and supports the
Android resume-upload path. Tokens remain environment-only.

The website contract, backend refresh service, and frontend source picker now
cover ModelScope for macOS, both Linux formats, x64 and ARM64 Windows installer
and zip packages, and Android APK. Mainland-China selection prefers the newest
available ModelScope, AI FastLab, or HF Mirror record, in that order when
versions are equal.

## Semantic or visual review

The root review inspected the provider-to-platform mapping in both repositories
and verified ModelScope's public dataset tree response shape plus the anonymous
`/datasets/<owner>/<repo>/resolve/<revision>/<path>` download route against an
existing public dataset. The configured RWKV App dataset currently has no
public tree, so the website correctly leaves ModelScope records unavailable
until the release repository and artifacts exist.

## Exclusions

- `HaloWang1991/rwkv-chat` has not been created as a ModelScope dataset.
- No token authority, actual binary upload, byte-for-byte cross-provider check,
  GitHub Actions run, Fastlane lane, commit, push, or website deployment was
  performed.
- Ruby is unavailable on this Windows node, so Fastlane syntax and execution
  require validation on the macOS release node before publication.
