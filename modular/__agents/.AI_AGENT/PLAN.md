# PLAN

## Active Task
Fix the current unit test and lint regressions introduced or exposed by recent content porting by:
- repairing the current `missing_icons` offenders through valid atlas/state mappings;
- removing the confirmed preset/species lookup-name overlaps from runtime setup;
- sanitizing `lv671.dmm` of generated `tag = "icon-..."` var edits;
- verifying the fixes through repo CI-equivalent checks and updating task evidence.

## Status
Completed.

## Current Scope
- Audit the failing icon references against real `.dmi` state inventories.
- Fix the CANC UPP platoon leader preset path typo and its callsites.
- Preserve `SYNTH_COMBAT` for Whiteout/W-Y android lookups and move the legacy combat synth type to a unique lookup name.
- Remove generated icon tags from `maps/map_files/lv671/lv671.dmm`.
- Add a changelog entry and prepare a commit.

## Out Of Scope Guard
- No sprite-atlas redesign.
- No broad registry/unit test exceptions.
- No unrelated runtime cleanup outside the confirmed failing surfaces.

## Acceptance Target
- The current `missing_icons` offenders in scope resolve to real icon states.
- No runtime overlap remains for the audited CANC preset and synthetic species names.
- `tools/ci/check_grep.sh` no longer flags generated `tag = "icon-..."` lines in `lv671.dmm`.
- Task-state reflects this unit test/lint stabilization task.
