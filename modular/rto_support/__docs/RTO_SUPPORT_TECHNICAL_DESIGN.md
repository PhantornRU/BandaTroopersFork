# RTO Support: технический дизайн

## 1. Цель технического документа

Этот документ фиксирует архитектурные решения, API-контракты и границы ответственности будущей runtime-системы `RTO Support`.

Документ нужен, чтобы следующий этап реализации:

- не превращал controller в `god object`;
- не смешивал immutable config и mutable runtime state;
- не привязал модуль к хрупким деталям текущего `fire_support`;
- не вынес бизнес-логику из `modular/...` без необходимости.

## 2. Архитектурные ограничения

Базовые ограничения:

1. Основная бизнес-логика должна жить в `modular/rto_support/...`.
2. Интеграция с апстримом должна быть минимальной и добавляться только после появления реальной потребности.
3. На текущем этапе skeleton не должен выполнять никакой игровой логики.
4. Контракты должны проектироваться так, чтобы новые пресеты и новые типы поддержки добавлялись расширением datums, а не переписыванием core-логики.

## 3. Почему текущие singleton `datum/fire_support` не подходят

Текущая fire support подсистема в проекте не должна быть базовой runtime-моделью для персонального `RTO`.

### 3.1. Причина: глобальный mutable state

Если один `datum/fire_support` используется как общий экземпляр, то runtime-поля вроде `cooldown_timer` перестают быть персональными.

Это создаёт риск:

- общих кулдаунов между разными RTO;
- трудноуловимых shared-state багов;
- утечки состояния между раундами и вызовами.

### 3.2. Причина: смешение config и runtime

Текущие `datum/fire_support` совмещают:

- конфигурацию удара;
- runtime-подготовку;
- визуальные и звуковые параметры;
- cooldown и прочие mutable-поля.

Это противоречит проектному требованию `RTO Support`, где config и runtime должны быть разделены.

### 3.3. Причина: GM semantics

Текущая fire support подсистема уже ориентирована на:

- глобальные toggles;
- фракционные очки;
- GM-управление;
- существующие предметные механики.

Будущий `RTO Support` должен иметь собственную персональную модель доступа и кулдаунов.

### 3.4. Вывод

`datum/fire_support` допустимо использовать только как исполнительный backend через adapter/service-слой.

Решение о точном адаптере:

`Откладывается до runtime-этапа`.

## 4. Слои системы

### 4.1. Configuration layer

Содержит только неизменяемые описания:

- пресеты поддержки;
- описания способностей;
- metadata для UI.

Этот слой:

- не знает про владельца;
- не хранит кулдауны;
- не знает про active zone;
- не запускает поддержку.

### 4.2. Runtime layer

Содержит состояние конкретного оператора:

- controller;
- active visibility zone;
- текущий armed mode;
- runtime request;
- validation;
- dispatch.

Этот слой:

- знает владельца и мир;
- может проверять состояние;
- может собирать request;
- не должен протекать в UI напрямую.

## 5. Основные типы и обязанности

### `/datum/modpack/rto_support`

Ответственность:

- регистрация модпака;
- безопасная инициализация модуля без side effects.

Не должен:

- создавать контроллеры сам по себе;
- запускать runtime механику;
- выполнять интеграцию с ролью.

### `/datum/rto_support_controller`

Ответственность:

- orchestration runtime-потока одного владельца;
- управление выбранным template;
- управление active zone;
- управление armed mode;
- подготовка request;
- вызов validation и dispatch.

Не должен:

- содержать TGUI-логику;
- напрямую вызывать конкретный `datum/fire_support`;
- становиться хранилищем UI-состояния.

### `/datum/rto_support_registry`

Ответственность:

- хранение и поиск controller по owner;
- выдача контроллера через public API;
- безопасное удаление.

Не должен:

- валидировать таргет;
- выбирать пресет;
- диспетчеризовать поддержку.

### `/datum/rto_support_template`

Ответственность:

- immutable config пресета;
- описание сектора;
- список action templates;
- metadata для выбора.

Не должен:

- хранить runtime-состояние;
- зависеть от `world.time`;
- знать конкретного владельца.

### `/datum/rto_support_action_template`

Ответственность:

- immutable config одной способности;
- описание ограничений способности;
- metadata для будущей action-кнопки.

Не должен:

- хранить кулдауны игрока;
- решать, можно ли вызвать поддержку;
- запускать payload сам по себе.

### `/datum/rto_visibility_zone`

Ответственность:

- runtime-представление сектора наведения;
- хранение центра, радиуса и времени жизни сектора.

Не должен:

- знать про UI;
- выбирать payload;
- знать список action-кнопок.

### `/datum/rto_support_request`

Ответственность:

- быть transport-объектом между controller и dispatch service;
- хранить уже подготовленный контекст вызова.

Не должен:

- принимать проектные решения;
- запускать поддержку сам по себе;
- подменять validation layer.

### `/datum/rto_support_validation_service`

Ответственность:

- проверка правил допуска;
- валидация deploy zone;
- валидация support call.

Не должен:

- менять runtime-состояние игрока;
- исполнять dispatch;
- строить UI-сообщения в терминах конкретного интерфейса.

### `/datum/rto_support_dispatch_service`

Ответственность:

- перевод подготовленного request в фактическое исполнение поддержки.

Не должен:

- решать, разрешён ли вызов;
- выбирать template;
- управлять armed mode.

### UI DTO

Ответственность:

- перенос предвычисленных данных в будущий интерфейсный слой.

Не должны:

- читать runtime internals напрямую;
- хранить world-state;
- содержать побочные эффекты.

## 6. Карта файлов skeleton

Ниже фиксируется назначение текущего skeleton-каркаса.

- `modular/rto_support/code/modpack.dm`
  Регистрация модпака.
- `modular/rto_support/code/api/public_api.dm`
  Стабильная точка доступа к controller через proc.
- `modular/rto_support/code/controller/controller.dm`
  Контракт будущего runtime-controller.
- `modular/rto_support/code/controller/registry.dm`
  Контракт будущего registry.
- `modular/rto_support/code/config/template.dm`
  Базовый config пресета.
- `modular/rto_support/code/config/action_template.dm`
  Базовый config способности.
- `modular/rto_support/code/runtime/visibility_zone.dm`
  Runtime-объект сектора наведения.
- `modular/rto_support/code/runtime/request.dm`
  DTO подготовленного support request.
- `modular/rto_support/code/services/dispatch_service.dm`
  Adapter/service для исполнения.
- `modular/rto_support/code/services/validation_service.dm`
  Service для проверок.
- `modular/rto_support/code/ui/ui_contracts.dm`
  UI DTO и interface contracts.

## 7. Контракты будущих API

### 7.1. Public API

- `/proc/get_rto_support_controller(mob/living/carbon/human/human)`
- `/proc/ensure_rto_support_controller(mob/living/carbon/human/human)`
- `/proc/remove_rto_support_controller(mob/living/carbon/human/human)`

Назначение:

- изолировать будущие callsites от деталей хранения controller;
- не заставлять интеграционные точки работать с registry напрямую.

### 7.2. Controller API

- `get_available_templates()`
- `can_select_template()`
- `select_template(template_type)`
- `get_active_template()`
- `get_action_templates()`
- `get_active_zone()`
- `can_deploy_zone()`
- `deploy_zone(turf/target_turf)`
- `can_arm_action(action_id)`
- `arm_action(action_id)`
- `disarm_action()`
- `handle_binocular_target(turf/target_turf, mob/living/carbon/human/user)`
- `build_preset_ui_data()`

Назначение:

- держать orchestration внутри controller;
- не разносить продуктовый поток по action datum, предмету и UI.

### 7.3. Validation API

- `validate_zone_deploy(...)`
- `validate_support_call(...)`

Назначение:

- централизовать правила допуска;
- не дублировать проверки между разными callsites.

### 7.4. Dispatch API

- `dispatch_request(datum/rto_support_request/request)`

Назначение:

- изолировать способ исполнения поддержки;
- допустить замену backend без переписывания controller.

## 8. Поток данных будущего runtime

### 8.1. Спавн и инициализация

1. Интеграционный слой определяет, что моб является корректным владельцем `RTO Support`.
2. Через public API создается или получается controller.
3. Controller стартует без выбранного template.

### 8.2. Выбор пресета

1. UI открывает список templates.
2. Controller получает `template_type`.
3. Controller проверяет возможность выбора.
4. Controller фиксирует выбранный template.
5. UI и action layer обновляют отображение.

### 8.3. Armed mode

1. Игрок активирует действие сектора или конкретной способности.
2. Controller переводится в armed state.
3. Бинокль становится транспортом следующего валидного таргета.

### 8.4. Передача цели

1. Бинокль передает target turf в controller.
2. Controller определяет контекст armed action.
3. Controller либо разворачивает сектор, либо собирает support request.

### 8.5. Validation

Controller обращается к validation service.

Validation проверяет:

- owner state;
- наличие и использование бинокля;
- line of sight;
- существование и радиус сектора;
- ограничения типа способности;
- кулдауны.

### 8.6. Request assembly

Если validation пройдена:

1. Controller создает `datum/rto_support_request`.
2. Request содержит только подготовленные данные и не принимает собственных решений.

### 8.7. Dispatch

1. Controller передает request в dispatch service.
2. Dispatch service исполняет запрос через backend.
3. Controller получает результат и обновляет своё runtime-состояние.

## 9. Правила валидации

### 9.1. Выбор template

- template выбирается один раз на жизнь моба;
- template доступен только корректному owner;
- template selection не должна жить в UI как источник истины.

### 9.2. Наличие бинокля

- вызов сектора и поддержки невозможен без корректного RTO-бинокля;
- наличие action-кнопки не является достаточным условием.

### 9.3. Использование бинокля

- target считается валидным только в контексте реального использования бинокля;
- произвольный world-click не должен считаться целеуказанием.

### 9.4. Линия видимости

- target без LOS невалиден;
- LOS должна проверяться в validation layer, а не в UI.

### 9.5. Правила сектора

- поддержка вызывается только в активном секторе;
- радиус сектора трактуется как runtime-правило;
- у владельца одновременно существует только один active zone.

### 9.6. Ограничения типа поддержки

- авиация и heavy strike должны учитывать потолок и иные пространственные ограничения;
- правила должны вытекать из action template, а не из UI имени кнопки.

### 9.7. Кулдауны

- общий кулдаун и персональный кулдаун способности проверяются независимо;
- UI не является источником истины по cooldown;
- структура хранения временных меток:

`Откладывается до runtime-этапа`.

## 10. OOP и SOLID

### 10.1. Single Responsibility

Каждый datum отвечает только за один тип задач:

- config;
- runtime orchestration;
- validation;
- dispatch;
- UI transport.

### 10.2. Open/Closed

Новые пресеты и новые способности должны добавляться новыми datums и metadata, а не через переписывание controller.

### 10.3. Liskov

Любой специализированный template или action template должен сохранять базовый контракт:

- может быть прочитан как config;
- может участвовать в validation;
- может отдавать metadata без знания частной реализации consumer-ом.

### 10.4. Interface Segregation

Нельзя делать один широкий API для:

- UI;
- cooldown;
- таргетинга;
- dispatch;
- валидации.

### 10.5. Dependency Inversion

Controller должен зависеть от абстракций config/service-слоя, а не от:

- конкретного TGUI;
- конкретного backend fire support;
- конкретного singleton объекта поддержки.

## 11. Соответствие `SS220_DEVELOPMENT_RULES`

Текущая структура документа и skeleton-а соответствует правилам:

1. Бизнес-логика проектируется в `modular/rto_support`.
2. В `code/...` не добавляется новая предметная логика.
3. Интеграционные точки пока не добавляются заранее.
4. Документация явно ограничивает scope и запрещает преждевременное смешение слоев.

## 12. Отложенные технические решения

Ниже решения, которые нельзя фиксировать окончательно до реальной runtime-интеграции:

- точный adapter к существующим `datum/fire_support`;
- точная форма validation result;
- способ хранения cooldown timestamps;
- перечень интеграционных точек в loadout и binocular callsites;
- критерии выбора final backend для исполнения support request.

Для всех этих пунктов действует пометка:

`Откладывается до runtime-этапа`.
