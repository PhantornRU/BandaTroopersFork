# Геймдизайн World Edit v1.3

## Цель
Дать администраторам единый интерфейс редактирования мира с предсказуемым жизненным циклом генераторов, безопасными ограничениями и обязательным аудитом. Legacy-инструменты HumanAI не изменяются и продолжают работать отдельно.

## Границы
1. Не изменяем legacy-файлы:
- `code/modules/mob/living/carbon/human/ai/fortify_room.dm`
- `code/modules/mob/living/carbon/human/ai/defense_creator.dm`
- `code/modules/mob/living/carbon/human/ai/breach_placer.dm`
2. Новый код и документация находятся в `modular/world_edit/*`.
3. TGUI-интерфейс расположен в `tgui/packages/tgui/interfaces/WorldEditPanel.tsx`.

## UX-поток
Единый поток для всех генераторов:
1. `Select` — выбор генератора по категориям.
2. `Configure` — inline-поля (`get_ui_fields/set_ui_param`) или wizard fallback (`configure_params`).
3. `Preview` — dry-run без мутации карты.
4. `Apply` — подтвержденное применение.
5. `History` — история операций текущей сессии (до 50 записей).

## Единый TGUI-хаб
Панель: `WorldEditPanel`.

Вкладки:
1. `Генераторы` — категории, фильтр `status=ready`, права, режим выполнения.
2. `Параметры` — inline-форма v2, wizard fallback, runtime-статус, ошибки `set_param`.
3. `Preview` — запуск/очистка предпросмотра, meta-информация.
4. `Apply` — запуск применения, остановка click-режима.
5. `История` — последние операции сессии и очистка истории.

## UI Field Schema v2
Подробности в `docs/ui_field_schema_v2.md`.

Ключевые правила:
1. Обязательные поля: `id`, `label`, `kind`, `value`.
2. `kind`: `select | number | boolean | text`.
3. Optional metadata: `description`, `validate_hint`, `group`, `visible`, `disabled`, `required`, `placeholder`, `min/max/step`, `options`.
4. Если генератор не вернул валидные inline-поля, используется wizard fallback.

## Матрица генераторов (v1.3)
| Генератор | Runtime статус | UI-режим | Wizard fallback |
|---|---|---|---|
| `fortify_room` | `ready` | `inline` | `да` |
| `defense_grid` | `ready` | `inline` | `да` |
| `breach_layout` | `ready` | `inline` | `да` |
| `structure_chunk` | `ready` | `inline` | `да` |
| `barricade_builder` | `ready` | `inline` | `да` |
| `chaos_demolition` | `ready` | `inline` | `да` |

## Политика прав
1. Открытие панели `open_world_edit_panel`: `R_DEBUG`.
2. Генераторы по умолчанию: `R_DEBUG`.
3. `structure_chunk`: `R_EVENT` (дополнительное ограничение).
4. Для `structure_chunk` фактически нужны оба условия: доступ к панели + права генератора.

## Политика click-intercept
1. Захват intercept происходит только при `apply` click-генератора.
2. При конфликте с другим инструментом показывается подтверждение перехвата.
3. Освобождение intercept выполняется при:
- остановке click-режима;
- сбросе генератора;
- закрытии панели;
- `Destroy()` менеджера.

## Политика логирования
Каждое `apply` обязано писать:
1. `log_admin(...)`
2. `message_admins(...)`

Payload v1.3:
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

## UX ошибок и отказов
1. Ошибки `set_ui_param` показываются одновременно:
- в `last_ui_error` на вкладке параметров;
- в `to_chat`.
2. Невалидные/скрытые поля не роняют панель: backend их фильтрует.
3. `Preview`/`Apply` используют disable-флаги из backend (`can_run_preview`, `can_run_apply`).

## Интеграция с существующими инструментами
1. `PlayerPanel` — шаблон вкладочного UX.
2. `Human Defense Creator` — шаблон работы с каталогами объектов и параметрами.
3. Legacy `Fortify Room`/`Breach Placer`/`Defense Creator` — источник паритетной логики через дублирование в модуле.
4. `Map Template - Place` — backend для `structure_chunk` без дублирования map loader.
5. `Build Mode` — корректная обработка конфликта click-intercept.

## Ограничения v1.3
1. Полного rollback нет.
2. Используем `preview + confirm + session history + audit`.
3. История операций хранится только в рамках текущей сессии менеджера.
