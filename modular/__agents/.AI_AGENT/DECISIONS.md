# DECISIONS

## D-001: `species.name` у HALO-рас возвращается к canonical `SPECIES_*`
- Решение: использовать `SPECIES_SANGHEILI` и `SPECIES_UNGGOY` как `name` в species datum.
- Почему: `setup_species()`, `set_species()`, AI/preset flow и часть совместимости завязаны на `species.name` как на ключ lookup/contract, а не как на display label.

## D-002: Локализация species-имен отделяется от canonical ID
- Решение: локализованные названия держать в explicit display-layer (`display_name`, `display_name_plural`) и использовать его только в player-facing сообщениях.
- Почему: предыдущая попытка локализовать raw `name` сломала species registration и HALO equip restrictions.

## D-003: Прямые subtype-спавны добавляются в upstream `human.dm`
- Решение: завести `/mob/living/carbon/human/sangheili` и `/mob/living/carbon/human/unggoy` по примеру `/mob/living/carbon/human/synthetic`.
- Почему: пользователь явно просит create-human/create-object surface для прямого спавна рас без обязательного gear preset.
