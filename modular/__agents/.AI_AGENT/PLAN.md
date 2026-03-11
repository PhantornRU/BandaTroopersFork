# PLAN

## Active task
Implemented PR `#61` HALO UNSC/ODST refactor so active squads, platoons, and ship-side role logic now inherit from and conform to the `modular/squads` runtime, with legacy ODST compat removed.

## Delivery status
- [x] Task-state rewritten for the full PR `#61` scope.
- [x] Obvious PR noise removed from the final worktree.
- [x] HALO shared defines moved to `code/__DEFINES/bandamarines/halo_jobs.dm`.
- [x] Legacy ODST compat datums, landmarks, file includes, and string contracts removed.
- [x] `marine_standart.dm` renamed to `marine_standard.dm`.
- [x] Dead `auto_squad_name_unsc` preset routing removed.
- [x] `modular/squads` remains the owner of active HALO platoon profiles, jobs, squads, lockers, and ship-role helpers.
- [x] Shared consumers in `code/**` now use `RoleAuthority` helper APIs or canonical default-role mapping instead of HALO-specific role-list widening.
- [x] HALO ship maps and tests synced to the final platoon contracts.
- [x] HALO documentation refreshed to the no-legacy contract.

## Acceptance status
- Passed: no runtime code or map path remains on legacy `/datum/squad/marine/odst`, non-namespaced ODST job paths, `SQUAD_ODST_2`, or `auto_squad_name_unsc`.
- Passed: active HALO runtime uses only `/datum/squad/marine/halo/unsc/*`, `/datum/squad/marine/halo/odst/*`, and `/datum/job/marine/.../halo/{unsc,odst}`.
- Passed: latejoin, preferences, lockers/vendors, manifest/datacore, who/end-round counters, and ship-role grouping resolve through `RoleAuthority` helpers or canonical default-role mapping.
- Passed: HALO ship maps keep `allowed_platoons` as the only platoon-selection surface and use only active HALO platoon typepaths.
- Passed with tooling caveat: `git diff --check`, main compile, all-maps compile, and maplint are clean; `tools/build/build dm-test` still returns a non-zero wrapper exit on Windows even when the produced `data/unit_tests.json` and `data/logs/ci/clean_run.lk` show a clean run.
