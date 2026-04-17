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
			"label" = "Metal Perimeter",
			"description" = "Single-material metal perimeter with minimal barricade mixing.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/metal,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/metal,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm,
		),
		"wired_metal_perimeter" = list(
			"label" = "Wired Metal",
			"description" = "Uniform wired-metal perimeter for stricter chokepoints.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/metal/wired,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/metal/wired,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/shotgun,
		),
		"plasteel_bastion" = list(
			"label" = "Plasteel Bastion",
			"description" = "Heavy plasteel perimeter for high-value fortified holds.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/plasteel,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/plasteel,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/dmr,
		),
		"plasteel_wired_bastion" = list(
			"label" = "Wired Plasteel",
			"description" = "Reinforced plasteel perimeter with wired barricade emphasis.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/plasteel/wired,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/plasteel/wired,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/dmr,
		),
		"sandbag_redoubt" = list(
			"label" = "Sandbag Redoubt",
			"description" = "Temporary sandbag hold with broad cover and cheaper perimeter pieces.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/sandbag,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/sandbag,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/shotgun,
		),
		"wooden_screen" = list(
			"label" = "Wooden Screen",
			"description" = "Fast wooden perimeter for expedient forward cover.",
			"default_barricade_path" = /datum/human_ai_defense/barricade/wooden,
			"default_barricade_pattern" = "uniform",
			"barricade_mix" = list(
				/datum/human_ai_defense/barricade/wooden,
			),
			"default_sentry_path" = /datum/human_ai_defense/defense/sentry/uscm/mini,
		),
		"mixed_standard" = list(
			"label" = "Mixed Standard",
			"description" = "Balanced mixed perimeter with metal and sandbag rotation.",
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
			"label" = "Mixed Siege",
			"description" = "Heavier mixed perimeter that rotates plasteel and wired cover.",
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
			"label" = "Crossroads",
			"description" = "One passage on every cardinal side.",
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"guard_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"opening_half_width" = 0,
		),
		"wide_crossroads" = list(
			"label" = "Wide Crossroads",
			"description" = "Wider passages on every cardinal side for larger traffic.",
			"opening_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"guard_dirs" = list(NORTH, EAST, SOUTH, WEST),
			"opening_half_width" = 1,
		),
		"lane_ns" = list(
			"label" = "North-South Lane",
			"description" = "Two broad passages aligned north-south.",
			"opening_dirs" = list(NORTH, SOUTH),
			"guard_dirs" = list(NORTH, SOUTH),
			"opening_half_width" = 1,
		),
		"lane_ew" = list(
			"label" = "East-West Lane",
			"description" = "Two broad passages aligned east-west.",
			"opening_dirs" = list(EAST, WEST),
			"guard_dirs" = list(EAST, WEST),
			"opening_half_width" = 1,
		),
		"north_gate" = list(
			"label" = "North Gate",
			"description" = "Single northern passage with inward cover.",
			"opening_dirs" = list(NORTH),
			"guard_dirs" = list(NORTH),
			"opening_half_width" = 1,
		),
		"south_gate" = list(
			"label" = "South Gate",
			"description" = "Single southern passage with inward cover.",
			"opening_dirs" = list(SOUTH),
			"guard_dirs" = list(SOUTH),
			"opening_half_width" = 1,
		),
		"east_gate" = list(
			"label" = "East Gate",
			"description" = "Single eastern passage with inward cover.",
			"opening_dirs" = list(EAST),
			"guard_dirs" = list(EAST),
			"opening_half_width" = 1,
		),
		"west_gate" = list(
			"label" = "West Gate",
			"description" = "Single western passage with inward cover.",
			"opening_dirs" = list(WEST),
			"guard_dirs" = list(WEST),
			"opening_half_width" = 1,
		),
		"corner_ne" = list(
			"label" = "North-East Corner",
			"description" = "Two corner exits that favor a north-east push.",
			"opening_dirs" = list(NORTH, EAST),
			"guard_dirs" = list(NORTH, EAST),
			"opening_half_width" = 0,
		),
		"corner_se" = list(
			"label" = "South-East Corner",
			"description" = "Two corner exits that favor a south-east push.",
			"opening_dirs" = list(SOUTH, EAST),
			"guard_dirs" = list(SOUTH, EAST),
			"opening_half_width" = 0,
		),
		"corner_sw" = list(
			"label" = "South-West Corner",
			"description" = "Two corner exits that favor a south-west push.",
			"opening_dirs" = list(SOUTH, WEST),
			"guard_dirs" = list(SOUTH, WEST),
			"opening_half_width" = 0,
		),
		"corner_nw" = list(
			"label" = "North-West Corner",
			"description" = "Two corner exits that favor a north-west push.",
			"opening_dirs" = list(NORTH, WEST),
			"guard_dirs" = list(NORTH, WEST),
			"opening_half_width" = 0,
		),
		"sealed_redoubt" = list(
			"label" = "Sealed Redoubt",
			"description" = "No direct passages; inner sentries guard the perimeter from inside.",
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
