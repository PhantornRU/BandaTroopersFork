#define SPECIES_RUUHTIAN "Ruuhtian"
#define LANGUAGE_RUUHTIAN "Ruuhtian"

#define RUUHTIAN_SKIN_COLOR list("ruuht1")

#define isruuhtian(A) (ishuman(A) && istype(A?:species, /datum/species/ruuhtian))
#define isspeciesruuhtian(A) (A.species?.group == SPECIES_RUUHTIAN)
