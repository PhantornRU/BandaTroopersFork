# PLAN

## Active task
Implement HALO Covenant AI overheat fallback, Sangheili sword behavior, sword-only Sangheili presets, and new pure-Sangheili squads in `modular/halo/**`.

## Delivery status
- [x] Rewrite task-state for the Covenant AI scope.
- [ ] Add HALO brain helpers for Covenant overheat and Sangheili sword metadata.
- [ ] Implement Sangheili overheat response and sword charge action datums.
- [ ] Extend Unggoy panic retreat with overheat-aware branches.
- [ ] Update Sangheili gear presets, AI presets, and Covenant belt storage for swords.
- [ ] Add pure-Sangheili squad presets.
- [ ] Extend HALO unit tests for swords, overheat branches, and squad compositions.
- [ ] Run compile and `dm-test` verification.

## Acceptance status
- Pending: Sangheili no longer freeze on Covenant gun overheat.
- Pending: Unggoy retreat on plasma overheat and rejoin combat after cooldown.
- Pending: Ultra and Zealot presets carry one energy sword on the belt.
- Pending: sword-only Sangheili AI presets and pure-Sangheili squads are spawnable.
- Pending: HALO compile and unit tests are green.
