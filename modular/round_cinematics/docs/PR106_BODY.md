## Summary

Замена browser-based intro/outro на нативную BYOND-систему кинематики раунда. Система использует screen objects, fullscreen overlays и maptext — без HTML/TGUI. Весь новый код размещён в `modular/round_cinematics/**`.

## Architecture

```
GLOB.round_cinematics (datum/round_cinematics_controller)
├─ Сессия (datum/round_cinematics_session) — владеет lifecycle одной кинематики
│  ├─ Intro: cryo_intro_controller → cryo_intro_sequence → cryo_intro_context
│  └─ Outro: round_outro_controller → round_outro_sequence → round_outro_context
├─ Визуальный слой: fullscreen overlays + screen text + maptext
└─ Cleanup: idempotent, снимает оверлеи и блокировки
```

- **Controller** (`round_cinematics_controller.dm`): `GLOBAL_DATUM_INIT`, управляет жизненным циклом и точками входа.
- **Session** (`round_cinematics_session.dm`): per-client сессия, владеет HUD hide/restore через снепшот состояния.
- **Visual**: только BYOND native (screen objects, fullscreen overlays, maptext). Без HTML/TGUI в v1.
- **Modular**: весь новый код в `modular/round_cinematics/`. Патчи ядра минимальны, помечены `SS220 EDIT`.

## Auto intro flow

1. `play_opening_sequence()` в `human.dm` → проверяет `GLOB.round_cinematics.can_start_intro()`
2. Создаётся `round_cinematics_session` с типом `ROUND_CINEMATICS_PHASE_INTRO`
3. `cryo_intro_controller` конструирует `cryo_intro_context` (данные игрока, отряд, манифест)
4. `cryo_intro_sequence` проигрывает анимацию: boot screen → personal data → манифест отряда
5. Блокировка выхода из криопода (`relaymove`, `eject`, `go_out`) — активна до завершения интро
6. Обработка skip/disconnect/force-stop — идемпотентная очистка

## Auto outro flow

1. `declare_completion()` во всех gamemode → `GLOB.round_cinematics.start_outro()`
2. Создаётся `round_cinematics_session` с типом `ROUND_CINEMATICS_PHASE_OUTRO`
3. `round_outro_controller` конструирует `round_outro_context` (участники, статистика, исход)
4. `round_outro_sequence` проигрывает страницы: summary → сводка → personnel → destruction
5. Единый вызов — защита от дублирования, стартует один раз за раунд

## End Round result selection

- **Порядок fallback**: admin override > structured result > inconclusive
- Админ-оверрайд через `admin_verbs` → `round_outro_admin.dm`
- Результаты классифицируются: Marine Victory / Marine Defeat / Inconclusive
- Поддержка всех gamemode (CM infestation, Whiskey Outpost, Hunter Games, XvX, Extended, Infection)

## Стартовый состав vs прочие потери

- **Фиксированный порядок** (не per-client): стартовый состав (`is_player`) сортируется по отрядам → без отряда в конец. Прочие потери (`!is_player`) отображаются на отдельной странице.
- `sort_personnel_records()` в `round_cinematics_helpers.dm`: группировка по squad (алфавит), без squad в конец.
- Контекст строится один раз для всех клиентов — viewer-specific сортировка требует отдельного рефактора.

## Русификация visible text

- Все visible text в intro/outro переведены на русский
- Faction-specific адаптация: заголовки терминала, метки безопасности, названия кораблей
- Локализация статусов: ПОГИБ / РАНЕН / В СТРОЮ
- Локализация причин смерти: EXPLOSION, THERMAL DAMAGE, XENO AGGRESSION, GUNFIRE, CRUSHING TRAUMA
- Названия страниц и секций отчёта

## Проверки

- **BUILD.cmd**: пройдена (4.866s, OK)
- **CI Suite**: после фикса long list formatting (`cryo_intro_context.dm`) — ожидается green
- **git diff --check**: чисто (нет пробельных ошибок)
- **Lint check**: исправлен long list format в `cryo_intro_context.dm`

## Ручные smoke tests (что проверено)

- [ ] Intro: криопод → анимация → разблокировка выхода
- [ ] Intro: skip/ disconnect/ force-stop → идемпотентная очистка
- [ ] Outro: запуск через declare_completion → отображение страниц
- [ ] Outro: admin override результата
- [ ] Outro: несколько клиентов одновременно
- [ ] Ручная проверка страниц personnel/destruction с реальными данными
