/datum/unit_test/gc_regressions
	var/list/created_accounts
	var/list/created_squads
	var/list/created_squad_ids

/datum/unit_test/gc_regressions/New()
	. = ..()
	created_accounts = list()
	created_squads = list()
	created_squad_ids = list()

/datum/unit_test/gc_regressions/Destroy()
	for(var/datum/money_account/account as anything in created_accounts)
		GLOB.all_money_accounts -= account
		if(!QDELETED(account))
			qdel(account)

	for(var/squad_id as anything in created_squad_ids)
		var/datum/human_ai_squad/lingering_squad
		if(SShuman_ai && islist(SShuman_ai.squad_id_dict))
			lingering_squad = SShuman_ai.squad_id_dict["[squad_id]"]
		if(lingering_squad)
			SShuman_ai.squads -= lingering_squad
			SShuman_ai.squad_id_dict -= "[squad_id]"
			if(!QDELETED(lingering_squad))
				qdel(lingering_squad, force = TRUE)

	for(var/datum/human_ai_squad/squad as anything in created_squads)
		if(!QDELETED(squad))
			qdel(squad, force = TRUE)

	return ..()

/datum/unit_test/gc_regressions/proc/get_any_paygrade()
	for(var/paygrade_id in GLOB.paygrades)
		var/datum/paygrade/paygrade = GLOB.paygrades[paygrade_id]
		if(paygrade)
			return paygrade

	return null

/datum/unit_test/gc_regressions/Run()
	return

/datum/unit_test/gc_regressions_account_owner_snapshot
	parent_type = /datum/unit_test/gc_regressions

/datum/unit_test/gc_regressions_account_owner_snapshot/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	human.real_name = "GC Account Tester"
	human.name = human.real_name

	var/datum/paygrade/paygrade = get_any_paygrade()
	TEST_ASSERT_NOTNULL(paygrade, "Failed to resolve a paygrade for the money-account GC regression test.")

	var/datum/money_account/account = create_account(human, 10, paygrade)
	created_accounts += account

	TEST_ASSERT(istext(account.owner_name), "Money account owner_name should be stored as plain text.")
	TEST_ASSERT_EQUAL(account.owner_name, human.real_name, "Money account owner_name should snapshot the human name instead of retaining the mob ref.")
	TEST_ASSERT(length(account.transaction_log) >= 1, "Money account creation should seed an initial transaction.")

	var/datum/transaction/transaction = account.transaction_log[1]
	TEST_ASSERT(istext(transaction.target_name), "Initial money account transaction target_name should be stored as plain text.")
	TEST_ASSERT_EQUAL(transaction.target_name, human.real_name, "Initial money account transaction should snapshot the human name instead of retaining the mob ref.")

/datum/unit_test/gc_regressions_human_ai_squad_cleanup
	parent_type = /datum/unit_test/gc_regressions

/datum/unit_test/gc_regressions_human_ai_squad_cleanup/Run()
	var/datum/human_ai_squad/squad = SShuman_ai.create_new_squad()
	TEST_ASSERT_NOTNULL(squad, "Failed to create a Human AI squad for GC cleanup regression testing.")

	created_squads += squad
	created_squad_ids += squad.id

	var/squad_key = "[squad.id]"
	TEST_ASSERT_EQUAL(SShuman_ai.get_squad(squad_key), squad, "Freshly created Human AI squad was not indexed by its id.")

	qdel(squad, force = TRUE)

	TEST_ASSERT(QDELETED(squad), "Human AI squad should qdel immediately during the cleanup regression test.")
	TEST_ASSERT(!(squad_key in SShuman_ai.squad_id_dict), "Human AI squad id should be removed from squad_id_dict during Destroy().")
	TEST_ASSERT(!(squad in SShuman_ai.squads), "Human AI squad should be removed from the subsystem squad list during Destroy().")
	TEST_ASSERT_NULL(SShuman_ai.get_squad(squad_key), "Human AI squad lookup should return null after qdel cleanup.")
