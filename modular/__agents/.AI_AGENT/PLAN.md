# PLAN - PR99 Semantic Interiors Production Layer

Status: COMPLETE
Date: 2026-07-03

## Goal
Replace the placeholder `building_layout` interiors stage and scatter-style room filling with a deterministic semantic scene layer:

room fields -> semantic anchors -> scene candidates -> scene scoring -> scene selection -> scene member placement -> existing `place_fixture_at()` emitter -> semantic validation/reporting.

The public generator contract remains narrow: program, style, size-or-shape, direction, and seed. Rooms, routes, doors, furniture, infrastructure, validation, reports, and scoring are generator responsibilities.

## Source Documents
- Current user request: attached `e1414e02.../pasted-text.txt`.
- Active review doc: `modular/world_edit/docs/rework_docs/tech_rework/03.07.26_review.md`.
- Prior hard review context: `modular/world_edit/docs/rework_docs/tech_rework/30.06.26_review_2.md`.
- Production code under `modular/world_edit/code/generators/building_layout/**`.

## Scope
- Production DM generator code in `modular/world_edit/code/generators/building_layout/**`.
- New semantic interior layer under `modular/world_edit/code/generators/building_layout/semantic/**`.
- Pipeline integration through `pipeline/stages/stage_interiors.dm` and minimal coordination with `stage_fixtures.dm`.
- Hard validation/report metrics and visual expectation aliases.
- Focused visual cases in `tools/world_edit_visual/cases/**` as acceptance/report contracts only.

## Non-Scope
- No visualizer-side generation or PNG/sprite-driven acceptance.
- No random module/recipe expansion as a substitute for scene solving.
- No rewrite of `place_fixture_at()` or object provider catalog unless the emitter contract is proven insufficient.
- No full SAT solver in this slice.
- No storage/workshop v2 data-pack rollout before the semantic scene layer is stable; storage/workshop can be smoke/expectation coverage only.

## MUST
1. `stage_interiors` must no longer be a placeholder that selects prefab macro ids and then `continue`s.
2. Primary major furniture must come from scene selection with room identity, primary/secondary/detail layers, route/door clearance checks, and global scene limits.
3. `place_building_room_purpose_fill()` must remain detail/secondary fallback only; it must not be the primary semantic scene source.
4. Scene emission must use the existing `place_fixture_at()` metadata contract.
5. Semantic report/counters are the source of truth; PNG/sprite output remains review artifact only.
6. Current noisy screenshots must fail counters or be replaced by solver output that satisfies semantic expectations.

## Expected New Path
1. Build room fields for every solved room: floor, wall band, corners, center, free turfs, door buffers, route edges, service wall candidates, focus turf.
2. Build scene rules from program/room role and select required room identities first.
3. Score scene candidates by fit, clearance, wall availability, route separation, and role identity.
4. Emit selected scene members through `place_fixture_at()` with stable scene/module metadata.
5. Run hard semantic validation for route blocks, door clearance, missing required scenes, missing primary room scenes, major objects without scenes, pairing errors, distribution noise, functional coverage, and route clearance.
6. Expose hard counters and expectation aliases in workbench reports.

## Forbidden Old Paths
- `place_room_prefab_groups()` must not remain production primary interior placement.
- `place_building_room_purpose_fill()` must not create primary room identity success.
- `tools/world_edit_visual/**` must not generate, repair, or simulate layouts.
- Metadata-only success is forbidden when scene identity, route clearance, pairing, or room function is not satisfied.
- Do not broaden this into storage/workshop solver data packs until the semantic layer is green for living.

## Acceptance
- `building_living_target_rooms_6` remains mandatory and passes without config `use_layout_v2`.
- Reports expose and expectations can check:
  - `semantic_scene_route_block_count`
  - `semantic_scene_door_clearance_block_count`
  - `semantic_scene_required_missing_count`
  - `semantic_room_primary_scene_missing_count`
  - `semantic_major_object_without_scene_count`
  - `semantic_pairing_error_count`
  - `semantic_distribution_noise_score`
  - `semantic_functional_coverage_percent`
  - `semantic_route_clearance_percent`
- Expectation aliases support `*_max` and `*_min` threshold checks.
- Current supported living cases retain zero hard counters.
- Storage/workshop existing cases stay production safe; if their current visual noise is asserted, it must be via semantic report expectations, not PNG-only judgment.
- Required checks when practical:
  - `git diff --check`
  - `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`
  - focused visual workflow for living target/matrix and non-living smoke.
