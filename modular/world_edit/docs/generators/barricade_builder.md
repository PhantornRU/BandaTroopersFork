# Паспорт генератора: `barricade_builder`

## Метаданные
1. `id`: `barricade_builder`
2. `name_ru`: `Построитель баррикад`
3. `category_ru`: `Баррикады`
> Исторический паспорт. Реализация генератора удалена из live code; документ сохранен как deprecated/historical reference и не входит в active registry/runtime surface.
4. `status`: `deprecated`
5. `execution_mode`: `click`
6. `required_rights`: `R_DEBUG`

## Назначение
Построение баррикад формами `point/line/rectangle` с управлением направлением (`auto/fixed`) и безопасными ограничениями.

## Параметры
1. `barricade_path`
2. `shape_mode` (`point|line|rectangle`)
3. `dir_mode` (`auto|fixed`)
4. `fixed_dir` (`NORTH|EAST|SOUTH|WEST`)
5. `replace_existing_same_dir` (`TRUE|FALSE`)
6. `max_tiles` (`1..120`)

## UI fields contract
1. `ui_schema_version`: `v2`
2. `ui_mode`: `inline+fallback`
3. Inline-поля содержат `group`, `description`, `validate_hint`.
4. `fixed_dir` динамически блокируется, если `dir_mode != fixed`.
5. Для дублей названий баррикад label дополняется path.

## Inline/Wizard parity
1. Все параметры доступны и inline, и в wizard.
2. Валидация (`shape_mode/dir_mode/max_tiles`) одинакова.

## Click-flow
1. `apply` включает click-режим.
2. `point`: ЛКМ ставит одну баррикаду.
3. `line/rectangle`: первый ЛКМ — anchor, второй ЛКМ — финал формы.
4. СКМ сбрасывает anchor.

## Алгоритмы
1. `line`: Bresenham между двумя точками.
2. `rectangle`: периметр осевого прямоугольника.
3. DIR:
- `fixed` — всегда `fixed_dir`;
- `auto + point` — `user.dir`;
- `auto + line` — доминирующая ось (при равенстве приоритет X);
- `auto + rectangle` — внешний DIR стороны периметра.

## Guardrails
1. Ограничение `max_tiles`.
2. При `replace_existing_same_dir=TRUE` запрашивается отдельное destructive-подтверждение.
3. Если лимит превышен, операция блокируется без мутации мира.

## Логирование
Каждое завершенное click-применение пишет `log_admin + message_admins` со стандартным payload и `params_hash`.

## Тест-кейсы
1. `point/line/rectangle` дают ожидаемый набор тайлов.
2. `auto/fixed` DIR работает корректно.
3. Preview и apply используют согласованный target-набор.
4. После stop/close/Destroy click-intercept освобождается.
