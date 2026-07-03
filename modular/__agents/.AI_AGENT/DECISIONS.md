# DECISIONS - PR99 Structured Scene And Wall Topology Hardening

## D-001: Use one structured-scene ownership contract
- Decision: Add shared fixture-state fields for structured scene ownership and use them for both living v2 and semantic interiors.
- Why: The review rejects private `semantic_interiors_emitted` gating because v2 scene emission can still allow old fixture/fallback behavior to pass unnoticed.

## D-002: Stage success follows semantic validity
- Decision: `stage_interiors` must reserve door cones, run semantic interiors, report the `interiors` stage, and return false when required/primary semantic scene counters are nonzero.
- Why: A stage that always returns success makes missing identity scenes invisible to the pipeline.

## D-003: Legacy fixtures after structured scenes are a hard failure
- Decision: Track `legacy_fixture_after_scene_count` and include it in hard counters, verdict/report metrics, and expectations.
- Why: The current bad screenshots can be visually improved by stray old fixtures while still violating the solver contract.

## D-004: Multi-scene is phase-based
- Decision: Emit at most one accepted rule per phase per room, ordered `primary`, `secondary`, `detail`, with required primary scene identity first.
- Why: The review wants layered scenes, not scatter. Phase limits keep output bounded and deterministic.

## D-005: Room classes are explicit contracts
- Decision: Introduce `resolve_building_semantic_room_class(state, room)` and build scene rules from the class.
- Why: Loose string matching makes beds/tables/storage appear in wrong contexts and weakens validation.

## D-006: Footprint-aware members extend the model, not the emitter
- Decision: Add member footprint/relative placement fields to semantic specs and continue emitting through `place_fixture_at()`.
- Why: The emitter already owns object placement metadata; rule grammar should decide where grouped members belong.

## D-007: Visual review tightens semantic gates
- Decision: Update focused expectations to zero legacy-after-scene, coverage >= 90, route clearance 100, and noise <= 10.
- Why: PNG/sprite artifacts are review output only; semantic counters must be the pass/fail surface.

## D-008: Wall topology is a hard solver contract
- Decision: Add explicit hard counters for walls outside the footprint and orphan internal wall islands, expose them in reports, and expect zero in focused living cases.
- Why: The latest visual review shows wall chunks that are disconnected from shell, isolated, or visually outside mapping. These cannot remain PNG-only review notes.

## D-009: V2 must clean leftover wall derivation
- Decision: Keep v2 wall derivation deterministic, but remove/reject isolated leftover internal wall cells after floor/door/window emission.
- Why: Treating every non-floor footprint cell as a wall hides allocation/mapping mistakes and creates shell artifacts that validators currently miss.

## D-010: Living cabinet budget follows scene grammar
- Decision: Raise living `cabinet` object budget from 3 to 4.
- Why: Large common side-surface scenes and bedroom storage can legitimately need four cabinet-category placements. The previous budget made the rectangle regression fail during v2 scene emission despite valid room/scene contracts.

## D-011: Wall mapping beats shell connectivity
- Decision: Add a separate hard counter for internal wall tiles that are connected to the shell but not adjacent to any mapped room/route floor or opening.
- Why: Component connectivity alone is too weak. A bad leftover wall spur can touch the shell and still be visually isolated or outside-looking.
