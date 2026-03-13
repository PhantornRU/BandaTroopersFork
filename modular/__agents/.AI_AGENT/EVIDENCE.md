# EVIDENCE

## E-001: HALO `energy_sword` already contains the requested AI gate
- `modular/halo/code/modules/projectiles/guns/halo/cov_melee.dm` defines `should_auto_activate_for_ai(mob/living/user)`.
- The helper returns false for already active or nonfunctional swords, non-humans, non-Sangheili, users with a live client, and users without an AI brain.
- `energy_sword.attack(target, user)` calls that helper before `..()` and toggles activation first when the guard passes.

## E-002: HALO sword-charge is not the only melee path
- `modular/halo/code/modules/mob/living/carbon/human/ai/action_datums/sangheili_sword_charge.dm` draws the sword for the dedicated HALO charge path.
- `code/modules/mob/living/carbon/human/ai/action_datums/walk_melee.dm` still falls back to generic AI click/melee flow.
- This confirms the item-level `attack()` hook is the correct scope for the bugfix.

## E-003: Focused sword auto-activation tests already exist
- `code/modules/unit_tests/halo_sangheili_equipment.dm` already contains:
- `/datum/unit_test/halo_sangheili_ai_sword_auto_activation`
- `/datum/unit_test/halo_sangheili_ai_mixed_sword_auto_activation`
- `/datum/unit_test/halo_sangheili_player_sword_manual_activation_guard`
- These cover sword-only AI, mixed AI outside the draw helper path, and the player/manual guard.

## E-004: Verification status in the current workspace
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed locally on 2026-03-13.
- `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror` timed out after rebuilding `colonialmarines.test.dmb` on 2026-03-13, matching the known Windows wrapper hang pattern.
- `data/unit_tests.json` is older than the current sword-test additions and must not be used as proof for this task.
