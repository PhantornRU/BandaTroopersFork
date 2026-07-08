# TODO - PR99 Building Layout v2.1 Universal Solver

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Read `08.07.06_review.md`, stable guidance, active task-state, include graph, v2 solver/contracts/living files, validation/report surfaces. | [x] |
| M2 | MUST | Replace stale wall-topology task-state with v2.1 contract before product edits. | [x] |
| M3 | MUST | Record self plan-mapping challenge and old-path audit before implementation. | [x] |
| M4 | MUST | Add v2.1 datums/state: influence zones, region candidates, room connections, opening candidates, scene budget, scene hierarchy fields. | [x] |
| M5 | MUST | Change living patterns to output influence zones, route hints, and room connections; no hardcoded doors and no production fixed room slots. | [x] |
| M6 | MUST | Add room allocator that builds rectangles from room contracts with target area/aspect and rejects thin/pen rooms and scene-capacity failures. | [x] |
| M7 | MUST | Replace opening flow with connection-driven shared-wall segment solver; choose best non-corner center segment and expose door failure counters. | [x] |
| M8 | MUST | Keep window solving policy-driven and expose v2 window-policy hard failures. | [x] |
| M9 | MUST | Add scene hierarchy: primary anchor, negative-space/no-furniture mask, secondary/detail anchors, and validation against negative-space blocking. | [x] |
| M10 | MUST | Add global scene budget with focal limits and required bedroom/sanitation/storage scene minimums; solve required rooms first. | [x] |
| M11 | MUST | Add v2.1 quality validator hard counters for empty large rooms, isolated rooms, invalid doors, thin rooms, scene missing, duplicate focal scenes, negative-space blocking, and windows. | [x] |
| M12 | MUST | Expose new counters through hard counters, metadata/report metrics, visual report metrics, and focused living expectations. | [x] |
| C1 | CHECK | Run compile/diff/focused visual workflow and record final Plan Fidelity/verification evidence. | [x] |

## Forbidden Substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | No visualizer-side generation, repair, success simulation, or report-only fix. |
| F2 | No hardcoded `add_building_v2_door(x, y)` in living patterns. |
| F3 | No fixed final room-slot pattern path as the production allocation path. |
| F4 | No fallback wrapper leaving the old living v2 core production-reachable. |
| F5 | No expanding to storage/workshop before living v2.1 passes focused checks. |
| F6 | No counter-only acceptance without diff-level solver path evidence. |

## Old Path Audit

| Old path | Required result | Current evidence |
| --- | --- | --- |
| `pattern.build_candidates()` fixed slots | Not production-reachable for living v2.1 candidate generation. | Generator now consumes `build_region_candidates()` and allocator output. |
| `add_building_v2_room_allocation_slot()` from living patterns | Not used by living v2.1 production path. | `rg` found no `add_building_v2_room_allocation_slot()` matches in `building_layout_v2_living.dm`. |
| `add_building_v2_door()` from living patterns | Not used by living v2.1 production path. | `rg` found no `add_building_v2_door()` matches in `building_layout_v2_living.dm`. |
| room-loop opening solver | Replace with declared `room_connections` shared-wall solver. | `solve_building_v2_openings()` now iterates `candidate.room_connections` and uses `collect_building_v2_door_candidates()`. |
| scene switch-only builder | Keep emission recipes but route them through primary/negative/secondary hierarchy and validation. | Scene plans are registered through `register_building_v2_scene_hierarchy()` and validated by v2 quality. |
| legacy hard counter names only | Add v2.1 counters while preserving existing report contracts. | `v2_*` counters are in validation state, hard-counter lookup, visual report metrics, and focused living expectations. |
