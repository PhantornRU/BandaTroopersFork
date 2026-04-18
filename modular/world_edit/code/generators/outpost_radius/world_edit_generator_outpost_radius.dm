#define WORLD_EDIT_OUTPOST_RADIUS_MAX 25
#define WORLD_EDIT_OUTPOST_SINGLE_POINT_SAFE_PLACEMENT_CAP 300

/datum/world_edit_generator/outpost_radius
	requires_preview_before_apply = TRUE
	var/static/list/valid_factions = list(FACTION_MARINE, FACTION_UA_REBEL, FACTION_UPP, FACTION_CANC, FACTION_WY, FACTION_FREELANCER, FACTION_TWE, FACTION_TWE_REBEL, FACTION_MERCENARY)
	var/static/list/allowed_barricade_types = list(
		/datum/human_ai_defense/barricade/metal,
		/datum/human_ai_defense/barricade/metal/wired,
		/datum/human_ai_defense/barricade/sandbag,
		/datum/human_ai_defense/barricade/plasteel,
		/datum/human_ai_defense/barricade/plasteel/wired,
		/datum/human_ai_defense/barricade/wooden,
	)
	var/static/list/allowed_sentry_types = list(
		/datum/human_ai_defense/defense/sentry/uscm,
		/datum/human_ai_defense/defense/sentry/uscm/shotgun,
		/datum/human_ai_defense/defense/sentry/uscm/dmr,
		/datum/human_ai_defense/defense/sentry/uscm/mini,
		/datum/human_ai_defense/defense/sentry/upp,
		/datum/human_ai_defense/defense/sentry/wy,
	)
	var/static/list/outpost_family_profiles = list(
		"metal_perimeter" = list(
			"label" = "Металл, контур",
			"description" = "Однородный металлический периметр с минимальным смешением баррикад.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/metal,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/metal,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		),
		"wired_metal_perimeter" = list(
			"label" = "Металл с проволокой",
			"description" = "Ровный периметр из металла с проволокой для более жёстких узких проходов.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/metal/wired,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/metal/wired,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/shotgun,
		),
		"plasteel_bastion" = list(
			"label" = "Пласталь, бастион",
			"description" = "Тяжёлый пласталевый периметр для укреплённых опорных точек.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/plasteel,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/plasteel,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/dmr,
		),
		"plasteel_wired_bastion" = list(
			"label" = "Пласталь с проволокой",
			"description" = "Усиленный пласталевый периметр с упором на проволочные баррикады.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/plasteel/wired,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/plasteel/wired,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/dmr,
		),
		"sandbag_redoubt" = list(
			"label" = "Мешки с песком",
			"description" = "Временное укрепление из мешков с песком с широким прикрытием и дешёвым периметром.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/sandbag,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/sandbag,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/shotgun,
		),
		"wooden_screen" = list(
			"label" = "Деревянное прикрытие",
			"description" = "Быстрый деревянный периметр для спешного передового укрытия.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/wooden,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/wooden,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/mini,
		),
		"mixed_standard" = list(
			"label" = "Смешанный стандарт",
			"description" = "Сбалансированный смешанный периметр с чередованием металла и мешков с песком.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/metal,
			"default_barricade_pattern" = "paired",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/metal,
				/datum/human_ai_defense/barricade/metal/wired,
				/datum/human_ai_defense/barricade/sandbag,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		),
		"mixed_siege" = list(
			"label" = "Смешанный осадный",
			"description" = "Более тяжёлый смешанный периметр с чередованием пластали и проволочного укрытия.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/plasteel,
			"default_barricade_pattern" = "paired",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/plasteel,
				/datum/human_ai_defense/barricade/plasteel/wired,
				/datum/human_ai_defense/barricade/metal,
				/datum/human_ai_defense/barricade/metal/wired,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/dmr,
		),
	)
	var/static/list/outpost_layout_profiles = list(
		"crossroads" = list(
			"label" = "Крест",
			"description" = "По одному проходу на каждой стороне света.",
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"guard_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"opening_half_width" = 0,
		),
		"wide_crossroads" = list(
			"label" = "Широкий крест",
			"description" = "Более широкие проходы на каждой стороне света для интенсивного движения.",
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"guard_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"opening_half_width" = 1,
		),
		"lane_ns" = list(
			"label" = "Коридор север-юг",
			"description" = "Два широких прохода по линии север-юг.",
			"opening_dirs" = list(NORTH, SOUTH),
			"guard_dirs" = list(NORTH, SOUTH),
			"opening_half_width" = 1,
		),
		"lane_ew" = list(
			"label" = "Коридор восток-запад",
			"description" = "Два широких прохода по линии восток-запад.",
			"opening_dirs" = list(EAST, WEST),
			"guard_dirs" = list(EAST, WEST),
			"opening_half_width" = 1,
		),
		"north_gate" = list(
			"label" = "Северные ворота",
			"description" = "Один северный проход с внутренним прикрытием.",
			"opening_dirs" = list(NORTH),
			"guard_dirs" = list(NORTH),
			"opening_half_width" = 1,
		),
		"south_gate" = list(
			"label" = "Южные ворота",
			"description" = "Один южный проход с внутренним прикрытием.",
			"opening_dirs" = list(SOUTH),
			"guard_dirs" = list(SOUTH),
			"opening_half_width" = 1,
		),
		"east_gate" = list(
			"label" = "Восточные ворота",
			"description" = "Один восточный проход с внутренним прикрытием.",
			"opening_dirs" = list(EAST),
			"guard_dirs" = list(EAST),
			"opening_half_width" = 1,
		),
		"west_gate" = list(
			"label" = "Западные ворота",
			"description" = "Один западный проход с внутренним прикрытием.",
			"opening_dirs" = list(WEST),
			"guard_dirs" = list(WEST),
			"opening_half_width" = 1,
		),
		"corner_ne" = list(
			"label" = "Угол северо-восток",
			"description" = "Два угловых выхода с упором на северо-восточное направление.",
			"opening_dirs" = list(NORTH, EAST),
			"guard_dirs" = list(NORTH, EAST),
			"opening_half_width" = 0,
		),
		"corner_se" = list(
			"label" = "Угол юго-восток",
			"description" = "Два угловых выхода с упором на юго-восточное направление.",
			"opening_dirs" = list(SOUTH, EAST),
			"guard_dirs" = list(SOUTH, EAST),
			"opening_half_width" = 0,
		),
		"corner_sw" = list(
			"label" = "Угол юго-запад",
			"description" = "Два угловых выхода с упором на юго-западное направление.",
			"opening_dirs" = list(SOUTH, WEST),
			"guard_dirs" = list(SOUTH, WEST),
			"opening_half_width" = 0,
		),
		"corner_nw" = list(
			"label" = "Угол северо-запад",
			"description" = "Два угловых выхода с упором на северо-западное направление.",
			"opening_dirs" = list(NORTH, WEST),
			"guard_dirs" = list(NORTH, WEST),
			"opening_half_width" = 0,
		),
		"sealed_redoubt" = list(
			"label" = "Закрытый редут",
			"description" = "Без прямых проходов; внутренние турели охраняют периметр изнутри.",
			"opening_dirs" = list(),
			"guard_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"opening_half_width" = 0,
		),
	)

/datum/world_edit_generator/outpost_radius/get_supported_placement_modes()
	return list("single", "repeat")

/datum/world_edit_generator/outpost_radius/get_supported_placement_shapes()
	return GLOB.world_edit_placement_shapes.world_edit_get_supported_shape_ids().Copy()

/datum/world_edit_generator/outpost_radius/supports_placement_direction()
	return TRUE

/datum/world_edit_generator/outpost_radius/get_default_placement_direction()
	return NORTH
