# Паспорт генератора: `breach_layout`

## Метаданные
1. `id`: `breach_layout`
2. `name_ru`: `Схема бреш-зарядов`
3. `category_ru`: `Проломы`
> Исторический паспорт. Реализация генератора удалена из live code; документ сохранен как deprecated/historical reference и не входит в active registry/runtime surface.
4. `status`: `deprecated`
5. `execution_mode`: `click`
6. `required_rights`: `R_DEBUG`

## Назначение
Click-генератор для расстановки бреш-зарядов с выбором типа заряда, направления и профиля допустимых целей.

## Параметры
1. `charge_type`
2. `direction` (`NORTH|EAST|SOUTH|WEST`)
3. `allowed_profile`

## UI fields contract
1. `ui_schema_version`: `v2`
2. `ui_mode`: `inline+fallback`
3. Inline-поля покрывают все runtime-параметры.
4. `set_ui_param` валидирует `charge_type`, `direction`, `allowed_profile`.

## Inline/Wizard parity
1. Все параметры доступны и inline, и в wizard.
2. Click-flow после настройки одинаков для обоих путей.

## Click-intercept
1. `apply` включает click-режим и захватывает intercept через менеджер.
2. ЛКМ — установка заряда по текущему профилю.
3. СКМ — быстрый локальный выбор типа заряда и направления.
4. Освобождение intercept выполняется менеджером при stop/close/Destroy.

## Preview / Apply
1. `preview` информационный (описывает click-flow).
2. `apply` переводит генератор в click-режим.

## Guardrails
1. Проверка допустимых целей через профиль `allowed_profile`.
2. Отказ без мутации мира при невалидной цели.

## Логирование
Каждая успешная click-постановка логируется как отдельная операция с `params_hash`.

## Тест-кейсы
1. Смена всех параметров без wizard.
2. Корректная постановка/блокировка по профилю целей.
3. Корректное освобождение click-intercept.
