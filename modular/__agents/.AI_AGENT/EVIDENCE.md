# EVIDENCE

## E-001: Round 204 local logs exist and include sendmaps perf data
- Local files exist under `data/logs/2026/03-March/15-Sunday/round-204/`, including `perf-204-New Irvine.csv`, `runtime.log`, `game.log`, and the standard round logs.
- `perf-204-New Irvine.csv` comes from `SS time_track` sendmaps profiling, not from MC subsystem timing.

## E-002: Round 204 sendmaps pressure grew into a movable/object storm
- Peak values from `perf-204-New Irvine.csv` include approximately:
- `maptick = 4.45249`
- `client_loop = 2.01928`
- `look_for_movable_changes = 1.29666`
- `movables_examined = 5,467,639`
- This is consistent with projectile-heavy movable churn rather than a pure UI/statpanel issue.

## E-003: Round 204 runtime hit HALO Unggoy panic-retreat
- `runtime.log` for round `204` contains `Cannot read null.halo_unggoy_runtime` in `modular/halo/code/modules/mob/living/carbon/human/ai/action_datums/unggoy_panic_retreat.dm`.
- This is a real `Human AI` correctness bug, but only one local runtime was present and it does not explain the whole projectile runaway by itself.

## E-004: Current HALO perf instrumentation surfaces only lightweight counters
- HALO perf counters currently track `temp_visuals`, `cover_scans`, `path_requests`, active shield harnesses, and projectile throttles.
- MC stat output surfaces them through `SSprojectiles`, `SShuman_ai`, and `SSpathfinding`.
- Before this task, the CSV logger did not persist those HALO counters.

## E-005: Current local evidence does not include a text dump of MC subsystem timings
- The `Human AI / Human Life / Projectiles` timing values mentioned during the investigation are not written into the local `round-204` text logs.
- Repo code shows subsystem timing snapshots are written through DB-backed `perf_logging.dm`, while filesystem logs only include the sendmaps CSV and normal round logs.

## E-006: Round-204 sendmaps peak was materially worse than adjacent calmer rounds
- Quick local comparison showed:
- `round 202`: `maptick 1.78141`, `client_loop 3.42944`, `movable_scan 2.49642`, `movables_examined 8,093,180`
- `round 203`: `maptick 4.45478`, `client_loop 1.68274`, `movable_scan 1.08918`, `movables_examined 3,095,365`
- `round 204`: `maptick 4.45249`, `client_loop 2.01928`, `movable_scan 1.29666`, `movables_examined 5,467,639`
- This supports the interpretation that round `204` was a projectile-heavy movable-churn event rather than a one-off statpanel artifact.

## E-007: Implemented mitigation now targets both projectile creation and AI support churn
- HALO projectile pressure is now cached and shared through `modular/halo/code/mixed/components/halo_projectile_backpressure.dm`.
- HALO AI now defers ranged fire earlier in `fire_at_target`, suspends nearby-item scans during combat saturation, and makes Unggoy panic retreat prefer the cheap step-away path once projectile pressure is high enough.
- HALO nearby-item search cadence for Covenant AI presets was also reduced from `0.5 SECONDS` to `1 SECONDS`.

## E-008: HALO perf CSV now preserves the incident counters needed for next repro
- `SS time_track` CSV logging now includes `halo_ai_brains`, `halo_temp_visuals`, `halo_cover_scans`, `halo_path_requests`, `halo_active_shields`, `halo_projectile_queue`, and `halo_projectile_throttles`.
- This closes the gap between what was visible live in MC stat output and what remained in local filesystem logs after the round.

## E-009: Final verification passed after the refactor
- `git diff --check` returned clean for the touched optimization and task-state files.
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` completed successfully with `0 errors, 0 warnings`.

## E-010: Round 205 shifted the main live bottleneck from projectiles to pathfinding
- Reported round-`205` live MC numbers before Sangheili spawn were approximately:
- `CPU 80`
- `Human AI 80`
- `Human Life 120`
- `Old effects 40`
- `Pathfinding 600`
- `Projectiles 60-90`
- After spawning Sangheili, the reported live numbers became approximately:
- `CPU 80-100`
- `Human AI 80`
- `Human Life 200`
- `Old effects 30`
- `Pathfinding 1300`
- `Projectiles 173`
- This strongly suggests the projectile mitigation helped, but HALO Covenant melee/retreat behavior still drives excessive path recalculation.

## E-011: Current refactor now targets nearby movement and moving-target churn directly
- `human_ai_brain` now supports cheap nearby short-step movement and configurable retarget slack before rebuilding a path.
- HALO Unggoy and Sangheili presets opt into those controls through their existing AI override hooks.
- Regression coverage now checks both the short-step movement path and the retarget-slack contract for HALO brains.

## E-012: Round 206 still looked like projectile backlog, not a shield runaway
- Reported live numbers for the last round included approximately `AI/LIFE 100/120`, `Pathfinding 600`, `Projectiles 300`, followed by `Human AI 20`, `Human Life 90`, `Pathfinding 20`, `Projectiles 0` near the end of the battle.
- `perf-206-New Irvine.csv` shows `halo_projectile_queue` spiking above `200`, while `halo_active_shields` stays around `8-12` and `halo_temp_visuals` stays near `0-4`.
- This pattern matches a projectile backlog that later drains, not a shield-specific loop that stays hot for the whole fight.

## E-013: Round 206 runtime exposed a separate clientless storage path
- `data/logs/2026/03-March/15-Sunday/round-206/runtime.log` contains `Cannot execute null.remove from screen()` in `code/game/objects/items/storage/storage.dm`.
- The call stack shows `Human AI` invoking `human_ai_act()` on a `vehicle_locker/cabinet/cups`, which reached `storage.show_to()` with a clientless AI mob.
- This is correctness noise in `Human AI`, but it is independent from the projectile queue problem.

## E-014: HALO appraisals still allowed unbounded sustained fire chains before the latest fix
- HALO plasma rifle and needler had HALO-specific appraisals but still depended on the generic action logic, which only counted `AUTOMATIC` fire toward the burst cap.
- HALO carbine had no HALO-specific appraisal at all and inherited the generic rifle appraisal.
- This left a credible path for long semiauto and automatic fire chains to keep feeding `SSprojectiles` even after backpressure was added.

## E-015: CI later exposed a helper mismatch on magazine-fed HALO guns
- The failing unit test `halo_ai_projectile_pressure_ai_helpers` asserted that a `minor_needler` brain should defer ranged fire at queue `120`, but the helper only looked at `in_chamber` and `gun.ammo`.
- HALO `needler` and `carbine` use magazine-fed state, so the helper now resolves ammo from `current_mag.default_ammo` and only reads `chamber_contents/chamber_position` through `/obj/item/ammo_magazine/internal`.
- DreamChecker also warned that `halo_projectile_backpressure.dm` touched private `SSprojectiles.projectiles`; that was replaced with a public subsystem getter, and `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed again with `0 errors, 0 warnings`.

## E-016: Round 207 stalled in pathfinding after stacked Unggoy spawns and separate UNSC squads
- User-reported live numbers for round `207` were approximately `CPU 101`, `Pathfinding 1011`, followed by a total hang after spawning many Unggoy in one tile and then multiple UNSC squads in separate positions.
- `data/logs/2026/03-March/15-Sunday/round-207/runtime.log` contains only startup lines, so the stall did not come with a visible runtime storm.
- `perf-207-New Irvine.csv` shows peaks around `halo_ai_brains 71-76`, `halo_projectile_queue` up to `105`, `movables_examined` above `2.5M`, but `halo_path_requests` near `0-6` at the same snapshots.
- This points away from "too many fresh path requests" and toward expensive in-flight path runs or repeated crowd-blocked movement on already-issued paths.

## E-017: The new mitigation resets stale A* state and lets crowd-blocked human AI sidestep locally
- `SSpathfinding.calculate_path()` now resets reused `datum/xeno_pathinfo` frontier state before starting a new destination for the same agent.
- `human_ai_brain.move_to_next_turf()` now tries a cheap local detour when the next path turf is blocked, instead of hammering the same failed adjacent step forever.
- Regression coverage was added for both behaviors in `code/modules/unit_tests/halo_unggoy_ai.dm`.
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed after these changes with `0 errors, 0 warnings`.

## E-018: The follow-up safe refactor made navigation lifecycle explicit without widening scope
- `human_ai_brain` navigation now has dedicated helpers for clearing path state, resetting navigation failures, consuming `no_path_found`, queueing a path request, and following an existing path.
- `SSpathfinding` now resolves or creates reusable `xeno_pathinfo` through a dedicated helper, and `xeno_pathinfo` configures a new search through a single proc instead of scattered field writes.
- This refactor preserved the existing external action datum API (`move_to_next_turf`) while making the shared navigation layer easier to reason about and safer to extend.
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed after the refactor with `0 errors, 0 warnings`.
