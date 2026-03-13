# EVIDENCE

## E-001: Sticky sword commitment was too broad for the requested behavior
- The earlier HALO helper logic kept mixed Sangheili in sword mode until combat end or sword loss.
- The clarified requirement is narrower: switch to melee for close or unusable-gun cases, then return to ranged when the target is far or gone.

## E-002: The HALO AI graph already has the right choke points
- `halo_sangheili_should_sword_charge()` controls when the dedicated sword action is eligible.
- `halo_sangheili_draw_sword()` and `halo_sangheili_holster_sword()` already own the actual equip transitions.
- That makes the HALO helper layer the minimal place to change behavior.

## E-003: The visual issue is still code-side
- `cov_melee.dm` refreshes hand overlays after sword activation changes.
- The HALO hand DMI files already expose `energy_sword` and `energy_sword_activated` for all four directions, so no art change is required for this task.

## E-004: Verification status
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed locally on 2026-03-13 after the conditional sword-switch update.
- `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror` still timed out in the Windows wrapper on 2026-03-13.
