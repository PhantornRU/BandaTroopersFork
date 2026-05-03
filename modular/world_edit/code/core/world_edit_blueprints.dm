#define WORLD_EDIT_BLUEPRINT_SCHEMA "world_edit_blueprint_lite"
#define WORLD_EDIT_BLUEPRINT_VERSION 1
#define WORLD_EDIT_BLUEPRINT_DIR "data/world_edit/blueprints/"
#define WORLD_EDIT_BLUEPRINT_ID_LEN 32
#define WORLD_EDIT_BLUEPRINT_NAME_MAX_LEN 64
#define WORLD_EDIT_BLUEPRINT_MAX_ENTRIES 170
#define WORLD_EDIT_BLUEPRINT_MAX_RADIUS 20

GLOBAL_LIST_INIT(world_edit_blueprint_valid_factions, list(
	FACTION_MARINE,
	FACTION_UA_REBEL,
	FACTION_UPP,
	FACTION_CANC,
	FACTION_WY,
	FACTION_FREELANCER,
	FACTION_TWE,
	FACTION_TWE_REBEL,
	FACTION_MERCENARY,
	FACTION_COVENANT,
))

GLOBAL_DATUM_INIT(world_edit_blueprints, /datum/world_edit_blueprint_service, new)

/datum/world_edit_blueprint_service
	var/list/world_edit_blueprint_type_rules = list()

/datum/world_edit_blueprint_service/New()
	. = ..()
	world_edit_blueprint_type_rules = world_edit_build_blueprint_type_rules()
