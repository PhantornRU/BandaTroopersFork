# PLAN - Variant A Building Layout Furnishing

Status: IMPLEMENTED AND VERIFIED
Date: 2026-06-30

## Goal
Implement Variant A for `building_layout` furnishing in the production DM generator: verified object providers, a 100+ semantic placement module catalog, an atomic module solver, cluster-to-module integration, and hard acceptance counters that fail the current loose table/chair mosaic result.

## Source Documents
- `modular/world_edit/docs/rework_docs/tech_rework/30.06.26_review.md`
- `modular/world_edit/docs/rework_docs/tech_rework/PR99_CODEX_EXECUTION_PLAN.md`

## Scope
- Primary: `modular/world_edit/code/generators/building_layout/**`
- Include integration: `modular/world_edit/_world_edit.dme`
- Tests: `code/modules/unit_tests/world_edit_building_layout.dm`
- Acceptance case/reporting: `modular/world_edit/code/visual_workbench/**`, `tools/world_edit_visual/cases/building_living_target_rooms_6.json`

## MUST
- M1. Add a verified object provider registry with at least 50 providers sourced from existing building layout presets/templates; every provider must resolve with `text2path`/`ispath`.
- M2. Covenant barricade/recharger providers must be `decorative_only` unless proven functional; they must not satisfy bed, sanitation, power, alarm, medical, hydro, security, or living capabilities.
- M3. Add a placement module catalog with at least 100 modules. Every module must define allowed programs, allowed zones/roles, occupied cells, clearance cells, repeat group, max per room, and max per building.
- M4. Modules must place existing providers as semantic recipes/groups, not loose table/chair/bed/toilet/medical/hydro/security scatter.
- M5. Add a module solver that enumerates room candidates, rejects route and door-clearance conflicts, rejects invalid room roles, and places a module atomically with no partial groups.
- M6. Integrate current cluster specs by `cluster_id`, `signature_id`, and `macro_id`; required clusters without module mapping must hard error, optional unmapped clusters must skip with warning.
- M7. Disable legacy scatter for semantic furniture slots: table, chair, bed, toilet, medical bed/storage, hydro tray, weapon/security racks.
- M8. Add and export all requested furnishing counters, including provider, module, loose object, fragmented group, role, overfill, route, and door-clearance counters.
- M9. Update `building_living_target_rooms_6` expectations so all requested furnishing counters must be zero.
- M10. Add focused unit coverage proving provider/module counts, provider path audit, Covenant decorative behavior, no loose furniture, and mosaic rejection.

## KEEP
- K1. Production fixes stay in `modular/world_edit/**`; `tools/world_edit_visual` remains reporting/acceptance only.
- K2. Existing generator/Workbench public contracts remain compatible except for adding metrics.
- K3. Existing PR99 verdict, hard-counter, deterministic replay, and target-state checks remain intact.
- K4. Task-state files are local working contract and must not be committed/PR'd unless separately requested.

## REJECT
- R1. A visualizer-side furniture generator or report-only fix.
- R2. Provider paths invented outside current build/preset/template evidence.
- R3. Treating Covenant decorative placeholders as functional providers.
- R4. Legacy single-object scatter for semantic furniture after Variant A integration.
- R5. Partial module placement, including table without required chairs or a template/module fragment after repair.
- R6. Required cluster fallback when no module mapping exists.
- R7. Acceptance that passes while any requested furnishing counter is nonzero or absent.

## CHECK
- C1. `git diff --check`
- C2. `tools/build/build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror`
- C3. `tools/build/build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`
- C4. `py -3 tools/world_edit_visual/scripts/render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 240 --no-ascii`

## Old Path Audit
- `place_building_cluster_spec()` must route semantic furniture clusters through modules before legacy patterns.
- `place_table_cluster()`, `place_fixture_object()`, `place_paired_fixture_objects()`, `place_wall_fixture()`, and `place_fixture_run()` must not remain the production fallback for semantic furniture clusters.
- Template placement may remain for non-semantic/infrastructure paths, but semantic furnishing acceptance must prove module instance IDs and no fragmented groups.
- Workbench must consume production metadata; it must not synthesize furniture quality results.
