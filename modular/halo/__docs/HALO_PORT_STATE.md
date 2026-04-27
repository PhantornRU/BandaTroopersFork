# HALO PORT STATE

Canonical source of truth for the active HALO sync baseline. For HALO port, sync, or update tasks, read this file first; `HALO_PORT_BACKLOG.md` stays secondary and tracks the wave split plus open work.

## Source Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Previous pinned upstream commit: `95a84ab9f59f9118e5543f664b2793e7a1841c55` (2026-03-11)
- Current pinned upstream commit for the active follow-up wave: `a4943e1cd28387b86e47ba282a8cd06e7b953c96` (2026-04-27 current master)
- Original April snapshot for this wave: `33a011138b2529982de18896616a7cfa9d38f376` (2026-04-24)
- Latest verification fetch: `cm-pve-halo/master` at `a4943e1c` on 2026-04-27; requested PR refs were refreshed before final modularization, including `PR #97` at `7e34c9db`, `PR #145` at `6d1c763440d1`, `PR #146` at `7a0bd462fe86`, and the current-master audit for `PR #113/#118/#129/#132/#138/#142/#144`.
- Current port wave: `follow-up maps + mines/shrapnel + weapon assets/offsets + Bumblebee escape pod + motion sensor HUD + Covenant master sync + HALO preset coverage cleanup`

## Scope Summary
- HALO content ownership stays split by module boundary:
  - `modular/halo/**` owns HALO content, gear, mapsupport runtime, weapons, assets, shields, and HALO-specific AI/preset support.
  - `modular/squads/**` continues to own HALO platoon/job/squad runtime and must not be collapsed back into upstream job trees.
- Main follow-up wave ports:
  - residual missing scope from upstream `PR #46` after `15f2cc1`;
  - `PR #126` post-`1bac3e1` state through `94cce6a541`;
  - map PR `#134`, `#135`, `#136`;
  - gameplay/runtime PR `#139`, `#140`, `#141`, `#143`;
  - Bumblebee escape pod `PR #145`;
  - UNSC helmet motion sensor HUD `PR #146`;
  - current-master Covenant/job/flavor follow-ups from `PR #113`, `PR #118`, `PR #129`, `PR #132`, and `PR #138`;
  - audit-only review of already covered `PR #142` Pelican roof node delta and no-runtime `PR #144` CODEOWNERS/changelog delta;
  - audit-only review of `PR #137`.
- Separate `PR #94` update ports only the fresh Kig-Yar/Unggoy tail from upstream `PR #97`, including semantic equivalents of `21fe2b79f4`, `4424f96051`, `4996ca9d10`, `437039a158`, `f9c7909f44`, and `7e34c9db50`.
- Preset coverage cleanup keeps the same upstream anchors but verifies concrete combat-ready presets across Sangheili, Unggoy, UNSC, ODST, UNSC Crew, ONI, UEG Police and Insurrectionist families. Ruuhtian/Kig-Yar preset/species coverage belongs to the separate `PR #94` update branch.

## BandaTroopers Sync Anchors
- Main wave base: `master` / `upstream/master` on `66bf244f0ecf925736d9081053d35abb59fb6c6e`
- Existing Jackal/Spartan branch base: `origin/halo_jackal_spartan_wave_apr2026` on `d7a830c7dfdde8a8f849792ce01a7205a976cb4e`
- Prior merged HALO sync baseline: `ss220club/BandaTroopers#93`

## Intentional Source Deviations
- HALO guns stay modular in `modular/halo/code/modules/projectiles/guns/halo/**`; upstream HALO gun file layout is not restored.
- HALO mine content and HALO/Covenant-specific defense support stay modular-first; upstream shared explosive/shrapnel/projectile surfaces receive only minimal glue that current BT runtime actually needs.
- HALO Kig-Yar armor/shield/loadout wiring in `PR #94` stays on `ruuhtian` modular files instead of upstream `standard.dm` layout.
- HALO Unggoy armor/loadout wiring from `PR #97` stays in modular `unggoy` files; shared Human AI creator surfaces receive only the minimal preset exposure required by current BT runtime.
- Ruuhtian/Kig-Yar species, organs, language, clothing, shields, presets, HumanAI wrappers and squad spawner cells are intentionally owned by the separate `PR #94` update branch; the main wave keeps only shared Covenant faction/AI compatibility needed by upstream `PR #129/#138`.
- UNSC/ODST leader equipped presets intentionally use M392 DMRs, and UNSC Frigate Squad Leader job lockers place unloaded DMRs instead of BR55s. Rifleman/medic/RTO/pilot BR55/MA5C loadouts are left unchanged.
- Bumblebee escape pod runtime from `PR #145` stays in `modular/halo/code/modules/shuttle/halo/bumblebee.dm`; upstream `modular_pve_halo/**` includes are not imported.
- Motion sensor HUD runtime from `PR #146` stays in `modular/halo/code/mixed/components/halo_motion_sensor.dm`; shared HUD receives only one `SS220 EDIT` draw call, and UNSC helmet wiring stays in `modular/halo/code/mixed/clothing/unsc_helmets.dm`.
- Covenant gear/faction/loadout sync from upstream `PR #129/#132/#138` stays in modular `modular/halo/**` files. Shared faction defines are limited to the existing `SS220 EDIT` HALO faction block in `code/__DEFINES/mode.dm`, while Game Master HumanAI machinegunner/sniper preset menus receive only HALO preset list glue.
- Flavor text updates from upstream `PR #118` stay in `modular/halo/code/mixed/flavor/halo_master_flavor.dm`; the upstream `modular_pve_halo/**` layout is not imported.
- The `prime_priority` removal from upstream `PR #113` is applied through `modular/halo/code/mixed/jobs/halo_master_job_overrides.dm` instead of editing the base job files.
- `PR #126` New Irvine auto-grass turf definitions stay in `modular/halo/code/mixed/turfs/halo_new_irvine_auto_turfs.dm`, and New Irvine forest flora object definitions stay in `modular/halo/code/mixed/structures/halo_new_irvine_flora.dm`; the base `r_wall/bunker/hull` subtype is intentionally anchored as a tiny `SS220 EDIT` shared wall compatibility block because New Irvine DMMs reference the shared wall path directly.
- `PR #46` Mackay/ONI Digsite shuttle IDs are covered by BT-specific shared glue in `code/__DEFINES/bandamarines/halo_map_support.dm`; map item contracts are covered via JSON `map_item_type` resolution and direct fallback creation. These are intentionally not duplicated in `code/__DEFINES/shuttles.dm`.
- `PR #142` is treated as covered because current `maps/shuttles/dropship_pelican.dmm` already contains the additional Pelican roof nodes. `PR #144` has no runtime delta for BT beyond the already present PhantornRU CODEOWNERS section.
- `PR #137` is treated as an audit source, not as a mandatory refactor import. Current reviewed head is `b8067cc367`; sunglasses and UNSC grenade runtime additions are already covered in current modular HALO files, so only genuinely missing runtime objects/contracts are copied from it.

## Compatibility Hotspots
- Recheck `modular/halo/code/modules/projectiles/guns/halo/{unsc_guns,unsc_gun_attachables}.dm` together with `icons/halo/obj/items/weapons/guns_by_faction/unsc/*.dmi`.
- Recheck `code/game/objects/items/explosives/mine.dm`, `code/datums/ammo/shrapnel.dm`, `code/modules/projectiles/projectile.dm`, and HALO mine content in `modular/halo/**` as one runtime bundle.
- Recheck `code/modules/mob/living/carbon/human/ai/defense_creator.dm`, `code/game/objects/items/storage/boxes.dm`, and `code/game/objects/structures/crates_lockers/largecrate_supplies.dm` for overlap between existing BT mine logic and upstream `PR #139`.
- Recheck `code/modules/mob/living/carbon/human/ai/action_datums/{mg_nest,sniper_nest}.dm`, `modular/halo/code/modules/gear_presets/Halo/unsc_marines.dm`, `modular/halo/code/modules/mob/living/carbon/human/ai/ai_spawner/ai_presets_unsc.dm`, and `modular/halo/code/modules/unit_tests/halo_preset_coverage.dm` together for upstream `PR #129` HumanAI preset exposure.
- Recheck `modular/halo/code/modules/gear_presets/Halo/{ruuhtian,unggoy}.dm`, `modular/halo/code/modules/clothing/ruuhtian_gear.dm`, `modular/halo/code/modules/mob/living/carbon/human/species/halo/ruuhtian/ruuhtian.dm`, `modular/halo/code/modules/mob/living/carbon/human/ai/ai_spawner/ai_presets_ruuhtian.dm`, and the shared Human AI creator preset lists together for `PR #97`.
- Recheck `code/game/area/halo_new_irvine.dm`, `code/modules/cm_phone/halo/phone_base.dm`, and both New Irvine map/json files together.
- Recheck `modular/halo/code/mixed/turfs/halo_new_irvine_auto_turfs.dm`, `modular/halo/code/mixed/structures/halo_new_irvine_flora.dm`, `icons/turf/floors/auto_forest_irvine.dmi`, New Irvine flora/area DMI assets, and `code/game/turfs/walls/r_wall.dm` together for `PR #126` map/turf parity.
- Recheck `map_config/maps.txt`, `code/modules/cm_marines/equipment/maps.dm`, and any new area/map prop hooks together for map PR `#134/#135/#136`.
- Recheck `maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm`, `maps/shuttles/bumblebee_west.dmm`, and `modular/halo/code/modules/shuttle/halo/bumblebee.dm` together for `PR #145`.
- Recheck `code/_onclick/hud/human.dm`, `modular/halo/code/mixed/components/halo_motion_sensor.dm`, and `modular/halo/code/mixed/clothing/unsc_helmets.dm` together for `PR #146`.
- Recheck `modular/halo/code/modules/clothing/covenant_gear_master_sync.dm`, `modular/halo/code/modules/gear_presets/Halo/covenant_master_sync.dm`, `modular/halo/code/game/objects/items/storage/halo/covenant_storage_master_sync.dm`, and Covenant DMI assets together for `PR #138`.
- Recheck `modular/halo/code/mixed/flavor/halo_master_flavor.dm` and `modular/halo/code/mixed/jobs/halo_master_job_overrides.dm` when auditing full upstream master PRs `#113/#118`.

## Last Validation Snapshot
- Validation status: refreshed on `halo_sync_followup_apr2026` after adding HALO preset coverage cleanup on 2026-04-27.
- Passed in the latest local pass:
  - `git diff --check`
  - `cmd /c "tools\bootstrap\python tools\ci\validate_dme.py < colonialmarines.dme"`
  - `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - `tools/build/build --ci clean dm-test -DCIBUILDING -DANSICOLORS -Werror` compile phase (`colonialmarines.test.dmb` built cleanly)
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`
  - `tools/bootstrap/python -m dmi.test`
- Runtime `dm-test` runner was stopped after several minutes without additional output after compile; rerun in CI or locally when a full unit-test runtime result is required.
- `tools/build/build --ci clean dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE` is not the valid local ordering: `clean` runs after `dm-maps-include` and removes generated `maps/templates_base.dm`. Run ALL_MAPS without `clean` or invoke the targets separately.
- `tools/bootstrap/python -m tools.maplint.source --github` is not a valid module path in this checkout; `tools/bootstrap/python -m maplint.source --github` was run instead.
- Full repository maplint still fails only on the pre-existing `maps/map_files/UNSC_Stalwart_Frigate/UNSC_Stalwart_Frigate.dmm` cp1251 `UnicodeDecodeError`; all other maps reported OK in the latest run, and ALL_MAPS compile covers the edited Frigate DMM.
- Required verification set for this wave:
  - `git diff --check`
  - `tools/bootstrap/python tools/ci/validate_dme.py < colonialmarines.dme`
  - `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`
  - `tools/bootstrap/python -m maplint.source --github`
  - `tools/bootstrap/python -m dmi.test`

## Update Protocol
- Any future HALO upstream baseline change must update this file in the same change.
- If a HALO sync adds a new intentional deviation or hotspot, record it here immediately.
- If this file and `HALO_PORT_BACKLOG.md` diverge, this file wins.
