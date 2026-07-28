---
id: DEC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
type: decision
date: 2026-07-26
status: approved
approved_by: user
inputs:
  - PI-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
observations: []
conflicts: []
supersedes: []
superseded_by: []
acceptance_records:
  - ACC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
canonical_assertions:
  - SPEC-RWKV-AGENTIC-EVAL
affected_surfaces:
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - docs/agentic-evaluation/README.md
  - lib/model/agent.dart
  - lib/store/agent.dart
  - test/agent_transport_test.dart
---

# Bound Agentic Evaluation first-token startup

## Decision

App Agentic Evaluation uses seed 42, temperature 0.2, top-k 500, top-p 0, zero presence and frequency penalties, and penalty decay 0.99. The App validates this sampler before native generation, ignores response-buffer content that is stale or not tied to an Agent-owned poll for the active chat model, and stops with an infrastructure failure when no fresh output arrives within 20 seconds

## Reason

On Windows, the 13.3B model completed the identical raw prompt with a 10,240-token limit in under one second and the supported fixed sampler also returned promptly, while the Agent evaluator remained running with an empty response buffer. The Agent-only sampler used temperature 0 and top-k 0 even though the App's supported deterministic preset uses temperature 0.2 and the normal hidden top-k is 500. A bounded first-token contract prevents this native no-output state from appearing as an indefinitely running evaluation
