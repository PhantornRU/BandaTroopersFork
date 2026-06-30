# EVIDENCE - Variant A Building Layout Furnishing

## Read-Only Discovery

Date: 2026-06-30

- `TOOLS/AI_INDEX/ai_index.py` is absent; discovery used targeted `rg` and direct reads.
- Include chain confirms `modular/world_edit/_world_edit.dme` owns `building_layout` includes and currently includes `building_layout_fixture_capabilities.dm`, `building_layout_templates.dm`, `building_layout_fixtures.dm`, `building_layout_validators.dm`, `building_layout_emitter.dm`, and `world_edit_generator_building_layout.dm`.
- Current production fixture path: `stage_fixtures -> place_building_fixtures() -> place_building_cluster_spec() -> template/procedural placement -> place_fixture_at()`.
- Existing provider support: `building_layout_fixture_capabilities.dm` has `/datum/world_edit_building_fixture_provider`, `build_fixture_provider_registry()`, `resolve_fixture_provider()`, slot capability roots, and Covenant decorative rejection, but only as per-style slot providers, not a verified 50+ global catalog.
- Existing provider source: `get_building_faction_catalog()` contains real style object paths for colony, uscm, unsc, neutral, and Covenant placeholder paths; `resolve_building_type_path()` already uses `text2path`/`ispath`.
- Current cluster specs are declared through `add_cluster()` / `add_signature_cluster()` in `building_layout_archetypes.dm` and `building_layout_programs_extra.dm`, with `cluster_id`, `signature_id`, and `macro_id` metadata already present.
- Current semantic risk: `place_building_cluster_spec()` still falls through to procedural `table_cluster`, `object`, `paired_object`, `run`, and `wall_object` patterns. These can place loose semantic furniture when no template/module path exists.
- Current atomicity risk: template placement preplans cells, but the final placement loop skips failed cells and can leave a partial chunk. Variant A module placement must use its own atomic rollback.
- Workbench reports can gate any production metric exported in plan metadata through `merge_metrics()` and `get_expectation_actual_value()`. `building_living_target_rooms_6.json` currently lacks the requested furnishing counters.
- Dirty worktree before implementation contains only untracked `modular/world_edit/docs/rework_docs/tech_rework/30.06.26_review.md`.

## Plan-Mapping Challenge

Result: `PASS WITH RISKS`.

- Challenge 1: Provider count cannot be met by one provider per current style slot if duplicate path/slot combinations are collapsed too aggressively. Resolution: catalog entries may be style-slot providers from existing faction paths and optional explicit base providers, but every entry must resolve and audit through `text2path`/`ispath`.
- Challenge 2: A full hand-authored 100-module catalog would be high-risk and duplicative because current cluster specs already encode program/zone/role/pattern metadata. Resolution: generate placement modules from active archetype cluster specs and validate module metadata/counts in unit tests.
- Challenge 3: Replacing every old procedural pattern in one pass risks breaking infrastructure. Resolution: hard-route semantic furniture slots through modules and leave non-semantic infrastructure/template paths compatible.
- Challenge 4: Existing repair can remove fixtures after placement, creating fragmented groups. Resolution: stamp `module_instance_id`/expected member counts and validate fragmentation after repair.
- Challenge 5: Required unmapped clusters can break programs outside the immediate living case. Resolution: module mapping is generated from current cluster identifiers and falls back to required hard errors only when no module can be derived.

Implementation may proceed because risks do not change MUST/KEEP/REJECT.

## Implementation Evidence

- Added `furnishing/building_object_provider_catalog.dm` with a global verified provider registry built from existing faction `interior_paths`, resolving every entry through `resolve_building_type_path()` / `ispath`.
- Extended fixture provider payloads with `path_text`, `styles`, audit data, `dense_expected`, and `wall_mountable`; `build_fixture_provider_registry()` and `resolve_fixture_provider()` now prefer the verified registry.
- Covenant barricade/recharger paths remain `decorative_only`, `functional = FALSE`, with empty provided slots/capabilities unless future functional evidence is added.
- Added `furnishing/building_placement_module_catalog.dm` with generated modules from current archetype cluster specs, indexed by `cluster_id`, `signature_id`, and `macro_id`.
- Added module metadata: allowed programs, zones/roles, occupied offsets, clearance offsets, repeat group, max per room/building, priority, wall requirement, and member specs.
- Added atomic module solver: enumerates modules/rooms/origins/dirs, rejects invalid room roles, route reservations, door cones, unrelated reservations, and clearance conflicts; commits with `module_instance_id` and rolls back failed instances.
- Routed semantic furniture slots through `place_building_modules_for_cluster()` before legacy procedural/template paths. Required unmapped clusters hard error; optional unmapped clusters warn/skip.
- Added module instance tracking to fixture state and plan metadata.
- Added furnishing validators/counters and hard-counter exports for every requested counter.
- Updated `building_living_target_rooms_6.json` expectations to require all requested counters at zero.
- Added focused unit tests for provider registry audit/count, Covenant decorative-only behavior, placement module catalog metadata/count, and living no-loose-furniture/module-instance contracts.
- Added Workbench metric plumbing only; `tools/world_edit_visual` remains reporting/acceptance, not a production furniture writer.

## Verification Status

- `./BUILD.cmd`: PASS. Normal CBT build completed with `colonialmarines.dmb - 0 errors, 0 warnings`.
- `tools/build/build --define=UNIT_TESTS dm`: PASS. Temporary acceptance build completed with `colonialmarines.dmb - 0 errors, 0 warnings`.
- `py -3 tools/world_edit_visual/scripts/render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 180 --poll-seconds 3 --no-ascii`: PASS. `rendered=1, failures=0`.
- Final normal rebuild after acceptance: `tools/build/build clean; ./BUILD.cmd`: PASS. Normal CBT build restored with `colonialmarines.dmb - 0 errors, 0 warnings`.
- Final case report: `status=supported`, `passed=1`, `diff_count=0`, `module_instance_count=18`, and every requested furnishing counter is `0`.

## Plan Fidelity Matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Verified provider registry >=50 resolved providers. | `capability_provider_contract`; compile PASS. | DONE |
| M2 | MUST | Covenant decorative-only providers do not satisfy functional capabilities. | `capability_provider_contract`; compile PASS. | DONE |
| M3 | MUST | Placement module catalog >=100 modules with metadata. | `placement_module_catalog_contract`; compile PASS. | DONE |
| M4 | MUST | Modules place semantic recipes/groups, no loose semantic scatter. | `building_living_target_rooms_6` counters zero, `module_instance_count=18`. | DONE |
| M5 | MUST | Atomic module solver rejects invalid role/route/door conflicts. | Solver candidate checks and counters; acceptance counters zero. | DONE |
| M6 | MUST | Cluster ids/signatures/macros integrate with modules and required unmapped hard errors. | Module catalog indexes and `place_building_modules_for_cluster()`. | DONE |
| M7 | MUST | Legacy scatter disabled for semantic furniture slots. | Semantic branch precedes legacy pattern switch; acceptance counters zero. | DONE |
| M8 | MUST | Requested counters exported. | Hard-counter table, emitter metadata, Workbench metrics. | DONE |
| M9 | MUST | `building_living_target_rooms_6` gates requested counters at zero. | Case expectation diff `0`, pass. | DONE |
| M10 | MUST | Focused tests cover provider/module/furniture quality contracts. | `world_edit_building_layout.dm` added/updated tests; compile PASS. | DONE |
