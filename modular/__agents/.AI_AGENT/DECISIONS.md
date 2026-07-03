# DECISIONS - PR99 Semantic Interiors Production Layer

## D-001: Build a semantic interiors layer over the existing emitter
- Decision: Add room-field, scene-rule, scene-solver, emitter, and validation datums under `building_layout/semantic/**`.
- Why: The attached plan identifies `place_fixture_at()` as the correct emission contract; rewriting object emission would add risk without addressing scene selection.

## D-002: Replace `stage_interiors`, do not patch the visualizer
- Decision: Wire semantic interiors into the production DM pipeline through `stage_interiors`.
- Why: `tools/world_edit_visual/**` is review/acceptance only and must not repair generation.

## D-003: Keep legacy cluster fixtures as fallback/detail
- Decision: `stage_fixtures` may still place existing semantic-plan clusters when semantic interiors did not provide primary scenes, but must skip primary major scatter when semantic interiors succeeded.
- Why: The approved path forbids `place_building_room_purpose_fill()` as primary success, but a safe compatibility fallback is still needed for programs not yet covered by scene rules.

## D-004: V2 living scene emission stays on one path but is hardened
- Decision: Do not duplicate v2 living scene emission inside the new legacy semantic interiors stage; keep the current v2 scene path and harden its member-density, side-surface, and shared semantic validation/reporting.
- Why: Living v2 already emits scene metadata through `place_fixture_at()`. Duplicating emitters would create double placement, while the visual blocker can be addressed through stricter scene contracts and shared hard counters.

## D-005: Threshold expectations belong in DM workbench reports
- Decision: Add max/min semantic expectation aliases in `world_edit_visual_report.dm`.
- Why: Reports are generated in the DM visual workbench; Python scripts only orchestrate/render artifacts.

## D-006: Storage/workshop are safety smoke, not new solver rollout
- Decision: The first slice can expose semantic counters for all programs, but storage/workshop data-pack solver work remains a later stage.
- Why: The user explicitly asked to reuse the same solver after living visual pass, not to mix data-pack rollout with living cleanup.
