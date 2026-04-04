# EVIDENCE

## E-001: Directed barricade semantics в апстриме уже slot-based
- `code/game/objects/structures/barricade/barricade.dm`:
  - `flags_atom = ON_BORDER`
  - `initialize_pass_flags()` использует `flags_can_pass_front/behind`
  - `BlockedPassDirs()` / `BlockedExitDirs()` делегируют в border-aware movement semantics
- `code/modules/movement/movement.dm` показывает, что `ON_BORDER` объект блокирует только соответствующее направление, а не весь тайл.
- `code/modules/projectiles/projectile.dm` учитывает `dir` как orientation cover-а для border objects.

## E-002: Правило “не более одной баррикады на сторону” уже существует
- `modular/world_edit/code/generators/shared/world_edit_generator_shared_helpers.dm`:
  - `build_turf_dir_slot_key()`
  - `has_barricade_in_dir()`
- `modular/world_edit/code/core/world_edit_blueprints.dm`:
  - `world_edit_build_blueprint_relative_slot_key()`
  - `world_edit_build_blueprint_target_slot_key()`
  - `world_edit_validate_blueprint_target_turf()`
- `code/game/objects/items/stacks/stack.dm` при border-building тоже запрещает overlap по `O.dir == usr.dir`.

## E-003: Active blueprint/template format уже допускает несколько DIR на одном тайле
- `data/world_edit/blueprints/05_corner.json`: slot `(-2,-2,0)` содержит две записи с `dir=2` и `dir=8`.
- `data/world_edit/blueprints/02_sandbag.json`: slots `(-1,0,0)` и `(1,0,0)` содержат по две записи с разными `dir`.
- Значит проблема не в JSON schema, а в части generator planning logic.

## E-004: Найден live generator path, который still мыслит тайлами вместо side-slots
- `modular/world_edit/code/generators/world_edit_generator_outpost_radius.dm`:
  - `collect_perimeter_placements()` строит top/bottom rows полностью, но left/right только по внутреннему диапазону `(-radius + 1) .. (radius - 1)`.
  - Это исключает corner side-slots и ломает radius=1 / corner-heavy layouts.
- В той же реализации shape-aware path уже опирается на `build_turf_dir_slot_key()`, `opening_lookup`, `barricade_lookup`, то есть работает slot-aware.

## E-005: Рабочее дерево перед правками
- `git status --short`: чисто.

## E-006: После правок perimeter planning переведён на slot-aware shell/perimeter
- `modular/world_edit/code/generators/world_edit_generator_outpost_radius.dm`:
  - square/point perimeter теперь регистрирует все четыре стороны, включая угловые shared slots;
  - shape-aware path строит outer shell по Chebyshev distance и выводит outward `dir` из shell topology, а не из tile-centric cardinal stepping;
  - opening/sentry planning продолжает дедупиться по `build_turf_dir_slot_key()`.

## E-007: Curated blueprints после аудита
- Мигрированы как явно tile-centric fort samples:
  - `data/world_edit/blueprints/01_outpost.json`
  - `data/world_edit/blueprints/example_fort.json`
- Оставлены без forced-migration:
  - `02_sandbag.json`, `05_corner.json` уже используют multi-DIR slots;
  - `04_ruin.json` — нерегулярный ruin cluster, corner-stack ему не обязателен.

## E-008: Верификация
- `git diff --check`: passed.
- PowerShell JSON parse всех `data/world_edit/blueprints/*.json`: passed.
- Полный DM compile через `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`: не выполнен из-за sandbox/runtime ограничения `spawn EPERM`, а не из-за диагностированного compile error.
