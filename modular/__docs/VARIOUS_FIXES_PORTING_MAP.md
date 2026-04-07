# various_fixes: карта портов и конфликтов после split

Назначение документа:
- зафиксировать, что именно осталось в rebuilt-ветке `various_fixes` после отделения map/faction пакетов в отдельный PR;
- не допустить повторного смешивания zombie/hAI/xeno-AI scope с картами и фракциями;
- дать короткую карту для повторного force-push и сопровождения обновленного `ss220club/BandaTroopers#49`.

## База пересборки

- source-of-truth для split: `ss220club/BandaTroopers#49`
- исходный общий head до разделения: `2fc7e58bbf637ca0d94ce9d3445ab276c59809c9`
- base rebuilt-ветки: `ss220club/master` на `80c26c912eddd9f3466840ee1b8ba6d18b5600ce`
- принцип пересборки:
  - сохранять authored non-merge commits для нужных пакетов;
  - не переносить merge commits;
  - смешанные интеграционные коммиты делить вручную по смыслу.

## Что входит в эту ветку

Ветка `various_fixes` после split содержит только remaining AI/zombie/general integration scope:

1. `cmss13-pve#1218`
   - большой weapons/equipment/support bundle
2. `cmss13-pve#1227`
   - follow-up fix поверх `#1218`
3. `cmss13-pve#1148`
   - zombie overhaul
4. `cmss13-pve#977`
   - Warrior Drone / xeno content-support
5. `cmss13-pve#1250`
   - ARES laptop prop
6. `cmss13-pve#1239`
   - Human AI preset-management follow-up поверх уже перенесенного zombie/hAI фундамента
7. `RU-CMSS13#75`
   - xeno AI actions follow-up
8. supporting TM/integration commits
   - только те, что реально нужны для remaining-scope ветки

## Что было вынесено в sibling-ветку

Из этой ветки сознательно убраны:
- `#1235`
- `#1128`
- `ss220club/BandaTroopers#20`
- `#1253`
- `#1251`
- `#1228`
- GroundSide stabilization

Все эти пакеты теперь живут в отдельной ветке:
- `various_fixes_maps_factions`
- PR title: `[TM ONLY] HARDCODE Maps and faction ports from CM-PVE`

## Ручные split-коммиты

### 1. Разделение `fbe6292953`

Remaining half перенесен отдельным commit:
- `f4f1e093e5` `Split integration: keep HumanAISpawner follow-up on remaining branch`

Что осталось здесь:
- `code/modules/mob/living/carbon/human/ai/ai_spawner/ai_spawner.dm`
- `tgui/packages/tgui/interfaces/HumanAISpawner.tsx`

Что вынесено в sibling-ветку:
- map/faction conflict resolution и related content integration

### 2. Разделение `e45cddff66`

Remaining half перенесен отдельным commit:
- `9065dbfc97` `Split integration: keep RU75 xeno AI cleanup on remaining branch`

Что осталось здесь:
- cleanup `GAME_MASTER_AI_XENOS`
- removal of invalid `PATHOGEN_CREATURE_*` entries для текущей hardcode-базы

Что вынесено в sibling-ветку:
- `wo.dm` DME include
- `marine_uniform.dm` leftover conflict-marker cleanup

### 3. Follow-up после merge commit `#65`

Отдельный commit:
- `de66520240` `Keep Human AI spawner expected-species follow-up on remaining branch`

Зачем нужен:
- merge `#65` менял `ai_spawner.dm` уже после `fbe629...`;
- без этого follow-up rebuilt-ветка теряла финальное expected-species состояние spawner'а.

## Важные supporting commits, которые оставлены здесь

- `d545cb8899` `Resolve TM merge conflicts with pending team merges`
- `36c3079dca` `Align TM conflict hunks with team-merge branches`
- `8a5358369b` `Normalize UPP RPG trait list formatting for TM auto-merge`
- `059e313fbd` `Fix HumanAISpawner preset typing for tgui-tsc`
- `9494291953` `Sync cyrillic radio keys with current channel map`

Это не отдельные external PR, но они нужны для консистентного remaining diff и CI/TM-совместимости.

## Основные hotspots этой ветки

Если remaining-ветку придется пересобрать заново, сначала проверять:

1. `code/modules/mob/living/carbon/human/ai/ai_spawner/ai_spawner.dm`
2. `tgui/packages/tgui/interfaces/HumanAISpawner.tsx`
3. `code/modules/admin/game_master/game_master.dm`
4. `code/modules/mob/living/carbon/human/ai/brain/*`
5. `code/modules/mob/living/carbon/human/species/zombie.dm`
6. `code/modules/mob/living/carbon/xenomorph/castes/*`

Причина:
- именно здесь пересекались zombie overhaul, hAI follow-ups, xeno-AI actions и post-port integration fixes.

## Практический итог split

Эта ветка предназначена для обновленного PR `#49`:
- title: `[TM ONLY] HARDCODE AI, zombie and integration fixes from CM-PVE`
- scope:
  - zombie systems
  - human AI follow-ups
  - xeno-AI / Warrior Drone support
  - ARES laptop
  - generic CI/TGUI/integration fixes, которые нужны именно этой части

Sibling PR:
- `[TM ONLY] HARDCODE Maps and faction ports from CM-PVE`
- ветка: `various_fixes_maps_factions`
