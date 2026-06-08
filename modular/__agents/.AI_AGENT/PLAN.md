# PLAN

## Active Task
Порт PR #129 (Faction splitting / HAI updates) из cmss13-devs/cmss13-pve-halo в BandaTroopers.

## Goal
Применить изменения из upstream PR #129 к BT-версиям файлов, сохраняя BT-specific content (русские названия, BT-specific presets, faction splitting, specops factions).

## Scope
45 файлов из upstream diff. BT уже имеет большинство из них в `modular/halo/` с расширенным функционалом.

## Strategy
1. **Defines** (`code/__DEFINES/mode.dm`): добавить `FACTION_LIST_COVENANT` если отсутствует
2. **Gear presets** (`modular/halo/.../gear_presets/Halo/`): 
   - sangheili.dm: добавить `faction_group`, helper-based loadout где ещё нет, stealth presets если отсутствуют
   - unggoy.dm: добавить `faction_group`, helper-based loadout, cloaked presets
   - insurgent.dm: добавить `ai_man` SPNKr preset
   - unsc_marines.dm: добавить `ai_sniper`, `ai_man` SPNKr presets
3. **Helper procs** (`_select_equipment.dm`): добавить `add_plasma_pistol_package`, `add_needler_package`, `add_plasma_rifle_package`, `add_cov_carbine_package` в BT modular
4. **Stealth armor** (NEW): создать `modular/halo/code/modules/clothing/.../sangheili_stealth_armor.dm` и `unggoy_stealth_armor.dm`
5. **AI action_datums** (`code/.../mg_nest.dm`, `sniper_nest.dm`): добавить HALO presets с SS220 EDIT
6. **AI spawner/squad/defense** (`code/.../ai/`): закомментировать non-HALO factions с SS220 EDIT
7. **AI brain** (`code/.../ai_brain_factions.dm`): добавить HALO faction brains, закомментировать non-HALO с SS220 EDIT
8. **colonialmarines.dme**: добавить include для новых stealth armor файлов

## Acceptance Criteria
- `BUILD.cmd` — 0 errors
- BT-specific content (русские названия, specops factions, BT presets) сохранён
- Все новые `code/` изменения с SS220 EDIT маркерами
- Новые файлы в `modular/halo/`
