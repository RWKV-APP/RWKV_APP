<a id="SPEC-SYNC-EXECUTION-PLANS"></a>

# Historical Specification-Aware Execution Plans

This file defines the validation contract for the existing checked-in plan
archive. Under `SPEC-SYNC-ROOT-INTAKE-BOUNDARY`, new Root-routed execution
plans, milestones, discoveries, decisions, and delivery evidence stay in the
private Root Mission.

A historical plan is an implementation handoff snapshot. It does not replace
canonical assertions, project truth, or Root acceptance.

## Historical Plan Contract

Every retained plan includes:

- `Status: in progress`, `Status: blocked`, or `Status: completed`
- `Started: YYYY-MM-DD` using the actual start date
- title and scope
- linked `SPEC-*`, historical `DEC-*`, and applicable historical `CF-*` IDs
- intended behavior and exclusions
- implementation milestones with observable outcomes
- mechanical checks and result-level review
- progress with timestamps
- discoveries and decisions
- final outcome, remaining gaps, and retrospective

Every plan has a non-empty H1. Each required section contains meaningful
content, and Progress includes at least one `YYYY-MM-DD` timestamp. Empty
headings do not satisfy the contract.

## Rules

- Do not create a new checked-in plan for a Root-routed task
- Keep active execution state, coordination, and acceptance in the Root Mission
- Synchronize lasting target-owned truth into canonical contracts, source, tests, architecture, and required durable documentation
- Treat historical plan status as a snapshot; it does not prove current delivery
- Preserve dirty-worktree and cross-repository scope in Root handoffs

## Completion

A retained historical plan is complete only when its own recorded Outcome,
Remaining Gaps, and Retrospective are honest. Current delivery and acceptance
are established by the active Root Mission Result, not by extending this
archive.
