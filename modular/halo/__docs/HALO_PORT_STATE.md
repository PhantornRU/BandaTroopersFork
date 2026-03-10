# HALO PORT STATE

Канонический source of truth для текущего HALO upstream baseline. Для задач на HALO port/sync/update этот документ нужно читать до планирования и правок. [`../HALO_PORT_BACKLOG.md`](../HALO_PORT_BACKLOG.md) остается вторичным рабочим backlog и не переопределяет baseline.

## Source Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Pinned upstream commit: `7e498b805686ab870ddcfaa3cdf348103c0e3f51` (2026-03-05)
- Current port wave: `CORE + ODST parity glue`

## Scope Summary
- HALO CORE parity currently covers species/support, weapons/ammo, armor/clothing, radios/scanners, chemistry, cryo/monitor/organs.
- HALO map-critical runtime typepaths required by `halo_new_irvine`, `unsc_dark_was_the_night*`, and active UNSC ship maps are split between `modular/halo/**` content and the HALO squad-role / ship-locker layer in `modular/squads/**`.
- Active HALO ship maps use HALO platoon families selected by ship-map `platoon` config and resolved through the generic ship-profile helpers in `modular/squads`.
- Legacy single-squad ODST jobs/landmarks/squad datum remain only as compat surfaces for older ported content and are owned by `modular/squads`, not by `modular/halo`.

## BandaTroopers Sync Anchor
- Last local sync anchor commit: `e87823c878970babe535ddd0fe239516ebb8e8b8` (2026-03-06, `ODST part port`)
- Previous HALO core landing anchor: `4174552cd42952710791e2019e9de318cb82d8b0` (2026-03-06, `HALO BUILD PORT`)

## Intentional Source Deviations
- `/obj/effect/landmark/start/marine/rto/odst` points to `/datum/job/marine/standard/ai/rto/odst` instead of generic `/ai/odst` to preserve ODST RTO role correctness.
- Legacy single-squad ODST compat paths remain available even though active HALO ship maps are expected to use the HALO platoon families owned by `modular/squads`.
- HALO squad/role string contracts intentionally remain in the early-include upstream compat surface `code/__DEFINES/bandamarines/halo_jobs.dm`; `colonialmarines.dme` includes that file before `code/__DEFINES/mode.dm` so shared marine-role lists can consume the same macros without duplicating literals.
- HALO human AI faction datums for `UNSC`, `UNSC Navy`, `ONI`, `UEG Police`, `Insurgency`, and `Covenant` are a local BandaTroopers extension; pinned upstream does not ship HALO `human_ai_faction` datums.
- `FACTION_MARINE -> HALO allied bloc` friendship is bridged at runtime by the modular HALO modpack after `SShuman_ai` initializes, instead of being hard-patched into upstream `ai_brain_factions.dm`.

## Compatibility Hotspots
- Recheck `modular/halo/code/mixed/compat/**` on every upstream sync.
- Recheck HALO squad-role and ship-locker ownership surfaces in `modular/squads`: `modular/squads/code/__DEFINES/halo_unsc_crew_jobs.dm`, `modular/squads/code/job/{halo_modular_platoons,halo_odst_legacy_compat}.dm`, and `modular/squads/code/closets/{halo_marine_personal,halo_marine_personal_squads,halo_job_lockers,halo_unsc_crew_personal}.dm`.
- Recheck ODST/HALO glue surfaces in `code/**`: `code/__DEFINES/{job,mode}.dm`, `code/__DEFINES/bandamarines/halo_jobs.dm`, `colonialmarines.dme`, `code/controllers/subsystem/communications.dm`, `code/game/jobs/job/marine/{squads.dm,squad/*}.dm`, `code/game/objects/effects/landmarks/landmarks.dm`, `code/modules/mob/new_player/preferences_setup.dm`, `code/game/gamemodes/colonialmarines/colonialmarines.dm`, `code/modules/mob/living/carbon/human/human.dm`, `code/modules/maptext_alerts/misc_alert.dm`.
- Recheck HALO human-AI integration surfaces on upstream syncs: `code/controllers/subsystem/human_ai.dm`, `code/modules/mob/living/carbon/human/ai/brain/ai_brain_factions.dm`, `modular/halo/_halo.dm`, and `modular/halo/code/modules/mob/living/carbon/human/ai/brain/halo_ai_factions.dm`.
- Recheck HALO map activation/config surfaces: `map_config/maps.txt` and `map_config/shipmaps.txt`.

## Last Validation Snapshot
- `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_BASE`: passed.
- `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_EXTRA`: passed.
- `tools/build/build dm --ci --define=ALL_MAPS`: passed.
- maplint on 3 HALO maps: passed.
- Known local caveat: monolithic `tools/build/build dm --ci --define=ALL_MAPS --define=CIBUILDING` crashes DM process (`3221225477`) after map loading; staged CI-equivalent map compile remains the accepted signal.

## Update Protocol
- Any HALO upstream baseline change must update this file in the same change.
- If a HALO sync introduces new intentional deviations, compatibility hotspots, or validation expectations, update this file in the same change.
- [`../HALO_PORT_BACKLOG.md`](../HALO_PORT_BACKLOG.md) may track deferred work and open caveats, but it must not replace or contradict this document.
- If this file and backlog diverge, this file wins.
