# PLAN

## Active task
Keep HALO Sangheili swords active when an AI has no usable ranged fallback, and fix the missing hand-render issue for Sangheili sword overlays across all directions.

## Delivery status
- [x] Add a HALO-local no-ranged-fallback guard for drawn-sword persistence.
- [x] Prevent incidental sword holster/deactivation when that AI has no firearm it can return to.
- [x] Fix the Sangheili sword hand render path so 64x64 inhand overlays are not clipped by species offset handling.
- [x] Replace the old metadata-only sword dir guard with stronger sword render tests.
- [ ] Run `dm` verification.
- [ ] Attempt `dm-test` verification through the standard wrapper.

## Acceptance status
- Pending verification: no-gun HALO Sangheili should keep the sword drawn and active instead of deactivating it on combat/action teardown.
- Pending verification: HALO Sangheili sword overlays should render visibly in both hands for `SOUTH`, `NORTH`, `EAST`, and `WEST`.
