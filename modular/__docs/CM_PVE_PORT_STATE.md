# CM-PVE PORT STATE

Canonical tracking document for PRs ported from CM-PVE upstream (https://github.com/cmss13-devs/cmss13-pve) into BandaTroopers.

## Active Baseline

- Source repository: `https://github.com/cmss13-devs/cmss13-pve`
- Sync branch: `halo-pve-update-batch1-3b`
- PR: https://github.com/ss220club/BandaTroopers/pull/102
- Last sync commit: `5f1e274056` (fixup! PR #102 review fixes, 2026-06-09)
- This file is the canonical source of truth for CM-PVE porting.
- For CM-PVE-HALO PRs see [`HALO_PORT_STATE.md`](../halo/__docs/HALO_PORT_STATE.md).
- For complete porting history see [`VARIOUS_FIXES_PORTING_MAP.md`](VARIOUS_FIXES_PORTING_MAP.md).

## Ported PRs

| PR | Title | Status | SS220 EDIT Files | Notes |
|----|-------|--------|------------------|-------|
| #1289 | Observer Faction Categories | **PORTED** | `code/__DEFINES/mode.dm`, `code/modules/mob/dead/observer/orbit.dm`, `tgui/packages/tgui/interfaces/Orbit/index.tsx`, `tgui/packages/tgui/interfaces/Orbit/types.ts` | QoL — faction categories in observer orbit menu |
| #1288 | Anti Air - GM Choice | **PORTED** | `code/datums/ammo/misc.dm`, `code/modules/admin/topic/topic.dm:1219-1248`, `code/modules/projectiles/guns/specialist/launcher/rocket_launcher.dm` | GM verb for USCM AA launcher, SPNKR AA sounds |
| #1287 | Gas Mask Vision Impairment | **PORTED** | `code/game/objects/items.dm:853-862`, `code/modules/clothing/head/helmet.dm:1113-1477`, `code/modules/clothing/masks/gasmask.dm:24-249` | Vision impair + scope allowance for enclosed helmets/gas masks |
| #1284 | Lazy Bunker Shipmaps | **PORTED** | `code/global.dm`, `map_config/shipmaps.txt` | Maps: `uscm_bunker`, `upp_bunker`, access templates, JSON configs |
| #1283 | Movie-ish Sections | **PORTED** | `code/__DEFINES/access.dm`, `code/__DEFINES/job.dm`, `code/__DEFINES/mode.dm`, `code/datums/skills/civilian.dm`, `code/datums/skills/upp.dm`, `code/game/jobs/job/civilians/other/liaison.dm`, `code/game/jobs/job/marine/squads.dm`, `code/modules/clothing/suits/marine_coat.dm`, `code/modules/gear_presets/uscm_ship.dm` | Maps: `chapaev_movie`, `golden_arrow_movie`. New roles: UPP Liaison, Civilian Advisor, MSS Agent |
| #1282 | The Straya War | **PORTED** | `code/game/sound.dm:595-612`, `code/modules/mob/living/carbon/human/emote.dm:382-394` | TWE faction warcry sounds, FACTION_TWE support |
| #1280 | Dog war atomized | **PORTED** | `code/_globalvars/misc.dm`, `code/datums/ammo/bullet/special_ammo.dm`, `code/game/machinery/vending/vendor_types/squad_prep/squad_medic.dm`, `code/game/objects/items/explosives/grenades/marines.dm`, `code/game/objects/items/reagent_containers/food/mre_food/dog_war.dm`, `code/game/objects/items/storage/backpack.dm`, `code/game/objects/items/storage/mre.dm`, `code/modules/client/preferences.dm`, `code/modules/clothing/head/helmet.dm`, `code/modules/clothing/shoes/marine_shoes.dm`, `code/modules/clothing/suits/marine_armor/_marine_armor.dm`, `code/modules/clothing/under/marine_uniform.dm`, `code/modules/clothing/under/ties.dm`, `code/modules/cm_marines/dropship_equipment.dm`, `code/modules/cm_marines/smartgun_mount.dm`, `code/modules/projectiles/ammo_boxes/grenade_boxes.dm`, `code/modules/projectiles/ammo_boxes/magazine_boxes.dm`, `code/modules/projectiles/ammo_boxes/misc_boxes.dm`, `code/modules/projectiles/gun_attachables.dm`, `code/modules/projectiles/guns/misc.dm`, `code/modules/projectiles/guns/rifles.dm`, `code/modules/projectiles/magazines/misc.dm`, `code/modules/projectiles/magazines/rifles.dm`, `colonialmarines.dme` | M38 ammo, dog war MRE, slot preferences toggle, map `golden_arrow_dog_war`, dropship typhoon changes, new vendors/attachments |
| #1278 | Call ur hits | **PORTED** | `code/datums/emergency_calls/souto.dm` | LARP/airsoft items: M41A replica, foam darts, BB ammo |
| #1277 | Movie-like Xeno Castes | **PORTED** | `code/__DEFINES/xeno.dm:247-248,332`, `code/modules/mob/living/carbon/xenomorph/castes/Drone.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Runner.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Soldier.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Lurker.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Crusher.dm` | Buffed xeno castes: Runner, Drone, Soldier, Lurker, Crusher. New defines: XENO_HEALTH_DRONE, XENO_HEALTH_SOLDIER, XENO_SPEED_RAPTOR |
| #1276 | FV150 'Hobelar' | **PORTED** | `code/datums/vehicles.dm:133-145`, `code/modules/vehicles/twe_tank/twe_apc.dm`, `code/modules/vehicles/twe_tank/twe_tank.dm`, `code/modules/vehicles/hardpoints/hardpoint_ammo/heavy_autocannon.dm` | TWE tank/APC (FV150), heavy autocannon ammo, TWE vehicle interiors |
| #1275 | Vanguard's Arrow | **PORTED** | `code/modules/clothing/under/vai.dm:1-49`, `code/game/machinery/vending/vendor_types/squad_prep/squad_prep.dm`, `colonialmarines.dme` | VAI faction vendor, clothing (plaid/Hawaiian shirts), MARSOC helmet |
| #1273 | Gibson & Kloos | **PORTED** | `code/__DEFINES/xeno.dm:110,229,325,718-719,727`, `code/__DEFINES/mobs.dm`, `code/__DEFINES/typecheck/xenos.dm`, `code/game/jobs/role_authority.dm`, `code/game/machinery/medical_pod/autodoc.dm`, `code/modules/admin/game_master/game_master.dm`, `code/modules/admin/game_master/game_master_submenu/infest.dm`, `code/modules/admin/player_panel/actions/transform.dm`, `code/modules/mob/living/carbon/human/ai/brain/ai_brain_items.dm`, `code/modules/mob/living/carbon/xenomorph/Embryo.dm`, `modular/xeno_races/code/bodyburster.dm`, `modular/xeno_races/code/lanky.dm`, `modular/xeno_races/_xeno_races.dm` | Bodyburster и Lanky castes, hybrid species, FLAG_EMBRYO_HYBRID, XENO_SPEED_LANKY, XENO_ARMOR_TIER_9 |
| #1272 | Koishi's landmines | **PORTED** | `code/game/objects/items/explosives/mine.dm:373-382,393-918`, `code/__DEFINES/guns.dm`, `code/datums/ammo/shrapnel.dm`, `code/game/objects/items/storage/boxes.dm`, `code/game/objects/structures/crates_lockers/largecrate_supplies.dm`, `code/modules/assembly/proximity.dm`, `code/modules/clothing/suits/utility.dm`, `code/modules/mob/living/carbon/human/ai/defense_creator.dm` | New mine types: claymore strong, M760, M5A3, FZD-91, TN-13. Landmine shrapnel, prox_sensor, bomb suit buff |
| #1271 | Itsy Bitsy Buggers | **PORTED** | `code/__DEFINES/xeno.dm`, `code/__DEFINES/typecheck/xenos.dm`, `code/game/jobs/role_authority.dm`, `code/game/sound.dm`, `code/modules/admin/game_master/game_master.dm`, `code/modules/admin/game_master/game_master_submenu/ambush.dm`, `code/modules/mob/living/carbon/xenomorph/abilities/general_abilities.dm`, `code/modules/mob/living/carbon/xenomorph/abilities/general_ability_macros.dm`, `code/modules/mob/living/carbon/xenomorph/ai/movement/spider.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Spider_Guard.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Spider_Hunter.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Spider_Nurse.dm`, `code/modules/mob/living/carbon/xenomorph/castes/Giant_Lizard.dm`, `code/modules/mob/living/carbon/xenomorph/death.dm`, `code/modules/mob/living/carbon/xenomorph/emote.dm`, `colonialmarines.dme` | Spider Guard/Nurse/Hunter и Giant Lizard castes, XENO_HEALTH_SPIDER, XENO_SPEED_SPIDER/FASTSPIDER |
| #1270 | Featueless | **PORTED** | `code/__DEFINES/__game.dm:58-62`, `code/modules/cm_marines/equipment/maps.dm`, `map_config/maps.txt` | Featureless maps: Space, Arctic, Desert, Barrens, Jungle. MAP_LV818_FEATURELESS_JUNGLE |
| #1269 | Snowman | **PORTED** | `code/modules/clothing/head/helmet.dm:2381`, `code/modules/clothing/suits/marine_armor/_marine_armor.dm`, `code/modules/gear_presets/canc.dm`, `code/modules/mob/living/carbon/human/ai/action_datums/mg_nest.dm`, `code/modules/mob/living/carbon/human/ai/action_datums/sniper_nest.dm`, `code/modules/mob/living/carbon/human/ai/ai_spawner/ai_presets_canc.dm` | CANC presets, snowman helmet/armor |
| #1268 | Active prox_sensor | **PORTED** | `code/modules/assembly/proximity.dm:43-49`, `code/modules/mob/living/carbon/human/ai/defense_creator.dm` | Active proximity sensor with UI, scanning, cooldown |
| #1267 | Wolfpack | **PORTED** | `code/datums/vehicles.dm:33-35`, `code/modules/vehicles/apc/apc_wolfpack.dm`, `code/modules/vehicles/hardpoints/holder/tank_turret.dm`, `code/modules/vehicles/hardpoints/primary/ltb.dm`, `colonialmarines.dme` | M577A3E2 Wolfpack APC, wolfpack interior, hardpoints |
| #1266 | D66-44 | **PORTED** | `code/datums/vehicles.dm:65-67`, `code/modules/vehicles/ridgewaytank/ridgewaytank.dm`, `code/modules/vehicles/ridgewaytank/interior.dm`, `code/modules/vehicles/hardpoints/hardpoint_ammo/ridgewaycannon_ammo.dm`, `code/modules/vehicles/hardpoints/hardpoint_ammo/plasma_cannon.dm`, `code/modules/vehicles/hardpoints/primary/ridgeway_cannon.dm`, `code/modules/vehicles/hardpoints/primary/plasma_cannon.dm`, `code/datums/ammo/rocket.dm`, `code/modules/projectiles/magazines/specialist.dm`, `colonialmarines.dme` | Ridgeway tank, 115mm cannon, plasma cannon, ridgeway interior |
| #1265 | Auriga's Folly | **PORTED** | `code/modules/gear_presets/synths.dm`, `code/modules/mob/living/carbon/human/life/handle_pulse.dm`, `code/modules/mob/living/carbon/human/powers/human_powers.dm`, `code/modules/mob/living/carbon/human/species/synthetic.dm` | Xeno-Human Hybrid preset, hybrid species (NOBIOSCAN pulse, gut damage 100) |
| #1264 | Shipmap lighting GM verb | **PORTED** | `code/game/area/areas.dm`, `code/modules/admin/admin_verbs.dm`, `code/modules/admin/game_master/extra_buttons/light_change.dm`, `code/modules/admin/game_master/extra_buttons/shipmap_light_change.dm`, `colonialmarines.dme` | GM verb for shipmap lighting control |
| #1263 | Super Secret Fragile PR | **PORTED** | `code/game/objects/items/devices/taperecorder.dm` | Tape recorder messages color: MAROON → GREEN |
| #1258 | CANC presets & squad spawner tweak | **PORTED** | `code/modules/gear_presets/canc.dm`, `code/modules/mob/living/carbon/human/ai/ai_spawner/ai_presets_canc.dm`, `code/modules/mob/living/carbon/human/ai/squad_spawner/squad_clf.dm` | Cold weather scarf for CANC presets; new `remnant/officer`, `machinegunner/heap` presets; paygrade fixes; new CANC squad presets |
| #1257 | OOC-2 | **PORTED** | `code/modules/admin/admin_verbs.dm`, `code/modules/admin/game_master/extra_buttons/chapter_title.dm`, `code/modules/admin/game_master/extra_buttons/send_tip.dm`, `icons/mob/hud/screen2_full.dmi`, `colonialmarines.dme` | Chapter Title GM verb, Send Tip GM verb, disable tip_of_the_round |
| #1256 | FSM - Flyby/Hover with SFX | **ALREADY PRESENT** | `code/game/objects/effects/overlays.dm`, `code/modules/admin/game_master/extra_buttons/fire_support_menu.dm`, `tgui/packages/tgui/interfaces/GameMasterFireSupportMenu.jsx` | Cheyenne/Krokodil flyby/hover effects — already ported via HALO |
| #1255 | UPP camouflage armor/clothes | **PORTED** | `code/modules/clothing/head/helmet.dm`, `code/modules/clothing/suits/marine_armor/ert.dm`, `code/modules/clothing/under/marine_uniform.dm`, `code/modules/clothing/under/ties.dm` | `NO_SNOW_TYPE` removed from combat UPP gear; `select_gamemode_skin` added in `Initialize()`; DMI sprites imported (2026-06-14) |
| #1253 | Tethered USS Rover | **PORTED** | `map_config/shipmaps.txt`, `maps/rover_tethered.json`, `maps/map_files/rover_tethered/rover_tethered.dmm` | New shipmap: USS Rover Tethered for FORECON VBSS |

## Summary

| Status | Count |
|--------|-------|
| **PORTED** | 26 |
| **ALREADY PRESENT** | 1 |
| **Total** | 27 |

## Deferred / Future Work

- #1262 Alan's GM Mega-PR (>300 files, персональный GM-контент, требует отдельной задачи)
- #1261 Alan Sandbox (>300 files, персональный сэндбокс, требует отдельной задачи)
- #1290 Update README.md (CI-only badge fix, нерелевантен для BT)
- Некоторые PR требуют проверки компиляции из-за кросс-зависимостей между PR (например, #1273 Gibson & Kloos и #1277 Movie-like Xeno Castes используют одни и те же defines).
- Для полной истории портирования см. [`VARIOUS_FIXES_PORTING_MAP.md`](VARIOUS_FIXES_PORTING_MAP.md).

## Modular Migration Cleanup (2026-06-14)

- **Status**: COMPLETE
- **Action**: 8 non-glue files moved from `code/` to `modular/cm_pve/code/`, includes cleaned from `colonialmarines.dme` and `colonialmarines.test.dme`.
- **Files moved**: `dog_war.dm`, `shipmap_light_change.dm`, `vai.dm`, `helmet_visors.dm` (halo), `heavy_autocannon.dm`, `twe_tank/interior.dm`, `twe_tank/twe_apc.dm`, `twe_tank/twe_tank.dm`.
- **Kept in code/**: `halo_jobs.dm` (shared define contracts per Path Matrix rule 8), all `code/__DEFINES/bandamarines/*` (stable contracts).
- **New module**: `modular/cm_pve/` with `_cm_pve.dme` + `_cm_pve.dm`, included in `modular/modular.dme` after HALO.
- **Compile**: `BUILD.cmd` — 0 errors, 0 warnings.
- **No content deleted**. Original files remain in `code/` as fallback until cleanup is validated.

## HALO Modular Correction (2026-06-14)

- **Status**: COMPLETE
- **Action**: HALO-specific files incorrectly placed in `modular/cm_pve/` moved to `modular/halo/`.
- **Files moved to `modular/halo/`**:
  - `shipmap_light_change.dm` → `modular/halo/code/modules/admin/game_master/extra_buttons/shipmap_light_change.dm` (HALO upstream PR #171)
  - `helmet_visors.dm` (VISR night vision) → merged into existing `modular/halo/code/game/objects/items/devices/helmet_visors.dm` (appended after IHADSS visor)
- **Files kept in `modular/cm_pve/`** (pure CM-PVE, not HALO):
  - `vai.dm` — VAI faction clothing (CM-PVE PR #1275)
  - `dog_war.dm` — Dog War MRE food (CM-PVE PR #1280)
  - `twe_tank/` — FV150 Hobelar tank/APC (CM-PVE PR #1276)
  - `heavy_autocannon.dm` — 45mm L29A2 ammo (CM-PVE PR #1276)
- **DME updates**:
  - `modular/halo/_halo.dme`: added `#include` for `shipmap_light_change.dm`
  - `modular/cm_pve/_cm_pve.dme`: removed `#include` for `helmet_visors.dm` and `shipmap_light_change.dm`
- **`code/__DEFINES/halo_jobs.dm`**: kept in `code/` as required glue (used by `code/__DEFINES/mode.dm`, `code/game/jobs/job/marine/squads.dm`, `code/controllers/subsystem/communications.dm`)
- **Compile**: `BUILD.cmd` — 0 errors, 0 warnings

## Update Protocol

- When new CM-PVE PRs are ported, update this file in the same change.
- If this file disagrees with PR description, this file wins for CM-PVE tracking.
- This file is the canonical source of truth for CM-PVE porting.
- For CM-PVE-HALO PRs, see [`HALO_PORT_STATE.md`](../halo/__docs/HALO_PORT_STATE.md).
