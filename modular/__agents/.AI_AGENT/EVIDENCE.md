# EVIDENCE

## E-001: Стартовое состояние ветки
- Рабочая ветка для задачи находится в отдельном worktree: `D:/GitHub/_bt_port_tech`.
- `git status --short --branch` перед правками показал чистое дерево.
- Локальная ветка `port/tech-vehicle-wave` была fast-forward'нута до `origin/port/tech-vehicle-wave`.

## E-002: Область перевода
- `gh pr view 84 --repo ss220club/BandaTroopers` подтвердил, что работа идёт по PR #84 `PhantornRU:port/tech-vehicle-wave`.
- `git diff --name-only upstream/master...HEAD -- '*.dm' '*.yml' '*.json' '*.jsx'` сузил scope до набора файлов с новыми transport/vehicle изменениями.
- Дополнительный поиск по diff показал новые англоязычные player-facing строки в `code/modules/vehicles/**`, `code/modules/projectiles/magazines/specialist.dm` и `code/datums/ammo/rocket.dm`.

## E-003: Границы правок
- Текущий `PLAN/TODO/DECISIONS/EVIDENCE` до старта относился к другой HALO-задаче и был перезаписан под локализацию PR #84.
- Для перевода исключены строки, явно используемые как тех. ключи (`icon_state`, `interior_id`, trait ids, path-ы и similar identifiers).

## E-004: Выполненные правки
- На русский переведены новые player-facing строки в `code/modules/vehicles/**`, связанных `hardpoints/**` и `code/datums/ammo/rocket.dm`.
- Переведены названия, описания, lore-тексты, area/camera labels, warning/notice сообщения и спавнеры для новых сущностей `Wolfpack`, `Ridgeway` и `Warthog/Vulcan`.
- Технические строки (`icon_state`, `interior_id`, caliber ids, path-ы, list keys и similar identifiers) оставлены без перевода.

## E-005: Проверки
- `git diff --check`: passed.
- Поиск по изменённым кодовым файлам на характерные mojibake-символы (`�`, `Ѓ`, `љ`, etc.) ничего не нашёл.
- `BUILD.cmd`: passed (`colonialmarines.dmb - 0 errors, 0 warnings`).
