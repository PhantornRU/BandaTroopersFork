# PLAN - Canonical Building Layout Solver Rewrite

Status: APPROVED / IN PROGRESS
Date: 2026-07-10

## Goal
Replace both the legacy staged generator and the living-only `v2` branch with one canonical Pattern/Contract solver for all 15 building programs.

## MUST
- One production path: Program Contract -> Pattern Fields -> Room Allocation -> Route -> Openings/Windows -> Partitions/Walls -> Scene Hierarchy -> Placement Modules -> Quality Selection -> Emit.
- Compile all program behavior from the declarative archetype/semantic catalog.
- Support exact `target_room_count`, bounded deterministic search, program-aware partitions/openings/windows, generic scene modules, and hard architectural quality gates.
- Rename all production `v2` symbols/files/metadata/counters to canonical `building_layout` / `layout_*` names with no aliases.
- Preserve generator id, 15 program ids, four public UI fields, direction/seed/size semantics, and point/rectangle/filled_rectangle public shapes.

## KEEP
- Current dirty-worktree partition/opening changes as the implementation baseline.
- Shared footprint, provider, template, emitter, infrastructure, facade, microvariation, preview/apply/undo and reporting primitives where they are used by the canonical solver.
- `tools/world_edit_visual` as reporting/review only.

## REJECT
- No V1/V2 runtime switch, per-program fallback, compatibility alias, fixed-coordinate door/room recipe, `switch(scene_contract.id)`, or validator-only masking.
- No arbitrary divider rooms to satisfy `target_room_count`.
- No program left on the staged legacy pipeline.

## CHECK
- Compile/unit/runtime verification, all-program visual matrix, manual sprite review, deterministic replay, hard-counter gates, old-path audit and `git diff --check`.

## Final old paths
- `use_layout_v2`, `layout_v2_enabled`, `building_layout_v2_enabled()`, `use_building_layout_v2()` -> removed.
- `modular/world_edit/code/generators/building_layout/v2/**` -> moved/renamed to canonical solver files.
- `building_v2_*`, `WORLD_EDIT_V2_*`, `layout_v2_*`, `v2_*` production contracts -> canonical names, no aliases.
- `/datum/world_edit_generation_stage` orchestration and the legacy branch in `build_building_layout_candidate_state()` -> removed.
- living coordinate patterns and `switch(scene_contract.id)` -> removed from production.

## Programs
`living`, `workshop`, `storage`, `checkpoint`, `medbay`, `hydroponics`, `kitchen`, `dormitory`, `office`, `security`, `chapel`, `ritual_chamber`, `compound_colony`, `engineering`, `laboratory`.
