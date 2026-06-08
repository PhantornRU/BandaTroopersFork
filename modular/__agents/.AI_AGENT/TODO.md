# TODO

## Contract
| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Replace the ambiguous "large work" threshold with an approved-plan rule that applies before product-code/docs edits of any size. | DONE |
| M2 | MUST | Define one ordered workflow: read-only discovery -> task-state contract -> challenge -> implementation -> audit/sync -> verification/final. | DONE |
| M3 | MUST | Separate planning task-state edits from later product-code/docs mutating edits. | DONE |
| M4 | MUST | Make `PASS WITH RISKS`, `BLOCKED`, and incomplete `MUST/KEEP/REJECT` statuses block false "done". | DONE |
| M5 | MUST | Normalize test guidance so verification cannot replace plan fidelity when the user prioritizes plan implementation. | DONE |
| M6 | MUST | Make subagent usage explicit: only when the user and higher-priority instructions allow it; otherwise self-challenge. | DONE |
| K1 | KEEP | Keep modular-first, `rg`, build-tooling, UTF-8, and non-destructive git rules. | DONE |
| R1 | REJECT | Do not add another overlapping rule layer that keeps old contradictions alive. | DONE |
| C1 | CHECK | Run docs-level checks for diff whitespace and mojibake. | DONE |

## Forbidden Substitutions
- Do not replace normalization with a small wording patch in only one file.
- Do not keep "large task" as a gate for approved-plan contracts.
- Do not make tests or compile checks the proof of plan fidelity.
- Do not let old task-state about `outpost_radius` remain active for this docs task.
