# HALO PORT BACKLOG

Secondary tracking document for the active HALO follow-up wave. `HALO_PORT_STATE.md` owns the pinned upstream baseline; this file tracks the requested PR matrix, branch split, and open follow-up work.

## Active Sync Wave
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Previous pinned upstream commit: `95a84ab9f59f9118e5543f664b2793e7a1841c55` (`2026-03-11`)
- Target upstream head for this wave: `2ec6b82a5bbcb7bc386d14a60c890b408bb0bead` (`2026-04-26 current master`)
- Original requested snapshot: `33a011138b2529982de18896616a7cfa9d38f376` (`2026-04-24 snapshot`)
- Latest verification fetch: `cm-pve-halo/master` at `2ec6b82a5b` on 2026-04-27, with requested PR refs refreshed before final modularization; `PR #145` head `6d1c763440d1` and `PR #146` head `7a0bd462fe86` were added to the main wave on 2026-04-27, then full-master audit added `PR #113/#118/#129/#132/#138/#142/#144`.
- BandaTroopers execution model:
  - PR 1: new main HALO follow-up wave from `master`
  - PR 2: update existing `ss220club/BandaTroopers#94` with fresh Kig-Yar/Unggoy `PR #97` tail only

## Requested Upstream PR Matrix

### Main Follow-Up Wave

| Upstream PR | Title | Local State At Start | Planned Action |
| --- | --- | --- | --- |
| [`#46`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/46) | Mackay station | mixed overlap with BT `#73/#93` | manual residual import only after `15f2cc1`, no merge-commit carryover |
| [`#126`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/126) | New Irvine updates | partial; latest covenant map head missing | port post-`1bac3e1` state through `94cce6a541` |
| [`#134`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/134) | ONI Shield Base | missing | port map, areas, json, and required hooks |
| [`#135`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/135) | Valorous Chant | missing | port map, areas, json, and required hooks |
| [`#136`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/136) | 686 Regretful Flame | missing | port map, areas, json, and required hooks |
| [`#137`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/137) | modularization push lol | mostly superseded by BT modular HALO layout | audit-only; import only truly missing runtime objects/contracts |
| [`#139`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/139) | LandMines | partial overlap with existing BT landmine framework | port missing shared glue plus HALO/Covenant mine content |
| [`#140`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/140) | More Weapon Sprites | missing | sync DMI states and modular HALO gun offsets |
| [`#141`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/141) | Shrapnel overwork | missing | port shrapnel/projectile behavior needed by mine wave |
| [`#143`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/143) | BR55 Recoil | missing | port recoil/runtime delta into modular HALO gun file |
| [`#145`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/145) | bumblebee | missing | port Bumblebee escape pod assets, shuttle template, and Dark Was The Night placement through modular HALO shuttle runtime |
| [`#146`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/146) | Adds Motion Sensor HUD | missing | port UNSC helmet motion sensor HUD through modular HALO component with minimal shared HUD glue |

### Full Master Audit Additions

| Upstream PR | Title | Local State At Audit | Planned Action |
| --- | --- | --- | --- |
| [`#113`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/113) | removes prime rolling | base job files still had `prime_priority` on AI command roles | apply through modular job overrides, no base job file edit |
| [`#118`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/118) | Flavor Fixes | upstream `modular_pve_halo/**` layout absent in BT | port semantic flavor overrides into `modular/halo/code/mixed/flavor/` |
| [`#129`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/129) | Cov Create HAI updates, faction splitting | partially covered by existing HALO AI helpers | port missing Covenant split factions, SpecOps loadouts, stealth armor, and AI preset contracts modular-first |
| [`#132`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/132) | CovenantAI rate of fire limits | AI hook equivalent already present; ammo speed tail missing | keep modular AI follow-up callbacks and port remaining ammo speed contract |
| [`#138`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/138) | covenant gear update | missing Covenant DMI/gear/loadout tail | port Covenant gear/assets/storage/presets into `modular/halo/**` |
| [`#142`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/142) | fixes pelican roofs | already covered by current Pelican shuttle template roof nodes | audited no-op, document as covered |
| [`#144`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/144) | Update CODEOWNERS | no HALO runtime delta; PhantornRU section already present locally | audited no-op for runtime |

### Existing PR94 Update

| Upstream PR | Title | Local State At Start | Planned Action |
| --- | --- | --- | --- |
| [`#97`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/97) | Kig-Yar framework plus Unggoy tail | BT `PR #94` already contains the base port, but missed the refreshed tail | port `21fe2b79f4`, `4424f96051`, `4996ca9d10`, `437039a158`, `f9c7909f44`, `7e34c9db50` through current modular layout |
| [`#100`](https://github.com/cmss13-devs/cmss13-pve-halo/pull/100) | Spartan stuff | already represented by current `PR #94` base | no new scope requested in this follow-up wave |

## Branch Status
- Main follow-up branch: `halo_sync_followup_apr2026`
- Existing PR94 update branch for this wave: `codex/pr94-update`
- Previous merged baseline branch/PR: `halo_sync_wave_apr2026` / `ss220club/BandaTroopers#93`

## Known Hotspots
- `map_config/maps.txt`
- `code/game/area/{halo_new_irvine,shield_base,valorous_chant,606_regretful_flame}.dm`
- `maps/map_files/{halo_new_irvine_covenant,oni_shield_base,valorous_chant,686_regretful_flame}/**`
- `maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm`
- `maps/shuttles/bumblebee_west.dmm`
- `modular/halo/code/modules/shuttle/halo/bumblebee.dm`
- `code/_onclick/hud/human.dm`
- `modular/halo/code/mixed/components/halo_motion_sensor.dm`
- `modular/halo/code/mixed/clothing/unsc_helmets.dm`
- `code/game/objects/items/explosives/mine.dm`
- `code/datums/ammo/shrapnel.dm`
- `code/modules/projectiles/projectile.dm`
- `modular/halo/code/modules/projectiles/guns/halo/{unsc_guns,unsc_gun_attachables}.dm`
- `modular/halo/code/game/objects/items/weapons/halo_shields.dm`
- `modular/halo/code/modules/gear_presets/Halo/ruuhtian.dm`
- `modular/halo/code/modules/gear_presets/Halo/unggoy.dm`
- `modular/halo/code/modules/clothing/suits/marine_armor/covenant/unggoy.dm`
- `modular/halo/code/modules/clothing/covenant_gear_master_sync.dm`
- `modular/halo/code/modules/gear_presets/Halo/covenant_master_sync.dm`
- `modular/halo/code/mixed/flavor/halo_master_flavor.dm`
- `modular/halo/code/mixed/jobs/halo_master_job_overrides.dm`

## Update Rules
- Update this document in the same commits that change HALO port coverage or the upstream sync target.
- When a requested upstream PR is only partially ported locally, record both the imported subset and the intentional local deviation here.
- When the main PR or the `PR #94` update is opened, append the final BT PR numbers and branch names here.
