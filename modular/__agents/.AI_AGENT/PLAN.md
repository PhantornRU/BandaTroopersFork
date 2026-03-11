# PLAN

## Active task
Refactor HALO ship platoon integration in PR 61 so that:
- `allowed_platoons` is the only ship platoon selection surface.
- active HALO ODST runtime no longer depends on legacy `/datum/squad/marine/odst`.
- HALO marine roles stop expanding upstream global role lists.
- IDE-only noise is removed from the branch.

## Scope
- `modular/squads/**` ship platoon resolver and HALO squad/job definitions.
- Minimal integration points in `code/**` that still need to classify current-round HALO roles as marine-equivalent or shipside.
- Unit tests for ship platoon override persistence, HALO role classification, and legacy ODST compatibility.
- Branch cleanup for `.vscode/launch.json` and generated test artifacts.

## Out of scope
- Unrelated dirty worktree changes outside this refactor.
- New map content or `allowed_platoons` schema changes.
- Gameplay balance changes unrelated to ship-platoon modularization.

## Phases
1. Remove dead `ship_platoon_override` path and keep platoon selection on ship config plus `next_ship.json`.
2. Move active HALO ODST role mappings to namespaced HALO job paths and keep legacy ODST as compat-only wrappers.
3. Revert upstream global role-list widening and add modular helpers for active marine-equivalent and shipside role classification.
4. Add regression tests and run compile and diff verification.

## Acceptance criteria
- No runtime path uses `ship_platoon_override`.
- Active ship platoon registry uses `/datum/squad/marine/halo/odst/alpha`, not legacy `/datum/squad/marine/odst`.
- `ROLES_MARINES`, `ROLES_USCM`, `ROLES_SQUAD_ALL`, and `get_marine_jobs()` no longer include HALO-only expansions.
- Shared UIs and counters still treat active HALO marine jobs as marine-equivalent through modular helpers.
- `git diff --check` is clean.
- `tools/build/build.bat dm --ci -DCIBUILDING -DANSICOLORS -Werror` succeeds.
