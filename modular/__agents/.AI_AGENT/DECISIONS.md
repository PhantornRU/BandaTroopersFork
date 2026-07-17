# DECISIONS - Graph-first Building Layout Solver

## D-001: Reopen acceptance
- Prior `15/15` status was false-green; task returns to IN PROGRESS until the review Definition of Done is met.

## D-002: Rewrite inside the canonical solver
- Keep the single current entrypoint and replace axial route-first internals. Do not create a new version, flag or fallback.

## D-003: Functional target semantics
- Public `target_room_count` counts functional/open-bay/nested spaces. Circulation is compiled and budgeted separately.

## D-004: Graph-first families
- Semantic adjacency/nested rules own topology. Archetypes declare family preferences; solver families stay program-agnostic.

## D-005: Atomic authored compositions
- Reuse the curated placement-module catalog. Required identity is an atomic module or explicit compact substitute; singleton fallback is optional-only.

## D-006: Cleanup is failure evidence
- RECT candidates requiring wall cleanup are invalid. Irregular cleanup is capped by the review contract and never hides spurs.

## D-007: Stage A precedes repair
- Wire honest hard counters/expectations first so the four known layouts turn red before graph-first fixes make them green.

## D-008: Seed expansion is an acceptance harness
- Build the remaining 10-seed coverage by deriving temporary cases from the six committed target-room cases and running the ordinary visual workflow in bounded shards.
- Keep `tools/world_edit_visual` reporting-only: it may compose inputs and aggregate reports, but it cannot repair layouts or weaken expectations.
- Do not create the full seed x direction x size Cartesian product: direction and size axes are already independently verified, while the explicit residual is the 10-seed key-program axis.

## D-009: Cross-seed structural uniqueness is diagnostic
- The review requires same-seed replay equality and multiple hard-valid topology families, but does not require a different selected structural layout for every seed.
- Record unique structural hashes in the aggregate. Five key programs selected one structural winner across the sampled seeds and office selected two; this is a future scoring/diversity calibration signal, not permission to fail or weaken the current correctness gates.

## D-010: Seed chooses within a quality-admissible family tier
- Keep hard validity and the existing soft quality score authoritative. Seed never repairs, validates or increases a candidate score.
- Reduce the hard-valid shortlist to one best winner per topology family, compute a 10% best-score band clamped to 50..250 points, and exclude all winners below it.
- Apply the seed only to the stable ordered list of eligible family winners. This preserves exact replay and gives the public seed structural meaning without accepting materially worse layouts.

## D-011: Closeout separates product acceptance from repository-suite health
- Revalidate all 15 public programs after the selection change with the ordinary visual workflow, not isolated sprite-only rendering.
- A stalled or aborted repository-wide unit run is diagnostic evidence only. Solver acceptance requires completed focused unit and runtime matrices; unrelated full-suite failures are recorded without weakening Building Layout gates.

## D-012: Canvas origin owns a guarded singleton reference
- The `create_and_destroy` failure is a real lifecycle defect: a temporary landmark overwrites the compiled-map global and remains referenced during GC.
- Register only when no live origin exists. In `Destroy()`, clear the global only when it still points to `src`.
- Reject two alternatives: ignoring the type in the GC test would hide the leak, while replacing the landmark with repeated coordinate lookup would weaken the compiled-canvas contract without need.
