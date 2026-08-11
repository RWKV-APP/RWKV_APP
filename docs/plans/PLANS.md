<a id="SPEC-SYNC-EXECUTION-PLANS"></a>

# Specification-Aware Execution Plans

Use a checked-in execution plan for complex product changes, cross-repository work, large refactors, release flows, real-model or real-device investigations, and tasks whose implementation or verification spans several stages.

An execution plan is a living implementation handoff. It does not replace private Root intake, canonical assertions, decisions, conflicts, or final acceptance.

## When To Use A Plan

Use a plan when one or more conditions apply:

- product behavior changes across several modules or repositories
- the correct implementation path needs research
- staged migration, recovery, or release work must remain resumable
- real-model, real-device, network, visual, or cross-platform verification has several checkpoints
- several agents or future tasks need a shared progress surface

Small implementation-only changes can skip a checked-in plan when the active Specification and focused verification path are already clear.

## Required Sections

Every plan includes:

- `Status: in progress`, `Status: blocked`, or `Status: completed`
- `Started: YYYY-MM-DD` using the actual start date
- title and scope
- opaque private source IDs when needed, plus linked `SPEC-*`, `DEC-*`, and applicable current `CF-*` IDs
- intended behavior and exclusions
- implementation milestones with observable outcomes
- mechanical checks and result-level review
- progress with timestamps
- discoveries and decisions
- final outcome, remaining gaps, and retrospective

`in progress` means execution or verification remains. `blocked` means a named external ruling or state change is required before meaningful progress can continue. `completed` requires an honest final Outcome, Remaining Gaps, and Retrospective; it does not imply that excluded or conflict-blocked product work was completed.

Every plan has a non-empty H1. Each required section contains meaningful content, and Progress includes at least one `YYYY-MM-DD` timestamp. Empty headings do not satisfy the contract.

## Rules

- Resolve the canonical owner before planning implementation
- Keep milestone state synchronized with the actual working tree
- Record durable product or process decisions in their own `DEC-*` records
- Stop only conflict-dependent milestones when a current conflict appears
- Do not mark a milestone complete from an unexecuted command or delegated report
- Preserve dirty-worktree and cross-repository scope in handoffs

## Completion

A plan is complete when canonical truth and delivery surfaces agree, required checks and outcome review are recorded, unresolved conflicts and exclusions remain visible, and the final `ACC-*` record accurately represents the delivered scope.
