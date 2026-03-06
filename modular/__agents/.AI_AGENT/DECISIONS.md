# DECISIONS

## D-2026-03-06-01: Source pin for HALO parity
- Decision: Keep source baseline pinned to `7e498b805686ab870ddcfaa3cdf348103c0e3f51`.
- Rationale: Deterministic backport and reproducible sync behavior.

## D-2026-03-06-02: Modular-first map blocker fixes
- Decision: Port missing map-critical typepaths into `modular/halo/**` and only keep ODST glue in `code/**`.
- Rationale: Preserve upstream isolation while resolving `undefined/unknown type` map failures.

## D-2026-03-06-03: ODST parity without global constant overwrite
- Decision: Add only ODST constants/roles/channels in `code/**`; do not overwrite non-ODST defaults.
- Rationale: Meet parity target while minimizing regression risk in existing factions/roles.

## D-2026-03-06-04: Source deviation fix (intentional)
- Decision: For `/obj/effect/landmark/start/marine/rto/odst`, point `job` to `/datum/job/marine/standard/ai/rto/odst`.
- Rationale: Source mapping references generic `/ai/odst`; this is an obvious mismatch for RTO landmark and breaks role correctness.

## D-2026-03-06-05: Map compile validation strategy
- Decision: Use staged CI-equivalent map compile (`ALL_MAPS_STAGE_BASE` + `ALL_MAPS_STAGE_EXTRA`) as the acceptance signal.
- Rationale: Local monolithic `ALL_MAPS + CIBUILDING` invocation crashes with DM exit `3221225477` after map loading, while staged CI map compile passes with `0 errors`.

## D-2026-03-07-01: HALO runtime fix strategy for current map item
- Decision: Backport source-pinned HALO map key routing (`MAP_HALO_NEW_IRVINE`) instead of broad behavioral rewrites in `/obj/item/map/current_map/Initialize`.
- Rationale: Directly resolves `Cannot read null.name` for HALO map while keeping existing upstream behavior unchanged.

## D-2026-03-07-02: `liquidhydrogen` reagent placement
- Decision: Define `/datum/reagent/hydrogen/liquid` in `modular/halo/**` (HALO module scope) rather than patching base reagent files in `code/**`.
- Rationale: The reagent is required by HALO-specific objects (`barrel/liquidhydrogen`, `fueltank/liquidhydrogen`) and fits modular-first containment.
