
/proc/agibs(atom/location, list/viruses)
	new /obj/effect/spawner/gibspawner/xeno/arachnid(get_turf(location),viruses)

/mob/living/carbon/xenomorph/arachnide/spawn_gibs()
	agibs(get_turf(src))

/obj/effect/spawner/gibspawner/xeno/arachnid
	gibtypes = list(
		/obj/effect/decal/cleanable/blood/gibs/arachnid,
		/obj/effect/decal/cleanable/blood/gibs/arachnid/limb,
		/obj/effect/decal/cleanable/blood/gibs/arachnid/body
		)
	gibamounts = list(1,1,1)
