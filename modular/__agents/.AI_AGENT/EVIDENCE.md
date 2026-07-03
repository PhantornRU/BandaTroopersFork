# EVIDENCE - PR99 Structured Scene And Wall Topology Hardening

## Read-Only Discovery

Date: 2026-07-03

- Active hard-review contract is `03.07.26_review_2.md`; it says the newest visual output is better but still unacceptable and prioritizes ownership/gating, multi-scene grammar, room class mapping, footprint-aware placement, and hard counters.
- Attached verdict `ef96aa77.../pasted-text.txt` matches the active review direction.
- Current task-state was stale: `PLAN.md` was `Status: COMPLETE` for the previous semantic layer slice.
- AI index is absent; discovery used targeted `rg` and file reads.
- `pipeline/stages/stage_interiors.dm` currently calls `generator.run_building_semantic_interiors(context.state)` and unconditionally returns `TRUE`.
- `pipeline/stages/stage_fixtures.dm` currently skips legacy fixture placement only when `context.state.fixtures.semantic_interiors_emitted` is true.
- `pipeline/world_edit_building_layout_fixture_state.dm` has semantic-specific ownership fields but no shared `structured_scene_*` owner fields.
- `semantic/building_layout_semantic_solver.dm` skips v2, loops rules per room, emits one rule, then `break`s, preventing primary+secondary+detail layering.
- `semantic/building_layout_semantic_rules.dm` uses `room_key` substring helper checks instead of an explicit room-class resolver.
- `semantic/building_layout_semantic_model.dm` has `placement_mode` but no member footprint offsets, allowed relative dirs, clearance offsets, forbidden anchor tags, or `relative`/`wall_run`/`center_ring` grammar.
- `v2/building_layout_v2_solver.dm` emits scene plans through `place_fixture_at()` and reports them, but does not mark a shared structured scene owner.
- Living visual cases currently use `semantic_functional_coverage_percent_min = 85` and do not expect `legacy_fixture_after_scene_count`.
- Latest user correction after sprite review: generated buildings still contain wall chunks that are not connected to walls, are isolated, or appear to go outside; wall placement still does not match mapping.
- `emit_building_v2_candidate_to_state()` derives walls by iterating every footprint turf not present in `floor_lookup` and adding it to `state.geometry.wall_lookup`, with non-boundary cells added to `internal_wall_turfs`.
- Existing wall validation checks double-thick segments and diagonal-only contacts, and v2 scene validation has a lenient orphan internal wall allowance. There is no explicit hard counter for outside-footprint walls or isolated internal wall islands.

## Plan Mapping Challenge

Status: PASS WITH RISKS

- PASS: Shared ownership can be added in fixture state and a generator proc without changing public request parameters.
- PASS: `stage_interiors` can report an `interiors` stage in addition to existing semantic reports, making stage-level validity visible.
- PASS: V2 living scene emission already has scene metadata and can mark structured ownership after successful scene plan placement.
- PASS: Legacy-after-scene can be counted from object placement metadata without changing the visualizer.
- PASS: Multi-phase semantic emission can be bounded by fixed phase order and one emitted rule per phase.
- RISK: Full scene library for every listed program is larger than one pass. Mitigation: implement generic room-class/rule grammar now, keep new data-pack rollout out of scope.
- RISK: V2 and semantic paths use different scene emitters. Mitigation: unify ownership and validation counters while leaving emission mechanics in their existing production files.

## Subagents

- `Hypatia`: completed read-only audit. Findings used: add generic `_min/_max` actual-value lookup, add `legacy_fixture_after_scene_count`, structured scene expectations, and keep v2 multi-scene as a remaining larger design concern.
- `Herschel`: completed read-only audit. Findings used: explicit room-class resolver, validation resolver reuse, phase-based rules, constants for placement modes, and `add_relative_member()` for dining groups.

## Implementation Evidence

- `stage_interiors.dm` now reserves immediate door cones, calls semantic interiors, writes an `interiors` report with structured scene fields and semantic missing counters, and returns the semantic result.
- `world_edit_building_layout_fixture_state.dm` now tracks `structured_scene_emitted`, `structured_scene_owner`, `structured_scene_count`, `structured_primary_scene_count`, and `legacy_fixture_after_scene_count`.
- `mark_building_structured_scene_emission(state, owner)` marks shared ownership. Semantic interiors use owner `semantic`; living v2 emission uses owner `layout_v2`.
- `stage_fixtures.dm` skips legacy fixture placement whenever structured scenes are emitted and reports structured ownership plus legacy-after-scene count.
- `legacy_fixture_after_scene_count` is a hard counter and is exposed through validation state, generation verdict metrics, report metadata, visual report metrics, and focused expectations.
- Semantic solver now emits by fixed phases `primary`, `secondary`, `detail` instead of breaking after the first emitted scene per room.
- Semantic rules now use `resolve_building_semantic_room_class(state, room)` and build rules from explicit room classes.
- Semantic member specs now carry `dx`, `dy`, `allowed_relative_dirs`, `clearance_offsets`, and `forbidden_anchor_tags`; solver supports `relative`, `wall_run`, and `center_ring` placement modes.
- Living case expectations now require `legacy_fixture_after_scene_count = 0`, `semantic_functional_coverage_percent_min = 90`, `structured_scene_count_min = 1`, and `structured_primary_scene_count_min = 1`.
- `world_edit_visual_report.dm` now resolves generic `*_min` and `*_max` expectation keys by stripping the suffix and reading the base metric.

## Wall Topology Addendum

Status: COMPLETE

- Plan mapping challenge: PASS. Wall topology can be hardened in production generator validation and v2 emission cleanup without visualizer-side repair or changing public request parameters.
- Old path audit: The current v2 leftover-to-wall derivation is deterministic but too permissive; it must be followed by topology cleanup/validation so leftover cells do not pass as valid walls.
- Added hard counters `wall_outside_footprint_count` and `wall_orphan_island_count`.
- V2 now prunes internal wall components disconnected from the shell after leftover wall derivation.
- `validate_building_wall_geometry_rules()` now fails walls outside footprint and internal wall islands disconnected from the boundary shell.
- Focused living expectations now require `wall_outside_footprint_count = 0` and `wall_orphan_island_count = 0`.
- Rectangle living regression was restored to `supported` by aligning living cabinet budget with the scene grammar (`cabinet = 4`) and keeping rectangle hard-valid candidate minimum at 1. `building_living_target_rooms_6` still proves 2 hard-valid v2 candidates.
- Evidence that current bad wall topology would fail: `building_living_rectangle_colony` rejected a non-selected candidate with `wall_orphan_island_count = 2`; selected candidate passed with both wall counters at zero.
- Focused visual report summary after changes:
  - `building_living_target_rooms_6`: passed=1, `layout_v2_hard_valid_candidate_count=2`, `structured_scene_owner=layout_v2`, `wall_outside_footprint_count=0`, `wall_orphan_island_count=0`, `legacy_fixture_after_scene_count=0`.
  - N/S/E/W living point cases: passed=1, wall topology counters zero.
  - compact/standard/spacious living size cases: passed=1, wall topology counters zero.
  - `building_living_rectangle_colony`: passed=1, status supported, wall topology counters zero.
  - `building_living_explicit_micro_1x1`: passed=1, status locked/no-solution as negative case.
  - `building_storage_target_rooms_5` and `building_workshop_target_rooms_6`: passed=1 on legacy path, wall topology counters zero.
- Sprite inspection:
  - `building_living_target_rooms_6` no longer shows obvious disconnected wall chunks or walls escaping the footprint; shell and central route are coherent.
  - `building_living_rectangle_colony` no longer locks and shows a connected shell/partition layout.
  - Residual visual risk: some rooms still feel sparse/dry. That should be handled by the next scene-density/composition pass, not by wall-mapping fixes.

## Verification After Wall Topology Addendum

- `git diff --check`: PASS. Only CRLF normalization warnings for existing files.
- `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`: PASS, `colonialmarines.dmb - 0 errors, 0 warnings`.
- `tools\build\build.bat dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`: PASS/up-to-date through repo build path.
- Focused visual workflow:
  - Command: `py tools\world_edit_visual\scripts\render_workflow.py --isolated --timeout-seconds 180 --poll-seconds 2 --case building_living_target_rooms_6 --case building_living_point_colony --case building_living_point_colony_east --case building_living_point_colony_south --case building_living_point_colony_west --case building_living_size_compact --case building_living_size_standard --case building_living_size_spacious --case building_living_rectangle_colony --case building_living_explicit_micro_1x1 --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6`
  - Result: rendered 12, workflow failures 0.

## Wall Mapping Addendum

Status: COMPLETE

- Latest user correction repeats that visible chunks are disconnected, isolated, or outside-looking, and that wall placement still does not match mapping.
- Read-only gap confirmed: previous `wall_orphan_island_count` caught disconnected components, but shell-connected or mapped-looking leftovers could still survive if individual wall tiles did not border room/route floor/opening correctly.
- Added mapped-wall hard counters `wall_unmapped_interior_count` and `wall_single_sided_internal_count` and exposed them through validation state, hard counters, visual report metrics, and focused living expectations.
- V2 now builds a candidate-level cleaned wall model before scene solving. Scene anchors can only use that cleaned wall model, and emission uses the same model instead of re-deriving all non-floor leftovers as walls.
- V2 wall cleanup removes unmapped internal wall leftovers, single-sided internal wall runs, and unmapped orphan components while preserving genuinely mapped room/route partitions.
- Locked/no-solution visual reports now keep support dry-solve diagnostics, so rejected v2 candidates expose stage reports and hard counters instead of reporting only `program.insufficient_footprint`.
- `building_living_rectangle_colony` proved the new counters were active: intermediate candidates were rejected with `wall_single_sided_internal_count`/`wall_orphan_island_count`, then selected `front_common_back_private` passed with all wall mapping counters at zero.
- Residual visual risk: `building_living_target_rooms_6` and rectangle outputs are semantically clean on wall mapping but still visually dry with large rooms/long route axes. That belongs to the next composition/room-proportion pass, not another wall-hotfix.

## Verification

- `git diff --check`: PASS. Only CRLF normalization warnings for existing files.
- `tools\build\build.bat --ci dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`: PASS, `colonialmarines.dmb - 0 errors, 0 warnings`.
- `tools\build\build.bat dm -DUNIT_TESTS -DCIBUILDING -DANSICOLORS -Werror`: PASS/up-to-date through repo build path.
- Focused visual workflow:
  - Command: `py tools\world_edit_visual\scripts\render_workflow.py --timeout-seconds 300 --poll-seconds 2 --case building_living_target_rooms_6 --case building_living_point_colony --case building_living_point_colony_south --case building_living_point_colony_east --case building_living_point_colony_west --case building_living_size_compact --case building_living_size_standard --case building_living_size_spacious --case building_living_rectangle_colony --case building_storage_target_rooms_5 --case building_workshop_target_rooms_6`
  - Result: rendered 11, workflow failures 0.
  - Extra rectangle direction command: `py tools\world_edit_visual\scripts\render_workflow.py --timeout-seconds 240 --poll-seconds 2 --case building_living_rectangle_colony_north --case building_living_rectangle_colony_south --case building_living_rectangle_colony_west`
  - Result: rendered 3, workflow failures 0.
- Report-source summary:
  - `building_living_target_rooms_6`: passed=1, status=supported, hard=0, `layout_v2_candidate_count=2`, `layout_v2_hard_valid_candidate_count=2`, wall mapping counters all 0.
  - Point living N/S/E/W: passed=1, status=supported, hard=0, `layout_v2_candidate_count=2`, `layout_v2_hard_valid_candidate_count=2`, wall mapping counters all 0.
  - Living compact/standard/spacious: passed=1, status=supported, hard=0; compact/standard have 1 hard-valid candidate, spacious has 2; wall mapping counters all 0.
  - `building_living_rectangle_colony`: passed=1, status=supported, hard=0, `layout_v2_candidate_count=3`, `layout_v2_hard_valid_candidate_count=2`, wall mapping counters all 0.
  - Rectangle north/south/west variants: passed=1, status=supported, hard=0, wall mapping counters all 0.
  - `building_storage_target_rooms_5` and `building_workshop_target_rooms_6`: passed=1, status=supported, hard=0, `layout_v2_enabled=0`, wall mapping counters all 0.
