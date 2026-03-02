# RTO Support: технический дизайн

## 1. Цель документа

Документ фиксирует реальную архитектуру модуля `RTO Support`, его границы ответственности и точки расширения.

Это рабочая спецификация для разработки, code review и сопровождения. Она описывает уже реализованную модель, а не только целевую идею.

## 2. Архитектурная модель

Система разделена на четыре слоя:

1. `Configuration layer`
   Пресеты и action templates.
2. `Runtime orchestration layer`
   Контроллер игрока, активный сектор, armed mode, кулдауны и action lifecycle.
3. `Validation and dispatch layer`
   Проверка правил и адаптация request к существующим `datum/fire_support`.
4. `Interface layer`
   TGUI меню пресетов, action-кнопки и бинокль как транспорт таргетинга.

Такое разбиение держит `Single Responsibility` и не допускает превращения контроллера в `god object`.

## 3. Почему не используется singleton-модель fire support

Текущие `datum/fire_support` в апстриме удобны как payload-исполнители, но непригодны как runtime-состояние конкретного RTO:

- у них есть mutable state, например `cooldown_timer`;
- они спроектированы вокруг глобальной экономики и GM semantics;
- reuse одного экземпляра между игроками создаёт shared-state баги.

Поэтому модуль делает иначе:

- controller хранит персональные кулдауны и armed state;
- dispatch создаёт свежий `datum/fire_support` на каждый вызов;
- экземпляр удаляется отложенно через `QDEL_IN`, чтобы не утекать как singleton.

Это ключевое архитектурное решение. Менять его без явной причины не стоит.

## 4. Основные datums и ответственности

### `/datum/rto_support_controller`

Отвечает за:

- выбранный пресет;
- активный сектор;
- общий и персональные кулдауны;
- armed mode;
- lifecycle action-кнопок;
- сборку request и оркестрацию вызова.

Не отвечает за:

- низкоуровневый dispatch payload;
- правила LOS, потолков и доступности;
- TGUI layout.

### `/datum/rto_support_registry`

Отвечает за:

- поиск и создание контроллера по `mob/living/carbon/human`;
- очистку контроллера при удалении владельца;
- выдачу controller через public API.

Контроллер создаётся только для `JOB_SQUAD_RTO`.

### `/datum/rto_support_template`

Immutable-конфиг пресета:

- id;
- название и описание;
- параметры сектора;
- список action templates;
- optional visibility payload.

### `/datum/rto_support_action_template`

Immutable-конфиг способности:

- stable `action_id`;
- отображаемое имя и описание;
- `scatter`;
- `shared_cooldown`;
- `personal_cooldown`;
- требования к сектору и потолку;
- `fire_support_path`.

### `/datum/rto_visibility_zone`

Runtime-объект сектора:

- центр;
- радиус;
- абсолютное время истечения;
- центральный marker overlay.

Сейчас сектор показывает только центральную метку. Радиус проверяется серверно.

### `/datum/rto_support_request`

DTO между controller и dispatch:

- владелец;
- target turf;
- template;
- action template;
- visibility zone;
- dispatch path;
- display name;
- request kind.

### `/datum/rto_support_validation_service`

Отвечает за серверные проверки:

- наличие пресета;
- наличие и активное использование RTO-бинокля;
- incapacitation;
- LOS;
- shipside restrictions;
- радиус сектора;
- altitude restrictions;
- кулдауны.

### `/datum/rto_support_dispatch_service`

Отвечает только за выполнение уже валидированного request:

- создание нового `datum/fire_support`;
- настройку `faction`, `name`, `scatter_range`;
- запуск payload;
- ghost notification для ударных вызовов;
- cleanup request-local экземпляра.

Dispatch не решает, можно вызывать поддержку или нет.

## 5. Реальный runtime-flow

### 5.1. Инициализация роли

Контроллер создаётся двумя путями:

- основным: через модульные override `load_gear()` для RTO;
- запасным: lazy-init через `ensure_rto_support_controller()` из RTO-бинокля.

Это уменьшает риск потери контроллера, если предмет выдан нестандартно или персонаж получен вне обычной ветки экипировки.

### 5.2. Выбор пресета

Пока пресет не выбран:

- у RTO есть только action `select_preset`;
- TGUI показывает список доступных шаблонов;
- после выбора пресет фиксируется на жизнь текущего моба.

После выбора:

- кнопка выбора удаляется;
- появляются action сектора и action способностей пакета.

### 5.3. Armed mode

Action-кнопка не вызывает поддержку напрямую.

Она только переводит controller в armed state:

- `RTO_SUPPORT_ARM_VISIBILITY_ZONE` для сектора;
- `action_id` способности для удара.

Следующий `Ctrl+Click` через активный бинокль завершает таргетинг.

### 5.4. Таргетинг

Точка выбирается только через `/obj/item/device/binoculars/rto`.

Бинокль:

- работает только через zoom/interact flow;
- без armed state показывает координаты;
- с armed state передаёт turf в controller.

### 5.5. Валидация и вызов

Controller:

1. получает turf из бинокля;
2. вызывает validation service;
3. при успехе собирает `rto_support_request`;
4. отправляет request в dispatch service;
5. обновляет кулдауны и armed state.

## 6. Реализованные интеграции

### Loadout

Модуль переопределяет:

- `/datum/equipment_preset/uscm/rto/load_gear`
- `/datum/equipment_preset/uscm/rto/equipped/load_gear`

Что делает интеграция:

- сохраняет trait `spotter`;
- выдаёт `RTO binoculars` вместо designator;
- гарантирует наличие controller.

### Locker

Переопределён:

- `/obj/structure/closet/secure_closet/marine_personal/rto/spawn_gear`

Что выдаётся:

- `RTO binoculars`;
- две коробки сигнальных фальшфейеров.

### TGUI

Добавлены:

- `/datum/rto_support_preset_menu`
- `tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx`

### Runtime support payload

Добавлен локальный payload:

- `/datum/fire_support/rto_visibility/illumination`

Он нужен для mortar-sector и не зависит от GM menu.

## 7. OOP и SOLID в текущей реализации

### Single Responsibility

- template datums не знают про runtime;
- validation не dispatch-ит;
- dispatch не валидирует;
- UI меню не содержит боевую логику;
- бинокль только получает цель и делегирует controller.

### Open/Closed

Новый пресет добавляется расширением config-слоя:

- новый subtype `rto_support_template`;
- новые `rto_support_action_template`;
- при необходимости новый local payload.

Controller и TGUI не должны переписываться под каждый новый пакет.

### Dependency Inversion

Controller зависит от:

- config datums;
- validation service;
- dispatch service.

Он не зависит напрямую от конкретной реализации `datum/fire_support`.

## 8. Известные ограничения

- Один сектор на оператора.
- Нет world-overlay радиуса сектора.
- Dispatch сейчас ориентирован на marine faction flow.
- Нет отдельного recovery flow для нештатной смены роли после спавна.
- Кнопки обновляются таймером раз в секунду, а не реактивной системой событий.

Эти ограничения допустимы на текущем этапе и не ломают модель ответственности.

## 9. Что не делать дальше

- Не переносить controller-логику в `code/...`.
- Не читать внутренние списки кулдаунов напрямую из TGUI.
- Не вызывать `datum/fire_support` напрямую из action datum.
- Не вводить string-switch по имени пресета в core-flow.
- Не превращать validation service в место side effects.
