# PLAN

## Active Task
HALO CORE port from `cmss13-pve-halo` into `modular/halo` (separate modular module), with only unavoidable glue in `code/**`.

## Current Status
- Module, content migration, assets, maps, and rotation are integrated.
- Compile gate and maplint gate are green.
- Compatibility pass for upstream API drift is completed.

## Delivered Scope
- `modular/halo/_halo.dme` + `modular/modular.dme` include wiring.
- HALO CORE code in `modular/halo/code/**` (species/support, weapons/ammo, clothing/armor, objects, cryo/map-related content).
- Required glue in `code/**` and `map_config/**` (with `SS220 EDIT` where required).
- HALO assets and 3 map entries in rotation without changing defaults (`lv624`, `blue_ridge`).

## Remaining Scope
- Manual runtime smoke checklist on live host/session.
