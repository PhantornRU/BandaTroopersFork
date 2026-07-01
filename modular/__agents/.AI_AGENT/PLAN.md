# PLAN - Living V2 Visual Quality Hardening

Status: IMPLEMENTATION CONTRACT
Date: 2026-07-01

## Goal
Treat the current living v2 output as visually unacceptable even though semantic counters pass. Improve production `building_layout` v2 so living plans read as real connected houses: clear public/private/service zones, connected circulation, sensible room proportions, furniture mapped to room roles, and review PNGs that match semantic expectations.

## Source Documents
- Current user message: skeptical review of generated PNG and explicit request to use subagents.
- `modular/world_edit/docs/rework_docs/tech_rework/30.06.26_review_2.md`
- Existing Living V2 Production Hardening task-state and visual reports.

## Scope
- Production v2 solver/patterns/rules: `modular/world_edit/code/generators/building_layout/v2/**`
- Validation/metadata/reporting only where semantic expectations need to catch visual defects.
- Visual cases/expectations under `tools/world_edit_visual/cases/**`
- `tools/world_edit_visual/out/**` and PNGs are review artifacts only.

## MUST
- M1. Review generated living PNGs skeptically and convert visual defects into production constraints or semantic expectations.
- M2. Use subagents for parallel review/implementation slices.
- M3. Expand living v2 patterns beyond the current awkward proof layouts; reject maze/ribbon corridors and fake room subdivisions.
- M4. Improve connected circulation: exterior entry must connect to an intelligible corridor/hub, no long dead-end slivers unless they are deliberate service closets.
- M5. Add mapping-based scene placement rules: furniture placement must be derived from room role, scene kind, usable wall/free cells, door/window clearance, and route clearance.
- M6. Add or tighten hard counters/expectations so visually bad layouts cannot be green only because old counters are zero.
- M7. Keep fixes in production DM generator; visualizer remains reporting/acceptance only.
- M8. Preserve living v2 default and non-living legacy safety.

## REJECT
- R1. Do not call the case green from PNG review alone.
- R2. Do not add one-off seed/case conditions.
- R3. Do not hide bad room composition with extra random furniture/modules.
- R4. Do not change storage/workshop to v2 in this pass.
- R5. Do not accept huge empty halls, corridor labyrinths, orphan vertical strips, or furniture stranded away from room function.

## CHECK
- C1. Targeted semantic/PNG review of the living matrix.
- C2. Compile with `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`.
- C3. Living visual matrix passes with tightened expectations.
- C4. Storage/workshop smoke still passes and remains `layout_v2_enabled=0`.
- C5. `git diff --check`.

## Subagent Split
- Agent A: visual critique and semantic counter gaps.
- Agent B: living pattern/corridor expansion.
- Agent C: scene placement/mapping rules.
- Main agent: task-state, integration, conflict resolution, final verification.

## Current Slice - Agent C
- Implement mapping-based scene member placement in `modular/world_edit/code/generators/building_layout/v2/building_layout_v2_solver.dm`.
- Keep pattern coordinates untouched unless scene mapping cannot be made valid without them.
- Use existing hard scene counters/metrics unless a missing metric is proven necessary.
- Preserve living v2 default and non-living legacy routing.
