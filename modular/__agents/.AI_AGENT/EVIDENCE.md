# EVIDENCE

## E-001: Stock human AI does not understand Covenant overheat
- `fire_at_target`, `keep_distance`, and `select_primary` only reason about ammo and generic gun usability.
- Covenant plasma cooldown lives on HALO gun-side `cooldown` and `manual_cooldown`, so overheated weapons still look usable to stock AI.

## E-002: Stock human AI melee support does not fit Sangheili swords
- `unholster_melee()` only pulls melee from shoes and `holster_melee()` only tries to return it to shoes.
- HALO energy swords are belt/suit-store items, so Sangheili need HALO-specific draw/holster handling.

## E-003: Current HALO Unggoy retreat only covers health panic and lost-leader panic
- Existing `unggoy_panic_retreat.dm` exposes health-threshold panic and no-leader panic helpers, but it has no overheat-specific branch.
- Suicide bomber behavior already uses HALO-specific brain metadata and remains the intended exemption point for new overheat retreat logic.
