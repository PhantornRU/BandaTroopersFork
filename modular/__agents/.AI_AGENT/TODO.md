# TODO

## PR #1277 — Movie-like Xeno Castes (PVE xeno balance)

## Contract Table

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | code/__DEFINES/xeno.dm: XENO_HEALTH_RUNNER 230→100, XENO_HEALTH_DRONE 150, XENO_HEALTH_SOLDIER 180, XENO_SPEED_RAPTOR -0.9 | BT already has all 4 defines at lines 243-245, 328 | ALREADY PRESENT |
| M2 | MUST | Abilities.dm: gut cooldown 15 MINUTES → 1 MINUTES | BT already has `xeno_cooldown = 1 MINUTES` at line 174 | ALREADY PRESENT |
| M3 | MUST | Crusher.dm: melee_damage XENO_DAMAGE_TIER_5→6, max_health XENO_HEALTH_IMMORTAL→QUEEN, armor XENO_ARMOR_TIER_3→5, acid_blood_damage=50, acid_blood_spatter=TRUE | BT already has all changes at lines 5-8, 12, 45-46 | ALREADY PRESENT |
| M4 | MUST | Drone.dm: melee_damage XENO_DAMAGE_TIER_1/2→3/4, max_health 180→XENO_HEALTH_DRONE, explosion_resist XENO_NO_EXPLOSIVE_ARMOR→TIER_2, armor XENO_NO_ARMOR→TIER_2, acid_blood_damage 25→40 | BT already has all changes at lines 4-11, 80 | ALREADY PRESENT |
| M5 | MUST | Facehugger.dm: acid_blood_damage 5→15 | BT already has `acid_blood_damage = 15` at line 36 | ALREADY PRESENT |
| M6 | MUST | Lurker.dm: melee_damage XENO_DAMAGE_TIER_4→5, max_health XENO_HEALTH_TIER_5→DRONE, explosion_resist TIER_2→4, armor XENO_NO_ARMOR→TIER_1, evasion NONE→MEDIUM, acid_blood_damage=35 | BT already has all changes at lines 5-13, 60 | ALREADY PRESENT |
| M7 | MUST | Queen.dm: melee_damage XENO_DAMAGE_TIER_5/7→7/9, armor XENO_ARMOR_TIER_4→5, acid_blood_spatter=TRUE, screech→screech/ai, ai_range=24, forced_retarget_time=3s, queen roar in Init, do_after 80→30, screech/ai datum, queen_macro/ai datum | BT already has all changes at lines 9-10, 16, 277-278, 315, 351, 359, 369-370, 433, 451-457, 806, 1010-1018, 1020-1028 | ALREADY PRESENT |
| M8 | MUST | Runner.dm: melee_damage XENO_DAMAGE_TIER_1/2→2/3, explosion_resist TIER_1→2, armor XENO_NO_ARMOR→TIER_1, acid_blood_damage=30, acider acid_blood_spatter=TRUE | BT already has all changes at lines 5-6, 10-11, 52, 174-175 | ALREADY PRESENT |
| M9 | MUST | Soldier.dm: melee_damage XENO_DAMAGE_TIER_3/4→4/5, max_health XENO_HEALTH_RUNNER→SOLDIER, explosion_resist TIER_1→4, armor TIER_1→3, speed HELLHOUND→RAPTOR, acid_blood_damage 35→50, acid_blood_spatter TRUE→FALSE | BT already has all changes at lines 4-13, 40-41 | ALREADY PRESENT |
| C1 | CHECK | BUILD.cmd 0 errors | Not run — 0 implementation changes needed | SKIP |

## Forbidden Substitutions
- Не перезаписывать BT-файлы upstream версиями

## Execution Order
1. ~~Read diff PR #1277~~ — DONE
2. ~~Read all target BT files~~ — DONE
3. ~~Compare changes line-by-line~~ — DONE
4. ~~M1-M9: All ALREADY PRESENT~~ — DONE
5. ~~EVIDENCE.md update~~ — DONE
