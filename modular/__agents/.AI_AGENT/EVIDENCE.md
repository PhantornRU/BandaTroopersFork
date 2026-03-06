# EVIDENCE

## Baseline
- The uncommitted patch that expanded `z_list` to `world.maxz` was reverted.
- New implementation keeps `zlevel_manager.dm` on managed-only initialization.

## Current Code Changes
- `code/controllers/subsystem/mapping.dm`
  - `LoadGroup()` now starts dynamic z-allocation from `length(z_list) + 1`.
  - Added a managed-z invariant after `add_new_zlevel()`.
  - `zlevel.bounds` are rebound using world z-values instead of local DMM z-values.
  - `ground_start` now follows managed z-count.
- `code/modules/mapping/space_management/traits.dm`
  - `level_trait()` now treats `z <= world.maxz && z > length(z_list)` as compile-time unmanaged and trait-less.
- `code/modules/lighting/lighting_static/static_lighting_setup.dm`
  - Static lighting bootstrap now skips compile-time unmanaged z-levels.
- `code/game/machinery/telecomms/telecomunications.dm`
  - Telecomms machines on compile-time unmanaged z-levels stay dormant instead of joining active tcomms startup.
- `code/game/machinery/telecomms/presets.dm`
  - Telecomms tower minimap markers are only registered on managed z-levels.

## Verification
- `git diff --check`
  - Passed.
- `rg -n "list index out of bounds|Unmanaged z-level" data/logs/2026/03-March/06-Friday/round-149 data/logs/2026/03-March/06-Friday/round-151 data/logs/2026/03-March/06-Friday/round-152`
  - No matches.
- normal `dm-test`
  - Earlier smoke run reached `Round started` in `round-149`.
  - Not re-run after the later lighting/telecomms cuts.
- `ALL_MAPS` base `dm-test`
  - `round-151` confirmed that the server no longer died immediately after managed-z setup and continued progressing through late init.
  - `round-152` showed reduced early side effects after the lighting/telecomms managed-z cuts.
  - `clean_run.lk` was still not produced before the test run was stopped manually.

## Residual Risk
- `ALL_MAPS` runtime still appears dominated by compile-time map content initializing outside the active managed z-set.
- The original `mapping` root bug is fixed, but full `ALL_MAPS` clean completion remains unproven.
