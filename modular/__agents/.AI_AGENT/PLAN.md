# PLAN

## Active Task
Complete `various_fixes` GroundSide stabilization for RU-CMSS13 source maps:
- finish missing GroundSide ports;
- fix compile/map regressions introduced by merge history;
- resolve DMI state overflow with split files and explicit repoints;
- document source mapping, conflicts, and compatibility decisions.

## Final Status
Completed.

## Delivered Scope
- Build blockers fixed (`telecomms`, compatibility types, AI menu warning cleanup).
- Existing regressed maps reconciled (`Otogi`, `BigBlue`, `Onyx`).
- Missing GroundSide maps imported (`lv671`, `oil_depot`, `derelict_almayer_infested`) with required wiring.
- Maplint/map-format compatibility stabilized with targeted subtype support and UpdatePaths scripts.
- DMI overflows removed via split assets and code-side icon repoints.
- Porting documentation expanded in `modular/__docs/VARIOUS_FIXES_PORTING_MAP.md`.

## Out Of Scope Guard
- No new RU shipmap content was ported.
- Ship-side map edits were limited to compile/maplint stabilization only.

## Acceptance Snapshot
- `dm` and `ALL_MAPS` compile: pass.
- `dmi.test`: pass (no overflow errors for target atlases).
- `maplint` and `mapmerge2`: pass.
- Task-state files updated from baseline to task-specific completed state.
