# Каталог генераторов World Edit v1.3 (seed)

Примечание:
1. Runtime core 1:1:
- `id`, `name_ru`, `category_ru`, `description_ru`
- `required_rights`, `supports_preview`, `execution_mode`
- `generator_type`, `default_params`, `status`
2. Docs-only metadata:
- `owner`, `priority`, `phase`
- `ui_schema_version`, `ui_mode`
3. Актуальный runtime-ready набор для текущей Phase 3A ветки:
- `outpost_radius`
- `destruction_pack`
- `blueprint_stamp`
4. Ниже сохранены исторические паспорта deprecated-генераторов v1.3; они не входят в current ready surface.

## fortify_room
- `status`: `deprecated`
- `owner`: `BandaTroopers`
- `priority`: `P1`
- `phase`: `v1.3`
- `required_rights`: `R_DEBUG`
- `supports_preview`: `TRUE` (обязательный)
- `execution_mode`: `batch`
- `generator_type`: `/datum/world_edit_generator/fortify_room`
- `ui_schema_version`: `v2`
- `ui_mode`: `inline+fallback`
- `default_params`:
  - `fortification_level = "Metal"`
  - `tile_scan_limit = 195`
  - `scan_radius = 12`
  - `respect_windows = TRUE`
  - `respect_doors = TRUE`

## defense_grid
- `status`: `deprecated`
- `owner`: `BandaTroopers`
- `priority`: `P1`
- `phase`: `v1.3`
- `required_rights`: `R_DEBUG`
- `supports_preview`: `TRUE`
- `execution_mode`: `batch`
- `generator_type`: `/datum/world_edit_generator/defense_grid`
- `ui_schema_version`: `v2`
- `ui_mode`: `inline+fallback`
- `default_params`:
  - `defense_path = null`
  - `faction = FACTION_MARINE`
  - `turned_on = TRUE`
  - `placement_direction = "Default"`
  - `batch_count = 1`
  - `batch_step = 1`

## breach_layout
- `status`: `deprecated`
- `owner`: `BandaTroopers`
- `priority`: `P1`
- `phase`: `v1.3`
- `required_rights`: `R_DEBUG`
- `supports_preview`: `TRUE` (информационный preview)
- `execution_mode`: `click`
- `generator_type`: `/datum/world_edit_generator/breach_layout`
- `ui_schema_version`: `v2`
- `ui_mode`: `inline+fallback`
- `default_params`:
  - `charge_type = /obj/item/explosive/plastic`
  - `direction = NORTH`
  - `allowed_profile = "Стандартный"`

## structure_chunk
- `status`: `deprecated`
- `owner`: `BandaTroopers`
- `priority`: `P2`
- `phase`: `v1.3`
- `required_rights`: `R_EVENT` (override)
- `supports_preview`: `TRUE`
- `execution_mode`: `batch`
- `generator_type`: `/datum/world_edit_generator/structure_chunk`
- `ui_schema_version`: `v2`
- `ui_mode`: `inline+fallback`
- `default_params`:
  - `template_name = ""`
  - `centered = TRUE`
  - `delete_atoms = FALSE`

## barricade_builder
- `status`: `deprecated`
- `owner`: `BandaTroopers`
- `priority`: `P1`
- `phase`: `v1.3`
- `required_rights`: `R_DEBUG`
- `supports_preview`: `TRUE`
- `execution_mode`: `click`
- `generator_type`: `/datum/world_edit_generator/barricade_builder`
- `ui_schema_version`: `v2`
- `ui_mode`: `inline+fallback`
- `default_params`:
  - `barricade_path = /datum/human_ai_defense/barricade/metal`
  - `shape_mode = "point"`
  - `dir_mode = "auto"`
  - `fixed_dir = NORTH`
  - `replace_existing_same_dir = FALSE`
  - `max_tiles = 40`

## chaos_demolition
- `status`: `deprecated`
- `owner`: `BandaTroopers`
- `priority`: `P1`
- `phase`: `v1.3`
- `required_rights`: `R_DEBUG`
- `supports_preview`: `TRUE`
- `execution_mode`: `click`
- `generator_type`: `/datum/world_edit_generator/chaos_demolition`
- `ui_schema_version`: `v2`
- `ui_mode`: `inline+fallback`
- `default_params`:
  - `radius = 3`
  - `shuffle_enabled = TRUE`
  - `scatter_enabled = FALSE`
  - `scatter_steps = 2`
  - `explode_enabled = FALSE`
  - `explosion_power = 250`
  - `explosion_falloff = 600`
  - `persistent_fire_enabled = FALSE`
  - `persistent_fire_density = 0.15`
  - `max_atoms = 120`
  - `affect_anchored = FALSE`
