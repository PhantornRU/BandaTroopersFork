# HALO PORT BACKLOG

## Source Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Pinned commit: `7e498b805686ab870ddcfaa3cdf348103c0e3f51` (2026-03-05)
- Current wave: `CORE`

## CORE Matrix
- Ported:
  - Covenant species support (`Sangheili`, `Unggoy`), related datums/skills/pain/factions/languages/traits.
  - HALO weapons/ammo/attachables/magazines and related SFX keys.
  - HALO armor/clothing, storage, radio/headsets, scanners, vending, chemistry reagents.
  - HALO cryo/crew monitor/organ-limb mixed blocks and structural mixed blocks (walls/windows/turfs/gun-racks/crates).
  - HALO assets (`icons/halo/**`, HALO sound trees + required single files).
  - Maps + rotation entries:
    - `halo_new_irvine` (ground, active in `map_config/maps.txt`)
    - `unsc_dark_was_the_night` (ship, active in `map_config/shipmaps.txt`)
    - `unsc_dark_was_the_night_odst` (ship, active in `map_config/shipmaps.txt`)
  - Compile/maplint validation.
- Deferred:
  - Advanced HALO AI combat scenario parity not required for CORE.
  - Broad fire support parity and heavy cross-system integrations outside compile/playability gate.
  - Flavor-only drift not affecting CORE functionality.

## Mandatory Glue Surfaces
- `code/__DEFINES/mode.dm`
- `code/__DEFINES/mob_hud.dm`
- `code/datums/mob_hud.dm`
- `code/__DEFINES/typecheck/humanoids.dm`
- `code/__DEFINES/language.dm`
- `code/__DEFINES/mobs.dm`
- `code/__DEFINES/traits.dm`
- `code/_globalvars/lists/mobs.dm`
- `code/modules/mob/living/carbon/human/emote.dm`
- `code/modules/mob/living/carbon/human/human_helpers.dm`
- `code/modules/organs/limbs.dm`
- `code/modules/organs/limb_objects.dm`
- `code/game/sound.dm`
- `code/game/objects/items/storage/pouch.dm`
- `code/modules/projectiles/gun.dm`
- `code/modules/projectiles/gun_helpers.dm`
- `code/modules/projectiles/gun_attachables.dm`
- `code/modules/projectiles/ammo_boxes/ammo_boxes.dm`
- `code/datums/elements/traitbound/gun_silenced.dm`
- `map_config/maps.txt`
- `map_config/shipmaps.txt`

## Validation Snapshot
- `BUILD.cmd`: passed (`0 errors, 0 warnings`).
- maplint on 3 new HALO `.dmm`: passed.
- HALO icon/sound reference scan in `modular/halo/**`: `MISSING=0`.

## Next Sync Notes
- Keep importing against explicit commit pins.
- Recheck compatibility shim files in `modular/halo/code/mixed/compat/**` on each upstream sync.
- Execute manual runtime smoke checklist after deployment host is available.
