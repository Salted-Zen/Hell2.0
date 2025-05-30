/obj/machinery/byteforge
	name = "byteforge"

	circuit = /obj/item/circuitboard/machine/byteforge
	desc = "A machine used by the quantum server. Quantum code converges here, materializing decrypted assets from the virtual abyss."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "byteforge"
	obj_flags = BLOCKS_CONSTRUCTION | CAN_BE_HIT
	/// Idle particles
	var/mutable_appearance/byteforge_particles

/obj/machinery/byteforge/Initialize(mapload)
	. = ..()

	return INITIALIZE_HINT_LATELOAD

/obj/machinery/byteforge/LateInitialize()
	. = ..()

	byteforge_particles = mutable_appearance(initial(icon), "on_particles", ABOVE_MOB_LAYER)
	setup_particles()

/obj/machinery/byteforge/update_appearance(updates)
	. = ..()

	setup_particles()

/// Does some sparks after it's done
/obj/machinery/byteforge/proc/flash(atom/movable/thing)
	playsound(src, 'sound/magic/blink.ogg', 50, TRUE)

	var/datum/effect_system/spark_spread/quantum/sparks = new()
	sparks.set_up(5, 1, loc)
	sparks.start()

	set_light(l_on = FALSE)

/// Forge begins to process
/obj/machinery/byteforge/proc/flicker(angry = FALSE)
	var/mutable_appearance/lighting = mutable_appearance(initial(icon), "on_overlay[angry ? "_angry" : ""]")
	flick_overlay_view(lighting, 1 SECONDS)

	set_light(l_outer_range = 2, l_power = 1.5, l_color = angry ? LIGHT_COLOR_BUBBLEGUM : LIGHT_COLOR_BABY_BLUE, l_on = TRUE)

/// Adds the particle overlays to the byteforge
/obj/machinery/byteforge/proc/setup_particles(angry = FALSE)
	cut_overlay(byteforge_particles)

	byteforge_particles = mutable_appearance(initial(icon), "on_particles[angry ? "_angry" : ""]", ABOVE_MOB_LAYER)

	if(is_operational)
		add_overlay(byteforge_particles)

/// Begins spawning the crate - lights, overlays, etc
/obj/machinery/byteforge/proc/start_to_spawn(obj/structure/closet/crate/secure/bitrunning/encrypted/cache)
	addtimer(CALLBACK(src, PROC_REF(spawn_crate), cache), 1 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

	var/mutable_appearance/lighting = mutable_appearance(initial(icon), "on_overlay")
	flick_overlay_view(lighting, 1 SECONDS)

//	set_light(l_range = 2, l_power = 1.5, l_color = LIGHT_COLOR_BABY_BLUE, l_on = TRUE) MONKEYSTATION EDIT ORIGINAL - We have changed lights
	set_light(l_inner_range = 1, l_outer_range = 2, l_power = 1.5, l_color = LIGHT_COLOR_BABY_BLUE, l_on = TRUE) // MONKEYSTATION EDIT NEW

/// Sparks, moves the crate to the location
/obj/machinery/byteforge/proc/spawn_crate(obj/structure/closet/crate/secure/bitrunning/encrypted/cache)
	if(QDELETED(cache))
		return

	playsound(src, 'sound/magic/blink.ogg', 50, TRUE)
	var/datum/effect_system/spark_spread/quantum/sparks = new()
	sparks.set_up(5, 1, loc)
	sparks.start()

	cache.forceMove(loc)
	set_light(l_on = FALSE)
