# PLAN

## Active Task
HALO map compile blockers + ODST gameplay parity (source pin `7e498b805686ab870ddcfaa3cdf348103c0e3f51`).

## Current Status
- Missing HALO map typepaths were ported into `modular/halo/**` and wired into `_halo.dme`.
- ODST glue in `code/**` was added for squads/jobs/landmarks/radio/preferences/intro alerts.
- HALO maplint passes for all 3 HALO maps.
- CI-equivalent staged map compile (`ALL_MAPS_STAGE_BASE` + `ALL_MAPS_STAGE_EXTRA`) passes.

## Delivered Scope
- New modular files for `dark_was_the_night` areas, UNSC airlocks/poddoors/decals/reagent dispensers/barrels/toolboxes/job lockers.
- Expanded HALO ammo boxes (`/obj/item/ammo_box/magazine/unsc*`, `/misc/unsc/*`).
- ODST constants/roles and runtime glue (`job/mode/communications/squads/landmarks/jobs/preferences/intro/maptext alerts`).

## Remaining Scope
- Optional: investigate DM compiler crash in local environment for monolithic `ALL_MAPS + CIBUILDING` invocation (`exit code 3221225477`), despite staged CI map compile passing.
- Runtime smoke in-host (latejoin/start landmarks, ODST comms, FACTION_UNSC intro branch).
