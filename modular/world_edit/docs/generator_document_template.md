# Шаблон документации live-генератора World Edit

## 1. Метаданные
1. `id`
2. `name_ru`
3. `category_ru`
4. `status` (`draft|ready`)
5. `execution_mode` (`batch|click`)
6. `version`

## 2. Runtime-контракт
1. `generator_type`
2. `required_rights`
3. `supports_preview`
4. `default_params`
5. `description_ru`

## 3. Назначение
1. Что делает генератор.
2. Какие админские сценарии он закрывает.
3. Что явно вне scope.

## 4. Параметры
1. Обязательные параметры.
2. Опциональные параметры.
3. Значения по умолчанию.
4. Диапазоны, enum и whitelist.
5. Пример валидного набора.

## 5. UI fields contract
1. Используется схема `ui_field_schema`.
2. Поля `get_ui_fields`: `id`, `label`, `kind`, `value`.
3. Допустимые метаданные: `options`, `min`, `max`, `step`, `description`, `validate_hint`, `group`, `visible`, `disabled`, `required`, `placeholder`.
4. `set_ui_param` должен возвращать обновленный `list`, строку ошибки или `null`.
5. Если генератор динамический, опиши `refresh_ui_state`.

## 6. Validation and guardrails
1. Правила `validate_params`.
2. Лимиты по объему операции.
3. Что считается destructive.
4. Какие подтверждения обязательны.

## 7. Preview / Apply
1. Что делает preview.
2. Что делает apply.
3. Какие данные попадают в `preview_meta`.
4. Какой результат считается успешным.

## 8. Click-intercept
1. Когда генератор захватывает click-mode.
2. Когда click-mode освобождается.
3. Что происходит при закрытии панели и `Destroy()` менеджера.

## 9. Audit and telemetry
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

## 10. Test cases
1. Позитивные сценарии.
2. Негативные сценарии.
3. Проверка прав.
4. Проверка preview без мутаций.
5. Проверка apply с мутациями.
6. Проверка click-intercept.
7. Проверка логов и истории.

## 11. Criteria for ready
1. Пройдены обязательные тесты и smoke-checklist.
2. Логи соответствуют контракту.
3. Документация синхронизирована с live runtime surface.
