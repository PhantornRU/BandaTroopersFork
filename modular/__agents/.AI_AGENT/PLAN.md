# PLAN

## Активная задача
Починить HALO species regression в ветке `another_halo_fixes_wave`: Sangheili/Unggoy снова должны спавниться своей расой, корректно экипироваться через HALO presets, иметь прямые subtype-спавны для админских create-human/create-object flow и не использовать человеческую красную кровь.

## Scope
- Подтвердить и устранить корень поломки в `species.name`/`set_species()`/HALO compat checks.
- Добавить прямые subtype path'ы `/mob/living/carbon/human/sangheili` и `/mob/living/carbon/human/unggoy`.
- Сохранить локализованные player-facing названия без повторного ломания canonical species IDs.
- Добавить regression tests на species spawn, blood color/type и HALO preset equip.
- Обновить PR #87 и допушить follow-up commit в текущую ветку.

## Out of scope
- Новая волна полной HALO name-localization migration по всем surface'ам.
- Несвязанные правки AI, транспорта, RTO или вендоров из уже открытого PR.

## Решение
- Вернуть `species.name` у HALO-рас к каноническим `SPECIES_*` ключам.
- Для локализованного UX использовать отдельный display-layer, а не canonical `name`.
- Добавить прямые human subtype initializers в upstream `human.dm` как минимальный glue.

## Acceptance criteria
- `set_species(SPECIES_SANGHEILI|SPECIES_UNGGOY)` снова находит правильные species datums.
- HALO covenant presets больше не создают голых людей вместо Sangheili/Unggoy.
- Прямой spawn `/mob/living/carbon/human/sangheili` и `/mob/living/carbon/human/unggoy` работает.
- У Sangheili/Unggoy после спавна не остается человеческий blood color/type.
- `git diff --check` и `BUILD.cmd` проходят.
