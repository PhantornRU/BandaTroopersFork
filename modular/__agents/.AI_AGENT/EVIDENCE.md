# EVIDENCE

## E-001: Upstream delta was mapped before editing
- Previous HALO pin in `HALO_PORT_STATE.md`: `7e498b805686ab870ddcfaa3cdf348103c0e3f51`.
- Current upstream head used for sync: `95a84ab9f59f9118e5543f664b2793e7a1841c55`.
- Runtime/content commits in the delta included the weapons and fixes wave, ODST pods, elite shield sprite/effects, and follow-up HALO fixes.

## E-002: HALO weapons, visuals, and assets were ported into modular HALO
- Updated or added HALO runtime/content files include:
- `modular/halo/code/modules/projectiles/guns/halo/{unsc_guns,unsc_magazines,unsc_gun_attachables,cov_guns,cov_melee,spnkr}.dm`
- `modular/halo/code/datums/ammo/bullet/halo_unsc_ammo.dm`
- `modular/halo/code/mixed/effects/halo_temp_visuals.dm`
- `modular/halo/code/modules/clothing/suits/marine_armor/covenant/{shield_armor,unggoy}.dm`
- `modular/halo/code/modules/mob/living/carbon/human/species/halo/{sangheili/unggoy}/*.dm`
- HALO sounds, onmob icons, weapon icons, lineart, mouse pointers, and drop pod assets were copied from upstream where required.

## E-003: ODST drop pods were ported with modular support layers
- Added `modular/halo/code/__DEFINES/halo_pod.dm`.
- Added `modular/halo/code/modules/admin/game_master/drop_pod_menu.dm`.
- Added `modular/halo/code/modules/halo_drop_pod/drop_pod.dm`.
- Added `modular/halo/code/mixed/compat/halo_droppod_support.dm`.
- Added `tgui/packages/tgui/interfaces/GameMasterDroppodMenu.jsx`.
- Minimal glue was added in `code/game/sound.dm`, `code/modules/admin/{admin_verbs,topic/topic}.dm`, and `code/modules/mob/living/living_verbs.dm`.

## E-004: The HALO map sync was adapted to the local SQUADS contract
- `maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm` and `maps/map_files/unsc_dark_was_the_night_odst/unsc_dark_was_the_night_odst.dmm` were synced from upstream.
- `maps/map_files/unsc_dark_was_the_night_odst/unsc_dark_was_the_night_odst.dmm` was then migrated off removed legacy ODST landmark typepaths onto current `alpha` marine landmarks.
- `modular/halo/code/mixed/structures/halo_gun_racks.dm` gained MA5B rack paths required by the synced maps.
- `modular/halo/code/mixed/ammo_boxes/halo_unsc_boxes.dm` gained MA5B ammo-box paths required by the synced maps.

## E-005: Existing user local changes were preserved
- `modular/squads/code/job/halo_modular_platoons.dm` already had local label edits and was not overwritten.
- `maps/map_files/UNSC_Stalwart_Frigate/UNSC_Stalwart_Frigate.dmm` already had local map edits and was not overwritten.

## E-006: Verification completed on 2026-03-12
- `git diff --check`: clean.
- Clean-tree verification ran in `C:\Users\Alexey\Documents\GitHub\_tmp_bt_halo_buildcheck2`.
- `tools/build/build dm --ci -DCIBUILDING -DANSICOLORS -Werror`: passed.
- `tools/build/build dm --ci -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`: passed.
- `tools/build/build dm --ci -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`: passed.
- `tools/bootstrap/python -m maplint.source ...` with `PYTHONPATH=tools`: passed for all three HALO ship maps.
- `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror` still returned a non-zero Windows wrapper exit, but the latest `data/unit_tests.json` showed all listed tests at `status: 0` and `data/logs/ci/clean_run.lk` contained `Success!`.
