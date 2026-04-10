# EVIDENCE

## E-001: All live template families are charge-based
- `modular/rto_support/code/config/templates/{logistics,medical,technical,mortar,cas,heavy,halo_logistics,halo_medical,halo_technical}.dm`
- Each live package now sets `support_resource_mode = RTO_SUPPORT_RESOURCE_MODE_CHARGES` with explicit pool config.

## E-002: Weighted sibling sharing is encoded in action config
- `modular/rto_support/code/config/action_templates/**`
- Heavy abilities now spend more shared charges than lighter sibling abilities, while using `personal_lockout` as the local anti-spam surface.

## E-003: Runtime and GM tooling manage live pool state immediately
- `modular/rto_support/code/runtime/resource_pool_state.dm`
- `modular/rto_support/code/controller/controller.dm`
- `modular/game_rule_panel/code/ui/game_rule_panel.dm`
- Active controllers expose live pool edits, recharge toggles, manual-only mode, and refill/empty/reset operations.

## E-004: Player-facing UI now speaks the charge model
- `tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx`
- `modular/rto_support/code/items/rto_binoculars.dm`
- Preset cards and binocular examine text now show shared charges, weighted costs, recharge state, and local lockouts.

## E-005: Verification passed after full migration
- `./BUILD.cmd`
- `tools/build/build --ci lint tgui-test`
- Both completed successfully on 2026-04-11 after the full package migration and UI/test updates.
