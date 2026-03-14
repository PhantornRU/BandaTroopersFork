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
