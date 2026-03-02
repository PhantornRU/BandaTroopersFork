# RTO Support: технический дизайн

## 1. Назначение

`RTO Support` реализует персональную систему вызова поддержки для роли `RTO` без привязки к singleton-runtime существующего `fire_support`.

Модуль держит:

- персональный controller на конкретного RTO;
- конфигурационные шаблоны поддержки;
- серверную валидацию;
- dispatch в свежие `datum/fire_support`;
- action-кнопки и таргетинг через отдельный RTO-бинокль.

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

## 3. Controller и runtime-контракты

Controller хранит:

- владельца;
- активный template;
- активный visibility zone;
- armed mode;
- общий cooldown пакета;
- личные cooldown способностей;
- ссылки на RTO action-кнопки.

Controller не должен содержать special-case branching под конкретные типы mortar. Все различия должны жить в конфигурации и `fire_support_path`.

## 4. RTO single-shot mortar

RTO не использует апстримовые многоснарядные mortar datums напрямую.

Модуль объявляет собственные подтипы:

- `/datum/fire_support/mortar/rto_single`
- `/datum/fire_support/mortar/smoke/rto_single`
- `/datum/fire_support/mortar/incendiary/rto_single`

Их ответственность:

- сохранить базовое поведение апстримового mortar типа;
- переопределить `impact_quantity = 1`;
- заменить announce-сообщения с barrage wording на single-round wording.

Почему так:

- апстримовый mortar остаётся неизменным для остальных систем;
- RTO получает отдельную продуктовую семантику;
- controller и dispatch не получают новую условную логику.

Action templates `mortar_*` должны ссылаться именно на эти module-local fire-support пути.

## 5. Zone и cooldown model

Runtime-модель кулдаунов остаётся data-driven:

- `visibility_zone_cooldown_until`
- `shared_cooldown_until`
- `action_cooldowns[action_id]`

Текущие zone timings:

- `Mortar`: `60s active / 35s recovery`
- `CAS`: `50s active / 95s recovery`
- `Heavy Strike`: `35s active / 140s recovery`
- `Logistics`: zones unsupported

Recovery зоны стартует после завершения или очистки зоны, а не в момент deploy.

## 6. Что не менять без причины

- не переносить RTO HUD на `item_action`;
- не возвращать timed coordinate marker;
- не возвращать timed manual designation как ground marker;
- не смешивать zone cooldown и support cooldown в одном primary label;
- не возвращать RTO mortar к `impact_quantity > 1`;
- не выносить runtime-логику из `modular/rto_support` в апстрим без жёсткой необходимости.
