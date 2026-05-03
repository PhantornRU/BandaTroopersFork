# DECISIONS

## D-001: Use one normalized workflow instead of additive exceptions
- Decision: rewrite the affected instruction sections so approved-plan execution has one order and one set of blocking statuses.
- Why: adding extra warnings without removing old thresholds left escape hatches such as "small hotfix", "tests passed", and "not a large task".

## D-002: Treat task-state edits as the allowed planning mutation
- Decision: after read-only discovery, updating `PLAN/TODO/DECISIONS/EVIDENCE` is the only mutation allowed before implementation edits.
- Why: the previous wording required task-state updates before mutating edits while also classifying every file edit as mutating.

## D-003: Verification is separate from plan fidelity
- Decision: tests and compile checks remain expected evidence, but they cannot close `MUST/KEEP/REJECT` items by themselves.
- Why: the user's current priority is adherence to approved plans; verification should not become a substitute for requested architecture work.
