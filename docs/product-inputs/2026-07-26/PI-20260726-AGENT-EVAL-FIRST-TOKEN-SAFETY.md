---
id: PI-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
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
  - lib/model/agent.dart
  - lib/store/agent.dart
  - test/agent_transport_test.dart
conflicts: []
supersedes: []
superseded_by: []
decisions:
  - DEC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
acceptance_records:
  - ACC-20260726-AGENT-EVAL-FIRST-TOKEN-SAFETY
---

# Make Agentic Evaluation fail fast when local generation produces no token

## Raw statement

> 那就按照你说的做呗

The approved proposal was to replace the Agent evaluator's unsupported deterministic sampler values, validate them before native generation, isolate response-buffer polling to the active model and request, ignore stale buffer content, and stop with an infrastructure failure when no first token arrives within a short bounded interval

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- App Agentic Evaluation must use a deterministic sampler configuration supported by the local inference engine
- The host must reject an invalid Agent sampler configuration before starting native generation
- Response-buffer content must belong to the active chat model and an Agent-owned polling request, and stale content from a previous generation must not count as fresh output
- A generation that produces no fresh model output within 20 seconds must be stopped and recorded as an infrastructure failure rather than remaining silently running
