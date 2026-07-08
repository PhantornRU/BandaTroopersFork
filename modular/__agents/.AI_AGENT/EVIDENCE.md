# EVIDENCE - PR99 Building Layout v2.1 Universal Solver

## Read-Only Discovery

Date: 2026-07-08

- Active contract is `modular/world_edit/docs/rework_docs/tech_rework/08.07.06_review.md`.
- Stable guidance requires read-only discovery, task-state contract, self plan-mapping challenge, implementation, old-path audit, then verification.
- AI index is absent in this checkout; discovery used targeted `rg` and direct file reads.
- Include graph: `colonialmarines.dme` includes `modular/modular.dme`; `modular/modular.dme` includes `modular/world_edit/_world_edit.dme`; `_world_edit.dme` includes v2 contracts/living/solver.
- Current v2 entrypoint is `build_building_layout_v2_state()`: generate candidates, solve scenes, select hard-valid trial candidate, emit, validate.
- Current living v2 is living-only behind `use_layout_v2`, matching the review's current-state diagnosis.
- Current living patterns no longer call `add_building_v2_door()`, but they still build formula route/room slots via `add_building_v2_route_rect()` and `add_building_v2_room_allocation_slot()`.
- Current opening solver is room-loop based: it clears doors/windows, solves main exit, then solves each room-to-route door.
- Current room allocator sizes fixed allocation slots; it checks min/max dimensions and scene fit but lacks influence zones, region candidates, and explicit aspect failure counters.
- Current scene builder selects one scene by `switch(scene_contract.id)` and does not persist primary anchors, negative-space masks, or secondary/detail hierarchy state.
- Current global scene limit has a `public_focal` slot cap, but no scene-budget datum with minimum required living slots.
- Existing v2 hard counters are `layout_v2_underfurnished_room_count`, `layout_v2_required_connection_missing_count`, `layout_v2_door_not_shared_wall_count`, `layout_v2_room_without_door_count`, and `layout_v2_forbidden_room_window_count`.

## Plan Mapping Challenge

Status: PASS WITH RISKS

- PASS: New datums and helper solvers can be added under `modular/world_edit/code/generators/building_layout/v2/**` without changing public request keys.
- PASS: Candidate generation can be switched from `build_candidates()` to region candidates plus allocator while keeping pattern IDs and report metadata stable.
- PASS: Opening solver can be driven by concrete room connections and existing room/route/wall lookup semantics.
- PASS: New `v2_*` quality counters can be bridged into existing hard-counter/report paths without removing legacy `layout_v2_*` counters.
- RISK: Fully general route solving for every future program is larger than this living-focused slice. Mitigation: implement route hints and connection-driven openings for living, keep storage/workshop expansion out of scope.
- RISK: Full scene replacement would be too broad. Mitigation: keep current recipe emitters but make scene selection/composition validate primary anchor, negative space, budget, and required slots.

## Old Path Audit

Status: PASS

- Living candidate generation now consumes pattern `build_region_candidates()` output and allocator-produced rooms instead of production fixed room slots.
- `rg -n "add_building_v2_door\(|add_building_v2_room_allocation_slot\(" modular/world_edit/code/generators/building_layout/v2/building_layout_v2_living.dm` returned no matches.
- `solve_building_v2_openings()` is reached from the v2 production path and iterates declared `candidate.room_connections`.
- Opening plans are created by `collect_building_v2_door_candidates()` shared-wall segment scans.
- Scene plans are registered through `register_building_v2_scene_hierarchy()` and then checked by v2 quality counters.
- Bad visual conditions hard-fail through `v2_*` counters surfaced in validation state, hard-counter lookup, visual reports, and living case expectations.

## Implementation Evidence

- Added v2.1 datums/state in `building_layout_v2_contracts.dm` and fixture/validation state: influence zones, region candidates, room connections, room/window policy fields, route hints, scene budget fields, scene hierarchy fields, negative/no-furniture masks, and v2 quality counters.
- Added `building_layout_v2_room_allocator.dm` and wired it through `_world_edit.dme`; it allocates rooms from contracts using target area/aspect scoring, route distance, scene capacity checks, thin/pen rejection, and direct-contact separation for non-common zones.
- Added `building_layout_v2_opening_solver.dm`; it finds shared wall segments per room connection and scores non-corner centers for door placement.
- Added `building_layout_v2_quality.dm`; it validates empty large rooms, isolated rooms, invalid doors, bad room aspect/thin strips, missing scenes, duplicate focal scenes, negative-space blocking, scene budget failures, and window-policy violations.
- Updated living contracts/patterns to emit influence zones, route hints, room connections, window policy, scene hierarchy requirements, and living global scene budget/minimums.
- Updated v2 solver to select allocator candidates, solve connection-driven openings, solve policy windows, apply scene hierarchy and budget, protect negative-space/door-to-focus paths, and run v2 quality.
- Exposed new counters through `building_layout_state.dm`, `world_edit_building_layout_validation_state.dm`, `world_edit_generator_building_layout.dm`, and `world_edit_visual_report.dm`.
- Updated focused living visual expectations for strict v2.1 counters in `building_living_target_rooms_6.json`, `building_living_rectangle_colony.json`, and candidate-count expectation in `building_living_size_spacious.json`.

## Verification

- PASS: `.\BUILD.cmd --ci dm -DUNIT_TESTS` completed successfully (`Done in 3.571s`; build targets were up to date).
- PASS: Full living visual matrix:
  `py tools\world_edit_visual\scripts\render_workflow.py --timeout-seconds 360 --poll-seconds 2 --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --case building_living_point_colony --case building_living_point_colony_east --case building_living_point_colony_south --case building_living_point_colony_west --case building_living_rectangle_colony --case building_living_rectangle_colony_north --case building_living_rectangle_colony_south --case building_living_rectangle_colony_west --case building_living_size_compact --case building_living_size_spacious --case building_living_size_standard --case building_living_target_rooms_6`
  Result: `Cases: 14`, `Semantic export: 14/14 ready`, `Done: rendered=14, failures=0`, index `tools/world_edit_visual/index.md`.
- PASS: Aggregate report check over all 14 living outputs returned `v2_nonzero_failures= []`.
- PASS: Representative manual visual review of latest `semantic_sprites.png` outputs for `building_living_rectangle_colony`, `building_living_target_rooms_6`, and `building_living_size_spacious`: connected separated rooms, shared-wall doors, required bedroom/sanitation/storage/common scenes present, no blocked main route, no repeated focal dining/social scene clusters.
- PASS: Storage/workshop smoke:
  `py tools\world_edit_visual\scripts\render_workflow.py --timeout-seconds 240 --poll-seconds 2 --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6`
  Result: `Cases: 2`, `Semantic export: 2/2 ready`, `Done: rendered=2, failures=0`.
- PASS: `git diff --check` exited cleanly.

## Plan Fidelity Matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Read active contract and code surfaces. | Read-only discovery above. | DONE |
| M2 | MUST | Replace stale task-state. | This v2.1 contract replaces the prior wall-topology state. | DONE |
| M3 | MUST | Challenge and old-path audit. | Self challenge above. | DONE |
| M4 | MUST | v2.1 datums/state. | Contracts, fixture state, validation state, report surfaces updated. | DONE |
| M5 | MUST | Pattern influence zones/connections. | Living patterns emit region candidates, influence zones, route hints, and room connections; static audit found no hardcoded door/slot calls. | DONE |
| M6 | MUST | Room allocator. | `building_layout_v2_room_allocator.dm` builds contract rooms and rejects bad geometry/scene capacity. | DONE |
| M7 | MUST | Opening solver. | `building_layout_v2_opening_solver.dm` and production `solve_building_v2_openings()` place connection-driven shared-wall doors. | DONE |
| M8 | MUST | Window solver policy. | Window policy fields and v2 window-policy counter implemented; living matrix reports zero violations. | DONE |
| M9 | MUST | Scene hierarchy. | Primary anchors, negative-space masks, secondary anchors, and validation implemented. | DONE |
| M10 | MUST | Scene budget. | Living budget/minimums and focal duplicate checks implemented; living matrix reports zero budget failures. | DONE |
| M11 | MUST | Quality validator. | `building_layout_v2_quality.dm` implements v2 hard-failure counters. | DONE |
| M12 | MUST | Report/expectations. | New counters exposed and focused expectations updated. | DONE |
| C1 | CHECK | Verification. | Compile, full living visual matrix, aggregate v2 counter check, manual review, storage/workshop smoke, and `git diff --check` passed. | DONE |
