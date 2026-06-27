# DECISIONS - PR99 Building Layout Generator Rewrite

## D-001: Execute documented PR99 rewrite contract
- Decision: Treat `PR99_TOTAL_REWORK_SPEC.md` and `PR99_CODEX_EXECUTION_PLAN.md` as the approved task contract.
- Why: User asked to proceed with subagents on the building generator rewrite.

## D-002: Generator-first orchestration
- Decision: Start with cleanup, typed domain, shape contract/defaults, candidate search, then proceed into solver/furnishing/apply/acceptance/TGUI slices.
- Why: Full PR99 includes blueprints/UI/acceptance, but the generator rewrite is the core dependency.

## D-003: Subagents used for challenge and disjoint implementation
- Decision: Use subagents for read-only challenge and independent cleanup/domain implementation slices with disjoint write scopes.
- Why: PR99 plan requests subagents and rewrite scope requires plan-mapping challenge.

## D-004: Keep task-state at orchestration level
- Decision: Restore these task-state files to the main PR99 contract after worker-local task-state overwrote them.
- Why: Worker-local contracts are useful evidence, but the active agent needs a single cross-slice contract.

## D-005: Candidate search improvement before full solver replacement
- Decision: Use existing `RECT/L/T/U` footprint builders in bounded point candidate search and remove first-valid break as an interim PR99-B05 step.
- Why: This is diff-level progress toward the approved solver contract and does not approve keeping old room-first as final production core.

## D-006: Switch production geometry stage to semantic-region solver
- Decision: Stop forcing `room_first_layout` in state init and route the production geometry stage through semantic region solving, primary-route reservation, zone dividers, nested rooms, and solved-room reconstruction.
- Why: The old room-first solver cannot remain the production authority for PR99; existing typed/region helpers are the nearest in-repo path to the documented solver pipeline.

## D-007: Make building apply transactional
- Decision: Stamp preview plans with a target-state hash, reject stale target areas, rollback any runtime or post-apply validation failure through the local changeset, and suppress manager history for rolled-back failed transactions.
- Why: PR99 forbids warning-success partial buildings and history entries for failed transactions.

## D-008: Gate required furnishing by functional capability providers
- Decision: Resolve style interiors through a provider registry with declared capabilities, reject incompatible required program/style combinations with `style.missing_capability`, and grant required semantic/signature credit only from provider-backed placements.
- Why: PR99 forbids decorative or visually similar objects from satisfying required building functions.

## D-009: Expose building capabilities through generator-specific UI payload
- Decision: Add a base generator `get_ui_payload()` hook and pass a `generator_payload` object through the World Edit manager UI payload; `building_layout` now emits a server-side capability matrix keyed by program/style.
- Why: TGUI and acceptance surfaces need a canonical server contract for supported/locked program-style combinations instead of reconstructing furnishing compatibility client-side.

## D-010: Gate building layout TGUI actions from server capability matrix
- Decision: Keep `building_layout` in the generic World Edit workspace, but add a typed TGUI view-model helper that reads the server matrix, decorates program/style options, shows the current incompatibility card, and disables preview/start/apply for unsupported rows.
- Why: This keeps compatibility authority on the server payload while making the client state visible and preventing unsafe apply entrypoints.

## D-011: Make acceptance reports authoritative before replacing the full runner
- Decision: Remove the old Workbench enable/poll startup markers, add a guarded `UNIT_TESTS + world.params["world_edit_acceptance"]` one-shot entrypoint, and make visual reports emit `passed`, `hard_error_count`, and expectation diffs; Python workflow now passes DreamDaemon `-params` and treats report mismatch as aggregate failure.
- Why: This converts existing `expect` data from inert metadata into a machine gate without restoring the production startup poller.

## D-012: Current continuation targets anti-shedding and purpose-aware furnishing
- Decision: Continue PR99 through a focused generator slice: hidden compact/micro program shedding must stop being a supported production success path, and large rooms should receive bounded program/style-aware optional furnishings after mandatory fixtures.
- Why: The user's current acceptance concern is not visualizer rendering; it is production generation of arbitrary-size buildings with furniture that follows room purpose without empty or chaotic rooms.

## D-013: Room-count request is bounded physical-divider best-effort
- Decision: Add `target_room_count` as a bounded request knob (0..24) that attempts same-zone physical divider plans before component-based solved-room reconstruction; exact satisfaction is reported with `room_count_satisfied` and `room_count_gap` instead of being silently claimed.
- Why: Available footprint and semantic furniture requirements can make arbitrary exact room counts impossible; PR99 forbids metadata-only splitting, so each added room-count gain must come from real wall/opening geometry.

## D-014: Route blockers use dense object semantics
- Decision: Treat reserved/door-cone post-emit and validation blockers as dense object blockers. Non-dense semantic furniture can remain on reserved tiles, while dense furniture still blocks, is removed during repair, and fails validation if emitted on a route.
- Why: BYOND objects such as beds/chairs used by living semantic patterns may be non-dense; counting every interior placement as a route blocker produced false post-emit failures and mandatory pattern loss after cleanup.

## D-015: Broaden acceptance through production report metrics
- Decision: Add report-level room/furnishing metrics and multi-program Visual cases before claiming broader arbitrary-size/room progress.
- Why: A single `living|colony` target-room case does not prove the user's requested end state. Visual Workbench can remain read-only while its reports expose production `room_count`, `target_room_count`, room-count satisfaction, and generated object counts for acceptance assertions.

## D-016: Move exterior entry ownership into semantic opening solve
- Decision: Stop calling `build_building_doors()` from `stage_geometry` before semantic layout. This slice introduces an opening-solver step inside the semantic layout flow so exterior entry selection is part of topology/route/opening generation evidence.
- Why: The approved contract says doors are generator responsibility but must be derived after topology/route constraints, not selected by a boundary pre-pass and repaired later.

## D-017: Remove legacy room-first callable entrypoints before helper cleanup
- Decision: Delete the dead top-level `build_building_room_first_layout()` and `build_building_micro_layout()` procs after proving they have no external callsites. Leave lower-level `room_first_*` utility/helper cleanup for a separate bounded pass because `get_room_first_region_specs_for_zone()` is still used by emitter reporting.
- Why: M1 forbids the old monolithic solver remaining callable as a fallback. Removing the callable entrypoints improves fidelity without a risky broad delete of helper code that still shares reporting logic.

## D-018: Keep solver knobs internal, not public UI contract
- Decision: Restrict `building_layout` public server UI fields to program, style, seed, and a coarse size profile. Existing detailed params such as explicit half sizes, target room count, blocker overrides, detail/window budgets, and service/back exits remain accepted for regression cases and internal callers but are not advertised as user-facing controls.
- Why: The current user contract says users provide only program/style/size-or-shape/direction/seed; doors, rooms, routes, furniture, infrastructure, and validation are generator responsibilities.

## D-019: Bridge support reports through validation verdict payloads
- Decision: Keep the existing support report list keys for current UI/Workbench compatibility, but make `world_edit_validation_verdict` the source payload embedded in each support/preflight report and preserved in plan metadata.
- Why: M4 requires one feasibility/verdict contract across support, preview, tests, Workbench, and UI. Replacing every consumer in one pass is too broad; embedding the typed verdict first removes the ad-hoc status gap without breaking existing consumers.

## D-020: Make generated-plan verdict authoritative for supported semantic reports
- Decision: For successfully generated previews, emit a generation/hard-validation verdict payload from candidate validation into candidate reports and plan metadata, and make Workbench supported `report.json` use that payload as top-level `validation_verdict`. Preserve support/preflight verdict separately as `support_validation_verdict`.
- Why: A supported preflight only proves the request was allowed. The semantic report source of truth must also prove that the bounded candidate search, partition, routes/openings, furnishing, and hard validation produced a valid plan.

## D-021: Preserve generation verdict while adding apply and undo phase verdicts
- Decision: Add `apply_validation_verdict` and `undo_validation_verdict` as phase payloads instead of replacing the supported report's top-level generation `validation_verdict`.
- Why: The report must prove generation, apply, and undo independently. Replacing the top-level generation verdict with `applied` would hide candidate hard-validation evidence; leaving apply/undo as booleans would keep M4 partial.

## D-022: Reuse production candidate solve as feasibility dry solve
- Decision: Add a bounded dry-solve probe to support/preflight that reuses `build_building_layout_candidate_state()` with an internal recursion guard, records candidate attempts, and only reports `supported` when at least one hard-valid in-memory candidate exists.
- Why: The PR99 contract forbids area-only feasibility. Reusing the production candidate path preserves parity with generation better than adding a parallel estimator, while the guard prevents `resolve_shape_footprint()` support re-entry from recursing.

## D-023: Prove same-seed determinism with production preview replay
- Decision: Add an opt-in Visual Workbench semantic report check that runs the same production preview twice before apply and compares `layout_hash` plus component hashes; `building_living_target_rooms_6` will require the boolean expectation.
- Why: The PR99 hard-pass explicitly requires same seed -> same layout hash. A single green preview/apply or stable PNG is not enough evidence, and the visualizer must stay a read-only reporter rather than manufacturing deterministic output.

## D-024: Gate mandatory regression on production hard-pass counters
- Decision: Extend generator validation/reporting and Workbench metric export so `building_living_target_rooms_6` asserts the remaining hard-pass topology counters from semantic report data, including a new production `door_corner_count`.
- Why: The required regression is only authoritative if the JSON report proves topology/route/opening constraints directly. PNG review and a single `valid_plan` verdict are not granular enough to prove every hard-pass item.

## D-025: Enforce preview target-state hash at apply time
- Decision: Treat `plan.metadata["target_state_hash"]` as a production apply precondition, not diagnostics. If the live target hash differs from the preview hash, `apply_plan()` must return a typed `world_conflict` before mutation and suppress history.
- Why: PR99 atomic apply requires stale preview/live world drift to be blocked. Runtime blocker checks and request-key checks do not cover all live target changes and cannot substitute for the preview target hash contract.

## Pending Decisions
- None yet. Any deviation from the PR99 rewrite contract must be recorded here before implementation proceeds.
