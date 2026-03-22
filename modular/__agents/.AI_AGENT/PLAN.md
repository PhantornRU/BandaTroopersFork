# PLAN

## Активная задача
Закрыть review comments по HALO map PR: weather chance, ambience, typo fixes, Pelican CAS console density, Covenant bomb overlay logic и сопутствующий task-state.

## Scope
- Точечные правки в `code/datums/weather/**`, `code/game/area/**`, `code/game/machinery/**`.
- Перезапись `modular/__agents/.AI_AGENT/{PLAN,TODO,DECISIONS,EVIDENCE}.md` под текущий review-fix scope.
- Минимальная верификация через diff/compile.

## Out of scope
- Широкий cleanup `ONI Digsite 451` maplint debt.
- Новые контентные изменения вне review comments.
- Рискованные визуальные правки turf rotation без подтверждения по DMI/runtime.

## Фазы
1. Подтвердить затронутые surfaces и существующие паттерны. В процессе.
2. Переписать task-state под текущую задачу.
3. Внести подтвержденные review fixes.
4. Прогнать релевантные проверки и зафиксировать остаточные риски.

## Acceptance criteria
- Гарантированный weather-start убран с `Mackay Station` и `ONI Digsite 451`.
- `Traxus Gamma Zone` больше не использует snow/blizzard ambience placeholders.
- Исправлены подтвержденные typo/logic issues в area/machinery файлах.
- Task-state отражает текущий review-fix scope.
- `git diff --check` и релевантная compile-проверка проходят, либо статус явно зафиксирован.
