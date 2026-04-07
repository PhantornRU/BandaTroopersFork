# RTO Support: сопровождение

## 1. Что важно не сломать

При любых изменениях сохранять следующие инварианты:

- RTO HUD остается `human_action`-based;
- controller владеет lifecycle action'ов;
- actions скрываются, если бинокль не в руке;
- `Координаты` и `Лазерная отметка` не получают cooldown;
- `Координаты` не рисуют лазер;
- `Лазерная отметка` остается live binocular laser, а не timed world marker;
- `select_preset` остается доступным и после первого выбора пакета;
- RTO может держать до `2` уникальных пакетов одновременно;
- reset слотов всегда полный и открывается через `60 минут` от первого выбора;
- `shared support cooldown` считается по пакету, а не глобально по всем пакетам;
- одновременно может существовать только один активный сектор;
- zone-based actions работают только через сектор своего пакета;
- `visibility_zone_cooldown` и `shared support cooldown` не смешиваются в один UI-state;
- solo-бонус на cooldown сектора применяется только если выбран ровно один zone-based пакет;
- `RTO sling pouch` остается жестко спаренным с одним биноклем.

## 2. Ключевые файлы

Runtime:

- `modular/rto_support/code/controller/controller.dm`
- `modular/rto_support/code/services/validation_service.dm`
- `modular/rto_support/code/services/dispatch_service.dm`

Интерфейс:

- `modular/rto_support/code/actions/rto_actions.dm`
- `modular/rto_support/code/items/rto_binoculars.dm`
- `modular/rto_support/code/ui/preset_menu.dm`
- `tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx`

Конфиг:

- `modular/rto_support/code/config/templates/**`
- `modular/rto_support/code/config/action_templates/**`
- `modular/rto_support/code/fire_support/uscm_support_payloads.dm`

Выдача комплекта:

- `modular/rto_support/code/items/rto_sling_pouch.dm`
- `modular/rto_support/code/job/rto_integration.dm`
- `modular/halo/code/modules/gear_presets/Halo/unsc_marines.dm`
- `modular/squads/code/closets/halo_marine_personal.dm`

## 3. Как безопасно менять HUD

Если меняешь action-кнопки:

- не переводить их на `item_action` без отдельного архитектурного решения;
- не удалять и не пересоздавать их на каждый hand swap;
- использовать `hide_from()` / `unhide_from()`;
- не вычислять cooldown UI вручную в action datum, если это уже делает controller state builder;
- сохранять стабильный порядок handles: preset -> visibility -> utility -> support.

## 4. Как безопасно менять выбор пакетов

Если меняется preset-flow:

- не возвращать старую модель одного активного пакета;
- не разрешать дубликаты;
- не вводить частичный reset одного слота, если это не отдельная осознанная фича;
- не прятать информацию про `solo zone cooldown bonus` от игрока;
- помнить, что `UNSC`, `ODST` и `USCM` имеют разные наборы доступных пакетов.

## 5. Как безопасно менять zone model

Если меняется сектор:

- оставлять один активный сектор на controller;
- сохранять общий zone cooldown отдельно от личного zone cooldown пакета;
- не разрешать support ability использовать чужой сектор;
- применять cooldown сектора через `get_effective_visibility_zone_cooldown()`, а не напрямую через конфиг;
- помнить, что при одном выбранном боевом пакете cooldown сектора должен быть в `2 раза` меньше.

## 6. Как безопасно менять cooldown UI

Support button должен разделять:

- состояние сектора;
- общий cooldown пакета;
- личный cooldown способности.

Не допускается возвращать старое поведение, где:

- recovery сектора выглядит как общий cooldown support ability;
- visibility action показывает cooldown support ability;
- solo-бонус существует только в runtime, но не объясняется в preset menu/examine.

Если меняется UI-модель, менять сначала controller state builder и UI DTO, а не размазывать условия по action-классам.

## 7. Как безопасно менять sling pouch

`RTO sling pouch` это не generic storage pouch.

Не ломать:

- привязку `paired_pouch <-> paired_binocular`;
- запрет на чужие предметы;
- запрет на ручной unsling;
- возврат бинокля в pouch при drop flow.

Если меняется `drop_retrieval` или storage API, первым делом перепроверять именно этот комплект.

## 8. Checklist после правок

1. Взять бинокль в руку: кнопки появились.
2. Убрать бинокль из рук: кнопки скрылись.
3. `Выбрать пакеты поддержки` открывает меню и после первого выбора.
4. Один пакет можно выбрать без второго; duplicate и третий пакет недоступны.
5. Reset обоих слотов закрыт до таймера и открывается после него.
6. При одном выбранном боевом пакете menu/examine явно показывают solo-бонус на сектор.
7. При выборе второго пакета solo-бонус пропадает и UI это отражает.
8. `Logistics`, `Medical`, `Technical` не показывают кнопку сектора.
9. Visibility action не показывает shared cooldown поддержки.
10. Zone-based support actions показывают сектор и cooldown'ы раздельно.
11. Locker и equipped RTO получают `pouch + binocular`, а не loose binocular.
12. `USCM RTO` сохраняет `spotter` trait.

## 9. Проверки сборки

Минимум:

1. `tools/build/build dm -DCIBUILDING -DANSICOLORS -Werror`

Если были правки фронтенда:

2. `tools/build/build tgui-eslint`
3. `tools/build/build tgui`
