# BandaTroopers PR #106 — план доработки Round Cinematics

Документ предназначен для передачи ИИ-агенту/Codex.
Цель — доработать текущий PR `#106 round cinematics`, а не переписать всё с нуля.

PR: `https://github.com/ss220club/BandaTroopers/pull/106`
Референсы визуала:
- `https://github.com/ss220club/BandaTroopers/pull/29`
- `https://github.com/ss220club/BandaTroopers/pull/31`

---

## 0. Краткий диагноз

Текущая реализация PR #106 уже имеет правильное направление:

- есть отдельный модуль `modular/round_cinematics/**`;
- есть `GLOB.round_cinematics`;
- есть `round_cinematics_controller`;
- есть per-session datums;
- есть cleanup;
- есть fullscreen overlays;
- есть typewriter через maptext;
- есть intro/outro contexts;
- есть admin preview и outcome override.

Но реализация пока ощущается как технический скелет:

1. **Интро не стартует автоматически стабильно.**
   - Сейчас запуск зависит от `play_opening_sequence()` и от того, что human уже находится в cryopod.
   - Если spawn/latejoin flow не вызывает этот proc или вызывает его до помещения в cryopod, интро не стартует.

2. **Визуал слишком простой.**
   - Сейчас это в основном центральный maptext.
   - Нет полноценной терминальной композиции: постоянного header/footer, рамки, фонового glow, boot panel, status grid, логотипа, атмосферных переходов.

3. **Печать есть, но её нужно сделать устойчивой.**
   - Текущий typewriter должен быть проверен на HTML/tag-safety.
   - Нельзя, чтобы во время печати частично появлялись HTML-теги или ломался maptext.

4. **Победа и поражение выглядят одинаково.**
   - Outcome определяется, но визуальный профиль не меняется.
   - Нужны разные цвета, заголовки, фразы, звуки, glitch/flicker и структура отчёта.

5. **Автоопределение исхода нужно довести.**
   - Админский override должен остаться, но default flow обязан быть автоматическим.
   - Нужно проверить все используемые game modes и `round_finished` constants.

6. **Upstream diff слишком широко размазан.**
   - Сейчас touched несколько gamemode files.
   - Нужно проверить, есть ли общий end-round hook, чтобы уменьшить количество upstream-правок.
   - Если общего hook нет, оставить текущие hooks, но аккуратно оформить `SS220 EDIT` и не добавлять лишнего.

---

## 1. Обязательные правила для агента

### 1.1. Discovery first

Перед изменениями выполнить:

```bash
rg -n "round_cinematics|try_start_cryo_intro|queue_cryo_intro|try_start_round_outro|play_opening_sequence|intro_sequence|declare_completion|announce_ending|round_finished|round_result|MODE_INFESTATION|COMSIG_CRYOPOD" code modular

rg -n "overlay_fullscreen|clear_fullscreen|/atom/movable/screen/fullscreen|screen_text|play_screen_text|playsound_client|cryo_beep|cryo_intro|cryo_opening" code modular

rg -n "SS220 EDIT" code map_config

rg -n "SS220 EDIT" modular -g "!modular/__agents/**" -g "!modular/__docs/**"
```

После discovery агент должен зафиксировать:

- где реально вызывается `play_opening_sequence()`;
- где human помещается в cryopod;
- где latejoin player получает mob/job/equipment;
- где вызывается `declare_completion()`;
- где выставляется `round_finished`;
- существуют ли общие signals/hooks для round end и cryo spawn;
- какие fullscreen/screen atoms уже можно использовать.

### 1.2. Правила модульности

Основная логика должна оставаться здесь:

```text
modular/round_cinematics/**
```

В `code/**` допускаются только:

- минимальные вызовы модульных hooks;
- adapters;
- безопасные fallback-ветки;
- неизбежный glue-код.

Нельзя:

- переносить visual/business logic в `human.dm`, `cryopod.dm`, `gamemode.dm`;
- добавлять большие блоки логики в upstream;
- менять TGUI/AlertModal без строгой причины;
- использовать browser/HTML-файл как runtime UI;
- добавлять CDN, Tailwind, Google Fonts или внешние web assets;
- ломать старый round end flow;
- оставлять игрока без HUD/в крио при ошибке.

### 1.3. `SS220 EDIT`

В новых файлах `modular/**` новые `SS220 EDIT` не ставить.

В `code/**`, если строка изменяется или добавляется:

```dm
// SS220 EDIT: delegate cryo intro to modular round cinematics
GLOB.round_cinematics?.queue_cryo_intro(src, "opening_sequence")
```

Для блоков:

```dm
// SS220 EDIT - START: delegate round cinematic outro to modular subsystem
GLOB.round_cinematics?.try_start_round_outro()
// SS220 EDIT - END
```

---

## 2. Целевое поведение

## 2.1. Интро

Интро должно запускаться автоматически для marine/human игрока, который просыпается в cryopod или появляется через latejoin cryo flow.

### Фазы интро

#### Фаза 1 — CRT power-on

Визуально:

- чёрный экран;
- зелёное свечение;
- scanlines/CRT overlay;
- короткий flicker;
- центральная линия/вспышка;
- terminal frame появляется через fade/turn-on.

Звук:

- короткий boot beep;
- тихий terminal hum, если уже есть подходящий asset.

#### Фаза 2 — Boot/status terminal

Верхняя строка:

```text
USCM-TERMINAL-7.02                                      КРИО-ОТСЕК 04. СЕКТОР B.
```

Центр:

```text
USMC
UNITED STATES COLONIAL MARINE CORPS
```

Панель:

```text
СИСТЕМА:             ОК
КРИО-СТАТУС:         ВЫХОД
ТЕМПЕРАТУРА ТЕЛА:    36.6 °C
ЧСС:                 72 УД/МИН

> ИНИЦИАЛИЗАЦИЯ ПРОБУЖДЕНИЯ...
```

Footer:

```text
© 2180 UNITED STATES COLONIAL MARINE CORPS. ВСЕ ПРАВА ЗАЩИЩЕНЫ.     BANDA TROOPERS CUR-S. E. 220
```

#### Фаза 3 — Личное дело

```text
ЛИЧНОЕ ДЕЛО

ИМЯ:              <real_name>
ЗВАНИЕ:           <rank/paygrade>
ОТРЯД:            <squad>
СПЕЦИАЛЬНОСТЬ:    <assignment/job>
СТАТУС:           АКТИВЕН

> ВЫХОД ИЗ КРИО-СНА:
```

#### Фаза 4 — Манифест/отряд

Список отряда или relevant platoon members:

```text
ОРУЖ. СЕРЖАНТ <name> — КОМАНДИР ОТРЯДА
ШТАБ-СЕРЖАНТ <name> — ЗАМ. КОМАНДИРА
СЕРЖАНТ <name> — ПОЛЕВОЙ САНИТАР
...
```

Требования:

- сортировать по squad, rank/order, role, name;
- не выводить слишком много строк на один экран;
- если строк больше лимита — разбить на страницы;
- не показывать null/пустые роли;
- не падать при отсутствующем ID card, squad, paygrade.

#### Фаза 5 — Exit/fade-out

- короткий beep;
- `> ПРОБУЖДЕНИЕ ЗАВЕРШЕНО`;
- fade-out;
- очистка overlays/text;
- восстановление HUD;
- unlock cryopod.

### Timing

Рекомендуемые значения:

```dm
#define ROUND_CINEMATICS_INTRO_ALLOW_SKIP_AFTER (5 SECONDS)
#define ROUND_CINEMATICS_INTRO_HARD_TIMEOUT (25 SECONDS)
#define ROUND_CINEMATICS_INTRO_PAGE_ROWS 8
```

Фазы:

| Фаза | Время |
|---|---:|
| power-on | 0.8–1.2 sec |
| boot/status | 4–5 sec |
| personal file | 4–5 sec |
| manifest | 4–6 sec на страницу |
| exit | 1 sec |

---

## 2.2. Аутро

Аутро должно автоматически запускаться в конце раунда, без необходимости ручного админского выбора.

Админский выбор должен остаться как override, но default — auto.

### Фазы аутро

#### Фаза 1 — Outcome splash

Победа:

```text
ОПЕРАЦИЯ ЗАВЕРШЕНА: УСПЕХ
СТАТУС: МОРСКАЯ ПЕХОТА СОХРАНИЛА КОНТРОЛЬ
```

Поражение:

```text
ОПЕРАЦИЯ ЗАВЕРШЕНА: ПОРАЖЕНИЕ
СТАТУС: БОЕВАЯ ГРУППА ПОТЕРЯЛА КОНТРОЛЬ
```

Неопределённо:

```text
ИСХОД ОПЕРАЦИИ НЕ ПОДТВЕРЖДЁН
СТАТУС: НЕДОСТАТОЧНО ДАННЫХ
```

#### Фаза 2 — Operation summary

```text
ОПЕРАЦИЯ: <mode.name>
ЛОКАЦИЯ: <map_name>
ИСХОД: <outcome.title>
ДЕТАЛИ: <outcome.detail>
РЕЖИМ ОПРЕДЕЛЕНИЯ: АВТО / АДМИН-ОВЕРРАЙД
```

Добавить, если доступно:

```text
ДЛИТЕЛЬНОСТЬ: <round duration>
КЛАССИФИКАЦИЯ: <victory/defeat/inconclusive>
```

#### Фаза 3 — Personnel summary

```text
СОСТОЯНИЕ ЛИЧНОГО СОСТАВА

ВСЕГО:             N
В СТРОЮ:           N
ТЯЖЕЛО РАНЕНЫ:     N
ПОГИБЛИ:           N
НЕТ СИГНАЛА:       N
```

#### Фаза 4 — Personnel/casualty pages

Для каждого участника:

```text
<rank> <name>
ОТРЯД: <squad>
РОЛЬ: <role>
СОСТОЯНИЕ: <status>
ПРИЧИНА: <death reason, только если погиб>
```

#### Фаза 5 — Final transmission

Victory:

```text
ОТЧЁТ ПЕРЕДАН В ШТАБ.
СТАТУС КАНАЛА: ЗАВЕРШЕНО.
```

Defeat:

```text
ПОСЛЕДНИЙ ПАКЕТ ДАННЫХ ПЕРЕДАН.
СТАТУС КАНАЛА: АВАРИЙНОЕ ЗАВЕРШЕНИЕ.
```

Inconclusive:

```text
ОТЧЁТ СОХРАНЁН.
СТАТУС КАНАЛА: ОЖИДАНИЕ ПОДТВЕРЖДЕНИЯ.
```

---

## 3. Этап 1 — стабилизировать автоматический запуск интро

### 3.1. Проверить текущий entrypoint

Сейчас PR #106 меняет:

```dm
/mob/living/carbon/human/proc/play_opening_sequence()
```

и вызывает:

```dm
GLOB.round_cinematics?.try_start_cryo_intro(src)
```

Проблема: этого недостаточно, если proc не вызывается или вызывается до помещения в cryopod.

### 3.2. Добавить deferred queue

Файл:

```text
modular/round_cinematics/code/round_cinematics_controller.dm
```

Добавить proc:

```dm
/datum/round_cinematics_controller/proc/queue_cryo_intro(mob/living/carbon/human/human, reason = "unknown", attempts_left = 3)
```

Логика:

```dm
if(!istype(human) || !human.client)
    return FALSE
if(human.stat == DEAD)
    return FALSE
if(get_intro_session(human))
    return FALSE

addtimer(CALLBACK(src, PROC_REF(_queue_cryo_intro_tick), human, reason, attempts_left), 1)
return TRUE
```

Добавить internal proc:

```dm
/datum/round_cinematics_controller/proc/_queue_cryo_intro_tick(mob/living/carbon/human/human, reason, attempts_left)
```

Логика:

1. Проверить `human`, `client`, `stat`, existing session.
2. Если human в cryopod — вызвать `try_start_cryo_intro(human)`.
3. Если не в cryopod и attempts_left > 0:
   - повторить через 1–2 секунды.
4. Если attempts_left == 0:
   - тихо завершить без runtime.
   - опционально debug log при включённом debug flag.

### 3.3. Использовать queue вместо прямого запуска

В `human.dm` заменить прямой вызов на queue:

```dm
// SS220 EDIT: queue modular cryo intro after opening sequence starts
if(GLOB.round_cinematics?.queue_cryo_intro(src, "play_opening_sequence"))
    sleeping = 11
```

Важно: не ставить `sleeping = 11`, если queue отказалась из-за no client/dead/already running.

### 3.4. Добавить второй hook после фактического cryopod placement

Агент должен найти точный callsite.

Discovery:

```bash
rg -n "occupant =|forceMove\\(.*cryopod|move_inside|go_in|hypersleep|latejoin|play_opening_sequence" code modular
```

И добавить минимальный hook в точке, где:

- human уже существует;
- client уже есть;
- job/equipment уже назначены;
- human уже находится в cryopod или сейчас будет помещён туда.

Форма:

```dm
// SS220 EDIT: queue modular cryo intro after cryopod occupant setup
GLOB.round_cinematics?.queue_cryo_intro(H, "cryopod_placement")
```

Если такого callsite нет или он слишком рискованный — оставить только `play_opening_sequence`, но обязательно выяснить, почему он не вызывается.

### 3.5. Добавить debug verb или debug log

В admin preview/verbs добавить диагностический вывод:

- почему intro не стартует;
- client есть/нет;
- pod есть/нет;
- `SSticker.intro_sequence` true/false;
- existing session есть/нет.

Не выводить игрокам постоянно.

### 3.6. Acceptance criteria

- Обычный round start: игрок в cryopod получает intro автоматически.
- Latejoin: игрок в cryopod получает intro автоматически.
- Preview admin verb работает.
- Интро не стартует дважды.
- Если игрок не в cryopod, обычный gameplay не блокируется.
- Если `SSticker.intro_sequence == FALSE`, intro не стартует, кроме preview.
- Нет runtime при no client / disconnect / qdel.

---

## 4. Этап 2 — сделать нормальный terminal visual layer

### 4.1. Не использовать HTML browser

PR #29 можно использовать как визуальный референс, но не как runtime-архитектуру.

Запрещено переносить:

- `html/colonial_marine_intro.html`;
- Tailwind;
- Google Fonts;
- CDN;
- browser UI.

Разрешено переносить идеи:

- green CRT palette;
- terminal header/footer;
- scanlines;
- glow;
- flicker;
- turn-on/turn-off;
- glitch;
- status grid;
- personal file layout;
- logo/ASCII style.

### 4.2. Ввести terminal renderer

Добавить файл:

```text
modular/round_cinematics/code/round_cinematics_terminal.dm
```

Новые типы:

```dm
/datum/round_cinematics_terminal_profile
/datum/round_cinematics_terminal_state
/atom/movable/screen/round_cinematics_terminal/body
/atom/movable/screen/round_cinematics_terminal/header
/atom/movable/screen/round_cinematics_terminal/footer
/atom/movable/screen/round_cinematics_terminal/frame
/atom/movable/screen/round_cinematics_terminal/glitch
```

Минимальная версия может быть проще:

```dm
/atom/movable/screen/text/round_cinematics_terminal
```

Но она должна рендерить весь экранный terminal layout, а не только центральный текст.

### 4.3. Перейти от “одного text_box” к persistent shell

Сейчас каждая фаза создаёт text object. Лучше:

- session создаёт persistent terminal shell в начале;
- shell содержит:
  - background/fullscreen;
  - header;
  - body;
  - footer;
  - optional glitch overlay;
- фазы обновляют только body/header/status;
- cleanup удаляет весь shell.

Добавить в session:

```dm
var/datum/round_cinematics_terminal/terminal
```

или:

```dm
var/list/active_terminal_atoms = list()
```

Методы:

```dm
/datum/round_cinematics_session/proc/create_terminal(datum/round_cinematics_terminal_profile/profile)
/datum/round_cinematics_session/proc/update_terminal_body(html, datum/round_cinematics_phase/phase)
/datum/round_cinematics_session/proc/destroy_terminal()
```

### 4.4. Если делать без отдельного datum

Можно расширить текущий `round_cinematics_screen.dm`:

- добавить `screen_loc = "CENTER,CENTER"` или корректную центровку;
- увеличить maptext до full-screen-like размера;
- в `build_terminal_html()` собирать ASCII/HTML layout:

```dm
/proc/round_cinematics_build_terminal_layout(header_left, header_right, body, footer_left, footer_right, profile)
```

Пример body layout:

```html
<div style='font-family:"Courier New", monospace; color:#00ff41; text-align:left;'>
  <div>USCM-TERMINAL-7.02                                      КРИО-ОТСЕК 04. СЕКТОР B.</div>
  <div>────────────────────────────────────────────────────────────────────────────</div>
  <br>
  <div style='text-align:center;'>USMC</div>
  <br>
  <div>┌────────────────────────────────────────────────────────────┐</div>
  <div>│ СИСТЕМА:                                  ОК              │</div>
  <div>│ КРИО-СТАТУС:                              ВЫХОД           │</div>
  <div>└────────────────────────────────────────────────────────────┘</div>
  <br>
  <div>────────────────────────────────────────────────────────────────────────────</div>
  <div>© 2180 ...                                      BANDA TROOPERS CUR-S. E. 220</div>
</div>
```

Важно: BYOND maptext поддерживает не весь CSS. Поэтому не полагаться на сложные CSS border/shadow. Основу делать через monospace ASCII/box drawing.

### 4.5. Добавить визуальный профиль

Новый файл:

```text
modular/round_cinematics/code/round_cinematics_visual_profile.dm
```

Тип:

```dm
/datum/round_cinematics_visual_profile
    var/id
    var/text_color
    var/dim_color
    var/accent_color
    var/background_color
    var/header_left
    var/header_right
    var/footer_left
    var/footer_right
    var/flicker_strength = 0
    var/glitch_strength = 0
    var/default_sound = null
```

Factory procs:

```dm
/proc/round_cinematics_intro_profile(mob/living/carbon/human/human)
/proc/round_cinematics_outro_profile(datum/round_cinematics_outcome/outcome)
```

Профили:

```dm
/datum/round_cinematics_visual_profile/intro_green
/datum/round_cinematics_visual_profile/outro_victory
/datum/round_cinematics_visual_profile/outro_defeat
/datum/round_cinematics_visual_profile/outro_inconclusive
```

### 4.6. Цвета

Intro:

```dm
text_color = "#00ff41"
dim_color = "#008f2a"
accent_color = "#39ff6a"
background_color = "#001a05"
```

Victory:

```dm
text_color = "#6dff8f"
dim_color = "#1a7f3a"
accent_color = "#b7ffd0"
background_color = "#001a08"
```

Defeat:

```dm
text_color = "#ff4a3d"
dim_color = "#8f241f"
accent_color = "#ffb14a"
background_color = "#180000"
glitch_strength = 2
```

Inconclusive:

```dm
text_color = "#ffd35a"
dim_color = "#8f7526"
accent_color = "#fff0a0"
background_color = "#141000"
glitch_strength = 1
```

### 4.7. Acceptance criteria

- Интро визуально узнаётся как зелёный CRT terminal.
- Есть header/footer.
- Есть рамка/панель данных.
- Есть boot/status фаза.
- Личное дело похоже на предоставленный скриншот.
- На маленьком экране текст не уходит полностью за пределы.
- Cleanup удаляет все screen atoms.
- HUD возвращается после окончания/skip/logout.

---

## 5. Этап 3 — исправить typewriter и добавить эффекты

### 5.1. Исправить HTML-safe typewriter

Текущий код в `round_cinematics_screen.dm` печатает через `copytext_char(text_to_play, 1, letter)` и пытается пропускать HTML tags.

Нужно заменить на tokenized typewriter.

Добавить helper:

```dm
/proc/round_cinematics_visible_steps(html)
```

или:

```dm
/proc/round_cinematics_typewriter_frames(html, letters_per_update)
```

Требования:

- HTML tags должны добавляться целиком и сразу;
- visible chars печатаются по шагам;
- entities (`&nbsp;`, `&lt;`) не ломаются;
- на каждом frame возвращается валидный HTML/maptext;
- не выводить частичные `<span sty`.

Пример логики:

1. Идти по строке.
2. Если встречен `<` — скопировать до следующего `>` целиком, не увеличивая visible_count.
3. Если встречен `&` — скопировать до `;` целиком, увеличить visible_count на 1.
4. Обычный символ — увеличить visible_count.
5. Создать frame после каждых `letters_per_update` visible chars.
6. Финальный frame — полный html.

### 5.2. Добавить post-line pauses

Для терминального эффекта нужны паузы после строк:

- после строки с `ONLINE`;
- после заголовка;
- после `> ИНИЦИАЛИЗАЦИЯ`;
- после outcome splash.

Можно реализовать через маркер в raw text:

```text
[[PAUSE:5]]
```

или через phase fields:

```dm
var/list/pause_after_visible_chars = list()
var/list/pause_after_lines = list()
```

Проще для v1:

- build frames по строкам;
- после каждой строки делать `sleep(line_delay)`;
- внутри строки печатать chars.

Добавить в phase:

```dm
var/typewriter_mode = ROUND_CINEMATICS_TYPEWRITER_CHAR
var/line_delay = 0.2 SECONDS
var/section_delay = 0.5 SECONDS
```

### 5.3. Добавить flicker/glitch

В `round_cinematics_effects.dm`:

```dm
/datum/round_cinematics_session/proc/effect_flicker(atom/movable/screen/target, times = 3, low_alpha = 180)
/datum/round_cinematics_session/proc/effect_glitch(atom/movable/screen/target, strength = 2, duration = 0.4 SECONDS)
/datum/round_cinematics_session/proc/effect_power_on()
/datum/round_cinematics_session/proc/effect_power_off()
```

Реализация без сложной графики:

- alpha flicker: `animate(target, alpha = 120, time = 1); animate(alpha = 255, time = 1)`
- pixel shift: временно `pixel_x = rand(-2, 2)`, `pixel_y = rand(-1, 1)`, вернуть;
- color pulse: `animate(color = profile.accent_color, time = 1); animate(color = profile.text_color, time = 2)`
- для defeat — повторить glitch чаще.

Важно: все spawned/async loops должны проверять `session.cleaned_up`.

### 5.4. Звуки

Использовать только существующие assets. Сначала проверить:

```bash
find sound -iname "*cryo*" -o -iname "*beep*" -o -iname "*terminal*" -o -iname "*alarm*" -o -iname "*siren*"
rg -n "cryo_beep|cryo_intro|cryo_opening|playsound_client" code modular
```

Если существуют:

- intro boot: `cryo_beep.ogg`
- intro exit: `cryo_opening.ogg` или подходящий existing sound
- defeat: alarm/error beep, если есть
- victory: confirmation beep, если есть
- inconclusive: neutral beep

Если asset не найден — не добавлять новый binary без согласования.

### 5.5. Acceptance criteria

- Typewriter не ломает HTML/maptext.
- Печать выглядит построчной, а не просто быстрым появлением текста.
- Есть flicker/power-on.
- Defeat имеет заметный glitch/alarm style.
- Victory стабильнее и чище.
- Эффекты не создают бесконечные loops после cleanup.

---

## 6. Этап 4 — развести visual outcome для победы/поражения

### 6.1. Расширить outcome profile

В `round_outro_sequence.dm` сейчас все страницы используют один и тот же fullscreen + phase settings.

Нужно:

```dm
var/datum/round_cinematics_visual_profile/profile = round_cinematics_outro_profile(context.outcome)
```

И передавать profile в каждую phase:

```dm
page.visual_profile = profile
page.color = profile.text_color
page.sound = profile.default_sound
```

### 6.2. Добавить outcome splash page

В `round_outro_context.dm` или `round_outro_report.dm` добавить первую страницу:

```dm
/proc/round_cinematics_outro_render_outcome_splash(datum/round_cinematics_outro_context/context)
```

Контент зависит от `outcome.classification`.

Victory:

```text
ОПЕРАЦИЯ ЗАВЕРШЕНА: УСПЕХ
КЛАССИФИКАЦИЯ: ПОБЕДА МОРСКОЙ ПЕХОТЫ
```

Defeat:

```text
ОПЕРАЦИЯ ЗАВЕРШЕНА: ПОРАЖЕНИЕ
КЛАССИФИКАЦИЯ: ПОТЕРЯ ОПЕРАЦИОННОГО КОНТРОЛЯ
```

Inconclusive:

```text
ИСХОД ОПЕРАЦИИ НЕ ПОДТВЕРЖДЁН
КЛАССИФИКАЦИЯ: НЕОПРЕДЕЛЁННО
```

### 6.3. Разные отчётные формулировки

В `round_outro_report.dm` добавить helper:

```dm
/proc/round_cinematics_outro_outcome_header(datum/round_cinematics_outcome/outcome)
/proc/round_cinematics_outro_outcome_footer(datum/round_cinematics_outcome/outcome)
```

Победа:

- “Штаб подтверждает выполнение основных задач.”
- “Контроль зоны операции сохранён.”

Поражение:

- “Штаб фиксирует потерю контроля зоны операции.”
- “Последняя телеметрия содержит критические потери.”

Неопределённо:

- “Данные операции неполны.”
- “Требуется ручная проверка штаба.”

### 6.4. Разные personnel emphasis

Victory:

- сначала summary;
- потом полный personnel list.

Defeat:

- сначала casualties/dead;
- потом survivors;
- усилить “ПОГИБ” / “НЕТ СИГНАЛА”.

Inconclusive:

- нейтральный список;
- выделить missing/no signal.

### 6.5. Acceptance criteria

- Победа и поражение различаются с первого экрана.
- Отличаются цвета.
- Отличаются заголовки.
- Отличаются footer/final transmission.
- Отличаются эффекты: defeat более аварийный.
- Авто outcome виден как `РЕЖИМ: АВТО`.

---

## 7. Этап 5 — автоматизировать outcome mapping

### 7.1. Проверить все constants

Выполнить:

```bash
rg -n "MODE_INFESTATION|MODE_INFECTION|MODE_.*WIN|round_finished|round_result" code modular
```

Составить таблицу:

| Constant | Classification |
|---|---|
| `MODE_INFESTATION_M_MAJOR` | marine victory |
| `MODE_INFESTATION_M_MINOR` | marine victory |
| `MODE_INFESTATION_X_MAJOR` | marine defeat |
| `MODE_INFESTATION_X_MINOR` | marine defeat |
| `MODE_INFESTATION_DRAW_DEATH` | inconclusive |
| `MODE_INFECTION_ZOMBIE_WIN` | marine defeat |
| другие найденные | определить по смыслу |

### 7.2. Расширить `round_cinematics_round_finished_label`

Файл:

```text
modular/round_cinematics/code/round_cinematics_helpers.dm
```

Сейчас есть basic mapping. Расширить найденными constants.

Требования:

- неизвестное значение не runtime;
- неизвестное значение попадает в inconclusive;
- detail содержит raw result;
- классификация не зависит от языка label.

### 7.3. Проверить timing вызова `try_start_round_outro`

Сейчас hooks стоят в нескольких `declare_completion()`. Нужно убедиться, что к моменту вызова:

- `mode.round_finished` уже выставлен;
- `GLOB.round_statistics.round_result`, если используется, уже выставлен;
- `announce_ending()` не блокирует/не очищает clients.

Если hook стоит слишком рано — перенести ниже, после выставления `round_finished`/statistics, но до музыкального/финального flow, если нужно.

### 7.4. Уменьшить количество hooks, если возможно

Поискать общий hook:

```bash
rg -n "/datum/game_mode/.*/declare_completion|/datum/game_mode/proc/declare_completion|announce_ending\\(" code/game/gamemodes code/controllers modular
```

Если существует общий proc, предпочтительно:

- один hook там;
- не размазывать по `colonialmarines.dm`, `huntergames.dm`, `whiskey_outpost.dm`, `xenovsxeno.dm`, `extended.dm`, `infection.dm`.

Если общего безопасного места нет:

- оставить текущие per-mode hooks;
- все hooks оформить `SS220 EDIT`;
- добавить комментарий почему нет общего hook.

### 7.5. Admin override

Оставить verbs:

- auto;
- marine victory;
- marine defeat;
- inconclusive.

Но:

- default должен быть AUTO;
- preview должен позволять preview конкретного outcome без изменения будущего round outcome;
- после реального `try_start_round_outro()` override должен сбрасываться после build context, как сейчас.

Добавить удобный preview:

```dm
/client/proc/preview_round_outro_victory()
/client/proc/preview_round_outro_defeat()
/client/proc/preview_round_outro_inconclusive()
```

Если не хочется новых verbs — использовать существующий set override + preview, но тогда в плане тестирования явно прописать.

### 7.6. Acceptance criteria

- При marine victory автоматически показывается victory outro.
- При marine defeat автоматически показывается defeat outro.
- При draw автоматически показывается inconclusive outro.
- Admin override меняет outcome.
- Auto mode после override возвращается в auto.
- Unknown round result не runtime и показывает inconclusive.

---

## 8. Этап 6 — улучшить данные интро и аутро

### 8.1. Интро personal data

В `cryo_intro_context.dm` проверить, что поля берутся так:

- name: `human.real_name || human.name`;
- rank: ID/paygrade prefix + readable rank, если есть;
- squad: `human.assigned_squad?.name`;
- role: ID assignment или `human.job`;
- faction profile: UNSC/USCM label.

Добавить fallback:

```dm
НЕИЗВЕСТНО
НЕТ ДАННЫХ
UNKWN
```

Не выводить `null`.

### 8.2. Squad manifest

Текущий helper собирает по `GLOB.alive_human_list` или `GLOB.human_mob_list`. Нужно определить правильный список.

Для intro предпочтительно:

- same faction;
- same squad, если assigned_squad есть;
- если squad пустой — same faction ship-side players;
- исключить ground mobs, если intro в ship cryo и это старый intended behavior;
- исключить observers/newplayers.

Сортировка:

1. same squad first;
2. squad role priority:
   - squad leader;
   - deputy/FTL;
   - corpsman;
   - specialist;
   - engineer;
   - rifleman;
3. rank/paygrade;
4. name.

### 8.3. Outro participants

Текущий `build_participants()` проходит по `GLOB.human_mob_list` и берёт тех, у кого есть `client` или `mind`.

Улучшить:

- добавить rank;
- добавить squad;
- добавить role;
- добавить status;
- не показывать non-player NPC/AI, если они не должны быть в отчёте;
- определить, нужны ли UNSC/HALO AI участники в отчёте;
- возможно, показывать только faction marine/UNSC.

Статусы:

```text
В СТРОЮ
ТЯЖЕЛО РАНЕН
ПОГИБ
НЕТ СИГНАЛА
```

Mapping:

- `DEAD` -> `ПОГИБ`;
- `UNCONSCIOUS` / crit / severe damage -> `ТЯЖЕЛО РАНЕН`;
- alive + client/mind -> `В СТРОЮ`;
- missing body but mind existed? если можно определить -> `НЕТ СИГНАЛА`.

### 8.4. Death reasons

Текущий `round_cinematics_human_death_reason()` уже categorizes by `last_damage_data`.

Расширить осторожно:

- explosion;
- thermal;
- acid/xeno;
- gunfire;
- crushing;
- unknown.

Русские labels:

```dm
"ВЗРЫВНАЯ ТРАВМА"
"ТЕРМИЧЕСКОЕ ПОРАЖЕНИЕ"
"КСЕНОУГРОЗА"
"ОГНЕСТРЕЛЬНОЕ РАНЕНИЕ"
"ТРАВМА ОТ УДАРА/СДАВЛИВАНИЯ"
"ПРИЧИНА НЕ УСТАНОВЛЕНА"
```

Не выводить raw `cause_name`, если он технический/английский, кроме fallback debug.

### 8.5. Acceptance criteria

- В интро нет `null`.
- В аутро нет `UNKNOWN`, если можно заменить русским fallback.
- Роли/отряды отображаются.
- Большой список участников пагинируется.
- Причины смерти читаемы и не runtime при пустом `last_damage_data`.

---

## 9. Этап 7 — cleanup, safety, lifecycle

### 9.1. Проверить cleanup

Сейчас session имеет:

- `abort_texts()`;
- `clear_fullscreens()`;
- `restore_hud()`;
- `finish_session()`;
- signal handlers for logout/qdel/pod exit.

Нужно дополнить:

- cleanup terminal shell atoms;
- cleanup active effect loops;
- cleanup sounds if channel is used and stoppable;
- cleanup on round restart;
- cleanup if client changes mob.

### 9.2. Проверить HUD restore

Сейчас session сохраняет:

```dm
saved_hud_version
saved_hud_shown
saved_inventory_shown
saved_action_buttons_hidden
saved_hotkey_ui_hidden
```

Проверить, что после `show_hud(saved_hud_version, owner)` реально восстанавливаются:

- hotkey UI;
- action buttons;
- inventory;
- selected hand / intent / health UI.

Если нет — добавить точечный restore через существующие HUD procs, но не менять глобальную HUD систему.

### 9.3. Проверить cryopod unlock

`handle_cryo_exit_attempt()`:

- до skip blocks;
- после skip завершает session и позволяет выйти.

Hard timeout должен:

- finish session;
- не вызывать eject автоматически;
- позволить игроку выйти вручную.

### 9.4. Acceptance criteria

- Нет вечного black screen.
- Нет вечного no-HUD.
- Нет вечного cryo lock.
- Нет runtime при logout во время typewriter.
- Нет runtime при qdel pod.
- Нет runtime при round restart.
- Preview можно остановить force-stop verb.

---

## 10. Файловый план

### 10.1. Изменять/добавлять в `modular/round_cinematics/**`

Добавить:

```text
modular/round_cinematics/code/round_cinematics_visual_profile.dm
modular/round_cinematics/code/round_cinematics_terminal.dm
modular/round_cinematics/code/round_cinematics_typewriter.dm
modular/round_cinematics/code/round_cinematics_effects.dm
```

Изменить:

```text
modular/round_cinematics/_round_cinematics.dm
modular/round_cinematics/_round_cinematics.dme
modular/round_cinematics/code/round_cinematics_controller.dm
modular/round_cinematics/code/round_cinematics_session.dm
modular/round_cinematics/code/round_cinematics_phase.dm
modular/round_cinematics/code/round_cinematics_screen.dm
modular/round_cinematics/code/round_cinematics_helpers.dm
modular/round_cinematics/code/intro/cryo_intro_context.dm
modular/round_cinematics/code/intro/cryo_intro_sequence.dm
modular/round_cinematics/code/outro/round_outro_context.dm
modular/round_cinematics/code/outro/round_outro_report.dm
modular/round_cinematics/code/outro/round_outro_sequence.dm
modular/round_cinematics/code/outro/round_outro_outcome.dm
modular/round_cinematics/code/admin/round_outro_admin.dm
```

### 10.2. Upstream files — только минимально

Проверить/минимизировать:

```text
code/modules/mob/living/carbon/human/human.dm
code/game/machinery/cryopod.dm
code/modules/admin/admin_verbs.dm
code/game/gamemodes/colonialmarines/colonialmarines.dm
code/game/gamemodes/colonialmarines/huntergames.dm
code/game/gamemodes/colonialmarines/whiskey_outpost.dm
code/game/gamemodes/colonialmarines/xenovsxeno.dm
code/game/gamemodes/extended/extended.dm
code/game/gamemodes/extended/infection.dm
```

Если найден общий hook round-end — сократить gamemode changes.

### 10.3. Revert unless needed

```text
tgui/packages/tgui/interfaces/AlertModal.tsx
```

Откатить, если изменение не требуется.

---

## 11. Конкретные implementation tasks

### Task A — `queue_cryo_intro`

1. Добавить `queue_cryo_intro`.
2. Добавить `_queue_cryo_intro_tick`.
3. Заменить прямой вызов в `play_opening_sequence()` на queue.
4. Найти и добавить второй hook после cryopod placement, если нужен.
5. Добавить debug reason.

### Task B — visual profiles

1. Добавить `round_cinematics_visual_profile.dm`.
2. Добавить intro/victory/defeat/inconclusive profiles.
3. Добавить profile field в phase/session.
4. Передавать profile из intro/outro sequence.

### Task C — terminal layout

1. Добавить terminal builder.
2. Header/footer/body.
3. ASCII frame/data-grid.
4. Body update per phase.
5. Cleanup.

### Task D — typewriter

1. Убрать текущий fragile HTML-skip loop.
2. Добавить tokenizer/frames.
3. Добавить line delay.
4. Проверить tags/entities.

### Task E — intro sequence

1. Разбить intro на:
   - power_on;
   - boot_status;
   - personal_file;
   - manifest pages;
   - exit.
2. Добавить sounds.
3. Добавить flicker/power-on.
4. Увеличить timings.

### Task F — outro sequence

1. Добавить outcome splash.
2. Добавить profile by outcome.
3. Развести content для victory/defeat/inconclusive.
4. Добавить personnel counts.
5. Улучшить participant entries.

### Task G — outcome automation

1. Расширить mapping constants.
2. Проверить all gamemode hooks.
3. Сократить hooks при наличии общего callsite.
4. Добавить tests/manual debug.

### Task H — admin/preview

1. Preview intro.
2. Preview outro auto.
3. Preview victory/defeat/inconclusive или documented flow через override.
4. Force stop.
5. Debug why intro did not start.

---

## 12. Manual test matrix

### 12.1. Intro

| Test | Expected |
|---|---|
| Round start marine in cryopod | Intro starts automatically |
| Latejoin marine in cryopod | Intro starts automatically |
| Admin preview intro | Works outside normal start |
| Press eject before 5 sec | Blocked with message |
| Press eject after 5 sec | Intro closes and ejection works |
| Disconnect during intro | No runtime, cleanup |
| Reconnect after intro | HUD normal |
| Death/qdel during intro | No runtime |
| No squad assigned | Fallback text, no runtime |
| No ID card | Fallback rank/role, no runtime |
| Large squad | Pagination |

### 12.2. Outro

| Test | Expected |
|---|---|
| Marine victory result | Victory color/profile/text |
| Marine defeat result | Defeat color/profile/text |
| Draw/inconclusive | Amber/neutral profile |
| Unknown result | Inconclusive fallback |
| Admin override victory | Victory outro regardless of auto |
| Admin override defeat | Defeat outro regardless of auto |
| Auto after override reset | Auto mapping used |
| Many participants | Pagination |
| Dead participant without cause | Unknown cause fallback |
| Client without mob/newplayer | Not shown / no runtime |
| Force stop outro | Clears overlays |

### 12.3. Regression

| Test | Expected |
|---|---|
| Build compile | Pass |
| Existing round end music/messages | Still happen |
| Existing cryopod eject | Works after intro/without intro |
| HUD after intro | Restored |
| HUD after outro | Restored/normal |
| No TGUI regression | `AlertModal.tsx` unchanged unless needed |

---

## 13. Проверки

Минимум:

```bash
git diff --check
tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror
```

Если TGUI всё же менялся:

```bash
tools/build/build --ci lint tgui-test
```

Если добавлялись/менялись DMI/icons:

```bash
tools/bootstrap/python -m dmi.test
```

Если maps не трогались — map checks не нужны.

---

## 14. PR body после доработки

Заменить текущий placeholder на нормальное описание:

```md
# About the pull request

Добавляет модульные round cinematics: автоматическое крио-интро при пробуждении/latejoin и автоматическое аутро в конце раунда.

Интро оформлено как зелёный CRT/terminal wake-up sequence: boot/status экран, личное дело, манифест отряда, typewriter-печать, fullscreen CRT/black overlays, звуки и безопасный cleanup.

Аутро оформлено как военный отчёт операции. Исход определяется автоматически по `round_finished`, при этом администратор может задать override. Победа, поражение и неопределённый исход имеют разные визуальные профили, тексты и эффекты.

# Explain why it's good for the game

- Улучшает атмосферу начала и конца операции.
- Даёт игроку контекст: кто он, какой у него отряд, кто рядом.
- Делает конец раунда более выразительным и читаемым.
- Сохраняет модульность: основная логика находится в `modular/round_cinematics/**`, upstream содержит только минимальные hooks.

# Testing Photographs and Procedure

- [ ] Round start marine cryo intro starts automatically.
- [ ] Latejoin cryo intro starts automatically.
- [ ] Intro can be skipped after configured delay.
- [ ] HUD restores after intro/skip/logout.
- [ ] Round outro starts automatically on marine victory.
- [ ] Round outro starts automatically on marine defeat.
- [ ] Victory/defeat/inconclusive use different visual profiles.
- [ ] Admin override works.
- [ ] Force stop cinematic clears overlays.
- [ ] `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`

# Changelog

:cl:
add: Добавлены автоматические крио-интро и аутро операции в стиле военного терминала.
add: Аутро теперь автоматически определяет победу, поражение или неопределённый исход.
add: Победа, поражение и неопределённый исход получили разные визуальные профили.
add: Добавлены терминальные эффекты: печать, CRT/flicker/glitch, header/footer и отчётные панели.
/:cl:
```

---

## 15. Готовый промт для агента

Скопируй агенту:

```text
Работаем в PR #106 `round cinematics` репозитория ss220club/BandaTroopers.

Цель: доработать текущий модуль `modular/round_cinematics/**`, чтобы:
1. крио-интро автоматически запускалось при round start/latejoin для игроков в cryopod;
2. интро визуально стало атмосферным terminal/CRT wake-up sequence как в референсах PR #29/#31: зелёный терминал, тёмный фон, scanlines/CRT, header/footer, рамки, boot/status, личное дело, манифест, typewriter-печать, звуки и эффекты;
3. аутро автоматически запускалось в конце раунда;
4. victory/defeat/inconclusive выглядели по-разному: разные цвета, заголовки, формулировки, звуки и glitch/flicker intensity;
5. admin override остался, но default был AUTO;
6. не использовать browser/HTML runtime, CDN, Tailwind, Google Fonts;
7. сохранить модульность: вся логика в `modular/round_cinematics/**`, upstream `code/**` только минимальные hooks с SS220 EDIT;
8. не менять `AlertModal.tsx`, если это не строго необходимо.

Перед правками выполнить discovery:
- `rg -n "round_cinematics|try_start_cryo_intro|try_start_round_outro|play_opening_sequence|intro_sequence|declare_completion|announce_ending|round_finished|round_result|MODE_INFESTATION|COMSIG_CRYOPOD" code modular`
- `rg -n "overlay_fullscreen|clear_fullscreen|/atom/movable/screen/fullscreen|screen_text|play_screen_text|playsound_client|cryo_beep|cryo_intro|cryo_opening" code modular`
- `rg -n "SS220 EDIT" code map_config`
- `rg -n "SS220 EDIT" modular -g "!modular/__agents/**" -g "!modular/__docs/**"`

Реализовать этапами:

Этап 1:
- проверить current diff;
- убрать/откатить `tgui/packages/tgui/interfaces/AlertModal.tsx`, если не нужен;
- проверить удаление `modular/fullscreen/**`;
- убедиться, что модуль подключён через `modular/modular.dme`.

Этап 2:
- добавить `queue_cryo_intro(human, reason, attempts_left)` в `round_cinematics_controller.dm`;
- заменить прямой старт intro в `play_opening_sequence()` на queue;
- найти фактический callsite помещения human в cryopod/latejoin и добавить минимальный hook туда, если `play_opening_sequence()` не гарантирован;
- добавить debug reason, почему intro не стартует;
- проверить cryopod lock/skip/hard timeout.

Этап 3:
- добавить visual profiles: intro green, outro victory, outro defeat, outro inconclusive;
- добавить terminal layout renderer: persistent header/body/footer/frame;
- не полагаться на сложный CSS, использовать monospace/ASCII/maptext/screen atoms/fullscreen overlays;
- сделать экран похожим на предоставленные скриншоты: `USCM-TERMINAL-7.02`, `КРИО-ОТСЕК`, зелёные тона, тёмный фон, рамка, личное дело, список отряда, footer.

Этап 4:
- переписать typewriter на HTML-safe tokenizer, чтобы не выводились частичные HTML tags;
- добавить line pauses;
- добавить flicker/glitch/power-on/power-off effects через animate/pixel shift/alpha;
- все loops должны проверять `session.cleaned_up`.

Этап 5:
- intro sequence разбить на power_on, boot_status, personal_file, manifest pages, exit;
- добавить sounds только из существующих assets;
- увеличить timings до читаемых.

Этап 6:
- outro sequence начать с outcome splash;
- добавить разные цвета/тексты/effects для victory/defeat/inconclusive;
- расширить personnel summary: всего, в строю, ранены, погибшие, нет сигнала;
- улучшить participant entries: rank, name, squad, role, status, death reason.

Этап 7:
- расширить auto outcome mapping по всем найденным round_finished constants;
- проверить gamemode hooks и по возможности заменить множественные hooks на общий hook;
- если общего hook нет, оставить per-mode hooks с SS220 EDIT и комментарием.

Этап 8:
- проверить cleanup: intro/outro/preview/logout/qdel/round restart;
- убедиться, что HUD, fullscreen overlays, terminal atoms, text boxes и effects очищаются всегда.

Проверки:
- `git diff --check`
- `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
- если TGUI всё же менялся: `tools/build/build --ci lint tgui-test`

Acceptance:
- intro starts automatically on round start cryo;
- intro starts automatically on latejoin cryo;
- intro has terminal CRT effects and typewriter;
- victory/defeat/inconclusive outro are visually distinct;
- outro starts automatically at round end;
- admin override still works;
- no stuck no-HUD;
- no stuck cryopod lock;
- no runtime on logout/qdel/disconnect;
- PR body updated with real testing procedure.
```
