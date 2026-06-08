# EVIDENCE

## E-001: Starting state
- Active task-state previously described `outpost_radius`, not the current instruction-normalization task.
- Read-only review found contradictions across `AGENTS.md`, `WORKFLOW_RULES.md`, `.AI_AGENT/README.md`, and `POLICIES.md`.

## E-002: Plan mapping challenge
- Status: PASS WITH RISKS before implementation.
- Risk: instructions are stable guidance, so duplicated wording can drift again. Mitigation: keep `AGENTS.md` as the entrypoint and put detailed mechanics in `WORKFLOW_RULES.md`.
- Risk: concise task-state conflicts with contract tables. Mitigation: explicitly allow concise tables and summaries while keeping raw logs outside Markdown.
- Risk: tests can still be over-prioritized. Mitigation: split `Plan Fidelity` from `Verification` and make incomplete `MUST/KEEP/REJECT` block final "done".

## E-003: Expected old contradictions to remove
- "Large work" must not be the gate when a user-approved plan exists.
- Task-state edits must not be confused with product-code/docs implementation edits.
- `PASS WITH RISKS` must not allow known plan-changing risks.
- `BLOCKED` must not become permission for fallback.
- Subagents must not be implied unless explicitly permitted by user and higher-priority instructions.

## E-004: Implementation result
- `AGENTS.md` now defines read-only discovery, planning-mutation, and implementation-правки before product/stable-doc edits.
- `.AI_AGENT/README.md` now allows compact contract/fidelity tables and removes the old "new large task" lifecycle gate.
- `WORKFLOW_RULES.md` now has one approved-plan order, explicit challenge outcomes, forbidden substitutions, old-path audit, pre-final sync, and separate Plan Fidelity/Verification status.
- `POLICIES.md` now routes approved plans through task-state contract and challenge instead of generic alternatives, and blocks hotfix/wrapper/fallback substitution.

## E-005: Verification
- PASS: `git diff --check`.
- PASS: `rg` check for removed contradiction phrases. The only hit was the intended `без готового пользовательского плана` wording in `POLICIES.md`.
- PASS: mojibake scan; the only hits are intentional `Р...` examples in `WORKFLOW_RULES.md` and this evidence note.

## Plan fidelity matrix
| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Approved plans do not depend on "large work" threshold. | `AGENTS.md`, `README.md`, `WORKFLOW_RULES.md`; `rg` check. | DONE |
| M2 | MUST | One ordered workflow exists. | `WORKFLOW_RULES.md` approved-plan order. | DONE |
| M3 | MUST | Planning task-state edits are separate from implementation edits. | `AGENTS.md` and `WORKFLOW_RULES.md` planning-mutation wording. | DONE |
| M4 | MUST | `PASS WITH RISKS`, `BLOCKED`, and incomplete contract items cannot hide false done. | `WORKFLOW_RULES.md`, `POLICIES.md`. | DONE |
| M5 | MUST | Verification cannot replace plan fidelity. | `AGENTS.md`, `WORKFLOW_RULES.md`, `POLICIES.md`. | DONE |
| M6 | MUST | Subagents require explicit user/higher-priority permission; otherwise self-challenge. | `AGENTS.md`, `WORKFLOW_RULES.md`. | DONE |
| K1 | KEEP | Preserve modular-first, `rg`, build, UTF-8, and non-destructive git guidance. | Existing rules retained and clarified. | DONE |
| R1 | REJECT | Avoid another overlapping layer. | Contradictory thresholds replaced in the affected sections. | DONE |
| C1 | CHECK | Docs-level checks pass. | `git diff --check`, `rg` scans. | DONE |
