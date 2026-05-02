# RTO Support: RFC for Shared Weighted Charges

## 1. Purpose

This RFC defines the next-stage RTO support model where support abilities consume shared weighted charges instead of relying on package-wide cooldown timers.

The intended gameplay result is:

- sibling abilities inside one package share a single resource pool;
- light calls can be used several times instead of one heavy call;
- heavy calls are blocked if the remaining package resource is too low;
- GMs can switch recharge off and issue charges manually to specific RTO players through Game Rule Panel.

This RFC does **not** implement the system. It defines the contract for future runtime, config, UI, and GM workflows.

## 2. Goals

- Replace support package `shared cooldown` with a shared weighted charge pool.
- Keep `zone` runtime time-based in the first migration stage.
- Reduce current `personal cooldown` into an optional short `personal lockout`.
- Support both automatic recharge and manual-only GM control.
- Let Game Rule Panel manage:
  - global charge mode and recharge rules;
  - per-template default values;
  - current charge state of active RTO players.

## 3. Non-goals

- Do not convert visibility-zone runtime to charges in stage one.
- Do not remove legacy cooldown fields in the first migration step.
- Do not force every package to migrate at once.
- Do not move package balance data out of `modular/rto_support/code/config/**`.

## 4. Current problem

Today the controller in `modular/rto_support/code/controller/controller.dm` uses three different cooldown families:

- package shared cooldown;
- ability personal cooldown;
- zone cooldown.

This works for simple throttling, but it is a poor fit for resource tradeoffs such as:

- logistics: one expensive crate vs one light drop;
- mortar: one incendiary round vs several cheaper shells;
- heavy strike: one very heavy call vs several smaller ones.

The desired gameplay model is not "wait N seconds after any use", but "spend a shared package resource with different ability weights".

## 5. High-level design

### 5.1 Resource split

Stage one should split RTO runtime into two independent layers:

- `support resource layer`
  - shared weighted charges per package
  - optional per-ability lockout
- `zone layer`
  - current timed active-sector flow
  - current shared/personal zone cooldown model

The zone layer remains unchanged in stage one because it already has separate ownership, validation, and UI semantics.

### 5.2 Player-facing model

Each selected support package owns one common pool.

Examples:

- `logistics`
  - one pool for all logistics drops
  - if the pool has `1/1`, using any logistics ability empties the package
- `mortar`
  - one pool for all mortar shots
  - if the pool has `5/5` and incendiary costs `2`, spending one incendiary leaves `3/5`
  - HE and smoke then consume from the same remaining amount
- `heavy`
  - one heavy strike may cost `3`
  - a lighter strike may cost `1` or `2`
  - if a lighter strike is used first, the heavier one can become unavailable until recharge restores enough resource

## 6. Proposed config contract

### 6.1 Template-level fields

Add package-level resource fields to `modular/rto_support/code/config/template.dm`.

Recommended fields:

- `support_resource_mode`
  - `legacy_cooldown`
  - `charges`
  - `hybrid`
- `support_pool_id`
  - defaults to `template_id`
  - allows multiple templates to share one pool later if needed
- `support_pool_capacity`
  - maximum amount of package resource
- `support_pool_starting_charges`
  - initial amount when the pool is created or fully reset
- `support_pool_recharge_interval`
  - time between recharge ticks
- `support_pool_recharge_amount`
  - how much one recharge tick restores
- `support_pool_auto_recharge`
  - default auto-recharge behavior for this package

Stage one recommendation:

- keep `support_pool_id = template_id`
- keep package pools independent
- use integer charges

### 6.2 Action-level fields

Add ability-level resource fields to `modular/rto_support/code/config/action_template.dm`.

Recommended fields:

- `support_pool_cost`
  - weighted cost paid from the package pool
- `personal_lockout`
  - short local anti-spam timer
- keep legacy fields for compatibility:
  - `shared_cooldown`
  - `personal_cooldown`

Interpretation:

- `shared_cooldown` remains the legacy package throttle
- `support_pool_cost` becomes the new package resource cost
- `personal_lockout` replaces `personal_cooldown` only for migrated templates

## 7. Proposed runtime contract

### 7.1 New pool datum

Introduce a dedicated runtime datum, for example:

- `/datum/rto_support_resource_pool_state`

Recommended state:

- `pool_id`
- `owner`
- `template_id`
- `capacity`
- `current_charges`
- `starting_charges`
- `recharge_interval`
- `recharge_amount`
- `auto_recharge_enabled`
- `manual_override_enabled`
- `next_recharge_at`
- `last_modified_by_admin_ckey`

### 7.2 Controller integration

`modular/rto_support/code/controller/controller.dm` should gain:

- `support_pools_by_id`
- pool lookup helpers
- recharge tick/update helpers
- GM override application helpers

The existing maps should remain during migration:

- `shared_cooldowns_by_template`
- `action_cooldowns`
- `zone_shared_cooldown_until`
- `zone_cooldowns_by_template`

### 7.3 Runtime rules

For `charges` or `hybrid` templates:

- `can_arm_action()` must check:
  - template exists
  - zone requirements are satisfied
  - enough pool resource exists
  - local lockout, if any, is clear
- successful support dispatch must:
  - subtract `support_pool_cost`
  - start `personal_lockout` if configured
  - leave zone runtime untouched
- HUD refresh must tick while:
  - a zone is active
  - zone cooldowns are active
  - local lockouts are active
  - charge recharge is pending

## 8. Balance model

Weighted charges are the core balancing unit.

Illustrative package patterns:

- `logistics`
  - `capacity = 1`
  - every use costs `1`
  - gameplay: one logistics drop before refill
- `mortar`
  - `capacity = 5`
  - smoke `1`
  - HE `1`
  - incendiary `2`
- `cas`
  - `capacity = 3..4`
  - gun run `1`
  - laser run `1`
  - rocket barrage `2`
- `heavy`
  - `capacity = 3`
  - napalm `2`
  - missile strike `3`

These exact numbers are examples, not final balance.

The implementation should derive initial migration values from current cooldown balance, then tune by playtest.

## 9. UI contract

### 9.1 Support HUD buttons

For charge-based templates, support buttons should stop presenting the package state as `Общий КД`.

Recommended primary labels:

- `Готово`
- `Заряды: X/Y`
- `Нужно: N`
- `Лок: Ns` for a short personal lockout
- `Нет сектора` for zone-based actions without a valid active sector

If the package has some charge but not enough for a heavy ability:

- the button should be disabled
- the label should explain the shortage directly
- example: `Нужно: 3 (есть 2)`

### 9.2 Preset menu

`tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx` and `modular/rto_support/code/ui/ui_contracts.dm` should eventually expose:

- `resource_mode`
- `pool_capacity`
- `pool_starting_charges`
- `pool_current_charges` when viewing a live selected package
- `pool_recharge_interval`
- `pool_recharge_amount`
- `pool_auto_recharge`
- `support_pool_cost` per action

Stage one requirement:

- legacy templates may continue to show cooldown values
- migrated templates should show charge cost and recharge behavior instead

### 9.3 Binocular examine text

`modular/rto_support/code/items/rto_binoculars.dm` should eventually describe:

- selected packages
- current pool amount for each selected package
- whether recharge is active or disabled
- whether the controller is in manual-only mode
- zone state separately from support resource

## 10. Game Rule Panel design

Game Rule Panel must support two distinct surfaces:

- global RTO resource rules
- live active-RTO management

These should not be merged into one flat form, because they affect different scopes and carry different GM intent.

## 11. Game Rule Panel: global resource rules

Global RTO resource rules belong in `modular/game_rule_panel/code/state/game_rule_state.dm`.

Recommended new rule fields:

- `rto_support_resource_mode`
  - `legacy_cooldown`
  - `hybrid`
  - `charges`
- `rto_charge_recharge_enabled`
  - master auto-recharge toggle
- `rto_charge_recharge_multiplier`
  - scales recharge speed
- `rto_charge_capacity_multiplier`
  - optional capacity scaling knob
- `rto_charge_manual_only`
  - if true, recharge is disabled and charge issuance is manual by GM

Recommended per-template default override table in Game Rule Panel:

- template id
- default capacity
- default starting charges
- default recharge interval
- default recharge amount
- default auto-recharge enabled

This table should override template defaults at runtime without moving balance source-of-truth out of modular config.

### 11.1 Behavior of global edits

Recommended live behavior:

- changing `capacity`
  - updates active pools immediately
  - clamps `current_charges` down if above the new maximum
  - does not grant free charges automatically
- changing `recharge interval` or `recharge amount`
  - applies immediately to active pools
- changing `starting charges`
  - affects only future pool creation/reset by default
- toggling master recharge off
  - freezes future recharge ticks
  - preserves current charges
- enabling `manual-only`
  - disables recharge regardless of template defaults
  - exposes that state in live player rows and HUD text

## 12. Game Rule Panel: active player management

Game Rule Panel also needs a live list of current RTO controllers.

Recommended row data for each active RTO:

- player name / ckey
- job / support profile
- selected templates
- one row per active package pool
- current charges
- max charges
- auto-recharge enabled
- next recharge in
- manual-only flag

Recommended GM actions per player per pool:

- set current charges
- add charges
- subtract charges
- set max charges
- refill to max
- empty to zero
- toggle auto-recharge
- toggle manual-only for this player or this pool
- reset player pool to template default

Recommended GM actions per player:

- refill all selected pools
- empty all selected pools
- enable recharge for all pools
- disable recharge for all pools

### 12.1 Manual-only GM workflow

The required moderation workflow is:

1. GM enables `manual-only` globally or disables recharge for a specific player.
2. Player charge pools stop refilling.
3. GM monitors current pool state in Game Rule Panel.
4. GM manually grants charges to one or more RTO players as needed.

In this mode:

- runtime must not silently refill resource
- HUD and panel must clearly show that recharge is disabled
- the player should understand that the package is waiting for command authorization, not natural recharge

Recommended player-facing wording:

- `Пополнение отключено`
- `Заряды выдаются вручную`

## 13. Validation and runtime messaging

`modular/rto_support/code/services/validation_service.dm` will need new failure reasons for migrated templates:

- not enough package charges
- recharge disabled
- manual-only mode active
- local lockout still active

Examples:

- `Недостаточно зарядов пакета: нужно 3, доступно 2.`
- `Пополнение пакета отключено. Заряды выдаются вручную.`
- `Способность ещё стабилизируется: 2 сек.`

## 14. Migration strategy

### Stage 1

- add new config fields
- add runtime pool datum
- keep legacy cooldown runtime intact
- keep zone runtime timed
- support both legacy and migrated templates

### Stage 2

- update UI DTO and HUD builders to branch by resource mode
- migrate one or two packages first
- recommended first packages:
  - `logistics`
  - `mortar`

### Stage 3

- expand Game Rule Panel with:
  - global charge settings
  - live player pool management
- add unit tests for hybrid and manual-only flows

### Stage 4

- migrate more packages:
  - `heavy`
  - `cas`
  - utility/HALO packages

### Stage 5

- revisit whether zone runtime needs a second independent pool
- only after support pools prove stable

## 15. Implementation notes

Expected code touchpoints for the future implementation:

- `modular/rto_support/code/config/template.dm`
- `modular/rto_support/code/config/action_template.dm`
- `modular/rto_support/code/controller/controller.dm`
- `modular/rto_support/code/services/validation_service.dm`
- `modular/rto_support/code/ui/ui_contracts.dm`
- `modular/rto_support/code/ui/preset_menu.dm`
- `modular/rto_support/code/actions/rto_actions.dm`
- `modular/rto_support/code/items/rto_binoculars.dm`
- `modular/game_rule_panel/code/state/game_rule_state.dm`
- `modular/game_rule_panel/code/ui/game_rule_panel.dm`
- `tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx`
- `tgui/packages/tgui/interfaces/GameRulePanel.jsx`
- `code/modules/unit_tests/game_rule_panel.dm`
- `code/modules/unit_tests/halo_ammo_drops.dm`

## 16. Key risks

- mixing support resource with zone resource too early
- confusing players with half-changed cooldown and charge language
- accidental free refill when a GM changes capacity or recharge values
- hidden per-player overrides that are not visible in Game Rule Panel

## 17. Recommended follow-up

The next practical step after this RFC is a code-oriented implementation plan that lists:

- new datum names
- new controller proc names
- UI DTO additions
- exact unit test cases
- rollout order for the first migrated packages

## 18. Concrete implementation plan

This section breaks the RFC into code-sized work slices.

### 18.1 Phase 0: groundwork

Goal:

- add the new resource model without changing live gameplay yet

Files:

- `modular/rto_support/code/config/template.dm`
- `modular/rto_support/code/config/action_template.dm`
- `modular/rto_support/code/controller/controller.dm`
- `modular/rto_support/code/services/validation_service.dm`
- `code/modules/unit_tests/halo_ammo_drops.dm`

Deliverables:

- new config fields compile and have safe defaults
- controller can hold pool state
- legacy templates still behave exactly as before

### 18.2 Phase 1: runtime pool state

Goal:

- introduce runtime support pools without switching any package to them yet

Recommended new file:

- `modular/rto_support/code/runtime/resource_pool_state.dm`

Recommended datum:

- `/datum/rto_support_resource_pool_state`

Recommended proc surface:

- `sync_from_template(template, rules)`
- `get_current_charges()`
- `get_capacity()`
- `can_pay(cost)`
- `pay(cost)`
- `set_current_charges(value)`
- `adjust_current_charges(delta)`
- `set_capacity(value, clamp_current = TRUE)`
- `set_auto_recharge_enabled(enabled)`
- `get_next_recharge_in()`
- `process_recharge(world_time)`
- `reset_to_starting_charges()`

### 18.3 Phase 2: controller integration

Goal:

- let controllers manage support pools in parallel with legacy cooldown state

Recommended controller additions in `modular/rto_support/code/controller/controller.dm`:

- vars:
  - `list/support_pools_by_id`
  - `support_pool_tick_timer_id`
- helpers:
  - `get_template_resource_mode(template_type = null)`
  - `get_support_pool_id(template_type)`
  - `get_support_pool(template_type, create_if_missing = FALSE)`
  - `ensure_support_pools_for_selected_templates()`
  - `remove_support_pool(template_type)`
  - `process_support_pool_recharge()`
  - `apply_support_pool_rules_update()`
  - `apply_support_pool_admin_override(...)`
  - `get_support_pool_current_charges(template_type)`
  - `get_support_pool_capacity(template_type)`
  - `get_support_pool_cost(action_template)`
  - `get_support_pool_next_recharge_in(template_type)`
  - `is_support_pool_manual_only(template_type)`

Existing proc changes:

- `ensure_runtime()`
  - initialize `support_pools_by_id`
- `select_template()`
  - create pool if the selected template uses charges
- `reset_templates()`
  - clear pools
- `prune_selected_templates_to_limit()`
  - remove pool state for pruned templates
- `apply_rules_update()`
  - propagate runtime rule changes into active pools
- `needs_hud_tick()`
  - return `TRUE` if recharge or local lockout is ticking

### 18.4 Phase 3: support action execution path

Goal:

- branch support execution by template resource mode

Recommended split in `controller.dm`:

- new proc `try_execute_support_call_with_legacy_cooldowns(...)`
- new proc `try_execute_support_call_with_charges(...)`
- new proc `apply_support_call_lockout(action_template)`

Recommended runtime rule:

- if template mode is `legacy_cooldown`
  - keep current flow
- if template mode is `charges` or `hybrid`
  - validate pool
  - subtract `support_pool_cost`
  - apply `personal_lockout`
  - skip package shared cooldown write

The current post-dispatch block:

- write to `shared_cooldowns_by_template`
- write to `action_cooldowns`

should become mode-aware instead of being unconditional.

### 18.5 Phase 4: validation service

Goal:

- make validation understand charge-based support actions

File:

- `modular/rto_support/code/services/validation_service.dm`

Recommended additions:

- `validate_support_resource(controller, template, action_template)`
- `build_support_resource_failure(...)`

Recommended branch:

- legacy templates keep `get_remaining_shared_cooldown()` checks
- migrated templates check:
  - enough pool charges
  - recharge state
  - manual-only state
  - local lockout state

Zone validation should stay separate.

### 18.6 Phase 5: UI DTO and HUD state

Goal:

- expose both legacy cooldown and charge data without breaking old templates

Files:

- `modular/rto_support/code/ui/ui_contracts.dm`
- `modular/rto_support/code/config/template.dm`
- `modular/rto_support/code/config/action_template.dm`
- `modular/rto_support/code/actions/rto_actions.dm`
- `modular/rto_support/code/items/rto_binoculars.dm`
- `tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx`

Recommended DTO additions:

- on preset entry:
  - `resource_mode`
  - `pool_capacity`
  - `pool_starting_charges`
  - `pool_current_charges`
  - `pool_recharge_interval`
  - `pool_recharge_amount`
  - `pool_auto_recharge`
  - `pool_manual_only`
  - `pool_next_recharge_in`
- on action entry:
  - `support_pool_cost`
  - `personal_lockout`

Recommended new controller state builders:

- `build_support_resource_state(action_id, template_type)`
- `get_support_button_primary_label(action_id, template_type)`

Recommended label priority for charge templates:

1. `Наведение`
2. `Нет сектора`
3. `Нужно: N`
4. `Лок: Ns`
5. `Заряды: X/Y`
6. `Готово`

### 18.7 Phase 6: Game Rule Panel global settings

Goal:

- add global charge controls before live player editing

Files:

- `modular/game_rule_panel/code/state/game_rule_state.dm`
- `modular/game_rule_panel/code/ui/game_rule_panel.dm`
- `tgui/packages/tgui/interfaces/GameRulePanel.jsx`
- `code/modules/unit_tests/game_rule_panel.dm`

Recommended new state fields:

- `rto_support_resource_mode`
- `rto_charge_recharge_enabled`
- `rto_charge_recharge_multiplier`
- `rto_charge_capacity_multiplier`
- `rto_charge_manual_only`
- `rto_template_charge_overrides`

Recommended state helpers:

- `sanitize_rto_resource_mode(value)`
- `sanitize_rto_charge_multiplier(value)`
- `get_rto_template_charge_override(template_id)`
- `set_rto_template_charge_override(template_id, field, value)`
- `reset_rto_charge_rules()`

Recommended UI actions:

- `set_rto_support_resource_mode`
- `set_rto_charge_recharge_enabled`
- `set_rto_charge_recharge_multiplier`
- `set_rto_charge_capacity_multiplier`
- `set_rto_charge_manual_only`
- `set_rto_template_charge_override`
- `reset_rto_charge_rules`

### 18.8 Phase 7: Game Rule Panel live player management

Goal:

- let GMs inspect and edit active RTO charge state per player

Files:

- `modular/rto_support/code/controller/registry.dm`
- `modular/game_rule_panel/code/ui/game_rule_panel.dm`
- `tgui/packages/tgui/interfaces/GameRulePanel.jsx`
- `code/modules/unit_tests/game_rule_panel.dm`

Recommended registry additions:

- `build_active_rto_charge_admin_data()`
- `find_controller_by_ckey(ckey)`

Recommended controller admin procs:

- `build_admin_charge_data()`
- `set_template_pool_current_charges(template_id, value, admin_ckey = null)`
- `adjust_template_pool_current_charges(template_id, delta, admin_ckey = null)`
- `set_template_pool_capacity(template_id, value, admin_ckey = null)`
- `set_template_pool_auto_recharge(template_id, enabled, admin_ckey = null)`
- `set_template_pool_manual_only(template_id, enabled, admin_ckey = null)`
- `reset_template_pool_to_defaults(template_id, admin_ckey = null)`
- `refill_all_template_pools(admin_ckey = null)`
- `empty_all_template_pools(admin_ckey = null)`

Recommended UI actions in `game_rule_panel.dm`:

- `set_rto_player_pool_current_charges`
- `adjust_rto_player_pool_current_charges`
- `set_rto_player_pool_capacity`
- `set_rto_player_pool_auto_recharge`
- `set_rto_player_pool_manual_only`
- `reset_rto_player_pool`
- `refill_rto_player_pools`
- `empty_rto_player_pools`

### 18.9 Phase 8: first migrated packages

Recommended rollout order:

1. `logistics`
2. `mortar`
3. `heavy`
4. `cas`

Reasoning:

- `logistics` is the simplest and best for validating manual-only GM supply flows
- `mortar` is the clearest example of weighted shared ammo
- `heavy` and `cas` are more sensitive to UX wording and “need X charges” states

## 19. Suggested file map

Suggested write set for the first implementation branch:

- `modular/rto_support/code/runtime/resource_pool_state.dm`
- `modular/rto_support/code/config/template.dm`
- `modular/rto_support/code/config/action_template.dm`
- `modular/rto_support/code/controller/controller.dm`
- `modular/rto_support/code/controller/registry.dm`
- `modular/rto_support/code/services/validation_service.dm`
- `modular/rto_support/code/ui/ui_contracts.dm`
- `modular/rto_support/code/ui/preset_menu.dm`
- `modular/rto_support/code/actions/rto_actions.dm`
- `modular/rto_support/code/items/rto_binoculars.dm`
- `modular/game_rule_panel/code/state/game_rule_state.dm`
- `modular/game_rule_panel/code/ui/game_rule_panel.dm`
- `tgui/packages/tgui/interfaces/RtoSupportPresetMenu.jsx`
- `tgui/packages/tgui/interfaces/GameRulePanel.jsx`
- `code/modules/unit_tests/game_rule_panel.dm`
- `code/modules/unit_tests/halo_ammo_drops.dm`

## 20. Test matrix

Recommended test additions:

### 20.1 Controller runtime

- creating a charge pool when a charge-based template is selected
- not creating a charge pool for a legacy template
- subtracting cost on successful dispatch
- refusing a heavy action if current charges are too low
- local lockout blocking only the triggering action
- recharge restoring charges over time
- manual-only mode preventing recharge

### 20.2 Package behavior

- logistics `1/1` pool empties after one use
- mortar shared pool decreases across HE, smoke, and incendiary together
- heavy large-cost action is blocked after spending lighter-cost action

### 20.3 Game Rule Panel

- toggling global recharge off freezes active pools
- enabling manual-only prevents future refill
- changing capacity clamps current charges but does not gift charges
- editing current charges of an active RTO updates controller state immediately
- per-player manual-only override does not affect another RTO

### 20.4 Legacy compatibility

- non-migrated templates still use legacy cooldown logic
- zone cooldown behavior is unchanged for migrated and non-migrated templates
- preset slot reset logic remains unchanged

## 21. Recommended first implementation ticket split

The first coding pass should be split into these tickets:

1. Runtime pool datum and template/action config fields
2. Controller integration with legacy-compatible branching
3. Support HUD and preset DTO changes
4. Game Rule Panel global charge settings
5. Game Rule Panel live player charge management
6. Migrate `logistics`
7. Migrate `mortar`
8. Expand tests and docs
