# DECISIONS

## 2026-03-28

### Decision
Implement `pony_xeno` as a standalone modular pack modeled after `modular/arachnid`, with only minimal upstream glue for places where the current xeno contracts do not expose a sufficient hook.

### Why
- SS220 guidance keeps new business logic in `modular/**`.
- `modular/arachnid` already demonstrates the intended xeno extension shape for subtypes, custom sounds, and modular combat presentation.
- The existing xeno AI, caste, hive, and minimap systems are already suitable if pony mobs stay inside the xenomorph inheritance tree.

### Consequences
- Most feature work stays isolated under `modular/pony_xeno`.
- A small number of `code/**` edits may still be necessary for dynamic icon handling and custom remains hooks.
- Those upstream edits must stay adapter-sized and marked with `SS220 EDIT`.

## 2026-03-28

### Decision
Expose pony xeno castes to existing admin spawn UX by extending the same string-based caste routing surfaces used for arachnids.

### Why
- `Create Xenos` and Game Master spawning do not operate on typepaths directly; they resolve a display string through `RoleAuthority.get_caste_by_text()`.
- Following the arachnid pattern keeps the UX consistent and avoids adding a pony-only spawn codepath.
- The user explicitly requested spawn support from both `Create Xenos` and Game Master Panel.

### Consequences
- Minimal upstream glue is required in defines, `RoleAuthority`, and the admin panel spawnable-xeno lists.
- Pony castes become available not only to the main Game Master panel, but also to the ambush submenu that shares the same pattern.

## 2026-03-28

### Decision
Refactor pony icon-pack generation to build single-direction canvases and insert them into a pack with named arguments and centered blend positions.

### Why
- The first pack assembly approach could throw `bad icon operation` during `Insert()` when building directional runtime states.
- Centering blend positions from actual part dimensions is more stable than relying on fixed canvas offsets for every part and direction.
- The user explicitly reported a runtime failure during directional state pack generation.

### Consequences
- Generated pony icons now use a deterministic per-direction render path before being inserted into the multi-state pack.
- Render offsets stay data-driven through caste-level base offsets and direction-specific adjustments.
- The appearance datum now carries the selected armor variant so cache keys fully describe the rendered composite.

## 2026-03-28

### Decision
Use a data-driven appearance datum plus runtime icon cache instead of prebuilt per-caste sprite sheets.

### Why
- The request explicitly requires composition from separate pony parts.
- A shared generator makes it easy to add future caste variants, parts, and palettes without multiplying authored sheets.
- Deterministic cache keys allow appearance reuse without rebuilding icons every tick.

### Consequences
- The module needs a stable cache key format and a disciplined part/state catalog.
- The first implementation should focus on a compile-safe subset of part/state combinations that already covers idle, walking, attacking, and death.

## 2026-03-28

### Decision
Favor locally authored pony-xeno part assets inspired by tgstation pony references rather than trying to port the entire upstream pony species asset tree verbatim.

### Why
- The requested feature needs xeno-readable combat silhouettes, 64x64 combat states, and modular compositing, not the full human-species pony stack.
- A focused local asset set is smaller, easier to maintain, and fits the requested hostile AI presentation better.

### Consequences
- Visual fidelity should follow the reference structure and flavor, but the asset set can stay purpose-built for hostile xeno gameplay.
- The implementation should preserve clearly named part categories so future ports or art refreshes remain straightforward.
