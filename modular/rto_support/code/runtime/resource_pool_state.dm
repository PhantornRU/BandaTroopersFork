/// Runtime state for one shared support resource pool.
/datum/rto_support_resource_pool_state
	var/pool_id
	var/template_id
	var/mob/living/carbon/human/owner
	var/capacity = 0
	var/current_charges = 0
	var/starting_charges = 0
	var/recharge_interval = 0
	var/recharge_amount = 0
	var/auto_recharge_enabled = TRUE
	var/manual_only = FALSE
	var/next_recharge_at = 0
	var/last_modified_by_admin_ckey = null
	var/config_initialized = FALSE

/datum/rto_support_resource_pool_state/proc/sync_configuration(new_pool_id, new_template_id, mob/living/carbon/human/new_owner, new_capacity, new_starting_charges, new_recharge_interval, new_recharge_amount, new_auto_recharge_enabled, new_manual_only, current_time = world.time)
	var/previous_recharge_interval = recharge_interval
	var/previous_next_recharge_at = next_recharge_at
	var/previous_can_recharge = config_initialized ? can_recharge() : FALSE
	if(config_initialized)
		process_recharge(current_time)
		previous_recharge_interval = recharge_interval
		previous_next_recharge_at = next_recharge_at
		previous_can_recharge = can_recharge()

	pool_id = new_pool_id
	template_id = new_template_id
	owner = new_owner
	capacity = max(0, round(new_capacity))
	starting_charges = clamp(round(new_starting_charges), 0, capacity)
	recharge_interval = max(0, round(new_recharge_interval))
	recharge_amount = max(0, round(new_recharge_amount))
	auto_recharge_enabled = !!new_auto_recharge_enabled
	manual_only = !!new_manual_only

	if(!config_initialized)
		current_charges = starting_charges
		config_initialized = TRUE
	else
		current_charges = clamp(round(current_charges), 0, capacity)

	if(!can_recharge())
		next_recharge_at = 0
	else if(current_charges >= capacity)
		next_recharge_at = 0
	else if(!previous_can_recharge || !previous_next_recharge_at)
		next_recharge_at = current_time + recharge_interval
	else if(previous_recharge_interval != recharge_interval)
		var/previous_remaining = max(0, previous_next_recharge_at - current_time)
		var/progress_ratio = previous_recharge_interval > 0 ? 1 - (previous_remaining / previous_recharge_interval) : 0
		progress_ratio = clamp(progress_ratio, 0, 1)
		var/new_remaining = max(1, round(recharge_interval * (1 - progress_ratio)))
		next_recharge_at = current_time + new_remaining
	else
		next_recharge_at = previous_next_recharge_at

	return TRUE

/datum/rto_support_resource_pool_state/proc/can_recharge()
	if(manual_only)
		return FALSE
	if(!auto_recharge_enabled)
		return FALSE
	if(recharge_interval <= 0 || recharge_amount <= 0)
		return FALSE
	return current_charges < capacity

/datum/rto_support_resource_pool_state/proc/process_recharge(current_time = world.time)
	if(!can_recharge())
		next_recharge_at = 0
		return current_charges

	if(!next_recharge_at)
		next_recharge_at = current_time + recharge_interval
		return current_charges

	while(can_recharge() && next_recharge_at && next_recharge_at <= current_time)
		current_charges = min(capacity, current_charges + recharge_amount)
		if(current_charges >= capacity)
			next_recharge_at = 0
			return current_charges
		next_recharge_at += recharge_interval

	return current_charges

/datum/rto_support_resource_pool_state/proc/get_current_charges(current_time = world.time)
	process_recharge(current_time)
	return current_charges

/datum/rto_support_resource_pool_state/proc/get_next_recharge_in(current_time = world.time)
	process_recharge(current_time)
	if(!next_recharge_at)
		return 0
	return max(0, next_recharge_at - current_time)

/datum/rto_support_resource_pool_state/proc/can_pay(cost, current_time = world.time)
	process_recharge(current_time)
	return current_charges >= max(0, round(cost))

/datum/rto_support_resource_pool_state/proc/pay(cost, current_time = world.time)
	var/safe_cost = max(0, round(cost))
	if(!can_pay(safe_cost, current_time))
		return FALSE

	current_charges = max(0, current_charges - safe_cost)
	if(can_recharge() && !next_recharge_at)
		next_recharge_at = current_time + recharge_interval
	return TRUE

/datum/rto_support_resource_pool_state/proc/set_current_charges(value, current_time = world.time)
	current_charges = clamp(round(value), 0, capacity)
	if(!can_recharge())
		next_recharge_at = 0
	else if(current_charges < capacity && !next_recharge_at)
		next_recharge_at = current_time + recharge_interval
	else if(current_charges >= capacity)
		next_recharge_at = 0
	return current_charges

/datum/rto_support_resource_pool_state/proc/adjust_current_charges(delta, current_time = world.time)
	return set_current_charges(current_charges + round(delta), current_time)

/datum/rto_support_resource_pool_state/proc/set_capacity(value, current_time = world.time)
	capacity = max(0, round(value))
	starting_charges = clamp(starting_charges, 0, capacity)
	current_charges = clamp(current_charges, 0, capacity)
	if(!can_recharge())
		next_recharge_at = 0
	else if(current_charges < capacity && !next_recharge_at)
		next_recharge_at = current_time + recharge_interval
	return capacity

/datum/rto_support_resource_pool_state/proc/set_auto_recharge_enabled(enabled, current_time = world.time)
	auto_recharge_enabled = !!enabled
	if(!can_recharge())
		next_recharge_at = 0
	else if(current_charges < capacity && !next_recharge_at)
		next_recharge_at = current_time + recharge_interval
	return auto_recharge_enabled

/datum/rto_support_resource_pool_state/proc/set_manual_only(enabled)
	manual_only = !!enabled
	if(manual_only)
		next_recharge_at = 0
	return manual_only
