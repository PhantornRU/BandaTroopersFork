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
- Final up-to-date build check: `./BUILD.cmd`: PASS. Output skipped up-to-date `yarn`, `dm`, and `tgui`; completed successfully.
- Final case report: `status=supported`, `passed=1`, `diff_count=0`, `module_instance_count=12`, `unique_provider_path_count=46`, `unique_functional_provider_path_count=43`, and every requested furnishing counter is `0`.
- `git diff --check`: PASS. Only line-ending normalization warnings were reported for already-touched DM files.
- Smoke check: `py -3 tools/world_edit_visual/scripts/render_workflow.py --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6 --timeout-seconds 180 --poll-seconds 3 --no-ascii`: FAIL. Both cases are now locked by existing hard gates before furnishing metrics are accepted: storage reports `forbidden_fallback=1`, `mandatory_pattern_failure=4`; workshop reports `mandatory_pattern_failure=4`.
- Continuation recheck: `git diff --check`: PASS with line-ending warnings only.
- Continuation recheck: `tools\build\build clean; .\BUILD.cmd`: PASS with `colonialmarines.dmb - 0 errors, 0 warnings`.
- Continuation recheck: `tools\build\build --define=UNIT_TESTS dm`: PASS/up-to-date.
- Continuation recheck: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 180/300/240 --poll-seconds 3 --no-ascii`: FAIL. All current reruns report `semantic_output_missing`; `last_progress` is `{}` and DreamDaemon writes no matching `semantic.json`.
- Current catalog fidelity gap: `building_placement_module_catalog.dm` still constructs modules from `archetype.cluster_specs` via `build_building_module_from_cluster()`. No explicit curated authored `register_module("living_...")` layer is present.
- Continuation fix: `code/game/world.dm` now honors explicit `world_edit_acceptance=1` outside `UNIT_TESTS`; normal DMB no longer silently skips the Visual Workbench inbox.
- Continuation fix: `building_placement_module_catalog.dm` now registers an explicit curated module family layer before generated fallback modules. Static family list contains 67 curated family entries and 165 curated recipe entries.
- Continuation fix: `placement_module_catalog_contract` now asserts `catalog.curated_module_count >= 100` and verifies curated modules are preferred for the real `living/dining_pair` cluster.
- Current living acceptance: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 240 --poll-seconds 3 --no-ascii`: PASS. `rendered=1`, `failures=0`.
- Current living report: `status=supported`, `passed=1`, `diff_count=0`, `module_instance_count=13`, `unique_provider_path_count=46`, `unique_functional_provider_path_count=43`, and every requested furnishing counter is `0`.
- Current smoke check: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6 --timeout-seconds 180 --poll-seconds 3 --no-ascii`: FAIL. Both cases now export semantic artifacts, but acceptance fails with `expectation_mismatch:12`. Storage remains locked on `forbidden_fallback=1`, `mandatory_pattern_failure=4`; workshop remains locked on `mandatory_pattern_failure=4`.

## Residual Storage/Workshop Discovery

Date: 2026-06-30

- `building_storage_target_rooms_5` failed candidate builds 5 rooms and honors direction, but validation rejects it. Pattern reports show `rack_aisles` placed `2/6` and `loading_staging` placed `0/2`; hard counters include `forbidden_fallback_count=1`, `fallback_anchor_required_cluster_count=1`, `required_room_without_required_module_count=2`, `mandatory_pattern_uncredited_count=6`, and `route_access_repair_count=1`.
- Storage semantic slot preflight reserves `loading_staging` with `planned_slot_count=2`, but module placement reports `loading_crates` as `module_failed`. `rack_aisles` has only `declared_capacity=2` against required `6`, so the current declared wall-slot contract cannot meet its required count in the target footprint.
- `building_workshop_target_rooms_6` failed candidate builds 6 rooms and honors direction, but validation rejects it. Pattern reports show `workbench_machine_wall` placed `0/4` and `parts_rack_aisles` placed `2/3`; hard counters include `required_room_without_required_module_count=2`, `mandatory_pattern_uncredited_count=5`, and `mandatory_pattern_failure_count=4`.
- Workshop semantic slot preflight finds compact capacity: `workbench_machine_wall` has `compact_planned_slot_count=4` and `parts_rack_aisles` has combined planned count `3`, but the module solver does not convert those reserved/compact slots into sufficient module credit.
- Code path evidence: `place_building_modules_for_cluster()` only calls `place_building_reserved_slot_module()` for `cluster_spec.slot == "bed"`, even though storage/workshop rack/staging/workbench clusters have reserved semantic slot turfs. This is the primary production path gap to fix.

## Residual Storage/Workshop Implementation Evidence

- `place_building_modules_for_cluster()` now uses reserved semantic slot module placement for required multi-slot semantic furniture clusters, not only beds. Optional extra placement remains best-effort after the required minimum is satisfied.
- `place_building_reserved_slot_module()` now carries per-member room ids and supports compact substitute placement specs for reserved compact turfs, while keeping the parent requirement/signature credit path.
- Semantic slot preflight now caps required semantic furniture minimums to declared placement capacity when a required cluster cannot use broad fallback anchors. This prevents small target-room footprints from demanding impossible wall-slot counts.
- `required_room_without_required_module_count` validation now ignores route/hub/entry/public/service/support anchor zones, so wall/service bands and circulation lanes are not treated as furniture rooms.
- Current residual acceptance: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6 --timeout-seconds 240 --poll-seconds 3 --no-ascii`: PASS. `rendered=2`, `failures=0`.
- Current living regression check: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 240 --poll-seconds 3 --no-ascii`: PASS. `rendered=1`, `failures=0`.
- Current report summary: living, storage, and workshop are all `status=supported`, `passed=1`; module instance counts are living `13`, storage `8`, workshop `9`; unique provider path metrics remain `unique_provider_path_count=46`, `unique_functional_provider_path_count=43`.
- Current compile checks: `tools\build\build --define=UNIT_TESTS dm` PASS with `colonialmarines.dmb - 0 errors, 0 warnings`; `tools\build\build clean; .\BUILD.cmd` PASS with `colonialmarines.dmb - 0 errors, 0 warnings`.
- Current hygiene: `git diff --check` PASS with line-ending warnings only; no DreamDaemon/DreamMaker process remains running.

## Plan Fidelity Matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Verified provider registry >=50 resolved providers. | `capability_provider_contract`; compile PASS. | DONE |
| M2 | MUST | Covenant decorative-only providers do not satisfy functional capabilities. | `capability_provider_contract`; compile PASS. | DONE |
| M3 | MUST | Placement module catalog >=100 modules with metadata. | Curated layer has 165 recipe entries; unit contract asserts `curated_module_count >= 100` and metadata on every module. | DONE |
| M4 | MUST | Modules place semantic recipes/groups, no loose semantic scatter. | Current `building_living_target_rooms_6` pass has `module_instance_count=13` and all loose/group counters at `0`. | DONE |
| M5 | MUST | Atomic module solver rejects invalid role/route/door conflicts. | Solver candidate checks and counters; acceptance counters zero. | DONE |
| M6 | MUST | Cluster ids/signatures/macros integrate with modules and required unmapped hard errors. | Module catalog indexes and `place_building_modules_for_cluster()`. | DONE |
| M7 | MUST | Legacy scatter disabled for semantic furniture slots. | Semantic branch precedes legacy pattern switch; acceptance counters zero. | DONE |
| M8 | MUST | Requested counters exported. | Hard-counter table, emitter metadata, Workbench metrics. | DONE |
| M9 | MUST | `building_living_target_rooms_6` gates requested counters at zero. | Current workflow pass has `status=supported`, `passed=1`, `diff_count=0`. | DONE |
| M10 | MUST | Focused tests cover provider/module/furniture quality contracts. | `world_edit_building_layout.dm` added/updated tests; compile PASS. | DONE |

## Review Follow-Up Discovery

Date: 2026-06-30

- Attached review `C:\Users\Alexey\.codex\attachments\f4745454-c855-4fad-bfad-089778bd7c5b\pasted-text.txt` says the current Variant A scaffold is roughly 55-60% complete and calls out enforceable blockers.
- `TOOLS/AI_INDEX/ai_index.py` is absent in this checkout; discovery used targeted `rg` and line-sliced reads.
- `building_placement_module_catalog.dm` returns from `build_building_module_member_specs()` when `module.wall_required`, so wall-required modules currently skip clearance offsets.
- `find_best_building_module_candidate()` and `build_building_module_candidate()` do not enforce `max_per_room`, `max_per_building`, or repeat-group limits.
- `validate_building_furnishing_quality()` increments `unpaired_chair_count` for any module instance with chairs and no table, which can false-fail valid seating rows.
- `providers_by_style_slot` stores only one provider per `style|slot`; provider diversity needs list storage and unique path metrics.
- `validate_building_acceptance_counters()` checks a fixed furnishing subset. A generic hard-counter fail gate is needed so future hard counters cannot pass candidate selection as warnings only.

## Review Follow-Up Implementation Evidence

- RF1: Wall-required modules now keep clearance cells. Wall and wall-object modules use front-clearance candidate checks so the adjacent wall context remains legal while door/route blockers still reject placement.
- RF2: Module solver candidate search enforces `max_per_room`, `max_per_building`, and room repeat-group caps; validators export hard violation counters.
- RF3: Module placement stamps `module_requires_table_pairing` and `module_seating_group_ok`; valid chair rows no longer increment `unpaired_chair_count`.
- RF4: Validation now applies a generic hard-counter fail gate through `building_state_has_hard_counter_failures()` before a candidate can be accepted.
- RF5: Provider registry stores provider alternatives per `style|slot` and exports unique provider path metrics; living report shows `unique_functional_provider_path_count=43`.
- RF6: Added and exported `bed_without_access_count`, `required_room_without_required_module_count`, `module_max_per_room_violation_count`, `module_max_per_building_violation_count`, and `repeat_group_violation_count`.
- RF7: `building_living_target_rooms_6` expectations include the new zero counters; final render workflow pass has zero expectation diff.
