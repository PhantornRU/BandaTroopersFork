/turf/closed/wall/unsc
	name = "внутренняя переборка корабля"
	desc = "Обычная корабельная переборка. Не Titanium-A, но всё равно довольно прочная."
	icon = 'icons/halo/turf/walls/unsc.dmi'
	icon_state = "unsc"
	walltype = WALL_UNSC

/turf/closed/wall/unsc/reinforced
	name = "усиленная внутренняя переборка корабля"
	icon_state = "unsc_reinforced"
	damage_cap = HEALTH_WALL_REINFORCED

/turf/closed/wall/unsc/reinforced/hull
	hull = TRUE
	icon_state = "unsc_hull"

/turf/closed/wall/unsc/reinforced/hull/titanium_a
	name = "обшивка корпуса из Titanium-A"
	desc = "Лучшая боевая обшивка, которую ККОН может поставить на свои корабли."
	icon_state = "unsc_hull_ext"

/turf/closed/wall/voi
	name = "панельная стена"
	desc = "Дешёвая и легко заменяемая обшивка для обычных промышленных нужд."
	icon_state = "voiwall"
	walltype = WALL_VOI
	icon = 'icons/halo/turf/walls/voi_wall.dmi'

/turf/closed/wall/voi/reinforced
	name = "усиленная панельная стена"
	desc = "Под декоративными панелями эта стена дополнительно усилена."
	icon_state = "voiwall_r"
	damage_cap = HEALTH_WALL_REINFORCED

/turf/closed/wall/voi/reinforced/hull
	name = "сверхусиленная панельная стена"
	desc = "Панельная стена с особенно мощным усилением."
	icon_state = "voiwall_h"
	hull = TRUE

/turf/closed/wall/covenant
	name = "облегчённая наноламинатная стена"
	desc = "Более лёгкая разновидность наноламината."
	icon_state = "covwall"
	walltype = WALL_COV
	damage_cap = HEALTH_WALL_REINFORCED
	icon = 'icons/halo/turf/walls/cov_standard.dmi'

/turf/closed/wall/covenant/hull
	name = "наноламинатная стена"
	desc = "Стандартная наноламинатная конструкция, распространённая по всему Ковенанту."
	icon_state = "covwall_h"
	hull = TRUE

/turf/closed/wall/covenant/hull/ship
	name = "корабельный наноламинат"
	desc = "Самый прочный стеновой материал Ковенанта."
	icon_state = "covwall_h_ext"

/turf/closed/wall/covenant/lights
	name = "облегчённая наноламинатная стена"
	desc = "Облегчённый наноламинат со встроенной маломощной подсветкой."
	icon_state = "l_covwall"
	walltype = WALL_COV_LIGHTS
	damage_cap = HEALTH_WALL_REINFORCED
	light_on = TRUE
	light_range = 3
	light_power = 0.25
	light_color = LIGHT_COLOR_PINK

/turf/closed/wall/covenant/lights/brighter
	light_range = 4
	light_power = 0.5

/turf/closed/wall/covenant/lights/hull
	name = "наноламинатная стена"
	desc = "Стандартная наноламинатная стена со встроенной маломощной подсветкой."
	icon_state = "l_covwall_h"
	hull = TRUE

/turf/closed/wall/covenant/lights/hull/brighter
	light_range = 4
	light_power = 0.5
