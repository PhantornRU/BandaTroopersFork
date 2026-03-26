# Game Rule Panel

## Цель

`Game Rule Panel` — отдельная админская панель для runtime-настройки правил `RTO Support`, `Fire Support` и `Player Survival` в текущем раунде.

## Кто использует

- Game Master
- Администраторы с правами `R_ADMIN`

## Область действия

- Все изменения применяются сразу в текущем раунде.
- Настройки не сохраняются между рестартами, сменами карты и новыми раундами.

## Что можно менять

### Вкладка RTO Support

- Глобально включать и отключать `RTO Support`.
- Менять общий множитель `shared cooldown`.
- Менять локальный множитель `personal cooldown`.
- Сбрасывать RTO-настройки к значениям по умолчанию.

### Вкладка Fire Support

- Глобально включать и отключать `Fire Support`.
- Выдавать очки поддержки по фракциям.
- Включать и выключать отдельные типы Fire Support.
- Сбрасывать Fire Support-настройки к значениям по умолчанию.

### Вкладка Player Survival

- Включать и отключать `Save Before Death`.
- Менять `Critical Grace Duration (seconds)` для окна выживания после входа в hardcrit.
- Включать и отключать `Anti-Gib Fallback`.
- Менять `Anti-Gib Limb Loss Chance (%)`.
- Сбрасывать Player Survival-настройки к значениям по умолчанию.

## Мгновенные и отложенные эффекты

Изменяется сразу:

- Глобальная доступность `RTO Support`.
- Глобальная доступность `Fire Support`.
- Списки включенных и выключенных типов `Fire Support`.
- Количество выданных очков `Fire Support`.

Применяется только к будущим вызовам:

- Новые `shared cooldown` у RTO-абилок.
- Новые `personal cooldown` у RTO-абилок.

Не пересчитывается задним числом:

- Уже идущие RTO-кулдауны.
- Уже идущие Fire Support-кулдауны.
- `Visibility Zone cooldown` у RTO.

Применяется сразу для Player Survival:

- `Save Before Death` сразу отключает и включает damage-block логику crit grace.
- `Anti-Gib Fallback` сразу отключает и включает anti-gib fallback.
- Новый `Critical Grace Duration` применяется только к будущим срабатываниям crit grace.
- Новый `Anti-Gib Limb Loss Chance` применяется только к будущим anti-gib fallback.

## Поведение RTO Support при отключении

Если `RTO Support` отключен:

- `Coordinates` остаются доступными.
- `Manual Marker` остается доступным.
- Выбор пресета становится недоступным.
- `Visibility Zone` и strike/support-абилки становятся недоступными.
- Если у RTO был активный сектор, он снимается без постановки нового sector cooldown.
- Если у RTO была armed strike- или sector-абилка, она сбрасывается.
- Уже отправленные запросы поддержки не отменяются.
- При повторном включении ранее выбранный пресет сохраняется.

## Поведение Fire Support

- У `Fire Support` есть master-toggle на уровне Game Rule Panel.
- Этот toggle не переписывает индивидуальные `FIRESUPPORT_AVAILABLE` флаги на самих типах поддержки.
- Индивидуальная доступность конкретных support-типов продолжает храниться отдельно.
- Очки поддержки остаются фракционными.
- Выдача очков работает аддитивно, а не как установка абсолютного значения.

Если `Fire Support` отключен глобально:

- Бинокли не могут вызывать поддержку.
- Состав списков `Enabled` и `Disabled` не меняется.
- Текущие points не меняются.
- Текущие индивидуальные cooldown'ы не сбрасываются.

## Поведение Player Survival

- `Save Before Death` и `Anti-Gib Fallback` — независимые toggles.
- Если `Save Before Death` выключен, активный `damage block` перестает работать сразу, даже если его таймер еще не истек.
- Если `Anti-Gib Fallback` выключен, механика из коммита `8b0c14ddeb925bd420497e5447d4107018d6fdbe` больше не перехватывает `gib` и взрывной anti-gib fallback.
- Если `Save Before Death` выключен, но `Anti-Gib Fallback` включен:
  - моб все еще может пережить anti-gib fallback;
  - crit grace при этом не включается.
- `Reset` для Player Survival возвращает `Save Before Death = ON`, `Critical Grace Duration = 15`, `Anti-Gib Fallback = ON`, `Anti-Gib Limb Loss Chance = 30`.

## Ограничения v1

- Вкладка `Fire Support` общая и не разбита на отдельные faction-tabs.
- `Reset` для Fire Support возвращает состояние к первому снапшоту, зафиксированному при первом использовании панели в раунде.
- Legacy admin verbs и старое `Fire Support Menu` остаются доступны и не удаляются.
