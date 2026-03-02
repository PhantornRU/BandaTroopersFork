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
