/proc/round_cinematics_cleanup_session(datum/round_cinematics_session/session, reason = "cleanup")
	if(!session)
		return
	session.finish_session(reason)

/proc/round_cinematics_cleanup_client(client/target_client)
	if(!istype(target_client))
		return
	target_client.clear_screen()
