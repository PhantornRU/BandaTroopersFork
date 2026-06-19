# PLAN - PR99 Building Layout Generator Rewrite

Status: IMPLEMENTATION CONTRACT
Date: 2026-06-19
Baseline HEAD: 050a5790352b0b54f78585e0a54fce4dfacf7ebe

## Goal
Rebuild PR #99 World Edit `building_layout` into the documented deterministic, graph-constrained, bounded solver pipeline. The current orchestration is generator-first: cleanup, typed-domain foundation, shape/candidate safety, semantic solver routing, atomic apply, first capability furnishing gate, server capability matrix payload, TGUI capability consumption, guarded one-shot acceptance/report gate, anti-shedding/purpose-aware fill, bounded target room-count dividers, and dense-aware route/post-emit validation are in place; full furnishing catalog/template solving, live acceptance matrix execution, full safe-apply UX hardening, and remaining tests remain incremental slices.

## Source Documents
- `modular/world_edit/docs/rework_docs/tech_rework/PR99_TOTAL_REWORK_SPEC.md`
- `modular/world_edit/docs/rework_docs/tech_rework/PR99_CODEX_EXECUTION_PLAN.md`
- `modular/world_edit/docs/rework_docs/tech_rework/verdict.md`
- `modular/world_edit/docs/rework_docs/CURRENT_GENERATION_PIPELINE.md`

## Scope
- Primary: `modular/world_edit/code/generators/building_layout/**`
- Integration: `modular/world_edit/_world_edit.dme`, `modular/world_edit/code/core/**` only where needed for shared verdict/apply contracts
- Tests: `code/modules/unit_tests/world_edit_building_layout.dm` and focused new tests
- Acceptance surface: `modular/world_edit/code/visual_workbench/**`, `tools/world_edit_visual/**`
- UI surface: `tgui/packages/tgui/interfaces/WorldEditPanel/**`

## MUST
- M1. Remove `room_first_layout` and all production bypass/fallback branches; old monolithic room-first code must not remain production-reachable/callable as solver fallback.
- M2. Replace decorative pipeline stages with typed production flow: request normalization -> footprint -> feasibility -> program graph -> candidate generation -> spatial partition -> routing/openings -> shell -> furnishing -> validation -> scoring -> immutable plan.
- M3. Advertise and accept only `point`, `rectangle`, and `filled_rectangle`; every other shape returns `shape.unsupported_for_building_layout`.
- M4. Use a single feasibility/verdict contract across support/preflight, generation, preview, apply, unit tests, Workbench, and TGUI payloads.
- M5. Remove hidden program shedding, `micro` degradation of `living`, and silent geometry fallback. Insufficient footprint must be structured failure.
- M6. Candidate search must be bounded, deterministic, compare all valid candidates by score, and support declared point families `RECT/L/T/U`.
- M7. Furnishing must be capability-based. Required capability credit is granted only for emitted functional providers; incompatible program/style combinations are unsupported.
- M8. Apply must be all-or-nothing with target state hash, rollback snapshot, post-apply world inspection, history publish only after commit, and no warning-success partial buildings.
- M9. Defaults must be safe: `respect_blockers=TRUE`, `replace_blocked_turfs=FALSE`; destructive replacement requires explicit confirmed preview revision.
- M10. Workbench/acceptance must stop using production startup polling and must validate expectations/reports through shared verdict contract before final merge readiness.

## KEEP
- K1. Modular-first placement under `modular/world_edit/**`; upstream `code/**` changes only for unavoidable glue, with `SS220 EDIT`.
- K2. Existing World Edit generator adapter APIs unless the shared contract requires deliberate update.
- K3. Existing deterministic seed helper concepts if they fit typed RNG streams and tests.
- K4. Existing DMM template assets only after registry/capability validation; no fake template support.
- K5. Task-state files are local working contract and must not be committed/PR'd unless separately requested.

## REJECT
- R1. Wrapper/guard/compat path around old room-first solver instead of replacement.
- R2. Visualizer fallback, relaxed preview success criteria, or report-level success while hard errors exist.
- R3. Silent shape fallback, hidden autosize/program shedding, or living micro degradation.
- R4. Generic single-object fallback or semantic credit without emitted objects for required capabilities.
- R5. Partial apply success, `applied with warnings`, skipped placements on success, or history entries for failed transactions.
- R6. Parallel `legacy`/`v2` production directories in final code.

## CHECK
- C1. `git diff --check`
- C2. `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror`
- C3. Focused unit tests for domain, footprint, solver, routing, furnishing, apply/undo.
- C4. One-shot acceptance runner with nonzero exit on expectation/report mismatch.
- C5. `tools/build/build --ci lint tgui-test` after TGUI surface changes.
- C6. Map/DMI checks from spec before final merge-ready state.

## Old Path Audit
- `building_layout_geometry.dm`: old room-first solver must be removed or rewritten so `build_building_room_first_layout` is not production-callable.
- `pipeline/stages/*`: decorative/skip stages must be removed or replaced by real typed stages.
- `world_edit_generator_building_layout.dm`: must become adapter/orchestrator only; no giant mutable solver, silent fallback, or partial apply.
- `building_layout_state.dm` and `pipeline/world_edit_building_layout_*_state.dm`: must give way to typed immutable-by-convention stage results.
- `building_layout_fixtures.dm`, `building_layout_signatures.dm`, `building_layout_macros.dm`: required capability/furnishing fallback and credit hacks must be retired.
- `code/game/world.dm`, `modular/world_edit/_world_edit.dm`, `world_edit_visual_workbench.dm`: Workbench production startup/poller must remain retired and later replaced by one-shot acceptance.
