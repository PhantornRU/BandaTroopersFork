# PLAN

## Активная задача
Доработать World Edit DIR-размещение баррикад так, чтобы генераторы и связанные шаблоны корректно работали с моделью `turf + side-slot`: на одном тайле может стоять до 4 направленных баррикад, но не более 1 на каждую сторону.

## Scope
- Аудит active World Edit surface: `outpost_radius`, `blueprint_stamp`, `world_edit_blueprints`, curated blueprint JSON.
- Исправление live generator logic, которая still мыслит периметр как набор тайлов вместо directional slots.
- Проверка и при необходимости миграция curated blueprint/template данных под slot-модель.
- Добавление regression coverage для corner-case с несколькими DIR-баррикадами на одном тайле.

## Out of scope
- Deprecated/historical generators вне active runtime surface.
- Несвязанные UI/preview redesign, если для фикса не требуется менять runtime semantics.
- Изменение базовой семантики самих апстрим-баррикад вне минимально нужных integration points.

## Фазы
1. Подтвердить source-of-truth по directed barricade semantics и найти slot-aware / turf-only участки. Выполнено.
2. Перезаписать task-state под новый scope. Выполнено.
3. Перевести проблемный generator path на `turf+dir` slot planning с сохранением правила “одна баррикада на сторону”. В процессе.
4. Проверить curated templates и добавить regression test. Не начато.
5. Прогнать релевантные проверки и зафиксировать evidence/results. Не начато.

## Acceptance criteria
- Square/perimeter generation в World Edit умеет планировать несколько баррикад на одном тайле по разным cardinal DIR.
- На одну сторону тайла планируется и спавнится не более одной баррикады.
- Preview/apply/blueprint flows не ломают существующую slot-модель и не схлопывают multi-DIR corner placements в turf-only occupancy.
- Regression coverage ловит corner-case с углами и radius-based perimeter placement.
