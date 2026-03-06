# DECISIONS

## D-001: `z_list` remains managed-only
- `z_list` represents mapping-managed runtime z-levels only.
- `world.maxz` is allowed to be larger than `length(z_list)`.

## D-002: Dynamic map loading starts from managed z-count
- `LoadGroup()` and `ground_start` use `length(z_list) + 1`.
- Reason: `add_new_zlevel()` allocates from managed z-count, not from precompiled `world.maxz`.

## D-003: Compile-time unmanaged z-levels are trait-less, not invalid
- `level_trait()` returns no trait for `z <= world.maxz` but `z > length(z_list)`.
- Reason: `ALL_MAPS` compiles many physical z-levels that do not need `datum/space_level`.

## D-004: Strict `get_level()` is preserved
- `get_level()` still crashes for unmanaged z-levels.
- Reason: code asking for a managed `datum/space_level` is making a stronger contract than a trait lookup.

## D-005: No subsystem skips are allowed in this task
- Startup hangs must be fixed through managed-z semantics, not through `ALL_MAPS` fast-paths.

## D-006: Unmanaged compile-time z-levels should not bootstrap late-init integrations
- Static lighting objects are not created for `z > length(SSmapping.z_list)`.
- Telecomms on `z > length(SSmapping.z_list)` stay dormant and do not register minimap markers.
- Reason: these layers are physically compiled for `ALL_MAPS`, but they are not active managed runtime space levels.
