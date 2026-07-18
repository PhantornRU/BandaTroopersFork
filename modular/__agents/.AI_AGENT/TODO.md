# TODO - Canonical Building Layout Solver rewrite

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| M1 | MUST | Preserve baseline and replace stale task-state with the `17.07.06_review.md` contract. | DONE |
| M2 | MUST | Map canonical entrypoint, include graph, data flow, masking paths, legacy callsites and report mismatch. | DONE |
| M3 | MUST | Add honest hard counters/expectations and prove living/hydro false-green before solver repair. | DONE |
| M4 | MUST | Add topology node/edge contracts and reject disconnected required graphs. | PENDING |
| M5 | MUST | Add seven distinct family policies, axial gating and fair 24-candidate scheduling. | PENDING |
| M6 | MUST | Replace greedy allocation with bounded graph-aware beam allocation. | PENDING |
| M7 | MUST | Replace route stub/universal connectors with terminal-driven bounded A*. | PENDING |
| M8 | MUST | Add owner-bound route overlays plus ownership/partition graph and direct materialization. | PENDING |
| M9 | MUST | Compile/place all required compositions atomically with instance policies and reserved clearances. | PENDING |
| M10 | MUST | Add actual topology signature, quality vector, lexicographic selection and seed-only tie. | PENDING |
| M11 | MUST | Fix normalized room reports and extend optional semantic v1 room/debug fields. | PENDING |
| M12 | MUST | Migrate used helpers, remove semantic/BSP/room-graph/divider legacy after zero-callsite audit. | PENDING |
| K1 | KEEP | One canonical production pipeline and existing public generator/config/UI/runtime contracts. | ACTIVE |
| R1 | REJECT | No alternate solver, flag, fallback, synthetic required support or visualizer-side repair. | ACTIVE |
| C1 | CHECK | New living/hydro Stage 0 expectations fail before repair and pass after repair unchanged. | RED BASELINE VERIFIED; final green pending |
| C2 | CHECK | Focused Building Layout units and Werror compile pass. | PENDING |
| C3 | CHECK | Seven-program 840-case v2 matrix passes with replay hashes and required summaries. | PENDING |
| C4 | CHECK | All 15 public programs pass preview/apply/undo smoke. | PENDING |
| C5 | CHECK | Full units, diff/old-path/process audits complete; external HALO/config failures isolated. | PENDING |

## Forbidden substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | Wrapping or validating the old greedy/blanket topology instead of replacing it. |
| F2 | Auto-connecting disconnected required graphs. |
| F3 | Treating `family_id` as an actual topology signature. |
| F4 | Counting blanket circulation or ownerless open bay as assigned useful interior. |
| F5 | Connecting every room directly to route or using a seed-only route as the final network. |
| F6 | Inflating budgets, pruning required module members or synthesizing singleton support. |
| F7 | Repairing canonical walls/partitions after emission or weakening geometry counters. |
| F8 | Keeping the old two-family early exit or 10% seeded quality band. |
| F9 | Moving any generation, allocation or geometry repair into `tools/world_edit_visual`. |

## Old path audit

| Old path | Required result | Audit |
| --- | --- | --- |
| `connect_building_layout_topology_components()` | Deleted; disconnected required graph is compile error. | definition + callsite `rg` |
| blanket circulation materialization | Deleted; every overlay turf has a semantic owner or explicit route. | overlay callsite + report counters |
| automatic `[room]_to_route` | Deleted; only compiled topology/terminal geometry creates connections. | fixed-string/callsite audit |
| `solve_building_layout_route_from_region()` and direct-route fast path | Deleted/replaced by bounded terminal A*. | definition + callsite audit |
| synthetic support specs / budget inflation / singleton fallback | Deleted from required composition flow. | helper and fallback counter audit |
| member-level budget pruning | Deleted; whole module instance accepted/rejected. | composition callsite audit |
| post-emission canonical repair | Deleted; defects reject before emission. | materializer/cleanup audit |
| family-id dedup / two-family stop / 10% selection | Replaced by signature dedup, full cap trial and lexicographic tie policy. | selection audit + units |
| duplicate canyon validators | Keep route-band validator only. | definition/callsite audit |
| legacy `semantic/**`, room graph, BSP, divider data | Removed after helper migration and zero callsites. | include + type + field audit |
| `layout_layout_*` room key | Removed by normalized candidate room ID reporting. | report payload audit |
