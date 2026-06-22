# BandaTroopers: план реализации модульных интро и аутро

**Назначение документа:** рабочее ТЗ и пошаговый план для ИИ-агентов/Codex по переработке серии PR с интро/аутро в поддерживаемую модульную систему BandaTroopers.

**Цель:** на основе идей из PR `#29`, `#31`, `#41`, `#42` собрать новую реализацию красивого крио-интро и round-outro без прямого переноса старого архитектурного долга.

**Ключевое решение:** не мержить старые PR как есть. Использовать их как UX/контент-референсы, а код собрать заново в `modular/**` с минимальными upstream hooks.

---

## 1. Контекст и исходные PR

### 1.1. PR-источники

| PR | Название | Использовать как | Что взять | Что не переносить напрямую |
|---:|---|---|---|---|
| `#29` | `[TM]Интро пробуждения` | UX-прототип личного дела | Идею системного приветствия, личного дела, имени, звания, отряда, специализации, состава отряда | HTML-файл как основной UI, прямую интеграцию через `login.dm`, крупный diff вне `modular/**` |
| `#31` | `New Intro` | Исторический вывод | Вывод автора: HTML/browser-подход оказался проблемным для BYOND/игрового окружения | Повторную ставку на HTML как основной cinematic layer |
| `#41` | `[TM]Интро` | UX-прототип крио-интро | Многофазность, динамический текст, звуки, скрытие HUD, блокировку раннего выхода из крио, манифест отряда | Глубокие правки `human.dm`, `hud.dm`, `action.dm`, хранение большого состояния на human |
| `#42` | `[ТМ] Интро + Аутро` | UX-прототип аутро | Военный отчёт, fade/scroll, статусы бойцов, причины смерти, классификацию исхода, admin override | Смешанный PR с интро+аутро+HUD+tgui, прямое изменение `AlertModal.tsx` без доказанной необходимости |

### 1.2. Принцип переноса

Старые PR рассматривать как **референсы поведения и визуального результата**, а не как кодовую базу.

Агентам запрещено:

- просто cherry-pick старых PR;
- тащить HTML-интро из `#29/#31` как основной UI;
- переписывать upstream HUD/action/TGUI pipeline без отдельного discovery и доказанной необходимости;
- смешивать intro, outro, admin UI и TGUI-правки в один нечитаемый diff;
- оставлять состояние cinematic без cleanup.

---

## 2. Репозиторные ограничения, обязательные для агентов

### 2.1. Discovery first

Перед любыми правками агент обязан сузить область кода через `rg`.

Минимальные discovery-команды:

```bash
rg -n "cryo|cryopod|Cryo|wake|login|latejoin|play_opening_sequence|opening_sequence|manifest" code modular
rg -n "round_end|end_round|announce_ending|declare_completion|ticker|mode_result|round_result|game over" code modular
rg -n "client\.screen|screen_loc|maptext|fullscreen|AlertModal|hud_used|no_hud|action button|actions" code modular tgui
rg -n "#include.*modular|modular\.dme|round_outro|fullscreen" colonialmarines.dme modular -g "*.dme"
rg -n "SS220 EDIT" code map_config modular -g "!modular/__agents/**" -g "!modular/__docs/**"
```

После discovery агент должен записать краткий inventory:

```md
## Discovery inventory
- Current cryo entrypoints:
  - <file>:<line> <proc/type>
- Current round-end entrypoints:
  - <file>:<line> <proc/type>
- Existing fullscreen/maptext helpers:
  - <file>:<line> <proc/type>
- Existing modular include path:
  - <file>:<line>
- Existing signals/hooks usable without upstream edit:
  - <file>:<line>
- Upstream edits unavoidable:
  - <file>:<line> <reason>
```

Если discovery не проведён, реализация считается невалидной.

### 2.2. Модульность

Новая бизнес-логика должна жить в:

```text
modular/round_cinematics/**
```

Upstream `code/**` используется только для минимального glue:

- вызов модульного hook;
- безопасный fallback;
- маленькая точка интеграции;
- `SS220 EDIT`-маркер там, где это сопровождаемый upstream diff.

Запрещено помещать основную cinematic-логику в:

```text
code/modules/mob/living/carbon/human/human.dm
code/game/machinery/cryopod.dm
code/_onclick/hud/hud.dm
code/datums/action.dm
```

Эти файлы можно трогать только для точечных hooks после discovery.

### 2.3. `SS220 EDIT`

Если меняется upstream-файл вне `modular/**`, правка должна быть минимальной и размеченной.

Однострочный пример:

```dm
SSround_cinematics?.try_start_cryo_intro(src) // SS220 EDIT: delegate cryo intro to modular cinematic controller
```

Блочный пример:

```dm
// SS220 EDIT - START
if(SSround_cinematics?.handle_cryo_exit_attempt(src, user))
	return
// SS220 EDIT - END
```

Нельзя использовать `SS220 EDIT` как оправдание для крупного рефактора upstream.

### 2.4. Проверки

Минимум для DM/code changes:

```bash
git diff --check
BUILD.cmd
```

Или CI-эквивалент:

```bash
tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror
```

Если трогается TGUI:

```bash
tools/build/build --ci lint tgui-test
```

Если трогаются DMI/assets:

```bash
tools/bootstrap/python -m dmi.test
```

Map checks не нужны, если не меняются карты, map config или map-sensitive compile matrix.

---

## 3. Целевой пользовательский результат

### 3.1. Крио-интро

При пробуждении игрока из крио:

1. Игрок получает fullscreen/screen overlay.
2. Лишний HUD временно скрыт или перекрыт cinematic overlay.
3. Игрок видит короткий boot/wake-up протокол.
4. Показывается личное дело:
   - имя;
   - звание;
   - роль/специализация;
   - отряд;
   - назначение/операционный статус.
5. Показывается манифест отряда:
   - бойцы того же отряда;
   - звание;
   - роль;
   - статус, если доступен.
6. Проигрываются короткие звуковые сигналы, если assets доступны и лицензированно допустимы.
7. После завершения overlay очищается, HUD возвращается, крио разблокируется.

Длительность по умолчанию:

```text
Минимум до skip: 5 секунд
Обычная длительность: 8–15 секунд
Жёсткий timeout: 20 секунд
```

### 3.2. Round-outro

В конце раунда игроки получают военный отчёт:

1. Тёмный экран / fade.
2. Заголовок отчёта операции.
3. Классификация исхода:
   - победа морской пехоты / UNSC;
   - поражение;
   - неопределённый исход;
   - auto-detected;
   - admin override.
4. Сводка личного состава:
   - в строю;
   - тяжело ранен;
   - погиб;
   - нет данных / пропал без вести, если нужно.
5. Для погибших — нормализованная причина смерти:
   - огнестрельное поражение;
   - взрыв;
   - термическое воздействие;
   - ксеноугроза;
   - разгерметизация/окружение;
   - неизвестно.
6. Прокрутка/постраничное отображение.
7. Cleanup без задержки round-end pipeline.

---

## 4. Целевая архитектура

### 4.1. Новый модуль

Создать новый модуль:

```text
modular/round_cinematics/
  _round_cinematics.dm
  _round_cinematics.dme

  code/
    round_cinematics_controller.dm
    round_cinematics_session.dm
    round_cinematics_sequence.dm
    round_cinematics_phase.dm
    round_cinematics_screen.dm
    round_cinematics_cleanup.dm
    round_cinematics_helpers.dm

    intro/
      cryo_intro_controller.dm
      cryo_intro_context.dm
      cryo_intro_manifest.dm
      cryo_intro_sequence.dm
      cryo_intro_text.dm

    outro/
      round_outro_controller.dm
      round_outro_context.dm
      round_outro_report.dm
      round_outro_death_reasons.dm
      round_outro_outcome.dm
      round_outro_sequence.dm

    admin/
      round_outro_admin.dm
```

Если discovery покажет, что уже есть пригодный `modular/fullscreen/**`, нельзя дублировать его без причины. Возможные решения:

1. использовать существующие fullscreen helpers из `modular/fullscreen/**`;
2. перенести/обернуть их в `modular/round_cinematics/code/round_cinematics_screen.dm`;
3. оставить `modular/fullscreen/**` как low-level визуальный модуль, а `round_cinematics` сделать high-level orchestration layer.

Предпочтение: **не ломать существующий `modular/fullscreen`, а использовать/обернуть его**.

### 4.2. Контроллер

Целевой контроллер:

```dm
/datum/round_cinematics_controller
```

Ответственность:

- старт крио-интро;
- старт round-outro;
- хранение активных sessions;
- отказ от double-start;
- централизованный cleanup;
- проверка блокировки крио;
- админский override outcome;
- подготовка отчёта один раз, до визуального вывода.

Публичные методы:

```dm
/datum/round_cinematics_controller/proc/try_start_cryo_intro(mob/living/carbon/human/human)
/datum/round_cinematics_controller/proc/handle_cryo_exit_attempt(obj/machinery/cryopod/pod, mob/user)
/datum/round_cinematics_controller/proc/is_cryo_locked(mob/user)
/datum/round_cinematics_controller/proc/force_finish_for(mob/user, reason)
/datum/round_cinematics_controller/proc/try_start_round_outro()
/datum/round_cinematics_controller/proc/set_admin_outcome(outcome, mob/admin)
/datum/round_cinematics_controller/proc/get_effective_outcome()
/datum/round_cinematics_controller/proc/cleanup_all(reason)
```

Форма хранения singleton зависит от существующих repo conventions. Агент обязан проверить через:

```bash
rg -n "GLOBAL_DATUM|GLOBAL_LIST|SUBSYSTEM_DEF|/datum/controller/subsystem|modpack" code modular
```

Предпочтение:

1. использовать существующий pattern глобальных datums/subsystems, если он уже есть;
2. не вводить новую subsystem без необходимости;
3. не добавлять глобальные `/proc`, если можно вызвать метод владельца/контроллера.

Условное имя в этом документе:

```dm
SSround_cinematics
```

Это **placeholder**. Агент должен заменить его на реальный repo-conformant способ доступа.

### 4.3. Session

Каждый активный cinematic должен быть отдельной session:

```dm
/datum/round_cinematics_session
```

Поля:

```dm
var/mob/target_mob
var/client/target_client
var/datum/round_cinematics_sequence/sequence
var/list/created_screen_objects
var/list/original_screen_state
var/started_at
var/allow_skip_at
var/hard_timeout_at
var/finished = FALSE
var/cleanup_done = FALSE
var/lock_cryo = FALSE
var/lock_hud = TRUE
var/reason
```

Методы:

```dm
/proc/start()
/proc/show_phase(datum/round_cinematics_phase/phase)
/proc/finish(reason)
/proc/cleanup(reason)
/proc/can_skip()
/proc/skip(mob/user)
/proc/is_valid_target()
```

Session обязана быть idempotent:

- повторный `finish()` не должен делать второй cleanup;
- повторный `cleanup()` не должен runtime;
- исчезновение `client`/`mob` не должно runtime;
- `QDELETED` проверки обязательны в cleanup.

### 4.4. Sequence и Phase

```dm
/datum/round_cinematics_sequence
	var/id
	var/title
	var/list/phases = list()
	var/min_duration = 0
	var/allow_skip_after = 0
	var/hard_timeout = 0
	var/lock_movement = FALSE
	var/lock_hud = TRUE
	var/lock_cryo = FALSE
```

```dm
/datum/round_cinematics_phase
	var/id
	var/duration
	var/header
	var/body
	var/footer
	var/sound
	var/visual_mode
	var/transition
```

Запрещено hardcode-ить длинную последовательность прямо в `human.dm` или `cryopod.dm`.

---

## 5. Визуальный слой

### 5.1. Предпочтительный подход

Использовать BYOND screen objects/maptext/fullscreen overlay.

Приоритеты:

1. screen overlay поверх обычного HUD;
2. минимальное скрытие HUD;
3. cleanup всех созданных объектов;
4. no browser/HTML для основной версии;
5. no TGUI для v1, если без него можно.

### 5.2. Почему не HTML/TGUI в v1

Старые PR уже показали проблемы с HTML-подходом. Для крио-интро нужно стабильное поведение в lifecycle `mob/client/cryopod`, а не сложная browser-сцена.

TGUI можно рассмотреть позже для admin preview/config, но не для основного fullscreen cinematic v1.

### 5.3. Screen object contract

Файл:

```text
modular/round_cinematics/code/round_cinematics_screen.dm
```

Должен дать API:

```dm
/proc/show_cinematic_overlay(client/client, datum/round_cinematics_phase/phase, list/context)
/proc/update_cinematic_overlay(client/client, datum/round_cinematics_phase/phase, list/context)
/proc/clear_cinematic_overlay(client/client)
/proc/build_text_block(header, body, footer)
```

Требования:

- каждый созданный объект должен быть сохранён в `session.created_screen_objects`;
- cleanup должен удалять только свои объекты, не чужой HUD;
- если screen object уже удалён, cleanup не должен runtime;
- нельзя полагаться на глобальную очистку `client.screen -= all`, это риск сломать HUD;
- если нужно временно скрыть HUD, сохранить исходное состояние и восстановить его.

### 5.4. Анимации

Для v1 достаточно:

- fade in через `alpha`;
- статический текст;
- смена фаз;
- fade out;
- для outro — page/scroll imitation через смену текстовых блоков.

Запрещено на v1:

- heavy per-tick animation;
- spawn-loop без hard stop;
- бесконечный `while` без `QDELETED/client/session.finished` проверок;
- зависимость от FPS/lag-sensitive таймингов.

---

## 6. Крио-интро: реализация

### 6.1. Discovery крио entrypoint

Перед кодом найти актуальные места:

```bash
rg -n "cryopod|cryo|go_out|eject|occupant|container_resist|move_out|relaymove|wake" code/game code/modules modular
rg -n "login|Login\(|latejoin|job|equip|spawn|new_player|mind" code/modules/mob code/modules/jobs modular
rg -n "play_opening_sequence|opening|manifest|cryo_manifest" code modular
```

Заполнить:

```md
## Cryo entrypoint decision
- Start intro at: <file>:<line> <proc>
- Exit lock hook at: <file>:<line> <proc>
- Reason:
  - runs after mob has name/job/squad: yes/no
  - runs before player can act: yes/no
  - handles latejoin: yes/no
  - avoids duplicate run: yes/no
```

### 6.2. Когда запускать

Интро должно запускаться только если:

- `human` существует;
- у human есть `client`;
- это реальный игрок, не NPC;
- это релевантный режим/фракция/роль;
- интро ещё не запускалось для этой конкретной life/session;
- игрок не observer;
- round state позволяет показывать интро.

Не запускать:

- для админского possess, если это не явно нужно;
- для NPC/AI human;
- для повторного Login после disconnect, если cinematic уже закончен;
- для spectator;
- если mob уже dead/being deleted.

### 6.3. Контекст личного дела

Файл:

```text
modular/round_cinematics/code/intro/cryo_intro_context.dm
```

API:

```dm
/datum/cryo_intro_context
	var/name
	var/rank
	var/role
	var/squad_name
	var/assignment
	var/list/squad_manifest
	var/list/warnings
```

Collector:

```dm
/proc/build_cryo_intro_context(mob/living/carbon/human/human)
```

Должен:

- безопасно получить имя;
- безопасно получить ранг;
- безопасно получить job/role;
- безопасно получить squad;
- собрать членов отряда;
- отсортировать по squad/rank/role/name;
- ограничить вывод, если отряд слишком большой;
- возвращать fallback `НЕТ ДАННЫХ`, а не runtime.

Пример fallback-строк:

```text
ИМЯ: НЕТ ДАННЫХ
ЗВАНИЕ: НЕ ОПРЕДЕЛЕНО
НАЗНАЧЕНИЕ: НЕ НАЗНАЧЕНО
ОТРЯД: НЕ НАЗНАЧЕН
```

### 6.4. Манифест отряда

Файл:

```text
modular/round_cinematics/code/intro/cryo_intro_manifest.dm
```

Формат записи:

```dm
/datum/cryo_intro_manifest_entry
	var/name
	var/rank
	var/role
	var/status
	var/sort_order
```

Требования:

- не показывать null entries;
- не runtime на отсутствующей роли/отряде;
- не делать тяжёлый поиск на каждой фазе;
- сбор манифеста один раз перед стартом sequence;
- если отряд пустой, показать “ДАННЫЕ ОТРЯДА НЕДОСТУПНЫ”.

### 6.5. Последовательность фаз

Файл:

```text
modular/round_cinematics/code/intro/cryo_intro_sequence.dm
```

Рекомендуемые фазы v1:

| Phase | Длительность | Содержание |
|---|---:|---|
| `wake_boot` | 2 сек | `ИНИЦИАЛИЗАЦИЯ ПРОТОКОЛА ПРОБУЖДЕНИЯ` |
| `identity` | 3 сек | Личное дело: имя, звание, роль, отряд |
| `squad_manifest` | 4–6 сек | Манифест отряда, постранично если много людей |
| `deployment` | 2 сек | `СТАТУС: ГОТОВ К РАЗВЁРТЫВАНИЮ` |
| `finish` | 1 сек | fade out / system ready |

Skip доступен после `wake_boot + identity`, то есть примерно через 5 секунд.

### 6.6. Блокировка крио

Блокировка должна быть мягкой и fail-safe.

Правила:

- блокировать только пока active session с `lock_cryo = TRUE`;
- hard timeout не больше 20 секунд;
- при cleanup всегда unlock;
- если session потеряла mob/client — unlock;
- admin должен иметь способ force-finish/skip;
- нельзя оставлять var на cryopod без cleanup.

В upstream hook не должно быть бизнес-логики.

Плохой пример:

```dm
if(user.cryo_intro_active)
	to_chat(user, "...")
	return
```

Хороший пример:

```dm
// SS220 EDIT - START
if(SSround_cinematics?.handle_cryo_exit_attempt(src, user))
	return
// SS220 EDIT - END
```

Вся логика ответа, текста и unlock живёт в модуле.

### 6.7. HUD

Предпочтение: overlay поверх HUD, а не удаление HUD.

Если HUD нужно скрыть:

- найти существующий no-HUD/fullscreen mechanism;
- использовать его, если он безопасен;
- сохранить исходное состояние;
- восстановить при любом cleanup;
- не менять `code/datums/action.dm`, если можно обойтись overlay;
- не менять `code/_onclick/hud/hud.dm`, если можно обойтись overlay.

Перед правкой HUD выполнить:

```bash
rg -n "hud_used|show_hud|hide_hud|no_hud|screen|client\.screen|actions" code modular
```

---

## 7. Round-outro: реализация

### 7.1. Discovery round-end entrypoint

Перед кодом:

```bash
rg -n "announce_ending|round_end|end_round|declare_completion|ticker|mode_result|round_result|game over|end of round|show_roundend" code modular
rg -n "SSticker|ticker|SSmapping|SSdcs|round_finished|GAME_STATE_FINISHED|ROUND" code modular
```

Заполнить:

```md
## Round-end entrypoint decision
- Start outro at: <file>:<line> <proc>
- Reason:
  - called once: yes/no
  - all player states available: yes/no
  - before clients leave round: yes/no
  - safe for async visual display: yes/no
- Fallback if called multiple times:
  - controller idempotency: yes/no
```

### 7.2. Когда запускать

Outro запускать один раз в конце раунда.

Controller должен иметь защиту:

```dm
if(outro_started)
	return FALSE
outro_started = TRUE
```

Outro не должен блокировать базовый round-end pipeline тяжёлыми вычислениями.

Правильный flow:

1. round-end hook вызывает controller;
2. controller быстро собирает context;
3. context превращается в готовые страницы отчёта;
4. каждому client показывается prepared report;
5. visual sessions сами завершаются/очищаются.

### 7.3. Контекст аутро

Файл:

```text
modular/round_cinematics/code/outro/round_outro_context.dm
```

Типы:

```dm
/datum/round_outro_context
	var/operation_name
	var/map_name
	var/outcome
	var/outcome_source
	var/list/entries
	var/started_at
	var/finished_at
	var/list/summary_counts
```

```dm
/datum/round_outro_entry
	var/name
	var/rank
	var/role
	var/squad_name
	var/status
	var/death_reason
	var/sort_order
```

Collector:

```dm
/proc/build_round_outro_context()
```

Требования:

- собрать данные один раз;
- не runtime на null mind/client/body;
- не runtime на удалённом mob;
- не включать NPC, если scope — только игроки;
- сортировать по squad/rank/role/name;
- не делать per-client тяжелый сбор заново.

### 7.4. Фильтр участников

Рекомендуемый v1 scope:

- player-controlled human;
- морпехи/UNSC/BandaTroopers-релевантная фракция;
- участники раунда, а не observers.

Не включать:

- чистых observers;
- NPC;
- админские possess targets, если они не игроки;
- технических mobs.

Если faction contracts не ясны, агент обязан провести discovery:

```bash
rg -n "faction|FACTION_|UNSC|USCM|marine|squad|assigned_squad|job" code modular
```

И зафиксировать выбранный фильтр в комментарии к PR.

### 7.5. Статусы

Ввести внутренние constants/defines модуля:

```dm
#define ROUND_CINEMATIC_STATUS_ACTIVE "active"
#define ROUND_CINEMATIC_STATUS_WOUNDED "wounded"
#define ROUND_CINEMATIC_STATUS_KIA "kia"
#define ROUND_CINEMATIC_STATUS_UNKNOWN "unknown"
```

Пользовательские строки:

```text
В СТРОЮ
ТЯЖЕЛО РАНЕН
ПОГИБ
НЕТ ДАННЫХ
```

Алгоритм v1:

1. Если mob dead/stat dead — `KIA`.
2. Если mob alive, но critical/unconscious/heavily damaged — `WOUNDED`.
3. Если mob alive и в нормальном состоянии — `ACTIVE`.
4. Если body/mob отсутствует — `UNKNOWN`.

Агент обязан заменить generic checks на реальные constants проекта после discovery:

```bash
rg -n "DEAD|UNCONSCIOUS|stat|health|crit|hardcrit|softcrit|revivable" code modular
```

### 7.6. Причины смерти

Файл:

```text
modular/round_cinematics/code/outro/round_outro_death_reasons.dm
```

API:

```dm
/proc/normalize_round_outro_death_reason(mob/living/carbon/human/human)
```

Категории v1:

```text
ОГНЕСТРЕЛЬНОЕ ПОРАЖЕНИЕ
ВЗРЫВНОЕ ВОЗДЕЙСТВИЕ
ТЕРМИЧЕСКОЕ ВОЗДЕЙСТВИЕ
КИСЛОТНОЕ/БИОЛОГИЧЕСКОЕ ВОЗДЕЙСТВИЕ
КСЕНОУГРОЗА
ОКРУЖАЮЩАЯ СРЕДА
ДРУЖЕСТВЕННЫЙ ОГОНЬ
НЕИЗВЕСТНО
```

Перед реализацией выполнить:

```bash
rg -n "cause_of_death|last_damage|death_message|attack_log|combat_log|damage_type|BRUTE|BURN|TOX|OXY|CLONE|explosion|fire|acid|xeno" code modular
```

Правила:

- не строить сложную forensic-систему в v1;
- использовать доступные поля, если они уже есть;
- если данных нет — `НЕИЗВЕСТНО`;
- не runtime на missing damage data.

### 7.7. Outcome

Файл:

```text
modular/round_cinematics/code/outro/round_outro_outcome.dm
```

Constants:

```dm
#define ROUND_CINEMATIC_OUTCOME_AUTO "auto"
#define ROUND_CINEMATIC_OUTCOME_MARINE_VICTORY "marine_victory"
#define ROUND_CINEMATIC_OUTCOME_MARINE_DEFEAT "marine_defeat"
#define ROUND_CINEMATIC_OUTCOME_INCONCLUSIVE "inconclusive"
```

Outcome source:

```dm
#define ROUND_CINEMATIC_OUTCOME_SOURCE_AUTO "auto"
#define ROUND_CINEMATIC_OUTCOME_SOURCE_ADMIN "admin"
```

Алгоритм:

1. Если admin override установлен — использовать его.
2. Иначе попытаться прочитать результат mode/ticker, если в проекте есть стабильный field/proc.
3. Если результат невозможно определить — `INCONCLUSIVE`.

Запрещено:

- изобретать победу/поражение по случайным heuristics без согласования;
- привязываться к тексту round-end сообщения, если есть structured source;
- ломать существующий round-end summary.

### 7.8. Admin override

Файл:

```text
modular/round_cinematics/code/admin/round_outro_admin.dm
```

V1 без TGUI, если можно.

Варианты:

1. admin verb;
2. admin command;
3. существующий admin panel hook, если есть простой pattern.

Discovery:

```bash
rg -n "client/proc|admin|check_rights|R_ADMIN|holder|verbs|admin panel|datum/admins" code modular
```

Минимальные команды:

```text
Set Round Outro Outcome: Marine Victory
Set Round Outro Outcome: Marine Defeat
Set Round Outro Outcome: Inconclusive
Set Round Outro Outcome: Auto
Preview Round Outro
Force Stop Round Cinematic
```

Требования:

- права администратора проверять существующим способом проекта;
- логировать изменение outcome;
- не открывать доступ обычным игрокам;
- preview не должен менять реальный round state;
- preview должен иметь cleanup.

---

## 8. Этапы внедрения

## Этап 0. Подготовительный аудит

### Цель

Сузить кодовую область, подтвердить реальные entrypoints, понять существующие helpers.

### Только read-only действия

Команды:

```bash
rg -n "cryo|cryopod|Cryo|wake|login|latejoin|play_opening_sequence|opening_sequence|manifest" code modular
rg -n "round_end|end_round|announce_ending|declare_completion|ticker|mode_result|round_result|game over" code modular
rg -n "client\.screen|screen_loc|maptext|fullscreen|AlertModal|hud_used|no_hud|action button|actions" code modular tgui
rg -n "#include.*modular|modular\.dme|round_outro|fullscreen" colonialmarines.dme modular -g "*.dme"
rg -n "SS220 EDIT" code map_config modular -g "!modular/__agents/**" -g "!modular/__docs/**"
```

### Deliverable

Создать/обновить локальный рабочий markdown, например:

```text
modular/round_cinematics/IMPLEMENTATION_NOTES.md
```

С содержанием:

```md
# Round Cinematics Implementation Notes

## Discovery inventory
...

## Decisions
- Cryo intro starts at: ...
- Cryo exit lock hook: ...
- Round outro starts at: ...
- Visual layer reuses: ...
- Singleton/controller pattern: ...

## Upstream edits required
...
```

### Acceptance criteria

- нет изменений кода, кроме optional notes-документа;
- зафиксированы конкретные файлы и proc для hooks;
- указано, какие старые PR-файлы рассматриваются как reference only.

---

## Этап 1. Каркас модуля

### Цель

Добавить пустой, компилируемый модуль без функционального поведения.

### Файлы

Создать:

```text
modular/round_cinematics/_round_cinematics.dm
modular/round_cinematics/_round_cinematics.dme
modular/round_cinematics/code/round_cinematics_controller.dm
modular/round_cinematics/code/round_cinematics_session.dm
modular/round_cinematics/code/round_cinematics_sequence.dm
modular/round_cinematics/code/round_cinematics_phase.dm
modular/round_cinematics/code/round_cinematics_cleanup.dm
```

Изменить:

```text
modular/modular.dme
```

### Include structure

`modular/round_cinematics/_round_cinematics.dme` должен подключать все code-файлы модуля.

`modular/modular.dme` должен подключать `_round_cinematics.dme` по существующему стилю подключения модулей.

### Реализация

Добавить пустые datums и no-op controller methods.

Примерная форма:

```dm
/datum/round_cinematics_controller
	var/list/active_sessions
	var/outro_started = FALSE

/datum/round_cinematics_controller/New()
	. = ..()
	active_sessions = list()

/datum/round_cinematics_controller/proc/try_start_cryo_intro(mob/living/carbon/human/human)
	return FALSE

/datum/round_cinematics_controller/proc/handle_cryo_exit_attempt(obj/machinery/cryopod/pod, mob/user)
	return FALSE

/datum/round_cinematics_controller/proc/try_start_round_outro()
	return FALSE

/datum/round_cinematics_controller/proc/cleanup_all(reason)
	return
```

Форма singleton/controller access — по repo convention после discovery.

### Acceptance criteria

- компилируется;
- модуль подключён;
- no-op методы ничего не меняют;
- нет upstream changes на этом этапе, если можно;
- `git diff --check` проходит.

---

## Этап 2. Минимальные upstream hooks

### Цель

Подключить controller к реальным lifecycle-точкам, но пока без визуала.

### Возможные файлы

Точные файлы выбрать по discovery. Ожидаемые кандидаты:

```text
code/game/machinery/cryopod.dm
code/modules/mob/living/carbon/human/login.dm
<round-end entrypoint file>
```

### Hook 1: start cryo intro

Добавить один вызов после того, как у human уже есть:

- client;
- name;
- job/role;
- squad;
- body готово к отображению.

Pseudo:

```dm
// SS220 EDIT: delegate BandaTroopers cryo intro to modular round cinematics
SSround_cinematics?.try_start_cryo_intro(src)
```

Если `SSround_cinematics` не repo-conformant, заменить на найденный pattern.

### Hook 2: cryo exit attempt

Добавить в proc выхода из крио:

```dm
// SS220 EDIT - START
if(SSround_cinematics?.handle_cryo_exit_attempt(src, user))
	return
// SS220 EDIT - END
```

Controller пока возвращает `FALSE`, чтобы поведение не изменилось.

### Hook 3: round outro start

В round-end entrypoint:

```dm
// SS220 EDIT: delegate BandaTroopers round outro to modular round cinematics
SSround_cinematics?.try_start_round_outro()
```

Controller пока no-op.

### Acceptance criteria

- hooks компилируются;
- поведение игры не меняется, так как controller no-op;
- upstream diff минимальный;
- все upstream changes размечены `SS220 EDIT`;
- нет больших рефакторов вокруг hook.

---

## Этап 3. Общий visual/session слой

### Цель

Сделать безопасный overlay lifecycle без intro/outro бизнес-логики.

### Файлы

```text
modular/round_cinematics/code/round_cinematics_screen.dm
modular/round_cinematics/code/round_cinematics_session.dm
modular/round_cinematics/code/round_cinematics_cleanup.dm
modular/round_cinematics/code/round_cinematics_helpers.dm
```

### Реализация

Session должна уметь:

- стартовать на client;
- создать простой fullscreen overlay;
- показать тестовый текст;
- завершиться через duration;
- cleanup по вызову;
- cleanup при invalid target;
- cleanup при force stop.

Методы:

```dm
/datum/round_cinematics_session/proc/start()
/datum/round_cinematics_session/proc/finish(reason)
/datum/round_cinematics_session/proc/cleanup(reason)
/datum/round_cinematics_session/proc/is_valid_target()
/datum/round_cinematics_session/proc/register_screen_object(atom/movable/screen/object)
```

Controller:

```dm
/datum/round_cinematics_controller/proc/start_session(mob/target, datum/round_cinematics_sequence/sequence, list/context)
/datum/round_cinematics_controller/proc/remove_session(datum/round_cinematics_session/session, reason)
/datum/round_cinematics_controller/proc/force_finish_for(mob/user, reason)
```

### Принципы cleanup

Cleanup должен:

- удалить только объекты из `session.created_screen_objects`;
- восстановить HUD/interaction state, если менялся;
- снять cryo lock, если был;
- удалить session из controller maps/lists;
- быть безопасным при повторном вызове.

### Acceptance criteria

- admin/test proc может показать тестовый overlay и убрать его;
- повторный cleanup не runtime;
- disconnect во время overlay не runtime;
- no HTML/TGUI;
- no heavy loops.

---

## Этап 4. Крио-интро v1

### Цель

Полностью реализовать первое рабочее интро без финальной полировки.

### Файлы

```text
modular/round_cinematics/code/intro/cryo_intro_controller.dm
modular/round_cinematics/code/intro/cryo_intro_context.dm
modular/round_cinematics/code/intro/cryo_intro_manifest.dm
modular/round_cinematics/code/intro/cryo_intro_sequence.dm
modular/round_cinematics/code/intro/cryo_intro_text.dm
```

### Controller logic

`try_start_cryo_intro(human)`:

1. validate human;
2. validate client;
3. validate player-controlled;
4. validate relevant faction/job/mode;
5. check not already started;
6. build context;
7. build sequence;
8. start session;
9. set cryo lock if needed;
10. return TRUE/FALSE based on start result.

### Context logic

`build_cryo_intro_context(human)`:

- collect identity;
- collect role;
- collect squad;
- collect squad manifest;
- sanitize strings;
- fallback missing fields.

### Sequence logic

Build phases:

```text
wake_boot
identity
squad_manifest
deployment
finish
```

### Lock logic

`handle_cryo_exit_attempt(pod, user)`:

1. if no active intro lock — return FALSE;
2. if admin bypass allowed — return FALSE;
3. show short warning;
4. return TRUE to block exit.

Hard timeout:

- no more than 20 seconds;
- timeout must call `finish("timeout")`;
- cleanup must unlock.

### Acceptance criteria

Manual test cases:

1. Normal marine wakes from cryo, intro shows and ends.
2. Player tries to exit during intro, blocked with warning.
3. After intro, player exits normally.
4. Player disconnects during intro, no runtime, no stuck pod.
5. Player reconnects, intro does not loop infinitely.
6. Player has no squad, intro shows fallback.
7. Squad has many members, manifest does not overflow badly.
8. Admin force-stop clears overlay and unlocks.

Build:

```bash
git diff --check
BUILD.cmd
```

---

## Этап 5. Round-outro v1

### Цель

Реализовать финальный военный отчёт без сложного admin UI/TGUI.

### Файлы

```text
modular/round_cinematics/code/outro/round_outro_controller.dm
modular/round_cinematics/code/outro/round_outro_context.dm
modular/round_cinematics/code/outro/round_outro_report.dm
modular/round_cinematics/code/outro/round_outro_death_reasons.dm
modular/round_cinematics/code/outro/round_outro_outcome.dm
modular/round_cinematics/code/outro/round_outro_sequence.dm
```

### Controller logic

`try_start_round_outro()`:

1. if already started — return FALSE;
2. set `outro_started = TRUE`;
3. build context once;
4. build report pages once;
5. find target clients;
6. start visual sessions per client;
7. return TRUE.

### Context logic

Collect:

- operation/map name;
- outcome;
- list of player combatants;
- status per entry;
- death reason per dead entry;
- summary counts.

### Report pages

File:

```text
modular/round_cinematics/code/outro/round_outro_report.dm
```

Should build list of pages:

```dm
list(
	/datum/round_cinematics_phase(...header="ОТЧЁТ ОПЕРАЦИИ"...),
	/datum/round_cinematics_phase(...header="КЛАССИФИКАЦИЯ ИСХОДА"...),
	/datum/round_cinematics_phase(...header="СОСТОЯНИЕ ЛИЧНОГО СОСТАВА"...),
	...
)
```

If too many entries:

- paginate by fixed number of rows;
- do not build a single giant maptext string;
- preserve order across pages.

### Acceptance criteria

Manual test cases:

1. Round end starts outro once.
2. Multiple clients receive report.
3. Dead players appear as `ПОГИБ`.
4. Alive players appear as `В СТРОЮ` or `ТЯЖЕЛО РАНЕН`.
5. Missing death reason becomes `НЕИЗВЕСТНО`.
6. No runtime on disconnected clients.
7. No runtime on missing body/mind.
8. Round end does not freeze.
9. Repeated round-end call does not duplicate sessions.

Build:

```bash
git diff --check
BUILD.cmd
```

---

## Этап 6. Admin outcome override and preview

### Цель

Дать администраторам управляемый итог операции и preview без TGUI, если возможно.

### Файлы

```text
modular/round_cinematics/code/admin/round_outro_admin.dm
modular/round_cinematics/code/outro/round_outro_outcome.dm
```

### Commands/verbs

Реализовать по существующему admin convention:

```text
Set Round Outro Outcome: Auto
Set Round Outro Outcome: Marine Victory
Set Round Outro Outcome: Marine Defeat
Set Round Outro Outcome: Inconclusive
Preview Cryo Intro
Preview Round Outro
Force Stop Round Cinematics
```

### Rules

- check admin rights;
- log action;
- preview только для вызывающего admin или selected target;
- preview не меняет реальные round values;
- force stop вызывает централизованный cleanup.

### Acceptance criteria

1. Обычный игрок не видит/не может вызвать commands.
2. Admin может выбрать outcome до конца раунда.
3. Round outro использует override.
4. Auto возвращает автоопределение/fallback.
5. Preview не ломает реальный раунд.

---

## Этап 7. Полировка визуала и текста

### Цель

Сделать cinematic красивым, не меняя архитектуру.

### Файлы

```text
modular/round_cinematics/code/intro/cryo_intro_text.dm
modular/round_cinematics/code/outro/round_outro_report.dm
modular/round_cinematics/code/round_cinematics_screen.dm
```

Optional assets:

```text
sound/** or modular/round_cinematics/sound/**
icons/** or modular/round_cinematics/icons/**
```

Assets добавлять только если:

- есть право использования;
- они проходят репозиторные проверки;
- не раздувают PR без причины.

### Text style

Стиль:

- военный отчёт;
- без игровых терминов вроде “раунд закончился”, если это не admin/debug;
- единый тон UNSC/BandaTroopers;
- русская локализация в UTF-8;
- без mojibake.

Примеры:

```text
ПРОТОКОЛ ПРОБУЖДЕНИЯ АКТИВИРОВАН
ИДЕНТИФИКАЦИЯ БОЙЦА ЗАВЕРШЕНА
НАЗНАЧЕНИЕ ПОДТВЕРЖДЕНО
ОТЧЁТ ОПЕРАЦИИ СФОРМИРОВАН
КЛАССИФИКАЦИЯ ИСХОДА: ПОБЕДА МОРСКОЙ ПЕХОТЫ
```

### Visual constraints

- тёмный фон;
- высокий контраст;
- читаемый текст;
- не слишком мелкий шрифт;
- адаптация под разные размеры окна;
- не зависеть от exact pixel-perfect layout в BYOND.

### Acceptance criteria

1. Текст читается на маленьком и большом окне.
2. Overlay не перекрывает игру после завершения.
3. Нет лишней серой каши/нечитабельного контраста.
4. Интро не раздражает длительностью.
5. Аутро выглядит как отчёт, а не debug dump.

---

## Этап 8. Финальное ревью и стабилизация

### Code review checklist

- [ ] Новая бизнес-логика находится в `modular/round_cinematics/**`.
- [ ] Upstream diff минимальный.
- [ ] Upstream diff размечен `SS220 EDIT`.
- [ ] Нет прямого переноса HTML-интро.
- [ ] Нет необоснованных TGUI changes.
- [ ] Нет heavy per-tick loops.
- [ ] Все sessions имеют cleanup.
- [ ] Cleanup idempotent.
- [ ] Cryo lock имеет hard timeout.
- [ ] Round outro context собирается один раз.
- [ ] Missing data даёт fallback, а не runtime.
- [ ] Русский текст в UTF-8.
- [ ] Нет mojibake.
- [ ] `git diff --check` проходит.
- [ ] DM build проходит.

### Regression tests/manual matrix

| Case | Expected |
|---|---|
| Normal cryo wake | Intro starts, ends, HUD returns |
| Exit cryo during intro | Blocked until intro ends/skip allowed |
| Exit cryo after intro | Works normally |
| Disconnect during intro | Cleanup, no runtime |
| No squad | Fallback text |
| Large squad | Manifest paginated/capped |
| Round end with many players | Outro shown, no freeze |
| Dead player no cause | `НЕИЗВЕСТНО` |
| Admin outcome victory | Outro shows victory |
| Admin outcome auto | Uses auto/fallback |
| Preview outro | Only preview target sees it; no state pollution |
| Force stop | All overlays cleared |

---

## 9. Рекомендуемое разбиение на PR

### PR A — `Round Cinematics: skeleton and hooks`

Содержит:

- каркас `modular/round_cinematics`;
- no-op controller;
- include in `modular/modular.dme`;
- минимальные upstream hooks;
- `IMPLEMENTATION_NOTES.md` с discovery decisions.

Не содержит:

- финальный визуал;
- аутро logic;
- admin commands;
- TGUI.

### PR B — `Round Cinematics: cryo intro`

Содержит:

- intro context;
- manifest;
- sequence;
- screen overlay;
- cryo lock;
- cleanup.

Не содержит:

- round outro;
- admin outcome;
- TGUI.

### PR C — `Round Cinematics: operation outro`

Содержит:

- outro context;
- statuses;
- death reason normalization;
- outcome auto fallback;
- report pages;
- end-round sessions.

Не содержит:

- complex admin UI;
- optional assets.

### PR D — `Round Cinematics: admin controls and polish`

Содержит:

- admin outcome override;
- preview commands;
- force stop;
- visual polish;
- optional sound/assets.

---

## 10. Запрос для Codex / ИИ-агента

Ниже готовый промт, который можно дать основному агенту.

```text
Ты работаешь в репозитории ss220club/BandaTroopers.
Задача: реализовать поддерживаемую модульную систему intro/outro на основе идей из PR #29, #31, #41, #42, но НЕ переносить эти PR как есть.

Главное архитектурное решение:
- новая бизнес-логика должна жить в modular/round_cinematics/**;
- code/** можно трогать только для минимальных hooks;
- все upstream edits размечать SS220 EDIT;
- HTML/TGUI не использовать для основной v1 cinematic, если discovery не докажет необходимость;
- старые PR использовать только как UX/content reference.

Перед любыми правками выполни discovery:
rg -n "cryo|cryopod|Cryo|wake|login|latejoin|play_opening_sequence|opening_sequence|manifest" code modular
rg -n "round_end|end_round|announce_ending|declare_completion|ticker|mode_result|round_result|game over" code modular
rg -n "client\.screen|screen_loc|maptext|fullscreen|AlertModal|hud_used|no_hud|action button|actions" code modular tgui
rg -n "#include.*modular|modular\.dme|round_outro|fullscreen" colonialmarines.dme modular -g "*.dme"
rg -n "SS220 EDIT" code map_config modular -g "!modular/__agents/**" -g "!modular/__docs/**"

После discovery создай/обнови modular/round_cinematics/IMPLEMENTATION_NOTES.md:
- Cryo entrypoint decision
- Cryo exit lock hook decision
- Round-end entrypoint decision
- Visual layer decision
- Singleton/controller pattern decision
- Required upstream edits and why

Реализуй по этапам:
1. skeleton module + no-op controller;
2. minimal upstream hooks, no behavior change;
3. safe session/overlay/cleanup layer;
4. cryo intro v1;
5. round outro v1;
6. admin outcome/preview;
7. polish.

Не смешивай этапы без необходимости. Если работа большая, дели на PR A/B/C/D:
A skeleton/hooks, B cryo intro, C round outro, D admin/polish.

Обязательные acceptance criteria:
- no business logic in upstream files;
- no big HUD/action/TGUI rewrite;
- cleanup is idempotent;
- cryo lock has hard timeout;
- outro context is built once;
- missing data uses fallback strings, not runtimes;
- git diff --check passes;
- BUILD.cmd or tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror passes.
```

---

## 11. Definition of Done

Фича считается готовой, когда:

1. Есть модуль `modular/round_cinematics/**`.
2. Интро запускается в правильном cryo/latejoin flow.
3. Интро не ломает HUD и не оставляет игрока запертым.
4. Аутро запускается один раз на round end.
5. Аутро показывает понятный военный отчёт.
6. Outcome можно определить автоматически или задать админом.
7. Причины смерти нормализованы и имеют fallback.
8. Все overlays чистятся при normal finish, skip, disconnect, qdel, force stop.
9. Upstream diff минимальный и размечен.
10. Проходят минимальные проверки.

---

## 12. Критичные запреты

Агентам нельзя:

- мержить PR #29/#31/#41/#42 напрямую;
- тащить весь HTML из старого интро;
- делать новый большой `AlertModal.tsx` diff без необходимости;
- хранить всё состояние cinematic на `/mob/living/carbon/human`;
- писать длинную intro/outro логику в `human.dm`;
- делать endless loops ради scroll/fade;
- оставлять cryo lock без timeout;
- очищать весь `client.screen` вместо своих объектов;
- ломать существующий HUD/action system;
- менять карты/configs/build workflows без отдельного scope;
- оставлять русские строки в неправильной кодировке.

---

## 13. Предпочтительные дефолты, если нет дополнительных решений

Если владелец проекта не уточнил детали, использовать:

```text
Фракционный стиль: UNSC / BandaTroopers military style
Интро: только для player-controlled marine/human cryo/latejoin
Skip: разрешить после 5 секунд
Hard timeout интро: 20 секунд
Блокировка крио: да, только во время active intro session
Аутро: показывать player-controlled marine/human participants
SSD/disconnected: НЕТ ДАННЫХ / ПРОПАЛ БЕЗ ВЕСТИ, если body не найден
Причины смерти: обобщённые категории
Outcome: admin override > structured mode result > inconclusive
TGUI: не использовать в v1, кроме если discovery докажет необходимость
HTML: не использовать в v1
```
