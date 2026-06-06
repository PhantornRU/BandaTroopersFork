# PLAN

## Active Task
Normalize repository AI-agent instructions so approved implementation plans cannot be replaced by small fixes, wrappers, or test-only closure.

## Goal
- Remove contradictions between `AGENTS.md`, `.AI_AGENT/README.md`, `WORKFLOW_RULES.md`, and `POLICIES.md`.
- Establish one execution order for approved plans: read-only discovery -> task-state contract -> plan-mapping challenge -> product-code/docs edits -> old-path audit -> task-state sync -> verification/final.
- Preserve the existing repository preferences for `rg`, modular-first development, build tooling, UTF-8 docs, and non-destructive git behavior.

## Scope
- Stable guidance files:
  - `AGENTS.md`
  - `modular/__agents/.AI_AGENT/README.md`
  - `modular/__agents/.AI_AGENT/WORKFLOW_RULES.md`
  - `modular/__agents/.AI_AGENT/POLICIES.md`
- Active task-state files:
  - `modular/__agents/.AI_AGENT/PLAN.md`
  - `modular/__agents/.AI_AGENT/TODO.md`
  - `modular/__agents/.AI_AGENT/DECISIONS.md`
  - `modular/__agents/.AI_AGENT/EVIDENCE.md`

## Acceptance Criteria
- No rule still depends on "large task" when the user has given or approved a concrete plan.
- Task-state edits are clearly separated from product-code/docs edits.
- `PASS WITH RISKS`, `BLOCKED`, and test status cannot hide incomplete `MUST/KEEP/REJECT` items.
- Subagents are only used when explicitly allowed by the user and current higher-priority instructions.
- Docs stay concise UTF-8 Markdown with no mojibake.
