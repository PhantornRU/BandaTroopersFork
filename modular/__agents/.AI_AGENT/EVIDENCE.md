# EVIDENCE - Graph-first Building Layout Solver

## Read-only discovery 2026-07-11

- Approved contract: `modular/world_edit/docs/rework_docs/tech_rework/11.07.26_review.md` (1331 lines, read completely).
- Dirty baseline contains only the untracked approved review document; it is preserved.
- Include path remains `colonialmarines.dme -> modular/modular.dme -> modular/world_edit/_world_edit.dme` and includes one canonical solver.
- Production entrypoint is `build_building_layout_candidate_state() -> solve_building_layout() -> emit_building_layout_plan()`.
- `allocate_building_layout_rooms()` calls `solve_building_layout_route_from_region()` before placing rooms.
- Program contracts allow only `adaptive_axis` and `adaptive_cross_axis`; both call `build_building_layout_axis_region_candidate()`.
- Semantic `connection_contracts` are compiled but have no production consumer; region generation connects every room directly to `route`.
- Repeated instances are explicitly excluded from required cluster ownership by `instance_index > 1` checks.
- Curated placement modules already expose `occupied_offsets`, `clearance_offsets`, `member_specs`, caps and atomic commit primitives; canonical scene solving does not use them as its composition source.
- Candidate selection stops after two hard-valid allocation variants, not two distinct topology families.
- Wall materialization prunes unmapped/spur walls during successful emission; cleanup counts are not hard failures.
- Visual case expectations for the four reproduced layouts assert basic support/emission, not functional count, composition, cleanup, canyon or family diversity.
- AI index is unavailable; targeted `rg` and bounded direct reads are the discovery path.

## BYOND/DM bounded-loop audit

- Route BFS has the existing `WORLD_EDIT_BUILDING_MAX_ROUTE_EXPANSIONS` cap and consumes `open` with `Cut(1, 2)`.
- Candidate selection consumes `remaining` by index with `Cut`; no nested-list subtraction bug found in the active selection loop.
- Room ordering consumes `pending` by best index with `Cut`.
- Current dimension enumeration scans `1..free_w` and `1..free_h`, then positions; review replacement must use bounded dimension variants and the approved beam/expansion caps.

## Self plan-mapping challenge

Status: PASS WITH RISKS

- PASS: all required behavior can replace internals of the current canonical solver without public API or include-path changes.
- PASS: archetype zone/adjacency/nested/cluster data and the curated module catalog provide the declarative sources required by the review.
- PASS: trial emission already provides a place to enforce graph/composition/wall hard gates before selection.
- RISK: functional-only targets increase required footprint and will make some previously supported fixed sizes explicit `program.target_room_count_unreachable`; this is required behavior, not fallback permission.
- RISK: graph-first allocation expands search. Mitigation is the mandated beam width, dimension variants and topology/route/module caps.
- RISK: Stage A intentionally makes current cases red. Acceptance may return green only after stages B-F, never by weakening expectations.
- RISK: direct wall materialization overlaps existing emitter validation. Mitigation is to retain emitter primitives but remove cleanup ownership from successful candidates.

## Plan fidelity matrix

| ID | Type | Requirement | Evidence | Status |
| --- | --- | --- | --- | --- |
| M1-M2 | MUST | Refresh contract and map current production paths. | Sections above; include/callsite/loop audits. | DONE |
| M3-M12 | MUST | Hard gates, functional graph, families, graph-first allocation, atomic modules, direct walls and reporting. | Solver and visual matrix complete. | DONE |
| K1 | KEEP | Preserve one solver and public/runtime contracts. | Compile and visual preview/apply/undo verified. | VERIFIED |
| R1 | REJECT | No alternate solver/fallback/recipe/expectation weakening. | Legacy audit returned no hits. | VERIFIED |
| C1-C3 | CHECK | Runtime/matrix/determinism verification. | Focused cases, all-program matrix and 60-sample seed matrix verified. | VERIFIED |
| C4 | CHECK | Build/full tests/old-path/diff verification. | Compile/focused checks/audit verified; full suite external failures recorded. | PARTIAL |

## Seed-matrix extension discovery 2026-07-14

- The only explicit C3 residual is the 10-seed axis; direction, size-profile and replay checks are already verified in the focused living/representative batches.
- The six committed target-room cases are the source contracts for `living`, `workshop`, `storage`, `office`, `hydroponics` and `dormitory`.
- `render_workflow.py --case-path` accepts temporary JSON inputs and performs ordinary batch preview/apply/undo plus report acceptance; `same_seed_layout_hash` activates the DM-side replay path.
- The report expectation layer supports exact counters and generic `_min`/`_max` gates, so the matrix can strengthen shared acceptance without adding generator logic.
- Self challenge: a 6 x 10 standard-profile seed matrix closes the recorded residual. A 6 x 10 x 4 x 3 Cartesian run would repeat already verified direction/size axes, add 720 expensive renders, and provide no distinct contract evidence for this follow-up.

## Seed-matrix verification 2026-07-14

- Command: `py -3 tools/world_edit_visual/scripts/run_building_layout_seed_matrix.py`, followed by `--resume-passed` after reducing the calibrated shard size from five to three for the slower office rectangle footprint.
- Aggregate: `tools/world_edit_visual/out/building_layout_seed_matrix_summary.json` (`world_edit_building_layout_seed_matrix/v1`), 60 samples, 60 passed, 0 failed.
- Per program: living/workshop/storage/office/hydroponics/dormitory each pass 10/10; same-seed replay matches 10/10 for every program.
- Every sample has `layout_distinct_hard_valid_family_count >= 2`, semantic functional coverage 100%, semantic route clearance 100%, exact functional room count and zero canonical adjacency/composition/capacity/underfill/wall/canyon/metric-mismatch counters.
- Structural hash diagnostic: living/workshop/storage/hydroponics/dormitory each selected one structural layout hash across the ten seeds; office selected two. This is recorded for later scoring diversity calibration and is not a failed requirement of the active review.

## Final extension checks 2026-07-14

- `BUILD.cmd --ci dm -DUNIT_TESTS`: 0 errors, 0 warnings.
- `py -3 -m py_compile tools/world_edit_visual/scripts/run_building_layout_seed_matrix.py`: passed.
- Aggregate integrity assertion: schema `world_edit_building_layout_seed_matrix/v1`, 60 results, 60 passed, 0 failed, all replay matches and no expectation diffs.
- Old-path audit over production/tests/cases: `NO_LEGACY_HITS` for V1/V2 aliases, old stage type and `switch(scene_contract.id)`.
- `git diff --check`: exit 0; only existing CRLF-to-LF normalization warnings on three dirty DM files.
- No DreamDaemon or World Edit Visual Python runtime processes remain after the matrix.

## Seeded family-selection discovery 2026-07-16

- `select_hard_valid_building_layout_candidate()` orders structural candidates by score, runs scene/trial validation progressively, stops once the minimum hard-valid count and family count are met, and always retains the highest score encountered.
- The final comparison contains no `root_seed`, `effective_seed`, PRNG or stable seed rank. Identical structural winners across seeds are therefore expected, not a hash/report defect.
- Candidate generation already supplies declarative topology families and stable candidate ids; the active matrix reports at least two hard-valid families for every standard sample.
- `candidate.score` combines preferred room area, route/opening cost, partition quality and scene composition. It must remain an unmodified quality signal; seeded selection belongs after hard validity and best-per-family collapse.
- Plan-mapping challenge: PASS. The change stays inside the canonical solver selection proc, adds no search expansion, no program switch and no visualizer generation. Main risk is admitting a visibly weaker family; the bounded 10% / 50..250 quality floor and unchanged hard gates contain it.

## Seeded family-selection verification 2026-07-16

- `select_seeded_building_layout_family_winner()` collapses the hard-valid shortlist to the best candidate per topology family, applies the 10% quality band clamped to 50..250 points, then uses a stage-seeded PRNG over stable `family|candidate.id` keys.
- Candidate scores and hard validation are unchanged. Report metadata exports the best score, family winner scores, quality margin/floor, eligible family count, selection key/index and selected score gap.
- Focused unit `/datum/unit_test/world_edit_building_layout/seeded_family_selection_preserves_quality_tier` completed with status 0. The temporary `focus` marker was removed and the normal test DMB was rebuilt.
- An attempted full repository unit run entered unrelated long-running coverage and stopped making CPU/log/JSON progress; it was terminated without being counted as a completed check. Existing full-suite external HALO/config/create-destroy failures remain unchanged.
- `BUILD.cmd --ci dm -DUNIT_TESTS`: 0 errors, 0 warnings after restoring the ordinary unit-test set.
- Fresh command `py -3 tools/world_edit_visual/scripts/run_building_layout_seed_matrix.py`: 20/20 shards completed; aggregate 60 passed, 0 failed, all same-seed replay hashes match and aggregate hard invariant failures = 0.
- Structural hashes: living 2, workshop 2, storage 2, office 4, dormitory 2. Each exposes exactly two quality-admissible family winners across the matrix.
- Hydroponics remains on one structural hash because `axial_fallback=2202` and `split_wing=1854`; the 348-point gap exceeds its 220-point quality margin. No quality threshold was weakened.
- Maximum selected score gaps: living 77, workshop 46, storage 21, office 88, dormitory 16, hydroponics 0.
- `py -3 -m py_compile tools/world_edit_visual/scripts/run_building_layout_seed_matrix.py`: passed.
- Final old-path audit over production/tests/cases returned `NO_LEGACY_HITS` for V1/V2 aliases, the removed stage type and `switch(scene_contract.id)`.
- Final `git diff --check`: exit 0; only the pre-existing CRLF normalization warnings remain. No DreamDaemon or seed-matrix Python process remains.

## Post-selection closeout discovery 2026-07-17

- Active implementation contract remains `11.07.26_review.md`; no newer product plan or worktree replacement was found.
- Dirty worktree matches the existing approved solver rewrite and is preserved.
- The six-program 60-seed matrix is complete, but the seeded selection change has not yet been followed by one fresh representative ordinary-workflow case for each of all 15 public programs.
- The only partial active checklist item is C4. The last full unit attempt was correctly left uncounted after progress, CPU and output JSON stopped; the completed focused seeded-family unit remains valid.
- AI index remains unavailable. Targeted case discovery identifies exactly one representative/target case for living, workshop, storage, checkpoint, medbay, hydroponics, kitchen, dormitory, office, security, chapel, ritual chamber, compound colony, engineering and laboratory.

## Post-selection closeout verification 2026-07-17

- The first all-15 ordinary workflow used the default short timeout and produced 3/15 exports; the 12 missing cases had no report/expectation result and were not counted as product failures.
- The same 15-case batch rerun with `--timeout-seconds 1200` completed `semantic export: 15/15`, `rendered=15`, `failures=0` in one ordinary managed DreamDaemon run.
- Every report has exact functional room count, `hard_error_count=0`, semantic functional coverage 100%, semantic route clearance 100% and zero expectation differences.
- Temporary START/END diagnostics in `RunUnitTest()` proved the previous apparent stall was intentional/expensive runner behavior: `/datum/unit_test/spawn_humans` sleeps 60 seconds, direction/preview integration tests are CPU-heavy, and inter-test cleanup can be as long as the preceding test.
- The full repository unit execution completed and wrote fresh `data/unit_tests.json`: 71 total tests, 3 failures, 28 Building Layout tests, 0 Building Layout failures. The seeded family test has status 0.
- The three full-suite failures are outside this task: `/datum/unit_test/halo_preset_coverage` (missing HALO icon states), `/datum/unit_test/check_runtimes` (`configuration.dm:270` bad index) and `/datum/unit_test/create_and_destroy` (hard-deleted visual canvas landmark).
- All temporary unit-run instrumentation was removed; `git diff --exit-code -- code/modules/unit_tests/unit_test.dm` passed.
- Final ordinary `BUILD.cmd --ci dm -DUNIT_TESTS` after removal: 0 errors, 0 warnings.
- Closeout assertions: all 15 representative reports satisfy exact room count, zero hard errors/diffs and 100% coverage/clearance; the existing 60-seed aggregate remains 60 passed, 0 failed.
- Closeout audits: Python compile passed, `NO_LEGACY_HITS`, `NO_TEMP_UNIT_MARKERS`, active review encoding check passed, `git diff --check` exit 0 and no DreamDaemon/visual Python process remains.

## Canvas-origin lifecycle discovery 2026-07-17

- `world_edit_visual_canvas_origin/New()` unconditionally assigns `GLOB.world_edit_visual_canvas_origin = src` and defines no `Destroy()` cleanup.
- The compiled canvas map already contains the canonical landmark. `create_and_destroy` then constructs another instance at the unit-test turf, overwrites the global, force-qdel's it and reports a hard delete because the global still retains it.
- `clear_canvas()` intentionally preserves the origin and `acquire_test_z()` consumes the registered global; therefore the canonical map instance must remain stable when duplicates appear.
- Existing repository singleton patterns guard initial assignment and clear the global only when it still points to the object being destroyed.
- Plan-mapping challenge: PASS. The two-proc lifecycle fix is inside the owning modular type, changes no generator/public contract and directly removes the GC root. Ignoring the type in the unit test is forbidden because it would mask the defect.

## Canvas-origin lifecycle focused verification 2026-07-17

- `New()` now preserves an existing live compiled-map origin; `Destroy()` clears the global only when it points to the object being destroyed.
- Added `visual_canvas_origin_lifecycle`: duplicate construction/deletion preserves the canonical origin, while a temporary owner registers and clears itself.
- One focused run completed both lifecycle and the unchanged stock `/datum/unit_test/create_and_destroy` with status 0. No ignore-list or GC assertion was changed.
- All temporary focus markers were removed and `git diff --exit-code -- code/modules/unit_tests/create_and_destroy.dm` passed.
- Ordinary `BUILD.cmd --ci dm -DUNIT_TESTS`: 0 errors, 0 warnings. A normal living visual workflow completed semantic export 1/1, rendered 1, failures 0, hard errors 0 and expectation differences 0.

## Canvas-origin lifecycle full verification 2026-07-17

- A second full ordinary unit run completed without focus or diagnostic runner changes and wrote a fresh JSON with 72 tests.
- All 29 `/datum/unit_test/world_edit_building_layout*` tests pass. `visual_canvas_origin_lifecycle=0` and the unchanged stock `create_and_destroy=0`.
- Full-suite failures dropped from three to two: only `/datum/unit_test/halo_preset_coverage` and `/datum/unit_test/check_runtimes` remain. The World Edit canvas landmark no longer appears in GC failures.
- Final audits: stock `create_and_destroy.dm` unchanged, no focus/temp markers or ignore workaround, visual acceptance passed, Python/diff/legacy/encoding checks passed and no DreamDaemon/visual Python process remains.
