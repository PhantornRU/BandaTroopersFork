# RTO Support: сопровождение и развитие

## 1. Цель документа

Документ описывает, как безопасно поддерживать и расширять `RTO Support` после текущей реализации.

Фокус:

- не сломать архитектуру;
- не вытащить логику из `modular/...`;
- не смешать UI, validation и dispatch;
- не потерять совместимость с апстримом.

## 2. Как добавлять новый пресет

Минимальный путь:

1. создать новый subtype `/datum/rto_support_template`;
2. создать нужные `/datum/rto_support_action_template`;
3. добавить новый template в `build_rto_support_template_catalog()`;
4. при необходимости добавить local payload в `code/fire_support/visibility_payloads.dm`.

Не нужно:

- переписывать controller;
- менять TGUI layout;
- добавлять string-switch по имени пакета.

## 3. Как добавлять новую способность

Минимальный путь:

1. описать новый `action_template`;
2. указать `fire_support_path`, cooldown, scatter и ограничения;
3. подключить action template к нужному preset template.

Если нужен особый backend:

- добавлять адаптацию в `dispatch_service`;
- не в action datum;
- не в TGUI;
- не в binocular item.

## 4. Как менять validation

Все серверные правила должны жить в:

- `modular/rto_support/code/services/validation_service.dm`

Если появляется новая карта, новый тип потолка или новое ограничение сектора, правка должна идти сюда.

Не нужно:

- дублировать validation в бинокле;
- дублировать validation в action-кнопке;
- переносить validation в frontend.

## 5. Как менять UI

Frontend-файл:

- `tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx`

Backend меню:

- `modular/rto_support/code/ui/preset_menu.dm`

DTO:

- `modular/rto_support/code/ui/ui_contracts.dm`

Связанные документы:

- `modular/rto_support/__docs/RTO_SUPPORT_PLAYER_GUIDE.md`
- `modular/rto_support/__docs/RTO_SUPPORT_BALANCE.md`

Если интерфейсу нужны новые поля, их добавляют сначала в DTO и backend-меню, а потом в JSX.

Не нужно:

- читать controller internals напрямую из TGUI;
- делать frontend authoritative по кулдаунам;
- привязывать JSX к конкретным типам DM-datum path.

## 6. Anti-patterns

### Controller-as-god-object

Плохой признак:

- controller начинает валидировать всё сам;
- строит TGUI payload вручную;
- dispatch-ит поддержку напрямую;
- хранит UI-only state.

### Singleton runtime reuse

Не переиспользовать один mutable `datum/fire_support` между игроками. Текущая реализация специально создаёт свежий экземпляр на каждый вызов.

### Upstream sprawl

Не выносить бизнес-логику в `code/...`, если модульный override или локальный adapter уже решают задачу.

### Preset string-switch

Не добавлять разветвления вида:

- `if(template_id == "mortar")`
- `switch(template_id)`

в core-runtime, если задача решается через subtype config datum.

## 7. Проверки после апстрим-синка

Проверить:

1. не изменились ли контракты `datum/action`;
2. не изменился ли binocular interaction flow;
3. не изменились ли пути gear preset и locker override для RTO;
4. не изменились ли `datum/fire_support` path и их expected behavior;
5. не изменились ли TGUI build requirements.

## 8. Базовые команды проверки

Из корня репозитория:

1. `tools\build\build.bat dm`
2. `tools\build\build.bat tgui-eslint`
3. `tools\build\build.bat tgui`

На текущем этапе именно эти проверки уже проходили на модуле без ошибок.

## 9. Checklist перед review

1. Новый код остался в `modular/rto_support/...`, если не было объективной причины идти в апстрим.
2. Controller не получил лишние обязанности.
3. Validation не создаёт side effects.
4. Dispatch не принимает решение “можно/нельзя”.
5. TGUI не знает о внутреннем хранении кулдаунов.
6. Все новые player-facing правила отражены в документации.
7. Если менялись численные параметры, обновлён `RTO_SUPPORT_BALANCE.md`.
8. Если менялся реальный пользовательский цикл, обновлён `RTO_SUPPORT_PLAYER_GUIDE.md`.

## 10. Известные точки роста

- реактивное обновление action-кнопок вместо секундного timer refresh;
- расширение под другие фракции;
- более явная визуализация радиуса сектора;
- дополнительные payload-типы для visibility zone.

Добавлять это стоит только если новая функциональность реально окупает рост сложности.
