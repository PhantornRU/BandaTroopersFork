# PLAN - Graph-first Building Layout Solver

Status: WORLD EDIT CLOSEOUT VERIFIED; TWO EXTERNAL SUITE FAILURES RECORDED
Date: 2026-07-17
Contract: `modular/world_edit/docs/rework_docs/tech_rework/11.07.26_review.md`

## Goal
Replace the false-green axial layout model inside the existing canonical solver with graph-first topology, functional/circulation separation, graph-aware room allocation, minimal route networks, atomic per-instance compositions, direct partition walls and honest hard quality/reporting gates.

## MUST
- `target_room_count` counts functional/open-bay/nested spaces only; entry/route/choke are circulation.
- Semantic adjacency and nested rules compile to a topology graph that controls placement and openings.
- One canonical solver enumerates declarative topology families; axial is low-score fallback only.
- Rooms allocate before route; route connects access ports and may overlay open bays without partition walls.
- Every repeated functional room receives an authored atomic module composition and capacity credit.
- Wall materialization follows ownership/partition edges; cleanup-heavy candidates are rejected.
- Trial selection compares topology families and exports one consistent metric source.
- Existing false-green underfill, composition, adjacency, template, wall-cleanup and canyon defects are hard failures.

## KEEP
- One production `building_layout` solver entrypoint, existing public generator/program/shape/UI identities, bounded deterministic search, preview/apply/undo and emitter/provider primitives.
- Existing curated placement-module catalog as the atomic geometry source.
- `tools/world_edit_visual` as observer/reporting surface only.
- Current dirty worktree, including the untracked approved review document.

## REJECT
- No v3/next/experimental solver, runtime switch, staged fallback or compatibility path.
- No program-specific coordinate recipes, detail-budget masking, random room-purpose fill or weakened expectations.
- No entry/route/choke counted as functional rooms.
- No singleton fallback for required identity and no cleanup-heavy candidate accepted as valid.

## Stages
1. A: wire current false-green counters and fixed-seed expectations as hard failures.
2. B: compile functional/circulation contracts and capacity-aware feasibility.
3. C: compile topology graph and declarative candidate families.
4. D: allocate rooms graph-first, then solve minimal routes/open-bay overlays.
5. E: assign per-instance clusters and place curated modules atomically.
6. F: materialize direct partition walls and reject cleanup.
7. G: focused four-case, six target-program, all-15, seed/direction/size and determinism acceptance.

## Stage G extension - key-program seed matrix
- Expand the six canonical target-room cases (`living`, `workshop`, `storage`, `office`, `hydroponics`, `dormitory`) across 10 deterministic seeds each.
- Generate matrix cases into temporary runtime state from committed base cases; do not add 60 copied case JSON files and do not move generation logic into the visual tool.
- Every matrix sample must run ordinary preview/apply/undo plus same-seed replay and the canonical functional/composition/route/wall/family hard gates.
- Emit one machine-readable aggregate summary with per-program/per-seed failures and layout hashes.
- Directions and compact/standard/spacious profiles remain covered by the already verified focused matrix; this extension closes the remaining seed-axis gap without multiplying the runtime into an unnecessary Cartesian product.

Outcome: VERIFIED. The canonical 60-sample matrix passed 60/60 with replay
matches, zero hard counters, 100% semantic coverage/route clearance and at
least two hard-valid topology families in every sample.

## Stage H - seeded hard-valid family selection
- Preserve hard validation and the unmodified soft quality score as the first two selection layers.
- Collapse the progressive hard-valid shortlist to the best post-emission candidate per topology family.
- Admit only family winners within a bounded quality band: 10% of the best score, clamped to 50..250 score points.
- Select deterministically from the quality-admissible family winners using the exact root seed and a stable family/candidate ordering.
- Export best score, selected gap, quality floor, eligible family count and selection index; same seed must replay exactly.
- Key-program 10-seed acceptance must retain 60/60 correctness and produce at least two structural hashes for every program that exposes at least two quality-admissible families.

Outcome: VERIFIED. The fresh 60-sample matrix passed 60/60 with exact replay.
Living, workshop, storage, office and dormitory expose two eligible families
and select at least two structural hashes. Hydroponics exposes one eligible
family because its second family winner is 348 points below the best candidate,
outside the 220-point quality margin.

## Stage I - post-selection closeout
- Re-run one ordinary preview/apply/undo representative case for every one of
  the 15 public programs after seeded family selection.
- Preserve the existing strict expectations and prove exact room counts,
  semantic coverage, route clearance and zero canonical hard counters.
- Treat the full repository unit runtime separately from solver acceptance:
  localize any non-progressing test, do not count an aborted run, and retain a
  completed focused Building Layout unit result.
- Finish with the normal compile, old-path, Python, diff and process audits.

Outcome: VERIFIED FOR BUILDING LAYOUT. The ordinary all-program batch passed
15/15. The completed repository unit run passed all 28 Building Layout tests
and reported only the three already external HALO/config/create-destroy
failures. Temporary runner instrumentation was removed before the final build.

## Stage J - visual canvas origin lifecycle
- Keep the compiled-map canvas landmark as the canonical registered origin.
- A duplicate/test-created landmark must not replace an existing live origin.
- Deleting the registered owner clears the global only when that owner is the
  current reference; deleting a duplicate leaves the canonical origin intact.
- Do not mask the defect by adding the landmark to `create_and_destroy` ignore
  lists or by weakening GC assertions.
- Verify with a focused lifecycle unit, `create_and_destroy`, ordinary visual
  acceptance, compile and final audits.

Outcome: VERIFIED. Focused and full ordinary unit runs pass the lifecycle and
stock create-and-destroy tests. The full suite now has 72 tests, 29 passing
Building Layout tests and only two external HALO/config failures.

## Bounded contracts
- Total topology candidates <= 24; beam width 6; top rectangles per node 8; <= 96 allocation expansions per topology.
- Route expansion remains bounded by `min(4 * footprint_count, 4096)`.
- Module anchors <= 64 and candidates <= 32 per module.
- Seeded family selection never expands the candidate/trial search and cannot admit a hard-invalid candidate.

## Forbidden old paths
- `adaptive_axis`/`adaptive_cross_axis` as the only families and `build_building_layout_axis_region_candidate()` as universal topology.
- `solve_building_layout_route_from_region()` before room allocation.
- automatic room-to-`route` edges for every room.
- repeated-instance ownership rejection (`instance_index > 1`).
- generic `0/1/2` scene-member sufficiency and cleanup pruning as normal finalization.
