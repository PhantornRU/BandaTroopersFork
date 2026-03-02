# various_fixes: карта портов и конфликтов

Назначение документа:
- зафиксировать, какие внешние PR уже портированы в ветку `various_fixes`;
- описать, какие конфликты уже были решены и почему именно так;
- дать будущему ИИ-агенту и разработчику короткую, но практичную схему повторного порта и перепроверки.

Важно:
- эта ветка делает переносы в хардкод, а не в `modular/`;
- summaries ниже частично выведены по локальным commit history и diff, а не переписаны дословно из PR-описаний;
- при спорных случаях использовать этот файл как карту, а GitHub PR как первоисточник.

## Базовые ссылки

Исходные PR, которые уже использовались при сборке ветки:

1. `cmss13-pve#1218`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1218
   - локальный ref: `pr-1218`
   - статус: портирован в хардкод
2. `cmss13-pve#1227`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1227
   - локальный ref: `pr-1227`
   - статус: портирован как follow-up fix поверх `#1218`
3. `cmss13-pve#1148`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1148
   - локальный ref: `pr-1148`
   - title: `zombies are a go or smth idfk`
   - статус: портирован в хардкод
4. `cmss13-pve#977`
   - https://github.com/cmss13-devs/cmss13-pve/pull/977
   - локальный ref: `pr-977`
   - статус: портирован в хардкод
   - практический summary: Warrior Drone / anti-air / дополнительные xeno-сущности и связанный код
5. `genessee-forgot-his-password-again/cmss13-pve#32`
   - https://github.com/genessee-forgot-his-password-again/cmss13-pve/pull/32
   - актуальный локальный ref: `genessee-32-head`
   - title: `ports cool xenos`
   - статус: использовался как вспомогательный downstream-референс для порта `#977`

Примечание по `genessee#32`:
- старый локальный ref `pr-genessee-32` был ненадежным и указывал не на полезный head PR;
- для повторной работы использовать именно `genessee-32-head` или заново fetch'ить `pull/32/head`.

## Что фактически заехало в ветку

### 1. Пакет `#1218` + `#1227`

Это большой content/equipment/weapons bundle. По локальной истории сюда вошли:
- specialist kit changes;
- SHARP/B18 related content;
- sentry tweaks;
- RMC pressure suit / armor related changes;
- PMC/RMC/FORECON related content;
- attachment/icon fixes;
- несколько follow-up исправлений поверх этого же набора.

Полезные локальные commit markers в ветке:
- `29def8976f` `Spec kit stuff`
- `bc757794e6` `RMC space-suit moved`
- `f47c31bbf5` `Attachments icon adjustments`
- `f62e42e5fb` `Forgor this bit of player-facing feedback on usage`

Практический вывод:
- `#1227` не надо рассматривать отдельно от `#1218`;
- если порт повторяется, сначала переносится весь пакет `#1218`, потом поверх обязательно перепроверяется `#1227`.

### 2. Пакет `#1148`

Это крупный zombie overhaul. По локальным commits и diff в ветку вошли:
- переработка zombie damage / dismember / decap behavior;
- zombie blood / fire / body handling;
- zombie AI, targetting, interaction with doors and obstacles;
- GM/admin tooling для zombie-related mechanics;
- связанная правка skills, factions, presets и supporting combat logic.

Наиболее конфликтный участок из этого пакета:
- `code/modules/mob/living/carbon/human/ai/brain/ai_brain_targeting.dm`

### 3. Пакет `#977` + downstream ref `genessee#32`

Это xeno-oriented bundle. По локальной истории в ветке присутствуют:
- `Warrior_Drone`;
- anti-air / AA связанный код;
- дополнительные xeno definitions, icons и support code.

Практический вывод:
- canonical source для идеи и базовой логики: `cmss13-pve#977`;
- useful downstream integration reference: `genessee#32`;
- если надо понять, как это уже присаживалось на более грязное downstream-дерево, смотреть `genessee-32-head`.

## Уже решенные конфликты

Ниже перечислены не все merge overlaps, а именно те, которые уже пришлось стабилизировать вручную ради TM и повторяемого сопровождения.

### 1. `code/game/objects/items/devices/radio/headset.dm`

Что исправлялось:
- `CLF_FREQ -> CANC_FREQ` для CANC headset;
- добавлены отсутствующие подтипы:
  - `/obj/item/device/radio/headset/almayer/marine/solardevils/canc/command`
  - `/obj/item/device/radio/headset/almayer/marine/solardevils/canc/medic`
  - `/obj/item/device/radio/headset/almayer/marine/solardevils/canc/sof`
- убрано лишнее расхождение по пустым строкам между блоками CANC и CIA.

Почему именно так:
- файл одновременно задевается и content-портами, и squad/headset-related TM;
- даже пустая строка в этом месте ломала auto-merge хунка.

### 2. `code/modules/mob/living/carbon/human/ai/brain/ai_brain_targeting.dm`

Что исправлялось:
- был убран дополнительный bypass:

```dm
if(iszombie(tied_human))
	return TRUE
```

Почему именно так:
- этот bypass мешал безболезненно стыковать zombie-port с TM-правками targetting/path check;
- итоговый выбор был в пользу совместимого pathing without special zombie fast-path в этом конкретном месте;
- если этот bypass понадобится вернуть, сначала заново проверить full TM stack.

### 3. `code/modules/projectiles/guns/specialist/launcher/rocket_launcher.dm`

Что исправлялось:
- в `/obj/item/weapon/gun/launcher/rocket/upp/set_bullet_traits()` оставлен только:

```dm
BULLET_TRAIT_ENTRY_ID("vehicles", /datum/element/bullet_trait_damage_boost, 70, GLOB.damage_boost_vehicles),
```

- строка `BULLET_TRAIT_ENTRY(/datum/element/bullet_trait_iff)` для UPP-варианта была убрана;
- отдельно сохранен trailing comma, потому что без него снова возникал content conflict.

Почему именно так:
- прямого конфликта с обновленным `PR #46` больше нет;
- но без formatting-fix последний хунк все еще конфликтовал в полном TM stack;
- источник остаточного конфликта был не `PR #46`, а пересечение с `tm-20`.

## Важные служебные коммиты ветки

Коммиты, которые не являются самостоятельным external PR-port, но критичны для сопровождения ветки:

1. `fb7b05ec1c`
   - `Resolve TM merge conflicts with pending team merges`
   - базовое разведение конфликтов с pending TM.
2. `16cb1b1847`
   - `Align TM conflict hunks with team-merge branches`
   - финальная подгонка конфликтных хунков под TM-ветки.
3. `f1bf2c7896`
   - `Normalize UPP RPG trait list formatting for TM auto-merge`
   - нужен для auto-merge полного TM stack.
   - важный факт: не нужен для пары `various_fixes <-> PR #46`, но нужен для полного стека TM.
4. `59780b0ccc`
   - `Merge branch 'master' into various_fixes`
   - подтянул свежий `master` в ветку; часть инфраструктурных/линейных правок пришла отсюда.

## Что уже проверено по TM

Проверки, которые уже были выполнены:

1. direct merge `tm-46 <- various_fixes`
   - проходит без конфликтов;
2. direct merge `tm-46-latest <- various_fixes~1`
   - тоже проходит без конфликтов;
3. full TM stack (`tm-20`, `tm-30`, `tm-42`, `tm-44`, `tm-46`) + `various_fixes`
   - проходит;
4. full TM stack + `various_fixes~1`
   - ломается в `code/modules/projectiles/guns/specialist/launcher/rocket_launcher.dm`.

Вывод:
- последний commit `f1bf2c7896` оставлять нужно;
- причина не в `PR #46`, а в совместимости с полным TM stack, прежде всего через `tm-20`.

## Какие проблемы уже решены

1. Запрошенные external PR перенесены в хардкод, а не в `modular/`.
2. Самые болезненные conflict hotspots для TM уже разрулены.
3. Зафиксировано, что `PR #46` больше не является прямым источником конфликта.
4. Зафиксировано, что `rocket_launcher.dm` остается чувствительной точкой полного TM stack.
5. Ненадежный downstream ref для `genessee#32` заменен на нормальный `genessee-32-head`.

## Hotspots для будущих правок

Если при следующем sync/port что-то снова ломается, сначала проверять:

1. `code/game/objects/items/devices/radio/headset.dm`
2. `code/modules/mob/living/carbon/human/ai/brain/ai_brain_targeting.dm`
3. `code/modules/projectiles/guns/specialist/launcher/rocket_launcher.dm`
4. `code/modules/gear_presets/_select_equipment.dm`
5. `code/game/jobs/job/marine/squads.dm`

## Как дальше портировать в эту ветку

Рекомендуемая процедура:

1. Обновить refs:

```powershell
git fetch upstream master
git fetch upstream pull/1218/head:pr-1218
git fetch upstream pull/1227/head:pr-1227
git fetch upstream pull/1148/head:pr-1148
git fetch upstream pull/977/head:pr-977
git fetch https://github.com/genessee-forgot-his-password-again/cmss13-pve pull/32/head:genessee-32-head
```

2. Собирать перенос в хардкод.
   - `modular/` использовать только как reference, не как конечную точку интеграции.

3. После ручного порта обязательно прогонять merge-проверку не только с одним PR/TM, а с полным стеком.

4. Минимальный practical test set:

```powershell
git merge --no-commit --no-ff tm-46
git merge --abort
```

и отдельно:

```powershell
# На временной ветке/временном worktree собрать стек tm-20 -> tm-30 -> tm-42 -> tm-44 -> tm-46
# затем поверх проверить merge various_fixes
```

5. Если конфликт снова в `rocket_launcher.dm`:
   - сначала сравнить UPP `set_bullet_traits()`;
   - проверить наличие/отсутствие `bullet_trait_iff`;
   - проверить trailing comma;
   - не удалять `f1bf2c7896`, пока не доказано, что full TM stack проходит без него.

6. Если конфликт снова в `ai_brain_targeting.dm`:
   - сначала проверить, не вернулся ли zombie-specific bypass;
   - затем сравнить `path_check()` с TM/base-version.

7. Если конфликт снова в `headset.dm`:
   - сначала проверить CANC subtype block;
   - затем пустые строки вокруг него;
   - затем соответствие `CANC_FREQ`.

## Что обновлять в этом документе после новых работ

После любого нового порта или TM-fix обновлять:
- список источников;
- конфликтные файлы;
- rationale по каждому ручному решению;
- вывод о том, нужен ли временный formatting/fix commit или его уже можно удалить.

## Новая пачка портов от 2026-03-02

Дополнительно в `various_fixes` были перенесены:

1. `cmss13-pve#1250`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1250
   - локальный ref: `pr-1250`
   - practical summary: RP/PvE portable ARES laptop prop
   - фактический перенос: `code/game/machinery/ARES/ARES_interface.dm`
2. `cmss13-pve#1239`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1239
   - локальный ref: `pr-1239`
   - practical summary: hAI preset-management follow-up поверх zombie/hAI branch
   - важное замечание:
     - переносить не как `master...pr-1239`;
     - переносить как diff поверх уже портированного `pr-1148`, то есть `pr-1148...pr-1239`;
     - иначе повторно затягивается уже перенесенная zombie-база и старый rust-g related baggage.
3. `cmss13-pve#1235`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1235
   - локальный ref: `pr-1235`
   - practical summary: Black Dragoons / mercenary weapons, gear, presets, attachments
4. `cmss13-pve#1128`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1128
   - локальный ref: `pr-1128`
   - practical summary: FIL/FAAMI faction package
   - важное замечание:
     - PR старый и требует актуализации;
     - shared файлы конфликтуют с `#1235` и текущим hardcode.
5. `cmss13-pve#1252`
   - https://github.com/cmss13-devs/cmss13-pve/pull/1252
   - локальный ref: `pr-1252`
   - practical summary: Hybrisa map/content/soundscape bundle
   - includes:
     - новая карта и map json;
     - props, structures, ambience/soundscape, clothing, presets и supporting code.

## Порядок порта для новой пачки

Практически безопасный порядок оказался таким:

1. `#1239` как follow-up поверх уже имеющегося `#1148`
2. `#1250` как small independent content PR
3. `#1235`
4. `#1128`
5. `#1252` последним, как большой map/content overlay

Почему именно так:
- `#1239` зависит от старого zombie/hAI фундамента и должен садиться до faction/content пакетов;
- `#1235` и `#1128` оба трогают armor/weapons/faction files и должны быть сведены между собой до карты;
- `#1252` трогает часть тех же shared content-файлов, но в основном является map/content bulk layer, поэтому его проще применять последним.

## Конфликты новой пачки

### 1. `#1239`

Что переносилось:
- `topic_events.dm` helper simplification:
  - `paradrop()`
  - `strip_all()`
  - `strip_weapons()`
- `ai_management_menu.dm`
  - импорт словаря пресетов;
- `ai_spawner.dm`
  - расширенный preset dictionary / click-intercept / outfit-spawn / species/equipment selection;
- `human_helpers.dm`
  - helper logic под новый spawner flow;
- `HumanAISpawner.tsx`
  - новый UI для пресетов.

Что сознательно НЕ переносилось из старой ветки:
- rust-g update baggage;
- старые бинарники/зависимости, идущие как incidental diff из древней базы ветки.

Причина:
- это не часть смысла `#1239` для `various_fixes`;
- перенос таких файлов создает лишний риск отката актуального upstream/Banda состояния.

### 2. `#1235` + `#1128`

Основные shared conflict hotspots:
- `code/__DEFINES/mode.dm`
- `code/modules/clothing/masks/gasmask.dm`
- `code/modules/mob/living/carbon/human/ai/action_datums/mg_nest.dm`
- `code/modules/mob/living/carbon/human/ai/action_datums/sniper_nest.dm`
- `code/modules/mob/living/carbon/human/ai/brain/ai_brain_factions.dm`
- `code/modules/projectiles/magazines/rifles.dm`

Принятые решения:

1. `mode.dm`
   - сохранить расширенный `FACTION_LIST_TWE` из текущей ветки;
   - отдельно добавить `FACTION_LIST_FIL`.
2. `gasmask.dm`
   - сохранить уже существующие RMC/royal_marine свойства;
   - добавить FIL gasmask отдельным блоком, без замены старого.
3. `mg_nest.dm`
   - оставить mercenary sentinel MG preset;
   - добавить FIL MG preset.
4. `sniper_nest.dm`
   - оставить mercenary sentinel marksman;
   - добавить mercenary infiltrator и FIL sniper.
5. `ai_brain_factions.dm`
   - для TWE сохранить текущую дружбу с PMC;
   - дополнительно добавить FIL в friendly list.
6. `magazines/rifles.dm`
   - сохранить `vulture/terror` из текущей ветки;
   - добавить FR F20 magazine family из FIL PR ниже по файлу.

Общее правило:
- в этих конфликтах почти всегда нужно объединять обе стороны, а не выбирать одну.

### 3. `#1252`

Единственный ручной текстовый конфликт после 3-way apply:
- `code/modules/clothing/under/marine_uniform.dm`

Суть:
- FIL uniform из `#1128`
- Hybrisa civilian/steward utility uniforms из `#1252`

Решение:
- сохранить оба блока;
- конфликт был purely positional, не semantic.

## Что помнить при следующем перепорте этой пачки

1. Для `#1239` смотреть diff относительно `pr-1148`, а не относительно `master`.
2. Для `#1128` заранее ожидать конфликты с `#1235`.
3. Для `#1252` не пугаться огромного числа binary/map files:
   - реальных текстовых конфликтов обычно мало;
   - bulk assets через 3-way apply садятся нормально.
4. После `#1252` отдельно перепроверять:
   - `marine_uniform.dm`
   - `headset.dm`
   - `helmet.dm`
   - `rifles.dm`
   - `smgs.dm`
   - `maps/lv759_hybrisa_prospera*.json`
   - `maps/map_files/LV759_Hybrisa_Prospera*`
