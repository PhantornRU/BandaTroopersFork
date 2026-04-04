# Паспорт генератора: `defense_grid`

## Метаданные
1. `id`: `defense_grid`
2. `name_ru`: `Сетка обороны`
3. `category_ru`: `Оборона`
> Исторический паспорт. Этот генератор сохранен как deprecated/historical ветка и не входит в active registry/runtime surface.
4. `status`: `deprecated`
5. `execution_mode`: `batch`
6. `required_rights`: `R_DEBUG`

## Назначение
Пакетная установка оборонительных объектов на последовательность тайлов с использованием каталога `subtypesof(/datum/human_ai_defense)`.

## Параметры
1. `defense_path`
2. `faction`
3. `turned_on`
4. `placement_direction` (`Default|North|East|South|West`)
5. `batch_count` (`1..50`)
6. `batch_step` (`1..7`)

## UI fields contract
1. `ui_schema_version`: `v2`
2. `ui_mode`: `inline+fallback`
3. Inline-поля динамически учитывают флаги выбранного объекта:
- `faction` скрывается/блокируется, если объект не поддерживает faction;
- `turned_on` скрывается/блокируется, если объект не поддерживает управление питанием.
4. Для дублей имен в каталоге label дополняется path.

## Inline/Wizard parity
1. Все параметры доступны и inline, и в wizard.
2. Валидация и диапазоны одинаковые.

## Preview / Apply
1. `preview` показывает целевые тайлы пакетной установки.
2. `apply` выполняет реальный spawn объектов по target-тайлам.

## Guardrails
1. Ограничение `batch_count` и `batch_step`.
2. Валидация `defense_path` на принадлежность `datum/human_ai_defense`.

## Логирование
`apply` пишет `log_admin + message_admins` со стандартным payload и `params_hash`.

## Тест-кейсы
1. Корректная динамика `faction/turned_on` при смене `defense_path`.
2. Корректная генерация target-тайлов при разных `placement_direction/batch_*`.
3. Корректная обработка дублей названий в select.
