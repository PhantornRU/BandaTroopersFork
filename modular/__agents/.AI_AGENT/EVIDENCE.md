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

### Multi-Program Acceptance Verification Slice
- Verified the existing high-signal non-living production cases through the one-shot Visual Workbench semantic report gate; no visualizer-side generation was added.
- Command: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_office_rectangle_target_rooms_6 --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6 --case building_hydroponics_target_rooms_7 --case building_dormitory_target_rooms_7 --timeout-seconds 180 --no-ascii`.
- Result: `rendered=5, failures=0`.
- `building_office_rectangle_target_rooms_6`: `passed=1`, `hard_error_count=0`, `room_count=6`, `target_room_count=6`, `room_count_satisfied=1`, `room_count_gap=0`, `generated_object_count=75`, `has_interior_objects=1`, `has_template_chunks=1`, zero post-emit/route/door-cone/semantic-credit/reserved-walk/mandatory-pattern/forbidden-fallback counters.
- `building_storage_target_rooms_5`: `passed=1`, `hard_error_count=0`, `room_count=5`, `target_room_count=5`, `room_count_satisfied=1`, `room_count_gap=0`, `generated_object_count=59`, `has_interior_objects=1`, `has_template_chunks=1`, zero hard counters.
- `building_workshop_target_rooms_6`: `passed=1`, `hard_error_count=0`, `room_count=6`, `target_room_count=6`, `room_count_satisfied=1`, `room_count_gap=0`, `generated_object_count=80`, `has_interior_objects=1`, `has_template_chunks=1`, zero hard counters.
- `building_hydroponics_target_rooms_7`: `passed=1`, `hard_error_count=0`, `room_count=8`, `target_room_count=7`, `room_count_satisfied=1`, `room_count_gap=0`, `generated_object_count=72`, `has_interior_objects=1`, `has_template_chunks=1`, zero hard counters.
- `building_dormitory_target_rooms_7`: `passed=1`, `hard_error_count=0`, `room_count=7`, `target_room_count=7`, `room_count_satisfied=1`, `room_count_gap=0`, `generated_object_count=54`, `has_interior_objects=1`, `has_template_chunks=1`, zero hard counters.
- Residual risk: this proves the committed high-signal explicit target-room cases, not the full fast/full acceptance matrix from the PR99 spec.

### Exterior Opening Solver Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for moving exterior entry selection into the semantic layout flow.
- `TOOLS\AI_INDEX\ai_index.py` is absent; targeted `rg` and line-slice reads were used.
- Current production path still runs `stage_geometry -> build_building_doors()` before `build_building_semantic_layout()`. This violates the requested route/opening solver ownership because the front door is chosen from boundary geometry before semantic zones, routes, and openings are solved.
- The existing route solver seeds `build_building_primary_routes()` from `state.geometry.door_turfs`, so the safe slice is to introduce an explicit opening-solver step inside `build_building_semantic_layout()` before primary route construction, then remove the early stage call. This changes ownership without adding a visualizer fallback or weakening validation.
- Risk accepted: this does not delete all dead room-first helper code. It only removes the production early door authority and records the old helper as a remaining cleanup target.

### Exterior Opening Solver Slice
- Removed the `stage_geometry -> build_building_doors()` production pre-pass.
- Renamed the exterior entry owner to `solve_building_exterior_openings()` and call it from `build_building_semantic_layout()` after semantic region solving and before preliminary circulation/primary route construction.
- The opening solve now resets exterior door state, selects main/service openings, records actual entry direction, and emits `opening_solver` stage reports before route construction consumes `state.geometry.door_turfs`.
- Diff-level evidence: `rg -n "build_building_doors\(|solve_building_exterior_openings\(|opening_solver" modular/world_edit/code/generators/building_layout code/modules/unit_tests/world_edit_building_layout.dm` returns only the new `solve_building_exterior_openings()` proc/call/report lines and no `build_building_doors()` matches.
- Verification: `git diff --check` passed with only Git's line-ending warning for the touched DM file.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` reported the DM target up to date.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_point_colony --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed with `rendered=2, failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, `hard_error_count=0`, `room_count=6`, `target_room_count=6`, `room_count_satisfied=1`, `room_count_gap=0`, and zero post-emit/route/door-cone/semantic-credit/reserved-walk/mandatory-pattern/forbidden-fallback counters.

### Legacy Room-First Callable Cleanup Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for removing dead top-level room-first callable entrypoints.
- `rg -n "build_building_room_first_layout\(|build_building_micro_layout\(|room_first_layout" modular/world_edit/code/generators/building_layout code/modules/unit_tests/world_edit_building_layout.dm tools/world_edit_visual` showed only definitions/config writes in `building_layout_geometry.dm`; no external production or test callsites.
- `building_layout_emitter.dm` still calls `get_room_first_region_specs_for_zone()` for region report enrichment, so broad deletion of every `room_first_*` helper is not safe in this slice.
- Safe scope: delete `build_building_room_first_layout()` and `build_building_micro_layout()` so the old monolithic solver is no longer callable as a fallback, then verify compile/regression.

### Legacy Room-First Callable Cleanup Slice
- Deleted dead top-level `build_building_room_first_layout()` and `build_building_micro_layout()` from `building_layout_geometry.dm`.
- Removed the remaining production-file `room_first_layout` config writes together with those dead procs.
- Diff-level evidence: `rg -n "build_building_room_first_layout|build_building_micro_layout|room_first_layout" modular/world_edit/code/generators/building_layout code/modules/unit_tests/world_edit_building_layout.dm tools/world_edit_visual` returned no matches.
- Remaining cleanup debt: lower-level `room_first_*` helper names still exist, and at least `get_room_first_region_specs_for_zone()` is still used by `building_layout_emitter.dm` for report enrichment; they are not a production fallback entrypoint after this slice.
- Verification: `git diff --check` passed with only Git's line-ending warning for the touched DM file.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` reported the DM target up to date.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed with `rendered=1, failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, `hard_error_count=0`, `room_count=6`, `target_room_count=6`, `room_count_satisfied=1`, `room_count_gap=0`, and zero post-emit/route/door-cone/semantic-credit/reserved-walk/mandatory-pattern/forbidden-fallback counters.

### Public UI Contract Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for a focused server UI field contract slice.
- The current server `get_ui_fields()` exposed solver/control internals (`auto_size`, half sizes, `target_room_count`, window/detail budgets, service exit, blocker/replacement flags, and replacement confirmation) as user-facing fields.
- Shape and direction are not generator-specific fields; they are handled by the shared World Edit placement flow, so the building generator UI should advertise only program/style/seed and a coarse size profile.
- Safe scope: change only the building_layout server field list and size-profile normalization while preserving existing internal params for regression cases and scripted Visual Workbench acceptance. Do not move generation logic into `tools/world_edit_visual`.

### Public UI Contract Slice
- Added a coarse `size_profile` UI request path (`compact`, `standard`, `spacious`) and kept explicit half-size/room-count/blocker/window/detail/service-exit params as internal/scripted inputs.
- `building_layout.get_ui_fields()` now advertises only `archetype_id`, `faction_preset`, `building_seed`, and `size_profile`. Shared World Edit placement still owns shape and direction.
- Added unit contract `public_ui_field_contract` to reject public exposure of low-level generation fields.
- Diff-level evidence: `rg -n '"id" = "(auto_size|half_width|half_depth|target_room_count|window_density|detail_budget|back_exit|respect_blockers|replace_blocked_turfs|confirm_large_replacement)"' modular/world_edit/code/generators/building_layout/world_edit_generator_building_layout.dm` returned no matches.
- Verification: `git diff --check` passed with only Git's line-ending warning for the touched DM file.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: after `tools\build\build.bat --ci clean`, fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed with `rendered=1`, `failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, `hard_error_count=0`, `status=supported`, `room_count=6`, `target_room_count=6`, `room_count_satisfied=1`, `room_count_gap=0`, `generated_object_count=91`, `has_interior_objects=1`, `has_template_chunks=1`, and zero post-emit/route/door-cone/semantic-credit/reserved-walk/mandatory-pattern/forbidden-fallback counters.

### Support Verdict Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for wiring support/preflight reports through typed verdict payloads.
- Current evidence: `validation/building_validation_verdict.dm` defines the typed verdict datum, but `build_building_context_support_result()` still constructs a standalone list of support fields and every support caller consumes that list directly.
- Compatibility boundary: TGUI, placement state, Workbench support checks, plan metadata, and unit tests already depend on existing keys such as `status`, `reason`, `lock_code`, `request_locked`, `can_preview`, and `can_apply`.
- Safe scope: embed a `verdict` payload generated from `world_edit_validation_verdict` into the existing support list, preserve it through config/state/plan metadata, and add focused unit assertions. This advances M4 without rewriting every UI/Workbench consumer in the same slice.

### Support Verdict Slice
- Added `build_building_support_validation_verdict()` and `finalize_building_support_result()` so every `build_building_context_support_result()` path embeds a typed `world_edit_validation_verdict` payload in the existing support report adapter list.
- Preserved the support verdict through `apply_building_support_result_to_config()`, candidate state initialization, plan metadata, and Visual Workbench reports.
- Updated locked Workbench support handling to pass the full support report into `finish_locked()` instead of reducing it to `reason_code/reason`.
- Visual Workbench reports now expose `support` and top-level `validation_verdict`, making the semantic report JSON the source of truth for support/preflight verdict status.
- Added unit assertions for supported default preview, undersized explicit requests, and unsupported shapes to require support verdict payloads and stable hard error codes.
- Diff-level evidence: `rg -n "build_building_support_validation_verdict|finalize_building_support_result|validation_verdict|support_verdict|support_status_report" modular/world_edit/code/generators/building_layout modular/world_edit/code/visual_workbench code/modules/unit_tests/world_edit_building_layout.dm` shows the support finalizer, plan/state preservation, report export, and tests.
- Verification: `git diff --check` passed with only Git's line-ending warning for the touched DM file.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: after `tools\build\build.bat --ci clean`, fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed with `rendered=1`, `failures=0`; report JSON had `support.status=SUPPORTED_AND_VALIDATED`, `validation_verdict.status=supported`, `validation_verdict.stage=feasibility`, `validation_verdict.hard_errors=0`, `room_count=6`, `target_room_count=6`, `room_count_satisfied=1`, `room_count_gap=0`, and zero hard counters.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 120 --no-ascii` passed with `rendered=2`, `failures=0`; both locked reports had `support.status=UNSUPPORTED_WITH_CLEAR_ERROR`, `validation_verdict.status=unsupported`, `validation_verdict.stage=feasibility`, and first hard error `program.insufficient_footprint`.
- Residual risk: this closes support/preflight verdict transport only. Full M4 still needs generation, hard validation, apply, and post-apply to converge on the same typed verdict object instead of parallel metadata/counter contracts.

### Generation Verdict Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for wiring successful generated plans through generation/hard-validation verdict payloads.
- Current evidence: `build_building_state_hard_counter_report()` already centralizes hard counters, `build_building_layout_candidate_report()` exports counters/errors per candidate, and `emit_building_layout_plan()` exports final hard counters after post-emit validation. However, supported Workbench reports currently use support/preflight verdict as top-level `validation_verdict`, so `building_living_target_rooms_6` reports `status=supported` and `stage=feasibility` even after generation.
- Safe scope: create one generation verdict helper from state validation errors plus hard counters, attach it to candidate reports and final plan metadata, and make supported Workbench reports prefer that payload while keeping support verdict as separate diagnostics.
- Residual risk accepted: this does not finish apply/post-apply verdict unification. It closes the successful preview/report hard-validation verdict gap only.

### Generation Verdict Slice
- Added `build_building_generation_validation_verdict()` from `state.validation.errors` plus centralized `build_building_state_hard_counter_report()` counters.
- Candidate reports now include `generation_validation_verdict` and `validation_verdict`; final plan metadata includes `generation_validation_verdict` and top-level `validation_verdict`.
- Supported Workbench reports now prefer final generation/hard-validation verdict as top-level `validation_verdict` and preserve support/preflight verdict separately as `support_validation_verdict`. Locked support failures still report top-level support verdicts.
- Added unit assertions that default living preview includes `generation_validation_verdict.status=valid_plan`, `stage=candidate_validation`, zero hard errors, and final `validation_verdict.status=valid_plan`.
- Verification: `git diff --check` passed with only Git's line-ending warnings for touched DM files.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: after `tools\build\build.bat --ci clean`, fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 120 --no-ascii` passed with `rendered=3`, `failures=0`.
- Report metrics: `building_living_target_rooms_6` had `status=supported`, top-level `validation_verdict.status=valid_plan`, `validation_verdict.stage=candidate_validation`, `validation_verdict.hard_errors=0`, `support_validation_verdict.status=supported`, `room_count=6`, `target_room_count=6`, `room_count_satisfied=1`, `room_count_gap=0`, and `post_emit_validation_error_count=0`.
- Locked report metrics: `building_living_explicit_compact_2x2` and `building_living_explicit_micro_1x1` retained top-level `validation_verdict.status=unsupported`, `stage=feasibility`, and first hard error `program.insufficient_footprint`.
- Residual risk: full M4 remains partial until apply/post-apply results converge on the same verdict object instead of separate result/meta fields.

### Apply Verdict Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for adding typed apply/post-apply and undo verdict payloads.
- Current evidence: `apply_plan()` already gates missing preview, changed params, runtime blockers, target state hash presence, mutation preflight, rollback on turf/object/post-apply failures, `suppress_history` on failed transactions, and success only after post-apply world inspection. `run_undo_validation()` already reverts the changeset and records `status=restored|failed`.
- Current gap: apply/post-apply/undo are reported through `result.success`, `result.meta`, `post_apply_validation_error_count`, and `undo.restored`, not `world_edit_validation_verdict` payloads. `building_living_target_rooms_6` expectations currently assert status, direction, and post-emit counters but not `generation=valid_plan`, `apply=applied`, or `undo=restored`.
- Safe scope: attach typed phase verdict payloads to existing result/meta/report lists and extend the expectation resolver. Do not alter changeset mutation order, rollback behavior, history suppression, or the top-level generation verdict semantics.
- Residual risk accepted: this closes report/expectation transport for apply and undo, not the broader full fast/full acceptance matrix or every safe-apply UX path.

### Apply Verdict Slice
- Added `build_building_apply_validation_verdict()` and `stamp_building_apply_validation_verdict()` so `apply_plan()` success, pre-mutation world conflicts, missing preview/plan errors, no-change outcomes, rollback failures, and post-apply inspection failures serialize `apply_validation_verdict` payloads.
- Preserved existing transaction mechanics: target state hash presence gate, runtime blocker checks, changeset mutation order, rollback on failure, `suppress_history` for failed/rolled-back results, and success only after post-apply world inspection.
- Workbench reports now attach `apply_validation_verdict` and `undo_validation_verdict` phase payloads. Apply-stage errors use apply verdict as the top-level error verdict; supported reports keep generation verdict top-level and expose apply/undo as phase verdicts.
- Extended the Workbench expectation resolver with `generation`, `generation_stage`, `apply`, `apply_stage`, and `undo_validation` keys; `building_living_target_rooms_6.json` now requires `generation=valid_plan`, `generation_stage=candidate_validation`, `apply=applied`, and `undo=restored`.
- Verification: `git diff --check` passed with only Git's line-ending warnings for touched DM files.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: after `tools\build\build.bat --ci clean`, fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification note: an initial parallel locked-case run overlapped with `clean`/rebuild and failed before semantic export (`rendered=0`); this was discarded as a command scheduling artifact and rerun sequentially.
- Verification: sequential `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 120 --no-ascii` passed with `rendered=2`, `failures=0`.
- Verification: after the fresh UNIT_TESTS compile, `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed with `rendered=1`, `failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, empty `expectation_diff`, top-level `validation_verdict.status=valid_plan`, `validation_verdict.stage=candidate_validation`, `apply_validation_verdict.status=applied`, `apply_validation_verdict.stage=apply`, `apply_validation_verdict.hard_errors=0`, `apply_validation_verdict.metrics.post_apply_validation_error_count=0`, `apply_validation_verdict.metrics.transaction_committed=1`, `undo.status=restored`, `undo_validation_verdict.status=passed`, `undo_validation_verdict.hard_errors=0`, `room_count=6`, and `target_room_count=6`.
- Residual risk: this closes phase verdict/report expectation transport for the required regression case. M4 remains partial until the same verdict contract is confirmed through the broader TGUI/safe-apply UI surface and fast/full acceptance matrix.

### Feasibility Dry-Solve Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for making support/preflight prove candidate feasibility.
- Current evidence: `build_building_context_support_result()` still performs blocker, catalog, shape, and area checks only; it rejects `estimated_usable_area <= 0` and `estimated_usable_area < required_compact_area`, then returns `supported`.
- Current generation evidence: `build_plan_from_shape_contract()` already runs a bounded candidate loop over point size/family candidates, and `build_building_layout_candidate_state()` runs the production pipeline into in-memory state before emission/apply.
- Recursion risk: `build_building_layout_candidate_state() -> resolve_shape_footprint()` calls support again, so dry solve needs a private `skip_feasibility_dry_solve` guard inside candidate config. That guard must not be public UI/config fallback.
- Safe scope: reuse the production candidate path for a support dry-solve probe, record attempt/status diagnostics into the support verdict, reject no-solution preflight with structured `program.insufficient_footprint`, and add focused assertions plus the required `building_living_target_rooms_6` expectation.
- Residual risk accepted: this proves support/generation parity for the bounded candidate path but does not finish the full typed-module solver extraction or fast/full matrix.

### Feasibility Dry-Solve Slice
- `normalize_building_params()` now preserves a private `skip_feasibility_dry_solve` recursion guard for internal candidate support re-entry.
- `build_building_context_support_result()` still uses blocker/catalog/shape/area checks as early rejection filters, but supported placement-context requests now call `build_building_feasibility_dry_solve_result()` before returning `supported`.
- The dry solve reuses the production bounded candidate path: `build_building_request() -> get_building_point_size_candidate_specs()/get_ordered_building_footprint_candidate_families() -> build_building_candidate_request() -> build_building_layout_candidate_state()`.
- Support reports and support verdict metrics now include `feasibility_dry_solve_status`, `feasibility_dry_solve_stage`, candidate attempt count, valid candidate count, error candidate count, reason, and selected candidate diagnostics.
- `building_living_target_rooms_6.json` now gates `preflight=supported` and `feasibility_dry_solve=solved` in addition to generation/apply/undo expectations.
- Focused unit contract asserts default living preview support has a solved dry solve with at least one attempted and one valid candidate.
- Verification: `git diff --check` passed with only Git's line-ending warnings for pre-existing touched DM files.
- Verification: fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: sequential `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 180 --no-ascii` passed with `rendered=2`, `failures=0`.
- Verification: fresh `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 180 --no-ascii` passed with `rendered=1`, `failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, empty expectation diff, `support_validation_verdict.status=supported`, `support.feasibility_dry_solve_status=solved`, `feasibility_dry_solve_attempt_count=3`, `feasibility_dry_solve_valid_candidate_count=1`, top-level `validation_verdict.status=valid_plan`, `apply_validation_verdict.status=applied`, `undo_validation_verdict.status=passed`, and `hard_error_count=0`.
- Verification: final clean normal `tools\build\build.bat --ci clean; tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.

### Same-Seed Determinism Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for adding semantic same-seed regression proof.
- Current evidence: `emit_building_layout_plan()` already serializes `layout_hash`, `footprint_hash`, `room_graph_hash`, `route_hash`, `wall_hash`, `pattern_credit_hash`, and `determinism_check_hash` into preview metadata.
- Current Workbench flow builds preview from production `build_plan_from_shape_contract()` before apply, so a second preview with the same shape/context/params can prove deterministic output without mutating the world or using PNG artifacts.
- Safe scope: opt-in replay only for cases that request a determinism expectation; compare production preview metadata hashes, expose the result in `report.json`, and make `building_living_target_rooms_6` require `same_seed_layout_hash=true`.
- Residual risk accepted: this validates the required regression case and lays the semantic report hook for matrix determinism, but it does not execute the full fast/full seed matrix.

### Same-Seed Determinism Slice
- Visual Workbench cases now run an opt-in production preview replay when `expect.same_seed_layout_hash` is present or `render.determinism_replay` is enabled.
- The replay uses the same production `build_plan_from_shape_contract()` path before apply and compares `layout_hash`, `footprint_hash`, `room_graph_hash`, `route_hash`, `wall_hash`, `pattern_credit_hash`, and `determinism_check_hash`.
- Supported semantic reports now include `determinism_replay`, top-level `same_seed_layout_hash`, first/replay hashes, and hash mismatch names.
- The expectation resolver now supports `same_seed_layout_hash`; `building_living_target_rooms_6.json` requires it to be `true`.
- Added focused unit assertion that default living same-seed previews keep the same `layout_hash`.
- Verification: `git diff --check` passed with only Git's line-ending warnings for pre-existing touched DM files.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: fresh `tools\build\build.bat --ci clean; tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 240 --no-ascii` passed with `rendered=1`, `failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, empty expectation diff, `same_seed_layout_hash=1`, `determinism_replay.status=matched`, `layout_hash=147484000`, `replay_layout_hash=147484000`, `hash_mismatches=0`, and `hard_error_count=0`.
- Verification: sequential `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 180 --no-ascii` passed with `rendered=2`, `failures=0`.

### Hard-Pass Topology Gate Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `PASS WITH RISKS` for expanding required regression gates.
- Current evidence: generator metadata already emits mandatory-room, door-cone, reserved-walk, reachability, and post-apply counters, but Workbench metrics do not export every hard-pass counter and `building_living_target_rooms_6` does not assert all of them.
- Current gap: no stable `door_corner_count` exists. Door selection penalizes corner boundary turfs, but the required regression needs an explicit production validation counter.
- Safe scope: add `door_corner_count` to validation state, compute it in `validate_building_door_buffers()` only when the door is on an exterior boundary corner and a same-side non-corner boundary wall segment exists, emit it through plan metadata/candidate reports/Workbench metrics, and gate the required case.
- Residual risk accepted: this strengthens the required regression and hard validation report, but does not execute the full fast/full matrix.

### Hard-Pass Topology Gate Slice
- Added `door_corner_count` to production validation state, reset flow, hard-counter names, hard-counter value lookup, and plan metadata.
- `validate_building_door_buffers()` now increments `door_corner_count` only for an exterior boundary door on an avoidable corner: the same exterior side must have a non-corner boundary wall segment with interior floor and no dense fixture blocker.
- Workbench metrics now export remaining hard-pass counters: mandatory-room missing/bounds/access, mandatory fixture reachability, reachability failure, door-cone blocked, door-corner, reserved-walk blocked, and post-apply validation error count.
- Workbench expectation resolver now supports pasted-contract aliases `mandatory_room_unreachable_count` and `post_apply_error_count`.
- `building_living_target_rooms_6.json` now gates `post_apply_error_count=0`, `door_corner_count=0`, `door_cone_blocked_count=0`, `mandatory_room_missing_count=0`, and `mandatory_room_unreachable_count=0` in addition to previous source-of-truth expectations.
- Added focused unit assertions for default living preview `door_corner_count=0`, `mandatory_room_missing_count=0`, and `mandatory_room_no_access_count=0`.
- Verification: `git diff --check` passed with only Git's line-ending warnings for pre-existing touched DM files.
- Verification: `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: fresh `tools\build\build.bat --ci clean; tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 240 --no-ascii` passed with `rendered=1`, `failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, empty expectation diff, `post_apply_validation_error_count=0`, `door_corner_count=0`, `door_cone_blocked_count=0`, `mandatory_room_missing_count=0`, `mandatory_room_no_access_count=0`, `reachability_failure_count=0`, `reserved_walk_blocked_count=0`, `semantic_credit_without_emitted_slots_count=0`, and `hard_error_count=0`.
- Verification: sequential `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 180 --no-ascii` passed with `rendered=2`, `failures=0`.

### Atomic Apply Target-State Continuation Read-Only Challenge
- Date: 2026-06-27.
- Result: `FAIL CURRENT GAP` for claiming target-state hash as an enforced apply gate.
- Current evidence: `stamp_building_target_state_metadata()` writes `target_state_hash`, `apply_plan()` computes `current_target_state_hash`, but the current `apply_plan()` comment says the live hash is diagnostic only and does not compare it to the preview hash.
- Contract risk: runtime blocker checks and request keys do not cover every live target drift. A preview can become stale through target turf changes while still reaching mutation, which violates M8 all-or-nothing apply with target state hash.
- Safe scope: enforce `expected_target_hash != current_target_hash` as typed `WORLD_EDIT_BUILDING_APPLY_WORLD_CONFLICT` before preflight/mutation, preserve existing rollback/post-apply mechanics, and add a focused stale-preview unit regression.
- Forbidden substitution: do not satisfy this slice with report-only metadata, Workbench-only fault injection, or a test that bypasses production `apply_plan()`.

### Atomic Apply Target-State Slice
- Enforced preview target-state hash in production `apply_plan()` by comparing normalized numeric preview/live hashes before mutation; mismatch returns typed `WORLD_EDIT_BUILDING_APPLY_WORLD_CONFLICT`.
- Expanded `build_building_target_state_hash()` to include existing non-mob movable atoms on target turfs in addition to turf type/density, so stale object drift is part of the preview target-state contract.
- Failure path now serializes target/current hash metrics in `apply_validation_verdict`, sets `target_state_mismatch`, suppresses history, and leaves `transaction_committed=FALSE` with no changeset.
- Added focused unit regression `world_edit_building_layout/atomic_apply_rejects_stale_target_state`: build real preview plan, mutate one target turf after preview, call production `apply_plan()`, and assert `world_conflict`, `apply_target_state_mismatch`, no commit, no changes, no created objects, no history, and unchanged drift turf.
- Verification: `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings after one macro-scope fix in the test.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 240 --no-ascii` passed with `rendered=1`, `failures=0`.
- Report metrics: `building_living_target_rooms_6` had `passed=1`, empty expectation diff, `validation_verdict.status=valid_plan`, `apply_validation_verdict.status=applied`, `undo_validation_verdict.status=passed`, and zero post-apply/topology hard counters. An intermediate false mismatch was fixed by normalizing both hash sides before comparison.
- Verification: after `tools\build\build.bat --ci clean`, fresh normal `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: after another `tools\build\build.bat --ci clean`, fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings.
- Verification: `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 180 --no-ascii` passed with `rendered=2`, `failures=0`.
- Verification: final `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_target_rooms_6 --timeout-seconds 240 --no-ascii` passed with `rendered=1`, `failures=0`.
- Final report metrics: `building_living_target_rooms_6` had `passed=1`, empty expectation diff, `validation_verdict.status=valid_plan`, `validation_verdict.stage=candidate_validation`, `apply_validation_verdict.status=applied`, `undo_validation_verdict.status=passed`, and zero `post_apply_validation_error_count`, `door_corner_count`, `door_cone_blocked_count`, `mandatory_room_missing_count`, `mandatory_room_no_access_count`, `reachability_failure_count`, `reserved_walk_blocked_count`, and `semantic_credit_without_emitted_slots_count`.
- Verification: final `git diff --check` passed with only Git CRLF warnings for pre-existing touched DM files.

## Current Verification Status
- `git diff --check` passed on the current working tree after the room-count slice.
- Fresh `tools\build\build.bat --ci dm -DCIBUILDING -DANSICOLORS -Werror` and fresh `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror` passed with 0 errors/0 warnings after the shape/safety, candidate-search, semantic solver, atomic apply, capability furnishing, capability matrix payload, TGUI payload, acceptance report gate, anti-shedding, room-purpose fill, and room-count request slices.
- `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_explicit_compact_2x2 --case building_living_explicit_micro_1x1 --timeout-seconds 120 --no-ascii` passed through the production runtime with `rendered=2, failures=0`.
- `py -3 tools\world_edit_visual\scripts\render_workflow.py --case building_living_point_colony --case building_living_target_rooms_6 --timeout-seconds 120 --no-ascii` passed through the production runtime with `rendered=2, failures=0`; target-room metrics showed 6 solved rooms, a satisfied target room count, and zero post-emit/reserved/mandatory hard counters.
- Current slice moved exterior entry selection into `build_building_semantic_layout() -> solve_building_exterior_openings() -> build_building_primary_routes()`; normal DM compile passed and the required `building_living_target_rooms_6` semantic report still passed with hard counters at zero.
- Current slice removed dead top-level `build_building_room_first_layout()` / `build_building_micro_layout()` and cleared all exact `room_first_layout` markers from production generator/test/tooling scope; normal DM compile passed and `building_living_target_rooms_6` still passed as a semantic-report regression.
- Current multi-program acceptance slice passed office/storage/workshop/hydroponics/dormitory explicit target-room cases through semantic reports with nonzero generated objects/interiors/templates and zero hard counters.
- Current public UI contract slice restricts advertised building_layout server fields to program/style/seed/size profile, keeps low-level params internal for scripted cases, adds a unit field-list contract, and keeps `building_living_target_rooms_6` passing with zero hard counters.
- Current support verdict slice embeds typed feasibility verdict payloads in support reports and Visual Workbench `report.json` for both supported and locked cases; full M4 remains partial outside support/preflight.
- Current generation verdict slice emits final hard-validation verdict payloads in candidate reports, plan metadata, and supported Workbench semantic reports; `building_living_target_rooms_6` now reports top-level `validation_verdict.status=valid_plan` / `stage=candidate_validation` while support/preflight remains `support_validation_verdict.status=supported` / `stage=feasibility`.
- Current apply verdict slice emits apply/post-apply and undo phase verdict payloads; `building_living_target_rooms_6` expectations now gate `generation=valid_plan`, `apply=applied`, and `undo=restored` with empty expectation diff.
- Current feasibility dry-solve slice makes support/preflight prove at least one production in-memory candidate before reporting supported; `building_living_target_rooms_6` expectations now gate `preflight=supported` and `feasibility_dry_solve=solved`.
- Current same-seed determinism slice makes `building_living_target_rooms_6` gate a production preview replay hash match, not visual artifact stability.
- Current hard-pass topology gate slice makes `building_living_target_rooms_6` assert the remaining hard-pass counters from semantic report metrics.
- Current target-state apply slice enforces preview/live target-state hash equality before mutation and adds a focused stale-preview unit regression. Broader mid-mutation rollback/post-apply failure runtime tests remain pending.
- Fresh normal DM compile, fresh UNIT_TESTS DM compile, compact/micro locked Visual cases, and final required `building_living_target_rooms_6` Visual case passed after the target-state apply slice.
- Full `tools\build\build.bat --ci lint tgui-test` currently fails only at `packages/tgui-panel/chat/renderer.tsx(479,13): error TS2554: Expected 1 arguments, but got 2`; this file is outside the WorldEditPanel/PR99 TGUI slice and was not modified here. Full Jest suites passed 17/17, 101/101 tests.
- Focused runtime unit suite and one-shot Workbench acceptance are still pending.

## Plan Fidelity Matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1 | MUST | Remove `room_first_layout` and old room-first production path. | `stage_geometry` routes only through semantic layout; dead top-level `build_building_room_first_layout()` / `build_building_micro_layout()` were deleted; `rg` finds no `build_building_room_first_layout`, `build_building_micro_layout`, or `room_first_layout` in generator/test/tooling scope. Lower-level `room_first_*` report/helper names remain cleanup debt, not fallback entrypoints. | DONE |
| M2 | MUST | Typed production flow foundation. | Typed domain/verdict/catalog skeleton added; production geometry now runs semantic region solver stages. | PARTIAL |
| M3 | MUST | Advertise only point/rectangle/filled_rectangle and stable unsupported code. | `get_supported_placement_shapes()` diff and tests. | DONE |
| M4 | MUST | Single feasibility/verdict contract. | Verdict datum added; support/preflight embeds typed verdict payloads; successful candidate/final plan metadata and supported Workbench reports emit generation hard-validation verdicts; apply/post-apply and Workbench undo now emit phase verdict payloads and required regression expectations. Broader TGUI/safe-apply UI and fast/full matrix parity remain outside this slice. | PARTIAL |
| M5 | MUST | Remove hidden program shedding/micro/silent fallback. | Silent shape fallback removed; undersized explicit living requests now return `program.insufficient_footprint` and compact/micro Workbench cases pass as locked; dead compact/micro helper cleanup and broader program matrix remain. | PARTIAL |
| M6 | MUST | Bounded deterministic candidate search over `RECT/L/T/U`, score all valid. | Candidate loop changed and compiled; focused runtime tests pending. | DONE |
| M7 | MUST | Capability-based furnishing. | Provider registry, `style.missing_capability`, provider-backed placement metadata, alias capability gates, required fallback cleanup, server capability matrix payload, and bounded room-purpose fill pass implemented; full typed catalog/template solver pending. | PARTIAL |
| M8 | MUST | Atomic apply/no partial success. | Target-state hash metadata, live hash enforcement before mutation, stale-preview focused regression, rollback transaction, post-apply inspection, and history suppression hook implemented. Broader mid-mutation rollback/post-apply failure runtime tests remain. | PARTIAL |
| M9 | MUST | Safe defaults. | `normalize_building_params()` diff and unit assertion. | DONE |
| M10 | MUST | One-shot acceptance/no production Workbench poller. | Production startup cleanup done; enable flag/poll loop removed from visual workbench; guarded `UNIT_TESTS` one-shot entrypoint and DreamDaemon params added; reports now validate expectations and Python workflow fails on report mismatch; undo/restoration validation pending. | PARTIAL |
| M11 | MUST | TGUI server capability payload/safe apply workflow. | TGUI reads `building_layout.capability_matrix`, decorates incompatible program/style options, shows current lock status, and blocks preview/start/apply for unsupported rows; broader safe-apply UX hardening remains. | PARTIAL |
| M12 | MUST | Bounded requested room count with physical geometry. | `target_room_count` request, same-zone divider planner, component reconstruction for explicit target requests, metadata, unit coverage, and target-room Visual case added; dense-aware post-emit/route cleanup passes focused Visual cases; exact arbitrary matrix remains. | PARTIAL |
| M13 | MUST | Broader multi-program arbitrary-size/room acceptance. | Office, storage, workshop, hydroponics, and dormitory explicit target-room cases passed through semantic reports with solved target rooms, emitted objects/interiors/templates, and zero hard counters; full fast/full matrix remains outside this slice. | DONE |
| M14 | MUST | Exterior entry/openings selected inside semantic topology/route/opening solve, not early boundary pre-pass. | `stage_geometry` no longer calls `build_building_doors()`; `build_building_semantic_layout()` now calls `solve_building_exterior_openings()` before primary route construction; `rg` shows no `build_building_doors()` matches; `building_living_target_rooms_6` report still passes. | DONE |
| M15 | MUST | Public request UI exposes only program/style/seed/size profile; shape/direction remain shared placement controls and solver internals remain internal/test params. | `get_ui_fields()` now returns only `archetype_id`, `faction_preset`, `building_seed`, and `size_profile`; `public_ui_field_contract` rejects low-level ids; compile and `building_living_target_rooms_6` semantic report passed. | DONE |
| M16 | MUST | Support/preflight verdicts use typed verdict payloads instead of detached ad-hoc support-only status. | Support reports include `verdict`, `preflight_status`, hard/warning counts; plan metadata and Workbench locked reports preserve support verdicts. | DONE |
| M17 | MUST | Supported semantic reports use generation/hard-validation verdict as final truth. | Candidate reports, final plan metadata, and supported Workbench reports now include `generation_validation_verdict`; `building_living_target_rooms_6` report shows top-level `valid_plan/candidate_validation` with zero hard errors and separate `support_validation_verdict=supported/feasibility`. | DONE |
| M18 | MUST | Apply/post-apply/undo phases emit typed verdict payloads and are expectation-checkable in semantic reports. | `apply_plan()` stamps `apply_validation_verdict` for success/failure/rollback/post-apply paths; Workbench reports attach `apply_validation_verdict` and `undo_validation_verdict`; `building_living_target_rooms_6` expectations gate generation/apply/undo phase statuses and passed with empty diff. | DONE |
| M19 | MUST | Support/preflight runs bounded feasibility dry solve before reporting supported. | Support now calls `build_building_feasibility_dry_solve_result()` after early area/blocker filters, records dry-solve metrics in support reports/verdicts, rejects no-solution as unsupported, and `building_living_target_rooms_6` gates `preflight=supported` plus `feasibility_dry_solve=solved`. | DONE |
| M20 | MUST | Required regression proves same-seed `layout_hash` determinism through semantic report expectations. | Visual Workbench now opt-in replays production preview and compares semantic hashes; `building_living_target_rooms_6` requires `same_seed_layout_hash=true` and passed with matching first/replay `layout_hash=147484000` and zero mismatches. | DONE |
| M21 | MUST | Required regression gates remaining hard-pass topology counters from semantic report metrics. | Added production `door_corner_count`, exported remaining hard-pass counters to Workbench metrics, added expectation aliases, and `building_living_target_rooms_6` passed with zero door-corner, door-cone, mandatory-room, reachability, reserved-walk, semantic-credit, post-apply, and hard errors. | DONE |
| M22 | MUST | Apply enforces preview target-state hash against live state before mutation. | `apply_plan()` now compares normalized preview/current target hashes before mutation, returns typed `world_conflict` on mismatch, and unit regression `atomic_apply_rejects_stale_target_state` asserts no commit/history/changes. | DONE |
