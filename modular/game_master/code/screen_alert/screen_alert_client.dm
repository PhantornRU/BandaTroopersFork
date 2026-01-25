/client/proc/screen_alert_menu_save_1()
	set name = "Send Screen Alert - Save 1"
	set category = "Game Master.Extras Screen Alert"

	if(!check_rights(R_ADMIN))
		return

	var/datum/screen_alert_save/datum = GLOB.screen_alert_save_1
	datum.choose_or_use_save(src)

/client/proc/screen_alert_menu_save_2()
	set name = "Send Screen Alert - Save 2"
	set category = "Game Master.Extras Screen Alert"

	if(!check_rights(R_ADMIN))
		return

	var/datum/screen_alert_save/datum = GLOB.screen_alert_save_2
	datum.choose_or_use_save(src)

/client/proc/screen_alert_menu_save_3()
	set name = "Send Screen Alert - Save 3"
	set category = "Game Master.Extras Screen Alert"

	if(!check_rights(R_ADMIN))
		return

	var/datum/screen_alert_save/datum = GLOB.screen_alert_save_3
	datum.choose_or_use_save(src)

/client/proc/screen_alert_menu_save_4()
	set name = "Send Screen Alert - Save 4"
	set category = "Game Master.Extras Screen Alert"

	if(!check_rights(R_ADMIN))
		return

	var/datum/screen_alert_save/datum = GLOB.screen_alert_save_4
	datum.choose_or_use_save(src)

/client/proc/screen_alert_menu_save_5()
	set name = "Send Screen Alert - Save 5"
	set category = "Game Master.Extras Screen Alert"

	if(!check_rights(R_ADMIN))
		return

	var/datum/screen_alert_save/datum = GLOB.screen_alert_save_5
	datum.choose_or_use_save(src)

/client/proc/screen_alert_menu_save_6()
	set name = "Send Screen Alert - Save 6"
	set category = "Game Master.Extras Screen Alert"

	if(!check_rights(R_ADMIN))
		return

	var/datum/screen_alert_save/datum = GLOB.screen_alert_save_6
	datum.choose_or_use_save(src)
