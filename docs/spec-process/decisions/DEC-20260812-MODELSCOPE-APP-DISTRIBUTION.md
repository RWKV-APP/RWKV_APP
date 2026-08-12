---
id: DEC-20260812-MODELSCOPE-APP-DISTRIBUTION
type: decision
date: 2026-08-12
status: approved
approved_by: user
inputs:
  - PI-20260812-MODELSCOPE-APP-DISTRIBUTION
observations: []
conflicts: []
supersedes: []
superseded_by: []
acceptance_records:
  - ACC-20260812-MODELSCOPE-APP-DISTRIBUTION
canonical_assertions:
  - SPEC-RWKV-APP-BINARY-DISTRIBUTION
affected_surfaces:
  - docs/contracts/app_distribution.md
  - .github/workflows
  - scripts/upload_to_modelscope.py
  - fastlane/Fastfile
  - fastlane/README.md
  - fastlane/actions/modelscope.rb
  - app_website:.
---

# Add ModelScope as an RWKV App binary distribution channel

## Decision

Publish the same direct-download RWKV App packages currently sent to Hugging
Face to a dedicated public ModelScope dataset, and expose ModelScope as a new
download source on the public App website. Keep GitHub Release, Hugging Face,
its mirrors, and store channels available.

The ModelScope copy must preserve the existing platform directory, artifact
filename, version, build number, and bytes. GitHub Actions covers the existing
Linux and Windows package workflows; Fastlane covers Android APK and macOS DMG.
Remote repository creation, credential configuration, first upload, and website
deployment require separate release execution and verification.

## Reason

The user explicitly requested a first-party domestic download source instead of
depending only on GitHub and Hugging Face-compatible routes, and explicitly
selected ModelScope plus the App GitHub workflows and Fastlane as the required
publication surfaces.
