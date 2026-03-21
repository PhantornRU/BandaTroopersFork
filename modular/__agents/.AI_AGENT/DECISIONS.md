# DECISIONS

## D-001: Порт выполнять по фактическому file diff upstream PR, а не через прямой cherry-pick веток
- Решение: переносить содержимое PR `#46`, `#96`, `#107` по реальным затронутым файлам и вручную интегрировать в локальные surfaces.
- Почему: upstream ветки содержат шумную историю, а задаче нужен чистый SS220/BandaTroopers port конкретных map/content changes.

## D-002: `Mackay Station (Shipmap)` привязать к локальным HALO platoons
- Решение: в `maps/mackay_station_shipmap.json` использовать `"/datum/squad/marine/halo/unsc/alpha"` и тот же путь в `allowed_platoons`.
- Почему: в BandaTroopers HALO shipmaps работают через platoon routing из `modular/squads`, а legacy marine squad paths ломают локальный runtime contract.

## D-003: Новый secure five-tile poddoor держать в `modular/halo/**`
- Решение: добавить secure subtype в `modular/halo/code/mixed/machinery/halo_unsc_poddoors.dm`, не меняя `code/game/machinery/doors/poddoor/two_tile.dm`.
- Почему: текущая база HALO five-tile poddoor уже живет в modular HALO-слое, и это лучше соответствует modular-first правилу репозитория.

## D-004: HALO shipmap rotation расширять через существующую SS220 surface
- Решение: добавить `mackay_station_shipmap` в `map_config/shipmaps.txt` внутри `SS220 EDIT` блока и расширить `SHIP_MAP_NAMES`.
- Почему: это минимальная интеграция, которая сохраняет локальные обходы `current_map` fallback и не смешивает HALO shipmaps с vanilla routing.

## D-005: Итоговый PR делать единым пакетом по трем upstream PR
- Решение: подготовить один SS220/BandaTroopers PR, который объединяет порт PR `#46`, `#96`, `#107` и явно перечисляет BandaTroopers-specific adaptations.
- Почему: пользователь запросил единый port PR, а изменения логически связаны общей HALO map-expansion темой.
