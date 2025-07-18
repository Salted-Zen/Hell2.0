////////////////////////////////
/proc/message_admins(msg)
	msg = "<span class=\"admin\"><span class=\"prefix\">ADMIN LOG:</span> <span class=\"message\">[msg]</span></span>"
	to_chat(GLOB.admins,
		type = MESSAGE_TYPE_ADMINLOG,
		html = msg,
		confidential = TRUE)

/proc/message_high_admins(msg)
	for(var/client/admin in GLOB.admins)
		var/datum/admins/D = GLOB.admin_datums[admin.ckey]
		if(D.check_for_rights(R_BAN))
			msg = "<span class=\"admin\"><span class=\"prefix\">ADMIN LOG:</span> <span class=\"message\">[msg]</span></span>"
			to_chat(admin,
				type = MESSAGE_TYPE_ADMINLOG,
				html = msg,
				confidential = TRUE)

/proc/relay_msg_admins(msg)
	msg = "<span class=\"admin\"><span class=\"prefix\">RELAY:</span> <span class=\"message\">[msg]</span></span>"
	to_chat(GLOB.admins,
		type = MESSAGE_TYPE_ADMINLOG,
		html = msg,
		confidential = TRUE)

///////////////////////////////////////////////////////////////////////////////////////////////Panels

/datum/admins/proc/Game()
	if(!check_rights(0))
		return

	var/dat = "<html><meta charset='UTF-8'><head><title>Game Panel</title></head><body>"
	dat += "<center><B>Game Panel</B></center><hr>"
	if(SSticker.current_state <= GAME_STATE_PREGAME)
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_roundstart=1'>(Force Roundstart Rulesets)</A><br>"
		if (GLOB.dynamic_forced_roundstart_ruleset.len > 0)
			for(var/datum/dynamic_ruleset/roundstart/rule in GLOB.dynamic_forced_roundstart_ruleset)
				dat += {"<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_roundstart_remove=[text_ref(rule)]'>-> [rule.name] <-</A><br>"}
			dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_roundstart_clear=1'>(Clear Rulesets)</A><br>"
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_options=1'>(Dynamic mode options)</A><br>"
	dat += "<hr/>"
	if(SSticker.IsRoundInProgress())
		dat += "<a href='byond://?src=[REF(src)];[HrefToken()];gamemode_panel=1'>(Game Mode Panel)</a><BR>"
	dat += {"
		<BR>
		<A href='byond://?src=[REF(src)];[HrefToken()];create_object=1'>Create Object</A><br>
		<A href='byond://?src=[REF(src)];[HrefToken()];quick_create_object=1'>Quick Create Object</A><br>
		<A href='byond://?src=[REF(src)];[HrefToken()];create_turf=1'>Create Turf</A><br>
		<A href='byond://?src=[REF(src)];[HrefToken()];create_mob=1'>Create Mob</A><br>
		"}

	if(marked_datum && istype(marked_datum, /atom))
		dat += "<A href='byond://?src=[REF(src)];[HrefToken()];dupe_marked_datum=1'>Duplicate Marked Datum</A><br>"

	dat += "</body></html>"
	usr << browse(dat, "window=admin2;size=240x280")
	return

////////////////////////////////////////////////////////////////////////////////////////////////ADMIN HELPER PROCS

ADMIN_VERB(spawn_atom, R_SPAWN, FALSE, "Spawn", "Spawn an atom.", ADMIN_CATEGORY_DEBUG, object as text)
	if(!object)
		return

	var/list/preparsed = splittext(object,":")
	var/path = preparsed[1]
	var/amount = 1
	if(length(preparsed) > 1) //MONKE EDIT
		amount = clamp(text2num(preparsed[2]),1,ADMIN_SPAWN_CAP)

	var/chosen = pick_closest_path(path)
	if(!chosen)
		return
	var/turf/T = get_turf(user.mob)

	if(ispath(chosen, /turf))
		T.ChangeTurf(chosen)
	else
		for(var/i in 1 to amount)
			var/atom/A = new chosen(T)
			A.flags_1 |= ADMIN_SPAWNED_1

	log_admin("[key_name(user)] spawned [amount] x [chosen] at [AREACOORD(user.mob)]")
	BLACKBOX_LOG_ADMIN_VERB("Spawn Atom")

ADMIN_VERB(spawn_atom_pod, R_SPAWN, FALSE, "PodSpawn", "Spawn an atom via supply drop.", ADMIN_CATEGORY_DEBUG, object as text)

	if(!check_rights(R_SPAWN))
		return

	var/chosen = pick_closest_path(object)
	if(!chosen)
		return
	var/turf/target_turf = get_turf(user.mob)

	if(ispath(chosen, /turf))
		target_turf.ChangeTurf(chosen)
	else
		var/obj/structure/closet/supplypod/pod = podspawn(list(
			"target" = target_turf,
			"path" = /obj/structure/closet/supplypod/centcompod,
		))
		//we need to set the admin spawn flag for the spawned items so we do it outside of the podspawn proc
		var/atom/A = new chosen(pod)
		A.flags_1 |= ADMIN_SPAWNED_1

	log_admin("[key_name(user)] pod-spawned [chosen] at [AREACOORD(user.mob)]")
	BLACKBOX_LOG_ADMIN_VERB("Podspawn Atom")

ADMIN_VERB(spawn_cargo, R_SPAWN, FALSE, "Spawn Cargo", "Spawn a cargo crate.", ADMIN_CATEGORY_DEBUG, object as text)
	var/chosen = pick_closest_path(object, make_types_fancy(subtypesof(/datum/supply_pack)))
	if(!chosen)
		return
	var/datum/supply_pack/S = new chosen
	S.admin_spawned = TRUE
	S.generate(get_turf(user.mob))

	log_admin("[key_name(user.mob)] spawned cargo pack [chosen] at [AREACOORD(user.mob)]")
	BLACKBOX_LOG_ADMIN_VERB("Spawn Cargo")

/datum/admins/proc/dynamic_mode_options(mob/user)
	var/dat = {"
		<html>
		<meta charset='UTF-8'>
		<head>
		<title>Game Panel</title>
		</head>
		<body>
		<center><B><h2>Dynamic Mode Options</h2></B></center><hr>
		<br/>
		<h3>Common options</h3>
		<i>All these options can be changed midround.</i> <br/>
		<br/>
		<b>Force extended:</b> - Option is <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_force_extended=1'> <b>[GLOB.dynamic_forced_extended ? "ON" : "OFF"]</a></b>.
		<br/>This will force the round to be extended. No rulesets will be drafted. <br/>
		<br/>
		<b>No stacking:</b> - Option is <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_no_stacking=1'> <b>[GLOB.dynamic_no_stacking ? "ON" : "OFF"]</b></a>.
		<br/>Unless the threat goes above [GLOB.dynamic_stacking_limit], only one "round-ender" ruleset will be drafted. <br/>
		<br/>
		<b>Forced threat level:</b> Current value : <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_forced_threat=1'><b>[GLOB.dynamic_forced_threat_level]</b></a>.
		<br/>The value threat is set to if it is higher than -1.<br/>
		<br/>
		<br/>
		<b>Stacking threeshold:</b> Current value : <a href='byond://?src=[REF(src)];[HrefToken()];f_dynamic_stacking_limit=1'><b>[GLOB.dynamic_stacking_limit]</b></a>.
		<br/>The threshold at which "round-ender" rulesets will stack. A value higher than 100 ensure this never happens. <br/>
		</body>
		</html>
		"}

	user << browse(dat, "window=dyn_mode_options;size=900x650")

ADMIN_VERB(create_or_modify_area, R_DEBUG, FALSE, "Create Or Modify Area", "Create of modify an area. wow.", ADMIN_CATEGORY_DEBUG)
	create_area(user.mob)

//Kicks all the clients currently in the lobby. The second parameter (kick_only_afk) determins if an is_afk() check is ran, or if all clients are kicked
//defaults to kicking everyone (afk + non afk clients in the lobby)
//returns a list of ckeys of the kicked clients
/proc/kick_clients_in_lobby(message, kick_only_afk = 0)
	var/list/kicked_client_names = list()
	for(var/client/C in GLOB.clients)
		if(isnewplayer(C.mob))
			if(kick_only_afk && !C.is_afk()) //Ignore clients who are not afk
				continue
			if(message)
				to_chat(C, message, confidential = TRUE)
			kicked_client_names.Add("[C.key]")
			qdel(C)
	return kicked_client_names

//returns TRUE to let the dragdrop code know we are trapping this event
//returns FALSE if we don't plan to trap the event
/datum/admins/proc/cmd_ghost_drag(mob/dead/observer/frommob, mob/tomob)

	//this is the exact two check rights checks required to edit a ckey with vv.
	if (!check_rights(R_VAREDIT,0) || !check_rights(R_SPAWN|R_DEBUG,0))
		return FALSE

	if (!frommob.ckey)
		return FALSE

	var/question = ""
	if (tomob.ckey)
		question = "This mob already has a user ([tomob.key]) in control of it! "
	question += "Are you sure you want to place [frommob.name]([frommob.key]) in control of [tomob.name]?"

	var/ask = tgui_alert(usr, question, "Place ghost in control of mob?", list("Yes", "No"))
	if (ask != "Yes")
		return TRUE

	if (!frommob || !tomob) //make sure the mobs don't go away while we waited for a response
		return TRUE

	// Disassociates observer mind from the body mind
	if(tomob.client)
		tomob.ghostize(FALSE)
	else
		for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
			if(tomob.mind == ghost.mind)
				ghost.mind = null

	message_admins(span_adminnotice("[key_name_admin(usr)] has put [frommob.key] in control of [tomob.name]."))
	log_admin("[key_name(usr)] stuffed [frommob.key] into [tomob.name].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Ghost Drag Control")

	tomob.PossessByPlayer(frommob.key)
	tomob.client?.init_verbs()
	qdel(frommob)

	return TRUE

/// Sends a message to adminchat when anyone with a holder logs in or logs out.
/// Is dependent on admin preferences and configuration settings, which means that this proc can fire without sending a message.
/client/proc/adminGreet(logout = FALSE)
	if(!SSticker.HasRoundStarted())
		return

	if(logout && CONFIG_GET(flag/announce_admin_logout))
		message_admins("Admin logout: [key_name(src)]")
		return

	if(!logout && CONFIG_GET(flag/announce_admin_login) && (prefs.toggles & ANNOUNCE_LOGIN))
		message_admins("Admin login: [key_name(src)]")
		return

