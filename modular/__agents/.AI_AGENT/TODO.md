# TODO - Variant A Building Layout Furnishing

## Contract Tasks

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| T1 | MUST | Complete read-only discovery of fixture entrypoints, include graph, provider source, cluster specs, validators, tests, and Workbench metrics. | [x] |
| T2 | MUST | Replace broad PR99 task-state with Variant A furnishing contract. | [x] |
| T3 | MUST | Complete self plan-mapping challenge before implementation. | [x] |
| T4 | MUST | Add verified provider registry/catalog with >=50 resolved providers and Covenant decorative-only behavior. | [x] |
| T5 | MUST | Add placement module catalog with >=100 semantic modules and required metadata. | [x] |
| T6 | MUST | Add atomic module solver and candidate rejection for invalid room, route, and door-clearance conflicts. | [x] |
| T7 | MUST | Route current cluster specs to modules and hard-error required unmapped clusters while warning/skipping optional unmapped clusters. | [x] |
| T8 | MUST | Disable legacy scatter for semantic furniture slots. | [x] |
| T9 | MUST | Add/export requested furnishing validators and counters. | [x] |
| T10 | MUST | Update `building_living_target_rooms_6` expectations to require all requested counters at zero. | [x] |
| T11 | CHECK | Add focused unit tests for provider audit, module catalog, Covenant decorative-only, no loose furniture, and mosaic rejection. | [x] |
| T12 | CHECK | Run focused verification commands and record results. | [x] |

## Review Follow-Up Tasks

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| RF1 | MUST | Give wall-required modules clearance cells and keep wall-context candidate handling valid. | [x] |
| RF2 | MUST | Enforce module `max_per_room`, `max_per_building`, and room repeat-group caps in candidate search. | [x] |
| RF3 | MUST | Add chair pairing metadata and prevent valid seating rows from producing `unpaired_chair_count`. | [x] |
| RF4 | MUST | Add hard-counter fail gate after validation before candidate success. | [x] |
| RF5 | MUST | Convert provider `style|slot` lookup to provider lists and add unique path metrics. | [x] |
| RF6 | MUST | Add missing review counters and hard-counter exports. | [x] |
| RF7 | CHECK | Update living expectations and run compile plus visual acceptance evidence. | [x] |

## Continuation Tasks

| ID | Type | Requirement | Status |
| --- | --- | --- | --- |
| C13 | MUST | Add an explicit curated placement module layer and prefer it over generated cluster-derived modules. | [x] |
| C14 | MUST | Diagnose and fix current `building_living_target_rooms_6` `semantic_output_missing` workflow failure without moving generation into `tools/world_edit_visual`. | [x] |
| C15 | CHECK | Re-run `building_living_target_rooms_6` after fixes and record current report metrics. | [x] |
| C16 | CHECK | Re-run build/unit compile and `git diff --check`. | [x] |
| C17 | MUST | Treat storage/workshop residual hard gates as active scope instead of out-of-scope smoke failures. | [x] |
| C18 | MUST | Fix semantic module placement so required multi-slot rack/staging/workbench clusters use reserved/compact semantic slot turfs atomically. | [x] |
| C19 | MUST | Remove storage forbidden fallback / route repair / required-room-without-module failures through production placement fixes, not validator hiding. | [x] |
| C20 | CHECK | Re-run storage, workshop, and living target-room visual workflows after the residual fix. | [x] |

## Forbidden Substitutions

| ID | Forbidden substitution |
| --- | --- |
| F1 | Do not add furniture generation to `tools/world_edit_visual`; it is reporting only. |
| F2 | Do not satisfy provider count with unresolved or invented paths. |
| F3 | Do not let Covenant barricade/recharger satisfy functional furniture/infrastructure capabilities. |
| F4 | Do not leave required semantic furniture on legacy `object`/`table_cluster` scatter fallback. |
| F5 | Do not accept partial groups or repair-trimmed module fragments as success. |
| F6 | Do not downgrade required unmapped clusters to warnings. |
| F7 | Do not close acceptance by hiding missing/nonzero counters. |

## Old Path Audit

| Old path/proc | Expected status | Evidence command |
| --- | --- | --- |
| `place_building_cluster_spec()` semantic fallback | semantic slots route through module solver first | `rg -n "place_building_modules_for_cluster|is_building_semantic_furniture_slot|place_building_cluster_spec" modular/world_edit/code/generators/building_layout` |
| `place_table_cluster()` loose table/chair pattern | not reachable for semantic furniture clusters without module mapping | `rg -n "place_table_cluster\\(" modular/world_edit/code/generators/building_layout/building_layout_fixtures.dm` |
| `place_fixture_object()` loose object pattern | not reachable for semantic furniture clusters without module mapping | `rg -n "place_fixture_object\\(" modular/world_edit/code/generators/building_layout/building_layout_fixtures.dm` |
| Missing module metadata | every catalog module has program, zone/role, occupied, clearance, repeat, max fields | unit test `placement_module_catalog_contract` |
| Provider path audit | zero invalid provider paths, >=50 providers | unit test `provider_registry_paths` |
| Workbench acceptance | requested counters are production metrics and gated at zero | `rg -n "loose_table_count|provider_path_not_in_build_count" tools/world_edit_visual/cases/building_living_target_rooms_6.json modular/world_edit/code/visual_workbench` |
