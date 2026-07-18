# PLAN - Canonical Building Layout Solver rewrite

Status: IN PROGRESS
Date: 2026-07-17
Contract: `modular/world_edit/docs/rework_docs/tech_rework/17.07.06_review.md`
Baseline: `cc210d870f8fa774de38c59b83de86f09c933ff2`

## Goal

Replace the false-green topology, allocation, routing, composition, partition and selection internals of the canonical Building Layout solver while preserving one production pipeline:

`build_building_layout_candidate_state() -> solve_building_layout() -> emit_building_layout_plan()`.

## MUST

- Compile explicit topology node kinds `FUNCTIONAL`, `CIRCULATION_TERMINAL`, `TRANSITION` and edge kinds `SHARED`, `OPEN_MERGE`, `NESTED`, `SECURE`, `ROUTE`.
- Reject a disconnected required topology at compile time; never synthesize a root edge.
- Select edge kind by precedence: nested, circulation endpoint, secure endpoint, public/open-bay pair, functional pair.
- Introduce `world_edit_building_layout_family_policy` with family-owned constraints, seed regions, partial scoring and hard validation for hub-spoke, split-wing, open-bay-perimeter, secure-core, nested-service, compound-cells and axial-fallback.
- Gate axial to compact, minimum side `<= 11`, or aspect `>= 1.7`; consider it only when no non-axial hard-valid result exists.
- Allocate the 24-candidate cap fairly across family/orientation; use beam width 6, at most 8 rectangles per node and 96 partial expansions per topology.
- Allocate root-first and parent-before-nested-child; validate topology edge geometry during partial allocation.
- Build an owner-bound route overlay after rooms with one connected bounded A* network and explicit terminals.
- Build ownership/partition edges directly, then openings; reject RECT cleanup, stubs, notches, stair-steps, misaligned joins and geometry-missing adjacency.
- Compile all required composition groups, instance policies and atomic module budgets; reserve negative space and interaction lanes before module solve.
- Select lexicographically by hard validity, mapping defects, composition deficits, residual/cleanup, topology, route efficiency and scene quality.
- Deduplicate by actual topology signature and use seed only for candidates tied through earlier layers and within `max(1 point, 0.5% best score)`.
- Repair room-report flow from normalized candidate room IDs and extend optional semantic v1 debug fields without breaking existing consumers.
- Remove legacy semantic/BSP/room-graph/divider paths only after reusable helpers are migrated and zero-callsite audits pass.

## KEEP

- Existing generator/config/UI identities and public preview/apply/undo behavior.
- Existing plan metadata compatibility and `semantic.json` schema `world_edit_semantic/v1`.
- Existing provider/emitter primitives and deterministic bounded execution.
- `tools/world_edit_visual` as exporter, renderer and acceptance harness only.
- The untracked review document and all unrelated user changes.

## REJECT

- No v3, feature flag, parallel pipeline, compatibility solver, fallback solver or program-specific coordinate recipe.
- No automatic topology repair, blanket circulation fill, universal room-to-route edge, synthetic required support spec, budget inflation, required singleton fallback or member-level required pruning.
- No seed-only route stub, direct-route fast path, route-distance helper, ad-hoc parallel-spacing score or post-emission geometry repair.
- No family-id deduplication, two-family early exit, old 10% seeded winner band or expectation weakening.
- No generation or geometry repair in `tools/world_edit_visual`.

## CHECK

1. Stage 0: new hard counters and living/hydro expectations fail on the unchanged generator.
2. Unit coverage proves disconnected topology, terminals, edge geometry, policies, axial gating, fair scheduling, bounded beam/A*, ownership, defects, atomic composition, signatures, selection and semantic payload.
3. Hard gates: unassigned `<=3%` RECT / `<=5%` irregular; zero RECT cleanup/stubs/notches/stair-steps/canyon/adjacency misses; zero required fallback/reject/fragmentation/composition/capacity/underfill; route components exactly 1; no ownerless bay; exact functional count; topology signatures 2 standard/spacious and 1 compact.
4. Runtime: living and hydro regressions, seven target programs, 840 temporary cases with shard/resume and summary v2, then preview/apply/undo for all 15 public programs.
5. Final: prescribed Werror build, focused and full units, `git diff --check`, old-path/include/callsite audit and no temporary markers/processes.

## Bounded contracts

- Topology candidates: 24 total, scheduled round-robin by family/orientation.
- Allocation: beam width 6, 8 rectangle variants per node, 96 partial expansions per topology.
- Route A*: `min(4 * footprint, 4096)` expansions; width 1 first, width 2 only for required clearance/transition.
- Composition: module instances are the indivisible budget unit; no required member pruning.

## Delivery order

1. Stage 0 hard counters and fixed regression expectations.
2. Contracts, topology compilation and family policies.
3. Bounded graph-aware allocation, route overlay, partitions and openings.
4. Atomic compositions, lexicographic selection and reporting.
5. Legacy cleanup, units, runtime matrices and final audits.

