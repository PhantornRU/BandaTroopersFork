#define WORLD_EDIT_PRESET_FILENAME "world_edit_presets.sav"
#define WORLD_EDIT_PRESET_VERSION 1
#define WORLD_EDIT_PRESET_LIMIT 60
#define WORLD_EDIT_PRESET_NAME_MAX_LEN 64

GLOBAL_LIST_INIT(world_edit_preset_supported_generators, list(
	"outpost_radius" = TRUE,
	"destruction_pack" = TRUE,
))

GLOBAL_DATUM_INIT(world_edit_presets, /datum/world_edit_preset_service, new)

/datum/world_edit_preset_service
