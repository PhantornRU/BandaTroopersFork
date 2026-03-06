# HALO PORT BACKLOG

## Source Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Pinned commit: `7e498b805686ab870ddcfaa3cdf348103c0e3f51` (2026-03-05)
- Current wave: `CORE + ODST parity glue`

## Port Matrix
- Ported:
  - HALO CORE species/support, weapons/ammo, armor/clothing, radios/scanners, chemistry, cryo/monitor/organs.
  - HALO map-critical runtime typepaths required by `halo_new_irvine` and `unsc_dark_was_the_night*`:
    - `dark_was_the_night` areas
    - UNSC airlocks/multi-tile airlocks
    - HALO poddoors (`/four_tile/halo`, `/vertical/halo`, `/five_tile`)
    - UNSC decals
    - UNSC reagent dispensers (`watertank/unsc`, `fueltank/liquidhydrogen`)
    - barrel and toolbox item families
    - UNSC ammo/misc boxes
    - HALO job lockers
  - ODST gameplay glue in `code/**`:
    - ODST squad/job constants
    - `ROLES_ODST` and `ROLES_SQUAD_ALL` extension
    - ODST radio channel mapping
    - ODST squad datum, latejoin and start landmarks, ODST marine job datums
    - ODST preference preview routing
    - FACTION_UNSC intro branches + alert picture typepaths.
- Deferred:
  - Broad HALO AI scenario parity beyond requested ODST/HALO flow.
  - Additional non-critical flavor drift not affecting compile/playability.

## Glue Surfaces (Current)
- `code/__DEFINES/job.dm`
- `code/__DEFINES/mode.dm`
- `code/controllers/subsystem/communications.dm`
- `code/game/jobs/job/marine/squads.dm`
- `code/game/objects/effects/landmarks/landmarks.dm`
- `code/game/jobs/job/marine/squad/{standard,leader,medic,specialist,tl}.dm`
- `code/modules/mob/new_player/preferences_setup.dm`
- `code/game/gamemodes/colonialmarines/colonialmarines.dm`
- `code/modules/mob/living/carbon/human/human.dm`
- `code/modules/maptext_alerts/misc_alert.dm`

## Validation Snapshot
- `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_BASE`: passed.
- `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_EXTRA`: passed.
- `tools/build/build dm --ci --define=ALL_MAPS`: passed.
- maplint on 3 HALO maps: passed.

## Status Updates
- `Compile Maps` blockers: **closed** (no unresolved HALO map typepaths).
- `ODST gameplay parity`: **implemented for requested scope** (jobs/squad/landmarks/comms/preferences/intro).

## Known Caveat
- Local monolithic invocation `tools/build/build dm --ci --define=ALL_MAPS --define=CIBUILDING` crashes DM process (`3221225477`) after map loading; staged CI-equivalent map compile succeeds.

## Next Sync Notes
- Recheck `modular/halo/code/mixed/compat/**` on every upstream sync.
- Keep documenting source deviations (example: ODST RTO landmark job path correction).
- Perform runtime smoke on live host/session.
