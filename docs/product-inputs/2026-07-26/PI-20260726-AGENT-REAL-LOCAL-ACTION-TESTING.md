---
id: PI-20260726-AGENT-REAL-LOCAL-ACTION-TESTING
type: product_input
captured_date: 2026-07-26
source_date: 2026-07-26
source: user
category: product
status: inbox
effective_status: pending
delivery_status: planned
canonical_assertions:
  - SPEC-RWKV-AGENTIC-EVAL
  - SPEC-RWKV-VERIFICATION-BOUNDARY
delivery_surfaces:
  - docs/agentic-evaluation/eval-spec-v0.1.md
  - lib/func/agent_runtime.dart
  - lib/page/chat.dart
  - lib/store/chat.dart
conflicts: []
supersedes: []
superseded_by: []
decisions: []
acceptance_records: []
---

# Test Agent capability through visible local actions

## Raw statement

> 我们如果要测试当前的这个13.23b的模型的agentic能力,我们怎么测试呢?我们现在写的这种测试它是不是不太行?我能不能见到某种所见即所得的这种测试,比如说,我就直接跟他说让他在我桌面上去创建一个新的文件,然后在里面写上一句话,我能不能这样做?

No credentials, personal data, signed URLs, or machine-local attachment paths were included

## Extracted assertions

- Agent capability review should include a visible real local action in addition to deterministic sandbox scoring
- A representative task is to create a new file in a user-authorized desktop location and write an exact sentence into it
- The result should be inspectable as an actual local artifact rather than only as an emulated sandbox state
- Real local action testing requires an explicit safety and authorization boundary before implementation
