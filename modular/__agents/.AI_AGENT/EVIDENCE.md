# EVIDENCE - PR99 Semantic Interiors Production Layer

## Read-Only Discovery

Date: 2026-07-03

- Attached `e1414e02.../pasted-text.txt` read. It requires a semantic scene solver over existing `place_fixture_at()` emitter/provider layer, plus hard semantic counters and report expectations as source of truth.
- `03.07.26_review.md` read. It rejects direct tile furniture placement, random recipes, and visual-only acceptance; it asks for room-first fields/zones/anchors/clusters.
- AI index is absent in this repo; discovery used targeted `rg` and file reads.
- Include graph: `modular/world_edit/_world_edit.dme` currently includes `pipeline/stages/stage_interiors.dm`, `stage_fixtures.dm`, furnishing catalogs, v2 solver, fixtures, infrastructure, and validators.
- Entry point: `world_edit_generator_building_layout.dm` uses `build_building_layout_v2_state(state)` for living v2; legacy pipeline runs `stage_interiors` before `stage_fixtures`.
- Current old path confirmed: `stage_interiors.dm` calls `place_room_prefab_groups(context.state, room, generator)`.
- Current placeholder confirmed: `place_room_prefab_groups()` switches room roles to prefab macro ids and then `continue`s without placing anything.
- Existing emitter contract confirmed: `place_fixture_at()` writes slot, requested_slot, category, zone_id, anchor_id, dir_source, front_dir, module_id, module_instance_id, semantic_requirement_id, cluster_id, signature_id, and related metadata.
- Existing validation/reporting already has many hard counters; new semantic alias counters and score/percent metrics are missing.
- Visual expectation comparator is in `modular/world_edit/code/visual_workbench/world_edit_visual_report.dm`; it currently supports exact equality and `layout_v2_min_candidate_count` only.

## Plan Mapping Challenge

Status: PASS WITH RISKS

- PASS: New logic can live under `modular/world_edit/code/generators/building_layout/semantic/**` with DME includes and stage glue.
- PASS: Existing `place_fixture_at()` is sufficient as the emission layer; semantic scene solver can feed it with module/scene metadata.
- PASS: The old placeholder path is isolated to `stage_interiors.dm`, and duplicate purpose-fill risk is isolated to `stage_fixtures.dm`/`building_layout_fixtures.dm`.
- PASS: Hard counters can be added through validation state, hard-counter registry, generation verdict metrics, detailed reports, and workbench expectation comparator.
- RISK: Full universal scene grammar for every program is bigger than one safe slice. Mitigation: implement the common solver/data model and living-first required scenes, while leaving storage/workshop data-pack expansion for the next phase.
- RISK: Existing v2 living has its own scene path. Mitigation: do not double-emit v2 scenes; share validation/report metrics.
- RISK: Disabling all legacy fixture placement immediately can regress non-living cases. Mitigation: semantic interiors marks success, and `stage_fixtures` skips primary placement only when semantic scenes were emitted.

## Subagent Status

- Semantic scene/emitter audit: completed. Findings used: old primary paths are `stage_interiors`, `stage_fixtures`, `place_building_room_purpose_fill`; scene metadata must preserve `scene_id`, `scene_kind`, `scene_layer`, `room_id`, slot counts, module ids; repair/fallback paths must not reintroduce old major clusters after semantic emission.
- Counter/report/expectation audit: completed. Findings used: hard counters must be added to `get_building_hard_counter_names()`, `get_building_state_hard_counter()`, generation verdict metrics, `emit_building_layout_plan()`, and `world_edit_visual_report.dm` metric merge/expectation code.

## Implementation Evidence

- Added semantic production layer:
  - `modular/world_edit/code/generators/building_layout/semantic/building_layout_semantic_defines.dm`
  - `modular/world_edit/code/generators/building_layout/semantic/building_layout_semantic_model.dm`
  - `modular/world_edit/code/generators/building_layout/semantic/building_layout_semantic_rules.dm`
  - `modular/world_edit/code/generators/building_layout/semantic/building_layout_semantic_solver.dm`
  - `modular/world_edit/code/generators/building_layout/semantic/building_layout_semantic_emitter.dm`
  - `modular/world_edit/code/generators/building_layout/semantic/building_layout_semantic_validation.dm`
- `_world_edit.dme` now includes the semantic layer before v2 includes.
- `pipeline/stages/stage_interiors.dm` now calls `run_building_semantic_interiors(context.state)`; the old `place_room_prefab_groups()` placeholder is removed.
- `pipeline/stages/stage_fixtures.dm` skips legacy primary cluster placement when semantic interiors already emitted scenes.
- `repair_building_missing_major_clusters()` now refuses to repair over semantic interiors.
- Scene emission uses `place_fixture_at()` and annotates scene/module metadata.
- V2 living scene path hardened:
  - side-surface scene now emits a secondary side table plus adjacent seating instead of consuming cabinet budget.
  - `get_building_v2_min_scene_members_for_room()` requires denser common/sleeping/sanitation/storage scenes.
- Added semantic hard counters and metrics:
  - `semantic_scene_route_block_count`
  - `semantic_scene_door_clearance_block_count`
  - `semantic_scene_required_missing_count`
  - `semantic_room_primary_scene_missing_count`
  - `semantic_major_object_without_scene_count`
  - `semantic_pairing_error_count`
  - `semantic_distribution_noise_score`
  - `semantic_functional_coverage_percent`
  - `semantic_route_clearance_percent`
- `world_edit_visual_report.dm` supports generic `*_min` and `*_max` expectation thresholds and merges semantic metrics.
- Living expectations updated for semantic source-of-truth counters:
  - `building_living_target_rooms_6`
  - `building_living_rectangle_colony`
  - `building_living_size_spacious`
  - `building_living_point_colony`
  - `building_living_point_colony_east`
  - `building_living_point_colony_south`
  - `building_living_point_colony_west`
  - `building_living_size_compact`
  - `building_living_size_standard`

## Verification

- `git diff --check`: PASS. Only CRLF normalization warnings for existing files.
- `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`: PASS, `colonialmarines.dmb - 0 errors, 0 warnings`.
- `tools\build\build.bat dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`: PASS/up-to-date through repo build path.
- Focused living + non-living smoke:
  - Command: `py tools\world_edit_visual\scripts\render_workflow.py --isolated --timeout-seconds 180 --poll-seconds 2 --case building_living_target_rooms_6 --case building_living_rectangle_colony --case building_living_size_spacious --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6`
  - Result: rendered 5, workflow failures 0.
- Living matrix + negative + non-living safety:
  - Command: `py tools\world_edit_visual\scripts\render_workflow.py --isolated --timeout-seconds 180 --poll-seconds 2 --case building_living_point_colony --case building_living_point_colony_east --case building_living_point_colony_south --case building_living_point_colony_west --case building_living_size_compact --case building_living_size_standard --case building_living_size_spacious --case building_living_rectangle_colony --case building_living_target_rooms_6 --case building_living_explicit_micro_1x1 --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6`
  - Result by report source of truth:
    - `building_living_point_colony`: passed=1, v2 hard/candidates=2/2, semantic coverage=100, clearance=100.
    - `building_living_point_colony_east`: passed=1, v2 hard/candidates=2/2, semantic coverage=100, clearance=100.
    - `building_living_point_colony_south`: passed=1, v2 hard/candidates=2/2, semantic coverage=100, clearance=100.
    - `building_living_point_colony_west`: passed=1, v2 hard/candidates=2/2, semantic coverage=100, clearance=100.
    - `building_living_size_compact`: passed=1, v2 hard/candidates=1/1, semantic coverage=100, clearance=100.
    - `building_living_size_standard`: passed=1, v2 hard/candidates=1/1, semantic coverage=100, clearance=100.
    - `building_living_size_spacious`: passed=1, v2 hard/candidates=2/2, semantic coverage=100, clearance=100.
    - `building_living_rectangle_colony`: passed=1, v2 hard/candidates=2/3, semantic coverage=100, clearance=100.
    - `building_living_target_rooms_6`: passed=1, v2 hard/candidates=2/2, semantic coverage=100, clearance=100.
    - `building_living_explicit_micro_1x1`: passed=1, status=locked.
    - `building_storage_target_rooms_5`: passed=1, status=supported, hard=0.
    - `building_workshop_target_rooms_6`: passed=1, status=supported, hard=0.
- Visual review artifacts checked for `building_living_target_rooms_6`, `building_living_rectangle_colony`, and `building_living_size_spacious`. PNG/sprite output is review evidence only; semantic reports and expectations are the pass/fail contract.

## Plan Fidelity Matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Read request/docs/code entrypoints and old paths. | Read-Only Discovery. | DONE |
| M2 | MUST | Replace stale task-state. | `PLAN.md`, `TODO.md`, `DECISIONS.md`, `EVIDENCE.md`. | DONE |
| M3 | MUST | Record challenge and old-path audit. | Plan Mapping Challenge and Old Path Audit in `TODO.md`. | DONE |
| M4 | MUST | Add semantic layer files. | `semantic/*.dm` files and DME include. | DONE |
| M5 | MUST | Replace `stage_interiors` placeholder. | `stage_interiors.dm` now calls `run_building_semantic_interiors()`. | DONE |
| M6 | MUST | Emit via `place_fixture_at()`. | `building_layout_semantic_emitter.dm`; v2 scene path remains `place_fixture_at()`. | DONE |
| M7 | MUST | Prevent primary purpose-fill fallback. | `stage_fixtures.dm` semantic skip and repair gate. | DONE |
| M8 | MUST | Add semantic counters/report metrics. | Validation state, hard-counter registry, verdict/report/metadata. | DONE |
| M9 | MUST | Add max/min expectation aliases. | `world_edit_visual_report.dm`. | DONE |
| M10 | MUST | Add focused expectations. | Living target/matrix case JSON updates. | DONE |
| M11 | REJECT | No visualizer generation/random expansion/PNG-only acceptance. | No production generation added under `tools/world_edit_visual`; semantic reports are expectations. | DONE |
| M12 | CHECK | Run verification. | Verification section. | DONE |
| M13 | MUST | Sync final evidence. | This file. | DONE |
