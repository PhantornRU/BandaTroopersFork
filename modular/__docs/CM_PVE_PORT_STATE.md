# CM-PVE PORT STATE

Tracking document for PRs ported from CM-PVE upstream (https://github.com/cmss13-devs/cmss13-pve) into BandaTroopers.

## Active Baseline
- Source repository: `https://github.com/cmss13-devs/cmss13-pve`
- Sync branch: `halo-pve-update-batch1-3b`
- PR: https://github.com/ss220club/BandaTroopers/pull/102
- Last sync commit: `5f1e274056` (fixup! PR #102 review fixes, 2026-06-09)

## Ported PRs

| PR | Title | Status | Notes |
|----|-------|--------|-------|
| #1289 | Observer Faction Categories | PORTED | |
| #1288 | Anti Air - GM Choice | PORTED | |
| #1287 | Gas Mask Vision Impairment | PORTED | |
| #1284 | Lazy Bunker Shipmaps | SKIP | DNM/maps |
| #1283 | Movie-ish Sections | SKIP | DNM/maps |
| #1282 | The Straya War | SKIP | DNM/TMONLY |
| #1280 | Dog war atomized | SKIP | maps |
| #1278 | Call ur hits | SKIP | PVE-only LARP |
| #1277 | Movie-like Xeno Castes | SKIP | DNM |
| #1276 | FV150 'Hobelar' | SKIP | DNM/TMONLY |
| #1275 | Vanguard's Arrow | SKIP | DNM/TMONLY |
| #1273 | Gibson & Kloos | SKIP | DNM |
| #1272 | Koishi's landmines | SKIP | TM ONLY |
| #1271 | Itsy Bitsy Buggers | SKIP | DNM |
| #1270 | Featueless | SKIP | TM Only/maps |
| #1269 | Snowman | ALREADY PRESENT | |
| #1268 | Active prox_sensor | ALREADY PRESENT | |
| #1267 | Wolfpack | SKIP | TM ONLY |
| #1266 | D66-44 | SKIP | TM |
| #1265 | Auriga's Folly | SKIP | DNM |
| #1264 | Shipmap lighting GM verb | ALREADY PRESENT | |

## Summary

| Status | Count |
|--------|-------|
| **PORTED** | 3 |
| **ALREADY PRESENT** | 3 |
| **SKIP** | 15 |
| **Total** | 21 |

## Deferred / Future Work
- SKIPped PRs marked DNM/TMONLY/maps may need re-evaluation if upstream changes or if BandaTroopers scope expands.
- PR #1278 (Call ur hits) — PVE-only LARP, unlikely to be ported.
- No active branch for CM-PVE follow-up work yet.

## Update Protocol
- When new CM-PVE PRs are ported, update this file in the same change.
- If this file disagrees with PR description, this file wins for CM-PVE tracking.
