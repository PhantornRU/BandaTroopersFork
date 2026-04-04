/datum/modpack/game_rule_panel
	name = "game rule panel modpack"
	desc = "Standalone TGUI panel for runtime RTO Support and Fire Support rules."
	author = "Codex"

/datum/modpack/game_rule_panel/pre_initialize()
	. = ..()

/datum/modpack/game_rule_panel/initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MODE_PREGAME_LOBBY, PROC_REF(handle_pregame_lobby))

/datum/modpack/game_rule_panel/proc/handle_pregame_lobby(subsystem)
	SIGNAL_HANDLER

	GLOB.game_rule_state?.reset_player_survival_for_new_round()

/datum/modpack/game_rule_panel/post_initialize()
	. = ..()
