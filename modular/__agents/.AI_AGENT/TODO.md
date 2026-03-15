# TODO

- [x] Confirm what local logs exist for round `204`.
- [x] Verify what HALO perf counters currently surface in MC stat output and CSV logging.
- [x] Capture the `round-204` runtime tied to `unggoy_panic_retreat`.
- [x] Refactor projectile-pressure helpers so AI and gun layers share one source of truth.
- [x] Add HALO AI early-outs for projectile overload in `fire_at_target` and related cheap-path checks.
- [x] Suppress non-critical HALO nearby-item/cover work during projectile overload.
- [x] Re-evaluate the live bottleneck after the projectile refactor using round-`205` MC numbers.
- [x] Move the next optimization layer into path reuse and short-range steering instead of more FX removal.
- [x] Tune HALO Covenant presets to use the new pathing controls where melee/retreat churn was observed.
- [x] Add regression tests for HALO short-step movement and retarget slack.
- [x] Inspect round-`206` logs for shield-specific evidence versus generic projectile backlog.
- [x] Fix the clientless storage runtime reached through `vehicle_locker` and generic storage UI code.
- [x] Cap sustained HALO AI firing for semiauto/automatic Covenant guns through appraisal logic.
- [x] Remove any now-unused HALO perf helpers or low-FX remnants left from earlier experiments.
- [x] Update `DECISIONS.md` and `EVIDENCE.md`.
- [x] Compile-check the final refactor.
