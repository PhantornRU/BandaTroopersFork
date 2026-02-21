# Шаблон паспорта генератора World Edit

## 1. Метаданные
1. `id`:
2. `name_ru`:
3. `category_ru`:
4. `status` (`draft|ready|deprecated`):
5. `execution_mode` (`batch|click`):
6. Версия:

## 2. Runtime-контракт (core 1:1)
1. `generator_type`:
2. `required_rights`:
3. `supports_preview`:
4. `default_params`:
5. Примечание: runtime-поля обязаны совпадать 1:1 с `world_edit_registry.dm`.

## 3. Docs-only metadata
1. `owner`:
2. `priority`:
3. `phase`:
4. `ui_schema_version`:
5. `ui_mode` (`inline`, `fallback`, `inline+fallback`):

## 4. Назначение
1. Что изменяет/создает генератор.
2. Целевые админские сценарии.
3. Что явно вне scope.

## 5. Параметры
1. Обязательные параметры.
2. Опциональные параметры.
3. Значения по умолчанию.
4. Диапазоны/enum.
5. Пример валидного набора.

## 6. UI fields contract (обязательно)
1. Версия схемы (`v2`).
2. Поля `get_ui_fields`:
- `id`, `label`, `kind`, `value`;
- `options/min/max/step`;
- `description`, `validate_hint`, `group`, `visible`, `disabled`, `required`, `placeholder`.
3. Правила `set_ui_param`.
4. Поведение при ошибке `set_ui_param` (возврат строки ошибки).

## 7. Inline/Wizard parity (обязательно)
1. Какие параметры доступны inline.
2. Какие параметры доступны через wizard.
3. Гарантия паритета значений и валидаций.
4. Допустимые отличия (если есть) и их причина.

## 8. Валидация и guardrails
1. Правила `validate_params`.
2. Лимиты (`batch/scan/radius/max_atoms/...`).
3. Что считается destructive.
4. Какие подтверждения обязательны.

## 9. Failure modes
1. Список отказов.
2. Реакция системы на каждый отказ.
3. Пользовательские сообщения.
4. Поведение истории/логов при отказах.

## 10. Click-intercept (для click генераторов)
1. Политика захвата.
2. Политика освобождения.
3. Конфликт с buildmode и другими intercept-инструментами.
4. Поведение при закрытии панели и Destroy менеджера.

## 11. Preview / Apply
1. Что делает preview.
2. Что делает apply.
3. Требуется ли preview перед apply.
4. Гарантия согласованности preview/apply.

## 12. Аудит и телеметрия
Обязательные поля apply-события:
1. `generator_id`
2. `actor_ckey`
3. `rights_used`
4. `center_turf`
5. `created_count`
6. `deleted_count`
7. `duration_ms`
8. `result`
9. `params_short`
10. `params_hash`

## 13. Совместимость
1. Совместимость с legacy-инструментами.
2. Ограничения backward compatibility.
3. План миграции (если применимо).

## 14. Тест-кейсы
1. Позитивные сценарии.
2. Негативные сценарии.
3. Проверка прав.
4. Проверка preview (без мутаций).
5. Проверка apply (с мутациями).
6. Проверка click-intercept.
7. Проверка логов.

## 15. Критерии `status=ready`
1. Пройдены обязательные тесты и smoke-checklist.
2. Логи соответствуют контракту.
3. Обновлены docs (`паспорт + каталог`).
4. Для click-режима подтверждено корректное освобождение intercept.
