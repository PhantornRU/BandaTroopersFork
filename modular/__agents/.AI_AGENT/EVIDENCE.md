# EVIDENCE

## E-001: Existing World Edit runtime already supports preview/apply/history/undo on the manager
- `modular/world_edit/code/core/manager/world_edit_manager_core.dm`
- `modular/world_edit/code/core/manager/world_edit_manager_generator_runtime.dm`
- `modular/world_edit/code/core/manager/world_edit_manager_state.dm`

## E-002: Safe placement helpers already exist for cardinal dirs and line turf collection
- `modular/world_edit/code/generators/shared/world_edit_generator_shared_helpers.dm`

## E-003: `blueprint_stamp` and `outpost_radius` are ready batch generators and are the intended safe Phase 4 targets
- `modular/world_edit/code/core/world_edit_registry.dm`
- `modular/world_edit/code/generators/world_edit_generator_blueprint_stamp.dm`
- `modular/world_edit/code/generators/world_edit_generator_outpost_radius.dm`

## E-004: Current TGUI panel already exposes apply/undo/cleanup controls and can be extended minimally
- `tgui/packages/tgui/interfaces/WorldEditPanel.tsx`
