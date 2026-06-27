# TODO - PR99 Building Layout Generator Rewrite

## Contract Tasks

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| T1 | MUST | Replace stale/worker-local task-state with PR99 rewrite orchestration contract. | [x] |
| T2 | MUST | Complete read-only discovery for entrypoints, include graph, callsites, data flow, side effects. | [x] |
| T3 | MUST | Complete subagent plan-mapping challenge before implementation. | [x] |
| T4 | MUST | Cleanup baseline: remove production Workbench startup, tracked enable flag, runtime artifacts, and scratch scripts. | [x] |
| T5 | MUST | Add typed domain/request/footprint/program/candidate/verdict and catalog skeleton foundation. | [x] |
| T6 | MUST | Limit advertised shapes, remove silent shape fallback, and set safe blocker defaults. | [x] |
| T7 | MUST | Make point candidate search bounded over declared `RECT/L/T/U` families and compare all valid candidates. | [x] |
| T8 | MUST | Replace legacy room-first geometry with typed footprint/topology/partition/routing solver. | [~] production path switched; legacy helper cleanup/tests pending |
| T9 | MUST | Replace furnishing/signature fallback with capability-based program/style/template registry. | [~] provider registry, required capability gates, server capability matrix payload, and required fallback cleanup implemented; full typed catalog/template solver pending |
| T10 | MUST | Replace partial apply with atomic transaction, target hash, rollback, post-apply validation, undo verification hooks. | [~] atomic transaction/history hook implemented; stale target-state regression added; broader rollback/post-apply failure runtime tests pending |
| T11 | MUST | Add/rewrite focused unit/integration tests for domain, solver, furnishing, apply/undo, and E-WEV regressions. | [~] furnishing provider and capability matrix payload contract assertions added; broader runtime suite pending |
| T12 | MUST | Replace Workbench polling with one-shot acceptance runner and expectation validator. | [~] production/startup enable flag and poll loop removed; guarded `UNIT_TESTS + world.params["world_edit_acceptance"]` one-shot entrypoint added; reports emit `passed`, expectation diff, hard error count, and undo restoration metrics; Python workflow passes DreamDaemon `-params` and fails on report mismatch; live fast/full matrix execution and broader schema-v2 cases pending |
| T13 | MUST | Update TGUI to server capability payload and safe apply workflow. | [~] TGUI consumes `generator_payload.building_layout.capability_matrix`, decorates program/style locks, and blocks preview/apply for unsupported rows; full safe-apply UX hardening pending |
| T14 | CHECK | Run build/focused tests/acceptance/TGUI gates as surfaces are touched. | [~] `git diff --check`, normal DM compile, fresh UNIT_TESTS DM compile, Python `render_workflow.py` py_compile, and targeted Visual Workbench compact/micro rejection cases passed; full `lint tgui-test` still previously blocked by unrelated `tgui-panel/chat/renderer.tsx:479`; full runtime unit/full acceptance pending |
| T15 | MUST | Current continuation: remove hidden compact/micro program shedding from supported `living` generation and replace sparse/noisy optional furnishing with bounded room-purpose-aware fill. | [x] |
| T16 | MUST | Current continuation: add a bounded production room-count request path that creates real same-zone dividers and reports multiple solved rooms without visualizer generation. | [x] |
| T17 | CHECK | Follow-up: resolve Visual post-emit door-cone blockers for dense multi-door buildings without breaking mandatory semantic furniture placement. | [x] |
| T18 | MUST | Current continuation: expand production acceptance beyond living-only with multi-program explicit-size/target-room cases and report metrics that prove solved rooms/furniture without visualizer generation. | [x] |
| T19 | MUST | Current continuation: move exterior entry/door selection out of `stage_geometry` early boundary pre-pass and into semantic topology/route/opening solve evidence. | [x] |
| T20 | MUST | Current continuation: remove dead top-level `build_building_room_first_layout()` / micro fallback callable surface from production DM. | [x] |
| T21 | MUST | Current continuation: restrict public building_layout UI to program/style/size profile/seed while keeping target-room and solver internals as non-public regression/internal params. | [x] |
| T22 | MUST | Current continuation: wire support/preflight through typed validation verdict payload while preserving existing UI/Workbench support report shape as adapter output. | [x] |
| T23 | MUST | Current continuation: emit final generation/hard-validation verdict payloads for candidate reports, plan metadata, and supported Workbench semantic reports. | [x] |
| T24 | MUST | Current continuation: emit typed apply/post-apply and undo verdict payloads and make `building_living_target_rooms_6` expectations assert `generation=valid_plan`, `apply=applied`, and `undo=restored`. | [x] |
| T25 | MUST | Current continuation: make support/preflight prove feasibility with a bounded dry solve through the production candidate path before returning `supported`. | [x] |
| T26 | MUST | Current continuation: make `building_living_target_rooms_6` assert same-seed `layout_hash` determinism through the semantic report/expectation gate. | [x] |
| T27 | MUST | Current continuation: make `building_living_target_rooms_6` assert remaining hard-pass topology counters from production validation metadata. | [x] |
| T28 | MUST | Current continuation: enforce live `target_state_hash` mismatch as a production apply world-conflict and add a focused stale-preview regression. | [x] |

## Forbidden Substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | Do not wrap or guard old `room_first_layout` and call the rewrite done. |
| F2 | Do not leave old solver production-reachable behind config/fallback/compat flag. |
| F3 | Do not make Workbench or reports reinterpret hard errors as supported. |
| F4 | Do not keep advertised shapes that lack preview/apply/undo acceptance. |
| F5 | Do not replace capability failures with decorative or visually similar objects. |
| F6 | Do not accept partial apply success, skipped placements, or history for failed transactions. |
| F7 | Do not move business logic outside `modular/**` except minimal required glue. |
| F8 | Do not use tests alone to close MUST/KEEP/REJECT without diff-level evidence. |
| F9 | Do not solve furniture quality in `tools/world_edit_visual`; visualizer must only display production generation. |
| F10 | Do not fill rooms by random scatter that ignores semantic zone, route clearance, budgets, or repeat caps. |
| F11 | Do not satisfy requested room count by metadata-only room splitting; the production geometry must add bounded physical dividers/openings where it reports extra rooms. |
| F12 | Do not hide post-emit door-cone blockers by weakening production placement semantics or making Visual Workbench generate/repair layouts itself. |
| F13 | Do not claim arbitrary-size/program support from a single `living` case; acceptance must cover multiple production programs and explicit sizes. |
| F14 | Do not keep `stage_geometry -> build_building_doors()` as the production authority for exterior entry before semantic route/opening solve. |
| F15 | Do not expose low-level generation controls (`target_room_count`, half sizes, windows, blockers, service exits, detail budget, replacement confirmation) as the user-facing building_layout contract. |
| F16 | Do not keep support/preflight status as an ad-hoc list-only contract while reporting that the unified verdict contract is implemented. |
| F17 | Do not use support/preflight `supported` verdict as the final semantic report verdict for a successfully generated plan; final report truth must come from generation hard validation. |
| F18 | Do not claim apply/undo acceptance from booleans alone; phase results must be serializable verdict payloads and expectation-checkable in the semantic report. |
| F19 | Do not let area-only support/preflight return `supported` when no production candidate can satisfy topology/routes/hard validation. |
| F20 | Do not satisfy same-seed determinism with PNG/sprite comparison, cached metadata, or visualizer-side normalization; replay the production preview and compare semantic hashes. |
| F21 | Do not satisfy hard-pass topology acceptance from visual inspection or missing metrics; counters must be emitted by generator validation and enforced by semantic report expectations. |
| F22 | Do not leave `target_state_hash` as a diagnostics-only field while relying on runtime blockers, request keys, or report assertions to imply atomic apply safety. |

## Old Path Audit

| Old path/proc | Expected status | Evidence command |
| --- | --- | --- |
| `room_first_layout` config and metadata | removed / not found in production generator | `rg -n "room_first_layout" modular/world_edit/code/generators/building_layout` |
| `build_building_room_first_layout()` | removed or not callable from production | `rg -n "build_building_room_first_layout" modular/world_edit/code/generators/building_layout` |
| Decorative stage bypasses | deleted or replaced by real typed stages | `rg -n "room_first_layout|TODO|fallback mode" modular/world_edit/code/generators/building_layout/pipeline/stages` |
| Silent shape fallback | removed | `rg -n "building_shape_fallback|unsupported_shape_silent_fallback|has_explicit_shape_params" modular/world_edit/code/generators/building_layout` |
| Program shedding/micro degradation | removed from `living`; explicit profiles only | `rg -n "program_shedding|DEGRADE_MICRO|micro_layout|size_degrade_level" modular/world_edit/code/generators/building_layout code/modules/unit_tests/world_edit_building_layout.dm` |
| Semantic/furnishing credit hacks | removed for required capabilities | `rg -n "semantic_credit_without_emitted|allow_single_object_fallback|fallback_anchor_required|forbidden_fallback" modular/world_edit/code/generators/building_layout` |
| Sparse/noisy optional furnishing | bounded purpose-aware fill pass, no visualizer-only generation | `rg -n "purpose_aware|room_fill|place_building_room" modular/world_edit/code/generators/building_layout tools/world_edit_visual` |
| Partial apply warning success | removed | `rg -n "applied with warnings|skipped_runtime|result.success = TRUE" modular/world_edit/code/generators/building_layout` |
| Workbench production poller | removed from production startup | `rg -n "world_edit_visual_should_start|enabled.txt|init_world_edit_visual_workbench" code modular/world_edit/code modular/world_edit/_world_edit.dm` |
| Early exterior door pre-pass | removed from stage entry; opening solver owns exterior entry | `rg -n "build_building_doors\\(" modular/world_edit/code/generators/building_layout/pipeline/stages modular/world_edit/code/generators/building_layout/building_layout_geometry.dm` |
| Low-level public UI knobs | absent from `get_ui_fields()`; only internal/test params may use them directly | `rg -n '"id" = "(auto_size|half_width|half_depth|target_room_count|window_density|detail_budget|back_exit|respect_blockers|replace_blocked_turfs|confirm_large_replacement)"' modular/world_edit/code/generators/building_layout/world_edit_generator_building_layout.dm` |
| Ad-hoc support-only verdict gap | support reports include `verdict` payload and state metadata preserves it | `rg -n "build_building_support_validation_verdict|finalize_building_support_result|support_status_report\\]\\[\"verdict\"|support_report\\[\"verdict\"\\]" modular/world_edit/code/generators/building_layout code/modules/unit_tests/world_edit_building_layout.dm` |
| Supported semantic report uses feasibility verdict as final truth | must be replaced by generation/hard-validation verdict, with support kept separately | `rg -n "generation_validation_verdict|support_validation_verdict|validation_verdict" modular/world_edit/code/generators/building_layout modular/world_edit/code/visual_workbench code/modules/unit_tests/world_edit_building_layout.dm` |
| Apply/undo phase outside verdict contract | apply/post-apply/undo must expose typed phase verdicts and semantic report expectations | `rg -n "apply_validation_verdict|undo_validation_verdict|post_apply_validation_report|validation_verdict" modular/world_edit/code/generators/building_layout modular/world_edit/code/visual_workbench tools/world_edit_visual/cases/building_living_target_rooms_6.json` |
| Area-only preflight support | support must include dry-solve status/attempt metrics and use candidate failure as structured unsupported result | `rg -n "feasibility_dry_solve|skip_feasibility_dry_solve|build_building_feasibility_dry_solve_result" modular/world_edit/code/generators/building_layout code/modules/unit_tests/world_edit_building_layout.dm tools/world_edit_visual/cases/building_living_target_rooms_6.json` |
| Missing same-seed determinism gate | required regression must compare production preview `layout_hash` on replay and expose expectation result | `rg -n "same_seed_layout_hash|determinism_replay|layout_hash" modular/world_edit/code/visual_workbench tools/world_edit_visual/cases/building_living_target_rooms_6.json` |
| Missing hard-pass topology gates | required regression must gate door-corner, mandatory-room, reachability, door-cone, and post-apply counters from semantic report metrics | `rg -n "door_corner_count|mandatory_room_missing_count|mandatory_room_no_access_count|reachability_failure_count|door_cone_blocked_count|post_apply_validation_error_count" modular/world_edit/code/generators/building_layout modular/world_edit/code/visual_workbench tools/world_edit_visual/cases/building_living_target_rooms_6.json` |
| Diagnostics-only target state hash | stale preview/live target drift must fail before mutation as typed `world_conflict` | `rg -n "current_target_state_hash|target_state_hash|target_state_mismatch|apply_target_state_mismatch" modular/world_edit/code/generators/building_layout code/modules/unit_tests/world_edit_building_layout.dm` |
