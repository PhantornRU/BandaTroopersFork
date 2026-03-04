# PLAN

## Активная задача
Завершить `various_fixes` GroundSide-порт из `RU-CMSS13/cmss13-pve`, устранить compile/map regressions, разгрузить переполненные DMI и задокументировать итоговый перенос.

## Scope
- Исправить branch-wide compile blockers и missing compatibility types.
- Сверить и починить уже портированные GroundSide DMM против `pr-1252` и `ru-master`.
- Доперенести отсутствующие GroundSide карты из `ru-master`.
- Вынести новые onmob/inhand состояния из переполненных `uniform_0.dmi`, `items_lefthand_0.dmi`, `items_righthand_0.dmi`.
- Обновить `VARIOUS_FIXES_PORTING_MAP.md` и task-state.

## Out Of Scope
- Порт новых shipmaps.
- Несвязанный incidental upstream baggage.
- Деструктивная перепись истории существующих authored commits.

## Фазы
1. Task-state + inventory missing GroundSide карт.
2. Build stabilization: telecomms + compatibility types.
3. Map reconciliation для уже лежащих карт.
4. Порт missing RU GroundSide maps.
5. DMI split и repoint ссылок.
6. Документация и финальные проверки.

## Acceptance Criteria
- `dm` и `ALL_MAPS` сборки не падают на текущих undefined/unknown type regressions.
- `dmi.test` не падает на переполненных onmob/inhand DMI.
- Все missing GroundSide карты из `ru-master` присутствуют в `maps/` и `map_config/maps.txt`.
- `VARIOUS_FIXES_PORTING_MAP.md` фиксирует sources, конфликты, aliases и DMI split.
