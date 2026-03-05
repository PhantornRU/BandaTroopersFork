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

## Пересборка истории порта от 2026-03-02

Пакет `#1239 + #1250 + #1235 + #1128 + #1252` был не просто перенесен как один squash-like набор, а затем
пересобран в историю, где сохранены authored commits исходных PR, а ручная интеграция вынесена отдельно.

Что сделано:
- сначала были replay'нуты authored non-merge commits из:
  - `pr-1148..pr-1239`
  - `cm-pve/master..pr-1250`
  - `cm-pve/master..pr-1235`
  - `cm-pve/master..pr-1128`
  - `cm-pve/master..pr-1252`
- затем поверх них был наложен отдельный интеграционный fix-коммит:
  - `fbe6292953` `Resolve port conflicts and restore integrated hardcode state`

Почему это важно:
- пользовательское требование для этой ветки: сохранять authored commits авторов исходных PR;
- все реальные conflict-resolution и hardcode-актуализации должны быть видны отдельно от исходной авторской истории;
- при будущих перепортах это место нужно воспринимать как canonical branch state, а не как случайный локальный rework.

Важное исключение:
- из follow-up ветки `#1239` сознательно не переносился `978ab70ce4` `Update rust_g 3.3.0 to 4.2.0 (#11327)`;
- причина: это incidental base-branch baggage, а не смысловой hAI follow-up для `various_fixes`.

Практический вывод:
- если эту пачку придется переносить заново, сначала нужно восстанавливать authored history;
- только после этого накладывать отдельный интеграционный fix-commit в духе `fbe6292953`.

## TGUI/CI фиксы от 2026-03-02

После пересборки истории локальный CI упал не на DM/map-части, а на `tgui`.

### 1. `0bc7f8b5c7`

- commit: `Fix HumanAISpawner preset typing for tgui-tsc`
- файл:
  - `tgui/packages/tgui/interfaces/HumanAISpawner.tsx`
- суть:
  - в `AIEquipmentPreset` добавлено поле `faction: string`
- причина:
  - UI уже использовал `chosenPreset.faction`, но локальный TS type этого поля не описывал;
  - backend реально отдает это поле через preset dictionary, поэтому fix типовой, а не behavioral.

### 2. `d4dadd3252`

- commit: `Format Orbit UI file for prettier CI`
- файл:
  - `tgui/packages/tgui/interfaces/Orbit/index.tsx`
- суть:
  - файл приведен к текущему `prettier`-формату
- причина:
  - CI падал на `tgui-prettier`;
  - commit не вносит смысловых изменений в поведение Orbit UI.

### 3. Актуальный статус локального CI после фиксов

Проверено локально:
- `check_filedirs.sh colonialmarines.dme` — проходит
- `validate_dme.py < colonialmarines.dme` — проходит
- `tools/build/build.bat --ci tgui-tsc` — проходит после `0bc7f8b5c7`
- `tools/build/build.bat --ci tgui-prettier` — проходит после `d4dadd3252`
- `tools/bootstrap/python -m mapmerge2.dmm_test` — проходит

Если похожий CI-fail повторится в будущем, сначала проверять:
- `tgui/packages/tgui/interfaces/HumanAISpawner.tsx`
- `tgui/packages/tgui/interfaces/Orbit/index.tsx`

## Порт `ss220club/BandaTroopers#20` от 2026-03-02

Источник:
- `ss220club/BandaTroopers#20`
- https://github.com/ss220club/BandaTroopers/pull/20
- локальные refs:
  - `pr-bt-20`
  - `tm-20`
- важный факт:
  - `pr-bt-20` и `tm-20` указывают на один и тот же head `bf2116ef37`

### Что именно перенесено

PR добавляет CANC Dogwar пакет в hardcode:
- новую фракцию `FACTION_CANC_DOGWAR`;
- paygrades, skills и faction datum;
- gear presets `canc_dogwar`;
- human AI presets и squad presets для CANC Dogwar;
- CANC radio/encryption/headset support;
- CANC PF-199 disposable AT launcher;
- связанные icon/dmi изменения;
- DME include entries.

### Авторские коммиты PR и их локальные replay-коммиты

В `various_fixes` перенесены authored non-merge commits PR:

1. original `48d679d005` `initial`
   - local replay: `621b240f41`
2. original `e45757c663` `renaming rebels`
   - local replay: `e1694e63a4`
3. original `d2b76f3af9` `fixes`
   - local replay: `1080aa19ad`
4. original `12752fbb45` `makes pf199 weaker`
   - local replay: `4e56796a5a`
5. original `bf2116ef37` `changes for AT gear presets`
   - local replay: `6beea3388a`

### Отдельный интеграционный fix-коммит

- `6cd6d898e1` `Fix PR20 integration conflicts and tgui radio styles`

Что исправляет этот commit:
- удаляет невалидный duplicate alias-block `RADIO_CHANNEL_CANC = ...` из `code/controllers/subsystem/communications.dm`
  - причина: в `code/__DEFINES/radio.dm` определены `RADIO_CHANNEL_CANC_GEN/_CMD/_MED/_ENGI/_SOF`, но не `RADIO_CHANNEL_CANC`;
  - оставленный как есть блок давал бы несогласованный branch state и лишний риск compile/runtime проблем;
- привязывает `code/modules/mob/living/carbon/human/ai/squad_spawner/squad_canc.dm` к `FACTION_CANC_DOGWAR`, а не к сырой строке;
- закрывает SCSS-регрессию после merge-resolution в:
  - `tgui/packages/tgui-panel/styles/goon/chat-dark.scss`
  - `tgui/packages/tgui-panel/styles/goon/chat-light.scss`
  - причина: `.cancradio` оказался вложен в незакрытый `.opformerc`, из-за чего валился `tgui-prettier`.

### Какие конфликты пришлось сводить вручную при переносе

Первый authored commit `48d679d005` конфликтовал в:

1. `code/__DEFINES/mode.dm`
   - решение:
     - сохранить текущие веточные additions (`FIL`, `NSPA`, SS220 role-list edits);
     - дополнительно добавить `FACTION_CANC_DOGWAR` в `FACTION_LIST_HUMANOID`;
     - сохранить `FACTION_LIST_CANC = list(FACTION_CANC, FACTION_CANC_DOGWAR)`.
2. `code/controllers/subsystem/communications.dm`
   - решение:
     - сохранить текущие FIL/SS220 radio changes;
     - добавить CANC frequencies, channels, spans и `CANC_FREQS`;
     - не возвращать старый `CLF_MED`.
3. `tgui/packages/tgui-panel/styles/goon/chat-dark.scss`
4. `tgui/packages/tgui-panel/styles/goon/chat-light.scss`
   - решение:
     - сохранить текущие squad-color overrides;
     - добавить отдельный `.cancradio`;
     - не затирать существующий `.opformerc`.

Практический вывод:
- этот PR нужно переносить не как "выбрать theirs", а как additive merge поверх уже существующих FIL/TM/tgui правок;
- самый рискованный файл здесь не только `rocket_launcher.dm`, но и `communications.dm`, потому что там легко оставить невалидный alias state.

### Что проверено после порта

Локально проверено на итоговом состоянии с authored commits + `6cd6d898e1`:
- `git diff --check` — проходит
- `bash tools/ci/check_filedirs.sh colonialmarines.dme` — проходит
- `validate_dme.py < colonialmarines.dme` — проходит
- `tools/build/build.bat --ci lint tgui-test` — проходит

Если этот порт придется повторять заново:
1. fetch'ить именно `pull/20/head` в отдельный ref;
2. replay'ить authored non-merge commits;
3. затем отдельно повторять интеграционный fix по `communications.dm`, `squad_canc.dm` и `chat-*.scss`;
4. после этого обязательно прогонять `lint tgui-test`, потому что SCSS ошибка проявилась только на CI-подобном прогоне.

## Пакет портов от 2026-03-04: `#1253`, `#1251`, `#1228`, `RU-CMSS13#75`

Источники:
- `cmss13-devs/cmss13-pve#1253`
- `cmss13-devs/cmss13-pve#1251`
- `cmss13-devs/cmss13-pve#1228`
- `RU-CMSS13/cmss13-pve#75`

Локальные refs:
- `pr-1253`
- `pr-1251`
- `pr-1228`
- `ru-master`
- `pr-ru-75`

### `#1253`

Что перенесено:
- новый shipmap `SSV Rover Tethered`;
- `maps/rover_tethered.json`;
- `maps/map_files/rover_tethered/rover_tethered.dmm`;
- запись в `map_config/shipmaps.txt`.

Локальный replay-коммит:
- original `d10c2d3f01` `Initial commit`
  - local replay: `7df2dfe4c9`

Конфликты:
- существенных конфликтов не было;
- `shipmaps.txt` смержился автоматически.

### `#1251`

Что перенесено:
- `SSV Laituri` как UPP shipmap;
- `dropship_korobka`;
- расширение UPP platoon/squad/job/loadout набора;
- UPP radio/encryption/rappel изменения;
- сопутствующие preset/icon/map изменения.

Локальные replay-коммиты:
1. original `75d5a0f8fe` `first pass`
   - local replay: `b49e2d4427`
2. original `f539b007d4` `fixed some phone stuff & other tidbits`
   - local replay: `768b3efe9e`
3. original `6860af4b5e` `some fixes - rto lockers, para PKP and armor, new beret, 2 rifles now`
   - local replay: `b9d85c8fe6`
4. original `8cf499673d` `pandora fixes`
   - local replay: `4dcb9520da`
5. original `52accfbd64` `fixed some job/role defines. Fixed radio encryption key & recon radio using a prefix. Added a smidge of cool Nouns UPP lore to the beret desc. Swapped Type-88 crate to the regular version to avoid FF from flak rounds`
   - local replay: `1b2da06c99`
6. original `c6f69756ff` `specific UPP rappel button added`
   - local replay: `ca832f3dc1`
7. original `f417111648` `added amsel aka scythe's korobka shuttle`
   - local replay: `4ebc0fc28f`

Какие конфликты пришлось сводить:
- `code/game/gamemodes/colonialmarines/colonialmarines.dm`
  - сохранен SS220 font-fix интро;
  - добавлен отдельный intro-case для `SQUAD_SISSI`.
- `code/global.dm`
  - сохранены и `SSV Laituri`, и `USS Blue Ridge` в `SHIP_MAP_NAMES`.
- `code/__DEFINES/shuttles.dm`
  - сохранены `DROPSHIP_TORNADO_220/_LONG`;
  - добавлен `DROPSHIP_KOROBKA`.

Практический вывод:
- `#1251` конфликтует не по своей бизнес-логике, а в местах, где ветка уже расширяла shipmaps/shuttles/intro text;
- повторный порт надо делать как additive merge, а не как blind cherry-pick.

### `#1228`

PR-title:
- `Overhaul PMC-12`

Что перенесено:
- PMC overhaul в hardcode;
- `Extended Armor Plates`;
- `whiteout` / `WO` faction datum и gear-presets;
- `WY commandos`;
- `working joe` / `wy_droid` species, emotes, sounds и presets;
- новые PMC/WY belts, pouches, webbings, armor parts, flamer/shotgun/weapon pieces;
- IASF uniforms и дополнительный faction clothing pack;
- сопутствующие карты/props/icons/sounds.

Локальные replay-коммиты:
1. original `d1a4b69c12` `test`
   - local replay: `44ee2fc480`
2. original `abd54f643d` `loadout fixes`
   - local replay: `48ecf88c15`
3. original `2ebe32c311` `few more sprites`
   - local replay: `c8ea8e43d6`
4. original `f2e36c1a93` `Extended Armor Plates (#58)`
   - local replay: `5479575a60`
5. original `847e46d3aa` `post_main-brainch_merge`
   - local replay: `2644986f05`
6. original `15b689f71f` `armor plate fix`
   - local replay: `26b34b2f17`
7. original `affa65830a` `Transferring clothing and patches from PVP to PVE (#57)`
   - local replay: `fade24e3ba`
8. original `38e8c4d022` `remove oxy`
   - local replay: `9e9aba97ac`
9. original `c6460c61ef` `reverts various changes to pain/nutrition`
   - local replay: `9b4a818001`
10. original `238c88c7b5` `revert dam values`
   - local replay: `e3e9932048`
11. original `a8428501e9` `revert SG drain`
   - local replay: `98b14d3828`
12. original `893e3bb7c0` `update from RU PVE`
   - local replay: `6191f13ecf`

Важное исключение:
- не переносился original `978ab70ce4` `Update rust_g 3.3.0 to 4.2.0 (#11327)`;
- причина:
  - это incidental base-branch baggage;
  - смыслового отношения к PMC overhaul для `various_fixes` не имеет;
  - уже раньше такой же pattern сознательно пропускался при follow-up портах.

Какие конфликты пришлось сводить:
- `code/game/machinery/vending/vendor_types/squad_prep/squad_prep.dm`
  - PMC vendor сведен как hybrid:
    - сохранены новые WY/PMC armor-pads, webbings, backpacks и masks;
    - возвращены полезные веточные utility-опции (tech/TWE packs и часть belt/pouch вариантов).
- `code/game/objects/items/storage/belt.dm`
  - сохранены и новые `WY-TM892` holster rigs, и веточный `pa76` fill preset.
- `code/modules/clothing/head/helmet.dm`
  - сохранены SS220/веточные visor hooks;
  - взяты новые `pmc_helmet_enclosed` / `rmc_helmet_enclosed`.
- `code/modules/clothing/suits/marine_armor/ert.dm`
  - объединены веточные modular PMC armors и PR-шный `M5X Apesuit`.
- `code/modules/clothing/under/ties.dm`
  - объединены PMC armor pads, новые WY webbings и кастомные hold-правила ветки.
- `code/modules/gear_presets/pmc.dm`
  - оставлены branch-specific synth slots/headset'ы;
  - поверх добавлены updated PMC masks/gloves/shoes.
- `code/modules/projectiles/guns/rifles.dm`
  - сохранены веточные `m41a/corporate`, `m20a/merc`;
  - добавлены `whiteout`/WY follow-up definitions.
- `maps/map_files/USCSS_Obsidian_Falk/USCSS_Obsidian_Falk.dmm`
  - вручную снят `merge_conflict_marker`;
  - на конфликтных heavy-weapon locker tiles сохранено новое PMC smartgun gear-state без возврата старых дублей.
- `code/modules/clothing/under/marine_uniform.dm`
  - объединены веточные FIL/utility uniforms и PR-шные IASF uniforms.

Практический вывод:
- `#1228` нельзя переносить как один "огромный theirs";
- у него два слоя:
  - authored PMC overhaul/history;
  - финальный downstream-sized commit `893e3bb7c0`, который нужно принимать только после того, как earlier authored layer уже лег поверх ветки.

### `RU-CMSS13#75`

PR-title:
- `XAI_actions_xenos`

Важное замечание по base:
- сравнивать `pr-ru-75` нужно именно с `ru-master`, а не с `cm-pve/master` и не с `pr-1228`;
- сам PR маленький и состоит только из двух authored commits.

Локальные replay-коммиты:
1. original `ae83a82728` `init`
   - local replay: `9f71b07b82`
2. original `0fe62e76f0` `hm`
   - local replay: `56bdc2e23b`

Что перенесено:
- follow-up правки xeno AI actions для:
  - `Defender`
  - `Praetorian`
  - `Queen`
  - `Ravager`
  - `Sentinel`
  - `Spitter`
- расширение `GAME_MASTER_AI_XENOS`.

Какие конфликты пришлось сводить:
- `code/modules/admin/game_master/game_master.dm`
  - branch already содержал `WARRIOR_DRONE` и arachnids;
  - PR добавлял `Defender/Carrier/Predalien/King`;
  - итоговое решение: объединить реальный доступный список каст.
- `Queen/Sentinel/Spitter`
  - взят более безопасный порядок short-circuit check'ов из PR;
  - для `Spitter` взята исправленная сигнатура `check_for_obstacles_projectile(..., datum/ammo/ammo_datum)`, потому что веточная версия смешивала `projectile` и `ammo datum`.

### Отдельный интеграционный fix-коммит поверх authored history

- `e45cddff66` `Fix PR1228 and RU75 integration regressions`

Что исправляет:
- добавляет и правильно упорядочивает `#include "code\\datums\\factions\\wo.dm"` в `colonialmarines.dme`;
- убирает оставшийся conflict-marker мусор в `code/modules/clothing/under/marine_uniform.dm`;
- выкидывает из `GAME_MASTER_AI_XENOS` несуществующие в этой базе `PATHOGEN_CREATURE_*`, которые были валидны в PR-source, но отсутствуют в текущем hardcode.

### Что проверено после порта

Локально проверено:
- `validate_dme.py` — проходит
- `tools/build/build.bat --ci dm` — проходит
- `tools/build/build.bat --ci lint` — проходит
- `tools/build/build.bat --ci dm lint tgui-test`:
  - изначально падал на интеграционных дырках, которые закрыты в `e45cddff66`;
  - после фикса отдельные `dm` и `lint` цели проходят

Оставшийся warning:
- `code/modules/mob/living/carbon/human/ai/ai_management_menu.dm:224`
- `unused_var: the_beast`
- warning pre-existing и не относится к текущему пакету портов.

## 2026-03-05 GroundSide stabilization (RU-CMSS13)

Source scope:
- RU GroundSide source of truth: `https://github.com/RU-CMSS13/cmss13-pve/tree/master`
- Reference examples from request: `https://github.com/RU-CMSS13/cmss13-pve/pull/56`, `https://github.com/RU-CMSS13/cmss13-pve/pull/20`, `https://github.com/RU-CMSS13/cmss13-pve/pull/68`
- Existing CM PVE refs used for reconciliation: `pr-1252`, `pr-1251`, `pr-1228`, `pr-1253`

GroundSide inventory/reconcile outcome:
- Missing rotation GroundSide maps (vs `ru-master`) were imported:
  - `maps/lv671.json`
  - `maps/oil_depot.json`
  - `maps/derelict_almayer_infested.json`
  - `maps/map_files/lv671/lv671.dmm`
  - `maps/map_files/oil_depot/oil_depot.dmm`
  - `maps/map_files/derelict_almayer_infested/derelict_almayer_infested.dmm`
- Existing regressed maps were reconciled/fixed:
  - `maps/map_files/BMG290_Otogi_Egress_Point/BMG290_Otogi_Egress_Point.dmm`
  - `maps/map_files/kleschers_research_site/BigBlue.dmm`
  - `maps/map_files/USCSS_Onyx_Karain/USCSS_Onyx_Karain.dmm`
  - `maps/map_files/LV759_Hybrisa_Prospera/LV759_Hybrisa_Prospera.dmm`
  - `maps/map_files/LV759_Hybrisa_Prospera_Fixed/LV759_Hybrisa_Prospera_repaired.dmm`

Build/compat fixes required by map sources:
- `code/game/machinery/telecomms/presets.dm`: `switch(user.faction)` changed from list-macro case to explicit constants (`FACTION_CANC`, `FACTION_CANC_DOGWAR`) to remove OD0500.
- Added compatibility types for canonical source paths:
  - `code/game/objects/items/storage/backpack.dm`: `/obj/item/storage/backpack/commando`
  - `code/modules/clothing/head/head.dm`: `/obj/item/clothing/head/beret/royal_marine`
  - `code/modules/projectiles/magazines/rifles.dm`: `/obj/item/ammo_magazine/rifle/nsg23/extended`
- Minor compile cleanup:
  - `code/modules/mob/living/carbon/human/ai/ai_management_menu.dm` static preset dictionary import path (`the_beast` warning removed)

Maplint-specific GroundSide sanitation:
- Converted imported maps to TGM via `mapmerge2.dmm` writer.
- Applied canonical and local UpdatePaths scripts:
  - `tools/UpdatePaths/Scripts/6656-no-more-open-turf-edits.txt`
  - `tools/UpdatePaths/Scripts/797-plane-bans.txt`
  - `tools/UpdatePaths/Scripts/6656-no-bad-dirs.txt`
  - `tools/UpdatePaths/Scripts/ss220-groundside-derelict-almayer-infested-maplint.txt`
  - `tools/UpdatePaths/Scripts/ss220-groundside-lv671-oildepot-maplint.txt`
- Added maplint-compat subtype support (minimal integration in existing turf files):
  - `code/game/turfs/floor_types.dm`
  - `code/game/turfs/strata.dm`
  - `code/game/turfs/open.dm`
  - `code/game/turfs/floors/desert.dm`

DMI overflow split (required by CI):
- New split files:
  - `icons/mob/humans/onmob/clothing/uniforms/uniforms_by_faction/groundside_military.dmi`
  - `icons/mob/humans/onmob/clothing/uniforms/uniforms_by_faction/groundside_wy_misc.dmi`
  - `icons/mob/humans/onmob/inhands/items/groundside_support_lefthand.dmi`
  - `icons/mob/humans/onmob/inhands/items/groundside_support_righthand.dmi`
- Repointed type groups to split files through `item_icons`:
  - GroundSide/CANC/UPP/FIL/WY uniforms (marine/veteran + liaison/officer subsets)
  - Bayonets, cameras, defibs, surgical/syringe cases, megaphone, UPP multitool/flare/binoculars, stethoscope, UPP handset
- Base atlases were reduced under limit:
  - `icons/mob/humans/onmob/uniform_0.dmi`
  - `icons/mob/humans/onmob/items_lefthand_0.dmi`
  - `icons/mob/humans/onmob/items_righthand_0.dmi`

Scope guard:
- No new shipmap content was ported from RU in this pass.
- Ship-side DMM changes were applied only as compile/maplint stabilization (`USCSS_Onyx_Karain` regression fix).

Validation executed:
- `git diff --check` passed.
- `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed.
- `tools/build/build.bat --ci lint tgui-test` passed.
- `tools/bootstrap/python -m dmi.test` passed.
- `tools/bootstrap/python -c "import sys, runpy; sys.path.insert(0, '.'); runpy.run_module('tools.maplint.source', run_name='__main__')" --github` passed.
- `tools/bootstrap/python -m mapmerge2.dmm_test` passed.
- `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE` passed.
- `tools/build/build.bat --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA` passed.
