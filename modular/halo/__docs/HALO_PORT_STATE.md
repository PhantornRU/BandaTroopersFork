# HALO PORT STATE

Canonical source of truth for the active HALO sync baseline. For HALO port, sync, or update tasks, read this file first; `HALO_PORT_BACKLOG.md` stays secondary and tracks the wave split plus open work.

## Source Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Previous pinned upstream commit: `95a84ab9f59f9118e5543f664b2793e7a1841c55` (2026-03-11)
- Current pinned upstream commit for the active follow-up wave: `33a011138b2529982de18896616a7cfa9d38f376` (2026-04-24 snapshot)
- Latest verification fetch: `cm-pve-halo/master` at `2ec6b82a5b` on 2026-04-27; requested PR refs were refreshed before final modularization, including `PR #145` at `6d1c763440d1` and `PR #146` at `7a0bd462fe86`.
- Current port wave: `follow-up maps + mines/shrapnel + weapon assets/offsets + Bumblebee escape pod + motion sensor HUD + Kig-Yar/Unggoy PR94 refresh`

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
  - audit-only review of `PR #137`.
- Separate `PR #94` update ports only the fresh Kig-Yar/Unggoy tail from upstream `PR #97`, including semantic equivalents of `21fe2b79f4`, `4424f96051`, `4996ca9d10`, `437039a158`, `f9c7909f44`, and `7e34c9db50`.

## BandaTroopers Sync Anchors
- Main wave base: `master` / `upstream/master` on `66bf244f0ecf925736d9081053d35abb59fb6c6e`
- Existing Jackal/Spartan branch base: `origin/halo_jackal_spartan_wave_apr2026` on `d7a830c7dfdde8a8f849792ce01a7205a976cb4e`
- Prior merged HALO sync baseline: `ss220club/BandaTroopers#93`

## Intentional Source Deviations
- HALO guns stay modular in `modular/halo/code/modules/projectiles/guns/halo/**`; upstream HALO gun file layout is not restored.
- HALO mine content and HALO/Covenant-specific defense support stay modular-first; upstream shared explosive/shrapnel/projectile surfaces receive only minimal glue that current BT runtime actually needs.
- HALO Kig-Yar armor/shield/loadout wiring in `PR #94` stays on `ruuhtian` modular files instead of upstream `standard.dm` layout.
- HALO Unggoy armor/loadout wiring from `PR #97` stays in modular `unggoy` files; shared Human AI creator surfaces receive only the minimal preset exposure required by current BT runtime.
- Bumblebee escape pod runtime from `PR #145` stays in `modular/halo/code/modules/shuttle/halo/bumblebee.dm`; upstream `modular_pve_halo/**` includes are not imported.
- Motion sensor HUD runtime from `PR #146` stays in `modular/halo/code/mixed/components/halo_motion_sensor.dm`; shared HUD receives only one `SS220 EDIT` draw call, and UNSC helmet wiring stays in `modular/halo/code/mixed/clothing/unsc_helmets.dm`.
- `PR #137` is treated as an audit source, not as a mandatory refactor import. Current reviewed head is `b8067cc367`; only missing runtime objects/contracts may be copied from it.

## Compatibility Hotspots
- Recheck `modular/halo/code/modules/projectiles/guns/halo/{unsc_guns,unsc_gun_attachables}.dm` together with `icons/halo/obj/items/weapons/guns_by_faction/unsc/*.dmi`.
- Recheck `code/game/objects/items/explosives/mine.dm`, `code/datums/ammo/shrapnel.dm`, `code/modules/projectiles/projectile.dm`, and HALO mine content in `modular/halo/**` as one runtime bundle.
- Recheck `code/modules/mob/living/carbon/human/ai/defense_creator.dm` for overlap between existing BT mine logic and upstream `PR #139`.
- Recheck `modular/halo/code/modules/gear_presets/Halo/{ruuhtian,unggoy}.dm`, `modular/halo/code/modules/clothing/suits/marine_armor/covenant/unggoy.dm`, and the shared Human AI creator preset lists together for `PR #97`.
- Recheck `code/game/area/halo_new_irvine.dm`, `code/modules/cm_phone/halo/phone_base.dm`, and both New Irvine map/json files together.
- Recheck `map_config/maps.txt`, `code/modules/cm_marines/equipment/maps.dm`, and any new area/map prop hooks together for map PR `#134/#135/#136`.
- Recheck `maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm`, `maps/shuttles/bumblebee_west.dmm`, and `modular/halo/code/modules/shuttle/halo/bumblebee.dm` together for `PR #145`.
- Recheck `code/_onclick/hud/human.dm`, `modular/halo/code/mixed/components/halo_motion_sensor.dm`, and `modular/halo/code/mixed/clothing/unsc_helmets.dm` together for `PR #146`.

## Last Validation Snapshot
- Validation status: refreshed on `halo_sync_followup_apr2026` after adding `PR #145/#146` on 2026-04-27.
- Passed on main wave branch:
  - `git diff --check`
  - `tools/bootstrap/python tools/ci/validate_dme.py < colonialmarines.dme`
  - `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`
  - `tools/bootstrap/python -m dmi.test`
- Maplint status: changed HALO maps/templates passed, including `unsc_dark_was_the_night.dmm` and `bumblebee_west.dmm`; full repository maplint still fails on pre-existing `maps/map_files/UNSC_Stalwart_Frigate/UNSC_Stalwart_Frigate.dmm` cp1251 `UnicodeDecodeError`, outside this PR diff.
- Required verification set for this wave:
  - `git diff --check`
  - `tools/bootstrap/python tools/ci/validate_dme.py < colonialmarines.dme`
  - `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`
  - `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`
  - `tools/bootstrap/python -m tools.maplint.source --github`
  - `tools/bootstrap/python -m dmi.test`

## Update Protocol
- Any future HALO upstream baseline change must update this file in the same change.
- If a HALO sync adds a new intentional deviation or hotspot, record it here immediately.
- If this file and `HALO_PORT_BACKLOG.md` diverge, this file wins.
