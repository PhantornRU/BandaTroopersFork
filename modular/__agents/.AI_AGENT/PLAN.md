# PLAN

## Active Task
Replace the reverted unmanaged-z patch with a managed-z implementation that:
- keeps `z_list` limited to mapping-managed runtime levels;
- keeps dynamic map loading based on `length(z_list) + 1`;
- treats compile-time, unmanaged `ALL_MAPS` z-levels as trait-less instead of erroring;
- removes startup hangs introduced by the reverted `z_list == world.maxz` approach.

## Status
In progress.

## Current Scope
- Revert the uncommitted changes in `mapping.dm` and `zlevel_manager.dm`.
- Reapply only the dynamic-z fixes needed in `mapping.dm`.
- Update `traits.dm` so unmanaged compiled z-levels are safe for trait lookup.
- Cut late-init integrations that still eagerly bootstrap compile-time unmanaged z-levels.
- Verify normal `dm-test` and `ALL_MAPS` `dm-test` startup behavior.

## Out Of Scope Guard
- No subsystem skip or `ALL_MAPS` fast-path logic.
- No unrelated runtime cleanup unless it directly blocks startup verification.

## Acceptance Target
- No `list index out of bounds` from mapping startup.
- No `Unmanaged z-level` spam for valid compiled-but-unmanaged z-levels.
- Normal runtime starts.
- `ALL_MAPS` runtime completes without startup hang.
