# EVIDENCE

## E-2026-03-06-01: Source baseline pin
- Repo: `https://github.com/cmss13-devs/cmss13-pve-halo`
- Commit: `7e498b805686ab870ddcfaa3cdf348103c0e3f51`
- Verification: `git -C C:\Users\Alexey\AppData\Local\Temp\cmss13-pve-halo-plan rev-parse HEAD`

## E-2026-03-06-02: Compile gate passed
- Command: `BUILD.cmd`
- Result: `colonialmarines.dmb - 0 errors, 0 warnings` (2026-03-06 09:17 local)
- Notes: Added HALO CORE compatibility surfaces (missing defines/typepaths/base vars) and removed duplicate proc conflict from Sangheili actions.

## E-2026-03-06-03: Map lint passed for new HALO maps
- Command:
  `tools/bootstrap/python -m maplint.source maps/map_files/halo_new_irvine/halo_new_irvine.dmm maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm maps/map_files/unsc_dark_was_the_night_odst/unsc_dark_was_the_night_odst.dmm`
- Result:
  - `maps/map_files/halo_new_irvine/halo_new_irvine.dmm OK`
  - `maps/map_files/unsc_dark_was_the_night/unsc_dark_was_the_night.dmm OK`
  - `maps/map_files/unsc_dark_was_the_night_odst/unsc_dark_was_the_night_odst.dmm OK`

## E-2026-03-06-04: HALO asset path integrity
- Scope: all quoted `icons/...` and `sound/...` paths referenced from `modular/halo/**` `.dm/.dme`.
- Result: `TOTAL_REFS=146`, `MISSING=0`.
- Method: PowerShell path existence check against repo root.

## E-2026-03-06-05: Remaining manual validation
- Not executed in this session:
  - Runtime smoke checks for species spawn flow, emote/warcry audio, live weapon usage, and map vote/forced load.
