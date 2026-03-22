# DECISIONS

## D-001: Weather holders перевести с guaranteed-start на low-probability start
- Решение: для `Mackay Station` и `ONI Digsite 451` использовать map-specific probability defines со значением `5`.
- Почему: при `min_time_between_checks = 0` возврат `TRUE` приводит к почти гарантированному старту сразу после cooldown; `5%` дает редкие, но не постоянные события.

## D-002: Placeholder ambience заменить существующим desert ambience asset
- Решение: для `dust/sand/rock` в `traxus_gamma_zone.dm` использовать `'sound/ambience/desert.ogg'`.
- Почему: в репозитории уже есть подходящий desert ambience, а snow/blizzard placeholders явно не соответствуют пустынной тематике.

## D-003: `new_varadero` turf dir values не менять без дополнительного подтверждения
- Решение: не применять bot-suggested dir fix в этом проходе.
- Почему: suggested diagonal constants конфликтуют с DMI metadata (`beachcorner*` имеют `dirs = 4`) и с уже существующим базовым `/turf/open/gm/coast` паттерном; слепая правка рискованна.
