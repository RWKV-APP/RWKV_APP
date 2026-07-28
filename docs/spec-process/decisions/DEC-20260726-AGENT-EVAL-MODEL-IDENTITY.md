---
id: DEC-20260726-AGENT-EVAL-MODEL-IDENTITY
type: decision
date: 2026-07-26
status: approved
approved_by: user
inputs:
  - PI-20260726-AGENT-EVAL-NO-MODEL-SHA-VALIDATION
observations: []
conflicts: []
supersedes: []
superseded_by: []
acceptance_records:
  - ACC-20260726-AGENT-EVAL-MODEL-IDENTITY-AND-INVALID-RUNS
canonical_assertions:
  - SPEC-RWKV-AGENTIC-EVAL
affected_surfaces:
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - docs/agentic-evaluation/README.md
  - lib/store/agent.dart
  - tools/agent_eval_reference.dart
---

# Remove model SHA validation from Agentic Evaluation

## Decision

Agentic Evaluation must never calculate or validate a selected model file's SHA. A catalog or operator supplied hash may be copied without reading the model file only when the report marks it as unverified. Model SHA is not required to start a run and is not a scoring, comparison, or delivery gate

## Reason

The user explicitly rejected SHA validation after a Windows evaluation spent about fifty seconds hashing an 8.45 GB model before showing running state. Model name, file name, file size, precision or quantization, backend, and source revision provide the required operational identity without blocking evaluation startup on full-file hashing
