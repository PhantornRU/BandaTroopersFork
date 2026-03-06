# TODO

- [x] Revert the uncommitted `z_list == world.maxz` patch and remove transient test file.
- [x] Reapply dynamic-z start/bounds fixes in `code/controllers/subsystem/mapping.dm`.
- [x] Change `level_trait()` to treat compiled unmanaged z-levels as trait-less.
- [x] Run `git diff --check`.
- [x] Cut late-init work that still bootstrapped unmanaged compile-time z-levels (`lighting`, `telecomms`).
- [ ] Run normal `dm-test` smoke.
- [ ] Re-run normal `dm-test` smoke after the lighting/telecomms changes.
- [ ] Get `ALL_MAPS` base `dm-test` to clean completion.
- [ ] Run `ALL_MAPS` extra `dm-test` smoke.
- [x] Update evidence with actual verification results.
