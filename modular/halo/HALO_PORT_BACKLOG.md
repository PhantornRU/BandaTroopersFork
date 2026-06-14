# HALO PORT BACKLOG

Canonical baseline: [`__docs/HALO_PORT_STATE.md`](./__docs/HALO_PORT_STATE.md). For any HALO port/sync/update task, read the state doc first. If this backlog and the state doc diverge, the state doc wins.

## Current State

- **Branch**: `halo-pve-update-batch1-3b` @ `5f1e274056` (PR #102)
- **Date**: 2026-06-09
- **Status**: All must-port PRs PORTED. Review fixes applied. Clean build — 0 errors, 0 warnings.
- **PR**: https://github.com/ss220club/BandaTroopers/pull/102
- **Latest port batch**: PRs #185, #186, #183, #159 @ `10b1519718` (2026-06-12)

## Ported PRs — CM-PVE-HALO

Source: https://github.com/cmss13-devs/cmss13-pve-halo

| PR | Title | Status |
|----|-------|--------|
| #180 | Wort wort wort, lohbaba! | PORTED |
| #179 | CE-like uniforms | PORTED |
| #178 | Chemlights & Flares | PORTED |
| #176 | Thermite Grenades | PORTED |
| #174 | UNSC loose-ammo packets | PORTED — MA5/BR55/M6/M7 ammo packet boxes, packets.dmi binary, map changes |
| #173 | Plasma grenade loadouts for Unggoy | PORTED |
| #172 | RTO-bag sprite issues | PORTED |
| #171 | Shipmap lighting verb | PORTED |
| #170 | New covenant squads | PORTED |
| #169 | Featureless Biomes | PORTED |
| #168 | Jumping and Leaping | ALREADY PRESENT |
| #167 | Muzzle Flash Attach Fix | PORTED |
| #166 | ODST VISR v0.1 | PORTED |
| #165 | SPNKR A-A: Random Outcome | PORTED |
| #164 | Titan rename to Voyager | PORTED |
| #163 | Halo Minimap Fix | PORTED — conditional faction/minimap logic (CICmap, overwatch), new defines, covenant radio, headset marker_flags |
| #162 | Elite "Hero" subtypes | PORTED |
| #160 | Holy Redoubts | PORTED |
| #186 | UNSC headsets default tracks | PORTED @ `10b1519718` (2026-06-12) |
| #185 | Specialist Stuff is indestructible | PORTED @ `10b1519718` (2026-06-12) |
| #183 | UNSC & ODST Flags/Banners | PORTED @ `10b1519718` (2026-06-12) |
| #159 | Shotgun & sniper ammo boxes | PORTED — shotgun/sniper handful boxes, handful_state updates, ammo crate changes, 3 binary assets, map changes; re-ported @ `10b1519718` (2026-06-12) |
| #158 | Fire Support Binos Support | PORTED — full fire support restructure: new defines, type path restructuring, ignore_availability, radial menu, UNSC binoculars, ammo mix crates, GM faction changes |
| #157 | UNSC Medals Enabled | PORTED — medal name defines, GLOBAL_LIST_INIT expanded, USCM→UNSC text, medal desc updates |
| #156 | Presets updates, Vendor tweaks | PORTED (core) |
| #155 | ODST Drop Pod - Intro Blurb | PORTED |
| #152 | Fences | PORTED |
| #150 | Loadout selection changes | PORTED — loadout rework, new modular files (helmet_visors, helmetgarb, storage, clothing, equipment/maps), binary assets, map changes |
| #145 | bumblebee | ALREADY PRESENT |

## New PR Audit (2026-06-10)

Post-PR #102 audit of new CM-PVE-HALO and CM-PVE PRs not in the original batch.

### CM-PVE-HALO

| PR | Title | Status |
|----|-------|--------|
| #182 | [DNM][MDB IGNORE] Featureless biomes | ALREADY PRESENT — duplicate of #169; defines, maps.dm, maps.txt, 5 json, 5 dmm already in tree |
| #181 | [DNM] SoutoATV renamed to mongoose | ALREADY PRESENT — `/obj/vehicle/souto/mongoose` in `code/modules/vehicles/souto_mobile.dm` |

### CM-PVE

| PR | Title | Status |
|----|-------|--------|
| #1290 | Update README.md — fix badge | SKIP — CI-only, README badge fix |
| #1263 | Super Secret Fragile PR [DNM] [TM Only] | SKIP — DNM, TM Only |
| #1262 | Alan's GM Mega-PR [DNM] [TM ONLY] [IDB IGNORE] | SKIP — DNM, TM Only |
| #1261 | Alan Sandbox [DNM] [TM ONLY] [IDB IGNORE] | SKIP — DNM, TM Only |
| #1258 | CANC presets & squad spawner tweak | ALREADY PRESENT — MAP_COLD checks, officer preset, heap MG, squad spawners |
| #1257 | [IDB IGNORE] [DNM] OOC-2 | SKIP — DNM |
| #1256 | FSM - Flyby/Hover with SFX | ALREADY PRESENT + HALO extended — flyby ordnance, Cheyenne/Krokodil/Banshee/Seraph/Wombat/C712/C709 |
| #1255 | UPP camouflage armor/clothes (TM only) | SKIP — TM Only |
| #1253 | [DMN] [TM Only] Tethered USS Rover | SKIP — DNM, TM Only |

## Summary

| Status | CM-PVE-HALO | CM-PVE | Total |
|--------|-------------|--------|-------|
| **PORTED** | 21 | 0 | 21 |
| **ALREADY PRESENT** | 4 | 2 | 6 |
| **SKIP** | 0 | 8 | 8 |
| **Total** | 25 | 10 | 35 |

## Deferred Scope

- **Map PRs** #134/#135/#136 — full DMM integration deferred to dedicated map wave.
- **PR #97** (Kig-Yar tail) and **PR #100** (Spartan base) — deferred to `halo_jackal_spartan_wave_apr2026` branch.
- **Broad HALO AI scenario parity** beyond requested ODST/HALO flow.
- **Additional non-critical flavor drift** not affecting compile/playability.

## Next Sync Tasks
- Recheck the compatibility hotspots listed in [`__docs/HALO_PORT_STATE.md`](./__docs/HALO_PORT_STATE.md) before changing upstream-facing HALO glue.
- Keep documenting intentional source deviations from `cmss13-pve-halo`.
- Perform runtime smoke on live host/session.

## Intentional Deviations Completion (2026-06-10)

All 6 previously deferred intentional deviations from PR #102 have been ported:

- [x] **PR #163** — Halo Minimap Fix: conditional faction/minimap logic, new defines, covenant radio, headset marker_flags
- [x] **PR #158** — Fire Support Binos Support: full fire support restructure, new defines, type path restructuring, ignore_availability, radial menu, UNSC binoculars, ammo mix crates, GM faction changes
- [x] **PR #150** — Loadout selection changes: loadout rework, new modular files, binary assets, map changes
- [x] **PR #174** — UNSC loose-ammo packets: ammo packet boxes, packets.dmi binary, map changes
- [x] **PR #159** — Shotgun & sniper ammo boxes: handful boxes, handful_state updates, ammo crate changes, binary assets, map changes
- [x] **PR #157** — UNSC Medals Enabled: medal name defines, GLOBAL_LIST_INIT expanded, USCM→UNSC text, medal desc updates

### Validation
- [x] `BUILD.cmd` — 0 errors, 0 warnings
- [x] `modular_pve_halo/` path audit — 0 occurrences
- [x] Root `icons/halo/` path audit — 0 occurrences (all use `modular/halo/icons/` prefix)
- [x] `HALO_PORT_STATE.md` updated — resolved deviations documented
- [x] `HALO_PORT_BACKLOG.md` updated — all 6 PRs marked with porting notes
- [x] `BUILD.cmd` — 0 errors, 0 warnings (2026-06-10 new PR audit)

## Open Caveats
- Local monolithic invocation `tools/build/build dm --ci --define=ALL_MAPS --define=CIBUILDING` crashes DM process (`3221225477`) after map loading; staged CI-equivalent map compile remains the current acceptance signal.

## Modular Migration Cleanup (2026-06-14)

- **Status**: COMPLETE
- **Action**: HALO non-glue files (`helmet_visors.dm`, `shipmap_light_change.dm`) moved from `code/` to `modular/cm_pve/code/`. `halo_jobs.dm` kept in `code/__DEFINES/` as shared define contract.
- **Compile**: `BUILD.cmd` — 0 errors, 0 warnings.

## HALO Modular Correction (2026-06-14)

- **Status**: COMPLETE
- **Action**: HALO-specific files moved from `modular/cm_pve/` to `modular/halo/` (correct modular).
  - `shipmap_light_change.dm` → `modular/halo/code/modules/admin/game_master/extra_buttons/`
  - `helmet_visors.dm` VISR content → merged into `modular/halo/code/game/objects/items/devices/helmet_visors.dm`
- **DME**: `_halo.dme` updated, `_cm_pve.dme` cleaned of HALO includes.
- **Compile**: `BUILD.cmd` — 0 errors, 0 warnings.
