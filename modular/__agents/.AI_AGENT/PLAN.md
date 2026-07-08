# PLAN - PR99 Building Layout v2.1 Universal Solver

Status: COMPLETE
Date: 2026-07-08

## Goal
Implement `building_layout` v2.1 from `modular/world_edit/docs/rework_docs/tech_rework/08.07.06_review.md`: replace hardcoded living v2 room/door/scene placement with a universal Pattern -> Room Allocation -> Opening Solver -> Window Solver -> Scene Hierarchy -> Quality Validator pipeline for the living slice.

## Source Documents
- Active hard-review contract: `modular/world_edit/docs/rework_docs/tech_rework/08.07.06_review.md`.
- Production code: `modular/world_edit/code/generators/building_layout/v2/**`.
- Report contracts: `tools/world_edit_visual/cases/building_living*.json`.

## Scope
- Modular production DM code under `modular/world_edit/code/generators/building_layout/v2/**`.
- V2 quality counters and hard-counter exposure in existing building layout/reporting code.
- Focused living visual case expectations.
- Include registration in `modular/world_edit/_world_edit.dme` for new v2 solver files.

## Non-Scope
- No visualizer-side generation or repair.
- No expansion to storage/workshop/office beyond preserving smoke safety.
- No public request contract changes: keep `program/style/size-or-shape/direction/seed/use_layout_v2`.
- No upstream `code/**` rewrite.

## Expected New Paths
- `building_layout_v2_room_allocator.dm`: allocation from influence zones and room contracts.
- `building_layout_v2_opening_solver.dm`: connection-driven shared-wall door/window solving helpers.
- `building_layout_v2_quality.dm`: v2.1 semantic/visual hard-failure counters.

## Implemented Result
- Living v2 patterns now emit region candidates, influence zones, route hints, and room connections; final room rectangles are produced by the allocator.
- Room allocation uses room contracts, target area/aspect scoring, route distance, scene capacity, and rejection for thin/pen/contact-invalid room shapes.
- Openings are solved from declared room connections by scanning shared wall segments and choosing scored non-corner segment centers.
- Windows are policy-driven by room contract requirements and forbid/require/prefer semantics.
- Scene solving records primary anchors, negative-space/no-furniture masks, secondary/detail anchors, and global scene budget accounting.
- V2.1 quality counters hard-fail bad living visuals and are exposed through validation state, hard counters, reports, and focused case expectations.

## Forbidden Old Paths
- Living patterns directly producing final room rectangles through fixed room slots as the production path.
- Any `add_building_v2_door()` call from living patterns.
- One-scene switch recipes without primary anchor and negative-space checks as the only acceptance gate.
- Counter-only green without failing bad topology/composition through hard counters.

## Acceptance
- Existing living visual matrix passes semantic expectations and hard counters.
- Current bad visual patterns are represented by hard v2 quality counters: empty large room, isolated room, invalid door, thin room, scene missing, duplicate focal, negative-space blocking, and window policy.
- `BUILD.cmd --ci dm -DUNIT_TESTS`, full living visual workflow, storage/workshop smoke, and `git diff --check` passed.
