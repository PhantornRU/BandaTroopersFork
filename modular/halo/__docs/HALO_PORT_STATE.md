# HALO PORT STATE

Canonical source of truth for the active HALO sync baseline. For HALO port, sync, or update tasks, read this file first; `HALO_PORT_BACKLOG.md` stays secondary and tracks the wave split plus open work.

## Source Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Previous pinned upstream commit: `95a84ab9f59f9118e5543f664b2793e7a1841c55` (2026-03-11)
- Current pinned upstream commit for the active follow-up wave: `33a011138b2529982de18896616a7cfa9d38f376` (2026-04-24 snapshot)
- Latest verification fetch: `cm-pve-halo/master` at `2ec6b82a5b` on 2026-04-27; requested PR refs were refreshed before final modularization.
- Current port wave: `follow-up maps + mines/shrapnel + weapon assets/offsets + Kig-Yar PR94 refresh`

## Scope Summary
- HALO content ownership stays split by module boundary:
  - `modular/halo/**` owns HALO content, gear, mapsupport runtime, weapons, assets, shields, and HALO-specific AI/preset support.
  - `modular/squads/**` continues to own HALO platoon/job/squad runtime and must not be collapsed back into upstream job trees.
- Main follow-up wave ports:
  - residual missing scope from upstream `PR #46` after `15f2cc1`;
  - `PR #126` post-`1bac3e1` state through `94cce6a541`;
  - map PR `#134`, `#135`, `#136`;
  - gameplay/runtime PR `#139`, `#140`, `#141`, `#143`;
  - audit-only review of `PR #137`.
- Separate `PR #94` update ports only the fresh Kig-Yar tail from upstream `PR #97`, including semantic equivalents of `21fe2b79f4`, `4424f96051`, `4996ca9d10`, `437039a158`, `f9c7909f44`, and `7e34c9db50`.

## BandaTroopers Sync Anchors
- Main wave base: `master` / `upstream/master` on `66bf244f0ecf925736d9081053d35abb59fb6c6e`
- Existing Jackal/Spartan branch base: `origin/halo_jackal_spartan_wave_apr2026` on `d7a830c7dfdde8a8f849792ce01a7205a976cb4e`
- Prior merged HALO sync baseline: `ss220club/BandaTroopers#93`

## Intentional Source Deviations
- HALO guns stay modular in `modular/halo/code/modules/projectiles/guns/halo/**`; upstream HALO gun file layout is not restored.
- HALO mine content and HALO/Covenant-specific defense support stay modular-first; upstream shared explosive/shrapnel/projectile surfaces receive only minimal glue that current BT runtime actually needs.
- HALO Kig-Yar armor/shield/loadout wiring in `PR #94` stays on `ruuhtian` modular files instead of upstream `standard.dm` layout.
- `PR #137` is treated as an audit source, not as a mandatory refactor import. Current reviewed head is `b8067cc367`; only missing runtime objects/contracts may be copied from it.

## Compatibility Hotspots
- Recheck `modular/halo/code/modules/projectiles/guns/halo/{unsc_guns,unsc_gun_attachables}.dm` together with `icons/halo/obj/items/weapons/guns_by_faction/unsc/*.dmi`.
- Recheck `code/game/objects/items/explosives/mine.dm`, `code/datums/ammo/shrapnel.dm`, `code/modules/projectiles/projectile.dm`, and HALO mine content in `modular/halo/**` as one runtime bundle.
- Recheck `code/modules/mob/living/carbon/human/ai/defense_creator.dm` for overlap between existing BT mine logic and upstream `PR #139`.
- Recheck `code/game/area/halo_new_irvine.dm`, `code/modules/cm_phone/halo/phone_base.dm`, and both New Irvine map/json files together.
- Recheck `map_config/maps.txt`, `code/modules/cm_marines/equipment/maps.dm`, and any new area/map prop hooks together for map PR `#134/#135/#136`.

## Last Validation Snapshot
- Validation status: pending refresh on `halo_sync_followup_apr2026` and `codex/pr94-update`
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
