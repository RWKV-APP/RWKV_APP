---
id: PI-20260726-AGENT-CONVERSATION-SURFACE
type: product_input
captured_date: 2026-07-26
source_date: 2026-07-26
source: user
category: product
status: inbox
effective_status: pending
delivery_status: planned
canonical_assertions:
  - SPEC-RWKV-DESIGN-PRINCIPLES
  - SPEC-RWKV-PRODUCT-SCOPE
delivery_surfaces:
  - PRODUCT.md
  - docs/specification.md
  - lib/func/agent_runtime.dart
  - lib/page/chat.dart
  - lib/store/chat.dart
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records: []
---

# Make local Agent operation a conversation capability

## Raw statement

> 你觉得就是如何这样做呢?或者说它本身是否应该做一个conversation,其实就直接集中在我们的普通的聊天里面。

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- A production local Agent may belong in the ordinary chat conversation rather than only in a separate evaluation page
- Tool calls, approvals, results, and generated artifacts should remain visible in the conversation that requested them
- Agent mode and ordinary chat should share conversation history while keeping action permissions explicit
- The exact interaction and authorization contract still requires a product decision before implementation
