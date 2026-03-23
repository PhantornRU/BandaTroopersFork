# HALO NAME LOCALIZATION MIGRATION

Canonical baseline for moving HALO `name` localization toward `translation_data` without regressing current player-facing Russian text.

## Current model
- `translation_data/ru_names` is metadata for Russian forms and declensions.
- It is not a global replacement for `name`.
- A player-facing surface must explicitly ask for the localized form through a hook/helper such as `get_display_name_ru()` or `get_display_name_ru_initial()`.

## HALO migration buckets

### `safe_now`
- Surfaces that already use an explicit localization hook.
- Current confirmed example: vendor entry rewriting through `translate_vendor_entries_to_ru()` and `get_display_name_ru_initial()`.
- Current pilot package: HALO UNSC medical vendor entries in `modular/halo/code/game/machinery/vending/vendor_types/halo/misc.dm`, backed by `modular/translations/code/translation_data/ru_names/halo_vendors.toml`.
- Only names that are shown exclusively through such hooks are eligible for English-canonical `name` plus `translation_data` migration right now.

### `needs_hook`
- Any HALO atom name that can reach players or admins through raw `.name`, `[src]`, `[item]`, or generic display helpers that still read canonical `name`.
- This includes the current high-risk HALO surfaces:
  - generic examine/display flows
  - visible chat/combat/use messages
  - admin-visible attack/debug messages
  - inventory and UI lists that still read `name` directly
  - mapped objects and items whose in-game interactions interpolate `[src]` or `[item.name]`
- These names must stay localized in DM until the specific surface is moved to an explicit display-name hook.

### `never_move`
- Non-atom and map/UI labels that are outside the `ru_names` model.
- Keep localized directly in DM/DMM:
  - map-instance strings in `.dmm`
  - area names
  - datum names and preset names
  - `assignment`
  - `prefix`
  - `phone_id`

## Migration protocol
1. Identify the exact player-facing surface for a candidate HALO name.
2. Convert that surface to an explicit localized display-name helper.
3. Verify that the surface no longer exposes canonical English `name`.
4. Only then move the atom to English-canonical `name` plus `translation_data`.
5. Review `ru_names` TOML key collisions before adding common English base names, because the keys are global and may affect non-HALO content.

## Non-goals for this baseline
- No mass revert of current HALO Russian `name`.
- No attempt to move `desc`, map labels, or datum strings into `translation_data`.
- No assumption that a `ru_names` TOML entry is sufficient unless the target surface explicitly consumes localized display names.
