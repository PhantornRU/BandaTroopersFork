GLOBAL_DATUM_INIT(admin_music_service, /datum/admin_music_service, new)

/datum/admin_music_session
	var/owner_ckey
	var/source_kind
	var/audience_mode
	var/sound_type
	var/show_title_to_players = TRUE
	var/list/tracked_clients = list()
	var/source_url
	var/resolved_url
	var/resolved_title
	var/start_time
	var/end_time
	var/loop = FALSE
	var/preset_id
	var/preset_name
	var/tier_id
	var/tier_name
	var/variant_id
	var/variant_title
	var/must_send_assets = FALSE
	var/asset_name
	var/takeover = FALSE

/datum/admin_music_session/proc/to_ui_data()
	return list(
		"source_kind" = source_kind,
		"owner" = owner_ckey,
		"audience_mode" = audience_mode,
		"show_title_to_players" = show_title_to_players,
		"resolved_title" = resolved_title,
		"source_url" = source_url,
		"preset_id" = preset_id,
		"preset_name" = preset_name,
		"tier_name" = tier_name,
		"variant_title" = variant_title,
		"loop" = loop,
		"takeover" = takeover,
	)

/datum/admin_music_service
	var/list/presets = list()
	var/library_loaded = FALSE
	var/list/open_panels = list()
	var/datum/admin_music_session/active_session

/datum/admin_music_service/proc/register_panel(datum/admin_music_panel/panel)
	if(!panel)
		return FALSE
	if(!(panel in open_panels))
		open_panels += panel
	return TRUE

/datum/admin_music_service/proc/unregister_panel(datum/admin_music_panel/panel)
	open_panels -= panel
	return TRUE

/datum/admin_music_service/proc/update_open_panels()
	for(var/datum/admin_music_panel/panel as anything in open_panels.Copy())
		if(QDELETED(panel))
			open_panels -= panel
			continue
		SStgui.update_uis(panel)

/datum/admin_music_service/proc/build_default_variant()
	return new /datum/admin_music_variant

/datum/admin_music_service/proc/build_default_tier()
	var/datum/admin_music_tier/tier = new
	tier.variants += build_default_variant()
	return tier

/datum/admin_music_service/proc/build_default_preset()
	var/datum/admin_music_preset/preset = new
	preset.tiers += build_default_tier()
	return preset

/datum/admin_music_service/proc/get_preset_path(preset_id)
	return "data/admin_sound_presets/[preset_id].json"

/datum/admin_music_service/proc/build_export_path(client/requester, preset_name)
	var/export_name = sanitize_filename(trim(preset_name))
	var/requester_key = requester ? requester.ckey : "admin"
	if(!length(export_name))
		export_name = "admin_sound_preset"
	return "tmp/[requester_key]_[export_name]_[world.time].json"

/datum/admin_music_service/proc/get_audience_options()
	return list(
		list("id" = "global", "label" = "Globally"),
		list("id" = "xenos", "label" = "Xenos"),
		list("id" = "marines", "label" = "Marines"),
		list("id" = "ghosts", "label" = "Ghosts"),
		list("id" = "in_view", "label" = "All In View Range"),
		list("id" = "single_mob", "label" = "Single Mob"),
	)

/datum/admin_music_service/proc/get_sound_type_options()
	return list(
		list("id" = "atmospheric", "label" = "Atmospheric"),
		list("id" = "meme", "label" = "Meme"),
	)

/datum/admin_music_service/proc/get_audience_label(audience_mode)
	switch(audience_mode)
		if("global")
			return "Globally"
		if("xenos")
			return "Xenos"
		if("marines")
			return "Marines"
		if("ghosts")
			return "Ghosts"
		if("in_view")
			return "All In View Range"
		if("single_mob")
			return "Single Mob"
	return "Unknown"

/datum/admin_music_service/proc/get_sound_type_label(sound_type)
	switch(sound_type)
		if("atmospheric")
			return "Atmospheric"
		if("meme")
			return "Meme"
	return "Unknown"

/datum/admin_music_service/proc/get_sound_type_flag(sound_type)
	switch(sound_type)
		if("meme")
			return SOUND_ADMIN_MEME
		if("atmospheric")
			return SOUND_ADMIN_ATMOSPHERIC
	return SOUND_ADMIN_ATMOSPHERIC

/datum/admin_music_service/proc/build_session_ui_data()
	if(!active_session)
		return null
	var/list/data = active_session.to_ui_data()
	data["audience_label"] = get_audience_label(active_session.audience_mode)
	data["sound_type_label"] = get_sound_type_label(active_session.sound_type)
	return data

/datum/admin_music_service/proc/build_preset_slug(raw_name, fallback = "preset")
	var/slug = lowertext(trim(raw_name))
	slug = replacetext(slug, " ", "_")
	slug = sanitize_filename(slug)
	while(findtext(slug, "__"))
		slug = replacetext(slug, "__", "_")
	slug = trim(slug)
	if(!length(slug))
		return fallback
	return slug

/datum/admin_music_service/proc/find_available_copy_name(base_name)
	var/base_trimmed = trim(base_name)
	if(!length(base_trimmed))
		base_trimmed = "New Preset"
	var/index = 2
	var/candidate_name = "[base_trimmed] ([index])"
	var/candidate_id = build_preset_slug(candidate_name)
	ensure_library_loaded()
	while(presets[candidate_id])
		index++
		candidate_name = "[base_trimmed] ([index])"
		candidate_id = build_preset_slug(candidate_name)
	return candidate_name

/datum/admin_music_service/proc/ensure_library_loaded()
	if(library_loaded)
		return TRUE
	library_loaded = TRUE
	presets = list()

	var/static/regex/json_file_regex = regex("\\.json$", "i")
	var/list/file_names = flist("data/admin_sound_presets/")
	for(var/file_name as anything in file_names)
		if(findtext(file_name, "/", -1))
			continue
		if(!json_file_regex.Find(file_name))
			continue
		var/preset_id = replacetext(file_name, ".json", "")
		var/datum/admin_music_preset/preset = load_preset_from_file(get_preset_path(preset_id), preset_id)
		if(preset)
			presets[preset_id] = preset
	return TRUE

/datum/admin_music_service/proc/load_preset_from_file(path, preset_id)
	var/raw_text = file2text(path)
	if(!length(raw_text))
		return null
	var/list/parse_result = parse_preset_json_text(raw_text, preset_id)
	if(!islist(parse_result) || !parse_result["preset"])
		var/list/error_messages = list("unknown parse failure")
		if(islist(parse_result) && islist(parse_result["errors"]) && length(parse_result["errors"]))
			error_messages = parse_result["errors"]
		log_world("admin_music_service failed to parse preset file [path]: [jointext(error_messages, "; ")]")
		return null
	return parse_result["preset"]

/datum/admin_music_service/proc/parse_preset_json_text(json_text, preset_id_override = null)
	var/list/result = list("errors" = list())
	if(!istext(json_text) || !length(trim(json_text)))
		result["errors"] += "JSON text is empty."
		return result

	var/list/json_data
	try
		json_data = json_decode(json_text)
	catch(var/exception/decode_error)
		result["errors"] += "Failed to decode JSON: [decode_error]"
		return result

	if(!islist(json_data))
		result["errors"] += "Preset JSON root must be an object."
		return result

	var/version_raw = json_data["version"]
	var/version = text2num("[version_raw]")
	if(isnull(version_raw) || version != 1)
		result["errors"] += "Preset JSON version must be 1."
		return result

	var/datum/admin_music_preset/preset = preset_from_json_data(json_data, preset_id_override)
	if(!preset)
		result["errors"] += "Preset JSON could not be converted to a preset."
		return result

	var/list/errors = validate_preset(preset)
	if(length(errors))
		result["errors"] = errors
		return result

	result["preset"] = preset
	return result

/datum/admin_music_service/proc/preset_from_json_data(list/json_data, preset_id_override = null)
	if(!islist(json_data))
		return null

	var/datum/admin_music_preset/preset = new
	preset.preset_id = preset_id_override
	preset.name = "[isnull(json_data["name"]) ? "" : json_data["name"]]"
	preset.description = "[isnull(json_data["description"]) ? "" : json_data["description"]]"

	var/list/playback = json_data["playback"]
	if(islist(playback))
		if(!isnull(playback["audience_mode"]))
			preset.audience_mode = "[playback["audience_mode"]]"
		if(!isnull(playback["sound_type"]))
			preset.sound_type = "[playback["sound_type"]]"
		if(!isnull(playback["show_title_to_players"]))
			preset.show_title_to_players = !!playback["show_title_to_players"]

	preset.tiers = list()
	var/list/tiers_data = json_data["tiers"]
	if(islist(tiers_data))
		for(var/list/tier_data as anything in tiers_data)
			if(!islist(tier_data))
				continue
			var/datum/admin_music_tier/tier = new
			tier.name = "[isnull(tier_data["name"]) ? "" : tier_data["name"]]"
			tier.description = "[isnull(tier_data["description"]) ? "" : tier_data["description"]]"
			tier.variants = list()

			var/list/variants_data = tier_data["variants"]
			if(islist(variants_data))
				for(var/list/variant_data as anything in variants_data)
					if(!islist(variant_data))
						continue
					var/datum/admin_music_variant/variant = new
					variant.title = "[isnull(variant_data["title"]) ? "" : variant_data["title"]]"
					variant.description = "[isnull(variant_data["description"]) ? "" : variant_data["description"]]"
					variant.duration_seconds = max(round(text2num("[variant_data["duration_seconds"]]")), 0)
					variant.source_url = "[isnull(variant_data["source_url"]) ? "" : variant_data["source_url"]]"
					tier.variants += variant

			preset.tiers += tier

	return preset

/datum/admin_music_service/proc/build_library_ui_data()
	ensure_library_loaded()
	var/list/library = list()
	for(var/preset_id in presets)
		var/datum/admin_music_preset/preset = presets[preset_id]
		library += list(preset.build_library_summary())
	return library

/datum/admin_music_service/proc/find_preset(preset_id)
	ensure_library_loaded()
	return presets[preset_id]

/datum/admin_music_service/proc/load_preset_copy(preset_id)
	var/datum/admin_music_preset/preset = find_preset(preset_id)
	if(!preset)
		return null
	return preset.copy()

/datum/admin_music_service/proc/validate_preset(datum/admin_music_preset/preset)
	var/list/errors = list()
	if(!preset)
		errors += "Preset is missing."
		return errors

	preset.name = trim("[preset.name]")
	preset.description = trim("[preset.description]")
	if(!length(preset.name))
		errors += "Preset name cannot be empty."

	if(!(preset.audience_mode in list("global", "xenos", "marines", "ghosts", "in_view", "single_mob")))
		errors += "Preset audience mode is invalid."

	if(!(preset.sound_type in list("atmospheric", "meme")))
		errors += "Preset sound type is invalid."

	if(!length(preset.tiers))
		errors += "Preset must contain at least one tier."
		return errors

	var/list/seen_tier_names = list()
	for(var/datum/admin_music_tier/tier as anything in preset.tiers)
		tier.name = trim("[tier.name]")
		tier.description = trim("[tier.description]")
		if(!length(tier.name))
			errors += "Tier names cannot be empty."
		else
			var/tier_key = lowertext(tier.name)
			if(seen_tier_names[tier_key])
				errors += "Tier names must be unique."
			seen_tier_names[tier_key] = TRUE

		if(!length(tier.variants))
			errors += "Each tier must contain at least one variant."
			continue

		for(var/datum/admin_music_variant/variant as anything in tier.variants)
			variant.title = trim("[variant.title]")
			variant.description = trim("[variant.description]")
			variant.source_url = trim("[variant.source_url]")
			variant.duration_seconds = max(round(variant.duration_seconds), 0)

			if(!length(variant.title))
				errors += "Variant titles cannot be empty."
			if(!length(variant.source_url))
				errors += "Variant source URLs cannot be empty."
			else if(!findtext(variant.source_url, GLOB.is_http_protocol))
				errors += "Variant source URLs must use http or https."
	return errors

/datum/admin_music_service/proc/validate_selected_variant(datum/admin_music_preset/preset, datum/admin_music_tier/tier, datum/admin_music_variant/variant)
	var/list/errors = list()
	if(!preset || !tier || !variant)
		errors += "No tier or variant is selected."
		return errors
	if(!(preset.audience_mode in list("global", "xenos", "marines", "ghosts", "in_view", "single_mob")))
		errors += "Preset audience mode is invalid."
	if(!(preset.sound_type in list("atmospheric", "meme")))
		errors += "Preset sound type is invalid."
	variant.title = trim("[variant.title]")
	variant.description = trim("[variant.description]")
	variant.source_url = trim("[variant.source_url]")
	variant.duration_seconds = max(round(variant.duration_seconds), 0)
	if(!length(variant.title))
		errors += "Variant title cannot be empty."
	if(!length(variant.source_url))
		errors += "Variant source URL cannot be empty."
	else if(!findtext(variant.source_url, GLOB.is_http_protocol))
		errors += "Variant source URL must use http or https."
	return errors

/datum/admin_music_service/proc/notify_validation_errors(client/requester, list/errors)
	if(!requester || !islist(errors) || !length(errors))
		return FALSE
	to_chat(requester, SPAN_WARNING(jointext(errors, " ")))
	return TRUE

/datum/admin_music_service/proc/write_preset_to_disk(datum/admin_music_preset/preset)
	if(!preset || !length(preset.preset_id))
		return FALSE
	rustg_file_write(json_encode(preset.to_json_data()), get_preset_path(preset.preset_id))
	return TRUE

/datum/admin_music_service/proc/save_draft(client/requester, datum/admin_music_preset/draft, as_copy = FALSE)
	var/list/errors = validate_preset(draft)
	if(length(errors))
		notify_validation_errors(requester, errors)
		return null

	ensure_library_loaded()
	var/old_id = draft.preset_id
	var/desired_name = draft.name
	if(as_copy)
		desired_name = find_available_copy_name(draft.name)

	var/desired_id = build_preset_slug(desired_name)
	if(!as_copy)
		if(length(old_id))
			if(old_id != desired_id && presets[desired_id])
				to_chat(requester, SPAN_WARNING("A different preset already uses that name. Rename it or use Save As Copy."))
				return null
		else if(presets[desired_id])
			to_chat(requester, SPAN_WARNING("A preset with that name already exists. Rename it or use Save As Copy."))
			return null

	var/datum/admin_music_preset/saved_preset = draft.copy()
	saved_preset.name = desired_name
	saved_preset.preset_id = desired_id
	write_preset_to_disk(saved_preset)

	if(length(old_id) && old_id != desired_id)
		fdel(get_preset_path(old_id))
		presets -= old_id

	presets[desired_id] = saved_preset
	update_open_panels()
	log_preset_action(requester, as_copy ? "save_as_copy" : "save", saved_preset)
	return saved_preset.copy()

/datum/admin_music_service/proc/delete_preset(client/requester, preset_id)
	if(!length(preset_id))
		return FALSE
	ensure_library_loaded()
	var/datum/admin_music_preset/preset = presets[preset_id]
	if(!preset)
		return FALSE
	fdel(get_preset_path(preset_id))
	presets -= preset_id
	update_open_panels()
	log_preset_action(requester, "delete", preset)
	return TRUE

/datum/admin_music_service/proc/export_draft(client/requester, datum/admin_music_preset/draft)
	var/list/errors = validate_preset(draft)
	if(length(errors))
		notify_validation_errors(requester, errors)
		return FALSE
	if(requester && requester.file_spam_check())
		return FALSE
	var/export_path = build_export_path(requester, draft.name)
	rustg_file_write(json_encode(draft.to_json_data()), export_path)
	requester << ftp(file(export_path))
	log_preset_action(requester, "export", draft)
	return TRUE

/datum/admin_music_service/proc/find_variant_by_trimmed_url(datum/admin_music_tier/tier, source_url)
	var/needle = trim(source_url)
	for(var/datum/admin_music_variant/variant as anything in tier.variants)
		if(trim(variant.source_url) == needle)
			return variant
	return null

/datum/admin_music_service/proc/merge_imported_preset(datum/admin_music_preset/existing_preset, datum/admin_music_preset/imported_preset)
	if(!existing_preset || !imported_preset)
		return existing_preset
	var/list/tier_lookup = list()
	for(var/datum/admin_music_tier/existing_tier as anything in existing_preset.tiers)
		tier_lookup[lowertext(trim(existing_tier.name))] = existing_tier

	for(var/datum/admin_music_tier/imported_tier as anything in imported_preset.tiers)
		var/tier_key = lowertext(trim(imported_tier.name))
		var/datum/admin_music_tier/target_tier = tier_lookup[tier_key]
		if(!target_tier)
			target_tier = imported_tier.copy()
			existing_preset.tiers += target_tier
			tier_lookup[tier_key] = target_tier
			continue

		for(var/datum/admin_music_variant/imported_variant as anything in imported_tier.variants)
			if(find_variant_by_trimmed_url(target_tier, imported_variant.source_url))
				continue
			target_tier.variants += imported_variant.copy()
	return existing_preset

/datum/admin_music_service/proc/import_preset_text(client/requester, json_text)
	var/list/parse_result = parse_preset_json_text(json_text)
	var/list/errors = parse_result["errors"]
	if(length(errors))
		notify_validation_errors(requester, errors)
		return null

	var/datum/admin_music_preset/imported_preset = parse_result["preset"]
	ensure_library_loaded()
	var/import_target_id = build_preset_slug(imported_preset.name)
	var/datum/admin_music_preset/existing_preset = presets[import_target_id]
	if(existing_preset)
		var/choice = tgui_alert(requester, "A preset named \"[existing_preset.name]\" already exists. How should it be imported?", "Import Preset", list("Replace Preset", "Merge New Tracks", "Save As Copy", "Cancel"))
		switch(choice)
			if("Replace Preset")
				imported_preset.preset_id = existing_preset.preset_id
				write_preset_to_disk(imported_preset)
				presets[existing_preset.preset_id] = imported_preset.copy()
				update_open_panels()
				log_preset_action(requester, "import_replace", imported_preset)
				return imported_preset.copy()
			if("Merge New Tracks")
				var/datum/admin_music_preset/merged_preset = existing_preset.copy()
				merge_imported_preset(merged_preset, imported_preset)
				write_preset_to_disk(merged_preset)
				presets[merged_preset.preset_id] = merged_preset.copy()
				update_open_panels()
				log_preset_action(requester, "import_merge", merged_preset)
				return merged_preset.copy()
			if("Save As Copy")
				imported_preset.preset_id = null
				return save_draft(requester, imported_preset, TRUE)
			else
				return null

	imported_preset.preset_id = null
	return save_draft(requester, imported_preset, FALSE)

/datum/admin_music_service/proc/get_media_players()
	var/list/datum/internet_media/media_players = list()
	if(CONFIG_GET(string/invoke_youtubedl))
		media_players += new /datum/internet_media/yt_dlp
	if(CONFIG_GET(string/cobalt_base_api))
		media_players += new /datum/internet_media/cobalt
	return media_players

/datum/admin_music_service/proc/resolve_media(client/requester, source_url)
	var/list/datum/internet_media/media_players = get_media_players()
	if(!length(media_players))
		to_chat(requester, SPAN_BOLDWARNING("Your server host has not set up any web media players."))
		return null

	var/datum/media_response/response
	for(var/datum/internet_media/player as anything in media_players)
		response = player.get_media(source_url)
		if(istype(response))
			break

	if(!istype(response))
		to_chat(requester, SPAN_BOLDWARNING("All configured web media players failed to provide a valid response:"))
		for(var/datum/internet_media/player as anything in media_players)
			to_chat(requester, SPAN_WARNING("[player.type] error: [player.error]"))
		return null

	if(!findtext(response.url, GLOB.is_http_protocol))
		to_chat(requester, SPAN_BOLDWARNING("BLOCKED: Content URL not using http(s) protocol"), confidential = TRUE)
		to_chat(requester, SPAN_WARNING("The media provider returned a content URL that isn't using the HTTP or HTTPS protocol"), confidential = TRUE)
		return null

	return response

/datum/admin_music_service/proc/resolve_target_clients(client/requester, audience_mode)
	var/list/targets = list()
	switch(audience_mode)
		if("global")
			targets = GLOB.mob_list
		if("xenos")
			targets = GLOB.xeno_mob_list + GLOB.dead_mob_list
		if("marines")
			targets = GLOB.human_mob_list + GLOB.dead_mob_list
		if("ghosts")
			targets = GLOB.observer_list + GLOB.dead_mob_list
		if("in_view")
			if(!requester?.mob)
				to_chat(requester, SPAN_WARNING("You need a mob to target people in view range."))
				return null
			var/list/atom/ranged_atoms = urange(requester.view, get_turf(requester.mob))
			for(var/mob/receiver in ranged_atoms)
				targets += receiver
		if("single_mob")
			var/list/mob/all_client_mobs = list()
			for(var/client/possible_client as anything in GLOB.clients)
				if(possible_client?.mob)
					all_client_mobs += possible_client.mob
			var/mob/choice = tgui_input_list(requester, "Select the mob to play to:", "Select Mob", all_client_mobs)
			if(!choice || QDELETED(choice))
				return null
			targets += choice
		else
			return null

	var/list/unique_clients = list()
	for(var/mob/target_mob as anything in targets)
		var/client/target_client = target_mob?.client
		if(target_client && !(target_client in unique_clients))
			unique_clients += target_client
	return unique_clients

/datum/admin_music_service/proc/filter_eligible_clients(list/target_clients, sound_type)
	var/list/eligible_clients = list()
	var/sound_flag = get_sound_type_flag(sound_type)
	for(var/client/target_client as anything in target_clients)
		if(!target_client?.prefs)
			continue
		if(!(target_client.prefs.toggles_sound & SOUND_MIDI))
			continue
		if(!(target_client.prefs.toggles_sound & sound_flag))
			continue
		eligible_clients += target_client
	return eligible_clients

/datum/admin_music_service/proc/build_music_payload(datum/admin_music_session/session)
	return list(
		"link" = session.show_title_to_players ? session.source_url : "Song Link Hidden",
		"title" = session.show_title_to_players ? session.resolved_title : "Admin sound",
		"start" = session.start_time,
		"end" = session.end_time,
		"loop" = session.loop,
	)

/datum/admin_music_service/proc/stop_session_clients(datum/admin_music_session/session, list/limit_to_clients = null)
	if(!session)
		return FALSE
	for(var/client/target_client as anything in session.tracked_clients)
		if(islist(limit_to_clients) && !(target_client in limit_to_clients))
			continue
		target_client?.tgui_panel?.stop_music()
	return TRUE

/datum/admin_music_service/proc/log_session_action(client/requester, action, datum/admin_music_session/session)
	if(!requester || !session)
		return FALSE
	var/preset_id = session.preset_id ? session.preset_id : "none"
	var/preset_name = session.preset_name ? session.preset_name : ""
	var/tier_name = session.tier_name ? session.tier_name : ""
	var/variant_title = session.variant_title ? session.variant_title : ""
	var/takeover_suffix = session.takeover ? " (takeover)" : ""
	var/message = "[key_name(requester)] admin music [action]: source=[session.source_kind], audience=[get_audience_label(session.audience_mode)], sound_type=[get_sound_type_label(session.sound_type)], show_title=[session.show_title_to_players], source_url=[session.source_url], resolved_title=[session.resolved_title], preset=[preset_id]/\"[preset_name]\", tier=\"[tier_name]\", variant=\"[variant_title]\", loop=[session.loop], takeover=[session.takeover]"
	log_admin(message)
	message_admins("[key_name_admin(requester)] admin music [action]: [session.resolved_title] ([get_audience_label(session.audience_mode)])[takeover_suffix]")
	return TRUE

/datum/admin_music_service/proc/log_preset_action(client/requester, action, datum/admin_music_preset/preset)
	if(!requester || !preset)
		return FALSE
	var/preset_id = preset.preset_id ? preset.preset_id : "unsaved"
	var/message = "[key_name(requester)] admin music preset [action]: [preset_id] / [preset.name]"
	log_admin(message)
	message_admins("[key_name_admin(requester)] admin music preset [action]: [preset.name]")
	return TRUE

/datum/admin_music_service/proc/apply_session(client/requester, datum/admin_music_session/session, list/eligible_clients, switch_mode = FALSE)
	if(!requester || !session || !islist(eligible_clients) || !length(eligible_clients))
		return FALSE
	session.takeover = !!active_session && !switch_mode

	if(active_session)
		if(switch_mode)
			var/list/leaving_clients = list()
			for(var/client/old_client as anything in active_session.tracked_clients)
				if(!(old_client in eligible_clients))
					leaving_clients += old_client
			stop_session_clients(active_session, leaving_clients)
		else
			stop_session_clients(active_session)

	var/list/music_payload = build_music_payload(session)
	for(var/client/target_client as anything in eligible_clients)
		if(session.must_send_assets)
			SSassets.transport.send_assets(target_client, session.asset_name)
		target_client?.tgui_panel?.play_music(session.resolved_url, music_payload)
		to_chat(target_client, SPAN_BOLDANNOUNCE("An admin played: [music_payload["title"]]"), confidential = TRUE)

	session.tracked_clients = eligible_clients.Copy()
	active_session = session
	update_open_panels()
	return TRUE

/datum/admin_music_service/proc/force_stop_all_clients()
	for(var/client/target_client as anything in GLOB.clients)
		target_client?.tgui_panel?.stop_music()
	return TRUE

/datum/admin_music_service/proc/stop_broadcast(client/requester, reason = "stop")
	if(!active_session)
		force_stop_all_clients()
		if(requester)
			log_admin("[key_name(requester)] admin music [reason]: forced global browser-audio stop with no tracked session.")
			message_admins("[key_name_admin(requester)] admin music [reason]: forced global browser-audio stop with no tracked session.")
		update_open_panels()
		return TRUE
	stop_session_clients(active_session)
	log_session_action(requester, reason, active_session)
	active_session = null
	update_open_panels()
	return TRUE

/datum/admin_music_service/proc/play_panel_variant(client/requester, datum/admin_music_preset/preset, datum/admin_music_tier/tier, datum/admin_music_variant/variant)
	var/list/errors = validate_selected_variant(preset, tier, variant)
	if(length(errors))
		notify_validation_errors(requester, errors)
		return FALSE

	var/datum/media_response/response = resolve_media(requester, variant.source_url)
	if(!response)
		return FALSE

	var/list/target_clients = resolve_target_clients(requester, preset.audience_mode)
	if(!islist(target_clients))
		return FALSE

	var/list/eligible_clients = filter_eligible_clients(target_clients, preset.sound_type)
	if(!length(eligible_clients))
		to_chat(requester, SPAN_WARNING("No eligible listeners were found for this preset."))
		return FALSE

	var/datum/admin_music_session/session = new
	session.owner_ckey = requester.ckey
	session.source_kind = "panel"
	session.audience_mode = preset.audience_mode
	session.sound_type = preset.sound_type
	session.show_title_to_players = preset.show_title_to_players
	session.source_url = variant.source_url
	session.resolved_url = response.url
	session.resolved_title = length(variant.title) ? variant.title : (response.title ? response.title : "Admin sound")
	session.start_time = response.start_time
	session.end_time = response.end_time
	session.loop = TRUE
	session.preset_id = preset.preset_id
	session.preset_name = preset.name
	session.tier_id = REF(tier)
	session.tier_name = tier.name
	session.variant_id = REF(variant)
	session.variant_title = variant.title

	var/switch_mode = active_session && active_session.source_kind == "panel" && active_session.owner_ckey == requester.ckey && active_session.preset_id == preset.preset_id
	if(!apply_session(requester, session, eligible_clients, switch_mode))
		return FALSE
	log_session_action(requester, switch_mode ? "switch_tier" : "play", session)
	return TRUE

/datum/admin_music_service/proc/prompt_legacy_request(client/requester)
	var/sound_mode = tgui_input_list(requester, "Play a sound from which source?", "Select Source", list("Upload", "Web"))
	if(!sound_mode)
		return null

	var/list/request = list(
		"must_send_assets" = FALSE,
		"asset_name" = null,
		"source_input" = null,
		"resolved_title" = null,
		"resolved_url" = null,
		"start_time" = null,
		"end_time" = null,
	)

	if(sound_mode == "Web")
		var/source_url = input(requester, "Enter content URL (supported sites only)", "Play Internet Sound") as text|null
		source_url = trim(source_url)
		if(!length(source_url))
			return null

		var/datum/media_response/response = resolve_media(requester, source_url)
		if(!response)
			return null

		request["source_input"] = source_url
		request["resolved_title"] = response.title
		request["resolved_url"] = response.url
		request["start_time"] = response.start_time
		request["end_time"] = response.end_time
	else
		var/current_transport = CONFIG_GET(string/asset_transport)
		if(!current_transport || current_transport == "simple")
			if(tgui_alert(requester.mob, "WARNING: Your server is using simple asset transport. Sounds will have to be sent directly to players, which may freeze the game for long durations. Are you SURE?", "Really play direct sound?", list("Yes", "No")) != "Yes")
				return null
			request["must_send_assets"] = TRUE

		var/soundfile = input(requester.mob, "Choose a sound file to play", "Upload Sound") as null|file
		if(!soundfile)
			return null

		var/static/regex/only_extension = regex(@{"^.*\.([a-z0-9]{1,5})$"}, "gi")
		var/extension = only_extension.Replace("[soundfile]", "$1")
		if(!length(extension))
			to_chat(requester, SPAN_WARNING("Invalid filename extension."))
			return null

		var/static/playsound_notch = 1
		var/asset_name = "admin_sound_[playsound_notch++].[extension]"
		SSassets.transport.register_asset(asset_name, soundfile)
		message_admins("[key_name_admin(requester)] uploaded admin sound '[soundfile]' to asset transport.")

		var/static/regex/remove_extension = regex(@{"\.[a-z0-9]+$"}, "gi")
		request["source_input"] = "[soundfile]"
		request["resolved_title"] = remove_extension.Replace("[soundfile]", "")
		request["resolved_url"] = SSassets.transport.get_asset_url(asset_name)
		request["asset_name"] = asset_name

	if(!length(trim("[request["resolved_title"]]")))
		request["resolved_title"] = tgui_input_text(requester, "What is the title of this media?", "Media Title")

	var/show_title_choice = tgui_alert(requester, "Show the name of this sound to the players?", "Sound Name", list("No", "Yes", "Cancel"))
	if(show_title_choice == "Cancel")
		return null
	request["show_title_to_players"] = show_title_choice == "Yes"

	var/audience_choice = tgui_input_list(requester, "Who do you want to play this to?", "Select Listeners", list("Globally", "Xenos", "Marines", "Ghosts", "All In View Range", "Single Mob"))
	if(!audience_choice)
		return null

	switch(audience_choice)
		if("Globally")
			request["audience_mode"] = "global"
		if("Xenos")
			request["audience_mode"] = "xenos"
		if("Marines")
			request["audience_mode"] = "marines"
		if("Ghosts")
			request["audience_mode"] = "ghosts"
		if("All In View Range")
			request["audience_mode"] = "in_view"
		if("Single Mob")
			request["audience_mode"] = "single_mob"
		else
			return null

	var/sound_type_choice = tgui_input_list(requester, "What kind of sound is this?", "Select Sound Type", list("Atmospheric", "Meme"))
	if(!sound_type_choice)
		return null
	request["sound_type"] = sound_type_choice == "Meme" ? "meme" : "atmospheric"
	return request

/datum/admin_music_service/proc/play_legacy_prompted(client/requester)
	var/list/request = prompt_legacy_request(requester)
	if(!islist(request))
		return FALSE

	var/list/target_clients = resolve_target_clients(requester, request["audience_mode"])
	if(!islist(target_clients))
		return FALSE

	var/list/eligible_clients = filter_eligible_clients(target_clients, request["sound_type"])
	if(!length(eligible_clients))
		to_chat(requester, SPAN_WARNING("No eligible listeners were found for this admin sound."))
		return FALSE

	var/datum/admin_music_session/session = new
	session.owner_ckey = requester.ckey
	session.source_kind = "legacy"
	session.audience_mode = request["audience_mode"]
	session.sound_type = request["sound_type"]
	session.show_title_to_players = request["show_title_to_players"]
	session.source_url = request["source_input"]
	session.resolved_url = request["resolved_url"]
	session.resolved_title = request["resolved_title"] ? request["resolved_title"] : "Admin sound"
	session.start_time = request["start_time"]
	session.end_time = request["end_time"]
	session.loop = FALSE
	session.must_send_assets = !!request["must_send_assets"]
	session.asset_name = request["asset_name"]

	if(!apply_session(requester, session, eligible_clients, FALSE))
		return FALSE
	log_session_action(requester, "legacy_play", session)
	return TRUE
