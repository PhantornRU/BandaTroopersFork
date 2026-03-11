# TODO

- [x] Remove the dead `ship_platoon_override` field and resolver branches.
- [x] Keep active ship platoon selection on ship config plus `allowed_platoons` override persisted in `data/next_ship.json`.
- [x] Move active HALO ODST role mappings to namespaced HALO paths.
- [x] Keep legacy ODST squad and job paths as compat-only wrappers.
- [x] Remove legacy ODST from active ship platoon registries and conflict-family filtering.
- [x] Revert upstream global HALO role-list widening.
- [x] Add modular helpers for marine-equivalent and shipside role classification.
- [x] Rewire shared consumers that depended on widened global lists.
- [x] Add unit tests for ship override persistence, HALO role classification, and legacy ODST compatibility.
- [x] Remove `.vscode/launch.json` from the branch.
- [x] Remove generated `colonialmarines.test.dme` artifact from the worktree.
- [ ] Manually verify each `allowed_platoons` option on `UNSC Stalwart Frigate` in a live round.
