# EVIDENCE

## E-001: Исходное git-состояние перед sync
- Активная ветка: `various_fixes`.
- `git status --short --branch` показал чистое рабочее дерево до начала работы.
- Незавершенных merge/rebase не было: `MERGE_HEAD`, `rebase-merge`, `rebase-apply` отсутствовали.

## E-002: Divergence с локальным `upstream/master`
- `git rev-list --left-right --count upstream/master...HEAD` вернул `2 383`.
- Локальный `upstream/master` указывает на `ffce50cb00` (`HALO build PORT (#59)`).
- Merge-base `HEAD` и `upstream/master`: `21baf372d8431a935c82320eb08a17f725db362e`.

## E-003: Дополнительные наблюдения
- В истории `various_fixes` уже есть merge-коммиты вида `Merge branch 'master' into various_fixes`.
- Файл `HALO_PORT_STATE.md`, упомянутый в repo-routing, не найден через `rg --files -g "HALO_PORT_STATE.md"`.

## E-004: Fetch и merge
- `git fetch upstream master` выполнен успешно 2026-03-08.
- `FETCH_HEAD` и `upstream/master` указывают на `ffce50cb00917c9fe49af45829ebd6ba45190ca4` (`HALO build PORT (#59)`).
- Во время merge возникло 7 текстовых конфликтов:
  - `code/__DEFINES/mob_hud.dm`
  - `code/__DEFINES/mode.dm`
  - `code/controllers/subsystem/communications.dm`
  - `code/datums/mob_hud.dm`
  - `code/game/jobs/job/marine/squads.dm`
  - `code/modules/cm_marines/equipment/maps.dm`
  - `map_config/maps.txt`

## E-005: Стратегия разрешения конфликтов
- Сохранены веточные добавления `FIL`/`SISSI` и одновременно приняты upstream HALO-добавления `UNSC`/`ODST`.
- В `code/modules/cm_marines/equipment/maps.dm` объединены:
  - JSON-priority для `map_item_type`,
  - guard на отсутствие `GROUND_MAP`,
  - fallback/diagnostic path через существующий `resolve_current_map_type()` и `log_runtime`.
- В `map_config/maps.txt` сохранены веточные карты `lv671`, `oil_depot`, `derelict_almayer_infested` и добавлена upstream-rotation запись `halo_new_irvine`.

## E-006: Проверки после разрешения конфликтов
- `git diff --check`: passed.
- `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_BASE`: passed, `0 errors, 0 warnings`, завершение в `2026-03-08 14:30`.
- `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_EXTRA`: passed, `0 errors, 0 warnings`, завершение в `2026-03-08 14:32`.
- После merge в рабочем дереве появился `modular/halo/__docs/HALO_PORT_STATE.md`; он подтверждает staged map compile как accepted validation signal для HALO sync.
