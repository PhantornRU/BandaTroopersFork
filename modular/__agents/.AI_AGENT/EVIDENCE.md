# EVIDENCE - Living V2 Universal Pattern/Scene Solver

## Read-Only Discovery

Date: 2026-07-02

- AI index is absent in this repo; discovery uses targeted `rg` and file reads.
- Include graph: `modular/world_edit/_world_edit.dme` includes `v2/building_layout_v2_contracts.dm`, `v2/building_layout_v2_living.dm`, and `v2/building_layout_v2_solver.dm`.
- Entry point: `world_edit_generator_building_layout.dm` calls `build_building_layout_v2_state(state)` when `use_building_layout_v2(request)` is true.
- Current living default is already wired before request construction; `building_layout_v2_enabled()` still requires `state.config["use_layout_v2"]` and `archetype == "living"`.
- Current v2 pipeline after this pass is `generate_building_layout_v2_candidates()` -> room allocation solve -> opening/window solve -> topology validation -> `solve_building_v2_scenes()` -> score-ordered post-emission hard-validation retry -> final emission -> scene placement -> hard validation.
- Current bad old path is confirmed: `building_layout_v2_living.dm` calls `add_building_v2_door()` and `add_building_v2_window()` directly from pattern build procs.
- Current topology validation trusts door metadata for room connectivity by populating `connected_rooms` from `door_plan.from_room/to_room`, without proving every door is on a shared wall between room floor and route floor.
- Current scene solver has contract/slot scaffolding and anchor selection, but global scene budgets and room allocation pre-fit are incomplete.

## Plan Mapping Challenge

Status: PASS WITH RISKS

- PASS: Production scope is modular World Edit generator code; visualizer remains reporting only.
- PASS: The required replacement maps to existing v2 datums and solver procs; no upstream full rewrite is needed.
- PASS: The old hardcoded opening source is isolated to `building_layout_v2_living.dm`, while the emission bridge already consumes candidate `door_plans` and `window_plans`.
- RISK: A full universal room allocator is larger than a single narrow patch because current patterns still create rectangles directly. Mitigation: first remove hardcoded openings/windows and add scene-fit/topology guards, then continue toward relation-zone allocation without storage/workshop rollout.
- RISK: Scene solver already uses switch-based scene builders; replacing every scene layer at once may be too invasive. Mitigation: add global budgets, layer metadata, and required identity validation without broad module expansion.
- RISK: Tightening counters can break existing visual cases. Mitigation: expectations are semantic source of truth; current bad screenshot class should fail until solver output is correct.

## Subagent Status

- Opening/door/window explorer: complete. Recommendation applied: move opening derivation between pattern candidate construction and topology validation; validate actual shared-wall/boundary geometry; preserve route opening plans as emission layer.
- Room/scene solver explorer: complete. Recommendation applied in living slice: room allocation requests, contract-driven rectangle materialization, required scene-fit precheck, global scene budgets, primary-scene identity checks, and required room identities. Residual: storage/workshop reuse is intentionally not rolled out yet.
- Validation/case explorer: complete. Recommendation applied: add hard v2 counters for required route connection, invalid shared-wall doors, rooms without doors, and forbidden windows; expose them to semantic report expectations.

## Implementation Evidence

- Living patterns no longer call hardcoded opening helpers:
  - `rg -n "add_building_v2_door|add_building_v2_window" modular/world_edit/code/generators/building_layout/v2/building_layout_v2_living.dm` -> no matches.
- Opening solver:
  - `solve_building_v2_openings()` runs before topology validation.
  - Door candidates are collected from room/route shared walls and rejected for missing shared wall, short segment/end/corner placement, blocked sides, or occupied opening turf.
  - Topology validation calls `building_v2_door_plan_has_valid_shared_wall()` and requires connected route turfs.
- Room allocation solver:
  - Living patterns now add `room_allocation_requests` with relation-zone slots instead of calling `add_building_v2_room_rect()` directly.
  - `solve_building_v2_room_allocation()` runs before openings and creates room plans from room contracts.
  - `select_building_v2_room_dimensions_for_slot()` chooses dimensions inside slot bounds using contract min/preferred/max area and required scene-fit.
  - `building_v2_room_dimensions_have_required_scene_fit()` rejects rooms that cannot fit required bedroom/sanitation/storage/living/dining scene contracts before the candidate reaches topology.
  - `side_spine_room_row` was added as bounded candidate breadth for wide/rectangle footprints.
  - Follow-up adjustment: side-spine now uses bounded connected service routes, an exit service room, side service room, rear service room, and shortened connector segments instead of a long corridor and unclaimed wall pocket.
  - `building_living_rectangle_colony` now proves `layout_v2_candidate_count=3` and `layout_v2_hard_valid_candidate_count=3`; side-spine has no candidate reject report and can survive post-emission hard validation.
- Window solver:
  - Window plans are derived by `solve_building_v2_windows()` from room policy and validated by `building_v2_window_plan_obeys_policy()`.
  - Optional windows are not emitted until facade-aware optional selection is expanded; required/desired window policy is hard validated.
- Scene solver:
  - Program contract now has `global_scene_slot_limits`; living sets `public_focal = 1`.
  - Scene contracts now carry `scene_layer`.
  - `common_entry_side_surface` replaces a second public focal in common rooms when dining has its own focal scene.
  - Scene validation increments fragmentation counters for duplicate public focal scenes and preserves bedroom/sanitation/storage identity counters.
- Post-emission candidate retry:
  - `select_hard_valid_building_layout_v2_candidate()` now tries scene-solved candidates in score order using isolated trial states.
  - `run_building_v2_candidate_emission_pipeline()` is shared by trial and final emission: emit rooms/routes/openings, refresh anchors, reserve door cones, place scenes, place infrastructure, rebuild fixture indexes, run hard validation, and build hashes.
  - `layout_v2_hard_valid_candidate_count` is exposed through plan metadata, validation verdict metrics, and visual report metrics.
  - `layout_v2_min_candidate_count` now prefers post-emission hard-valid candidate count, falling back to legacy candidate count only for compatibility.
- Reporting:
  - New counters are hard counters and are whitelisted into visual `metrics`, so semantic expectations are source of truth.

## Verification

- `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` -> PASS, 0 errors, 0 warnings.
- Living matrix:
  - Command: `py tools\world_edit_visual\scripts\render_workflow.py --isolated --timeout-seconds 180 --poll-seconds 2 --case building_living_target_rooms_6 --case building_living_point_colony --case building_living_point_colony_east --case building_living_point_colony_south --case building_living_point_colony_west --case building_living_size_compact --case building_living_size_standard --case building_living_size_spacious --case building_living_rectangle_colony`
  - Result: `rendered=9, failures=0`.
  - Semantic report aggregate: all 9 `passed=1`, `status=supported`, `hard_counter_failure_count=0`.
  - `building_living_target_rooms_6`: `layout_v2_enabled=1`, `layout_v2_candidate_count=2`, new v2 opening/window counters all 0.
  - `building_living_target_rooms_6` determinism replay: `status=matched`, `all_hashes_match=1`, `same_seed_layout_hash=1`.
  - `building_living_size_spacious`: `layout_v2_candidate_count=2`.
  - `building_living_rectangle_colony`: `layout_v2_candidate_count=3`, selected pattern `front_common_back_private`, `room_count=8`, `hard_counter_failure_count=0`, `unclaimed_interior_wall_count=0`, `corridor_ribbon_count=0`.
  - Remaining living matrix cases are hard-valid with 1 candidate.
- Non-living and undersized checks:
  - Command: `py tools\world_edit_visual\scripts\render_workflow.py --isolated --timeout-seconds 180 --poll-seconds 2 --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6 --case building_living_explicit_micro_1x1 --case building_living_explicit_compact_2x2`
  - Result: `rendered=4, failures=0`.
  - `building_storage_target_rooms_5`: `passed=1`, `status=supported`, `layout_v2_enabled=0`, `layout_v2_candidate_count=0`.
  - `building_workshop_target_rooms_6`: `passed=1`, `status=supported`, `layout_v2_enabled=0`, `layout_v2_candidate_count=0`.
  - `building_living_explicit_micro_1x1`: `passed=1`, `status=locked`, `reason=program.insufficient_footprint`, `canvas_changed=0`.
  - `building_living_explicit_compact_2x2`: `passed=1`, `status=locked`, `reason=program.insufficient_footprint`, `canvas_changed=0`.
- `git diff --check` -> PASS.
- `tools\build\build.bat clean; tools\build\build.bat dm` -> PASS, 0 errors, 0 warnings.
- Latest recheck after side-spine route/slot changes:
  - `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` -> PASS, 0 errors, 0 warnings.
  - Living matrix 9/9 `passed=1`.
  - Non-living/negative smoke 4/4 `passed=1`.
  - `git diff --check` -> PASS.
  - `tools\build\build.bat clean; tools\build\build.bat dm` -> PASS, 0 errors, 0 warnings.
- Latest recheck after post-emission retry:
  - `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` -> PASS, 0 errors, 0 warnings.
  - Living matrix 9/9 `passed=1`.
  - `building_living_target_rooms_6`: `layout_v2_candidate_count=2`, `layout_v2_hard_valid_candidate_count=2`, `layout_v2_min_candidate_count` actual = 2.
  - `building_living_size_spacious`: `layout_v2_candidate_count=2`, `layout_v2_hard_valid_candidate_count=2`.
  - `building_living_rectangle_colony`: `layout_v2_candidate_count=3`, `layout_v2_hard_valid_candidate_count=2`, selected pattern `front_common_back_private`, hard counters 0.
  - Non-living/negative smoke 4/4 `passed=1`; storage/workshop remain `layout_v2_enabled=0`; undersized living cases remain locked with `program.insufficient_footprint`.
  - `git diff --check` -> PASS.
  - `tools\build\build.bat clean; tools\build\build.bat dm` -> PASS, 0 errors, 0 warnings.
- Latest recheck after side-spine hard-valid cleanup:
  - `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` -> PASS, 0 errors, 0 warnings.
  - Focused `building_living_rectangle_colony` -> PASS with `layout_v2_candidate_count=3`, `layout_v2_hard_valid_candidate_count=3`, no `layout_v2_candidate*reject` stage reports, `unclaimed_interior_wall_count=0`, `corridor_ribbon_count=0`.
  - Living matrix 9/9 `passed=1`; `building_living_target_rooms_6` remains `2/2` hard-valid, `building_living_size_spacious` remains `2/2`, `building_living_rectangle_colony` is `3/3`.
  - Non-living/negative smoke 4/4 `passed=1`; storage/workshop remain `layout_v2_enabled=0`; undersized living cases remain locked with `program.insufficient_footprint`.
  - `git diff --check` -> PASS.
  - `tools\build\build.bat clean; tools\build\build.bat dm` -> PASS, 0 errors, 0 warnings.
- Visual review:
  - `building_living_target_rooms_6` now has readable central route, shared-wall room doors, separate dining/sleeping/sanitation/storage identities, and no repeated public focal group.
  - Superseded by manual review below: rectangle is not a follow-up risk; it is an active blocker because semantic counters are green while output is visually rejected.

## Manual Visual Review 2026-07-02

- Submitted screenshot 1 maps to `tools/world_edit_visual/out/building_living_rectangle_colony/semantic_sprites.png`.
  - Report status: `supported`, `passed=1`, `layout_v2_enabled=1`, selected pattern `front_common_back_private`, `layout_v2_candidate_count=3`, `layout_v2_hard_valid_candidate_count=3`.
  - Current counters are falsely green: `large_sparse_room_count=0`, `corridor_ribbon_count=0`, `common_scene_fragmentation_count=0`, `unclaimed_interior_wall_count=0`, `layout_v2_door_not_shared_wall_count=0`, `layout_v2_room_without_door_count=0`.
  - Visual finding: huge sparse rooms, repeated doors along the route spine, and weak scene identity. This case must become a semantic failure or select a better candidate.
- Submitted screenshot 2 maps to `tools/world_edit_visual/out/building_storage_target_rooms_5/semantic_sprites.png`.
  - Report status: `supported`, `passed=1`, `layout_v2_enabled=0`; legacy smoke only.
- Submitted screenshot 3 maps to `tools/world_edit_visual/out/building_workshop_target_rooms_6/semantic_sprites.png`.
  - Report status: `supported`, `passed=1`, `layout_v2_enabled=0`; legacy smoke only.
- Submitted screenshot 4 maps to `tools/world_edit_visual/out/building_living_explicit_micro_1x1/semantic_sprites.png`.
  - Report status: `locked`, `passed=1`, reason `program.insufficient_footprint`, `canvas_changed=0`; blank PNG is acceptable only for this structured negative case.
- Current code finding: `score_building_v2_layout_candidate()` rewards route length and door count, which directly favors the bad rectangle door-band/spine output.

## Visual Review Hardening Slice 2026-07-02

- Added hard counter `layout_v2_underfurnished_room_count`.
  - Purpose: fail large living-v2 rooms that have a scene identity but too few actual scene members to read visually.
  - Wired through validation state reset, hard-counter registry, visual report metrics, and living v2 expectations.
- Tightened `corridor_ribbon_count` for v2 route complexity.
  - Previous threshold allowed side-spine maze output (`primary_route_turfs=44`, `room_count=9`).
  - Current threshold rejects the side-spine rectangle candidate with `corridor_ribbon_count=18`.
- Changed v2 candidate scoring so longer routes and extra doors are no longer positive quality signals.
  - Routes/doors are still hard requirements, but surplus route/door exposure is now a cost.
- Added bounded scene-density details:
  - Large `entry_common` side-surface scenes add deterministic wall-side details.
  - Larger bedrooms add a second cabinet when placement fits.
  - Large crate-based service rooms add deterministic crate details.
  - Rack/cabinet tertiary detail was rejected because it failed emitter placement; it was removed instead of forcing a bad precheck.
- Updated `building_living_rectangle_colony` expectation from `layout_v2_min_candidate_count=3` to `2` because the third candidate is now intentionally hard-rejected by route complexity.

## Latest Verification After Visual Review Hardening

- `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` -> PASS, 0 errors, 0 warnings.
- Focused `building_living_rectangle_colony` -> PASS.
  - `layout_v2_candidate_count=3`, `layout_v2_hard_valid_candidate_count=2`, selected pattern `front_common_back_private`.
  - Hard counters: `layout_v2_underfurnished_room_count=0`, `large_sparse_room_count=0`, `corridor_ribbon_count=0`, `unclaimed_interior_wall_count=0`.
  - Rejected candidate evidence: `side_spine_room_row` rejected with `corridor_ribbon_count=18`.
- Living matrix 9/9 -> PASS.
  - `building_living_target_rooms_6`: `layout_v2_enabled=1`, `2/2` hard-valid, `layout_v2_underfurnished_room_count=0`.
  - N/S/E/W point cases: all `2/2` hard-valid, all new/old hard counters 0.
  - Compact/standard: both `central_spine_rooms`, `1/1` hard-valid, hard counters 0.
  - Spacious: `front_common_back_private`, `2/2` hard-valid, hard counters 0.
  - Rectangle: `front_common_back_private`, `2/3` hard-valid, side-spine rejected by corridor complexity.
- Non-living/negative smoke 4/4 -> PASS.
  - `building_storage_target_rooms_5`: `layout_v2_enabled=0`; legacy smoke only.
  - `building_workshop_target_rooms_6`: `layout_v2_enabled=0`; legacy smoke only.
  - `building_living_explicit_micro_1x1`: `status=locked`, `canvas_changed=0`, reason `Cannot build living: selected area has 1/17 minimum usable tiles.`
  - `building_living_explicit_compact_2x2`: `status=locked`, `canvas_changed=0`, reason `Cannot build living: selected area has 9/17 minimum usable tiles.`
- `git diff --check` -> PASS; existing warning: `building_layout_emitter.dm` CRLF will be replaced by LF.
- `tools\build\build.bat clean; tools\build\build.bat dm` -> PASS, 0 errors, 0 warnings.
- Visual residual risk:
  - Rectangle is materially denser and side-spine maze is no longer accepted, but the output is still a conservative room/corridor partition rather than final polished living design.
  - Storage/workshop screenshots remain visibly bad because they are legacy outputs; they are evidence for the next data-pack phase, not solved by this slice.

## Plan Fidelity Matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Confirm read-only scope, entrypoints, include graph, and old hardcoded paths. | This file, Read-Only Discovery. | DONE |
| M2 | MUST | Replace previous task-state with solver contract. | `PLAN.md`, `TODO.md`, `DECISIONS.md`, `EVIDENCE.md`. | DONE |
| M3 | MUST | Use subagents for independent review. | `Subagent Status`. | DONE |
| M4 | MUST | Remove hardcoded living pattern doors/windows as production source. | `Implementation Evidence`. | DONE |
| M5 | MUST | Add opening solver. | `Implementation Evidence`. | DONE |
| M6 | MUST | Add room allocation scene-fit checks. | `solve_building_v2_room_allocation()`, allocation slots, required scene-fit precheck, living matrix. | DONE |
| M7 | MUST | Add scene solver global/layer/identity rules. | `Implementation Evidence`; living matrix hard counters. | DONE |
| M8 | MUST | Add v2 quality counters. | New hard counters and visual expectations. | DONE |
| M9 | REJECT | Do not roll storage/workshop to v2. | Scope decision. | DONE |
| M10 | CHECK | Run verification. | `Verification`. | DONE |
| M11 | MUST | Sync final evidence. | This file updated. | DONE |
| M12 | MUST | Add per-candidate post-emission hard validation/retry. | `select_hard_valid_building_layout_v2_candidate()`, `run_building_v2_candidate_emission_pipeline()`, hard-valid count metrics, living matrix. | DONE |
| M13 | CHECK | Make side-spine post-emission hard-valid before it can win rectangle scoring. | Rectangle regression proves `layout_v2_hard_valid_candidate_count=3` and no side-spine candidate reject. | DONE |
