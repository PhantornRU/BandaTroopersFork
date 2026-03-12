# PLAN

## Active task
Update `modular/halo` from upstream `cmss13-pve-halo` and port the missing runtime/content delta on top of the already-finished HALO SQUADS refactor.

## Delivery status
- [x] Rewrite task-state for the HALO upstream sync scope.
- [x] Map the upstream delta from `7e498b805686ab870ddcfaa3cdf348103c0e3f51` to `95a84ab9f59f9118e5543f664b2793e7a1841c55`.
- [x] Port the HALO weapons, ammo, assets, temporary visuals, and shield-effects wave into `modular/halo`.
- [x] Port ODST drop pods into `modular/halo` with modular compat support and minimal glue in `code/**`.
- [x] Sync the `dark_was_the_night` HALO maps to the new content without reintroducing legacy ODST runtime paths.
- [x] Add the missing modular MA5B gun rack and ammo box types required by the upstream map content.
- [x] Refresh `HALO_PORT_STATE.md` and agent-state files to the new baseline.
- [x] Preserve existing user local changes in `modular/squads/code/job/halo_modular_platoons.dm` and `maps/map_files/UNSC_Stalwart_Frigate/UNSC_Stalwart_Frigate.dmm`.

## Acceptance status
- Passed: HALO compile, all-maps compile, and maplint are clean after the sync.
- Passed: `data/unit_tests.json` and `data/logs/ci/clean_run.lk` from the latest `dm-test` run are clean, including the HALO ship platoon suite.
- Passed with tooling caveat: the Windows `tools/build/build dm-test` wrapper still exits non-zero even when the produced test artifacts are clean.
