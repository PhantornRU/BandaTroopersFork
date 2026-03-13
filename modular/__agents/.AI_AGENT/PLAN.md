# PLAN

## Active task
Confirm and, if needed, carry the HALO Sangheili energy sword AI auto-activation fix that guarantees AI-controlled Sangheili activate an inactive sword before melee attacks without changing player behavior.

## Delivery status
- [x] Verify the fix stays HALO-local inside `energy_sword`.
- [x] Verify the gate only matches AI-controlled Sangheili with `human_ai_brain`.
- [x] Verify the hook lives in `attack()` so it covers both HALO sword-charge and generic melee fallback.
- [x] Verify focused unit coverage exists for sword-only AI, mixed AI, and player/manual guard behavior.
- [x] Rewrite active task-state away from the unrelated HALO TTS task.
- [x] Run targeted compile verification for `dm`.
- [x] Attempt `dm-test`; wrapper still hangs on Windows after rebuilding the test binary.

## Acceptance status
- Confirmed by code: `modular/halo/code/modules/projectiles/guns/halo/cov_melee.dm` already auto-activates inactive functional swords only for AI Sangheili without a live client and with an attached AI brain.
- Confirmed by code: manual activation flow, self-destruct, dropped-floor deactivation, and non-Sangheili behavior remain unchanged.
- Confirmed by code: `code/modules/unit_tests/halo_sangheili_equipment.dm` already contains the three focused sword auto-activation guards requested for this task.
- Confirmed by `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed on 2026-03-13.
- Confirmed by `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror`: `colonialmarines.test.dmb` rebuilt on 2026-03-13, but the Windows wrapper did not terminate within the timeout.
