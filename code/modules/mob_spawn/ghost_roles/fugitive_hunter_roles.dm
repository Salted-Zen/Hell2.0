
/obj/effect/mob_spawn/ghost_role/human/fugitive
	spawner_job_path = /datum/job/fugitive_hunter
	prompt_name = "Write me some god damn prompt names!"
	you_are_text = "Write me some god damn you are text!"
	flavour_text = "Write me some god damn flavor text!" //the flavor text will be the backstory argument called on the antagonist's greet, see hunter.dm for details
	show_flavor = FALSE
	var/back_story = "error"
	loadout_enabled = FALSE
	dont_be_a_shit = FALSE

/obj/effect/mob_spawn/ghost_role/human/fugitive/Initialize(mapload)
	. = ..()
	notify_ghosts(
		"Hunters are waking up looking for refugees!",
		source = src,
		action = NOTIFY_PLAY,
		notify_flags = NOTIFY_CATEGORY_NOFLASH,
		ignore_key = POLL_IGNORE_FUGITIVE,
	)

/obj/effect/mob_spawn/ghost_role/human/fugitive/special(mob/living/carbon/human/spawned_human)
	. = ..()
	var/datum/antagonist/fugitive_hunter/fughunter = new
	fughunter.backstory = back_story
	spawned_human.mind.add_antag_datum(fughunter)
	fughunter.greet()
	message_admins("[ADMIN_LOOKUPFLW(spawned_human)] has been made into a Fugitive Hunter by an event.")
	spawned_human.log_message("was spawned as a Fugitive Hunter by an event.", LOG_GAME)

/obj/effect/mob_spawn/ghost_role/human/fugitive/spacepol
	name = "police pod"
	desc = "A small sleeper typically used to put people to sleep for briefing on the mission."
	prompt_name = "a spacepol officer"
	you_are_text = "I am a member of the Spacepol!"
	flavour_text = "Justice has arrived. We must capture those fugitives lurking on that station!"
	back_story = HUNTER_PACK_COPS
	outfit = /datum/outfit/spacepol
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"

/obj/effect/mob_spawn/ghost_role/human/fugitive/russian
	name = "russian pod"
	desc = "A small sleeper typically used to make long distance travel a bit more bearable."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	faction = list(FACTION_RUSSIAN)
	prompt_name = "a russian"
	you_are_text = "Ay blyat. I am a Space-Russian smuggler!"
	flavour_text = "We were mid-flight when our cargo was beamed off our ship! Must be on station somewhere? \
		We must \"legally\" reaquire it by any means necessary - is our property, after all!"
	back_story = HUNTER_PACK_RUSSIAN
	outfit = /datum/outfit/russian_hunter

/obj/effect/mob_spawn/ghost_role/human/fugitive/russian/leader
	name = "russian commandant pod"
	you_are_text = "Ay blyat. I am the commandant of a Space-Russian smuggler ring!"
	outfit = /datum/outfit/russian_hunter/leader

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty
	name = "bounty hunter pod"
	prompt_name = "a bounty hunter"
	you_are_text = "I'm a bounty hunter."
	flavour_text = "We got a new bounty on some fugitives, dead or alive."
	back_story = HUNTER_PACK_BOUNTY
	desc = "A small sleeper typically used to make long distance travel a bit more bearable."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"

/obj/effect/mob_spawn/ghost_role/human/fugitive/psykers
	name = "mental energizer"
	desc = "A cryo sleeper modified to keep the occupant mentally sharp. However that works..."
	icon_state = "psykerpod"
	prompt_name = "a psyker-hunter"
	mob_species = /datum/species/human
	outfit = /datum/outfit/psyker

/obj/effect/mob_spawn/ghost_role/human/fugitive/psykers/captain
	prompt_name = "a psyker-hunter captain"
	outfit = /datum/outfit/psyker/captain

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty/Destroy()
	var/obj/structure/fluff/empty_sleeper/S = new(drop_location())
	S.setDir(dir)
	return ..()

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty/armor
	outfit = /datum/outfit/bountyarmor

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty/hook
	outfit = /datum/outfit/bountyhook

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty/synth
	outfit = /datum/outfit/bountysynth

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty/psyker
	name = "mental energizer"
	desc = "A cryo sleeper modified to keep the occupant mentally sharp. However that works..."
	icon_state = "psykerpod"
	prompt_name = "a psyker"
	you_are_text = "Ahahaha! I am a Psyker Shikari!"
	flavour_text = "Man, waking up from a gorenap always BLOWS. Finding dealers in this sector of space is always difficult, but \
		we've recieved an offer that might set us up for life! Kidnap some fugitives and get FREE GORE!"
	back_story = HUNTER_PACK_PSYKER
	outfit = /datum/outfit/psyker

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty/psyker/captain
	prompt_name = "a psyker Captain"
	back_story = HUNTER_PACK_PSYKER
	outfit = /datum/outfit/psyker/captain

/obj/effect/mob_spawn/ghost_role/human/fugitive/bounty/psyker/seer
	name = "cryosleep pod"
	desc = "A dingy, poorly maintained, but still run-of-the-mill cryo sleeper."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	prompt_name = "a psyker seer"
	you_are_text = "psyker seer"
	flavour_text = "Oh great, the fortunte-tellers want my help with something again. They picked up up while I was space-hitchhiking, said they would take me anywhere \
		if I assisted them with my 'flesh-gaze'. They're a bunch of freaks, but at least they leave me be after I'm done helping them..."
	back_story = HUNTER_PACK_PSYKER
	outfit = /datum/outfit/psyker_seer
