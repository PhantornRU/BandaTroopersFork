/atom/movable/screen/text/round_cinematics
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_HUD_PLANE
	layer = ABOVE_HUD_LAYER + 0.25
	maptext_height = ROUND_CINEMATICS_TEXT_HEIGHT
	maptext_width = ROUND_CINEMATICS_TEXT_WIDTH
	maptext_x = -(ROUND_CINEMATICS_TEXT_WIDTH / 2)
	maptext_y = -(ROUND_CINEMATICS_TEXT_HEIGHT / 2)
	screen_loc = "CENTER"
	appearance_flags = NO_CLIENT_COLOR|PIXEL_SCALE
	clear_with_screen = FALSE

	var/client/player
	var/text_to_play
	var/fade_in_time = 0
	var/fade_out_delay = ROUND_CINEMATICS_TEXT_HOLD
	var/fade_out_time = 0.75 SECONDS
	var/play_delay = ROUND_CINEMATICS_TEXT_DELAY
	var/letters_per_update = ROUND_CINEMATICS_TEXT_LETTERS
	var/style_open = "<span class='langchat' style='text-align:center; font-family:\"Courier New\", monospace; font-size:12pt;'>"
	var/style_close = "</span>"
	var/cancelled = FALSE

/atom/movable/screen/text/round_cinematics/proc/abort_play()
	cancelled = TRUE
	if(player)
		player.remove_from_screen(src)
		player = null
	qdel(src)

/atom/movable/screen/text/round_cinematics/proc/play_to_client()
	if(!player || QDELETED(player) || cancelled)
		qdel(src)
		return

	player.add_to_screen(src)
	if(fade_in_time)
		animate(src, alpha = 255, time = fade_in_time)

	var/list/lines_to_skip = list()
	var/static/html_locate_regex = regex("<.*>")
	var/tag_position = findtext(text_to_play, html_locate_regex)
	var/reading_tag = TRUE
	while(tag_position)
		if(reading_tag)
			if(text_to_play[tag_position] == ">")
				reading_tag = FALSE
			lines_to_skip += tag_position
			tag_position++
		else
			tag_position = findtext(text_to_play, html_locate_regex, tag_position)
			reading_tag = TRUE

	for(var/letter = 2 to length(text_to_play) + letters_per_update step letters_per_update)
		if(cancelled || !player || QDELETED(player))
			qdel(src)
			return
		if(letter in lines_to_skip)
			continue
		maptext = "[style_open][copytext_char(text_to_play, 1, letter)][style_close]"
		sleep(play_delay)

	if(cancelled || !player || QDELETED(player))
		qdel(src)
		return

	addtimer(CALLBACK(src, PROC_REF(after_play)), fade_out_delay)

/atom/movable/screen/text/round_cinematics/proc/after_play()
	if(cancelled || !player || QDELETED(player))
		qdel(src)
		return

	if(!fade_out_time)
		end_play()
		return

	animate(src, alpha = 0, time = fade_out_time)
	addtimer(CALLBACK(src, PROC_REF(end_play)), fade_out_time)

/atom/movable/screen/text/round_cinematics/proc/end_play()
	if(player)
		player.remove_from_screen(src)
		player = null
	qdel(src)

/proc/round_cinematics_show_text(client/target_client, text, color = "#FFFFFF", letters_per_update = ROUND_CINEMATICS_TEXT_LETTERS, play_delay = ROUND_CINEMATICS_TEXT_DELAY, hold_time = ROUND_CINEMATICS_TEXT_HOLD, fade_out_time = 0.75 SECONDS)
	if(!istype(target_client))
		return null

	var/atom/movable/screen/text/round_cinematics/text_box = new
	text_box.text_to_play = text
	text_box.player = target_client
	text_box.color = color
	text_box.letters_per_update = max(1, letters_per_update)
	text_box.play_delay = play_delay
	text_box.fade_out_delay = hold_time
	text_box.fade_out_time = fade_out_time
	INVOKE_ASYNC(text_box, TYPE_PROC_REF(/atom/movable/screen/text/round_cinematics, play_to_client))
	return text_box

