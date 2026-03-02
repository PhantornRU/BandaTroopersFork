/// Immutable configuration datum for one support action inside a template.
/datum/rto_support_action_template
	/// Stable identifier used by runtime and UI layers.
	var/action_id
	/// Display name shown on the action button.
	var/name = "RTO Support Action"
	/// Description shown in UI.
	var/description = ""
	/// Adapter-facing dispatch key.
	var/dispatch_key = "fire_support"
	/// Configured scatter override for a fresh support instance.
	var/scatter = 0
	/// Shared cooldown applied to all support actions on the controller.
	var/shared_cooldown = 0
	/// Personal cooldown applied only to this action.
	var/personal_cooldown = 0
	/// Whether the action requires an active visibility sector.
	var/requires_visibility_zone = TRUE
	/// Optional grouping label for UI.
	var/category = ""
	/// Icon file used by the action button overlay.
	var/icon_file = 'icons/mob/radial.dmi'
	/// Icon state used by the action button overlay.
	var/icon_state = null
	/// Fire support path instantiated by the dispatch adapter.
	var/fire_support_path
	/// Altitude requirement for the target area.
	var/altitude_requirement = RTO_SUPPORT_ALTITUDE_ANY
	/// Whether the ability may target a closed turf.
	var/allow_closed_turf = TRUE

/// Builds a UI DTO for the action list.
/datum/rto_support_action_template/proc/build_ui_entry()
	var/datum/rto_support_ui_action_entry/entry = new
	entry.action_id = action_id
	entry.name = name
	entry.description = description
	entry.dispatch_key = dispatch_key
	entry.scatter = scatter
	entry.shared_cooldown = shared_cooldown
	entry.personal_cooldown = personal_cooldown
	entry.requires_visibility_zone = requires_visibility_zone
	entry.icon_state = icon_state
	entry.altitude_requirement = altitude_requirement
	entry.allow_closed_turf = allow_closed_turf
	return entry

/datum/rto_support_action_template/mortar_he
	action_id = "mortar_he"
	name = "HE mortar"
	description = "Площадной осколочно-фугасный залп с большим разбросом."
	scatter = 6
	shared_cooldown = 12 SECONDS
	personal_cooldown = 45 SECONDS
	category = "mortar"
	icon_state = "he_mortar"
	fire_support_path = /datum/fire_support/mortar

/datum/rto_support_action_template/mortar_smoke
	action_id = "mortar_smoke"
	name = "Smoke mortar"
	description = "Дымовой залп для перекрытия проходов и отхода."
	scatter = 5
	shared_cooldown = 10 SECONDS
	personal_cooldown = 35 SECONDS
	category = "mortar"
	icon_state = "smoke_mortar"
	fire_support_path = /datum/fire_support/mortar/smoke

/datum/rto_support_action_template/mortar_incendiary
	action_id = "mortar_incendiary"
	name = "Incendiary mortar"
	description = "Зажигательный залп для выжигания зоны."
	scatter = 6
	shared_cooldown = 15 SECONDS
	personal_cooldown = 60 SECONDS
	category = "mortar"
	icon_state = "incendiary_mortar"
	fire_support_path = /datum/fire_support/mortar/incendiary

/datum/rto_support_action_template/cas_gun_run
	action_id = "cas_gun_run"
	name = "Gun run"
	description = "Быстрый пушечный проход по узкому коридору."
	scatter = 3
	shared_cooldown = 18 SECONDS
	personal_cooldown = 70 SECONDS
	category = "cas"
	icon_state = "gau"
	fire_support_path = /datum/fire_support/gau
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_action_template/cas_laser_run
	action_id = "cas_laser_run"
	name = "Laser run"
	description = "Точный лазерный проход с малым разбросом."
	scatter = 2
	shared_cooldown = 20 SECONDS
	personal_cooldown = 80 SECONDS
	category = "cas"
	icon_state = "laser"
	fire_support_path = /datum/fire_support/laser
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_action_template/cas_rocket_barrage
	action_id = "cas_rocket_barrage"
	name = "Rocket barrage"
	description = "Ракетный заход с умеренным разбросом."
	scatter = 4
	shared_cooldown = 20 SECONDS
	personal_cooldown = 90 SECONDS
	category = "cas"
	icon_state = "rockets"
	fire_support_path = /datum/fire_support/rockets
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_action_template/heavy_missile
	action_id = "heavy_missile"
	name = "Missile strike"
	description = "Редкий мощный ракетный удар по точке."
	scatter = 2
	shared_cooldown = 25 SECONDS
	personal_cooldown = 90 SECONDS
	category = "heavy"
	icon_state = "missile"
	fire_support_path = /datum/fire_support/missile
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_action_template/heavy_napalm
	action_id = "heavy_napalm"
	name = "Napalm strike"
	description = "Напалмовый удар по компактной зоне."
	scatter = 3
	shared_cooldown = 25 SECONDS
	personal_cooldown = 110 SECONDS
	category = "heavy"
	icon_state = "napalm_missile"
	fire_support_path = /datum/fire_support/missile/napalm
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH

/datum/rto_support_action_template/logistics_supply
	action_id = "logistics_supply"
	name = "Supply drop"
	description = "Сброс ящика снабжения с малым отклонением."
	scatter = 1
	shared_cooldown = 20 SECONDS
	personal_cooldown = 90 SECONDS
	category = "logistics"
	icon_state = "ammo"
	fire_support_path = /datum/fire_support/supply_drop
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE

/datum/rto_support_action_template/logistics_sentry
	action_id = "logistics_sentry"
	name = "Sentry drop"
	description = "Сброс турели в выбранную точку."
	scatter = 1
	shared_cooldown = 20 SECONDS
	personal_cooldown = 120 SECONDS
	category = "logistics"
	icon_state = "sentry"
	fire_support_path = /datum/fire_support/sentry_drop
	altitude_requirement = RTO_SUPPORT_ALTITUDE_HIGH
	allow_closed_turf = FALSE
