# PLAN - PR99 Structured Scene And Wall Topology Hardening

Status: ACTIVE
Date: 2026-07-03

## Goal
Continue the `building_layout` v2/semantic rework from `03.07.26_review_2.md`: make structured scene emission a single production contract shared by living v2 and semantic interiors, validate the interiors stage instead of returning unconditional success, support multiple scene phases per room, and add counters/expectations that make the current bad visual outputs fail semantically. Extend the current slice with the user's wall/shell correction: wall placement must follow footprint mapping, with no wall chunks outside the footprint, isolated internal wall islands, unconnected leftovers, or shell-connected wall spurs that are not justified by room/route mapping.

## Source Documents
- Active hard-review contract: `modular/world_edit/docs/rework_docs/tech_rework/03.07.26_review_2.md`.
- Attached verdict: `C:\Users\Alexey\.codex\attachments\ef96aa77-7bd2-46f1-b454-4ae18f352e79\pasted-text.txt`.
- Prior semantic layer contract: `modular/world_edit/docs/rework_docs/tech_rework/03.07.26_review.md`.
- Production code: `modular/world_edit/code/generators/building_layout/**`.

## Scope
- `stage_interiors` validation/reporting.
- Unified structured-scene fixture ownership state and legacy fixture skip behavior.
- Semantic scene model/rules/solver/emitter/validation for room classes, scene phases, and member placement modes.
- Hard counters, generation verdict metrics, plan metadata, and visual report expectation metrics.
- Wall/shell topology hard counters and v2 cleanup for orphaned leftover wall cells.
- Wall/mapping validation for shell-connected but unmapped internal wall chunks.
- Focused case expectations in `tools/world_edit_visual/cases/**` as report contracts only.

## Non-Scope
- No visualizer-side generation, repair, or fixture simulation.
- No new storage/workshop/hydro/office data-pack rollout before living visual pass is semantically stable.
- No random recipe/module expansion as a substitute for room-class scene grammar.
- No one-seed coordinate hotfix.

## MUST
1. `stage_interiors` must reserve immediate door cones before semantic furnishing, call semantic interiors, emit an `interiors` stage report, and return failure when required/primary scenes are missing.
2. V2 living scenes and semantic interiors must both mark shared structured ownership fields: `structured_scene_emitted`, `structured_scene_owner`, `structured_scene_count`, and `structured_primary_scene_count`.
3. `stage_fixtures` must skip legacy fixture placement whenever structured scenes own interiors, and report `legacy_fixture_after_scene_count`.
4. Legacy major/interior fixtures after structured scene ownership must be counted and fail hard.
5. Semantic interiors must support `primary`, `secondary`, and `detail` phases per room instead of breaking after the first emitted scene.
6. Room rules must use an explicit room-class resolver, not loose substring chains as the source of truth.
7. Scene member specs must support footprint-aware placement fields and modes needed by the review: `relative`, `wall_run`, and `center_ring`.
8. Case expectations must enforce `semantic_functional_coverage_percent_min >= 90`, route clearance 100, distribution noise <= 10, and `legacy_fixture_after_scene_count = 0`.
9. Wall topology must be hard-validated: walls outside the footprint and isolated internal wall islands are invalid, reported, and expected at zero in focused living cases.
10. V2 wall derivation must not blindly treat every non-floor leftover as acceptable internal wall; orphan leftovers must be removed or rejected before immutable plan/apply.
11. Internal wall tiles must be mapped to room/route separation or room/route adjacency; shell-connected dead zones/spurs with no walkable adjacency are invalid.
12. V2 cleanup must remove or reject unmapped internal wall leftovers before candidate scoring and apply.

## KEEP
- Public user contract remains `program/style/size-or-shape/direction/seed`.
- `tools/world_edit_visual` stays reporting/acceptance only.
- PNG/sprite output is review evidence only; semantic report and expectations are source of truth.
- Existing `place_fixture_at()` remains the emission layer.

## Acceptance
- `building_living_target_rooms_6` passes without config `use_layout_v2`.
- Living matrix still covers N/S/E/W, compact/standard/spacious, rectangle, and undersized negative case.
- Existing storage/workshop smoke remains safe on legacy path unless explicitly v2-gated.
- Required focused checks when practical:
  - `git diff --check`
  - `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`
  - focused visual workflow for living target/matrix and non-living smoke.

## Residual Risk
- Wall topology is now hard-validated and cleaned in v2, but the latest sprite review still shows a dry/under-composed visual style in some rooms. That remaining issue belongs to the next scene-density/composition pass, not to wall/shell mapping.
