# EVIDENCE

## PR #1277 (Movie-like Xeno Castes) — PVE xeno balance — CONFIRMED 2026-06-08

### Read-only Discovery Summary

**Remote**: `cm-pve` → https://github.com/cmss13-devs/cmss13-pve
**PR diff**: `pr1277.diff` (локально в корне репозитория)

### Diff-Level Evidence (2026-06-08 Session)

**PR #1277 Movie-like Xeno Castes** — diff audit (9 файлов changed):

#### 1. `code/__DEFINES/xeno.dm` — 3 changes
| Change | BT Line | Status |
|--------|---------|--------|
| `XENO_HEALTH_RUNNER 230→100` | 243 | ✅ PRESENT |
| `XENO_HEALTH_DRONE 150` (new) | 244 | ✅ PRESENT |
| `XENO_HEALTH_SOLDIER 180` (new) | 245 | ✅ PRESENT |
| `XENO_SPEED_RAPTOR -0.9` (new) | 328 | ✅ PRESENT |

#### 2. `Abilities.dm` — 1 change
| Change | BT Line | Status |
|--------|---------|--------|
| gut cooldown `15 MINUTES` → `1 MINUTES` | 174 | ✅ PRESENT |

#### 3. `Crusher.dm` — 5 changes
| Change | BT Line | Status |
|--------|---------|--------|
| melee_damage `XENO_DAMAGE_TIER_5` → `TIER_6` | 5-6 | ✅ PRESENT |
| max_health `XENO_HEALTH_IMMORTAL` → `XENO_HEALTH_QUEEN` | 8 | ✅ PRESENT |
| armor_deflection `XENO_ARMOR_TIER_3` → `TIER_5` | 12 | ✅ PRESENT |
| `acid_blood_damage = 50` | 45 | ✅ PRESENT |
| `acid_blood_spatter = TRUE` | 46 | ✅ PRESENT |

#### 4. `Drone.dm` — 6 changes
| Change | BT Line | Status |
|--------|---------|--------|
| melee_damage_lower `XENO_DAMAGE_TIER_1` → `TIER_3` | 4 | ✅ PRESENT |
| melee_damage_upper `XENO_DAMAGE_TIER_2` → `TIER_4` | 5 | ✅ PRESENT |
| melee_vehicle_damage `XENO_DAMAGE_TIER_2` → `TIER_3` | 6 | ✅ PRESENT |
| max_health `180` → `XENO_HEALTH_DRONE` | 7 | ✅ PRESENT |
| explosion_resist `XENO_NO_EXPLOSIVE_ARMOR` → `TIER_2` | 10 | ✅ PRESENT |
| armor_deflection `XENO_NO_ARMOR` → `XENO_ARMOR_TIER_2` | 11 | ✅ PRESENT |
| acid_blood_damage `25` → `40` | 80 | ✅ PRESENT |

#### 5. `Facehugger.dm` — 1 change
| Change | BT Line | Status |
|--------|---------|--------|
| acid_blood_damage `5` → `15` | 36 | ✅ PRESENT |

#### 6. `Lurker.dm` — 7 changes
| Change | BT Line | Status |
|--------|---------|--------|
| melee_damage `XENO_DAMAGE_TIER_4` → `TIER_5` | 5-6 | ✅ PRESENT |
| max_health `XENO_HEALTH_TIER_5` → `XENO_HEALTH_DRONE` | 8 | ✅ PRESENT |
| explosion_resist `XENO_EXPLOSIVE_ARMOR_TIER_2` → `TIER_4` | 11 | ✅ PRESENT |
| armor_deflection `XENO_NO_ARMOR` → `XENO_ARMOR_TIER_1` | 12 | ✅ PRESENT |
| evasion `XENO_EVASION_NONE` → `MEDIUM` | 13 | ✅ PRESENT |
| `acid_blood_damage = 35` | 60 | ✅ PRESENT |

#### 7. `Queen.dm` — 12 changes
| Change | BT Line | Status |
|--------|---------|--------|
| melee_damage_lower `XENO_DAMAGE_TIER_5` → `TIER_7` | 9 | ✅ PRESENT |
| melee_damage_upper `XENO_DAMAGE_TIER_7` → `TIER_9` | 10 | ✅ PRESENT |
| armor_deflection `XENO_ARMOR_TIER_4` → `TIER_5` | 16 | ✅ PRESENT |
| `acid_blood_spatter = TRUE` | 277 | ✅ PRESENT |
| screech → `screech/ai` in base_actions | 315 | ✅ PRESENT |
| screech → `screech/ai` in mobile_aged_abilities | 359 | ✅ PRESENT |
| `ai_range = 24` | 369 | ✅ PRESENT |
| `forced_retarget_time = (3 SECONDS)` | 370 | ✅ PRESENT |
| Queen roar in `Initialize()` (playsound + to_chat) | 451-457 | ✅ PRESENT |
| `do_after(src, 30, ...)` for gut | 806 | ✅ PRESENT |
| `/datum/action/xeno_action/onclick/screech/ai` datum | 1010-1018 | ✅ PRESENT |
| `/datum/action/xeno_action/activable/xeno_spit/queen_macro/ai` datum | 1020-1028 | ✅ PRESENT |

#### 8. `Runner.dm` — 6 changes
| Change | BT Line | Status |
|--------|---------|--------|
| melee_damage_lower `XENO_DAMAGE_TIER_1` → `TIER_2` | 5 | ✅ PRESENT |
| melee_damage_upper `XENO_DAMAGE_TIER_2` → `TIER_3` | 6 | ✅ PRESENT |
| explosion_resist `XENO_EXPLOSIVE_ARMOR_TIER_1` → `TIER_2` | 10 | ✅ PRESENT |
| armor_deflection `XENO_NO_ARMOR` → `XENO_ARMOR_TIER_1` | 11 | ✅ PRESENT |
| `acid_blood_damage = 30` | 52 | ✅ PRESENT |
| acider `acid_blood_spatter = TRUE` | 175 | ✅ PRESENT |

#### 9. `Soldier.dm` — 8 changes
| Change | BT Line | Status |
|--------|---------|--------|
| melee_damage_lower `XENO_DAMAGE_TIER_3` → `TIER_4` | 4 | ✅ PRESENT |
| melee_damage_upper `XENO_DAMAGE_TIER_4` → `TIER_5` | 5 | ✅ PRESENT |
| max_health `XENO_HEALTH_RUNNER` → `XENO_HEALTH_SOLDIER` | 7 | ✅ PRESENT |
| explosion_resist `XENO_EXPLOSIVE_ARMOR_TIER_1` → `TIER_4` | 10 | ✅ PRESENT |
| armor_deflection `XENO_ARMOR_TIER_1` → `TIER_3` | 11 | ✅ PRESENT |
| speed `XENO_SPEED_HELLHOUND` → `XENO_SPEED_RAPTOR` | 13 | ✅ PRESENT |
| acid_blood_damage `35` → `50` | 40 | ✅ PRESENT |
| acid_blood_spatter `TRUE` → `FALSE` | 41 | ✅ PRESENT |

### Plan Fidelity Matrix (FINAL)

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | xeno.dm: health/speed defines | All 4 defines present in BT | ALREADY PRESENT |
| M2 | MUST | Abilities.dm: gut cooldown | `1 MINUTES` at line 174 | ALREADY PRESENT |
| M3 | MUST | Crusher.dm: damage/health/armor/acid | All 5 changes present | ALREADY PRESENT |
| M4 | MUST | Drone.dm: damage/health/armor/acid | All 7 changes present | ALREADY PRESENT |
| M5 | MUST | Facehugger.dm: acid_blood_damage | `15` at line 36 | ALREADY PRESENT |
| M6 | MUST | Lurker.dm: damage/health/armor/evasion/acid | All 6 changes present | ALREADY PRESENT |
| M7 | MUST | Queen.dm: damage/armor/acid/screech/ai/roar/gut | All 12 changes present | ALREADY PRESENT |
| M8 | MUST | Runner.dm: damage/armor/acid | All 6 changes present | ALREADY PRESENT |
| M9 | MUST | Soldier.dm: damage/health/armor/speed/acid | All 8 changes present | ALREADY PRESENT |
| C1 | CHECK | BUILD.cmd 0 errors | Not run — 0 implementation changes | SKIP |

### Files Changed
**Нет изменений** — PR #1277 полностью портирован в предыдущих HALO-волнах. Все 9 файлов уже содержат все изменения из diff.

### Verification
- **Diff audit**: `pr1277.diff` (2026-06-08) сверен построчно с BT codebase
- **9/9 файлов**: 100% coverage confirmed
- **Status**: COMPLETE — 0 implementation changes, PR #1277 ALREADY PRESENT
