# TODO - Living V2 Universal Pattern/Scene Solver

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Confirm read-only scope, entrypoints, include graph, and old v2 hardcoded paths. | [x] |
| M2 | MUST | Replace previous visual-hardening task-state with this solver contract before product edits. | [x] |
| M3 | MUST | Use subagents for independent opening, scene, and validation review. | [x] |
| M4 | MUST | Remove production dependence on hardcoded pattern doors/windows for living v2. | [x] |
| M5 | MUST | Add bounded opening solver from shared wall candidates with corner/short/clearance/privacy scoring. | [x] |
| M6 | MUST | Add or wire room allocation checks so room contracts and required scene fit reject bad candidates before selection. | [x] |
| M7 | MUST | Add scene solver rules for primary/secondary/detail layers, global limits, and required bedroom/sanitation/storage identities. | [x] |
| M8 | MUST | Add v2 quality counters for room identity, scene fragmentation, large empty rooms, door/shared-wall correctness, and window policy. | [x] |
| M9 | REJECT | Do not add storage/workshop v2 data packs until living visual pass is semantically green. | [x] |
| M10 | CHECK | Run compile, diff check, living regression/matrix, negative undersized, and non-living smoke as feasible. | [x] |
| M11 | MUST | Sync final plan fidelity, old-path audit, subagent outcomes, and verification evidence. | [x] |
| M12 | MUST | Add per-candidate post-emission hard validation/retry so a high-scoring candidate cannot block a lower hard-valid candidate. | [x] |
| M13 | CHECK | Make `side_spine_room_row` post-emission hard-valid before allowing it to win rectangle scoring. | [x] |
| M14 | MUST | Treat manual visual review as failing current living-v2 acceptance; do not call the current green rectangle output solved. | [x] |
| M15 | MUST | Map the submitted screenshots to cases/reports and separate living-v2 failures from legacy storage/workshop smoke artifacts. | [x] |
| M16 | MUST | Add or tighten semantic counters so the current `building_living_rectangle_colony` visual failure class cannot pass with zero hard counters. | [x] |
| M17 | MUST | Change v2 scoring/selection so long routes and extra doors are bounded costs/requirements rather than quality bonuses. | [x] |
| M18 | CHECK | Re-run focused rectangle/living matrix and verify storage/workshop are only legacy safety smoke, not visual acceptance. | [x] |

## Forbidden Substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | No one-seed or one-PNG coordinate fix. |
| F2 | No visualizer-side generation, patching, or success simulation. |
| F3 | No extra random recipes/modules as a substitute for pattern/opening/scene constraints. |
| F4 | No metadata-only door connectivity; door/opening must be proven against shared wall/floor geometry. |
| F5 | No counter-only success if rooms/routes/scenes remain visually unreadable. |
| F6 | No living no-solution fallback to legacy. |
| F7 | No storage/workshop v2 rollout before living is solved under the same engine. |

## Old Path Audit

| Old path | Expected status | Evidence command |
| --- | --- | --- |
| `add_building_v2_door()` calls inside living pattern build procs | not production source for living openings | `rg -n "add_building_v2_door" modular/world_edit/code/generators/building_layout/v2/building_layout_v2_living.dm` |
| `add_building_v2_window()` calls inside living pattern build procs | not production source for living windows | `rg -n "add_building_v2_window" modular/world_edit/code/generators/building_layout/v2/building_layout_v2_living.dm` |
| `validate_building_v2_layout_topology()` metadata-only `connected_rooms` loop | replaced/tightened by shared-wall validation | `rg -n "connected_rooms|door\\.not_shared|door_shared" modular/world_edit/code/generators/building_layout/v2/building_layout_v2_solver.dm` |
| Scene solve as independent room-only switch with no global limits | tightened with global living scene budgets and identity checks | `rg -n "global_scene|common_scene_fragmentation|scene_slot" modular/world_edit/code/generators/building_layout/v2` |
| Living v2 fallback to legacy on no solution | forbidden | `rg -n "use_building_layout_v2|build_building_layout_v2_state" modular/world_edit/code/generators/building_layout` |

## Residual Work

- Living room allocation now has a solver layer: patterns provide route geometry plus room allocation slots/relation zones; `solve_building_v2_room_allocation()` materializes room rectangles from room contracts and required scene-fit checks before openings/topology.
- Reuse for storage/workshop remains future work and must wait until living visual quality is considered stable.
- `side_spine_room_row` exists as additional generated candidate breadth for wide footprints, but it is no longer counted hard-valid on `building_living_rectangle_colony` because tightened `corridor_ribbon_count` rejects its route maze.
- New visual-review blocker: current rectangle output is semantically green but visually unreadable enough to reject. The next implementation slice must make this class fail counters or select a better candidate.
- Current rectangle acceptance selects `front_common_back_private`, requires at least 2 hard-valid candidates, and records side-spine as a rejected candidate with nonzero corridor complexity.
- Optional windows are validated by policy and emitted only when required/desired; broad facade-aware optional window selection remains future work after living quality counters are stable.
