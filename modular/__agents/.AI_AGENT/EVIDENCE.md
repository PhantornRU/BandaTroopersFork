# EVIDENCE

## E-2026-03-06-01: Source baseline
- Repo: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Commit: `7e498b805686ab870ddcfaa3cdf348103c0e3f51`

## E-2026-03-06-02: Missing map typepaths are now resolved in codebase
- Command: `tmp_undefined_types.txt` back-check against repo type declarations.
- Verification command:
  - `NOT_FOUND_COUNT=0` via `rg` check over `code` and `modular/halo`.

## E-2026-03-06-03: Compile gate (requested monolithic invocation)
- Command: `tools/build/build dm --ci --define=ALL_MAPS --define=CIBUILDING`
- Result: DM process exits with `3221225477` after full map loading in local environment (no `undefined type` / `unknown type` lines emitted before crash).
- Note: reproduced twice.

## E-2026-03-06-04: CI-equivalent staged map compile passed
- Commands:
  - `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_BASE`
  - `tools/build/build dm --ci --define=CIBUILDING --define=CITESTING --define=ALL_MAPS --define=ALL_MAPS_STAGE_EXTRA`
- Result:
  - `colonialmarines.dmb - 0 errors, 0 warnings` on both stages.

## E-2026-03-06-05: Control compile passed
- Command: `tools/build/build dm --ci --define=ALL_MAPS`
- Result: `colonialmarines.dmb - 0 errors, 0 warnings`.

## E-2026-03-06-06: HALO maplint passed
- Command:
  - `tools/bootstrap/python -m maplint.source maps/map_files/halo_new_irvine/halo_new_irvine.dmm maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm maps/map_files/unsc_dark_was_the_night_odst/unsc_dark_was_the_night_odst.dmm`
- Result:
  - `halo_new_irvine.dmm OK`
  - `unsc_dark_was_the_night.dmm OK`
  - `unsc_dark_was_the_night_odst.dmm OK`

## E-2026-03-06-07: Source deviation logged
- Deviation: `/obj/effect/landmark/start/marine/rto/odst` now points to `/datum/job/marine/standard/ai/rto/odst`.
- Reason: fixes obvious source mismatch to generic `/ai/odst` and preserves ODST RTO role semantics.
