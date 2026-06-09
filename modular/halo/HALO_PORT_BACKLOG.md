# HALO PORT BACKLOG

Canonical baseline: [`__docs/HALO_PORT_STATE.md`](./__docs/HALO_PORT_STATE.md). For any HALO port/sync/update task, read the state doc first. If this backlog and the state doc diverge, the state doc wins.

## Current State

- **Branch**: `halo-pve-update-batch1-3b` @ `5f1e274056` (PR #102)
- **Date**: 2026-06-09
- **Status**: All must-port PRs PORTED. Review fixes applied. Clean build — 0 errors, 0 warnings.
- **PR**: https://github.com/ss220club/BandaTroopers/pull/102

### CM-PVE (https://github.com/cmss13-devs/cmss13-pve)

| PR | Title | Status |
|----|-------|--------|
| #1289 | Observer Faction Categories | PORTED |
| #1288 | Anti Air - GM Choice | PORTED |
| #1287 | Gas Mask Vision Impairment | PORTED |
| #1284 | Lazy Bunker Shipmaps | SKIP (DNM/maps) |
| #1283 | Movie-ish Sections | SKIP (DNM/maps) |
| #1282 | The Straya War | SKIP (DNM/TMONLY) |
| #1280 | Dog war atomized | SKIP (maps) |
| #1278 | Call ur hits | SKIP (PVE-only LARP) |
| #1277 | Movie-like Xeno Castes | SKIP (DNM) |
| #1276 | FV150 'Hobelar' | SKIP (DNM/TMONLY) |
| #1275 | Vanguard's Arrow | SKIP (DNM/TMONLY) |
| #1273 | Gibson & Kloos | SKIP (DNM) |
| #1272 | Koishi's landmines | SKIP (TM ONLY) |
| #1271 | Itsy Bitsy Buggers | SKIP (DNM) |
| #1270 | Featueless | SKIP (TM Only/maps) |
| #1269 | Snowman | ALREADY PRESENT |
| #1268 | Active prox_sensor | ALREADY PRESENT |
| #1267 | Wolfpack | SKIP (TM ONLY) |
| #1266 | D66-44 | SKIP (TM) |
| #1265 | Auriga's Folly | SKIP (DNM) |
| #1264 | Shipmap lighting GM verb | ALREADY PRESENT |

## Ported PRs — CM-PVE-HALO

Source: https://github.com/cmss13-devs/cmss13-pve-halo

| PR | Title | Status |
|----|-------|--------|
| #180 | Wort wort wort, lohbaba! | PORTED |
| #179 | CE-like uniforms | PORTED |
| #178 | Chemlights & Flares | PORTED |
| #176 | Thermite Grenades | PORTED |
| #174 | UNSC loose-ammo packets | PORTED |
| #173 | Plasma grenade loadouts for Unggoy | PORTED |
| #172 | RTO-bag sprite issues | SKIP (icons-only) |
| #171 | Shipmap lighting verb | PORTED |
| #170 | New covenant squads | PORTED |
| #169 | Featureless Biomes | SKIP (maps) |
| #168 | Jumping and Leaping | ALREADY PRESENT |
| #167 | Muzzle Flash Attach Fix | PORTED |
| #166 | ODST VISR v0.1 | PORTED |
| #165 | SPNKR A-A: Random Outcome | PORTED |
| #164 | Titan rename to Voyager | PORTED |
| #163 | Halo Minimap Fix | PORTED |
| #162 | Elite "Hero" subtypes | PORTED |
| #160 | Holy Redoubts | PORTED |
| #159 | Shotgun & sniper ammo boxes | PORTED |
| #158 | Fire Support Binos Support | PORTED |
| #157 | UNSC Medals Enabled | PORTED |
| #156 | Presets updates, Vendor tweaks | PORTED (core) |
| #155 | ODST Drop Pod - Intro Blurb | PORTED |
| #152 | Fences | PORTED |
| #150 | Loadout selection changes | PORTED |
| #145 | bumblebee | ALREADY PRESENT |

## Summary

| Status | CM-PVE | CM-PVE-HALO | Total |
|--------|--------|-------------|-------|
| **PORTED** | 3 | 16 | 19 |
| **ALREADY PRESENT** | 3 | 2 | 5 |
| **SKIP** | 15 | 2 | 17 |
| **Total** | 21 | 20 | 41 |

## Deferred Scope

- **Map PRs** #134/#135/#136 — full DMM integration deferred to dedicated map wave.
- **PR #97** (Kig-Yar tail) and **PR #100** (Spartan base) — deferred to `halo_jackal_spartan_wave_apr2026` branch.
- **Broad HALO AI scenario parity** beyond requested ODST/HALO flow.
- **Additional non-critical flavor drift** not affecting compile/playability.
- **CM-PVE SKIPped PRs** (DNM/TMONLY/maps/PVE-only LARP) — may need re-evaluation if upstream changes or if PVE-only content becomes relevant for CM-PVE-HALO cross-pollination.
- **CM-PVE-HALO #172** (RTO-bag sprite issues) — SKIP (icons-only), may need re-evaluation.

## Next Sync Tasks
- Recheck the compatibility hotspots listed in [`__docs/HALO_PORT_STATE.md`](./__docs/HALO_PORT_STATE.md) before changing upstream-facing HALO glue.
- Keep documenting intentional source deviations from `cmss13-pve-halo`.
- Perform runtime smoke on live host/session.

## Open Caveats
- Local monolithic invocation `tools/build/build dm --ci --define=ALL_MAPS --define=CIBUILDING` crashes DM process (`3221225477`) after map loading; staged CI-equivalent map compile remains the current acceptance signal.
