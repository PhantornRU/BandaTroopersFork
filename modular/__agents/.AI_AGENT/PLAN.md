# PLAN

## Active Task
Stabilize gun asset registration after the recent content ports by:
- fixing every current `gun_lineart` runtime offender through canonical `base_gun_icon` aliases or a new `p79s` lineart state;
- fixing the confirmed `forceMove(null)` runtime in `gun_attachables.dm` during off-map gun initialization;
- proving the fixes with compile/runtime checks and refreshed task evidence.

## Status
In progress.

## Current Scope
- Audit the current `gun_lineart` offenders from runtime logs and code.
- Patch gun subtypes that currently resolve to missing lineart states.
- Add `p79s` into `icons/obj/items/weapons/guns/lineart.dmi`.
- Keep `forceMove()` strict and fix the confirmed caller in attachment detachment flow.
- Verify the asset registration path through build/runtime checks.

## Out Of Scope Guard
- No gun lineart registry redesign.
- No silent-fail fallback in `forceMove()`.
- No unrelated runtime cleanup outside this asset/attachment scope.

## Acceptance Target
- No `does not have a valid lineart icon state` runtimes for the audited offenders.
- No `No valid destination passed into forceMove` during `gun_lineart.register()`.
- Task-state reflects this runtime stabilization task.
