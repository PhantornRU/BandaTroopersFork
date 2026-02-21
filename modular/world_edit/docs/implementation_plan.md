# План внедрения World Edit v1.3

## Цель
Синхронизировать все `status=ready` генераторы с единым inline UI-контрактом v2, стабилизировать `WorldEditPanel`, сохранить wizard fallback и зафиксировать полную документацию.

## Область изменений
1. Core manager и UI-контракт в `modular/world_edit/code/core/manager/*`.
2. Генераторы в `modular/world_edit/code/generators/*`.
3. TGUI-панель в `tgui/packages/tgui/interfaces/WorldEditPanel.tsx`.
4. Документация в `modular/world_edit/docs/*`.

## Жесткие ограничения
1. Legacy-файлы HumanAI не изменяются.
2. Runtime core реестра (`world_edit_registry.dm`) остается 1:1 без новых обязательных runtime-полей.
3. Комментарии и документация модуля `world_edit` ведутся на русском.

## Реализованный объем v1.3

### Этап 1. Нормализация UI-контракта менеджера
1. Backend-нормализация `ui_fields`:
- default-значения;
- фильтрация `visible=FALSE`;
- фильтрация невалидного `kind`;
- игнор полей без `id`;
- нормализация options с устранением коллизий label.
2. Добавлено поле `last_ui_error` в менеджере.
3. `ui_data` расширен флагами:
- `has_inline_fields`, `ui_mode`, `can_run_preview`, `can_run_apply`, `can_stop_click_mode`, `can_refresh_ui`.
4. Добавлено действие `refresh_ui` для принудительного обновления runtime UI-состояния генератора.

### Этап 2. Синхронизация ready-генераторов с inline
1. `fortify_room`: inline-поля лимитов/радиуса/флагов границ.
2. `defense_grid`: inline-каталог с динамикой `faction/turned_on`, unique label для дублей.
3. `breach_layout`: inline-управление зарядом/направлением/профилем.
4. `structure_chunk`: inline-выбор шаблона и destructive-флагов.
5. `barricade_builder`: v2 metadata (`group/description/validate_hint`), динамический disable для `fixed_dir`.
6. `chaos_demolition`: v2 metadata, динамический disable зависимых полей (`scatter/explosion/fire`).

### Этап 3. Доработка TGUI панели
1. Добавлена поддержка `kind=text`.
2. Добавлены отображения `description` и `validate_hint`.
3. Добавлена группировка полей по `group`.
4. Добавлен режим отображения источника параметров: `inline` или `wizard fallback`.
5. Добавлена кнопка `Обновить параметры генератора`.
6. Добавлен вывод `last_ui_error`.
7. Кнопки `Preview/Apply/Stop click` используют backend disable-флаги.

### Этап 4. Документация
1. Обновлены документы:
- `game_design.md`
- `implementation_plan.md`
- `generator_catalog_seed.md`
- `generator_document_template.md`
2. Добавлен документ:
- `ui_field_schema_v2.md`
3. Добавлены/обновлены паспорта генераторов:
- `fortify_room.md`
- `defense_grid.md`
- `breach_layout.md`
- `structure_chunk.md`
- `barricade_builder.md`
- `chaos_demolition.md`

## KPI v1.3
1. Все `status=ready` генераторы имеют inline-поля v2.
2. Wizard fallback остается рабочим для всех генераторов.
3. Каждое `apply` логируется по контракту с `params_hash`.
4. История операций ограничена 50 записями.
5. В diff отсутствуют изменения в legacy HumanAI-файлах.

## Smoke-checklist (обязательный)
1. Права:
- без `R_DEBUG` панель не открывается;
- `structure_chunk` недоступен без `R_EVENT`.
2. UI:
- панель открывается через `open_world_edit_panel`;
- вкладки работают;
- inline-поля доступны у всех `ready` генераторов;
- wizard fallback работает.
3. Функционал:
- `preview` и `apply` отрабатывают на каждом генераторе;
- click-режимы корректно захватывают и освобождают intercept.
4. Логи:
- `log_admin + message_admins` присутствуют на каждом `apply`;
- payload включает `params_hash`.
5. Регрессии:
- legacy HumanAI-файлы не изменены.

## Критерии готовности
1. Полный smoke-checklist пройден.
2. Документация синхронизирована с фактическим кодом.
3. Не найдено блокирующих багов по UI-контракту v2.
