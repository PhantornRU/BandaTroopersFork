# DECISIONS

## D-001: Ship platoon selection stays data-driven
- Decision: remove `ship_platoon_override` entirely and resolve the active ship platoon only from ship config defaults plus persisted `next_ship.json` override created by `allowed_platoons`.
- Why: this keeps selection on an existing data surface and avoids another hardcoded runtime branch in game mode code.

## D-002: Legacy ODST remains loadable but not active
- Decision: keep `/datum/squad/marine/odst`, old ODST landmarks, and legacy job paths only as compatibility wrappers over namespaced HALO ODST job paths.
- Why: old paths may still exist in content, but active ship rotation and role registries must only know about `/datum/squad/marine/halo/odst/alpha`.

## D-003: HALO role classification moves to modular helpers
- Decision: restore upstream global role lists to vanilla scope and expose helper procs on `RoleAuthority` for marine-equivalent and shipside classification.
- Why: HALO jobs are current-round specializations, not a reason to widen shared upstream globals for every unrelated consumer.

## D-004: Shared consumers may ask RoleAuthority for active titles
- Decision: update latejoin, admin, datacore, who, end-round, card-console, role-weight, and shipside access paths to use helper procs or default-role mapping instead of assuming HALO roles live in `ROLES_MARINES` or `ROLES_USCM`.
- Why: consumers still need correct behavior during HALO rounds, but the integration point must stay narrow and modular.

## D-005: Branch hygiene includes local-tool artifacts
- Decision: remove `.vscode/launch.json` and generated `colonialmarines.test.dme` from the branch.
- Why: they are environment noise and do not belong to the feature diff.
