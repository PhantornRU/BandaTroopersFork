# RTO Support: технический дизайн

## 1. Назначение

`RTO Support` реализует персональную modular-систему вызова поддержки для роли `RTO` без привязки к singleton-runtime существующего `fire_support`.

Модуль держит:

- персональный controller на конкретного RTO;
- конфигурационные шаблоны пакетов;
- серверную валидацию;
- dispatch в `datum/fire_support`;
- action-кнопки и targeting через отдельный `RTO binoculars`;
- отдельное TGUI preset menu.

## 2. Главная архитектура

Система разбита на четыре слоя:

1. `config`
   `rto_support_template` и `rto_support_action_template`
2. `runtime`
   `rto_support_controller`, `rto_visibility_zone`
3. `services`
   `rto_support_validation_service`, `rto_support_dispatch_service`
4. `interaction`
   `human_action`-кнопки, `RTO binoculars`, preset menu

## 3. Support profiles

Доступность пакетов data-driven и зависит от `support_profile`.

Текущий профильный контракт:

- `uscm`
- `unsc`
- `odst`

Текущая доступность:

- `USCM`: `mortar`, `cas`, `heavy`, `logistics`, `medical`, `technical`
- `UNSC`: `mortar`, `halo_logistics`, `halo_medical`, `halo_technical`
- `ODST`: `cas`, `heavy`, `halo_logistics`, `halo_medical`, `halo_technical`

Профиль должен определяться через dedicated RTO binocular variant, а fallback по job остается только резервным путем.

## 4. Controller и runtime-контракты

Controller хранит:

- владельца;
- `selected_templates`
- `active_zone`
- `armed_action_id`
- `armed_template_id`
- `shared_cooldowns_by_template[template_id]`
- `zone_shared_cooldown_until`
- `zone_cooldowns_by_template[template_id]`
- `action_cooldowns[action_id]`
- reset-state выбора слотов
- ссылки на RTO action-кнопки

Controller больше не живет в модели singular `active_template`.

Основной контракт:

- можно выбрать до `2` уникальных пакетов;
- второй слот необязателен;
- первый выбор запускает timer полного reset на `60 минут`;
- reset всегда полный и очищает оба слота;
- select-preset action остается доступным и после первого выбора.

## 5. Cooldown model

Runtime-модель cooldown'ов:

- `shared_cooldowns_by_template[template_id]`
- `action_cooldowns[action_id]`
- `zone_shared_cooldown_until`
- `zone_cooldowns_by_template[template_id]`

### Support cooldowns

- `shared_cooldown` относится к конкретному пакету;
- вызов из пакета A не блокирует пакет B;
- `personal_cooldown` относится только к одной ability.

### Zone cooldowns

- активный сектор в рантайме всегда только один;
- после окончания сектора стартует общий zone cooldown;
- одновременно стартует личный zone cooldown только пакета-источника;
- чужой пакет не наследует личный zone cooldown чужого сектора.

### Solo discount

Если выбран ровно один пакет и он zone-based, effective cooldown его сектора уменьшается в `2 раза`.

Для этого controller использует:

- `get_solo_visibility_zone_cooldown()`
- `uses_single_template_zone_discount()`
- `get_effective_visibility_zone_cooldown()`

Применять zone cooldown нужно через effective-value, а не напрямую через `template.visibility_zone_cooldown`.

## 6. Zone ownership

Zone-based actions работают только через сектор своего пакета.

Правила:

- у `Mortar`, `CAS`, `Heavy Strike` свой template-owned sector flow;
- активный сектор пакета A не валидирует actions пакета B;
- второй сектор нельзя развернуть, пока существует первый;
- `validation_service` и HUD state builder должны опираться на `source_template`.

## 7. HUD и action lifecycle

HUD остается `human_action`-based.

Порядок action handles должен быть стабильным:

1. `select_preset`
2. visibility actions по слотам
3. `coordinates`
4. `manual_marker`
5. support actions пакета 1
6. support actions пакета 2

Не переносить этот HUD на `item_action` без отдельного архитектурного решения.

## 8. Preset menu contract

Preset menu должен получать от controller:

- `selected_templates`
- `selected_count`
- `max_selected_templates`
- `can_add_template`
- `can_reset_templates`
- `reset_ready_in`

Для zone-based пакетов preset UI DTO также должен уметь показать:

- полный `visibility_zone_cooldown`
- reduced `visibility_zone_cooldown_solo`
- текущий `visibility_zone_cooldown_current`
- активен ли `solo_zone_cooldown_active`

Игрок не должен узнавать про solo-бонус только через код или случайный gameplay.

## 9. HALO support catalog

HALO admin bridge держится отдельно в modular compat layer.

Текущий HALO контракт:

- `halo_logistics`
- `halo_medical`
- `halo_technical`

`halo_engineering` и `halo_command` больше не являются публичными UI/admin template-id. Их payload-группы слиты в `halo_technical`.

## 10. USCM payload model

USCM utility support использует hybrid-подход:

- часть новых действий переиспользует existing upstream crates;
- часть заведена как compact modular payloads в `modular/rto_support/code/fire_support/uscm_support_payloads.dm`.

Текущие новые USCM utility-секции:

- `logistics`
- `medical`
- `technical`

## 11. Что не менять без причины

- не возвращать singular `active_template`-контракт наружу;
- не смешивать zone cooldown и support cooldown в одном primary label;
- не убирать постоянную доступность select-preset action;
- не делать zone cooldown глобально одинаковым для всех пакетов без учета template ownership;
- не скрывать solo-бонус от игрока;
- не разносить runtime-логику `rto_support` в upstream-пути без жесткой необходимости.
