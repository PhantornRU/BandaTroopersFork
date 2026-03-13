# EVIDENCE

## E-001: The sword persistence bug is a no-fallback teardown problem
- `sangheili_sword_charge` and `exit_combat()` could still holster/deactivate the sword after the AI no longer had a firearm to return to.
- That leaves no-gun Sangheili empty-clicking unless they redraw/reactivate again.

## E-002: The hand-DMI files are not missing states
- `items_lefthand_halo_64.dmi` and `items_righthand_halo_64.dmi` both declare `energy_sword` and `energy_sword_activated` with `dirs = 4`.
- The user-facing invisibility report therefore required checking the runtime overlay path, not only DMI metadata.

## E-003: The real render failure is runtime clipping
- Generic item rendering asks species `get_offset_overlay_image()` to rebuild direction-adjusted overlays on a 32x32 template.
- Sangheili hand offsets work for standard-sized items, but they clip the HALO sword's 64x64 inhand art.
- A HALO-local sword overlay override avoids that clipping while preserving Sangheili hand shifts.

## E-004: Verification status
- Verification has not yet been rerun after the persistence and runtime render fixes.
