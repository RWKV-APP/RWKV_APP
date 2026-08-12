---
id: PI-20260726-AGENT-EVAL-NO-MODEL-SHA-VALIDATION
type: product_input
captured_date: 2026-07-26
source_date: 2026-07-26
source: user
category: product
status: merged
effective_status: active
delivery_status: verified
canonical_assertions:
  - SPEC-RWKV-AGENTIC-EVAL
delivery_surfaces:
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - docs/agentic-evaluation/README.md
  - lib/store/agent.dart
  - tools/agent_eval_reference.dart
conflicts: []
supersedes: []
superseded_by: []
decisions:
  - DEC-20260726-AGENT-EVAL-MODEL-IDENTITY
acceptance_records:
  - ACC-20260726-AGENT-EVAL-MODEL-IDENTITY-AND-INVALID-RUNS
---

# Do not validate model SHA in Agentic Evaluation

## Raw statement

> 永远不要验证SHA。

The statement was made in direct response to the observed Agentic Evaluation delay caused by hashing the selected model file

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- Agentic Evaluation must never read a model file to calculate or validate its SHA
- Starting an App or reference evaluation must not require a verified model hash
- An already supplied catalog or operator hash may only be copied as explicitly unverified metadata and must not become a scoring, comparison, or delivery gate
