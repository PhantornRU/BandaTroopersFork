# PLAN

## Active task
Refine HALO mixed Sangheili sword behavior so they switch to the sword only while the target is too close or the firearm is unavailable, then return to ranged combat once the target dies or moves far away.

## Delivery status
- [x] Narrow the HALO melee-commit logic to conditional sword mode instead of combat-long commitment.
- [x] Keep firearm parking/action suppression only while sword conditions hold.
- [x] Restore the parked firearm when the melee target moves back out of sword range or disappears.
- [x] Keep the held-sword overlay refresh fix in place.
- [x] Update Sangheili unit tests for close-range sword switching and return-to-ranged behavior.
- [x] Run `dm` verification.
- [x] Attempt `dm-test` verification through the standard wrapper.

## Acceptance status
- Confirmed by code: mixed HALO Sangheili now draw the sword for close-range pressure or firearm-unavailable fights, and restore ranged state when the target moves back out of sword range or disappears.
- Confirmed by code: `energy_sword.set_activation_state()` still refreshes held hand overlays immediately for AI and players.
- Confirmed by `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed on 2026-03-13.
- `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror` still timed out in the Windows wrapper on 2026-03-13.
