# DECISIONS

## D-001: Source of truth для barricade semantics остается в апстрим-объекте, не в World Edit
- Решение: считать канонической directed-blocking моделью апстрим-семантику `/obj/structure/barricade` + `/atom/BlockedPassDirs`/`BlockedExitDirs`/projectile cover.
- Почему: баррикада уже является `ON_BORDER` blocker-ом с cardinal `dir`, а World Edit должен только корректно планировать и спавнить эти слоты.

## D-002: Slot identity для World Edit — `turf + dir`, а не `turf` и не `turf + type`
- Решение: для баррикад уникальность и дедупликацию вести по ключу стороны тайла; разные типы не могут сосуществовать в одном и том же `turf+dir`.
- Почему: пользовательский контракт явно требует “до 4 на тайл, но только 1 на сторону”, а blueprint service уже частично работает именно так.

## D-003: Исправлять нужно generator path, а не формат blueprint
- Решение: основную правку делать в `modular/world_edit/code/generators/world_edit_generator_outpost_radius.dm`, где square/perimeter path still строится как tile-ring без corner side-slots.
- Почему: `blueprint_stamp` и `world_edit_blueprints` уже поддерживают несколько баррикад на одном тайле через slot-keys.

## D-004: Curated blueprint JSON менять только по факту несоответствия slot-модели
- Решение: не переписывать seed blueprints массово, если после аудита они уже содержат корректные multi-slot corner placements.
- Почему: часть curated data (`02_sandbag`, `05_corner`) уже описана через несколько entry на одном `dx/dy` с разными `dir`; лишний churn не нужен.
