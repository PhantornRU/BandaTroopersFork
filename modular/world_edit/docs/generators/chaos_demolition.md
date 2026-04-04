# Паспорт генератора: `chaos_demolition`

## Метаданные
1. `id`: `chaos_demolition`
2. `name_ru`: `Хаос-разрушение`
3. `category_ru`: `Разрушение`
> Исторический паспорт. Реализация генератора удалена из live code; документ сохранен как deprecated/historical reference и не входит в active registry/runtime surface.
4. `status`: `deprecated`
5. `execution_mode`: `click`
6. `required_rights`: `R_DEBUG`

## Назначение
Контролируемая хаос-операция в радиусе с поддержкой:
1. перемешивания movable-объектов;
2. разлета movable-объектов;
3. опционального взрыва;
4. опционального создания постоянного огня.

## Параметры
1. `radius` (`1..6`)
2. `shuffle_enabled`
3. `scatter_enabled`
4. `scatter_steps` (`1..6`)
5. `explode_enabled`
6. `explosion_power` (`100..600`)
7. `explosion_falloff` (`100..1200`)
8. `persistent_fire_enabled`
9. `persistent_fire_density` (`0.05..0.50`)
10. `max_atoms` (`1..250`)
11. `affect_anchored`

## UI fields contract
1. `ui_schema_version`: `v2`
2. `ui_mode`: `inline+fallback`
3. Inline-поля содержат `group`, `description`, `validate_hint`.
4. Зависимые поля динамически блокируются:
- `scatter_steps` при `scatter_enabled=FALSE`;
- `explosion_power/explosion_falloff` при `explode_enabled=FALSE`;
- `persistent_fire_density` при `persistent_fire_enabled=FALSE`.

## Inline/Wizard parity
1. Все параметры доступны и inline, и в wizard.
2. Валидация диапазонов и no-op проверка одинаковы.

## Область воздействия
1. Обрабатываются только `atom/movable`.
2. `mob` исключены.
3. `screen`/служебные объекты исключены.
4. Турфы напрямую не перестраиваются.

## Click-flow
1. `apply` включает click-режим.
2. ЛКМ выбирает центр операции.
3. Перед запуском обязательно подтверждение.
4. Для тяжелых операций действует второе подтверждение.

## Guardrails
1. Блокировка при превышении `max_atoms`.
2. Блокировка при отключении всех режимов (`shuffle/scatter/explode/fire`).
3. Двойное подтверждение для тяжелых сценариев.

## Persistent fire
1. Используется `/obj/effect/world_edit_persistent_fire`.
2. Очаг не затухает автоматически.
3. Очаг тушится штатным огнетушителем через `extinguish()`.

## Логирование
Каждая завершенная click-операция пишет `log_admin + message_admins` со стандартным payload и `params_hash`.

## Тест-кейсы
1. Проверка всех переключателей режимов из inline.
2. Блокировка no-op и превышения лимитов.
3. Проверка режима `persistent_fire_enabled` и cap-поведения.
4. Проверка освобождения click-intercept.
