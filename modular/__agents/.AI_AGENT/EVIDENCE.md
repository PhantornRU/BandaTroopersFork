# EVIDENCE - Living V2 Visual Quality Hardening

## Read-Only Discovery

Date: 2026-07-01

- `TOOLS/AI_INDEX/ai_index.py` is absent; discovery uses targeted reads/search.
- User-provided PNG shows a visually poor living layout: oversized empty halls, thin corridor/room strips, unclear circulation, and furniture groups that satisfy counters but do not read as natural rooms.
- Existing reports prove `building_living_target_rooms_6` passed with `layout_v2_candidate_count=2`, but the visual result is not accepted by the user.
- `tools/world_edit_visual/out/**/semantic_sprites.png` contains living matrix review artifacts for target, point N/S/E/W, size profiles, rectangle, and negative undersized cases.

## Subagent Outcomes

- Agent A read-only visual critique found that passing reports still allowed giant halls, ribbon/maze corridors, sparse room scenes, and stale/non-atomic visual outputs. Recommended hard counters included oversized/common hall, thin strip, corridor ribbon, route legibility, sparse scene density, role-distance, and unclaimed interior wall metrics.
- Agent B reworked `modular/world_edit/code/generators/building_layout/v2/building_layout_v2_living.dm`: kept production living v2 grammar to readable front-common/service-core and central-spine candidates, capped room dimensions, removed the old branchy `side_spine_room_row`, and avoided visualizer/seed-specific edits.
- Agent C reworked `modular/world_edit/code/generators/building_layout/v2/building_layout_v2_solver.dm`: scene members are now selected by role/scene-kind mapping over usable room cells with route, door/door-cone, window, wall, occupied-member, and fixture-clearance rejection before placement.

## Implementation Evidence

- Added orientation-safe local dimensions in the v2 context so EAST/WEST rectangle requests validate pattern dimensions in the same local coordinate system used by `local_turf()`.
- Added a rear utility/service band for oversized living rectangles so large explicit footprints are occupied by connected rooms instead of being left as unreadable internal wall fields.
- Added candidate topology checks for max room bounds, strip rooms, and minimum floor coverage so compact block-in-large-footprint candidates are rejected before selection.
- Added final hard counters/report metrics/expectations: `unclaimed_interior_wall_count`, `thin_room_strip_count`, `large_sparse_room_count`, and `corridor_ribbon_count`.
- Added density improvements for scene grammar: lounge scenes can add a non-major table when clearance allows; large bedroom scenes can add an optional second cabinet.
- Updated living visual cases so the new counters are expected to remain zero.

## Agent C Read-Only Mapping Challenge

- PASS WITH RISKS: `modular/world_edit/_world_edit.dme` includes `v2/building_layout_v2_{contracts,living,solver}.dm`, and `world_edit_generator_building_layout.dm` calls `build_building_layout_v2_state(state)` only when `use_building_layout_v2(request)` is true.
- Existing `building_layout_v2_solver.dm` already builds scene contracts and hard scene counters, but scene member placement uses fixed offsets (`add_building_v2_*_scene_members`) rather than scoring usable wall/free cells.
- Existing hard counters include `scene_required_missing_count`, `room_primary_scene_missing_count`, `scene_slot_overflow_count`, `scene_blocks_route_count`, role-scene missing counters, and large-empty/oversized room counters, so Agent C can use current metrics unless implementation exposes a missing one.
- Risk: pattern files are owned by Agent B and are already untracked/dirty. Mitigation: only change solver-side mapping and leave v2 pattern coordinates unchanged.

## Verification Evidence

- `git diff --check` passed; PowerShell reported only pre-existing CRLF warnings for already-modified `building_layout_emitter.dm` and `building_layout_validators.dm`.
- `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors and 0 warnings; final rerun was up to date after the full compile.
- Living matrix passed via `py tools\world_edit_visual\scripts\render_workflow.py --isolated --timeout-seconds 180 --poll-seconds 2` for:
  - `building_living_target_rooms_6`: `passed=1`, `status=supported`, `layout_v2_candidate_count=2`, `rooms=6`, `objects=22`, new visual counters all 0.
  - `building_living_rectangle_colony`: `passed=1`, `status=supported`, `layout_v2_candidate_count=2`, `rooms=8`, `objects=27`, new visual counters all 0.
  - `building_living_point_colony`, `east`, `south`, `west`: all `passed=1`, `status=supported`, new visual counters all 0.
  - `building_living_size_compact`, `standard`, `spacious`: all `passed=1`, `status=supported`, new visual counters all 0; spacious has `layout_v2_candidate_count=2`.
- Non-living smoke passed via the same workflow:
  - `building_storage_target_rooms_5`: `passed=1`, `status=supported`, `layout_v2_enabled=0`, `rooms=5`.
  - `building_workshop_target_rooms_6`: `passed=1`, `status=supported`, `layout_v2_enabled=0`, `rooms=6`.
- Fresh PNGs inspected: rectangle no longer shows the original left-side strip maze; rooms occupy the explicit footprint with connected corridor doors and denser scene placement. Target case now has a lounge table and additional bedroom storage where clearance allows.
