# DECISIONS

## D-001: Live packages now default to `charges`
- Decision: switch all live RTO support templates to `RTO_SUPPORT_RESOURCE_MODE_CHARGES` and make Game Rule Panel default resource mode `charges`.
- Why: the rollout is complete enough that keeping `hybrid` as the default would only hide the new baseline.

## D-002: Zone runtime remains time-based
- Decision: keep `visibility_zone` timing and ownership rules unchanged while migrating support execution to shared pools.
- Why: zone runtime is already stable and separate from the support economy.

## D-003: Utility packages use small shared pools; combat packages use weighted burst pools
- Decision: logistics/medical/technical families use compact 2-charge pools with slower recharge, while mortar/CAS/heavy use larger weighted pools with faster or role-specific recharge.
- Why: this preserves role pacing while enabling “one heavy or several light” tradeoffs inside a package.

## D-004: Player-facing UI should explain charges directly
- Decision: preset menu, action descriptions, and binocular examine text must show charges/costs/lockouts instead of only shared cooldown language.
- Why: otherwise players cannot understand why a heavy ability is blocked after spending lighter sibling actions.

## D-005: GM live pool editing is a supported gameplay tool, not a debug-only escape hatch
- Decision: keep per-player `set/add/subtract/refill/empty`, capacity edits, auto-recharge toggle, and manual-only toggle in the main Game Rule Panel flow.
- Why: manual issuance is a requested GM gameplay mode for RTO.
