# EVIDENCE

## E-001: Legacy ODST compat runtime was removed
- `modular/squads/_squads.dme` no longer includes `code/job/halo_odst_legacy_compat.dm`.
- `modular/squads/code/job/halo_odst_legacy_compat.dm` was deleted.
- `modular/squads/code/job/marine/squad/marine_standard.dm` replaced the legacy typo-named `marine_standart.dm`.
- `code/modules/unit_tests/halo_ship_platoons.dm` now asserts that only namespaced HALO ODST runtime paths remain loadable.

## E-002: Shared HALO contracts were moved to the bandamarines define surface
- `colonialmarines.dme` now includes `code/__DEFINES/bandamarines/halo_jobs.dm` before `code/__DEFINES/mode.dm`.
- `code/__DEFINES/halo_jobs.dm` was deleted.
- `code/__DEFINES/bandamarines/halo_jobs.dm` preserves the public HALO job and platoon macros while dropping `SQUAD_ODST_2`.

## E-003: HALO presets no longer bypass SQUADS ownership through string routing
- `modular/halo/code/modules/gear_presets/Halo/unsc_marines.dm` no longer declares `auto_squad_name_unsc`, `ert_squad_halo`, or a `get_squad_by_name(...)` assignment path.
- `modular/halo/code/modules/gear_presets/Halo/unsc_crew.dm` no longer carries `auto_squad_name_unsc`.

## E-004: Shared ship-side consumers now resolve through `RoleAuthority`
- `modular/squads/code/job/ship_platoon_profiles.dm` now exposes `get_non_marine_shipside_role_titles(active_only = FALSE)` beside the existing HALO ship-profile helpers.
- Shared consumers were moved onto helper-based role classification in `code/controllers/subsystem/who.dm`, `code/datums/datacore.dm`, `code/game/gamemodes/cm_initialize.dm`, `code/game/gamemodes/extended/extended.dm`, `code/game/gamemodes/extended/infection.dm`, `code/game/gamemodes/colonialmarines/colonialmarines.dm`, `code/game/jobs/role_authority.dm`, `code/modules/admin/banjob.dm`, `code/modules/admin/topic/topic.dm`, `code/modules/cm_marines/marines_consoles.dm`, `code/modules/mob/living/carbon/human/human.dm`, and `code/modules/mob/new_player/new_player.dm`.

## E-005: HALO ship docs and tests now enforce the no-legacy contract
- `modular/halo/__docs/HALO_PORT_STATE.md` documents the final runtime ownership split and namespaced HALO squad/job paths.
- `code/modules/unit_tests/halo_ship_platoons.dm` now checks allowed-platoon flow, shipside-role classification, preview/preference resolution, and the absence of legacy ODST runtime paths.

## E-006: Verification completed on March 12, 2026
- `git diff --check` completed clean.
- Static legacy search across runtime code and maps was re-run with legacy doc/task-state paths excluded; no runtime or map matches remained for `/datum/squad/marine/odst`, `SQUAD_ODST_2`, `auto_squad_name_unsc`, or `halo_odst_legacy_compat`.
- `tools/build/build dm --ci -DCIBUILDING -DANSICOLORS -Werror` completed clean.
- `tools/build/build dm --ci -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE` and `tools/build/build dm --ci -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA` completed clean after the HALO map fixes.
- Maplint completed clean for `maps/map_files/UNSC_Stalwart_Frigate/UNSC_Stalwart_Frigate.dmm`, `maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm`, and `maps/map_files/unsc_dark_was_the_night_odst/unsc_dark_was_the_night_odst.dmm`.
- `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror` still returned a non-zero Windows wrapper exit, but the latest `data/unit_tests.json` and `data/logs/ci/clean_run.lk` produced on March 12, 2026 showed all unit tests green, including the HALO ship platoon suite.
