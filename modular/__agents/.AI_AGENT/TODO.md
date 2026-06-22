# TODO

## Contract
| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| D1 | MUST | Read the repo instructions and current cinematics code path. | DONE |
| D2 | MUST | Rewrite PLAN, TODO, DECISIONS, and EVIDENCE for the round cinematics contract. | DONE |
| D3 | MUST | Create `modular/round_cinematics/IMPLEMENTATION_NOTES.md`. | DONE |
| D4 | MUST | Implement the new modular controller, session, sequence, and screen layer. | DONE |
| D5 | MUST | Wire intro hooks from `human.dm` and cryo exit hooks from `cryopod.dm`. | DONE |
| D6 | MUST | Wire round-end hooks from the active gamemode completion procs. | DONE |
| D7 | MUST | Remove or retire the legacy `modular/fullscreen/**` and `modular/round_outro/**` implementations. | DONE |
| D8 | MUST | Verify with `git diff --check` and the DM build. | DONE |
| D9 | MUST | Wire the round-cinematics admin verbs into `code/modules/admin/admin_verbs.dm`. | DONE |
| K1 | KEEP | Leave unrelated pre-existing dirty files alone unless the new flow truly depends on them. | DONE |
| R1 | REJECT | Do not reintroduce HTML or TGUI as the v1 cinematic path. | DONE |
| R2 | REJECT | Do not patch shared HUD or action systems if the module can hide and restore UI itself. | DONE |
| C1 | CHECK | Record the discovery inventory and old-path audit in repo docs. | DONE |

## Forbidden substitutions
- Do not treat a browser wrapper as the new cinematic system.
- Do not keep legacy outro reachable after the module rewrite.
- Do not store long-lived cinematic state on `/mob/living/carbon/human`.
- Do not spread the new logic across `code/**` when it can live in `modular/**`.
