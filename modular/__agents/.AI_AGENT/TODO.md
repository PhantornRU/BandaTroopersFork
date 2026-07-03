# TODO - PR99 Semantic Interiors Production Layer

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Read attached 03.07 request, active review doc, stable guidance, task-state, include graph, and old interior/fill paths. | [x] |
| M2 | MUST | Replace stale living-only task-state with this semantic-interiors contract before product edits. | [x] |
| M3 | MUST | Record plan-mapping challenge and old-path audit before implementation. | [x] |
| M4 | MUST | Add semantic interior model/rules/solver/emitter/validation files under production `building_layout/semantic/**`. | [x] |
| M5 | MUST | Replace `stage_interiors` placeholder with `run_building_semantic_interiors(context.state)`. | [x] |
| M6 | MUST | Emit scene members through existing `place_fixture_at()` and preserve scene/module traceability metadata. | [x] |
| M7 | MUST | Prevent `stage_fixtures`/`place_building_room_purpose_fill()` from acting as primary semantic scene placement after semantic interiors run. | [x] |
| M8 | MUST | Add hard semantic counters and expose them through generation verdict/report metrics. | [x] |
| M9 | MUST | Add visual expectation threshold aliases for semantic max/min metrics. | [x] |
| M10 | MUST | Add/update focused expectations so living target and visual-review blockers are semantic-report gated. | [x] |
| M11 | REJECT | Do not implement visualizer-side generation, random module expansion, or PNG-only acceptance. | [x] |
| M12 | CHECK | Run compile, diff check, focused living regression, and non-living smoke as feasible. | [x] |
| M13 | MUST | Sync final plan fidelity, old-path audit, verification evidence, and subagent outcomes. | [x] |

## Forbidden Substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | No one-seed or one-PNG coordinate fix. |
| F2 | No visualizer-side generation, patching, or success simulation. |
| F3 | No extra random recipes/modules as a substitute for scene/room constraints. |
| F4 | No counter-only success if rooms/routes/scenes remain semantically unreadable. |
| F5 | No leaving `place_room_prefab_groups()` as production primary placement. |
| F6 | No letting `place_building_room_purpose_fill()` satisfy required primary scenes. |
| F7 | No storage/workshop solver rollout before living semantic pass is green. |

## Old Path Audit

| Old path | Expected status | Evidence command |
| --- | --- | --- |
| `pipeline/stages/stage_interiors.dm` placeholder `place_room_prefab_groups()` | replaced/not production primary | `rg -n "place_room_prefab_groups|run_building_semantic_interiors" modular/world_edit/code/generators/building_layout` |
| `place_room_prefab_groups()` macro-id switch with no placement | removed or non-production helper only | `rg -n "rack_aisles|sleep_nook|office_desk_cluster|sanitation_combined_chunk" modular/world_edit/code/generators/building_layout/pipeline/stages/stage_interiors.dm` |
| `place_building_room_purpose_fill()` as primary room function | detail/secondary fallback only | `rg -n "place_building_room_purpose_fill|semantic_interiors" modular/world_edit/code/generators/building_layout` |
| Major furniture without scene/module metadata | hard counter failure | `rg -n "semantic_major_object_without_scene_count|module_instance_id" modular/world_edit/code/generators/building_layout` |
| Exact-only visual expectations for semantic quality thresholds | max/min aliases added | `rg -n "semantic_.*_(max|min)|visual_expectation_satisfied" modular/world_edit/code/visual_workbench/world_edit_visual_report.dm` |
