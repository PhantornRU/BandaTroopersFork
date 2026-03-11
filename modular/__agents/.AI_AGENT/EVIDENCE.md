# EVIDENCE

## E-001: Dead platoon override path removed
- `code/game/gamemodes/cm_initialize.dm` no longer defines `ship_platoon_override`.
- `modular/squads/code/job/ship_platoon_profiles.dm` no longer contains override-specific resolver logic.

## E-002: Active HALO ODST moved off legacy runtime path
- `modular/squads/code/job/halo_modular_platoons.dm` defines namespaced HALO ODST job paths and uses them in active HALO ODST ship profiles.
- `modular/squads/code/job/halo_odst_legacy_compat.dm` keeps legacy ODST job paths as wrappers over the new HALO ODST paths.
- Active ship platoon registry and conflict-family filtering no longer include legacy `/datum/squad/marine/odst`.

## E-003: Upstream global role lists narrowed again
- `code/__DEFINES/mode.dm` restores vanilla `ROLES_MARINES`, `ROLES_USCM`, and removes `SQUAD_ODST` from `ROLES_SQUAD_ALL`.
- `code/__HELPERS/job.dm` restores `get_marine_jobs()` without HALO-only appends.

## E-004: Shared consumers now classify HALO roles through modular helpers
- `modular/squads/code/job/ship_platoon_profiles.dm` adds helper procs for marine-equivalent and shipside role classification.
- Shared consumers in `code/**` were rewired to use those helpers for current-round HALO roles where needed.

## E-005: Verification on 2026-03-11
- `git diff --check` completed without reporting whitespace or merge-marker issues.
- `tools/build/build.bat dm --ci -DCIBUILDING -DANSICOLORS -Werror` completed successfully after fixing `get_main_ship_faction()`.
- `tools/build/build.bat dm-test --ci -DCIBUILDING -DANSICOLORS -Werror` compiled the test DMB successfully, but the runtime test server did not produce a conclusive clean completion marker during this session.

## E-006: Branch cleanup applied
- `.vscode/launch.json` was removed from the branch.
- Generated `colonialmarines.test.dme` was removed from the worktree.
