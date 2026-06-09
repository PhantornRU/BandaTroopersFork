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
| #1284 | Lazy Bunker Shipmaps | PORTED | SS220 EDIT — карты uscm_bunker и upp_bunker, шаблоны доступа, shipmaps |
| #1283 | Movie-ish Sections | PORTED | SS220 EDIT — новые squad/role defines, карты chapaev_movie и golden_arrow_movie, UPP Liaison, Civilian Advisor, MSS Agent |
| #1282 | The Straya War | PORTED | SS220 EDIT — TWE faction warcry sounds, FACTION_TWE support в emote/sound |
| #1280 | Dog war atomized | PORTED | SS220 EDIT — M38 ammo, dog war MRE, slot preferences toggle, карта golden_arrow_dog_war, dropship typhoon changes, new vendors/attachments |
| #1278 | Call ur hits | PORTED | SS220 EDIT — LARP/airsoft items (M41A replica, foam darts) в souto.dm |
| #1277 | Movie-like Xeno Castes | PORTED | SS220 EDIT — buffed xeno castes (Runner, Drone, Soldier, Lurker, Crusher), новые defines (XENO_HEALTH_DRONE, XENO_HEALTH_SOLDIER, XENO_SPEED_RAPTOR) |
| #1276 | FV150 'Hobelar' | PORTED | SS220 EDIT — TWE tank/APC (FV150), heavy autocannon ammo, TWE vehicle interiors |
| #1275 | Vanguard's Arrow | PORTED | SS220 EDIT — VAI faction vendor, clothing (plaid/hawaiian shirts), MARSOC helmet |
| #1273 | Gibson & Kloos | PORTED | SS220 EDIT — Bodyburster и Lanky castes, hybrid species, FLAG_EMBRYO_HYBRID, XENO_SPEED_LANKY, XENO_ARMOR_TIER_9 |
| #1272 | Koishi's landmines | PORTED | SS220 EDIT — новые типы мин (claymore strong, M760, M5A3, FZD-91, TN-13), landmine shrapnel, prox_sensor, bomb suit buff |
| #1271 | Itsy Bitsy Buggers | PORTED | SS220 EDIT — Spider Guard/Nurse/Hunter и Giant Lizard castes, XENO_HEALTH_SPIDER, XENO_SPEED_SPIDER/FASTSPIDER |
| #1270 | Featueless | PORTED | SS220 EDIT — featureless карты (Space, Arctic, Desert, Barrens, Jungle), MAP_LV818_FEATURELESS_JUNGLE |
| #1269 | Snowman | ALREADY PRESENT | |
| #1268 | Active prox_sensor | ALREADY PRESENT | |
| #1267 | Wolfpack | PORTED | SS220 EDIT — M577A3E2 Wolfpack APC, wolfpack interior, hardpoints |
| #1266 | D66-44 | PORTED | SS220 EDIT — Ridgeway tank, 115mm cannon, plasma cannon, ridgeway interior |
| #1265 | Auriga's Folly | PORTED | SS220 EDIT — Xeno-Human Hybrid preset, hybrid species (NOBIOSCAN pulse, gut damage 100) |
| #1264 | Shipmap lighting GM verb | ALREADY PRESENT | |

## Summary

| Status | Count |
|--------|-------|
| **PORTED** | 18 |
| **ALREADY PRESENT** | 3 |
| **Total** | 21 |

## Deferred / Future Work
- Все CM-PVE PR портированы. SKIP статусы отсутствуют.
- Некоторые PR требуют проверки компиляции из-за交叉-зависимостей между PR (например, #1273 Gibson & Kloos и #1277 Movie-like Xeno Castes используют одни и те же defines).

## Update Protocol
- When new CM-PVE PRs are ported, update this file in the same change.
- If this file disagrees with PR description, this file wins for CM-PVE tracking.
