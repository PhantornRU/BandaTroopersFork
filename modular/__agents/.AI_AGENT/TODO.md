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
| T10 | MUST | Replace partial apply with atomic transaction, target hash, rollback, post-apply validation, undo verification hooks. | [~] atomic transaction/history hook implemented; focused tests pending |
| T11 | MUST | Add/rewrite focused unit/integration tests for domain, solver, furnishing, apply/undo, and E-WEV regressions. | [~] furnishing provider and capability matrix payload contract assertions added; broader runtime suite pending |
| T12 | MUST | Replace Workbench polling with one-shot acceptance runner and expectation validator. | [~] production/startup enable flag and poll loop removed; guarded `UNIT_TESTS + world.params["world_edit_acceptance"]` one-shot entrypoint added; reports emit `passed`, expectation diff, hard error count, and undo restoration metrics; Python workflow passes DreamDaemon `-params` and fails on report mismatch; live fast/full matrix execution and broader schema-v2 cases pending |
| T13 | MUST | Update TGUI to server capability payload and safe apply workflow. | [~] TGUI consumes `generator_payload.building_layout.capability_matrix`, decorates program/style locks, and blocks preview/apply for unsupported rows; full safe-apply UX hardening pending |
| T14 | CHECK | Run build/focused tests/acceptance/TGUI gates as surfaces are touched. | [~] `git diff --check`, normal DM compile, fresh UNIT_TESTS DM compile, Python `render_workflow.py` py_compile, and targeted Visual Workbench compact/micro rejection cases passed; full `lint tgui-test` still previously blocked by unrelated `tgui-panel/chat/renderer.tsx:479`; full runtime unit/full acceptance pending |
| T15 | MUST | Current continuation: remove hidden compact/micro program shedding from supported `living` generation and replace sparse/noisy optional furnishing with bounded room-purpose-aware fill. | [x] |
| T16 | MUST | Current continuation: add a bounded production room-count request path that creates real same-zone dividers and reports multiple solved rooms without visualizer generation. | [x] |
| T17 | CHECK | Follow-up: resolve Visual post-emit door-cone blockers for dense multi-door buildings without breaking mandatory semantic furniture placement. | [x] |
| T18 | MUST | Current continuation: expand production acceptance beyond living-only with multi-program explicit-size/target-room cases and report metrics that prove solved rooms/furniture without visualizer generation. | [ ] |

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
