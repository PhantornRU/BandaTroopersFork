# RTO Support: технический дизайн

## 1. Назначение

`RTO Support` реализует персональную систему вызова поддержки для роли `RTO` без привязки к singleton-runtime существующего `fire_support`.

Модуль держит:

- персональный controller на конкретного RTO;
- конфигурационные шаблоны поддержки;
- серверную валидацию;
- dispatch в свежие `datum/fire_support`;
- интерфейсные action-кнопки и таргетинг через отдельный RTO-бинокль.

## 2. Главная архитектура

Система разбита на четыре слоя:

1. `config`
   `rto_support_template` и `rto_support_action_template`.
2. `runtime`
   `rto_support_controller`, `rto_visibility_zone`.
3. `services`
   `rto_support_validation_service`, `rto_support_dispatch_service`.
4. `interaction`
   `human_action`-кнопки, `RTO binoculars`, preset menu.

Это сохраняет `SRP`:

- controller координирует runtime, но не рисует TGUI и не исполняет payload сам;
- validation валидирует, но не dispatch-ит;
- dispatch исполняет, но не принимает решение “можно/нельзя”;
- binocular остаётся транспортом наведения и live-laser поведения, а не владельцем всей бизнес-логики.

## 3. Почему actions остались `human_action`

HUD не был перенесён на `item_action`.

Причина:

- support-кнопки динамически зависят от выбранного пресета и состояния controller;
- lifecycle этих action'ов уже завязан на controller;
- миграция на `item_action` дала бы большой рефактор без достаточной продуктовой выгоды.

Итог:

- controller по-прежнему создаёт и хранит action-датумы;
- actions не удаляются при убирании бинокля из рук;
- actions скрываются и показываются через `hide_from()` / `unhide_from()` в зависимости от того, находится ли `RTO binoculars` в одной из рук владельца.

## 4. Controller

`/datum/rto_support_controller` хранит:

- владельца;
- активный template;
- активный visibility zone;
- armed mode;
- общий cooldown поддержки;
- личные cooldown'ы способностей;
- ссылки на RTO action-кнопки.

Controller дополнительно умеет:

- определять `RTO binoculars` именно в руках, а не где угодно в инвентаре;
- скрывать/показывать действия на HUD;
- строить structured state для action UI:
  - `build_visibility_action_state()`
  - `build_support_action_state(action_id)`
- собирать комбинированные chat-сообщения о блокировке действия.

## 5. Visibility actions only with binocular in hands

Все RTO actions скрываются, если:

- у владельца нет `RTO binoculars` в `l_hand` или `r_hand`;
- владелец мёртв;
- владелец больше не RTO.

Это правило распространяется на:

- `Выбрать пакет поддержки`;
- `Развернуть сектор наведения`;
- support abilities;
- `Координаты`;
- `Лазерная отметка`.

При потере бинокля из рук controller:

- снимает armed mode;
- останавливает live marker;
- обновляет HUD.

## 6. Utility-режимы

Utility-режимы остались частью `armed_action_id`, но теперь являются persistent mode, а не one-shot абилками.

### `Координаты`

- не имеют cooldown;
- не создают лазер;
- после успешного `Ctrl+Click` не выключаются;
- только печатают координаты цели в чат.

### `Лазерная отметка`

- не имеет cooldown;
- после `Ctrl+Click` запускает или переносит живую подсветку;
- не создаёт timed marker datum на земле;
- держится только пока RTO реально продолжает вести цель через бинокль.

Live marker сбрасывается, если:

- бинокль больше не в руке;
- пользователь перестал смотреть через него;
- armed mode больше не `RTO_SUPPORT_ARM_MARKER`;
- нет LOS;
- владелец умер или incapacitated.

## 7. Visibility zone и support cooldown model

Runtime-модель кулдаунов не была переписана. В controller уже живут отдельные таймеры:

- `visibility_zone_cooldown_until`
- `shared_cooldown_until`
- `action_cooldowns[action_id]`

Исправление было сделано на уровне state presentation.

### Zone timings

- `Mortar`: `75s active / 45s recovery`
- `CAS`: `55s active / 70s recovery`
- `Heavy Strike`: `40s active / 95s recovery`
- `Logistics`: zones unsupported

Recovery зоны стартует после завершения или очистки зоны, а не в момент deploy.

## 8. Как теперь строится UI-состояние support actions

Для support actions controller формирует state со следующими сущностями:

- `zone_state`
- `zone_ready_in`
- `zone_expires_in`
- `shared_cooldown_in`
- `personal_cooldown_in`
- `primary_label`
- `secondary_labels`

Правило:

- primary label для zone-based шаблонов описывает именно сектор;
- shared/personal cooldown идут отдельными secondary labels;
- visibility action не читает support shared cooldown вообще.

Примеры:

- `Сектор CD: 34s; Общий КД: 12s`
- `Сектор: 41s; Личный КД: 55s`
- `Общий КД: 20s` для `Logistics`

## 9. Бинокль и live laser

`/obj/item/device/binoculars/rto` теперь хранит:

- `paired_pouch`
- `live_marker_target`
- `live_marker_overlay`
- `live_marker_owner`
- loop-timer проверки live marker

Подсветка использует стандартные overlay helper'ы:

- `apply_fire_support_laser()`
- `remove_fire_support_laser()`

То есть ручная лазерная отметка ведёт себя как настоящий designator-style laser, а не как временная точка-объект.

## 10. Dedicated RTO sling pouch

Добавлен `/obj/item/storage/pouch/sling/rto`.

Семантика:

- pouch принимает только свой paired `RTO binoculars`;
- другой предмет внутрь не вставляется;
- ручное `attack_self()` не разрывает пару;
- `empty()` не используется для ручного выброса бинокля;
- если бинокль уронен, стандартный sling retrieval пытается вернуть его обратно;
- если pouch сброшен, пока paired binocular в руке владельца, pouch пытается немедленно втянуть бинокль внутрь.

Комплект создаётся helper-процедурой `build_rto_support_binocular_kit()`.

## 11. Loadout / locker

RTO больше не получает loose binocular.

Теперь:

- equipped preset создаёт paired `RTO sling pouch + RTO binoculars`;
- kit сначала пытается занять `L_STORE`, затем `R_STORE`, затем backpack, затем руку;
- locker также содержит paired-kit, а не отдельный бинокль;
- старый tactical binocular для RTO не выдаётся.

## 12. Что не менять без причины

- не переносить RTO HUD на `item_action`;
- не возвращать timed coordinate marker;
- не возвращать timed manual designation как ground marker;
- не смешивать zone cooldown и support cooldown в одном primary label;
- не выносить runtime-логику из `modular/rto_support` в апстрим без жёсткой необходимости.
