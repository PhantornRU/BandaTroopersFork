# HALO PORT BACKLOG

Secondary tracking document for HALO upstream sync waves. `HALO_PORT_STATE.md` owns the currently pinned baseline; this document tracks the requested port set, partial local coverage, open follow-up work, and branch/PR split.

## Active Sync Wave
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Previous pinned upstream commit: `95a84ab9f59f9118e5543f664b2793e7a1841c55` (`2026-03-11`)
- Target upstream head for this wave: `765e2a2f81` (`2026-04-10`)
- BandaTroopers execution model:
  - PR 1: main HALO sync wave
  - PR 2: Jackal/Spartan spawn wave (`#97` + `#100`)

## Requested Upstream PR Matrix

### Main HALO Sync PR

| Upstream PR | Title | Upstream State | Local State At Start | Planned Action |
| --- | --- | --- | --- | --- |
| `#114` | Flavor text touchup | open | partial/localized via `ab47067ef2` | finish remaining delta and document local deviations |
| `#116` | Spnkr resprite | open | missing | port |
| `#121` | Featureless Biomes | open | mostly ported via `b1860fc0c5`; `map_config/maps.txt` still diverges | finish map rotation integration without losing BT-specific entries |
| `#123` | [DNM] op stuff | open | missing | port the contained map/content pieces selectively into modular HALO ownership |
| `#126` | New Irvine updates | open | partial: local area support exists, new covenant map/update delta missing | port remaining content and reconcile map rotation |
| `#132` | CovenantAI rate of fire limits | open | partial: modular HALO firearm appraisal overrides already exist | port missing AI/ammo timing changes into current local architecture |
| `#115` | Residential Phone | merged | partial equivalent absent for HALO phone subtypes | include in this wave because `#126` depends on HALO phone subtypes |
| `#118` | Flavor Fixes | merged | partial/localized via `ab47067ef2` | verify remaining delta while finishing `#114` |
| `#122` | Fixes M6D Unloaded | merged | already localized via `1fb8fb1a27` | document as already covered |
| `#124` | fix pods | merged | already localized via `1fb8fb1a27` | document as already covered |
| `#125` | fixie fixie | merged | already localized via `1fb8fb1a27` | document as already covered |
| `#128` | rifleman support weapons change | merged | coverage to confirm against local HALO storage/vendor setup | port any missing delta |
| `#131` | makes spnkr less cumbersome | merged | partial support already exists in local HALO storageitems | port any missing delta while doing SPNKr wave |

### Separate Jackal/Spartan PR

| Upstream PR | Title | Upstream State | Local State At Start | Planned Action |
| --- | --- | --- | --- | --- |
| `#97` | Jackal framework | open | missing | port in dedicated branch/PR, then integrate with spawns and squads |
| `#100` | Spartan stuff | open | missing | port in dedicated branch/PR, then integrate with spawns |

## Confirmed Local Coverage Before New Edits
- `ab47067ef2` already localizes earlier HALO flavor/content work and references `#114`/`#118`.
- `b1860fc0c5` already ports the featureless-biomes wave related to `#121`, but local `map_config/maps.txt` still needs a manual merge.
- `1fb8fb1a27` already ports the local equivalents of upstream `#122`, `#124`, and `#125`.

## Current Branch Resolution (`halo_sync_wave_apr2026`)
- Main HALO sync branch status: implemented and locally verified; PR creation still pending.
- BandaTroopers PR: `ss220club/BandaTroopers#93`
- BandaTroopers branch: `PhantornRU:halo_sync_wave_apr2026`
- `#114` + `#118`: no missing code delta remained beyond the already-localized `ab47067ef2`; documented as previously covered.
- `#116` + `#131`: SPNKr handle/attachment setup, wearable storage flow, icon assets, and launcher case/storage updates were ported.
- `#121`: existing featureless-biome coverage was preserved; `map_config/maps.txt` was reconciled with the HALO rotation block without dropping BandaTroopers entries.
- `#123`: forerunner floor + Red Gate content was ported into new modular turf/structure files with the required icon assets.
- `#115` + `#126`: New Irvine area taxonomy, HALO phone subtypes, covenant New Irvine map/json, and missing dependency surfaces were ported. During all-maps verification the covenant map exposed a missing upstream dependency on `/obj/structure/machinery/recharger/covenant`; this subtype was ported modularly from upstream `master` so the map can compile in BandaTroopers.
- `#128`: rifleman support weapon selection, UNSC personal cases, MA5 launcher handling, shotgun/ammo balance, and `Dark Was The Night` / `Dark Was The Night ODST` spawn-map updates were ported. BandaTroopers also fixes the remaining ODST armory button to the unified `ship_armory` id because upstream `9a164b3dc8` leaves one button on the stale `ship_armory2` id after renaming the shutters.
- `#132`: covenant AI fire-rate/appraisal limits and matching projectile timing changes were ported into the current local AI architecture.
- Verification completed on this branch:
  - `git diff --check`
  - `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror`
  - `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`
  - `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`
  - `tools/bootstrap/python -m mapmerge2.dmm_test`
- Separate Jackal/Spartan PR status: still pending implementation/branch creation.

## Known Hotspots For This Wave
- `map_config/maps.txt`
- `modular/halo/code/modules/projectiles/guns/halo/{unsc_guns,unsc_gun_attachables,spnkr,unsc_magazines}.dm`
- `modular/halo/code/game/objects/items/storage/halo/halo_storageitems.dm`
- `modular/halo/code/datums/ammo/bullet/{halo_cov_ammo,halo_unsc_ammo}.dm`
- `modular/halo/code/modules/mob/living/carbon/human/ai/brain/halo_firearm_appraisals.dm`
- `code/modules/mob/living/carbon/human/ai/action_datums/fire_at_target.dm`
- `code/game/turfs/walls/r_wall.dm`
- `code/modules/cm_phone/phone_base.dm` or a modular HALO phone subtype file
- `maps/map_files/{halo_new_irvine,halo_new_irvine_covenant}/**`

## Update Rules
- Update this document in the same commits that change HALO port coverage or the upstream sync target.
- When a requested upstream PR is only partially ported locally, record both the local commit and the remaining delta here.
- When the main or secondary branch is opened as a PR, append the BandaTroopers PR number and branch name here.
