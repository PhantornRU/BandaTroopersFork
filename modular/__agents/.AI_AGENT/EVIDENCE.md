# EVIDENCE - PR99 Building Layout Generator Rewrite

## Read-Only Discovery

Date: 2026-06-18 / 2026-06-19
Baseline HEAD: `050a5790352b0b54f78585e0a54fce4dfacf7ebe`

### Discovery Summary
- `TOOLS\AI_INDEX\ai_index.py` is absent; discovery used targeted `rg`.
- Include chain: `colonialmarines.dme -> modular/modular.dme -> modular/world_edit/_world_edit.dme`.
- Production path before edits: `manager preview -> generator.preview() -> build_plan() -> build_placement_plan() -> build_plan_from_shape_contract() -> build_building_layout_candidate_state() -> pipeline stages -> emit_building_layout_plan()`.
- Before edits, `room_first_layout` was forced, decorative graph/BSP stages bypassed, point used `RECT` only and stopped after first valid candidate, shape support advertised too broadly, and `apply_plan()` allowed warning-success partial buildings.

## Plan-Mapping Challenge

Result: `PASS WITH RISKS`.

- Entry audit confirmed forced `room_first_layout`, decorative stages, broad shapes, first-valid candidate search, and silent shape fallback.
- Furnishing audit confirmed legacy archetypes/styles, `faction_preset` as mixed shell/function catalog, template alias patching, fallback anchors, and semantic credit helpers.
- Runtime audit confirmed partial apply success, no target world hash, production Workbench poller via `enabled.txt`, inert `expect_config`, and broad TGUI shape payload.
- Risks accepted: existing tests encode legacy micro/program-shedding behavior; implementation must rewrite tests with code and preserve diff-level evidence.

## Implementation Evidence

### Current Continuation Read-Only Challenge
- Date: 2026-06-20.
- Result: `PASS WITH RISKS` for a focused anti-shedding + purpose-aware furnishing slice.
- `TOOLS\AI_INDEX\ai_index.py` is absent; targeted `rg` and line-slice reads were used.
- `git status --short` showed existing dirty PR99 files in generator/report surfaces plus local task-state; these are treated as in-progress user/agent work and are not reverted.
- Production path remains `build_plan_from_shape_contract() -> build_building_layout_candidate_state() -> pipeline -> stage_fixtures -> place_building_fixtures() -> place_building_cluster_spec() -> select_fixture_turf()/place_fixture_at() -> emit_building_layout_plan()`.
- Hidden compact/micro shedding is still reachable through `build_building_context_support_result()`, `apply_building_support_result_to_config()`, `building_semantic_plan.build_adaptive_required_min_area()`, and tests/cases that expect `program_shedding=true`; this conflicts with PR99 M5 and the current user request.
- Visualizer scope checked: `tools/world_edit_visual` must remain a production report/artifact reader; no generation logic should be added there for this slice.
- Risk accepted: this slice improves production generator behavior but does not complete the full PR99 solver/catalog/acceptance rewrite.

### Cleanup/Baseline Slice
- Removed production Workbench startup from `code/game/world.dm`.
- Removed duplicate modpack Workbench init from `modular/world_edit/_world_edit.dm`.
- Deleted tracked `tools/world_edit_visual/enabled.txt`, tracked `tools/world_edit_visual/out/**`, root `plan`, `pipeline/fix_stages.py`, and local analysis scripts.
- Worker verification: `git diff --check` passed; `git ls-files tools/world_edit_visual/out tools/world_edit_visual/enabled.txt tools/world_edit_visual/inbox` empty; DM build passed with 0 errors/0 warnings before later local edits.

### Typed Domain Foundation Slice
- Added PR99 domain/status defines, validation verdict, typed request extension fields, footprint/program/candidate/stage diagnostics datums, and program/style catalog skeletons.
- Added `_world_edit.dme` includes for new domain/catalog/validation files.
- Worker verification: `git diff --check` passed; DM build passed with 0 errors/0 warnings before later local edits.

### Shape/Safety Slice
- `get_supported_placement_shapes()` now advertises only `point`, `rectangle`, and `filled_rectangle`.
- Unsupported shapes now return `shape.unsupported_for_building_layout`.
- Removed `has_explicit_shape_params()` and silent non-point-to-point fallback from `build_plan()`.
- `normalize_building_params()` now defaults `respect_blockers=TRUE` and `replace_blocked_turfs=FALSE`.
- Added focused unit assertions for safe defaults and supported/unsupported shape contract.

### Candidate Search Slice
- Increased `WORLD_EDIT_BUILDING_MAX_LAYOUT_CANDIDATES` to 16.
- Removed point-mode forced `RECT` returns from footprint-family ordering/selection.
- `build_plan_from_shape_contract()` now uses ordered point candidate families and does not break on first valid candidate; best score wins across bounded attempts.
- Verification: `git diff --check` passed; `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.

### Semantic Solver Production Slice
- `build_building_layout_state()` no longer forces `room_first_layout`.
- `stage_geometry` now calls `build_building_semantic_layout()` instead of `build_building_room_first_layout()`.
- Layout graph/spatial partition/room shape/derived wall/semantic room stages no longer early-return on `room_first_layout`.
- Added semantic layout orchestration over existing region solver helpers: semantic regions, primary routes, zone dividers, nested rooms, and solved-room reconstruction for downstream interiors/fixtures.
- Removed `room_first_layout` from production plan metadata/report surfaces and renamed the live layout contract to `semantic_region_solver`.
- Old helper `build_building_room_first_layout()` still exists as dead legacy code in `building_layout_geometry.dm`; no production pipeline caller remains.
- Verification: `rg -n "room_first_layout|build_building_room_first_layout|fallback mode|TODO" modular\world_edit\code\generators\building_layout\pipeline\stages` returned no matches; DM compile passed with 0 errors/0 warnings.

### Atomic Apply Slice
- Added target-state hashing over all plan target turfs and non-mob movable atoms; preview emission stamps `target_state_hash`, target count, and revision time.
- `apply_plan()` now rejects stale target state before mutation and uses a local changeset as the rollback record.
- Any runtime turf/object failure now returns failed transaction with rollback instead of warning-success partial apply.
- Added post-apply live world inspection for expected turf types and emitted object type/dir existence; failures rollback and suppress manager history.
- Added typed `/datum/world_edit_apply_result/suppress_history` and manager support to skip history only for opt-in failed/rolled-back results while keeping admin logging and chat behavior.
- Verification: `rg -n "applied with warnings|skipped_runtime|runtime_skip_reasons|skipped_base_turf|add_building_runtime_skip_reason" modular\world_edit\code\generators\building_layout` returned no matches; DM compile passed with 0 errors/0 warnings.

### Capability Furnishing Slice
- Added explicit slot-to-capability mapping and provider path-root checks in `building_layout_fixture_capabilities.dm`.
- Removed generic slot fallback provider resolution; missing required slots now produce nonfunctional providers instead of substituting table/cabinet/bed/console paths.
- `normalize_building_params()` now builds `fixture_providers_by_slot` and locks incompatible program/style combinations with `style.missing_capability`.
- `place_fixture_at()` records `required_capability` / `provided_capabilities` and rejects required placements whose provider does not satisfy the required capability.
- Removed `allow_single_object_fallback` from cluster specs and living required cluster definitions; required generic `object` without template/procedural pattern is rejected.
- Removed infrastructure raw category reconciliation so required infrastructure credit comes from placed requirement IDs, not category counts.
- Semantic/signature alias credit now requires a provider-backed placement with the alias capability; post-emit validation enforces the same capability metadata.
- Signature support fixtures no longer inherit parent signature credit.
- Added unit contract assertions for colony functional bed provider and Covenant living `style.missing_capability` rejection.
- Verification: `rg -n "allow_single_object_fallback|generic fallback|reconcile_canonical_requirement_count|semantic_credit_without_emitted_slots_count\+\+" modular\world_edit\code\generators\building_layout` returned no matches; `git diff --check` passed; `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.

### Capability Matrix Payload Slice
- Subagent `Ohm` completed a read-only audit of safe server payload surfaces and recommended manager-level generator payload threading over ad-hoc TGUI reconstruction.
- Added base `/datum/world_edit_generator/get_ui_payload(list/current_params)` and threaded `generator_payload` through `build_generator_ui_payload()`.
- `building_layout` now emits `generator_payload.building_layout` with schema version, current program/style/error fields, and `capability_matrix`.
- Capability matrix payload includes program required slots/capabilities, style capabilities/providers grouped by capability, and program/style compatibility rows with `supported`, `lock_code`, `missing_slots`, and `missing_capabilities`.
- Added focused unit contract assertion for `living|colony` support and `living|covenant` `style.missing_capability` lock through the server payload.
- Verification: `rg -n "generator_payload|capability_matrix|capability_matrix_payload_contract|get_ui_payload" modular\world_edit\code code\modules\unit_tests\world_edit_building_layout.dm` shows the new hook, manager payload wiring, building payload emitter, and test contract.

### TGUI Capability Consumption Slice
- Subagent `Meitner` completed a read-only audit of `WorldEditPanel` and confirmed the minimal touch points: `types.ts`, `viewModelBuildingLayout.ts`, `viewModelChrome.ts`, `workspaceGeneric.tsx`, `fieldRenderers.tsx`, `viewModelPage.ts`, and `viewModel.test.ts`.
- Added typed `generator_payload.building_layout.capability_matrix` definitions to `WorldEditPanel` backend data.
- Added `viewModelBuildingLayout.ts` as the central row lookup/status/decorator helper for program/style compatibility.
- `buildWorldEditViewModel()` now decorates `archetype_id` and `faction_preset`/`style_id` options from the server matrix so incompatible options are disabled with lock reasons.
- `getToolbarActions()` now treats unsupported building layout matrix rows as request locks, disabling preview/start/apply entrypoints and reusing the lock reason as tooltip text.
- `GenericToolWorkspace` now shows a compact bad-tone compatibility status card for the current unsupported row.
- `fieldRenderers.tsx` now supports disabled/tooltip select options and switches locked select fields to button strips so per-option locks are visible.
- Added TGUI view-model tests for unsupported `living|covenant`, supported `living|colony`, and option-level program/style lock decoration.
- Verification: targeted Prettier and ESLint passed for changed `WorldEditPanel` files; targeted `WorldEditPanel/viewModel.test.ts` passed 26/26.

### Acceptance Report Gate Slice
- Removed the DM `enabled.txt` gate, `world_edit_visual_should_start()`, `init_world_edit_visual_workbench()`, and the Workbench spawn/poll loop from `modular/world_edit/code/visual_workbench`.
- `prepare_cases.py` no longer writes `tools/world_edit_visual/enabled.txt`.
- Added guarded one-shot acceptance startup in `code/game/world.dm`: only `UNIT_TESTS` builds with explicit `world.params["world_edit_acceptance"]` call `run_world_edit_visual_acceptance_from_params()`, then shut down.
- `runtime_manager.py` now supports repeated `--param key=value` arguments and translates them to DreamDaemon `-params`; `render_workflow.py` passes `world_edit_acceptance`, inbox, and out paths.
- Visual reports now compute and serialize `hard_error_count`, `expectations.expected`, `expectations.actual`, `expectations.diff`, `expectation_diff`, and `passed`.
- Expected locked cases can pass without counting their structured lock reason as a hard error; unexpected errors still increment `hard_error_count`.
- Supported cases now export applied-state `semantic.json` before undo, then run changeset undo validation and serialize `undo.status`, `undo.restored`, `undo_reverted_count`, `undo_skipped_count`, and `undo_restored` metrics; undo failures add a hard report error.
- `render_workflow.py` now treats missing/invalid reports, `passed=false`, expectation mismatches, and hard errors as aggregate failures via `report_failure_reason()`.
- Verification: `rg -n "world_edit_visual_should_start|enabled\.txt|init_world_edit_visual_workbench|WORLD_EDIT_VISUAL_ENABLE_FLAG|WORLD_EDIT_VISUAL_START_DELAY" code modular\world_edit\code modular\world_edit\_world_edit.dm tools\world_edit_visual\scripts` returned no matches; `py -3 -m py_compile tools\world_edit_visual\scripts\prepare_cases.py tools\world_edit_visual\scripts\render_workflow.py tools\world_edit_visual\scripts\runtime_manager.py` passed; inline Python smoke for `report_failure_reason()` passed; runtime manager dry-run showed DreamDaemon `-params world_edit_acceptance=1`; normal and `UNIT_TESTS` DM compiles passed.

### Anti-Shedding + Purpose-Aware Furnishing Slice
- `build_building_context_support_result()` now returns `UNSUPPORTED_WITH_CLEAR_ERROR` with `program.insufficient_footprint` when the selected explicit usable area is below the program compact minimum; it no longer marks that path as supported with `program_shedding`.
- Added `WORLD_EDIT_BUILDING_ERROR_PROGRAM_INSUFFICIENT_FOOTPRINT` for the stable lock code.
- Added `place_building_room_purpose_fill()` after mandatory/secondary/detail fixture phases. It is bounded by `WORLD_EDIT_BUILDING_MAX_CLUSTER_STEPS`, remaining fixture cap, per-room open floor, route/door/fixture blockers, semantic zone contract, category budget, repeat penalty, and existing capability/provider checks.
- Added `room_fill_attempt_count` and `room_fill_fixture_count` diagnostics to validation state and emitted plan metadata.
- Updated focused unit tests: explicit `2x2` and `1x1` living requests must be rejected without placements, hidden `program_shedding`, or `micro_layout`; a large living layout asserts nonzero room-purpose fill.
- Updated Visual Workbench compact/micro cases from supported-degraded expectations to locked `program.insufficient_footprint` expectations.
- Fixed `render_workflow.py` report gate to accept DM JSON `passed=1` as a pass, not only Python `true`.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed; `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed after repo `clean`; `py -3 -m py_compile tools\world_edit_visual\scripts\render_workflow.py` passed; `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 120 --no-ascii` passed with `rendered=2, failures=0`; `git diff --check` passed; stale micro-success search returned no matches.

### Room Count Continuation Read-Only Challenge
- Date: 2026-06-20.
- Result: `PASS WITH RISKS` for a focused room-count request/divider slice.
- Current production room path is `build_building_semantic_layout() -> build_building_zone_dividers() -> build_building_nested_rooms() -> build_building_rooms_from_zone_assignments()`.
- `build_building_rooms_from_zone_assignments()` currently creates exactly one solved room per active semantic zone, so large zones cannot become multiple rooms even when geometry has internal divider openings.
- `size_profile` datums exist under `domain/building_request.dm`, but no live `size_profile`/room target request is wired through `normalize_building_params()`.
- Current slice must not claim full arbitrary-room solver completion. It can add a bounded `target_room_count` request, same-zone physical dividers for large splittable zones, connected-component room reconstruction that does not merge through internal door openings, metadata/tests, and leave broader exact-room-count solver matrix as pending.

### Room Count Request Slice
- Added `target_room_count` to normalized building params, UI fields, param summary, metadata, and Visual report counters.
- Added bounded same-zone room-count divider planning in production geometry. Candidate divider plans must emit physical wall turfs plus a controlled opening, keep floor reachability, and increase the planned room-component count before being accepted.
- `build_building_rooms_from_zone_assignments()` preserves legacy one-room-per-zone reconstruction for normal `target_room_count=0` requests and uses component reconstruction only for explicit room-count requests.
- Added `room_count_divider_count`, `target_room_count`, `room_count_satisfied`, and `room_count_gap` diagnostics.
- Added focused unit coverage for target-room requests increasing solved rooms and internal walls over a same-seed baseline.
- Added Visual case `tools/world_edit_visual/cases/building_living_target_rooms_6.json`; it uses the production generator/runtime and does not generate in the visualizer.
- Verification: `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_point_colony --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed with `rendered=2, failures=0`; target report counters showed `target_room_count=6`, `room_count=6`, `room_count_divider_count=1`, `room_count_satisfied=1`, `room_count_gap=0`, `post_emit_validation_error_count=0`, `route_blocking_count=0`, `door_cone_blocking_count=0`, `semantic_credit_without_emitted_slots_count=0`, `reserved_walk_blocked_count=0`, `mandatory_pattern_failure_count=0`, and `forbidden_fallback_count=0`.

### Door-Cone Dense-Blocker Cleanup Slice
- Added dense object path semantics for emitted object validation and production layout validation.
- Post-emit validation now marks only dense `interior`/`microvariation` objects as `emitted_dense_lookup` blockers, while still granting semantic credit only through provider-backed functional placements.
- Fixture conflict repair removes reserved-lane fixtures only when their object path is dense; non-dense mandatory furniture is preserved instead of causing unnecessary mandatory pattern failure.
- Reserved lane, corridor, route-pattern, and door-buffer validators now use dense fixture checks for fixture blockers.
- Verification: `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_point_colony --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed with `rendered=2, failures=0`; baseline and target reports both had `post_emit_validation_error_count=0`, `reserved_walk_blocked_count=0`, `semantic_credit_without_emitted_slots_count=0`, `mandatory_pattern_failure_count=0`, and `forbidden_fallback_count=0`.

### Multi-Program Acceptance Continuation Read-Only Challenge
- Date: 2026-06-20.
- Result: `PASS WITH RISKS` for a focused acceptance/reporting slice.
- `TOOLS\AI_INDEX\ai_index.py` is absent; targeted `rg` and line-slice reads were used.
- Existing Visual cases cover `living` almost exclusively, plus compact/micro lock cases and one target-room case.
- Visual reports can compare arbitrary top-level metrics, but `merge_metrics()` does not currently expose `room_count`, `target_room_count`, `room_count_satisfied`, `room_count_gap`, or `room_count_divider_count`, so acceptance cannot directly assert requested room-count satisfaction yet.
- Current archetype catalog includes non-living colony-compatible programs such as `workshop`, `storage`, `hydroponics`, `kitchen`, `dormitory`, `office`, `security`, `medbay`, `engineering`, and `laboratory`. `covenant` style remains intentionally suspect/locked for many functional providers because decorative Covenant placeholders are rejected by capability validation.
- Scope for this slice: expose production report metrics and add/run a small high-signal multi-program Visual matrix. If cases fail, fix the first production generator cause rather than weakening expectations or adding visualizer-side generation.

## Current Verification Status
- `git diff --check` passed on the current working tree after the room-count slice.
- Fresh `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` and fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings after the shape/safety, candidate-search, semantic solver, atomic apply, capability furnishing, capability matrix payload, TGUI payload, acceptance report gate, anti-shedding, room-purpose fill, and room-count request slices.
- `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 120 --no-ascii` passed through the production runtime with `rendered=2, failures=0`.
- `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_point_colony --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed through the production runtime with `rendered=2, failures=0`; target-room metrics showed 6 solved rooms, a satisfied target room count, and zero post-emit/reserved/mandatory hard counters.
- Full `tools\build\build.bat --ci lint tgui-test` currently fails only at `packages/tgui-panel/chat/renderer.tsx(479,13): error TS2554: Expected 1 arguments, but got 2`; this file is outside the WorldEditPanel/PR99 TGUI slice and was not modified here. Full Jest suites passed 17/17, 101/101 tests.
- Focused runtime unit suite and one-shot Workbench acceptance are still pending.

## Plan Fidelity Matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Remove `room_first_layout` and old room-first production path. | Production pipeline no longer calls room-first; legacy helper still exists as dead cleanup target. | PARTIAL |
| M2 | MUST | Typed production flow foundation. | Typed domain/verdict/catalog skeleton added; production geometry now runs semantic region solver stages. | PARTIAL |
| M3 | MUST | Advertise only point/rectangle/filled_rectangle and stable unsupported code. | `get_supported_placement_shapes()` diff and tests. | DONE |
| M4 | MUST | Single feasibility/verdict contract. | Verdict datum added; not yet wired across runtime. | PARTIAL |
| M5 | MUST | Remove hidden program shedding/micro/silent fallback. | Silent shape fallback removed; undersized explicit living requests now return `program.insufficient_footprint` and compact/micro Workbench cases pass as locked; dead compact/micro helper cleanup and broader program matrix remain. | PARTIAL |
| M6 | MUST | Bounded deterministic candidate search over `RECT/L/T/U`, score all valid. | Candidate loop changed and compiled; focused runtime tests pending. | DONE |
| M7 | MUST | Capability-based furnishing. | Provider registry, `style.missing_capability`, provider-backed placement metadata, alias capability gates, required fallback cleanup, server capability matrix payload, and bounded room-purpose fill pass implemented; full typed catalog/template solver pending. | PARTIAL |
| M8 | MUST | Atomic apply/no partial success. | Target-state hash, rollback transaction, post-apply inspection, and history suppression hook implemented; focused tests pending. | PARTIAL |
| M9 | MUST | Safe defaults. | `normalize_building_params()` diff and unit assertion. | DONE |
| M10 | MUST | One-shot acceptance/no production Workbench poller. | Production startup cleanup done; enable flag/poll loop removed from visual workbench; guarded `UNIT_TESTS` one-shot entrypoint and DreamDaemon params added; reports now validate expectations and Python workflow fails on report mismatch; undo/restoration validation pending. | PARTIAL |
| M11 | MUST | TGUI server capability payload/safe apply workflow. | TGUI reads `building_layout.capability_matrix`, decorates incompatible program/style options, shows current lock status, and blocks preview/start/apply for unsupported rows; broader safe-apply UX hardening remains. | PARTIAL |
| M12 | MUST | Bounded requested room count with physical geometry. | `target_room_count` request, same-zone divider planner, component reconstruction for explicit target requests, metadata, unit coverage, and target-room Visual case added; dense-aware post-emit/route cleanup passes focused Visual cases; exact arbitrary matrix remains. | PARTIAL |
| M13 | MUST | Broader multi-program arbitrary-size/room acceptance. | New continuation identified living-only Visual coverage and missing report metrics; implementation and verification pending. | PARTIAL |
