# Audited `geo-ai` Specification v1.6 Core Manifest

Captured: 2026-07-23
Source base revision: `9c3b088c1beb9ca1b4aae76b7055c18fb6b1126a`
Manifest SHA-256: `13edab8abde22126129bba29540712367525a7dde188d8ea9d11ed119ce5616e`

The visible source v1.6 was an uncommitted working-tree state. This manifest preserves the exact core mechanism files audited for the `rwkv_app` migration without copying GEO business records.

The manifest digest is SHA-256 over the following UTF-8 lines in lexical path order. Each second column is the Git blob ID of the working-tree file content.

| Repository-relative path | Git blob ID |
| --- | --- |
| `.agents/skills/spec-sync/SKILL.md` | `4043d01269c7a1086bd71eb52867d661b300f27e` |
| `.agents/skills/spec-sync/agents/openai.yaml` | `8df73e2ec7be57b7754d2a27bf18869ebebd7abf` |
| `AGENTS.md` | `8dabbe96309d85b8ba274279cdf2b5a8479f8fd3` |
| `SPEC-LOOP.md` | `7bf29605903580ec064d89bcd13d6399da76e4d0` |
| `docs/plans/PLANS.md` | `4eb3f9d14246cd9bc9b9acb4f2540f93c518b280` |
| `docs/spec-process/acceptance-records/2026-07-22-spec-v16-state-hardening.md` | `4b609c3d66a078785265419140d05919d947d335` |
| `docs/spec-process/acceptance-records/README.md` | `a4b55fa9ff8d94648afd3ad4a209bd9efd58817e` |
| `docs/spec-process/changelog.md` | `b687d0a066351126476d4b5dffa1ba63beb25944` |
| `docs/spec-process/conflicts.md` | `44ad60f40fe2bdcccf6c68a4dd3138cc9345d7a0` |
| `docs/spec-process/decisions.md` | `cbfa35b1cf74b271a5833551e4b2bb88b18ab648` |
| `docs/spec-process/eval-cases.md` | `5ef6df9e1f6458ea82a0f6bc134dd30ecce72f1c` |
| `docs/spec-process/observations.md` | `2b74f4a3c36e93eef7cccdb87f8468340ae66217` |
| `docs/spec-process/rules.md` | `b84d7c9914195e93546481e7e488e478a2af7a09` |
| `docs/specification.md` | `320bfc409a452e44788c2a694356dbfa29f19429` |
| `docs/specs/00-inventory.md` | `49a6661f575717d06ca0851a0a1dd28097109ed7` |
| `docs/specs/01-authority-map.md` | `779055e4bda3f11d6dd9b6793bdd4858b53ea277` |
| `package.json` | `1a340a8751c160687adfe637c031813a252a0cc2` |
| `scripts/check-spec-loop.mjs` | `a171e374e9fff7a1c68d55807e70e06b44efe945` |
| `scripts/check-spec-loop.test.mjs` | `db46b5469a044af14ef7e6f12a5154fae5a2425d` |

## Recompute

From the source repository root, compute the working-tree Git blob ID for each listed path, emit `path`, a tab, the blob ID, and a newline, sort by path, and calculate SHA-256 over the resulting bytes. A differing digest means the source mechanism snapshot has changed.
