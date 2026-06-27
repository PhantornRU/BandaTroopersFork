# PLAN - PR99 Building Layout Generator Rewrite

Status: IMPLEMENTATION CONTRACT
Date: 2026-06-27
Baseline HEAD: e426034f221e13626e04428bc649c68cc440a9a6

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
- M14. Current continuation: exterior entries/openings must be selected inside the semantic topology/route/opening solve, not by an early boundary door pre-pass before semantic layout.
- M15. Current continuation: the public building_layout request UI must expose only program, style, seed, and size profile; shape and direction remain owned by the shared World Edit placement controls. Low-level solver knobs stay internal/test params only.
- M16. Current continuation: support/preflight must emit and preserve a typed `world_edit_validation_verdict` payload, so preview, candidate state, unit tests, Workbench, and UI consume the same feasibility verdict semantics instead of a detached ad-hoc support list.
- M17. Current continuation: successful generated plans and supported Workbench semantic reports must expose final generation/hard-validation verdicts (`valid_plan`/`validation_failed`) from candidate validation, with support/preflight verdicts kept as separate diagnostics.
- M18. Current continuation: apply, post-apply inspection, and Workbench undo validation must emit typed verdict payloads so the semantic report can prove `apply=applied` and `undo=restored` through expectations, not only boolean result fields.
- M19. Current continuation: support/preflight must run a bounded feasibility dry solve against the same production candidate path before reporting `supported`; area-only preflight may remain only as an early rejection filter.
- M20. Current continuation: `building_living_target_rooms_6` must prove same-seed determinism through semantic report expectations by replaying the production preview and comparing `layout_hash`, not by comparing PNG/sprite artifacts.
- M21. Current continuation: `building_living_target_rooms_6` must gate the remaining hard-pass topology counters (`door_corner_count`, mandatory room access/missing, reachability, door cone, post-apply errors) from production validation/report data.
- M22. Current continuation: `apply_plan()` must enforce preview `target_state_hash` against live target state before mutation; stale previews must fail as typed world conflicts with no committed changes, no history, and focused regression evidence.

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
- R7. `stage_geometry -> build_building_doors()` as the production authority for exterior entry before route/opening solve.
- R8. Public building_layout UI fields for solver internals such as `target_room_count`, half sizes, blocker override, windows, detail budget, or back/service exits.
- R9. A compatibility wrapper that keeps feasibility/support status separate from `world_edit_validation_verdict` while claiming M4 is done.
- R10. Reporting `stage=feasibility` / `status=supported` as the top-level verdict for a successfully generated semantic report; that hides whether candidate validation and hard counters actually passed.
- R11. Treating `result.success`, `undo.restored`, or `post_apply_validation_error_count=0` as enough evidence while apply/post-apply/undo remain outside the typed verdict/report expectation contract.
- R12. Reporting `supported` from area/blocker checks alone when the bounded candidate topology/route solve cannot produce at least one hard-valid in-memory candidate.
- R13. Treating visual artifact stability or a single successful generation as proof of deterministic solver output without a same-input production replay hash check.
- R14. Treating a visually acceptable mandatory regression as passing while semantic hard-pass counters are absent from the report or not expectation-gated.
- R15. Treating `target_state_hash` as diagnostics-only while claiming atomic apply; stale preview/live target drift must be a production hard gate, not only a report field or unit-test assertion.

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
- `pipeline/stages/stage_geometry.dm`: must not call `build_building_doors()` before semantic layout.
- `building_layout_geometry.dm`: exterior door selection must be owned by a semantic opening-solver step; dead `room_first_layout` helpers remain cleanup targets and must not become fallback.
- `world_edit_generator_building_layout.dm`: public UI field list must not expose low-level generation/validation knobs; regression cases and internal params can continue to use them directly.
- `world_edit_generator_building_layout.dm` / `building_layout_state.dm`: support/preflight reports must carry a typed verdict payload through config, candidate state, metadata, UI support reports, and Workbench support checks.
- `world_edit_generator_building_layout.dm` / `building_layout_emitter.dm` / `world_edit_visual_report.dm`: final plan metadata and supported Workbench reports must prefer generation/hard-validation verdict payloads over support/preflight verdict payloads.
- `world_edit_generator_building_layout.dm` / `world_edit_visual_case.dm` / `world_edit_visual_report.dm`: apply/post-apply/undo results must expose phase verdict payloads while preserving existing transaction, rollback, changeset, history, and generation verdict semantics.
- `world_edit_generator_building_layout.dm`: any internal `skip_feasibility_dry_solve` recursion guard must stay private to candidate support re-entry and must not become a public bypass or supported fallback.
- `world_edit_visual_case.dm` / `world_edit_visual_report.dm`: same-seed determinism must be validated from production preview metadata hashes and semantic expectations; Workbench must not synthesize or normalize layout output to make hashes match.
- `building_layout_validators.dm` / `building_layout_emitter.dm` / `world_edit_visual_report.dm`: hard-pass topology counters must originate in production validation metadata and flow into Workbench metrics/expectations.
- `world_edit_generator_building_layout.dm`: `apply_plan()` must compare `plan.metadata["target_state_hash"]` with the live target hash and return a typed world-conflict failure before creating a changeset when they differ.
