# PLAN - Living V2 Universal Pattern/Scene Solver

Status: VISUAL REVIEW HARDENING APPLIED - RESIDUAL POLISH RISK
Date: 2026-07-02

## Goal
Replace the current living v2 scaffold with a deterministic graph-constrained solver path:

typed request -> footprint -> feasibility dry solve -> program graph -> bounded candidate search -> constrained room allocation -> route/opening solver -> shell derivation -> semantic furnishing -> hard validation -> scoring -> immutable plan -> atomic apply.

The user-facing contract stays narrow: program, style, size-or-shape, direction, seed. Doors, rooms, routes, windows, furniture, infrastructure, validation, and scoring are generator responsibilities.

## Source Documents
- Current user request: replace hardcoded layout/door/scene placement with a universal pattern/scene solver.
- Attached review text `da8a944a.../pasted-text.txt`.
- `modular/world_edit/docs/rework_docs/tech_rework/30.06.26_review_2.md`.
- Current production code under `modular/world_edit/code/generators/building_layout/v2/**`.

## Scope
- Production v2 code: `modular/world_edit/code/generators/building_layout/v2/**`.
- Shared validation/reporting fields only where needed for semantic expectations.
- Living visual cases/expectations under `tools/world_edit_visual/cases/**`.
- Unit/acceptance coverage for the production generator.

## Non-Scope
- No visualizer-side generation or PNG-driven source of truth.
- No storage/workshop v2 data-pack rollout before living passes the new solver contract.
- No random module/recipe expansion as a substitute for room/scene solving.
- No legacy fallback for a living no-solution: living v2 must fail with structured feasibility/no-solution evidence.

## Expected New Path
1. Living v2 patterns produce room/route relation candidates only.
2. Room allocation validates room contracts, dimensions, graph role, privacy, and required scene feasibility before a candidate can be accepted.
3. Opening solver derives main exits and internal doors from shared wall candidates, rejecting corner, short segment, clearance-blocked, and privacy-bad openings.
4. Window solver derives exterior windows from room window policy instead of hardcoded pattern coordinates.
5. Scene solver applies primary/secondary/detail layers, global scene limits, room identities, and slot budgets before emission.
6. Validators expose hard counters for room identity, scene fragmentation, large empty rooms, door/shared-wall correctness, and window policy.

## Forbidden Old Paths
- Pattern procs in `building_layout_v2_living.dm` must not call `add_building_v2_door()` or `add_building_v2_window()` as the production source of living openings.
- `validate_building_v2_layout_topology()` must not trust door metadata alone for room connectivity; it must verify shared-wall/floor adjacency.
- Living v2 must not pass because counters ignore unreadable rooms, fragmented scenes, invalid door placement, or forbidden windows.
- `tools/world_edit_visual/**` must not generate or repair layouts.

## Acceptance
- `building_living_target_rooms_6` stays a mandatory regression case without `use_layout_v2` in config.
- Current bad screenshot class fails semantic counters until the solver proves room identities, openings, route, windows, and scene composition.
- At least two hard-valid living v2 candidates for the standard living target.
- N/S/E/W point placement, compact/standard/spacious sizes, rectangle/filled rectangle, and undersized negative remain covered.
- Storage/workshop existing cases remain legacy unless explicitly v2-gated.
- Required checks when practical:
  - `git diff --check`
  - `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`
  - focused visual workflow for living target/matrix and non-living smoke.

## Current Result

- Living v2 now derives doors/windows through solver stages, not hardcoded living pattern calls.
- Living v2 now materializes room rectangles through `solve_building_v2_room_allocation()` from allocation slots, room contracts, and required scene-fit checks.
- Living v2 scene solving enforces a global public focal limit and required bedroom/sanitation/storage identities through hard counters.
- Living v2 candidate selection now retries score-ordered candidates through isolated post-emission hard validation before final state emission.
- `side_spine_room_row` is post-emission hard-valid on the rectangle regression and is locked by a 3 hard-valid candidate expectation.
- `building_living_target_rooms_6` is green without `use_layout_v2` and proves at least two hard-valid candidates.
- Living matrix is green across N/S/E/W, compact/standard/spacious, rectangle, and undersized negative feasibility cases.
- Storage/workshop remain on legacy path.
- Manual visual review rejected the previous green output: `building_living_rectangle_colony` is living-v2 and previously had huge sparse rooms, repeated door-band openings, and weak room identity despite zero hard counters.
- The current slice adds hard semantic coverage for underfurnished rooms and route-maze complexity; rectangle now selects `front_common_back_private` with 2 hard-valid candidates while side-spine is rejected by `corridor_ribbon_count`.
- `building_storage_target_rooms_5` and `building_workshop_target_rooms_6` screenshots are legacy safety smoke artifacts, not evidence that storage/workshop are solver-ready.
- Remaining active scope: add/tighten semantic counters and solver scoring so the current rectangle screenshot class fails until the solver produces readable rooms/routes/scenes.

## Active Visual-Fail Contract

- `building_living_rectangle_colony` must not pass only because existing counters are zero; sparse public/private rooms and excessive door-band route quality must be represented by semantic counters.
- Candidate scoring must stop rewarding longer routes and extra doors as quality by default; openings/routes are bounded requirements, not a positive visual goal.
- Storage/workshop screenshots remain evidence for the next data-pack phase, but no storage/workshop-specific hotfixes are allowed before living visual acceptance.
- The undersized blank PNG remains acceptable only as a structured locked/no-solution case with no canvas changes.
