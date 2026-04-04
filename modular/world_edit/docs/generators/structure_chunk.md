# Паспорт генератора: `structure_chunk`

## Метаданные
1. `id`: `structure_chunk`
2. `name_ru`: `Фрагмент структуры`
3. `category_ru`: `Шаблоны`
> Исторический паспорт. Реализация генератора удалена из live code; документ сохранен как deprecated/historical reference и не входит в active registry/runtime surface.
4. `status`: `deprecated`
5. `execution_mode`: `batch`
6. `required_rights`: `R_EVENT`

## Назначение
Обертка над существующим backend map templates (`SSmapping.map_templates`, `template.get_affected_turfs`, `template.load`) без дублирования loader.

## Параметры
1. `template_name`
2. `centered` (`TRUE|FALSE`)
3. `delete_atoms` (`TRUE|FALSE`, destructive)

## UI fields contract
1. `ui_schema_version`: `v2`
2. `ui_mode`: `inline+fallback`
3. Inline-поля:
- выбор `template_name` из актуального каталога;
- флаги `centered`, `delete_atoms`.
4. `set_ui_param` блокирует пустой/невалидный template.

## Inline/Wizard parity
1. Все параметры доступны и inline, и в wizard.
2. Подтверждения и guardrails одинаковые.

## Preview / Apply
1. `preview` показывает зону затрагиваемых тайлов.
2. `apply` вызывает `template.load`.

## Guardrails
1. Доступ только при `R_EVENT`.
2. `delete_atoms=TRUE` считается destructive и требует подтверждения apply.
3. При невалидном `template_name` операция блокируется.

## Логирование
Каждое `apply` пишет стандартный audit payload, включая `params_hash`.

## Тест-кейсы
1. Выбор существующего template и успешный preview/apply.
2. Блокировка при несуществующем template.
3. Проверка destructive подтверждения при `delete_atoms=TRUE`.
