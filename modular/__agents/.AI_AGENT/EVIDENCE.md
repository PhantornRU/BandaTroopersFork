# EVIDENCE

## E-001: Исходное состояние
- Активная ветка на старте фикса: `another_halo_fixes_wave`.
- `git status --short --branch` показал чистое рабочее дерево.

## E-002: Подтвержденная первопричина
- `setup_species()` в `code/_globalvars/global_lists.dm` индексирует species datums по `all_species[S.name]`.
- `set_species()` в `code/modules/mob/living/carbon/human/human.dm` делает lookup через `GLOB.all_species[new_species]` и fallback'ом уходит в `Human`, если ключ не найден.
- HALO species datums были изменены на `name = "Сангхейли"` и `name = "Унггой"`, из-за чего lookup по `SPECIES_SANGHEILI`/`SPECIES_UNGGOY` перестал находить нужные datums.

## E-003: Fallout по спавну и экипировке
- HALO gear presets (`modular/halo/code/modules/gear_presets/Halo/{sangheili,unggoy}.dm`) по-прежнему вызывают `set_species(SPECIES_SANGHEILI|SPECIES_UNGGOY)`.
- После failed species lookup такие мобы падали в `Human`, а covenant clothing restrictions переставали пропускать HALO экипировку, что проявлялось как спавн голого человека.

## E-004: Create Human / direct subtype surface
- В `code/modules/mob/living/carbon/human/human.dm` уже существуют прямые subtype initializers вроде `/mob/living/carbon/human/synthetic/Initialize(mapload)`.
- Для Sangheili/Unggoy таких subtype path'ов не было, поэтому прямой human subtype spawn для админских create-object/create-human flow отсутствовал.

## E-005: Blood contract
- `sangheili.dm` и `unggoy.dm` уже задают `blood_color = BLOOD_COLOR_SANGHEILI|BLOOD_COLOR_UNGGOY` и в `handle_post_spawn()` переводят `blood_type` на `S*`.
- Симптом с красной человеческой кровью согласуется с fallback-спавном в `Human`, а не с отсутствием species-side blood definitions.

## E-006: Реализация фикса
- HALO species datums переведены обратно на canonical `name = SPECIES_SANGHEILI|SPECIES_UNGGOY`, а локализованные названия вынесены в explicit display-layer.
- В `human.dm` добавлены subtype initializers `/mob/living/carbon/human/sangheili` и `/mob/living/carbon/human/unggoy`.
- HALO compat/TTS/helper paths переведены на более безопасное использование `species.group` там, где это уместно для HALO species contract.

## E-007: Проверки
- `git diff --check`: passed.
- `BUILD.cmd`: ранее выполнил полноценный compile с `0 errors, 0 warnings`; повторный вызов после этого уже скипал `dm` как up-to-date.
- `tools/build/build dm-test --ci -DCIBUILDING -DANSICOLORS -Werror`: test DME compile passed (`colonialmarines.test.dmb - 0 errors, 0 warnings`), после чего wrapper не вернул финальный отчёт в разумное время из этой сессии.
- Попытка принудительного `tools/build/build clean dm ...` уткнулась в Windows file lock (`EBUSY` на `colonialmarines.dyn.rsc`), поэтому отдельный clean-rebuild именно последней однострочной правки не завершён через juke-clean path.
