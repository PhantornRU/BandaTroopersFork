/datum/unit_test/game_rule_panel
	var/snapshot_rto_support_enabled
	var/snapshot_rto_shared_cooldown_multiplier
	var/snapshot_rto_personal_cooldown_multiplier
	var/snapshot_fire_support_enabled
	var/snapshot_player_survival_enabled
	var/snapshot_player_survival_crit_grace_seconds
	var/snapshot_player_survival_antigib_enabled
	var/snapshot_player_survival_antigib_limb_loss_chance
	var/snapshot_fire_support_defaults_captured
	var/list/snapshot_fire_support_default_points
	var/list/snapshot_fire_support_default_availability
	var/list/snapshot_fire_support_points
	var/list/snapshot_fire_support_flags

/datum/unit_test/game_rule_panel/Run()
	return

/datum/unit_test/game_rule_panel/New()
	. = ..()

	var/datum/game_rule_state/rules = GLOB.game_rule_state
	snapshot_rto_support_enabled = rules.rto_support_enabled
	snapshot_rto_shared_cooldown_multiplier = rules.rto_shared_cooldown_multiplier
	snapshot_rto_personal_cooldown_multiplier = rules.rto_personal_cooldown_multiplier
	snapshot_fire_support_enabled = rules.fire_support_enabled
	snapshot_player_survival_enabled = rules.player_survival_enabled
	snapshot_player_survival_crit_grace_seconds = rules.player_survival_crit_grace_seconds
	snapshot_player_survival_antigib_enabled = rules.player_survival_antigib_enabled
	snapshot_player_survival_antigib_limb_loss_chance = rules.player_survival_antigib_limb_loss_chance
	snapshot_fire_support_defaults_captured = rules.fire_support_defaults_captured
	snapshot_fire_support_default_points = rules.fire_support_default_points ? rules.fire_support_default_points.Copy() : list()
	snapshot_fire_support_default_availability = rules.fire_support_default_availability ? rules.fire_support_default_availability.Copy() : list()
	snapshot_fire_support_points = GLOB.fire_support_points.Copy()
	snapshot_fire_support_flags = list()

	for(var/fire_support_type in GLOB.fire_support_types)
		var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
		if(!fire_support_option)
			continue
		snapshot_fire_support_flags[fire_support_type] = fire_support_option.fire_support_flags

/datum/unit_test/game_rule_panel/Destroy()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.rto_support_enabled = snapshot_rto_support_enabled
	rules.rto_shared_cooldown_multiplier = snapshot_rto_shared_cooldown_multiplier
	rules.rto_personal_cooldown_multiplier = snapshot_rto_personal_cooldown_multiplier
	rules.fire_support_enabled = snapshot_fire_support_enabled
	rules.player_survival_enabled = snapshot_player_survival_enabled
	rules.player_survival_crit_grace_seconds = snapshot_player_survival_crit_grace_seconds
	rules.player_survival_antigib_enabled = snapshot_player_survival_antigib_enabled
	rules.player_survival_antigib_limb_loss_chance = snapshot_player_survival_antigib_limb_loss_chance
	rules.fire_support_defaults_captured = snapshot_fire_support_defaults_captured
	rules.fire_support_default_points = snapshot_fire_support_default_points.Copy()
	rules.fire_support_default_availability = snapshot_fire_support_default_availability.Copy()

	if(!islist(GLOB.fire_support_points))
		GLOB.fire_support_points = list()
	else
		GLOB.fire_support_points.Cut()
	for(var/faction in snapshot_fire_support_points)
		GLOB.fire_support_points[faction] = snapshot_fire_support_points[faction]

	for(var/fire_support_type in snapshot_fire_support_flags)
		var/datum/fire_support/fire_support_option = GLOB.fire_support_types[fire_support_type]
		if(!fire_support_option)
			continue
		fire_support_option.fire_support_flags = snapshot_fire_support_flags[fire_support_type]

	return ..()

/datum/unit_test/game_rule_panel/proc/count_player_survival_extremities(mob/living/carbon/human/human)
	. = 0
	if(!human)
		return

	var/static/list/extremity_zones = list(
		"l_hand",
		"r_hand",
		"l_foot",
		"r_foot"
	)

	for(var/zone in extremity_zones)
		var/obj/limb/limb = human.get_limb(zone)
		if(!limb)
			continue
		if(limb.status & LIMB_DESTROYED)
			continue
		.++

/mob/living/carbon/human/game_rule_panel_player_survival_test
/mob/living/carbon/human/game_rule_panel_player_survival_test/player_survival_is_protected_player()
	return TRUE

/mob/living/carbon/human/game_rule_panel_player_survival_test/player_survival_log_event(log_text, admin_text = null, notify_admins = FALSE)
	return

/datum/unit_test/game_rule_panel_rto_cooldowns
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_rto_cooldowns/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_rto_rules()

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)
	var/datum/rto_support_action_template/mortar_he/action_template = allocate(/datum/rto_support_action_template/mortar_he)

	rules.rto_shared_cooldown_multiplier = 2
	rules.rto_personal_cooldown_multiplier = 3

	TEST_ASSERT_EQUAL(controller.get_effective_shared_cooldown(action_template), 80, "Shared cooldown multiplier did not affect future cooldown calculations.")
	TEST_ASSERT_EQUAL(controller.get_effective_personal_cooldown(action_template), 240, "Personal cooldown multiplier did not affect future cooldown calculations.")

	controller.shared_cooldowns_by_template["mortar"] = world.time + controller.get_effective_shared_cooldown(action_template)
	controller.action_cooldowns[action_template.action_id] = world.time + controller.get_effective_personal_cooldown(action_template)

	var/previous_shared_until = controller.shared_cooldowns_by_template["mortar"]
	var/previous_personal_until = controller.action_cooldowns[action_template.action_id]

	rules.rto_shared_cooldown_multiplier = 5
	rules.rto_personal_cooldown_multiplier = 6

	TEST_ASSERT_EQUAL(controller.shared_cooldowns_by_template["mortar"], previous_shared_until, "Existing shared cooldown was recalculated after multiplier change.")
	TEST_ASSERT_EQUAL(controller.action_cooldowns[action_template.action_id], previous_personal_until, "Existing personal cooldown was recalculated after multiplier change.")

/datum/unit_test/game_rule_panel_rto_disable
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_rto_disable/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_rto_rules()
	rules.rto_support_enabled = FALSE

	var/mob/living/carbon/human/select_human = allocate(/mob/living/carbon/human)
	select_human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/select_controller = allocate(/datum/rto_support_controller, select_human)
	TEST_ASSERT(!select_controller.can_open_template_menu(), "Preset selection remained available while RTO support was disabled.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.job = JOB_SQUAD_RTO
	var/datum/rto_support_controller/controller = allocate(/datum/rto_support_controller, human)
	var/datum/rto_support_template/mortar/template = allocate(/datum/rto_support_template/mortar)
	controller.selected_templates += template

	var/datum/rto_support_action_template/action_template = template.get_action_template("mortar_he")
	TEST_ASSERT_NOTNULL(action_template, "Failed to retrieve RTO action template for disable rules test.")

	controller.active_zone = allocate(/datum/rto_visibility_zone, human, run_loc_floor_bottom_left, template)
	// controller.armed_action_id = "__visibility_zone__"
	controller.armed_action_id = RTO_SUPPORT_ARM_VISIBILITY_ZONE // switched unit test back to shared hardcode define
	controller.armed_template_id = "mortar"
	controller.apply_rules_update()

	TEST_ASSERT_NULL(controller.active_zone, "Active RTO visibility zone was not cleared after disabling support.")
	TEST_ASSERT_NULL(controller.armed_action_id, "Restricted armed action remained armed after disabling support.")
	TEST_ASSERT_EQUAL(controller.zone_shared_cooldown_until, 0, "Disabling RTO support applied a new visibility zone cooldown.")
	// TEST_ASSERT(controller.can_arm_action("__coordinates__"), "Coordinates action should remain available when RTO support is disabled.")
	TEST_ASSERT(controller.can_arm_action(RTO_SUPPORT_ARM_COORDINATES), "Coordinates action should remain available when RTO support is disabled.") // switched unit test back to shared hardcode define
	// TEST_ASSERT(controller.can_arm_action("__manual_marker__"), "Manual marker action should remain available when RTO support is disabled.")
	TEST_ASSERT(controller.can_arm_action(RTO_SUPPORT_ARM_MARKER), "Manual marker action should remain available when RTO support is disabled.") //  switched unit test back to shared hardcode define
	TEST_ASSERT(!controller.can_arm_action(action_template.action_id), "Strike action remained armable while RTO support was disabled.")

	var/list/visibility_state = controller.build_visibility_action_state("mortar")
	TEST_ASSERT(visibility_state["is_disabled"], "Visibility action state was not disabled by game rules.")
	TEST_ASSERT_EQUAL(visibility_state["primary_label"], "Disabled by Game Rule Panel", "Visibility action did not show the expected Game Rule Panel block reason.")

	var/list/support_state = controller.build_support_action_state(action_template.action_id, "mortar")
	TEST_ASSERT(support_state["is_disabled"], "Support action state was not disabled by game rules.")
	TEST_ASSERT_EQUAL(support_state["primary_label"], "Disabled by Game Rule Panel", "Support action did not show the expected Game Rule Panel block reason.")

/datum/unit_test/game_rule_panel_fire_support_master_toggle
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_fire_support_master_toggle/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_fire_support_rules()
	rules.fire_support_enabled = TRUE

	var/datum/fire_support/fire_support_option = GLOB.fire_support_types[FIRESUPPORT_TYPE_GUN]
	TEST_ASSERT_NOTNULL(fire_support_option, "Failed to find fire support datum for master toggle test.")

	var/original_flags = fire_support_option.fire_support_flags
	rules.fire_support_enabled = FALSE

	TEST_ASSERT_EQUAL(fire_support_option.fire_support_flags, original_flags, "Master toggle rewrote individual fire support availability flags.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/device/binoculars/fire_support/binoculars = allocate(/obj/item/device/binoculars/fire_support)
	binoculars.mode = fire_support_option

	TEST_ASSERT(!binoculars.bino_checks(run_loc_floor_bottom_left, human), "Fire support binoculars were not blocked by the master toggle.")

	rules.fire_support_enabled = TRUE

/datum/unit_test/game_rule_panel_fire_support_points
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_fire_support_points/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_fire_support_rules()
	GLOB.fire_support_points[FACTION_MARINE] = 0

	TEST_ASSERT(rules.grant_fire_support_points(FACTION_MARINE, 7), "Granting fire support points returned FALSE.")
	TEST_ASSERT_EQUAL(GLOB.fire_support_points[FACTION_MARINE], 7, "Fire support points were not added additively.")

/datum/unit_test/game_rule_panel_fire_support_toggle_entry
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_fire_support_toggle_entry/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_fire_support_rules()

	var/datum/fire_support/fire_support_option = GLOB.fire_support_types[FIRESUPPORT_TYPE_GUN]
	TEST_ASSERT_NOTNULL(fire_support_option, "Failed to find fire support datum for availability toggle test.")

	var/original_available = !!(fire_support_option.fire_support_flags & FIRESUPPORT_AVAILABLE)
	TEST_ASSERT(rules.set_fire_support_type_enabled(FIRESUPPORT_TYPE_GUN, !original_available), "Toggling fire support availability returned FALSE.")
	TEST_ASSERT_EQUAL(!!(fire_support_option.fire_support_flags & FIRESUPPORT_AVAILABLE), !original_available, "Fire support availability flag did not flip after panel toggle.")

	TEST_ASSERT(rules.set_fire_support_type_enabled(FIRESUPPORT_TYPE_GUN, original_available), "Failed to restore original fire support availability after toggle test.")

/datum/unit_test/game_rule_panel_player_survival_defaults
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_player_survival_defaults/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.player_survival_enabled = FALSE
	rules.player_survival_crit_grace_seconds = 99
	rules.player_survival_antigib_enabled = FALSE
	rules.player_survival_antigib_limb_loss_chance = 77
	rules.reset_player_survival_rules()

	TEST_ASSERT(rules.player_survival_enabled, "Player Survival reset did not restore Save Before Death.")
	TEST_ASSERT_EQUAL(rules.player_survival_crit_grace_seconds, 15, "Player Survival reset did not restore the default crit grace duration.")
	TEST_ASSERT(rules.player_survival_antigib_enabled, "Player Survival reset did not restore Anti-Gib Fallback.")
	TEST_ASSERT_EQUAL(rules.player_survival_antigib_limb_loss_chance, 30, "Player Survival reset did not restore the default limb loss chance.")

/datum/unit_test/game_rule_panel_player_survival_runtime_duration
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_player_survival_runtime_duration/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_player_survival_rules()
	rules.player_survival_crit_grace_seconds = 42

	var/mob/living/carbon/human/game_rule_panel_player_survival_test/human = allocate(/mob/living/carbon/human/game_rule_panel_player_survival_test)
	TEST_ASSERT_EQUAL(human.player_survival_get_crit_grace_seconds(), 42, "Player Survival crit grace duration did not read from Game Rule Panel runtime state.")

/datum/unit_test/game_rule_panel_player_survival_damage_block_toggle
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_player_survival_damage_block_toggle/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_player_survival_rules()

	var/mob/living/carbon/human/game_rule_panel_player_survival_test/human = allocate(/mob/living/carbon/human/game_rule_panel_player_survival_test)
	human.player_survival_damage_block_until = world.time + 50

	TEST_ASSERT(human.player_survival_is_damage_blocked(), "Active crit grace should block damage while Save Before Death is enabled.")

	rules.player_survival_enabled = FALSE
	TEST_ASSERT(!human.player_survival_is_damage_blocked(), "Disabling Save Before Death should immediately disable active crit grace blocking.")

/datum/unit_test/game_rule_panel_player_survival_antigib_gib_toggle
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_player_survival_antigib_gib_toggle/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_player_survival_rules()
	rules.player_survival_antigib_enabled = FALSE

	var/mob/living/carbon/human/game_rule_panel_player_survival_test/human = allocate(/mob/living/carbon/human/game_rule_panel_player_survival_test)
	human.gib(create_cause_data("unit test"))

	TEST_ASSERT(QDELETED(human), "Disabling Anti-Gib Fallback should restore normal gib behavior for human.gib().")

/datum/unit_test/game_rule_panel_player_survival_antigib_explosion_toggle
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_player_survival_antigib_explosion_toggle/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_player_survival_rules()
	rules.player_survival_antigib_enabled = FALSE

	var/mob/living/carbon/human/game_rule_panel_player_survival_test/human = allocate(/mob/living/carbon/human/game_rule_panel_player_survival_test)
	human.ex_act(EXPLOSION_THRESHOLD_GIB + 1, null, create_cause_data("unit test"))

	TEST_ASSERT(QDELETED(human), "Disabling Anti-Gib Fallback should restore normal gib behavior for explosion entrypoints.")

/datum/unit_test/game_rule_panel_player_survival_antigib_without_grace
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_player_survival_antigib_without_grace/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_player_survival_rules()
	rules.player_survival_enabled = FALSE
	rules.player_survival_antigib_enabled = TRUE
	rules.player_survival_antigib_limb_loss_chance = 0

	var/mob/living/carbon/human/game_rule_panel_player_survival_test/human = allocate(/mob/living/carbon/human/game_rule_panel_player_survival_test)
	TEST_ASSERT(human.player_survival_apply_non_gib_fallback(create_cause_data("unit test"), EXPLOSION_THRESHOLD_GIB, EXPLOSION_THRESHOLD_GIB, TRUE), "Anti-Gib Fallback did not trigger while enabled.")
	TEST_ASSERT(!QDELETED(human), "Anti-Gib Fallback should keep the mob alive when Save Before Death is disabled.")
	TEST_ASSERT_EQUAL(human.player_survival_damage_block_until, 0, "Anti-Gib Fallback should not start crit grace when Save Before Death is disabled.")

/datum/unit_test/game_rule_panel_player_survival_limb_loss_boundaries
	parent_type = /datum/unit_test/game_rule_panel

/datum/unit_test/game_rule_panel_player_survival_limb_loss_boundaries/Run()
	var/datum/game_rule_state/rules = GLOB.game_rule_state
	rules.reset_player_survival_rules()
	rules.player_survival_enabled = FALSE
	rules.player_survival_antigib_enabled = TRUE

	var/mob/living/carbon/human/game_rule_panel_player_survival_test/human_zero = allocate(/mob/living/carbon/human/game_rule_panel_player_survival_test)
	var/before_zero = count_player_survival_extremities(human_zero)
	rules.player_survival_antigib_limb_loss_chance = 0
	TEST_ASSERT(human_zero.player_survival_apply_non_gib_fallback(create_cause_data("unit test zero"), EXPLOSION_THRESHOLD_GIB, EXPLOSION_THRESHOLD_GIB, TRUE), "Anti-Gib Fallback failed during 0% limb loss test.")
	TEST_ASSERT_EQUAL(count_player_survival_extremities(human_zero), before_zero, "0% limb loss chance should never detach an extremity.")

	var/mob/living/carbon/human/game_rule_panel_player_survival_test/human_full = allocate(/mob/living/carbon/human/game_rule_panel_player_survival_test)
	var/before_full = count_player_survival_extremities(human_full)
	rules.player_survival_antigib_limb_loss_chance = 100
	TEST_ASSERT(human_full.player_survival_apply_non_gib_fallback(create_cause_data("unit test full"), EXPLOSION_THRESHOLD_GIB, EXPLOSION_THRESHOLD_GIB, TRUE), "Anti-Gib Fallback failed during 100% limb loss test.")
	TEST_ASSERT_EQUAL(count_player_survival_extremities(human_full), before_full - 1, "100% limb loss chance should always detach exactly one extremity.")
