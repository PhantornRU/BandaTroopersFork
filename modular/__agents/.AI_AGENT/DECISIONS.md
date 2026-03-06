# DECISIONS

## D-2026-03-06-01: Scope delivery model
- Decision: Implement HALO in phased mode, execute CORE now.
- Rationale: Reduces risk and preserves mergeability with SS220 overlays.

## D-2026-03-06-02: Integration policy
- Decision: Modular-first (`modular/halo/**`) with only unavoidable glue in `code/**`.
- Rationale: Keeps business logic isolated, limits upstream conflict surface.

## D-2026-03-06-03: Maps rollout
- Decision: Add 3 HALO maps to rotation with source map types preserved.
- Ground: `halo_new_irvine` in `map_config/maps.txt`.
- Ship: `unsc_dark_was_the_night`, `unsc_dark_was_the_night_odst` in `map_config/shipmaps.txt`.
- Default entries remain unchanged (`lv624`, `blue_ridge`).

## D-2026-03-06-04: Source pin
- Decision: Pin import source to commit `7e498b805686ab870ddcfaa3cdf348103c0e3f51`.
- Rationale: Deterministic migration baseline for future syncs.

## D-2026-03-06-05: Runtime rollout
- Decision: No runtime/compile feature flag for CORE phase.
- Rationale: User requested immediate active integration.

## D-2026-03-06-06: Upstream compatibility handling
- Decision: Resolve missing upstream HALO dependencies with modular compatibility files in `modular/halo/code/mixed/compat/**` and minimal targeted glue in `code/**`.
- Rationale: Keeps HALO business logic modular-first while avoiding broad unrelated upstream backports.
