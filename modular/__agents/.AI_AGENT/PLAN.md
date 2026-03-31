# PLAN

## Active Task
Implement World Edit Phase 4: safe placement UX for `blueprint_stamp` and limited `outpost_radius` on top of the existing Phase 3B state.

## Scope
- Minimal manager-side placement runtime for safe generators.
- `single` / `repeat` placement for `outpost_radius`.
- `single` / `repeat` / `line` / `rectangle` placement for `blueprint_stamp`.
- Cardinal rotate/dir UX where meaningful for blueprint stamping.
- Minimal TGUI controls for placement mode, direction, and start/stop of placement mode.
- Verification via `git diff --check`, DM build, and `lint tgui-test`.

## Out Of Scope
- Destruction redesign or new destructive modes.
- Turf painting or turf rollback.
- Full snapshot/template/DMM restore.
- Undo expansion beyond existing Phase 3B scope.
- Legacy/deprecated generator rewrites.
- Broad manager or TGUI architecture refactors.

## Planned Steps
1. Refresh stale task-state files and re-check the manager/runtime seams for placement UX.
2. Add minimal placement runtime state and safe click interception for batch safe generators.
3. Extend `blueprint_stamp` and `outpost_radius` with bounded placement plan building.
4. Add minimal panel controls for placement mode and direction.
5. Run required verification commands and commit the phase as a small logical series.

## Acceptance Criteria
- `blueprint_stamp` supports safe repeat placement with visible dir control and bounded line/rectangle placement.
- `outpost_radius` supports safe quick re-anchor/repeat placement without becoming unrestricted paint.
- Placement preview clears on cancel/reset/generator switch/panel close.
- Existing Phase 3B undo/changeset recording remains intact for safe placed objects.
- The phase stays narrow and reviewable.
