# EVIDENCE

## E-001: Актуальный HALO baseline
- `modular/halo/__docs/HALO_PORT_STATE.md` указывает pinned upstream commit `95a84ab9f59f9118e5543f664b2793e7a1841c55` от `2026-03-11`.
- Для этой задачи он использован как канонический baseline при сравнении с upstream HALO PR.

## E-002: Upstream PR scope подтвержден отдельно по каждому порту
- PR `#46`: `Karmac Map Pack #1 [OWP Mackay Station + ONI Digsite 451]`.
- PR `#96`: `Pelican't`.
- PR `#107`: `Halo Map Collection`.
- Фактический scope проверялся по file list и diff, а не по названию ветки.

## E-003: В локальный порт импортированы payload-файлы карт и ассетов
- Добавлены карты: `Mackay Station`, `Mackay Station (Shipmap)`, `ONI Digsite 451`, `Traxus Gamma Zone`.
- Добавлены shuttle DMM: Mackay trams/elevators, Digsite elevator, Pelican dropship.
- Добавлены соответствующие DM-файлы weather/areas/turfs/props/shuttles и icon payload для ported maps.

## E-004: Локальные BandaTroopers-адаптации внесены поверх upstream payload
- `maps/mackay_station_shipmap.json` переведен на halo platoon path `"/datum/squad/marine/halo/unsc/alpha"`.
- `map_config/maps.txt` и `map_config/shipmaps.txt` расширены через `SS220 EDIT` surfaces.
- `SHIP_MAP_NAMES` расширен HALO shipmap именами, чтобы сохранить локальный обход fallback логики.
- Secure five-tile HALO poddoor добавлен modular-side в `modular/halo/code/mixed/machinery/halo_unsc_poddoors.dm`.

## E-005: Размер локального integration diff
- `git diff --stat` после основной интеграции показывает `26 files changed, 754 insertions(+), 26 deletions(-)` для ручных integration-правок поверх импортированных payload-файлов.
- `git status --short` подтверждает наличие новых map/icon/content payload-файлов и правок integration surfaces.

## E-006: Проверки на момент обновления task-state
- `git diff --check`: пройден без содержательных замечаний; после ручной правки DMM дополнительно сняты предупреждения по line endings.
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`: passed, `0 errors, 0 warnings`, `2026-03-21`.
- `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_BASE`: initially found missing `voi` airlock types in `traxus_gamma_zone`, после интеграции `code/game/machinery/doors/airlock_types.dm` passed, `0 errors, 0 warnings`, `2026-03-21`.
- `tools/build/build --ci dm -DCIBUILDING -DCITESTING -DALL_MAPS -DALL_MAPS_STAGE_EXTRA`: passed, `0 errors, 0 warnings`, `2026-03-21`.
- Targeted maplint для `Mackay_Station.dmm` и `Mackay_Station_Shipmap.dmm`: passed после TGM-конверсии и замены escapepod var-edits на subtype path'ы.
- Полный maplint: все новые Mackay/tram/hangar/pelican DMM после локальных правок проходят, но `maps/map_files/ONI_Digsite_451/oni_digsite_451.dmm` все еще содержит upstream maplint violations:
  - duplicate reinforced girders;
  - duplicate power monitors;
  - var-edits на `/turf/open/shuttle/escapepod*`, `/turf/open/floor/almayer/black`, `/turf/open/nostromowater`.
- Из-за этого итоговый PR должен быть помечен как draft/with-known-lint-debt, если отдельно не выполнять cleanup ONI Digsite map.
