# various_fixes_maps_factions: карта портов и конфликтов

Назначение документа:
- зафиксировать, что именно осталось в ветке `various_fixes_maps_factions` после разделения бывшего `various_fixes`;
- дать короткую карту для повторного ребейза, force-push и сопровождения отдельного PR по картам и фракциям;
- не смешивать этот scope с zombie/hAI/xeno-AI веткой.

## База пересборки

- source-of-truth для split: `ss220club/BandaTroopers#49`
- исходный head до разделения: `2fc7e58bbf637ca0d94ce9d3445ab276c59809c9`
- base для обеих rebuilt-веток: `ss220club/master` на `80c26c912eddd9f3466840ee1b8ba6d18b5600ce`
- принцип пересборки:
  - authored non-merge commits сохраняются где это возможно;
  - merge commits и doc/task-state шум не переносятся;
  - смешанные интеграционные коммиты режутся вручную по смысловым пакетам.

## Что входит в эту ветку

Ветка `various_fixes_maps_factions` содержит только map/faction/content bundle и supporting integration:

1. `cmss13-pve#1235`
   - Black Dragoons / mercenary weapon-content пакет
2. `cmss13-pve#1128`
   - FIL / бывший FAAMI faction package
3. `ss220club/BandaTroopers#20`
   - CANC Dogwar package
   - плюс отдельный интеграционный fix `6cd6d898e1`
4. `cmss13-pve#1253`
   - `SSV Rover Tethered`
5. `cmss13-pve#1251`
   - `SSV Laituri`, UPP recon, `Korobka`
6. `cmss13-pve#1228`
   - PMC / Whiteout / WO / Working Joe / W-Y droids bundle
7. GroundSide stabilization
   - missing RU GroundSide maps
   - map regressions fix
   - maplint / DMI overflow / compat cleanup

## Что сознательно НЕ входит

Эта ветка не должна содержать:
- `#1218`
- `#1227`
- `#1148`
- `#977`
- `#1250`
- `#1239`
- `RU-CMSS13#75`
- чисто TM-oriented или `.AI_AGENT`-only commits без продуктового смысла

Эти изменения живут в sibling-ветке `various_fixes`.

## Ручные split-коммиты

### 1. Разделение `fbe6292953`

Map/faction half перенесен отдельным commit:
- `b86a5bbb3c` `Split integration: keep map and faction conflict resolution on maps branch`

Смысл:
- сохранить map/faction integration fixes из общего post-port cleanup;
- не забирать `HumanAISpawner` и прочий hAI-only follow-up.

### 2. Разделение `e45cddff66`

Map/faction half перенесен отдельным commit:
- `900fd58f77` `Split integration: keep PR1228 map/faction fixes on maps branch`

Смысл:
- добавить `#include "code\\datums\\factions\\wo.dm"` в `colonialmarines.dme`;
- убрать оставшийся conflict-marker из `code/modules/clothing/under/marine_uniform.dm`;
- не переносить RU75/xeno-AI cleanup из `game_master.dm`.

## GroundSide пакет в этой ветке

Практически важные replay/fix commits после `#1228`:
- `b462110c10` `fix(build): resolve GroundSide compile blockers and compat paths`
- `85aae84f30` `fix(maps): repair GroundSide merge regressions in existing DMMs`
- `f65a5f945b` `feat(maps): replay missing RU GroundSide map packs`
- `9b39772c86` `fix(assets): split GroundSide onmob atlases and repoint icon routes`
- `6e34314a36` `Z maps fix`
- `a99fb07145` `gun fixes`
- `39c1b83ee8` `Fix ported unit test and lint regressions`
- `b06da191e7` `linter fix`
- `e5bd4d1df6` `подтягиваем недостаток`
- `6f48649864` `Fix парсера`

Что было сознательно пропущено:
- `0e26ab835e` doc-only summary старой общей ветки
- `d4c21ddecc`, `5d28bb5474`, `2a0b083092` `.AI_AGENT`-state noise
- `c9ce0fd54c` старый общий doc/task-state finalize
- пустые no-op commits без tree diff (`87e5aba5a4`, `8744e94a9c`, `d156e2ac22`)
- weekly workflow noise (`47c07afc94`, `705b38a3e2`)

## Основные conflict hotspots

Если ветку придется пересобирать заново, сначала проверять:

1. `code/modules/cm_marines/equipment/maps.dm`
   - итоговое состояние должно совмещать JSON `map_item_type` flow и GroundSide lookup fallback/logging
2. `map_config/maps.txt`
   - должны одновременно жить HALO ground rotation и GroundSide rotation entries
3. `code/modules/clothing/under/marine_uniform.dm`
   - здесь пересекались FIL, PMC/WO и GroundSide atlas split
4. `colonialmarines.dme`
   - порядок include'ов критичен для `wo.dm`, `LV671.dm` и новых define/include блоков
5. `code/controllers/subsystem/communications.dm`
   - CANC integration нельзя сводить blind-theirs, иначе легко оставить невалидный alias-state

## Практический итог split

Эта ветка предназначена для отдельного PR:
- title: `[TM ONLY] HARDCODE Maps and faction ports from CM-PVE`
- scope:
  - faction bundles
  - shipmaps / ground maps
  - GroundSide stabilization
  - supporting integration fixes только для этого пакета

Sibling PR:
- `[TM ONLY] HARDCODE AI, zombie and integration fixes from CM-PVE`
- ветка: `various_fixes`
