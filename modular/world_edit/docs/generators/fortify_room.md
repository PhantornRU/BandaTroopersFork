# Паспорт генератора: `fortify_room`

## Метаданные
1. `id`: `fortify_room`
2. `name_ru`: `Укрепление комнаты`
3. `category_ru`: `Комнаты`
> Исторический паспорт. Этот генератор сохранен как deprecated/historical ветка и не входит в active registry/runtime surface.
4. `status`: `deprecated`
5. `execution_mode`: `batch`
6. `required_rights`: `R_DEBUG`

## Назначение
Генератор выполняет укрепление комнаты от текущего тайла через flood-fill с ограничениями `tile_scan_limit` и `scan_radius`.

## Параметры
1. `fortification_level`
2. `tile_scan_limit` (`1..195`)
3. `scan_radius` (`1..30`)
4. `respect_windows` (`TRUE|FALSE`)
5. `respect_doors` (`TRUE|FALSE`)

## UI fields contract
1. `ui_schema_version`: `v2`
2. `ui_mode`: `inline+fallback`
3. Inline-поля содержат `group`, `description`, `validate_hint`.
4. `set_ui_param` валидирует уровень укрепления и ограничивает числовые параметры.

## Inline/Wizard parity
1. Все параметры доступны и inline, и в wizard.
2. Диапазоны и валидация идентичны.

## Preview / Apply
1. `preview` рассчитывает цели и визуализирует их без мутации карты.
2. `apply` использует тот же расчет и выполняет создание объектов.
3. Для генератора включено `requires_preview_before_apply = TRUE`.

## Guardrails
1. `tile_scan_limit` ограничивает объем flood-fill.
2. `scan_radius` ограничивает распространение по расстоянию от стартового тайла.

## Логирование
Каждое `apply` фиксирует стандартный payload World Edit, включая `params_hash`.

## Тест-кейсы
1. Изменение всех параметров через inline и wizard.
2. Совпадение target-набора между preview и apply.
3. Блокировка при выходе параметров за диапазоны.
