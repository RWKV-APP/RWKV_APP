---
id: ACC-20260730-WINDOWS-REAL-AGENT-FILE-CRUD
type: acceptance
date: 2026-07-30
owner: root Codex agent
inputs:
  - PI-20260726-AGENT-REAL-LOCAL-ACTION-TESTING
  - PI-20260730-AGENT-FILE-ACTIONS-IN-ORDINARY-CHAT
  - PI-20260730-AGENT-REAL-WINDOWS-FILE-CRUD
  - PI-20260730-WINDOWS-REAL-AGENT-CAPABILITY-CAMPAIGN
decisions: []
canonical_assertions:
  - SPEC-RWKV-LOCAL-AGENT-FILE-ACTIONS
  - SPEC-RWKV-VERIFICATION-BOUNDARY
changed_surfaces:
  - docs/requirements/local_agent_file_actions.md
  - docs/product-inputs/2026-07-26/PI-20260726-AGENT-REAL-LOCAL-ACTION-TESTING.md
  - docs/product-inputs/2026-07-30/PI-20260730-AGENT-FILE-ACTIONS-IN-ORDINARY-CHAT.md
  - docs/product-inputs/2026-07-30/PI-20260730-AGENT-REAL-WINDOWS-FILE-CRUD.md
  - docs/product-inputs/2026-07-30/PI-20260730-WINDOWS-REAL-AGENT-CAPABILITY-CAMPAIGN.md
  - docs/spec-process/acceptance-records/ACC-20260730-WINDOWS-REAL-AGENT-FILE-CRUD.md
  - lib/func/agent_local_file_host.dart
  - lib/func/agent_local_file_intent.dart
  - lib/func/agent_sandbox.dart
  - lib/page/benchmark/benchmark_agent.dart
  - lib/page/chat.dart
  - lib/store/agent.dart
  - lib/store/chat_input_send.dart
  - lib/store/chat_local_agent.dart
  - lib/store/chat_pause.dart
  - lib/widgets/chat/agent_local_file_approval_card.dart
  - lib/widgets/sending_interaction.dart
  - test/agent_local_file_host_test.dart
  - test/agent_local_file_intent_test.dart
unresolved_conflicts:
  - CF-20260723-PRIVACY-WEB-DEMO-DATA-FLOW
result: accepted
supersedes_acceptance: []
superseded_by: []
---

# Windows real Agent file CRUD acceptance

## Requirement review

The Windows Debug ordinary-chat surface with RWKV7-G1h 13.3B completed create, read, update, and delete against disposable real files under an explicitly authorized Desktop workspace.

The acceptance covers the atomic local-file host and the ordinary-chat authorization and approval flow. It does not extend acceptance to unrestricted shell, process, application, browser, network, metadata, permission, scheduling, or directory-management capabilities.

## Semantic or visual review

- The first file was created with exact content `stage-one`
- The same file was updated to exact content `stage-two`
- The Agent listed and read fixture files and found `capability-needle` at the independently verified line
- Rename was completed by creating `renamed.txt`, reading it back, and deleting `work.txt`
- Every create, update, and delete paused on a visible in-chat approval card
- Rejected incorrect proposals left the Windows file state unchanged
- Parent traversal was blocked and missing-file access produced a truthful failure

## Mechanical evidence

- Independent Windows inspection confirmed `work.txt` contained `stage-one` after create and `stage-two` after update
- Independent Windows inspection confirmed `work.txt` was absent after the approved delete
- Independent Windows inspection confirmed `renamed.txt` existed with length 9 and exact content `stage-two`
- The rejected copy workflow left `copy.txt` absent
- The rejected metadata and permission workflow left the source content unchanged and `IsReadOnly` false
- No Notepad window was created during the application-control probe

## Capability boundary

The real host exposes `list_files`, `read_file`, `write_file`, `delete_file`, and `submit`. Search, copy, and rename are model-composed workflows. The deterministic Agentic Evaluation tools for shell-like and scheduling tasks remain sandbox-only and did not receive host access.

The unrelated Web Demo privacy conflict remains open and does not overlap this acceptance.

## Exclusions

- Non-Windows execution was outside this acceptance
- Shell, process, application, browser, network, metadata, permission, scheduling, and directory-management capabilities were not accepted
- Copy by composition was not accepted because the model proposed incorrect target content
- The pre-existing unrelated Web Demo privacy conflict was not changed
